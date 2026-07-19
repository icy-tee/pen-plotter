
.section .vectors, "ax"
.global _vectors_start

_vectors_start:
        .option push
        .option norvc
        .rept 7
        jal x0, default_exception_handler
        .endr
        jal x0, machine_timer_isr_entry
        .rept 24
        jal x0, default_exception_handler
        .endr
        .org 0x80
        jal x0, _start
        .option pop

        .section .text.start, "ax"
        .global _start
default_exception_handler:
        j default_exception_handler

.global machine_timer_isr_entry
.extern machine_timer_handler
machine_timer_isr_entry:
        addi sp, sp, -64
        sw ra, 0(sp)
        sw t0, 4(sp)
        sw t1, 8(sp)
        sw t2, 12(sp)
        sw t3, 16(sp)
        sw t4, 20(sp)
        sw t5, 24(sp)
        sw t6, 28(sp)
        sw a0, 32(sp)
        sw a1, 36(sp)
        sw a2, 40(sp)
        sw a3, 44(sp)
        sw a4, 48(sp)
        sw a5, 52(sp)
        sw a6, 56(sp)
        sw a7, 60(sp)

        call machine_timer_handler

        lw ra, 0(sp)
        lw t0, 4(sp)
        lw t1, 8(sp)
        lw t2, 12(sp)
        lw t3, 16(sp)
        lw t4, 20(sp)
        lw t5, 24(sp)
        lw t6, 28(sp)
        lw a0, 32(sp)
        lw a1, 36(sp)
        lw a2, 40(sp)
        lw a3, 44(sp)
        lw a4, 48(sp)
        lw a5, 52(sp)
        lw a6, 56(sp)
        lw a7, 60(sp)
        addi sp, sp, 64
        mret

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
