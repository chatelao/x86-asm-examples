@ =============================================================================
@ Recursive 64-bit factorial for Arm Cortex-M55 (bare metal, QEMU mps3-an547)
@ Computes 10! = 3628800 using umull and mla for 64-bit x 32-bit multiply.
@ =============================================================================
    .syntax unified
    .thumb
    .text

@ -----------------------------------------------------------------------------
@ Recursive 64-bit factorial: uint64_t factorial(uint32_t n)
@ Input:  r0 = n
@ Output: r0 = low 32 bits of n!, r1 = high 32 bits of n!
@ -----------------------------------------------------------------------------
    .thumb_func
factorial:
    cmp     r0, #1
    bls     .Lbase_case

    push    {r4, lr}                @ Save n and return address (8-byte aligned)
    mov     r4, r0
    subs    r0, r0, #1              @ n - 1
    bl      factorial               @ (r0, r1) = (n - 1)!

    umull   r2, r3, r0, r4          @ r2 = (lo * n)[31:0], r3 = (lo * n)[63:32]
    mla     r1, r1, r4, r3          @ r1 = hi * n + carry
    mov     r0, r2                  @ r0 = low word
    pop     {r4, pc}

.Lbase_case:
    movs    r0, #1
    movs    r1, #0
    bx      lr

    .thumb_func
    .global main
main:
    push    {r4, r5, r6, lr}

    movs    r0, #10                 @ Compute 10!
    bl      factorial
    mov     r4, r0                  @ Save 64-bit result in callee-saved regs
    mov     r5, r1

    movs    r0, #10
    bl      print_udec
    ldr     r0, =eq_str
    bl      print_str
    mov     r0, r4
    mov     r1, r5
    bl      print_udec64
    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    pop     {r4, r5, r6, pc}

    .section .rodata
eq_str:
    .asciz  "! = "
