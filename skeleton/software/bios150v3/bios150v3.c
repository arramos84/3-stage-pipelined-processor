#include "ascii.h"
#include "uart.h"
#include "string.h"
#include "memory.h"
#include "graphics.h"

#define UTRAN_CTRL (*((volatile uint32_t*)0x80000000) & 0x01)
#define UTRAN_CTRL_RX (*((volatile uint32_t*)0x8000000c) & 0x01)

#define UTRAN_DATA (*((volatile uint32_t*)0x80000008))

#define IN_IDX (*((volatile uint32_t*)0x1FFF0000))
#define OUT_IDX (*((volatile uint32_t*)0x1FFF0004))

#define STATE ((volatile uint32_t*)0x1FFF0008) 
#define ADDONE ((volatile uint32_t*)0x1FFF000C)
#define SW_RTC_MIN (*((volatile uint32_t*)0x1FFF0010))
#define SW_RTC_SEC (*((volatile uint32_t*)0x1FFF0014))

#define BUFFER ((volatile uint8_t*)0x1FFF001C)
#define UART_BUFFER_LEN 2048

#define CYCLECOUNT (*((volatile uint32_t*)0x80000010))
#define STRLEN 32
#define HUNDREDMILLION 100000000

#define PRINTING (*((volatile uint32_t*)0x1FFF0018))

#define FRAME_BUFFER0 ((volatile uint32_t*)0x10400000)
#define FRAME_BUFFER1 ((volatile uint32_t*)0x10800000)
#define FRAME_BUFFER2 ((volatile uint32_t*)0x10c00000)

#define BUFFER_LEN 128


typedef void (*entry_t)(void);


int8_t* read_n(int8_t*b, uint32_t n);
int8_t* read_token(int8_t* b, uint32_t n, int8_t* ds);
void store(uint32_t address, uint32_t length);
void line(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

int main(void){    

    uwrite_int8s("\r\n");

    for ( ; ; ) {
        uwrite_int8s("CP4> ");

        int8_t buffer[BUFFER_LEN];
        int8_t* input = read_token(buffer, BUFFER_LEN, " \x0d");

        if (strcmp(input, "file") == 0) {
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t file_length = ascii_dec_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            store(address, file_length);
        } else if (strcmp(input, "jal") == 0) {
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));

            entry_t start = (entry_t)(address);
            start();
        } else if (strcmp(input, "lw") == 0) {
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            volatile uint32_t* p = (volatile uint32_t*)(address);

            uwrite_int8s(uint32_to_ascii_hex(address, buffer, BUFFER_LEN));
            uwrite_int8s(":");
            uwrite_int8s(uint32_to_ascii_hex(*p, buffer, BUFFER_LEN));
            uwrite_int8s("\r\n");
        } else if (strcmp(input, "lhu") == 0) {
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            volatile uint16_t* p = (volatile uint16_t*)(address);

            uwrite_int8s(uint32_to_ascii_hex(address, buffer, BUFFER_LEN));
            uwrite_int8s(":");
            uwrite_int8s(uint16_to_ascii_hex(*p, buffer, BUFFER_LEN));
            uwrite_int8s("\r\n");
        } else if (strcmp(input, "lbu") == 0) {
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            volatile uint8_t* p = (volatile uint8_t*)(address);

            uwrite_int8s(uint32_to_ascii_hex(address, buffer, BUFFER_LEN));
            uwrite_int8s(":");
            uwrite_int8s(uint8_to_ascii_hex(*p, buffer, BUFFER_LEN));
            uwrite_int8s("\r\n");
        } else if (strcmp(input, "sw") == 0) {
            uint32_t word = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));

            volatile uint32_t* p = (volatile uint32_t*)(address);
            *p = word;
        } else if (strcmp(input, "sh") == 0) {
            uint16_t half = ascii_hex_to_uint16(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));

            volatile uint16_t* p = (volatile uint16_t*)(address);
            *p = half;
        } else if (strcmp(input, "sb") == 0) {
            uint8_t byte = ascii_hex_to_uint8(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t address = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));

            volatile uint8_t* p = (volatile uint8_t*)(address);
            *p = byte;
        } 
        //TODO: your job to fill in your calls to these commands
        else if(strcmp(input, "swline") == 0) {
            uint32_t color = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t X0 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t Y0 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t X1 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t Y1 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t buffAddr = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d")); 
            swline(color,X0,Y0,X1,Y1,buffAddr);
            
        } 
        else if (strcmp(input, "hwline") == 0) {
            uint32_t color = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t X0 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t Y0 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t X1 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t Y1 = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t buffAddr = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            hwline(color,X0,Y0,X1,Y1,buffAddr);
        } 
        else if (strcmp(input, "fill") == 0) {
            uint32_t color = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t buffAddr = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            fill(color, buffAddr);
        } 
        else if (strcmp(input, "swfill") == 0) {
            uint32_t color = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            uint32_t buffAddr = ascii_hex_to_uint32(read_token(buffer, BUFFER_LEN, " \x0d"));
            swfill(color, buffAddr);
        } 
        else {
            uwrite_int8s("Error: Unrecognized command\n\r");
        }
    }
    return 0;
}

int8_t* read_n(int8_t*b, uint32_t n) {
    for (uint32_t i = 0; i < n;  i++) {
        b[i] =  uread_int8();
    }
    b[n] = '\0';
    return b;
}

int8_t* read_token(int8_t* b, uint32_t n, int8_t* ds){
    for (uint32_t i = 0; i < n; i++) {
        int8_t ch = uread_int8();
        for (uint32_t j = 0; ds[j] != '\0'; j++) {
            if (ch == ds[j]) {
                b[i] = '\0';
                return b;
            }
        }
        b[i] = ch;
    }
    b[n - 1] = '\0';
    return b;
}

void store(uint32_t address, uint32_t length){
    for (uint32_t i = 0; i*4 < length; i++) {
        int8_t buffer[9];
        int8_t* ascii_instruction = read_n(buffer,8);
        volatile uint32_t* p = (volatile uint32_t*)(address+i*4);
        *p = ascii_hex_to_uint32(ascii_instruction);
    }
}

