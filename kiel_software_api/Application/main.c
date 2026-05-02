//backup
////--------------------------------------------------------
//// Application demonstrator: SNAKE game
////--------------------------------------------------------


//#include "EDK_CM0.h" 
//#include "core_cm0.h"
//#include "edk_driver.h"
//#include "edk_api.h"

//#include <stdio.h>

////Maximum snake length
//#define N 200							

////Game region
//#define left_boundary 5
//#define right_boundary 96
//#define top_boundary 5
//#define bottom_boundary 116
//#define boundary_thick 1

////Global variables
//static int i;
//static char key;
//static int score;
//static int pause;
//static int snake_has_moved;

//static int gamespeed;
//static int speed_table[10]={6,9,12,15,20,25,30,35,40,100};

//// Structure define
//struct target{
//	int x;
//	int y;
//	int reach;
//	}target;

//struct Snake{
//	int x[N];
//	int y[N];
//	int node;
//	int direction;
//	}snake;


////---------------------------------------------
//// Game
////---------------------------------------------


//void Game_Init(void)
//{	
//	//Draw a game region
//	clear_screen();
//	rectangle(left_boundary,top_boundary,right_boundary,top_boundary+boundary_thick,BLUE);
//	rectangle(left_boundary,top_boundary,left_boundary+boundary_thick,bottom_boundary,BLUE);
//	rectangle(left_boundary,bottom_boundary,right_boundary,bottom_boundary+boundary_thick,BLUE);
//	rectangle(right_boundary,top_boundary,right_boundary+boundary_thick,bottom_boundary+boundary_thick,BLUE);	

//	//Initialise data
//	
//	score=0;
//	gamespeed=speed_table[score];		
//	
//	//Initialise timer (load value, prescaler value, mode value)
//	timer_init((Timer_Load_Value_For_One_Sec/gamespeed),Timer_Prescaler,1);	
//	timer_enable();
//	
//	target.reach=1;
//	snake.direction=1;
//	snake.x[0]=60;snake.y[0]=80;
//	snake.x[1]=62;snake.y[1]=80;
//	snake.node=4;
//	pause=0;
//	
//	//Print instructions
//	printf("\n\n-------- EDK Demo ---------");
//	printf("\n------- Snake Game --------");
//  printf("\nCentre btn ..... hard reset");
//  printf("\nKeyboard r ..... soft reset");
//  printf("\nKeyboard w ........ move up");
//  printf("\nKeyboard s ...... move down");
//  printf("\nKeyboard a ...... move left");
//  printf("\nKeyboard d ..... move right");
//  printf("\nKeyboard space ...... pause");
//  printf("\n---------------------------");	
//	printf("\nTo ran the game, make sure:");
//	printf("\n*UART terminal is activated");
//	printf("\n*UART baud rare:  19200 bps");
//	printf("\n*Keyboard is in lower case");
//  printf("\n---------------------------");
//	printf("\nPress any key to start\n");	
//	while(KBHIT()==0);
//		
//	printf("\nScore=%d\n",score);
//	
//	NVIC_EnableIRQ(Timer_IRQn);			//start timing
//	NVIC_EnableIRQ(UART_IRQn);	
//}


//void Game_Close(void){
//	clear_screen();
//	score=0;
//	printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");		//flush screen
//	printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
//	NVIC_DisableIRQ(Timer_IRQn);			
//	NVIC_DisableIRQ(UART_IRQn);	
//}

////Generate a random target using system tick as seed
//void target_gen(void){
//		target.x= (char)random(left_boundary+boundary_thick+1,right_boundary-2);
//		target.x=target.x-target.x%2;
//		delay(111*target.x);
//		target.y= (char)random(top_boundary+boundary_thick+1,bottom_boundary-2);
//		target.y=target.y-target.y%2;
//		target.reach=0;	
//}
//	
//int GameOver(void){
//	char key;
//	
//	NVIC_DisableIRQ(UART_IRQn);
//	NVIC_DisableIRQ(Timer_IRQn);
//	printf("\nGame over\n");
//	printf("\nPress 'q' to quit");
//	printf("\nPress 'r' to replay");
//	while(1){
//		while(KBHIT()==0);
//		key = UartGetc();
//		if (key == RESET){
//			return 1;
//		}
//		else if (key == QUIT){	
//			return 0;
//		}
//		else
//			printf("\nInvalid input");
//	}
//		
//}






////---------------------------------------------
//// UART ISR -- used to input commands
////---------------------------------------------

//void UART_ISR(void)
//{	

