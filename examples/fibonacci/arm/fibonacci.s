@ =============================================================================
@ Iterative Fibonacci sequence for Arm Cortex-M55 (bare metal, QEMU mps3-an547)
@ Computes F(0) .. F(9) in 64-bit integer arithmetic using an adds / adc pair
@ (lo in r4, hi in r5 for F_n; lo in r6, hi in r7 for F_{n+1}).
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4-r8, lr}

    ldr     r0, =header_msg
    bl      print_str

    movs    r4, #0                  @ F_0 low  = 0
    movs    r5, #0                  @ F_0 high = 0
    movs    r6, #1                  @ F_1 low  = 1
    movs    r7, #0                  @ F_1 high = 0
    movs    r8, #0                  @ Loop counter i = 0

.Lfib_loop:
    ldr     r0, =prefix_str         @ Print "F("
    bl      print_str
    mov     r0, r8                  @ Print index i
    bl      print_udec
    ldr     r0, =eq_str             @ Print ") = "
    bl      print_str
    mov     r0, r4                  @ Print 64-bit F_i
    mov     r1, r5
    bl      print_udec64
    movs    r0, #'\n'
    bl      print_char

    adds    r0, r4, r6              @ next = F_i + F_{i+1} (64-bit)
    adc     r1, r5, r7
    mov     r4, r6                  @ F_i     = F_{i+1}
    mov     r5, r7
    mov     r6, r0                  @ F_{i+1} = next
    mov     r7, r1

    adds    r8, r8, #1
    cmp     r8, #10
    blt     .Lfib_loop

    movs    r0, #0                  @ Return 0
    pop     {r4-r8, pc}

    .section .rodata
header_msg:
    .asciz  "First 10 Fibonacci numbers:\n"
prefix_str:
    .asciz  "F("
eq_str:
    .asciz  ") = "
