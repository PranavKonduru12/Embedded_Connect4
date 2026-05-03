#include "EDK_CM0.h"
#include "core_cm0.h"
#include "edk_driver.h"
#include "edk_api.h"
#include <stdio.h>
#include <stdint.h>

/*
 * Connect Four
 *
 * Controls:
 *   sw0 -> drop in column 1
 *   sw1 -> drop in column 2
 *   sw2 -> drop in column 3
 *   sw3 -> drop in column 4
 *   sw4 -> drop in column 5
 *   sw5 -> drop in column 6
 *   sw6 -> drop in column 7
 *   sw7 -> reset game
 *
 * Both players share the same switches.
 * Player 1 = RED
 * Player 2 = GREEN
 *
 * 7-segment display:
 *   Digit1 = 0x5400_0000
 *   Digit2 = 0x5400_0004
 *   Digit3 = 0x5400_0008
 *   Digit4 = 0x5400_000C
 *
 * Timer:
 *   30 seconds per turn
 *   Counts down on the 7-segment display
 *   When time reaches 0, turn changes to the other player.
 *
 * IMPORTANT:
 *   Update GPIO_BASE_ADDR if your hardware uses a different address.
 *   This file assumes AHBGPIO data register at base+0 and dir register at base+4.
 */

#define ROWS 6
#define COLS 7

#define CELL_W 12
#define CELL_H 12
#define BOARD_X 8
#define BOARD_Y 20
#define CURSOR_H 6

/* Update this if your GPIO address is different in your AHB decoder */
#define GPIO_BASE_ADDR      0x53000000u

/* Fixed from your 7-seg register map screenshot */
#define SEG7_DIGIT1_ADDR    0x54000000u
#define SEG7_DIGIT2_ADDR    0x54000004u
#define SEG7_DIGIT3_ADDR    0x54000008u
#define SEG7_DIGIT4_ADDR    0x5400000Cu

#define TURN_TIME_SEC       30u

#define SW_COL0_MASK        (1u << 0)
#define SW_COL1_MASK        (1u << 1)
#define SW_COL2_MASK        (1u << 2)
#define SW_COL3_MASK        (1u << 3)
#define SW_COL4_MASK        (1u << 4)
#define SW_COL5_MASK        (1u << 5)
#define SW_COL6_MASK        (1u << 6)
#define SW_RESET_MASK       (1u << 7)

#define PLAYER1             1
#define PLAYER2             2

//chat
#define CHAT_BUF_SIZE 80

static volatile uint32_t * const GPIO32      = (volatile uint32_t *)GPIO_BASE_ADDR;
static volatile uint32_t * const SEG7_DIGIT1 = (volatile uint32_t *)SEG7_DIGIT1_ADDR;
static volatile uint32_t * const SEG7_DIGIT2 = (volatile uint32_t *)SEG7_DIGIT2_ADDR;
static volatile uint32_t * const SEG7_DIGIT3 = (volatile uint32_t *)SEG7_DIGIT3_ADDR;
static volatile uint32_t * const SEG7_DIGIT4 = (volatile uint32_t *)SEG7_DIGIT4_ADDR;

static int board[ROWS][COLS];
static int current_player;
static int cursor_col;
static int game_over;
static int winner;

static volatile uint8_t turn_time_left;
static uint8_t last_switch_sample;

static int r, c;


static char chat_buffer[CHAT_BUF_SIZE];
static int chat_index = 0;
static int chat_player = 1;
static int chat_prompt_printed = 0;

/* -------------------------------------------------------------------------- */
/* GPIO and 7-segment helpers                                                 */
/* -------------------------------------------------------------------------- */
static uint8_t read_switches(void)
{
    return (uint8_t)(GPIO32[0] & 0xFFu);
}

static void gpio_set_all_input(void)
{
    /* AHB GPIO DIR register at base + 4, 0 = input */
    GPIO32[1] = 0x00000000u;
}

static void seg7_show_number(uint16_t value)
{
    uint8_t d1 = (uint8_t)(value % 10u);          /* ones */
    uint8_t d2 = (uint8_t)((value / 10u) % 10u);  /* tens */
    uint8_t d3 = (uint8_t)((value / 100u) % 10u);
    uint8_t d4 = (uint8_t)((value / 1000u) % 10u);

    *SEG7_DIGIT1 = (uint32_t)d1;
    *SEG7_DIGIT2 = (uint32_t)d2;
    *SEG7_DIGIT3 = (uint32_t)d3;
    *SEG7_DIGIT4 = (uint32_t)d4;
}

static void start_turn_timer(void)
{
    turn_time_left = TURN_TIME_SEC;
    seg7_show_number(turn_time_left);
}