//  key=UartGetc();	
//	
//	//Only update the direction if the previous movement is finished
//	if(snake_has_moved==1){			
//				if(key==UP&&snake.direction!=4)
//					snake.direction=3;
//				else
//					if(key==RIGHT&&snake.direction!=2)
//						snake.direction=1;
//					else
//						if(key==LEFT&&snake.direction!=1)
//							snake.direction=2;
//						else
//							if(key==DOWN&&snake.direction!=3)
//								snake.direction=4;
//		}
//		if(key==PAUSE){
//				if(pause==0){
//						pause=1;
//						NVIC_DisableIRQ(Timer_IRQn);	
//				}
//				else{
//						pause =0;
//						NVIC_EnableIRQ(Timer_IRQn);
//				}
//		}
//		
//		snake_has_moved=0;
//		
//}
// 

////---------------------------------------------
//// TIMER ISR -- used to move the snake
////---------------------------------------------


//void Timer_ISR(void)
//{
//	
//	int overlap;

//	// If game is not paused
//	if(pause==0){
//		
//			//If target is reached, generate a new one
//			if(target.reach==1){

//				//Generate a new target address that is not overlapped with the snake
//				do{
//					overlap=0;
//					target_gen();
//					for(i=0;i<snake.node;i++){
//						if(snake.x[i]==target.x&&snake.y[i]==target.y){
//							overlap=1;
//							break;
//						}
//					}
//				}while(overlap==1);
//					
//				//Draw the target
//				rectangle(target.x,target.y,target.x+2,target.y+2,GREEN);
//				//Update the game speed (maximum 10 levels)	
//			}
//			
//			//Shift the snake
//			for(i=snake.node-1;i>0;i--){
//				snake.x[i]=snake.x[i-1];
//				snake.y[i]=snake.y[i-1];
//			}
//			
//			switch(snake.direction){
//				case 1:snake.x[0]+=2;break;
//				case 2: snake.x[0]-=2;break;
//				case 3: snake.y[0]-=2;break;
//				case 4: snake.y[0]+=2;break;
//			}
//			
//			//Detect if the snake reaches the target
//			if(snake.x[0]==target.x&&snake.y[0]==target.y){
//				rectangle(target.x,target.y,target.x+2,target.y+2,BLACK);
//				snake.x[snake.node]=-10;snake.y[snake.node]=-10;
//				snake.node++;
//				target.reach=1;
//				score+=1;				
//				if (score<=10)
//					gamespeed=speed_table[score];	
//				timer_init((Timer_Load_Value_For_One_Sec/gamespeed),Timer_Prescaler,1);	
//				timer_enable();
//				write_LED(score);
//				printf("\nScore=%d\n",score);
//			}
//			
//			//Detect if the snake hits itself
//			for(i=3;i<snake.node;i++){
//				if(snake.x[i]==snake.x[0]&&snake.y[i]==snake.y[0]){
//					if (GameOver()==0)
//						Game_Close();
//					else
//						Game_Init();
//				}
//			}
//			
//			//Detect if the snake hits the boundry
//			if(snake.x[0]<left_boundary+boundary_thick||snake.x[0]>=right_boundary||snake.y[0]<top_boundary+boundary_thick||snake.y[0]>=bottom_boundary){
//				if (GameOver()==0){
//					Game_Close();
//					return;
//				}
//				else{
//					Game_Init();
//					return;
//				}
//			}		
//			
//			//Move the snake
//			for(i=0;i<snake.node;i++)
//				rectangle(snake.x[i],snake.y[i],snake.x[i]+2,snake.y[i]+2,RED);
//				rectangle(snake.x[snake.node-1],snake.y[snake.node-1],snake.x[snake.node-1]+2,snake.y[snake.node-1]+2,BLACK);

//		}
//		
//	// Mark that snake has moved
//	snake_has_moved=1;

//	//Display the total distance that the snake has moved
//	Display_Int_Times();
//		
//	//Clear timer irq
//	timer_irq_clear();
//		
//}	

////---------------------------------------------
//// Main Function
////---------------------------------------------


//int main(void){

//	//Initialise the system
//	SoC_init();
//	//Initialise the game
//	Game_Init();
//	
//	//Go to sleep mode and wait for interrupts
//	while(1)
//		__WFI();	
//	

//}

//--------------------------------------------------------
// Application demonstrator: SNAKE game
//--------------------------------------------------------


#include "EDK_CM0.h" 
#include "core_cm0.h"
#include "edk_driver.h"
#include "edk_api.h"

#include <stdio.h>

//Maximum snake length
#define N 200							

