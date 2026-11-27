.section .vectors, "ax"
.option push
.option norvc
trap_vector:
  j trap_handler
.option pop

.section .text.startup, "ax"
.global _start
.type _start, @function
_start:
  .option push
  .option norelax
  la gp, __global_pointer$
  .option pop
  la sp, __stack_top

  csrwi mie, 0
  la t0, trap_vector
  csrw mtvec, t0

  la t0, __data_load
  la t1, __data_start
  la t2, __data_end
1:
  beq t1, t2, 2f
  lw t3, 0(t0)
  sw t3, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  j 1b

2:
  la t1, __bss_start
  la t2, __bss_end
3:
  beq t1, t2, 4f
  sw zero, 0(t1)
  addi t1, t1, 4
  j 3b

4:
  call SystemInit
  call main

trap_handler:
  wfi
  j trap_handler
.size _start, . - _start
