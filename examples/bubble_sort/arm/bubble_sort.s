@ =============================================================================
@ In-place 32-bit Integer Bubble Sort for Arm Cortex-M55 (QEMU mps3-an547)
@ Sorts [42, 15, 8, 99, 23, 4, 16, 7] -> [4, 7, 8, 15, 16, 23, 42, 99]
@ using shifted-register addressing [r4, r1, lsl #2].
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, r5, r6, lr}

    ldr     r4, =arr
    movs    r0, #7                  @ Outer loop bound: N - 1 = 7

.Louter_loop:
    movs    r1, #0                  @ Inner loop index j = 0

.Linner_loop:
    add     r2, r4, r1, lsl #2      @ r2 = &arr[j]
    ldr     r3, [r2]                @ r3 = arr[j]
    ldr     r12, [r2, #4]           @ r12 = arr[j + 1]
    cmp     r3, r12
    ble     .Lno_swap

    str     r12, [r2]               @ Swap arr[j] and arr[j + 1]
    str     r3, [r2, #4]

.Lno_swap:
    adds    r1, r1, #1
    cmp     r1, r0
    blt     .Linner_loop

    subs    r0, r0, #1
    bne     .Louter_loop

    @ Print sorted array elements
    movs    r5, #0
.Lprint_loop:
    ldr     r0, [r4, r5, lsl #2]
    bl      print_dec
    movs    r0, #' '
    bl      print_char
    adds    r5, r5, #1
    cmp     r5, #8
    blt     .Lprint_loop

    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    pop     {r4, r5, r6, pc}

    .data
    .balign 4
arr:
    .word   42, 15, 8, 99, 23, 4, 16, 7
