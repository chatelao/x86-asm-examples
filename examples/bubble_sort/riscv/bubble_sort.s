# =============================================================================
# In-place 32-bit Integer Bubble Sort on RV32 + Zbb
#
# Sorts [42, 15, 8, 99, 23, 4, 16, 7] -> [4, 7, 8, 15, 16, 23, 42, 99]
# using Zbb min/max instructions for branchless compare-and-swap.
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    sw      s1, 4(sp)

    la      s0, arr                 # Base pointer to array
    li      t0, 7                   # Outer loop bound: N - 1 = 7

.Louter_loop:
    li      t1, 0                   # Inner loop index j = 0
    mv      t2, s0                  # Current element pointer &arr[j]

.Linner_loop:
    lw      t3, 0(t2)               # t3 = arr[j]
    lw      t4, 4(t2)               # t4 = arr[j + 1]
    min     t5, t3, t4              # Branchless compare-and-swap via Zbb
    max     t6, t3, t4
    sw      t5, 0(t2)               # arr[j]     = min(arr[j], arr[j+1])
    sw      t6, 4(t2)               # arr[j + 1] = max(arr[j], arr[j+1])

    addi    t2, t2, 4
    addi    t1, t1, 1
    blt     t1, t0, .Linner_loop

    addi    t0, t0, -1
    bnez    t0, .Louter_loop

    # Print sorted array elements
    li      s1, 8                   # Element count
.Lprint_loop:
    lw      a0, 0(s0)
    call    print_dec
    li      a0, ' '
    call    print_char
    addi    s0, s0, 4
    addi    s1, s1, -1
    bnez    s1, .Lprint_loop

    li      a0, '\n'
    call    print_char

    li      a0, 0                   # Return 0
    lw      s1, 4(sp)
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .data
    .balign 16
arr:
    .word   42, 15, 8, 99, 23, 4, 16, 7
