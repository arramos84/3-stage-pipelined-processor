#include "types.h"

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
#define BUFFER_LEN 2048

#define CYCLECOUNT (*((volatile uint32_t*)0x80000010))
#define STRLEN 32
#define HUNDREDMILLION 100000000

#define PRINTING (*((volatile uint32_t*)0x1FFF0018))


void r100M();
void add_one_R();
void v100M();
void add_one_V();

void out();
void convert(int, int);
uint8_t itoa(int);

int mul(int, int);
int div(int, int);
int mod(int, int);

uint8_t buf[32];
const uint8_t nums[16] = "0123456789";
uint8_t MINS_10;
uint8_t MINS_1;
uint8_t SECS_10;
uint8_t SECS_1;

int main(){
    unsigned int startTime;
    unsigned int endTime;
    unsigned int timeDiff;
    unsigned int ret_min, ret_sec;

    IN_IDX = 0;
    OUT_IDX = 0;
    SW_RTC_MIN = 0;
    SW_RTC_SEC = 0;
    *STATE = 0;
    PRINTING = 1;


    asm("mtc0 $0, $9");
    asm("nop");
    asm("la $k0, 0x00008c01");
    asm("nop");
    asm("mtc0 $k0, $12");
    asm("nop");

    while(1) {
        switch(*STATE) {
            case 'r': // register variable add
                startTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                r100M();
                endTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                timeDiff = endTime - startTime;
                ret_min = div(timeDiff,60);
                ret_sec = mod(timeDiff,60);
                convert(ret_min,ret_sec);
                out();
                break;
            case 'R': // register variable, plusone function call
                startTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                for(unsigned int i = 0; i < HUNDREDMILLION; i++){
                    add_one_R();
                }
                endTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                timeDiff = endTime - startTime;
                ret_min = div(timeDiff,60);
                ret_sec = mod(timeDiff,60);
                convert(ret_min,ret_sec);
                out();
                break;
            case 'v': // volatile variable, add
                startTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                v100M();
                endTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                timeDiff = endTime - startTime;
                ret_min = div(timeDiff,60);
                ret_sec = mod(timeDiff,60);
                convert(ret_min,ret_sec);
                out();
                break;
            case 'V': // volatile variable, plusone function call
                startTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                for(unsigned int i = 0; i < HUNDREDMILLION; i++){
                    add_one_V();
                }
                endTime = mul(SW_RTC_MIN,60) + SW_RTC_SEC;
                timeDiff = endTime - startTime;
                ret_min = div(timeDiff,60);
                ret_sec = mod(timeDiff,60);
                convert(ret_min,ret_sec);
                out();
                break;
        }
    }
}
int mul(int a, int b){
   int p=0;
   for(int i=0; i<b; i++){p+=a;}
   return p;
}

int div(int a, int b){
   int s=0;
   for(int i=a; i>=b; i-=b){s++;}
   return s; 
}
int mod(int a, int b){
    int m = a;
    while(m >= b){m-=b;}
    return m; 
}
void out(){
        buf[0] = '\n';
        buf[1] = '\t';
        buf[2] = 'M';
        buf[3] =  'o';
        buf[4] =  'd';
        buf[5] =  'e';       
	       buf[6] =  ':';
        buf[7] =  ' ';
        buf[8] =  *STATE;
        buf[9] =  ' '; 
        buf[10] = 'T';
        buf[11] = 'i';
        buf[12] = 'm';
        buf[13] = 'e';       
	       buf[14] = ':';
        buf[15] = ' ';      
	       buf[16] =  MINS_10; //nums[div(min,10)];
        buf[17] =  MINS_1; //nums[mod(min,10)];
        buf[18] = ':';
        buf[19] =  SECS_10; //nums[div(sec,10)];
        buf[20] =  SECS_1; //nums[mod(sec,10)];
        buf[21] = '\n';
        buf[22] = '\n';
        buf[23] = '\0';

    unsigned int str_idx = 0;
    if(UTRAN_CTRL){ 
        UTRAN_DATA = buf[str_idx];
        str_idx++;
    }
    while((BUFFER[IN_IDX] = buf[str_idx])){ 
        if(IN_IDX == BUFFER_LEN-1){
            IN_IDX = 0;
        }
        else {
            IN_IDX++;
        }
        str_idx++;
    }
    *STATE = 0;
}

void convert(int min, int sec){
    int m_1, m_10, s_1, s_10;
    m_10 = 0;
    m_1 = min;
    s_10 = 0;
    s_1 = sec;
    while(m_1 >=10){
       m_1 -= 10;
       m_10++;
    }
    MINS_10 = itoa(m_10);
    MINS_1 = itoa(m_1);
    while(s_1 >=10){
       s_1 -= 10;
       s_10++;
    }
    SECS_10 = itoa(s_10);
    SECS_1 = itoa(s_1);
}

uint8_t itoa(int i){
    switch(i){
        case(0):
            return '0';
        case(1):
            return '1';
        case(2):
            return '2';
        case(3):
            return '3';
        case(4):
            return '4';
        case(5):
            return '5';
        case(6):
            return '6';
        case(7):
            return '7';
        case(8):
            return '8';
        case(9):
            return '9';
        default:
            return '#';
    }

}


void r100M(){
    for(register int i = 0; i < HUNDREDMILLION; i++); 
}

void add_one_R(){
    register int add = 0;
    add++;
}

void v100M(){
    for(*ADDONE = 0; *ADDONE < HUNDREDMILLION; (*ADDONE)++);
}

void add_one_V(){ 
    (*ADDONE)++;
}
          
    
