.section    .start
.global     _start

_start:
 #addiu $sp, $sp, -104
 #sw $at, 0($sp)
 #sw $v0, 4($sp)
 #sw $v1, 8($sp)
 #sw $a0, 12($sp)
 #sw $a1, 16($sp)
 #sw $a2, 20($sp)
 #sw $a3, 24($sp)
 #sw $t0, 28($sp)
 #sw $t1, 32($sp)
 #sw $t2, 36($sp)
 #sw $t3, 40($sp)
 #sw $t4, 44($sp)
 #sw $t5, 48($sp)
 #sw $t6, 52($sp)
 #sw $t7, 56($sp)
 #sw $s0, 60($sp)
 #sw $s1, 64($sp)
 #sw $s2, 68($sp)
 #sw $s3, 72($sp)
 #sw $s4, 76($sp)
 #sw $s5, 80($sp)
 #sw $s6, 84($sp)
 #sw $s7, 88($sp)
 #sw $t8, 92($sp)
 #sw $t9, 96($sp)
 #sw $ra, 100($sp)
 mfc0 $k1, $12      #move status into $k1
 mfc0 $k0, $13        #move cause into $k0
 andi $k1, $k1, 0xcc00
 and $k0, $k0, $k1      #and status and cause then put in $k0
 andi $k1, $k0, 0x8000  #cause[15] & status[15] = 1
 bne $k1, $0, TIMER_RTC_ISR #TIMER interrupt?
 andi $k1, $k0, 0x0800  #cause[11] & staus[11] = 1
 bne $k1, $0, UART_TX  #is it a UATX interrupt?
 andi $k1, $k0, 0x0400  #cause[10] & staus[10] = 11FFF0F000
 bne $k1, $0, UART_RX  #is it a UARX interrupt?
 j Done  

TIMER_RTC_ISR:
 #la $k0, 0x02FAF080     #load 50 million into $k0 #ff right now
 mfc0 $k1, $9           #put count into $k1
 #sub $k1, $k1, $k0      #subtract 50 million from count  
 #mtc0 $k1, $9           #put new count back into cp0 
 mtc0 $0, $9  
 la $k0, 0x1fff0014     #get the address of the SW_RTC_SEC and put it in $k0
 lw $k0, 0($k0)         #load the SW_RTC_SEC into $k0    
 addiu $k1, $0, 0x3b    #put 59 into $k1
 beq $k1, $k0, MIN_INC  #if 59 seconds increment minute  
 addiu $k0, $k0, 0x1    #add 1 to the SW_RTC_SEC signifying a second has passed	
 la $k1, 0x1fff0014
 sw $k0, 0($k1)         #put the new value of the SW_RTC back at its place in memory
  
FROM_MIN_INC: 
 la $k0, 0x1FFF0018   #load the address of the print enable variable
 lw $k0, 0($k0)       #load the value at the print variable's address  
 bne $k0, $0, Print  

From_Print:
 mfc0 $k1, $13        #get cause and put it in $k1
 andi $k1, $k1, 0x7ff  #clear out cause[15]
 mtc0 $k1, $13        #put cause back
 j Done
    
###########################################################################


UART_RX:


 la $k0, 0x8000000c    #load the address for UARX data
 lw $k0, 0($k0)        #load from UARX data  

 la $k1, 0x80000000      # load addr of DataInReady
 lw $k1, 0($k1)          #get value for TXReady

 beq $0, $k1, SKIP_TX
 la $k1, 0x80000008      # load addr of TX
 sb $k0, 0($k1)          # put cr in TX 
 j Skip_Buffer

####################################################################################

SKIP_TX: 
 addiu $sp, $sp, -12
 sw $t0, 8($sp)
 sw $t1, 4($sp)
 sw $t2, 0($sp)

 la $t0, 0x1fff001c      #buffer
 la $t1, 0x1fff0000      # in pointer address        
 lw $t1, 0($t1)          # value of in pointer
 addu $t0, $t0, $t1       # add inPtr + buffer addr
 sb $k0, 0($t0)
 addiu $t2, $0,0x7ff         # $t2 = 2047 
 beq $t1, $t2, Wrap_In_Ptr11 # if inPtr == 2047
 addiu $t1, $t1, 1          # inPtr ++ 

From_Wrap_In_Ptr11:
 la $t0, 0x1fff0000      # in pointer address 
 sw $t1, 0($t0)          # need to store in ptr
 lw $t0, 8($sp)
 lw $t1, 4($sp)
 lw $t2, 0($sp)
 addiu $sp, $sp, 12

Skip_Buffer:

########################

 addiu $k1, $0, 0x64   #put d into $k1
 beq $k0, $k1, PRINT_OFF
 addiu $k1, $0, 0x65   #put e into $k1
 beq $k0, $k1, PRINT_ON
 la $k1, 0x1fff0008    #load the address for the state variable
 la $k0, 0x8000000c    #load the address for UARX data
 lw $k0, 0($k0)        #load from UARX data 
 sw $k0, 0($k1)        #store from UARX into the state variable's location

