/*
 * Connect Four embedded game implementation.
 *
 * GPIO switches are used as interrupt-driven gameplay inputs:
 *   SW0-SW6 select columns 1-7.
 *   SW7 requests a game reset.
 *
 * UART is interrupt-driven for receiving characters, but the actual
 * name-entry and pause processing is handled in the main loop using
 * a small receive buffer.
 *
 * The timer interrupt controls the 30-second turn countdown and
 * automatically advances to the next player when time expires.
 *
 * VGA displays the board, player names, status, and prompts.
 * LEDs show game status such as current player, pause, win, or draw.
 */

/*
 * Global game state.
 *
 * board[][] stores the Connect Four grid.
 * current_player tracks whose turn it is.
 * cursor_col stores the currently selected column.
 * game_over and winner track the end-game state.
 * game_paused is controlled through the UART spacebar input.
 */ 
#include "EDK_CM0.h"
#include "core_cm0.h"
#include "edk_driver.h"
#include "edk_api.h"
#include <stdio.h>
#include <stdint.h>

#define ROWS 6
#define COLS 7

#define CELL_W 12
#define CELL_H 12
#define BOARD_X 8
#define BOARD_Y 20
#define CURSOR_H 6

#define GPIO_BASE_ADDR      0x53000000u

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

#define NAME_MAX_LEN        12u
#define UART_RX_BUF_SIZE    64u

static volatile uint32_t * const SEG7_DIGIT1 = (volatile uint32_t *)SEG7_DIGIT1_ADDR;
static volatile uint32_t * const SEG7_DIGIT2 = (volatile uint32_t *)SEG7_DIGIT2_ADDR;
static volatile uint32_t * const SEG7_DIGIT3 = (volatile uint32_t *)SEG7_DIGIT3_ADDR;
static volatile uint32_t * const SEG7_DIGIT4 = (volatile uint32_t *)SEG7_DIGIT4_ADDR;

static int board[ROWS][COLS];
static int current_player;
static int cursor_col;
static int game_over;
static int winner;
static uint8_t game_paused;

static volatile uint8_t turn_time_left;
static uint8_t last_switch_sample;

static int r, c;

static char player_name[3][NAME_MAX_LEN + 1u] = {
    "",
    "Player 1",
    "Player 2"
};

static volatile uint8_t uart_rx_buf[UART_RX_BUF_SIZE];
static volatile uint8_t uart_rx_head = 0u;
static volatile uint8_t uart_rx_tail = 0u;

static uint8_t entering_names = 1u;
static uint8_t name_player = PLAYER1;
static uint8_t name_index = 0u;
static char name_temp[NAME_MAX_LEN + 1u];

static void draw_board(void);
static void draw_status(void);
static void toggle_pause(void);

//reset flag
static volatile uint8_t reset_requested = 0;

/*
 * UART receive buffer and name-entry support.
 *
 * UART_ISR only stores incoming characters into a circular buffer.
 * The main loop later calls process_uart_name_input() to handle
 * player name entry, backspace, ENTER, and pause control.
 * This keeps the UART interrupt short and avoids doing printf()
 * directly inside the interrupt.
 */
static void uart_rx_push(uint8_t ch)
{
    uint8_t next = (uint8_t)((uart_rx_head + 1u) % UART_RX_BUF_SIZE);

    if (next != uart_rx_tail) {
        uart_rx_buf[uart_rx_head] = ch;
        uart_rx_head = next;
    }
}

static int uart_rx_pop(uint8_t *ch)
{
    if (uart_rx_head == uart_rx_tail)
        return 0;

    *ch = uart_rx_buf[uart_rx_tail];
    uart_rx_tail = (uint8_t)((uart_rx_tail + 1u) % UART_RX_BUF_SIZE);
    return 1;
}

static void uart_puts(const char *s)
{
    while (*s) {
        UartPutc((unsigned char)*s++);
    }
}

/*
 * Prompts the current player to enter a name.
 * The prompt is printed to both VGA/printf output and UART/SSH.
 */
static void prompt_current_name(void)
{
    if (name_player == PLAYER1) {
        printf("\nEnter Player 1 name, then press ENTER: ");
				uart_puts("\r\nEnter Player 1 name, then press ENTER: ");
		}
				
    else {
        printf("\nEnter Player 2 name, then press ENTER: ");
				uart_puts("\r\nEnter Player 2 name, then press ENTER: ");
		}
}

//writing in the player names
static void finish_one_name(void)
{
    uint8_t i;

    name_temp[name_index] = '\0';

    if (name_index > 0u) {
        for (i = 0u; i <= name_index; i++) {
            player_name[name_player][i] = name_temp[i];
        }
    }

    if (name_player == PLAYER1) {
        name_player = PLAYER2;
        name_index = 0u;
        name_temp[0] = '\0';
        prompt_current_name();
    } else {
        entering_names = 0u;
        printf("\nNames saved: P1=%s, P2=%s\n",
               player_name[PLAYER1],
               player_name[PLAYER2]);

        draw_board();
        draw_status();
    }
}

