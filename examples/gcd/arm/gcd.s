@ =============================================================================
@ Euclidean Algorithm for Greatest Common Divisor on Arm Cortex-M55
@ Computes GCD(1071, 462) = 21 using hardware udiv and mls (multiply-subtract)
@ to obtain the remainder (a % b = a - (a / b) * b).
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, r5, r6, lr}

    ldr     r4, =1071               @ a = 1071
    ldr     r5, =462                @ b = 462

.Lgcd_loop:
    cbz     r5, .Lgcd_done          @ Done when b == 0
    udiv    r0, r4, r5              @ q = a / b
    mls     r1, r0, r5, r4          @ rem = a - q * b
    mov     r4, r5                  @ a = b
    mov     r5, r1                  @ b = rem
    b       .Lgcd_loop

.Lgcd_done:
    ldr     r0, =prefix_str
    bl      print_str
    mov     r0, r4                  @ Print GCD result (21)
    bl      print_udec
    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    pop     {r4, r5, r6, pc}

    .section .rodata
prefix_str:
    .asciz  "GCD(1071, 462) = "