FROM_PRINT_OFF:

FROM_PRINT_ON:  
 mfc0 $k1, $13        #put cause into $k1
 andi $k1, $k1, 0xfbff  #clear out cause[10]
 mtc0 $k1, $13        #move new value of cause back to cp0
 j Done
###########################################################################################    
UART_TX:
 la $k0, 0x1fff0000  #load of in pointer	
 lw $k0, 0($k0)
 la $k1, 0x1fff0004  #load out pointer
 lw $k1, 0($k1) 
 beq $k0, $k1, FROM_ZERO_OUT
 la $k0, 0x1fff001c  #load address of buffer
 addu $k0, $k0, $k1   #add offset of out index to buffer address
 lb $k0, 0($k0)
 la $k1, 0x80000008   #load address of UATX_DATA
 sb $k0, 0($k1)       #store buffer contents into UART_TX
 la $k1, 0x1fff0004  #load out pointer
 lw $k1, 0($k1) 
 addiu $k0,$0,0x7ff
 beq $k0, $k1, ZERO_OUT_IDX   #check if out_idx = 31        
 addiu $k1, $k1, 0x1          #add one to outidx
 la $k0, 0x1fff0004
 sw $k1, 0($k0)

FROM_ZERO_OUT:
 mfc0 $k1, $13            #move Cause to k1
 andi $k1, $k1, 0xf7ff    #zero out cause[10]
 mtc0 $k1, $13            #move it back to cp0	 
 j Done

MIN_INC:
 la $k0, 0x1fff0010    #load SW_RTC_MIN
 lw $k1, 0($k0)        
 addiu $k1, $k1, 0x1   #put another minute on the clock
 sw $k1, 0($k0)        #put the update minutes back in mem
 la $k0, 0x1fff0014    #load SW_RTC_SEC   
 sw $0, 0($k0)         #put zero into seconds
 j FROM_MIN_INC
	
ZERO_OUT_IDX:
 la $k1, 0x1fff0004 
 sw $0, 0($k1)	
 j FROM_ZERO_OUT

PRINT_OFF:
 la $k0, 0x1FFF0018
 addiu $k1, $0, 0x0
 sw $k1, 0($k0)
 j FROM_PRINT_OFF
        
PRINT_ON:
 la $k0, 0x1FFF0018
 addiu $k1, $0, 0x1
 sw $k1, 0($k0)
 j FROM_PRINT_ON

Done:
 mfc0 $k1, $12
 ori $k1, $k1, 0x0001
 mfc0 $k0, $14
 mtc0 $k1, $12
 #lw $at, 0($sp)
 #lw $v0, 4($sp)
 #lw $v1, 8($sp)
 #lw $a0, 12($sp)
 #lw $a1, 16($sp)
 #lw $a2, 20($sp)
 #lw $a3, 24($sp)
 #lw $t0, 28($sp)
 #lw $t1, 32($sp)
 #lw $t2, 36($sp)
 #lw $t3, 40($sp)
 #lw $t4, 44($sp)
 #lw $t5, 48($sp)
 #lw $t6, 52($sp)
 #lw $t7, 56($sp)
 #lw $s0, 60($sp)
 #lw $s1, 64($sp)
 #lw $s2, 68($sp)
 #lw $s3, 72($sp)
 #lw $s4, 76($sp)
 #lw $s5, 80($sp)
 #lw $s6, 84($sp)
 #lw $s7, 88($sp)
 #lw $t8, 92($sp)
 #lw $t9, 96($sp)
 #lw $ra, 100($sp)
 #addiu $sp, $sp, 104
 jr $k0


Print:
 addiu $sp, $sp, -20
 sw $t0, 16($sp)
 sw $t1, 12($sp)
 sw $t2, 8($sp)
 sw $t3, 4($sp)
 sw $t4, 0($sp)
 la $k1, 0x1fff0010 # min
 lw $k1, 0($k1)
 la $k0, 0x1fff001c #buffer

#######################################################

la $t4, 0x80000000      # load addr of DataInReady
 lw $t4, 0($t4)          #get value for TXReady
 la $t1, 0x1fff0000      # in pointer address        
 lw $t1, 0($t1)          # value of in pointer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 addiu $t0, $0, 13	  # ascii for carraige return
 beq $0, $t4, SKIP_TX_LOAD
 la $t4, 0x80000008      # load addr of TX
 sb $t0, 0($t4)          # put cr in TX 
 j SKIP_BUFF_LOAD
 
SKIP_TX_LOAD: 
 sb $t0, 0($k0)
 addiu $t2, $0,0x7ff         # $t2 = 2047 
 beq $t1, $t2, Wrap_In_Ptr6 # if inPtr == 2047
 addiu $t1, $t1, 1          # inPtr ++ 
 
SKIP_BUFF_LOAD: 
 la $k0, 0x1fff001c #buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 addiu $t0, $0, 32	  # ascii for ' ' 

 sb $t0, 0($k0)
 addiu $t2, $0,0x7ff         # $t2 = 2047 
 beq $t1, $t2, Wrap_In_Ptr7 # if inPtr == 2047
 addiu $t1, $t1, 1 