//Game region
#define left_boundary 5
#define right_boundary 96
#define top_boundary 5
#define bottom_boundary 116
#define boundary_thick 1

//Global variables
//static int i;
static unsigned char key;
static int score_p1;
static int score_p2;
static int pause;
static int snake1_has_moved;
static int snake2_has_moved;

static int gamespeed;
static int speed_table[10]={6,9,12,15,20,25,30,35,40,100};

// Structure define
struct target{
	int x;
	int y;
	int reach;
	}target;

typedef struct {
	int x[N];
	int y[N];
	int node;
	int direction;
	}Snake;

//Two instances of snakes
Snake snake1;
Snake snake2;


//---------------------------------------------
// Game
//---------------------------------------------


void Game_Init(void)
{	
	//Draw a game region
	clear_screen();
	rectangle(left_boundary,top_boundary,right_boundary,top_boundary+boundary_thick,BLUE);
	rectangle(left_boundary,top_boundary,left_boundary+boundary_thick,bottom_boundary,BLUE);
	rectangle(left_boundary,bottom_boundary,right_boundary,bottom_boundary+boundary_thick,BLUE);
	rectangle(right_boundary,top_boundary,right_boundary+boundary_thick,bottom_boundary+boundary_thick,BLUE);	

	//Initialise data
	score_p1 = 0;
	score_p2 = 0;
	gamespeed = speed_table[score_p1];

	//Initialise timer (load value, prescaler value, mode value)
	timer_init((Timer_Load_Value_For_One_Sec / gamespeed), Timer_Prescaler, 1);	
	timer_enable();

	target.reach = 1;

	/* Snake 1 initial state */
	snake1.direction = 1;
	snake1.node = 4;
	snake1.x[0] = 60; snake1.y[0] = 80;
	snake1.x[1] = 62; snake1.y[1] = 80;
	snake1.x[2] = 64; snake1.y[2] = 80;
	snake1.x[3] = 66; snake1.y[3] = 80;

	/* Snake 2 initial state */
	snake2.direction = 1;
	snake2.node = 4;
	snake2.x[0] = 20; snake2.y[0] = 80;
	snake2.x[1] = 22; snake2.y[1] = 80;
	snake2.x[2] = 24; snake2.y[2] = 80;
	snake2.x[3] = 26; snake2.y[3] = 80;

	snake1_has_moved = 1;
	snake2_has_moved = 1;
	pause = 0;

	//Print instructions
	printf("\n\n-------- EDK Demo ---------");
	printf("\n------- Snake Game --------");
	printf("\nCentre btn ..... hard reset");
	printf("\nKeyboard r ..... soft reset");
	printf("\nKeyboard w .......... P1 up");
	printf("\nKeyboard s ........ P1 down");
	printf("\nKeyboard a ........ P1 left");
	printf("\nKeyboard d ....... P1 right");
	printf("\nKeyboard i .......... P2 up");
	printf("\nKeyboard k ........ P2 down");
	printf("\nKeyboard j ........ P2 left");
	printf("\nKeyboard l ....... P2 right");
	printf("\nKeyboard space ...... pause");
	printf("\n---------------------------");	
	printf("\nTo run the game, make sure:");
	printf("\n*UART terminal is activated");
	printf("\n*UART baud rate: 19200 bps");
	printf("\n*Keyboard is in lower case");
	printf("\n---------------------------");
	printf("\nPress any key to start\n");

	while (KBHIT() == 0);

	printf("\nP1 Score=%d\n", score_p1);
	printf("\nP2 Score=%d\n", score_p2);

	NVIC_EnableIRQ(Timer_IRQn);			//start timing
	NVIC_EnableIRQ(UART_IRQn);	
}


void Game_Close(void){
	clear_screen();
	score_p1=0;
	printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");		//flush screen
	printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
	NVIC_DisableIRQ(Timer_IRQn);			
	NVIC_DisableIRQ(UART_IRQn);	
}

//Generate a random target using system tick as seed
void target_gen(void){
		target.x= random(left_boundary+boundary_thick+1,right_boundary-2);
		target.x=target.x-target.x%2;
		delay(111*target.x);
		target.y= random(top_boundary+boundary_thick+1,bottom_boundary-2);
		target.y=target.y-target.y%2;
		target.reach=0;	
}

//Helper function for displaying the winner
void Display_Winner(void)
{
    printf("\nFinal Score:");
    printf("\nPlayer 1 = %d", score_p1);
    printf("\nPlayer 2 = %d", score_p2);

    if (score_p1 > score_p2)
        printf("\nPlayer 1 wins!\n");
    else if (score_p2 > score_p1)
        printf("\nPlayer 2 wins!\n");
    else
        printf("\nIt is a draw!\n");
}

