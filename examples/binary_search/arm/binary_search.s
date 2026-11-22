@ =============================================================================
@ Binary Search on a sorted 32-bit integer array (Arm Cortex-M55)
@ Searches [3, 7, 12, 19, 25, 31, 42, 58] for target = 25 (index 4).
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, r5, r6, lr}

    ldr     r4, =sorted_arr
    movs    r5, #25                 @ Target value = 25
    movs    r0, #0                  @ low = 0
    movs    r1, #7                  @ high = N - 1 = 7
    mov     r6, #-1                 @ result index = -1 (not found)

.Lbsearch_loop:
    cmp     r0, r1
    bgt     .Lbsearch_done

    add     r2, r0, r1              @ mid = (low + high) >> 1
    lsrs    r2, r2, #1

    ldr     r3, [r4, r2, lsl #2]    @ r3 = sorted_arr[mid]
    cmp     r3, r5
    beq     .Lbsearch_found
    blt     .Lbsearch_right

    subs    r1, r2, #1              @ high = mid - 1
    b       .Lbsearch_loop

.Lbsearch_right:
    adds    r0, r2, #1              @ low = mid + 1
    b       .Lbsearch_loop

.Lbsearch_found:
    mov     r6, r2                  @ Found at index mid

.Lbsearch_done:
    ldr     r0, =s_target
    bl      print_str
    mov     r0, r5
    bl      print_dec
    ldr     r0, =s_found
    bl      print_str
    mov     r0, r6
    bl      print_dec
    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    pop     {r4, r5, r6, pc}

    .section .rodata
    .balign 4
sorted_arr:
    .word   3, 7, 12, 19, 25, 31, 42, 58
s_target:
    .asciz  "Target "
s_found:
    .asciz  " found at index "