/* -------------------------------------------------------------------------- */
/* Drawing                                                                    */
/* -------------------------------------------------------------------------- */
static void clear_board_array(void)
{
    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++) {
            board[r][c] = 0;
        }
    }
}

static void draw_cell(int row, int col, int value)
{
    int x1 = BOARD_X + col * CELL_W;
    int y1 = BOARD_Y + row * CELL_H;
    int x2 = x1 + CELL_W - 2;
    int y2 = y1 + CELL_H - 2;

    rectangle(x1, y1, x2, y2, BLUE);

    if (value == 0) {
        rectangle(x1 + 2, y1 + 2, x2 - 2, y2 - 2, BLACK);
    } else if (value == PLAYER1) {
        rectangle(x1 + 2, y1 + 2, x2 - 2, y2 - 2, RED);
    } else {
        rectangle(x1 + 2, y1 + 2, x2 - 2, y2 - 2, GREEN);
    }
}

static void draw_cursor(void)
{
    int x1 = BOARD_X + cursor_col * CELL_W + 2;
    int x2 = x1 + CELL_W - 6;
    int y1 = BOARD_Y - CURSOR_H - 2;
    int y2 = BOARD_Y - 3;

    if (game_over) {
        rectangle(x1, y1, x2, y2, WHITE);
    } else if (current_player == PLAYER1) {
        rectangle(x1, y1, x2, y2, RED);
    } else {
        rectangle(x1, y1, x2, y2, GREEN);
    }
}

static void draw_status(void)
{
    if (!game_over) {
        if (current_player == PLAYER1) {
            printf("\nP1 TURN  sw0-sw6");
            write_LED(0x01);
        } else {
            printf("\nP2 TURN  sw0-sw6");
            write_LED(0x02);
        }
        printf("  TIME=%u", (unsigned)turn_time_left);
    } else {
        if (winner == PLAYER1) {
            printf("\nP1 WIN  sw7 reset");
            write_LED(0x0F);
        } else if (winner == PLAYER2) {
            printf("\nP2 WIN  sw7 reset");
            write_LED(0xF0);
        } else {
            printf("\nDRAW    sw7 reset");
            write_LED(0xAA);
        }
    }
}

static void draw_board(void)
{
    clear_screen();

    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++) {
            draw_cell(r, c, board[r][c]);
        }
    }

    draw_cursor();
}

/* -------------------------------------------------------------------------- */
/* Game logic                                                                 */
/* -------------------------------------------------------------------------- */
static int drop_piece(int col)
{
    int row;

    for (row = ROWS - 1; row >= 0; row--) {
        if (board[row][col] == 0) {
            board[row][col] = current_player;
            return row;
        }
    }

    return -1;
}

static int count_dir(int row, int col, int dr, int dc)
{
    int count = 0;
    int player = board[row][col];
    int rr = row + dr;
    int cc = col + dc;

    while (rr >= 0 && rr < ROWS && cc >= 0 && cc < COLS &&
           board[rr][cc] == player) {
        count++;
        rr += dr;
        cc += dc;
    }

    return count;
}

static int check_winner(int row, int col)
{
    if (1 + count_dir(row, col, 0, 1) + count_dir(row, col, 0, -1) >= 4)
        return 1;

    if (1 + count_dir(row, col, 1, 0) + count_dir(row, col, -1, 0) >= 4)
        return 1;

    if (1 + count_dir(row, col, 1, 1) + count_dir(row, col, -1, -1) >= 4)
        return 1;

    if (1 + count_dir(row, col, 1, -1) + count_dir(row, col, -1, 1) >= 4)
        return 1;

    return 0;
}

static int check_draw(void)
{
    for (c = 0; c < COLS; c++) {
        if (board[0][c] == 0)
            return 0;
    }

    return 1;
}

static void next_player(void)
{
    if (current_player == PLAYER1)
        current_player = PLAYER2;
    else
        current_player = PLAYER1;

    start_turn_timer();
}

static void show_game_over(void)
{
    draw_board();
    draw_status();
    seg7_show_number(0);
}

static void handle_drop_column(int col)
{
    int row;

    if (col < 0 || col >= COLS)
        return;

    if (game_over)
        return;

    cursor_col = col;
    row = drop_piece(col);

    if (row < 0) {
        draw_board();
        printf("\nCOLUMN %d FULL", col + 1);
        return;
    }

    draw_board();

    if (check_winner(row, col)) {
        game_over = 1;
        winner = current_player;
        show_game_over();
        return;
    }

    if (check_draw()) {
        game_over = 1;
        winner = 0;
        show_game_over();
        return;
    }

    next_player();
    draw_status();
    draw_board();
}

