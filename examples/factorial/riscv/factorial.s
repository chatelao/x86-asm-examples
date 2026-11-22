# =============================================================================
# Recursive 64-bit factorial for RV32M (ILP32F calling convention)
#
# Computes 10! = 3628800 recursively, returning a 64-bit unsigned result in
# (a0 = lo, a1 = hi) using mul and mulhu for 32x64 -> 64-bit multiplication.
# =============================================================================
    .text

# -----------------------------------------------------------------------------
# uint64_t factorial(uint32_t n)
# Input:  a0 = n
# Output: a0 = low 32 bits of n!, a1 = high 32 bits of n!
# -----------------------------------------------------------------------------
factorial:
    li      t0, 1
    bleu    a0, t0, .Lbase_case

    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    mv      s0, a0                  # Save n

    addi    a0, a0, -1              # n - 1
    call    factorial               # (a0, a1) = (n - 1)!

    # Multiply 64-bit (a0, a1) by 32-bit s0
    mulhu   t0, a0, s0              # Upper 32 bits of (lo * n)
    mul     a0, a0, s0              # New low word
    mul     t1, a1, s0              # Low 32 bits of (hi * n)
    add     a1, t1, t0              # New high word

    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

.Lbase_case:
    li      a0, 1
    li      a1, 0
    ret

    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    sw      s1, 4(sp)

    li      a0, 10                  # Compute 10!
    call    factorial
    mv      s0, a0                  # Save low word
    mv      s1, a1                  # Save high word

    la      a0, fmt_prefix          # "10! = "
    call    print_str
    mv      a0, s0
    mv      a1, s1
    call    print_udec64
    li      a0, '\n'
    call    print_char

    li      a0, 0                   # Return 0
    lw      s1, 4(sp)
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
fmt_prefix:
    .asciz  "10! = "
