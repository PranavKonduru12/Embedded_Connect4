#include "EDK_CM0.h"
#include "core_cm0.h"
#include "edk_driver.h"
#include "edk_api.h"
#include <stdio.h>
#include <stdint.h>

/*
 * Connect Four controlled by GPIO switches.
 *
 * Switch mapping:
 *   sw0 -> drop in column 1
 *   sw1 -> drop in column 2
 *   sw2 -> drop in column 3
 *   sw3 -> drop in column 4
 *   sw4 -> drop in column 5
 *   sw5 -> drop in column 6
 *   sw6 -> drop in column 7
 *   sw7 -> reset game
 *
 * Operation:
 *   - Flip one of sw0..sw6 from 0 to 1 to drop a piece in that column.
 *   - Turn the switch back to 0 before using it again.
 *   - Flip sw7 from 0 to 1 to reset the game.
 *
 * IMPORTANT:
 *   GPIO_BASE_ADDR must match your hardware address decoder.
 */

#define ROWS 6
#define COLS 7

#define CELL_W 12
#define CELL_H 12
#define BOARD_X 8
#define BOARD_Y 20
#define CURSOR_H 6

#define GPIO_BASE_ADDR 0x53000000

#define SW_COL0_MASK (1u << 0)
#define SW_COL1_MASK (1u << 1)
#define SW_COL2_MASK (1u << 2)
#define SW_COL3_MASK (1u << 3)
#define SW_COL4_MASK (1u << 4)
#define SW_COL5_MASK (1u << 5)
#define SW_COL6_MASK (1u << 6)
#define SW_RESET_MASK (1u << 7)

static volatile uint32_t * const GPIO32 = (volatile uint32_t *)GPIO_BASE_ADDR;

static int board[ROWS][COLS];
static int current_player;
static int cursor_col;
static int game_over;
static int winner;

static int r, c;
static uint8_t last_switch_sample;

static uint8_t read_switches(void)
{
    return (uint8_t)(GPIO32[0] & 0xFFu);
}

void clear_board_array(void)
{
    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++) {
            board[r][c] = 0;
        }
    }
}

void draw_cell(int row, int col, int value)
{
    int x1 = BOARD_X + col * CELL_W;
    int y1 = BOARD_Y + row * CELL_H;
    int x2 = x1 + CELL_W - 2;
    int y2 = y1 + CELL_H - 2;

    rectangle(x1, y1, x2, y2, BLUE);

    if (value == 0) {
        rectangle(x1 + 2, y1 + 2, x2 - 2, y2 - 2, BLACK);
    } else if (value == 1) {
        rectangle(x1 + 2, y1 + 2, x2 - 2, y2 - 2, RED);
    } else {
        rectangle(x1 + 2, y1 + 2, x2 - 2, y2 - 2, GREEN);
    }
}

void draw_cursor(void)
{
    int x1 = BOARD_X + cursor_col * CELL_W + 2;
    int x2 = x1 + CELL_W - 6;
    int y1 = BOARD_Y - CURSOR_H - 2;
    int y2 = BOARD_Y - 3;

    if (game_over) {
        rectangle(x1, y1, x2, y2, WHITE);
    } else if (current_player == 1) {
        rectangle(x1, y1, x2, y2, RED);
    } else {
        rectangle(x1, y1, x2, y2, GREEN);
    }
}

void draw_status(void)
{
    if (!game_over) {
        if (current_player == 1) {
            printf("\nP1 TURN");
            write_LED(0x01);
        } else {
            printf("\nP2 TURN");
            write_LED(0x02);
        }
    } else {
        if (winner == 1) {
            printf("\nP1 WIN  Turn on sw7 to reset");
            write_LED(0x0F);
        } else if (winner == 2) {
            printf("\nP2 WIN  Turn on sw7 to reset");
            write_LED(0xF0);
        } else {
            printf("\nDRAW    Turn on sw7 to reset");
            write_LED(0xAA);
        }
    }
}

void draw_board(void)
{
    clear_screen();

    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++) {
            draw_cell(r, c, board[r][c]);
        }
    }

    draw_cursor();
}

void game_init(void)
{
    clear_board_array();

    current_player = 1;
    cursor_col = 3;
    game_over = 0;
    winner = 0;
    last_switch_sample = read_switches();

    clear_screen();
    draw_board();

    printf("\n\n-------- EDK Demo ---------");
    printf("\n---- Connect Four Game ----");
    printf("\nUse switches to play:");
    printf("\nsw0 -> column 1");
    printf("\nsw1 -> column 2");
    printf("\nsw2 -> column 3");
    printf("\nsw3 -> column 4");
    printf("\nsw4 -> column 5");
    printf("\nsw5 -> column 6");
    printf("\nsw6 -> column 7");
    printf("\nsw7 -> reset game");
    printf("\nP1 = RED, P2 = GREEN");
    printf("\nTurn a switch ON to drop.");
    printf("\nTurn it OFF before using it again.\n");

    Display_Int_Times();
    draw_status();

    timer_init(Timer_Load_Value_For_One_Sec, Timer_Prescaler, 1);
    timer_enable();

    NVIC_EnableIRQ(Timer_IRQn);
    NVIC_DisableIRQ(UART_IRQn);
}

int drop_piece(int col)
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

int count_dir(int row, int col, int dr, int dc)
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

int check_winner(int row, int col)
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

int check_draw(void)
{
    for (c = 0; c < COLS; c++) {
        if (board[0][c] == 0)
            return 0;
    }

    return 1;
}

void next_player(void)
{
    if (current_player == 1)
        current_player = 2;
    else
        current_player = 1;
}

void show_game_over(void)
{
    draw_board();
    draw_status();
}

void handle_drop_column(int col)
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

void poll_switch_controls(void)
{
    uint8_t sw = read_switches();
    uint8_t rising = (uint8_t)(sw & (uint8_t)(~last_switch_sample));

    last_switch_sample = sw;

    if (rising & SW_RESET_MASK) {
        game_init();
        return;
    }

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

void UART_ISR(void)
{
    /* UART input disabled in switch-controlled version. */
    (void)UartGetc();
}

void Timer_ISR(void)
{
    Display_Int_Times();
    poll_switch_controls();
    timer_irq_clear();
}

int main(void)
{
    SoC_init();
    game_init();

    while (1) {
        __WFI();
    }
}