int GameOver(void){
	unsigned char game_key;
	
	NVIC_DisableIRQ(UART_IRQn);
	NVIC_DisableIRQ(Timer_IRQn);
	printf("\nGame over\n");
	printf("\nPress 'q' to quit");
	printf("\nPress 'r' to replay");

	while(1){
		while(KBHIT()==0);
		game_key = UartGetc();
		if (game_key == RESET){
			return 1;
		}
		else if (game_key == QUIT){	
			return 0;
		}
		else
			printf("\nInvalid input");
	}
}






//---------------------------------------------
// UART ISR -- used to input commands
//---------------------------------------------

//helper function
void update_direction(Snake *snake, int *snake_has_moved,
                      unsigned char up, unsigned char right,
                      unsigned char left, unsigned char down,
                      unsigned char key)
{
    if (*snake_has_moved == 1) {
        if (key == up && snake->direction != 4) {          // up
            snake->direction = 3;
            *snake_has_moved = 0;
        }
        else if (key == right && snake->direction != 2) { // right
            snake->direction = 1;
            *snake_has_moved = 0;
        }
        else if (key == left && snake->direction != 1) {  // left
            snake->direction = 2;
            *snake_has_moved = 0;
        }
        else if (key == down && snake->direction != 3) {  // down
            snake->direction = 4;
            *snake_has_moved = 0;
        }
    }
}

void UART_ISR(void)
{
    key = UartGetc();

    /* Player 1 controls: W A S D */
    update_direction(&snake1, &snake1_has_moved, W, D, A, S, key);

    /* Player 2 controls: I J K L */
    update_direction(&snake2, &snake2_has_moved, I, L, J, K, key);

    /* Pause control */
    if (key == PAUSE) {
        if (pause == 0) {
            pause = 1;
            NVIC_DisableIRQ(Timer_IRQn);
        }
        else {
            pause = 0;
            NVIC_EnableIRQ(Timer_IRQn);
        }
    }
}
 

//---------------------------------------------
// TIMER ISR -- used to move the snake
//---------------------------------------------

//Helper functions: 

// Checks if the target position overlaps with any segment of the given snake
int target_hits_snake(Snake *snake)
{
	int j;
	for (j = 0; j < snake->node; j++) {
		if (snake->x[j] == target.x && snake->y[j] == target.y)
			return 1;
	}
	return 0;
}


// Shifts all snake body segments forward to follow the head
void shift_snake(Snake *snake)
{
	int j;
	for (j = snake->node - 1; j > 0; j--) {
		snake->x[j] = snake->x[j - 1];
		snake->y[j] = snake->y[j - 1];
	}
}


// Moves the snake head one step based on its current direction
void move_snake_head(Snake *snake)
{
	switch (snake->direction) {
		case 1: snake->x[0] += 2; break;   // right
		case 2: snake->x[0] -= 2; break;   // left
		case 3: snake->y[0] -= 2; break;   // up
		case 4: snake->y[0] += 2; break;   // down
	}
}

// Checks if the snake's head collides with the other snake's body (excluding head)
int snake_hits_itself(Snake *snake)
{
	int j;
	for (j = 3; j < snake->node; j++) {
		if (snake->x[0] == snake->x[j] && snake->y[0] == snake->y[j])
			return 1;
	}
	return 0;
}

// Checks if the snake's head hits the game boundaries
int snake_hits_wall(Snake *snake)
{
	if (snake->x[0] < left_boundary + boundary_thick ||
		snake->x[0] >= right_boundary ||
		snake->y[0] < top_boundary + boundary_thick ||
		snake->y[0] >= bottom_boundary)
		return 1;

	return 0;
}

// Checks if the snake's head collides with the other snake's body
int snake_hits_other(Snake *snake, Snake *other)
{
    int j;

    for (j = 1; j < other->node; j++) {
        if (snake->x[0] == other->x[j] &&
            snake->y[0] == other->y[j]) {
            return 1;
        }
    }

    return 0;
}

// Draws all segments of the snake on the screen using the given color
void draw_snake(Snake *snake, int color)
{
	int j;
	for (j = 0; j < snake->node; j++) {
		rectangle(snake->x[j], snake->y[j],
		          snake->x[j] + 2, snake->y[j] + 2,
		          color);
	}
}
// Erases the last segment (tail) of the snake from the screen
void erase_snake_tail(Snake *snake)
{
	rectangle(snake->x[snake->node - 1], snake->y[snake->node - 1],
	          snake->x[snake->node - 1] + 2, snake->y[snake->node - 1] + 2,
	          BLACK);
}

