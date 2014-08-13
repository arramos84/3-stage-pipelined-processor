#include "types.h"

#define STATE ((volatile uint32_t*)0x1FFF0008) 
#define FRAME_BUFFER0 ((volatile uint32_t*)0x10400000)
#define FRAME_BUFFER1 ((volatile uint32_t*)0x10800000)
#define CODE0 ((volatile uint32_t*)0x10c00000)
#define CODE1 ((volatile uint32_t*)0x10e00000)
#define PF_BUFFER (*((volatile uint32_t*)0x80000018))

void fill(uint32_t color, uint32_t buffAddr){
  volatile uint32_t* p1 = (volatile uint32_t*)(0x10c00000);
  volatile uint32_t* p2 = (volatile uint32_t*)(0x10c00004);
  uint32_t* GP_FRAME = (uint32_t*)(0x80000020);
  uint32_t* GP_CODE = (uint32_t*)(0x80000024);
  *p1 = (0x01000000 | (0x00FFFFFF & color));
  *p2 = 0x00000000;
  *GP_FRAME = buffAddr;
  *GP_CODE = 0x10c00000;
}

void hwline(uint32_t color, uint32_t X0, uint32_t Y0, uint32_t X1, uint32_t Y1, uint32_t buffAddr){
  volatile uint32_t* p1 = (volatile uint32_t*)(0x10c00000);
  volatile uint32_t* p2 = (volatile uint32_t*)(0x10c00004);
  volatile uint32_t* p3 = (volatile uint32_t*)(0x10c00008);
  volatile uint32_t* p4 = (volatile uint32_t*)(0x10c0000c);
  uint32_t* GP_FRAME = (uint32_t*)(0x80000020);
  uint32_t* GP_CODE = (uint32_t*)(0x80000024);
  *p1 = (0x02000000 | (0x00FFFFFF & color));
  *p2 = ((X0 << 16) | Y0);
  *p3 = ((X1 << 16) | Y1);
  *p4 = 0x00000000;
  *GP_FRAME = buffAddr;
  *GP_CODE = 0x10c00000;  
}

void swfill(uint32_t color, uint32_t buffAddr){
  for(int y=0; y<600; y++){
    for(int x=0; x<800; x++){
      volatile uint32_t* p = (volatile uint32_t*)(buffAddr+(((1024*y)+x)*4));
      *p = color; 
    }
  }
}

//utility methods
void swap(int* a, int* b){
  int tmp = *a;
  *a = *b;
  *b = tmp;
}

uint16_t abs(int a){
   if (a < 0)
       return -a;
   return a;
}

void store_pixel(uint32_t color, int x, int y, uint32_t buffAddr)
{
  uint32_t addr = (buffAddr + (((1024*y)+x)*4));
  volatile uint32_t* p = (volatile uint32_t*)(addr);
  *p = color;
}

/* Based on wikipedia implementation 
 * TODO: modify this and its interface to be compatible with your design
*/
void swline(uint32_t color, int x0, int y0, int x1, int y1, uint32_t buffAddr){
  char steep = (abs(y1-y0) > abs(x1-x0)) ? 1 : 0; 
  if(steep) {
    swap(&x0, &y0);
    swap(&x1, &y1);
  }
  if( x0 > x1 ) {
    swap(&x0, &x1);
    swap(&y0, &y1);
  }
  int deltax = x1 - x0;
  int deltay = abs(y1-y0);
  int error = deltax / 2;
  int ystep;
  int y = y0;
  int x;
  ystep = (y0 < y1) ? 1 : -1;
  for( x = x0; x <= x1; x++ ) {
    if(steep)
      store_pixel(color, y, x, buffAddr);
    else
      store_pixel(color, x, y, buffAddr);
    error = error - deltay;
    if( error < 0 ) {
      y += ystep;
      error += deltax;
    }
  }
}

