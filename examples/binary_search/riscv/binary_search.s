# =============================================================================
# Binary Search on a sorted 32-bit integer array on RV32
#
# Searches [3, 7, 12, 19, 25, 31, 42, 58] for target = 25 (index 4).
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    sw      s1, 4(sp)

    la      t0, sorted_arr
    li      s0, 25                  # Target value = 25
    li      t1, 0                   # low = 0
    li      t2, 7                   # high = N - 1 = 7
    li      s1, -1                  # result index = -1 (not found)

.Lbsearch_loop:
    bgt     t1, t2, .Lbsearch_done

    add     t3, t1, t2              # low + high
    srli    t3, t3, 1               # mid = (low + high) >> 1
    slli    t4, t3, 2               # byte offset = mid * 4
    add     t4, t0, t4
    lw      t5, 0(t4)               # t5 = sorted_arr[mid]

    beq     t5, s0, .Lbsearch_found
    blt     t5, s0, .Lbsearch_right

    addi    t2, t3, -1              # high = mid - 1
    j       .Lbsearch_loop

.Lbsearch_right:
    addi    t1, t3, 1               # low = mid + 1
    j       .Lbsearch_loop

.Lbsearch_found:
    mv      s1, t3                  # Found at index mid

.Lbsearch_done:
    la      a0, fmt_part1           # "Target "
    call    print_str
    mv      a0, s0
    call    print_dec
    la      a0, fmt_part2           # " found at index "
    call    print_str
    mv      a0, s1
    call    print_dec
    li      a0, '\n'
    call    print_char

    li      a0, 0                   # Return 0
    lw      s1, 4(sp)
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
    .balign 16
sorted_arr:
    .word   3, 7, 12, 19, 25, 31, 42, 58
fmt_part1:
    .asciz  "Target "
fmt_part2:
    .asciz  " found at index "