void Timer_ISR(void)
{
	int overlap;
	int snake1_dead = 0;
	int snake2_dead = 0;
	int head_on_collision = 0;

	// If game is not paused
	if (pause == 0) {

		// If target is reached, generate a new one
		if (target.reach == 1) {
			do {
				overlap = 0;
				target_gen();

				if (target_hits_snake(&snake1))
					overlap = 1;

				if (overlap == 0 && target_hits_snake(&snake2))
					overlap = 1;

			} while (overlap == 1);

			// Draw the target
			rectangle(target.x, target.y, target.x + 2, target.y + 2, BLUE);
			target.reach = 0;
		}

		// Erase old tails
		erase_snake_tail(&snake1);
		erase_snake_tail(&snake2);

		// Shift both snakes
		shift_snake(&snake1);
		shift_snake(&snake2);

		// Move both snake heads
		move_snake_head(&snake1);
		move_snake_head(&snake2);

		// Check if snake1 eats target
		if (snake1.x[0] == target.x && snake1.y[0] == target.y) {
			rectangle(target.x, target.y, target.x + 2, target.y + 2, BLACK);
			snake1.x[snake1.node] = -10;
			snake1.y[snake1.node] = -10;
			snake1.node++;
			target.reach = 1;

			score_p1 += 1;
			if (score_p1 < 10)
				gamespeed = speed_table[score_p1];

			timer_init((Timer_Load_Value_For_One_Sec / gamespeed), Timer_Prescaler, 1);
			timer_enable();

			write_LED(score_p1);
			printf("\nP1 Score=%d\n", score_p1);
		}

		// Check if snake2 eats target
		if (snake2.x[0] == target.x && snake2.y[0] == target.y) {
			rectangle(target.x, target.y, target.x + 2, target.y + 2, BLACK);
			snake2.x[snake2.node] = -10;
			snake2.y[snake2.node] = -10;
			snake2.node++;
			target.reach = 1;

			score_p2 += 1;
			printf("\nP2 Score=%d\n", score_p2);
		}

		// ----------------------------------------
		// Collision detection
		// ----------------------------------------
		
		// Head-on collision: both heads meet at same position
		if (snake1.x[0] == snake2.x[0] && snake1.y[0] == snake2.y[0]) {
			head_on_collision = 1;
			snake1_dead = 1;
			snake2_dead = 1;
		}
		else {
			// Wall collisions
			if (snake_hits_wall(&snake1))
					snake1_dead = 1;

			if (snake_hits_wall(&snake2))
					snake2_dead = 1;

			// Self collisions (NEW — added here)
			if (snake_hits_itself(&snake1))
					snake1_dead = 1;

			if (snake_hits_itself(&snake2))
					snake2_dead = 1;

			// Collision with the other snake's body
			if (snake_hits_other(&snake1, &snake2))
					snake1_dead = 1;

			if (snake_hits_other(&snake2, &snake1))
					snake2_dead = 1;
		}

		// ----------------------------------------
		// Apply scoring and end game if needed
		// ----------------------------------------

		if (snake1_dead || snake2_dead) {

			if (head_on_collision) {
				// No bonus points for head-on collision
				printf("\nHead-on collision!\n");
			}
			else if (snake1_dead && !snake2_dead) {
				score_p2 += 5;
				printf("\nPlayer 1 died. Player 2 gets +5 points.\n");
			}
			else if (snake2_dead && !snake1_dead) {
				score_p1 += 5;
				printf("\nPlayer 2 died. Player 1 gets +5 points.\n");
			}

			Display_Winner();

			if (GameOver() == 0) {
				Game_Close();
			}
			else {
				Game_Init();
			}

			timer_irq_clear();
			return;
		}

		// Draw both snakes
		draw_snake(&snake1, RED);
		draw_snake(&snake2, GREEN);
	}

	// Mark that snakes have moved
	snake1_has_moved = 1;
	snake2_has_moved = 1;

	// Display the total distance that the snake has moved
	Display_Int_Times();

	// Clear timer irq
	timer_irq_clear();
}

//---------------------------------------------
// Main Function
//---------------------------------------------


int main(void){

	//Initialise the system
	SoC_init();
	//Initialise the game
	Game_Init();
	
	//Go to sleep mode and wait for interrupts
	while(1)
		__WFI();	
	

}



