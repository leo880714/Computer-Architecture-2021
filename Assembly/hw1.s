.globl __start
.rodata
  n:.word 7
.text  
FUNCTION:
    addi x9,  x10, 0
fuct:
    addi sp,  sp, -8
    sw   x1,  4(sp)
    sw   x9,  0(sp)
    addi x6,  x0,  1
    beq  x9,  x6,  L1  #if n != 0, jump to L1
    srli x9,  x9, 1   #n = n/2
    jal  x1,  fuct     #find T(n/2)
    slli x10, x10, 3   #find 8*T(n/2)
    lw   x9,  0(sp)    
    lw   x1,  4(sp)
    addi sp,  sp,  8
    slli x8,  x9,  2   #find 4n
    add  x10, x10, x8   #T(n) = 8T(n/2) + 4n
    jalr x0,  0(x1)
L1:
    addi x10, x0,  7    #when n = 1, T(n) = 7
    addi sp,  sp,  8
    jalr x0,  0(x1)
  
__start:
  la  t0, n
  lw  x10, 0(t0)
  jal x1,FUNCTION
  la  t0, n
  sw  x10,4(t0)
  addi a0,x0,10
  ecall