static void game_init(void)
{
    clear_board_array();

    current_player = PLAYER1;
    cursor_col = 3;
    game_over = 0;
    winner = 0;

    gpio_set_all_input();
    last_switch_sample = read_switches();

    clear_screen();
    draw_board();

    printf("\n\n-------- EDK Demo ---------");
    printf("\n---- Connect Four Game ----");
    printf("\nsw0 -> column 1");
    printf("\nsw1 -> column 2");
    printf("\nsw2 -> column 3");
    printf("\nsw3 -> column 4");
    printf("\nsw4 -> column 5");
    printf("\nsw5 -> column 6");
    printf("\nsw6 -> column 7");
    printf("\nsw7 -> reset");
    printf("\nP1 = RED, P2 = GREEN");
    printf("\nBoth players use the same switches.");
    printf("\n30-second timer shown on 7-segment.");
    printf("\nTurn switch OFF before using it again.\n");
		

    start_turn_timer();
    draw_status();

    timer_init(Timer_Load_Value_For_One_Sec, Timer_Prescaler, 1);
    timer_irq_clear();
    timer_enable();

    NVIC_EnableIRQ(Timer_IRQn);
    //NVIC_DisableIRQ(UART_IRQn);
		NVIC_EnableIRQ(UART_IRQn);
}

/* -------------------------------------------------------------------------- */
/* Switch input                                                               */
/* -------------------------------------------------------------------------- */
static void poll_switch_controls(void)
{
    uint8_t sw = read_switches();
    uint8_t rising = (uint8_t)(sw & (uint8_t)(~last_switch_sample));

    last_switch_sample = sw;

    if (rising & SW_RESET_MASK) {
        game_init();
        return;
    }

    if (game_over)
        return;

    if (rising & SW_COL0_MASK) {
        handle_drop_column(0);
        return;
    }
    if (rising & SW_COL1_MASK) {
        handle_drop_column(1);
        return;
    }
    if (rising & SW_COL2_MASK) {
        handle_drop_column(2);
        return;
    }
    if (rising & SW_COL3_MASK) {
        handle_drop_column(3);
        return;
    }
    if (rising & SW_COL4_MASK) {
        handle_drop_column(4);
        return;
    }
    if (rising & SW_COL5_MASK) {
        handle_drop_column(5);
        return;
    }
    if (rising & SW_COL6_MASK) {
        handle_drop_column(6);
        return;
    }
}



void UART_puts(const char *s)
{
    while (*s) {
        UartPutc(*s++);
    }
}

//Helper function to print message in vga
void VGA_puts(const char *s)
{
    while (*s) {
        VGAPutc(*s++);
    }
}

void print_chat_prompt(void)
{
    if (chat_player == 1)
        UART_puts("\r\nPlayer 1> ");
    else
        UART_puts("\r\nPlayer 2> ");
}

/* -------------------------------------------------------------------------- */
/* Interrupts                                                                 */
/* -------------------------------------------------------------------------- */
//void UART_ISR(void)
//{
//    /* UART disabled for this version. */
//    (void)UartGetc();
//}

void UART_ISR(void)
{
    unsigned char c;

    if (chat_prompt_printed == 0) {
        print_chat_prompt();
        chat_prompt_printed = 1;
    }

    c = UartGetc();

    if (c == '\r' || c == '\n') {
        chat_buffer[chat_index] = '\0';

        UART_puts("\r\n");

        if (chat_player == 1) {
            VGA_puts("\nPlayer 1: ");
            VGA_puts(chat_buffer);
            VGAPutc('\n');

            chat_player = 2;
        }
        else {
            VGA_puts("\nPlayer 2: ");
            VGA_puts(chat_buffer);
            VGAPutc('\n');

            chat_player = 1;
        }

        chat_index = 0;
        print_chat_prompt();
    }

    else if (c == 0x08 || c == 0x7F) {
        if (chat_index > 0) {
            chat_index--;

            /* Move cursor back, erase character, move cursor back again */
            UartPutc('\b');
            UartPutc(' ');
            UartPutc('\b');
        }
    }

    else {
        if (chat_index < CHAT_BUF_SIZE - 1) {
            chat_buffer[chat_index++] = c;

            /* Echo typed character to SSH/TeraTerm */
            UartPutc(c);
        }
    }
}

void Timer_ISR(void)
{
    if (!game_over) {
        if (turn_time_left > 0u) {
            turn_time_left--;
            seg7_show_number(turn_time_left);
        }

        /* Timeout changes turn, but does not make a move automatically. */
        if (turn_time_left == 0u) {
            printf("\nTIME OUT -> next player");
            next_player();
            draw_status();
            draw_board();
        }
    }

    timer_irq_clear();
}

/* -------------------------------------------------------------------------- */
/* Main                                                                       */
/* -------------------------------------------------------------------------- */
int main(void)
{
    SoC_init();
    game_init();

    while (1) {
        poll_switch_controls();
    }
}
