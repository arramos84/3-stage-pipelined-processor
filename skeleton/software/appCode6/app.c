#include "types.h"

#define UART_TX_READY  (*((volatile uint32_t*)0x80000000) & 0x01)
#define UART_RX_VALID  (*((volatile uint32_t*)0x80000004) & 0x01)
#define UART_RX_DATA   (*((volatile uint32_t*)0x80000008))
#define CYCLE_COUNT    (*((volatile uint32_t*)0x80000010))
#define INST_COUNT     (*((volatile uint32_t*)0x80000014))
#define RESET_COUNTERS (*((volatile uint32_t*)0x80000018))
#define PF_CUR_FRAME   (*((volatile uint32_t*)0x8000001C))
#define PF_NEXT_FRAME  (*((volatile uint32_t*)0x80000020))
#define GP_FRAME       (*((volatile uint32_t*)0x80000024))
#define GP_CODE        (*((volatile uint32_t*)0x80000028))

#define CODE0      ((volatile uint32_t*)0x10c00000)
#define CODE1      ((volatile uint32_t*)0x10c00000)

#define IN_IDX     (*((volatile uint32_t*)0x1FFF0000))
#define OUT_IDX    (*((volatile uint32_t*)0x1FFF0004))
#define STATE      (*((volatile uint32_t*)0x1FFF0008)) 
#define ADDONE       ((volatile uint32_t*)0x1FFF000C)
#define SW_RTC_MIN (*((volatile uint32_t*)0x1FFF0010))
#define SW_RTC_SEC (*((volatile uint32_t*)0x1FFF0014))
#define PRINTING   (*((volatile uint32_t*)0x1FFF0018))
#define BUFFER       ((volatile uint8_t*)0x1FFF001C)


#define BALL_DIAM 8
#define PADDLE_LEN 100
#define PADDLE_WIDTH 10
#define START_BALL_X 396
#define START_BALL_Y 296
#define START_PAD_1_X 50  
#define START_PAD_1_Y 250  // (Y_MAX / 2) - (PADDLE_LEN / 2)
#define START_PAD_2_X 749  
#define START_PAD_2_Y 250
#define X_MAX 800
#define Y_MAX 600
#define VEL_X 4
#define RESOLUTION 20 // of paddle movement
#define DELAY1 25000  // 25000
#define DELAY2 200000 // 200000
#define UP 2
#define IDLE 1
#define DOWN 0
#define P1 1
#define P2 2
#define P1_SCORE_X 300
#define P1_SCORE_Y 0
#define P2_SCORE_X 425
#define P2_SCORE_Y 0

#define UNIT_LEN 4
#define UNIT_WIDTH 4

typedef struct {
  uint32_t x;
  uint32_t y;
  uint32_t vX;
  uint32_t vY;
} ball;

typedef struct {
  uint32_t x;
  uint32_t y;
  uint32_t direction;
  uint32_t score;
} paddle;

uint32_t appBuffer;
uint32_t offset; 

//////////////////////////// FUNCTION DECLARATIONS /////////////////////
void inturruptsON();
void inturruptsOFF();

void fill(uint32_t color);
void hwline(uint32_t color, uint32_t X0, uint32_t Y0, uint32_t X1, uint32_t Y1);
void startGP();

void initializeGame(ball *aBall, paddle *p1, paddle *p2);

void updateFrame(uint32_t pY1, uint32_t pY2, uint32_t ballX, uint32_t ballY, ball *aBall, paddle *p1, paddle *p2);
void drawPaddle(uint32_t color, uint32_t y, uint32_t startX);
void drawBall(uint32_t color, ball *aBall);
void drawHalf (uint32_t color);
void drawScoreboard(paddle *p1, paddle *p2);
void draw0 (uint32_t color, uint32_t X, uint32_t Y);
void draw1 (uint32_t color, uint32_t X, uint32_t Y);
void draw2 (uint32_t color, uint32_t X, uint32_t Y);
void draw3 (uint32_t color, uint32_t X, uint32_t Y);

uint32_t isYInBounds(uint32_t y);
uint32_t isXInBounds(uint32_t x);
void ballInBounds(ball *aBall);

uint32_t isCollision(ball *aBall, paddle *p1, paddle *p2);

void calcBallPosition(ball *aBall, paddle *p1, paddle *p2);

////////////////////////////////////////////////////////////////////////



