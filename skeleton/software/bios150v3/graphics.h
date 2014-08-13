#ifndef GRAPHICS_H_
#define GRAPHICS_H_

#include "types.h"

//TODO: put your #defines for any addresses you may need here
//ex. #define LE_Y1 (*((volatile uint32_t*) 0x8000004c))

//TODO: modify these declarations as you need them
void fill(uint32_t color, uint32_t buffAddr);
void hwline(uint32_t color, uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1, uint32_t buffAddr);
void swline(uint32_t color, int X0, int Y0, int X1, int Y1, uint32_t buffAddr);
void swfill(uint32_t color, uint32_t buffAddr);

#endif