/*
 * Processes buffered UART characters.
 *
 * During startup, characters are used to enter Player 1 and Player 2 names.
 * After names are entered, the spacebar toggles pause/resume.
 * Backspace is handled for both SSH/TeraTerm and VGA text output.
 */
static void process_uart_name_input(void)
{
    uint8_t ch;

    while (uart_rx_pop(&ch)) {
        if (!entering_names) {
            if (ch == ' ') {
                toggle_pause();
            }
            continue;
        }

        if (ch == '\r' || ch == '\n') {
            printf("\n");
            finish_one_name();
        } else if (ch == 0x08u || ch == 0x7Fu) {
            if (name_index > 0u) {
                name_index--;
                name_temp[name_index] = '\0';
								
								/* erase from SSH/TeraTerm */
                UartPutc('\b');
                UartPutc(' ');
                UartPutc('\b');
								
								/* erase from VGA/printf output */
                printf("\b \b");
            }
        } else if (ch >= 32u && ch <= 126u) {
            if (name_index < NAME_MAX_LEN) {
                name_temp[name_index] = (char)ch;
                name_index++;
                name_temp[name_index] = '\0';
								
								/* show typed character in SSH/TeraTerm */
                UartPutc(ch);

                /* show typed character on VGA */
                printf("%c", ch);
            }
        }
    }
}

/*
 * 7-segment display support.
 *
 * The turn timer value is split into decimal digits and written to the
 * four 7-segment display registers.
 */
static void seg7_show_number(uint16_t value)
{
    uint8_t d1 = (uint8_t)(value % 10u);
    uint8_t d2 = (uint8_t)((value / 10u) % 10u);
    uint8_t d3 = (uint8_t)((value / 100u) % 10u);
    uint8_t d4 = (uint8_t)((value / 1000u) % 10u);

    *SEG7_DIGIT1 = (uint32_t)d1;
    *SEG7_DIGIT2 = (uint32_t)d2;
    *SEG7_DIGIT3 = (uint32_t)d3;
    *SEG7_DIGIT4 = (uint32_t)d4;
}

/*
 * Starts or resets the 30-second turn timer.
 * Called at game start and whenever the turn changes.
 */
static void start_turn_timer(void)
{
    turn_time_left = TURN_TIME_SEC;
    seg7_show_number(turn_time_left);
}

static void clear_board_array(void)
{
    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++) {
            board[r][c] = 0;
        }
    }
}

/*
 * VGA drawing functions.
 *
 * The board is drawn as a 6x7 grid.
 * Empty cells are black, Player 1 pieces are red, and Player 2 pieces
 * are green. The cursor color shows whose turn it is.
 */
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

/*
 * Displays current game status and updates LEDs.
 *
 * LED0 indicates Player 1's turn.
 * LED1 indicates Player 2's turn.
 * 0x55 indicates pause.
 * 0x0F / 0xF0 indicate Player 1 / Player 2 win.
 * 0xAA indicates draw.
 */