int32_t uread_int32(ball *aBall, paddle *p1, paddle *p2){
		uint32_t time1 = DELAY1;
		uint32_t time2 = DELAY2;

    while (!UART_RX_VALID){ // URECV_CTRL){
      time1 = time1 - 1;
      time2 = time2 - 1;

      if ( time2 == 0 ){
        p1->direction = IDLE;
        p2->direction = IDLE;
        time2 = DELAY2;
      }

			if ( time1 == 0 ) { 
        calcBallPosition(aBall,p1,p2);
        time1 = DELAY1;
      }
    }
    int32_t ch = STATE; //URECV_DATA;
    
    return ch;
}

typedef void (*entry_t)(void);

int main(void){
  appBuffer = (PF_CUR_FRAME==0x10400000) ? 0x10800000 : 0x10400000;
  offset = 0;
  uint32_t address = 0x40000000;
  uint32_t play = 1;
  uint32_t blue = 0x000099; //black = 0x0;
  uint32_t gold = 0xffff00; //white = 0xffffff;

  ball myBall;
  paddle p1;
  paddle p2;

  int32_t input;

  p1.score = 0;
  p2.score = 0;
  initializeGame(&myBall, &p1, &p2);
  updateFrame(p1.y, p2.y, myBall.x, myBall.y, &myBall, &p1, &p2);

  inturruptsON();
  while (play) // game loop
  {
/*    
    int loop = 0;
	  while(loop == 0){
		  switch(STATE) {
			  case '4': // LEFT
          left(pb);
				  startGP();
				  break;
        case '6': // RIGHT
				  right(pb);
				  startGP();
				  break;
			  case '8': // UP
				  up(pb);
				  startGP();
				  break;
			  case '2': // DOWN
				  down(pb);
				  startGP();
				  break;
			  case 'x': // DOWN
				  loop++;
				  break;
      }
	  }
    inturruptsOFF();
*/  
  
    input = uread_int32(&myBall,&p1,&p2);

    if (STATE == 'q'){ // input == 'q'){
      play = 0;
    }
    else //if ( myBall.vX != 5 )
    { // start p1
      if (input == 's'){ // p1 up
        if( isYInBounds( p1.y - RESOLUTION ) ){
          //drawPaddle(blue,p1.y,START_PAD_1_X);
          p1.direction = UP;
          p1.y = p1.y - RESOLUTION;
        }
      }
      else if (input == 'z'){ // p1 down
        if( isYInBounds( p1.y + RESOLUTION ) ){
          //drawPaddle(blue,p1.y,START_PAD_1_X);
          p1.direction = DOWN;
          p1.y = p1.y + RESOLUTION;
        }
      }
    //} // end p1
    else 
    //{ // start p2
      if (input == 'k'){ // p2 up
        if( isYInBounds( p2.y - RESOLUTION ) ){
          //drawPaddle(blue,p2.y,START_PAD_2_X);
          p2.direction = UP;
          p2.y = p2.y - RESOLUTION;
        }
      }
      else if (input == 'm'){ // p2 down
        if( isYInBounds( p2.y + RESOLUTION ) ){
          //drawPaddle(blue,p2.y,START_PAD_2_X);
          p2.direction = DOWN;
          p2.y = p2.y + RESOLUTION;
        }
      }
    } //end p2

    calcBallPosition(&myBall, &p1, &p2);
  }

  entry_t start = (entry_t)(address);
  start();
  return 0;
}

/////////////////////////// INTURRUPTS /////////////////////////////////////

void inturruptsON(){
  IN_IDX = 0;
  OUT_IDX = 0;
  SW_RTC_MIN = 0;
  SW_RTC_SEC = 0;
  STATE = 0;
  PRINTING = 1;
    asm("mtc0 $0, $9");
    asm("nop");
    asm("la $k0, 0x00008c01");
    asm("nop");
    asm("mtc0 $k0, $12");
    asm("nop");
}

void inturruptsOFF(){
    asm("la $k0, 0x00008c00");
    asm("nop");
    asm("mtc0 $k0, $12");
    asm("nop");
}

////////////////////////////  GRAPHICS COMANDS ///////////////////////////

void fill(uint32_t color){
  *(CODE0 + offset++) = (0x01000000 | (0x00FFFFFF & color));
}

void hwline(uint32_t color, uint32_t X0, uint32_t Y0, uint32_t X1, uint32_t Y1){
  *(CODE0 + offset++) = (0x02000000 | (0x00FFFFFF & color));
  *(CODE0 + offset++) = ((X0 << 16) | Y0);
  *(CODE0 + offset++) = ((X1 << 16) | Y1);
}

void startGP(){
  *(CODE0 + offset) = 0x00000000;
  GP_FRAME = appBuffer;
	GP_CODE = 0x10c00000; 
	offset = 0; 
	STATE = 0;
	while(PF_CUR_FRAME!=appBuffer);
	appBuffer = (appBuffer==0x10400000) ? 0x10800000 : 0x10400000;
}

