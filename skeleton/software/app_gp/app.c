#include "types.h"

#define STATE (*((volatile uint32_t*)0x1FFF0008)) 
#define FRAME_BUFFER0 ((volatile uint32_t*)0x10400000)
#define FRAME_BUFFER1 ((volatile uint32_t*)0x10800000)
#define CODE_ADDR ((volatile uint32_t*)0x10c00000)
#define PF_BUFFER (*((volatile uint32_t*)0x80000018))
#define GP_FRAME (*((volatile uint32_t*)0x80000020))
#define GP_CODE (*((volatile uint32_t*)0x80000024))

uint32_t appBuffer;
uint32_t gpCodeOffset;

struct Point {
   int x;
   int y;
};

struct Line {
   Point p1,p2;
};

struct Box {
	Line l1,l2,l3,l4;
};

Box b = {{{50,50},{70,45}}, {{70,45},{65,65}}, {{45,70},{65,65}}, {{50,50},{45,70}}};


int main(void){
   appBuffer = 0x10800000;
   gpCodeOffset=0;
	fill(0x98FB98, appBuffer)
   drawbox(0,appBuffer);
	startGP();
   move(); 
	return 0;
}

void startGP(){
	GP_FRAME = appBuffer;
	GP_CODE = 0x10c00000;  
	STATE=0;
	appBuffer = (appBuffer==0x10400000) ? 0x10800000 : 10400000;
	gpCodeOffset=0;
	while(PF_BUFFER==appBuffer);
}

void drawBox(uint32_t color, uint32_t buffAddr){
   hwline(color, b.l1.p1.x, b.l1.p1.y, b.l1.p2.x, b.l1.p2.y, buffAddr);
	hwline(color, b.l2.p1.x,	b.l2.p1.y, b.l2.p2.x, b.l2.p2.y, buffAddr);
   hwline(color, b.l3.p1.x, b.l3.p1.y, b.l3.p2.x, b.l3.p2.y, buffAddr);
   hwline(color, b.l4.p1.x, b.l4.p1.y, b.l4.p2.x, b.l4.p2.y, buffAddr);
}

void move(){
   bool loop = true;
   inturruptsON();
	while(loop){
		switch(STATE) {
			case '4': // LEFT
            left();
				startGP();
				break;
         case '6': // RIGHT
				right();
				startGP();
				break;
			case '8': // UP
				up();
				startGP();
				break;
			case '2': // DOWN
				down();
				startGP();
				break;
			case 'x': // DOWN
				loop = false;
				break;
      }
	}
   inturruptsOFF();
}

void left(){
		
}

void right(){
		
}

void up(){
		
}

void down(){
		
}

void inturruptsON(){
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

void fill(uint32_t color){
  *(CODE_ADDR+gpCodeOffset) = (0x01000000 | (0x00FFFFFF & color));
  gpCodeOffset+=4
  *(CODE_ADDR+gpCodeOffset) = 0x00000000;
}

void hwline(uint32_t color, uint32_t X0, uint32_t Y0, uint32_t X1, uint32_t Y1){
  *(CODE_ADDR+gpCodeOffset) = (0x02000000 | (0x00FFFFFF & color));
  gpCodeOffset+=4
  *(CODE_ADDR+gpCodeOffset) = ((X0 << 16) | Y0);
  gpCodeOffset+=4
  *(CODE_ADDR+gpCodeOffset) = ((X1 << 16) | Y1);
  gpCodeOffset+=4
  *(CODE_ADDR+gpCodeOffset) = 0x00000000;
  gpCodeOffset+=4
}
