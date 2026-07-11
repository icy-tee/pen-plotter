
.section .vectors, "ax"
.global _vectors_start

_vectors_start:
        .option push
        .option norvc
        .rept 32
        jal x0, default_exception_handler
        .endr
        .org 0x80
        jal x0, _start
        .option pop

        .section .text.start, "ax"
        .global _start
default_exception_handler:
        j default_exception_handler

_start:
        la sp, _stack_start

        la t0, _bss_start
        la t1, _bss_end
1:
        bgeu t0, t1, 2f
        sw zero, 0(t0)
        addi t0, t0, 4
        j 1b
2:
        call main
3:
        j 3b