/////////////////////////// GAME INTIALIZATION ///////////////////////////////

void initializeGame(ball *aBall, paddle *p1, paddle *p2){
  uint32_t blue = 0x000099; //black = 0x0;
  uint32_t gold = 0xffff00; //white = 0xffffff;
  
  aBall->x = START_BALL_X;
  aBall->y = START_BALL_Y;
  aBall->vX = -VEL_X;
  aBall->vY = 0;

  p1->x = START_PAD_1_X;
  p1->y = START_PAD_1_Y;
  p1->direction = IDLE;

  p2->x = START_PAD_2_X;
  p2->y = START_PAD_2_Y;
  p2->direction = IDLE;

  if ( (p1->score == 4) || (p2->score == 4) ){
    p1->score = 0;
    p2->score = 0;
  }

  fill(blue);
  drawHalf(gold);
  drawScoreboard(p1,p2);
  drawPaddle(gold,START_PAD_1_Y,START_PAD_1_X);
  drawPaddle(gold,START_PAD_2_Y,START_PAD_2_X);
  drawBall(gold,aBall);
  startGP();
}

/////////////////////////// Draw Code ///////////////////////////////

void updateFrame(uint32_t pY1, uint32_t pY2, uint32_t ballX, uint32_t ballY, ball *aBall, paddle *p1, paddle *p2){
  uint32_t gold = 0xffff00; //white = 0xffffff;
  uint32_t blue = 0x000099; //black = 0x0;
  
  drawHalf(gold);
  drawScoreboard(p1,p2);
  drawPaddle(gold,pY1,START_PAD_1_X);
  drawPaddle(gold,pY2,START_PAD_2_X);
  drawBall(gold,aBall);
  startGP();
}

void drawPaddle(uint32_t color, uint32_t y, uint32_t startX){
  uint32_t gold = 0xffff00; //gold = 0xffffff;
  uint32_t blue = 0x000099; //black = 0x0;
 
  uint32_t yEnd = y+PADDLE_LEN;

  for (uint32_t i = 0; i < PADDLE_WIDTH; i++){
    hwline(color, startX+i, y, startX+i, yEnd);
  }
}

void drawBall(uint32_t color, ball *aBall){
  uint32_t x = aBall->x;
  uint32_t y = aBall->y;

  for (uint32_t i = 0; i < BALL_DIAM; i++)  {
    hwline(color, x+i, y, x+i, y+BALL_DIAM);
  }
}

void drawHalf (uint32_t color){
		for (uint32_t Y = 5; Y<600; Y = Y + 30) {
			for (uint32_t X = 398; X<403; X++) {
				hwline(color,X,Y,X,Y+15);
			}
		}
}

void drawScoreboard(paddle *p1, paddle *p2){
  uint32_t gold = 0xffff00; //white = 0xffffff;

  if ( p1->score == 0 )
    draw0(gold,P1_SCORE_X,P1_SCORE_Y);
  else if ( p1->score == 1 )
    draw1(gold,P1_SCORE_X,P1_SCORE_Y); 
  else if ( p1->score == 2 )
    draw2(gold,P1_SCORE_X,P1_SCORE_Y);
  else if ( p1->score == 3 )
    draw3(gold,P1_SCORE_X,P1_SCORE_Y);
  if ( p2->score == 0 )
    draw0(gold,P2_SCORE_X,P2_SCORE_Y);
  else if ( p2->score == 1 )
    draw1(gold,P2_SCORE_X,P2_SCORE_Y); 
  else if ( p2->score == 2 )
    draw2(gold,P2_SCORE_X,P2_SCORE_Y);
  else if ( p2->score == 3 )
    draw3(gold,P2_SCORE_X,P2_SCORE_Y);
}

