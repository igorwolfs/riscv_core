    .section .text.init,"ax",@progbits
    .globl _start
    .type _start, @function

_start:
    # (1) Set up the stack pointer
    lui   t0, 0x40000        # 0x40000000
    addi  t0, t0, -16        # e.g. 0x3ffffff0 (16-byte aligned)
    mv    sp, t0

    # (2) Call main()
    call  main

    # (3) If main() returns, call finish_sim() or loop forever
    call  finish_sim

    # (4) If finish_sim() returns, just hang
1:  j 1b