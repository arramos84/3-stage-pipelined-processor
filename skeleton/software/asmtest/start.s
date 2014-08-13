.section    .start
.global     _start

_start:

addiu $s7, $0, 0x0
# Test 1 addiu test

li $s0, 0x00000020
addiu $t0, $0, 0x20
addiu $s7, $s7, 1 # register to hold the test number (in case of failure)
bne $t0, $s0, Error
	
/**
# Test 2 sw
li $s0, 0x7a
li $s1, 0x10000008	
sw $s0, 0($s1)
lw $t0, 0($s1)
addiu $s7, $s7, 2 # register to hold the test number (in case of failure)
bne $t0, $s0, Error

# Test 3 lb/sb
li $s0, 0x10000000
li $s2, 0x00000008
sb $s2, 0($s0)
lb $s3, 0($s0)
addiu $s7, $s7, 3 # register to hold the test number (in case of failure)
bne $s2, $s3, Error

# Test 4 lb/sb
li $s0, 0x10000007
li $s2, 0x08000008
sb $s2, 0($s0)
lb $s3, 0($s0)
li $s4, 0xfffffff8
addiu $s7, $s7, 4 # register to hold the test number (in case of failure)
bne $s3, $s4, Error

# Test 5 blez
li $s0, 0x00000001
addiu $s7, $s7, 5 # register to hold the test number (in case of failure)
blez $s0, Next5
j Error
	
Next5:
	
# Test 6
li $s0, 0xfffffff8
addiu $s7, $s7, 6 # register to hold the test number (in case of failure)
bgtz $s0, Next6
j Error

Next6:	

# Test 7
li $s0, 0x00000008
addiu $s7, $s7, 7 # register to hold the test number (in case of failure)
bltz $s0, Next7
j Error

Next7:

# Test 8
li $s0, 0xffffffff
addiu $s7, $s7, 8 # register to hold the test number (in case of failure)
bgez $s0, Next8
j Error

Next8:
	
# Test 9
li $s0, 0x00000004
li $s1, 0x00000004
addiu $s7, $s7, 9 # register to hold the test number (in case of failure)
beq $s0, $s1, Done
**/
	
# Test 10 SLL
addiu $s0, $zero, 0x0001
addiu $t0, $0, 0x1000
sll $s0, $s0, 0x3
addiu $s7, $s7, 10 # register to hold the test number (in case of failure)
bne $t0, $s0, Error

#Test 11 SRL
addiu $s0, $zero, 0x1000
addiu $t0, $0, 0x0001
srl $s0, $s0, 0x3
addiu $s7, $s7, 11 # register to hold the test number (in case of failure)
bne $t0, $s0, Error

# Test 12 SRA
li $s0, 0x11111000
li $t0, 0x11111110
sra $s0, $s0, 0x2
addiu $s7, $s7, 12 # register to hold the test number (in case of failure)
bne $t0, $s0, Error


# Test 13 SLLV
li $s1, 0x00000003
addiu $s0, $zero, 0x0001
addiu $t0, $0, 0x1000
sra $s0, $s0, $s1
addiu $s7, $s7, 13 # register to hold the test number (in case of failure)
bne $t0, $s0, Error


j Success

Error:
li $s0, 0x80000008
sw $s7, 0($s0)
	
Success:
li $s1, 0xFF
li $s0, 0x80000008
sw $s1, 0($s0)	