void draw0 (uint32_t color, uint32_t X, uint32_t Y){
		for (uint32_t i = 25; i<50; i++) {
			for (uint32_t j = 10; j<15; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 25; i<30; i++) {
			for (uint32_t j = 10; j<50; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 25; i<50; i++) {
			for (uint32_t j = 45; j<50; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 45; i<50; i++) {
			for (uint32_t j = 10; j<50; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
}

void draw1 (uint32_t color, uint32_t X, uint32_t Y){
		for (uint32_t i = 35; i<40; i++) {
			hwline(color,X+i,Y+10,X+i,Y+50);
		}
		for (uint32_t i = 30; i<35; i++) {
			for (uint32_t j = 10; j<15; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
}

void draw2 (uint32_t color, uint32_t X, uint32_t Y){
		for (uint32_t i = 25; i<45; i++) {
			for (uint32_t j = 10; j<15; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 45; i<50; i++) {
			for (uint32_t j = 15; j<30; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}	
		for (uint32_t i = 28; i<45; i++) {
			for (uint32_t j = 25; j<30; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}

		for (uint32_t i = 25; i<30; i++) {
			for (uint32_t j = 30; j<50; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 30; i<50; i++) {
			for (uint32_t j = 45; j<50; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
}

void draw3 (uint32_t color, uint32_t X, uint32_t Y){
		for (uint32_t i = 25; i<45; i++) {
			for (uint32_t j = 10; j<15; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 30; i<45; i++) {
			for (uint32_t j = 28; j<32; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 25; i<45; i++) {
			for (uint32_t j = 45; j<50; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
		for (uint32_t i = 45; i<50; i++) {
			for (uint32_t j = 15; j<45; j++) {
				hwline(color,X+i,Y+j,X+i,Y+j);
			}
		}
}

/////////////////////////// Boundary Check ///////////////////////////////

// is paddle in bounds?
uint32_t isYInBounds(uint32_t y){
  if ( (y > (Y_MAX-PADDLE_LEN-RESOLUTION)) || (y < RESOLUTION) )
    return 0;
  else
    return 1;
}

// is ball in bounds?
uint32_t isXInBounds(uint32_t x){
  if ( ((x+BALL_DIAM) > (X_MAX-10)) || (x < 10) )
    return 0;
  else
    return 1;
}

void ballInBounds(ball *aBall){
  if ( (aBall->y > (Y_MAX-BALL_DIAM)) || (aBall->y < 5) ) {
    aBall->vY = -aBall->vY;
  }
}

////////////////////////////// Collision Check /////////////////////////////

uint32_t isCollision(ball *aBall, paddle *p1, paddle *p2){
  uint32_t paddleEdge1 = START_PAD_1_X + PADDLE_WIDTH;
  uint32_t paddleLowerEdge1 = p1->y + PADDLE_LEN;
  uint32_t paddleEdge2 = START_PAD_2_X;
  uint32_t paddleLowerEdge2 = p2->y + PADDLE_LEN;

  uint32_t verticalP1 = ((aBall->y + BALL_DIAM) > p1->y) && (aBall->y < paddleLowerEdge1);
  uint32_t verticalP2 = ((aBall->y + BALL_DIAM) > p2->y) && (aBall->y < paddleLowerEdge2);
  uint32_t horizontalP1 = aBall->x <= paddleEdge1;
  uint32_t horizontalP2 = aBall->x + BALL_DIAM >= paddleEdge2;

	if ( aBall->x < 400 ){
    if ( horizontalP1 && verticalP1 ){
      return P1;
    } else return 0;
  } else if ( horizontalP2 && verticalP2 ){
      return P2;
    } else return 0;
}

///////////////////////////// Position Calculation ///////////////////////////

void calcBallPosition(ball *aBall, paddle *p1, paddle *p2){
  uint32_t collisionType = isCollision(aBall,p1,p2);
  uint32_t blue = 0x000099; //black = 0x0;

  if (collisionType == P1){
    if( p1->direction == UP ) {
      aBall->vY = aBall->vY - 1;
      aBall->vX = -aBall->vX;
    } 
    else if( p1->direction == DOWN ) {
      aBall->vY = aBall->vY + 1;
      aBall->vX = -aBall->vX;
    }
    else if( p1->direction == IDLE ) {
      aBall->vY = aBall->vY;
      aBall->vX = -aBall->vX;
    }
  } 
  else if (collisionType == P2){
    if( p2->direction == UP ) {
      aBall->vY = aBall->vY - 1;
      aBall->vX = -aBall->vX;
    } 
    else if( p2->direction == DOWN ) {
      aBall->vY = aBall->vY + 1;
      aBall->vX = -aBall->vX;
    }
    else if( p2->direction == IDLE ) {
      aBall->vY = aBall->vY;
      aBall->vX = -aBall->vX;
    }
  }

  ballInBounds(aBall);

  // erase ball
  drawBall(blue,aBall);  

  // calculate new positions
  aBall->x = aBall->x + aBall->vX;
  aBall->y = aBall->y + aBall->vY;
  
  updateFrame(p1->y, p2->y, aBall->x, aBall->y, aBall, p1, p2);

  if ( !isXInBounds( aBall->x ) ) {

    if ( aBall->vX == VEL_X ) {
      p1->score = p1->score + 1;
    } else p2->score = p2->score + 1;

    initializeGame(aBall, p1, p2);
  }
}