##################################################

Time:
 addiu $t0, $0, 1      # 1 compare
 addiu $t2, $0, 10     # 10 compare
 addiu $t3, $0, 0      # 10's min digit

 Min_Loop:
 sltu $t4, $k1, $t2                # if min < 10
 beq $t4, $t0, Put_Min_In_Buffer
 subu $k1, $k1, $t2                 # min -= 10
 addiu $t3, $t3, 1                 # 10's min digit += 1
 j Min_Loop
 
Put_Min_In_Buffer:
 addiu $t3, $t3, 48      # Convert 10's min digit to ASCII
 addiu $k1, $k1, 48      # Convert 1's min digit to ASCII
 la $k0, 0x1fff001c       # buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr

 sb $t3, 0($k0)
 addiu $t2, $0,0x7ff         # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr6 # if inPtr == 31
 addiu $t1, $t1, 1          # inPtr += 
  
From_Wrap_In_Ptr6:
 la $k0, 0x1fff001c #buffer
 addu $k0, $k0, $t1 
 sb $k1, 0($k0)          # store 1's min digit in buffer
 addiu $t2, $0,0x7ff        # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr1 # if inPtr == 31
 addiu $t1, $t1, 1          # inPtr += 1
 
From_Wrap_In_Ptr1:
 addiu $t2, $0, 58       # ASCII for :
 la $k0, 0x1fff001c #buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 sb $t2, 0($k0)          # store ":" in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr2  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1
     
From_Wrap_In_Ptr2:               
 addiu $t3, $0, 0         # 10's sec digit = 0
 addiu $t2, $0, 10        # 10 compare
 la $k1, 0x1fff0014       # load addr of sec 
 lw $k1, 0($k1)           # load value of sec 

Sec_Loop:
 sltu $t4, $k1, $t2               # if min/sec < 10
 beq $t4, $t0, Put_Sec_In_Buffer  
 subu $k1, $k1, $t2                # sec - 10
 addiu $t3, $t3, 1                # 10's sec diit += 1
 j Sec_Loop

Put_Sec_In_Buffer:
 addiu $t3, $t3, 48          # Convert 10's sec digit to ASCII
 addiu $k1, $k1, 48          # Convert 1's sec digit to ASCII
 la $k0, 0x1fff001c #buffer
 addu $k0, $k0, $t1           # add inPtr + buffer addr
 sb $t3, 0($k0)              # store 10's sec digit in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr3  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1
 
From_Wrap_In_Ptr3:  
 la $k0, 0x1fff001c #buffer
 addu $k0, $k0, $t1           # add inPtr + buffer addr
 sb $k1, 0($k0)              # store 1's sec digit in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr4  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1
 
From_Wrap_In_Ptr4:  
 addiu $t2, $0, 32       # ASCII for ' '
 la $k0, 0x1fff001c #buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 sb $t2, 0($k0)          # store "cr" in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr5  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1

##################################################################

From_Wrap_In_Ptr5:  
 addiu $t2, $0, 32        # ASCII for ' '
 la $k0, 0x1fff001c       #buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 sb $t2, 0($k0)           # store "cr" in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr8  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1

From_Wrap_In_Ptr8:
##################
la $t2, 0x1fff0008    #load the address for the state variable
lw $t2, 0($t2)
####################
 #addiu $t2, $0, 62        # ASCII for '>'
 la $k0, 0x1fff001c       #buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 sb $t2, 0($k0)           # store "cr" in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr9  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1

From_Wrap_In_Ptr9:
 addiu $t2, $0, 32        # ASCII for ' '
 la $k0, 0x1fff001c       #buffer
 addu $k0, $k0, $t1       # add inPtr + buffer addr
 sb $t2, 0($k0)           # store "cr" in buffer
 addiu $t2, $0,0x7ff          # $t2 = 31 
 beq $t1, $t2, Wrap_In_Ptr10  # if inPtr == 31
 addiu $t1, $t1, 1           # inPtr += 1

From_Wrap_In_Ptr10:
##################################################################


 la $k0, 0x1fff0000      # in pointer address
 sw $t1, 0($k0)
 lw $t0, 16($sp)
 lw $t1, 12($sp)
 lw $t2, 8($sp)
 lw $t3, 4($sp)
 lw $t4, 0($sp)
 addiu $sp, $sp, 20
j From_Print

Wrap_In_Ptr1:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr1
 
Wrap_In_Ptr2:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr2
 
Wrap_In_Ptr3:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr3
 
Wrap_In_Ptr4:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr4
 
Wrap_In_Ptr5:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr5
 
Wrap_In_Ptr6:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr6

Wrap_In_Ptr7:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j Time

Wrap_In_Ptr8:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr8

Wrap_In_Ptr9:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr9

Wrap_In_Ptr10:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr10

Wrap_In_Ptr11:
 addu $t1, $0, $0      # wrap in ptr back to 0
 j From_Wrap_In_Ptr11