static void draw_status(void)
{
    if (!game_over) {
        if (game_paused) {
            printf("\nGAME PAUSED  press SPACE to resume  sw7 reset");
            write_LED(0x55);
            printf("  TIME=%u", (unsigned)turn_time_left);
            return;
        }

        if (current_player == PLAYER1) {
            printf("\n%s TURN  sw0-sw6", player_name[PLAYER1]);
            write_LED(0x01);
        } else {
            printf("\n%s TURN  sw0-sw6", player_name[PLAYER2]);
            write_LED(0x02);
        }

        printf("  TIME=%u", (unsigned)turn_time_left);
    } else {
        if (winner == PLAYER1) {
            printf("\n%s WIN  sw7 reset", player_name[PLAYER1]);
            write_LED(0x0F);
        } else if (winner == PLAYER2) {
            printf("\n%s WIN  sw7 reset", player_name[PLAYER2]);
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

/*
 * Core Connect Four game logic.
 *
 * drop_piece() places the current player's piece in the lowest available
 * row of the selected column.
 */
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

    while (rr >= 0 && rr < ROWS &&
           cc >= 0 && cc < COLS &&
           board[rr][cc] == player) {
        count++;
        rr += dr;
        cc += dc;
    }

    return count;
}

/*
 * Win detection algorithm.
 *
 * After a piece is dropped, the program checks four directions:
 * horizontal, vertical, diagonal down-right, and diagonal down-left.
 * A player wins when four connected pieces are found.
 */
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

/*
 * Draw detection.
 *
 * The game is a draw if the top row of every column is occupied and
 * no winner has been found.
 */
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

/*
 * Handles one complete column selection.
 *
 * This function drops the piece, redraws the board, checks for win/draw,
 * and advances to the next player if the game continues.
 */
static void handle_drop_column(int col)
{
    int row;

    if (col < 0 || col >= COLS)
        return;

    if (game_over)
        return;

    if (game_paused)
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

/*
 * Initializes or resets the game.
 *
 * This clears the board, resets player and pause state, configures GPIO
 * as input, clears pending GPIO interrupts, starts the turn timer, and
 * enables Timer, UART, and GPIO interrupts.
 */
static void game_init(void)
{
    clear_board_array();

    current_player = PLAYER1;
    cursor_col = 3;
    game_over = 0;
    winner = 0;
    game_paused = 0u;
	
		//change for multiple gpio interrupt switches
		gpio_set_input();
		last_switch_sample = (uint8_t)(read_GPIO() & 0xFFu);

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
    printf("\nSPACE in Tera Term -> pause/resume");
    printf("\nP1 = RED, P2 = GREEN");
    printf("\nBoth players use the same switches.");
    printf("\n30-second timer shown on 7-segment.");
    printf("\nTurn switch OFF before using it again.\n");

    entering_names = 1u;
    name_player = PLAYER1;
    name_index = 0u;
    name_temp[0] = '\0';
    uart_rx_head = 0u;
    uart_rx_tail = 0u;

    prompt_current_name();

    start_turn_timer();

		timer_init(Timer_Load_Value_For_One_Sec, Timer_Prescaler, 1);
		timer_irq_clear();
		timer_enable();

		gpio_irq_clear();

		NVIC_EnableIRQ(Timer_IRQn);
		NVIC_EnableIRQ(UART_IRQn);
		NVIC_EnableIRQ(GPIO_IRQn);
}

static void toggle_pause(void)
{
    if (entering_names || game_over)
        return;

    game_paused = (uint8_t)(!game_paused);

    draw_board();
    draw_status();
}

/*
 * GPIO interrupt service routine.
 *
 * GPIO hardware generates an interrupt when a switch turns ON.
 * SW0-SW6 are mapped to Connect Four columns 1-7.
 * SW7 requests a reset. The reset is deferred to the main loop using
 * reset_requested so that game_init() is not called directly inside
 * the interrupt. (Do not want to run a large function in interrupt)
 */
void GPIO_ISR(void)
{
    uint8_t sw;
    uint8_t rising;
	
		//Read current switch state from GPIO input register

	sw = (uint8_t)(read_GPIO() & 0xFFu);
    rising = (uint8_t)(sw & (uint8_t)(~last_switch_sample));
    last_switch_sample = sw;

    if (rising & SW_RESET_MASK) {
        gpio_irq_clear();
				reset_requested = 1;
        return;
    }

    if (game_over || game_paused || entering_names) {
        gpio_irq_clear();
        return;
    }

    if (sw & SW_COL0_MASK) {
        handle_drop_column(0);
    }
    else if (sw & SW_COL1_MASK) {
        handle_drop_column(1);
    }
    else if (sw & SW_COL2_MASK) {
        handle_drop_column(2);
    }
    else if (sw & SW_COL3_MASK) {
        handle_drop_column(3);
    }
    else if (sw & SW_COL4_MASK) {
        handle_drop_column(4);
    }
    else if (sw & SW_COL5_MASK) {
        handle_drop_column(5);
    }
    else if (sw & SW_COL6_MASK) {
        handle_drop_column(6);
    }
	

    gpio_irq_clear();
}

/*
 * UART interrupt service routine.
 *
 * Reads one received character from UART and stores it in the receive
 * buffer. The main loop processes the character later.
 */
void UART_ISR(void)
{
    uint8_t ch;

    ch = (uint8_t)UartGetc();
    uart_rx_push(ch);
}

/*
 * Timer interrupt service routine.
 *
 * Decrements the current player's turn timer once per second.
 * If the timer reaches zero, the game automatically switches to the
 * next player and restarts the turn timer.
 */
void Timer_ISR(void)
{
    if (!game_over && !entering_names && !game_paused) {
        if (turn_time_left > 0u) {
            turn_time_left--;
            seg7_show_number(turn_time_left);
        }

        if (turn_time_left == 0u) {
            printf("\nTIME OUT -> next player");
            next_player();
            draw_status();
            draw_board();
        }
    }

    timer_irq_clear();
}

/*
 * Main program loop.
 *
 * The game is initialized once, then the CPU repeatedly processes
 * buffered UART input and handles deferred reset requests. __WFI()
 * puts the processor to sleep until the next interrupt occurs.
 */
int main(void)
{
    SoC_init();
    game_init();

    while (1) {
			process_uart_name_input();

			if (reset_requested) {
					reset_requested = 0;
					game_init();
			}

			__WFI();
		}
}
