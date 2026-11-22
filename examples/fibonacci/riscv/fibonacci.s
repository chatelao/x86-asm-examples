# =============================================================================
# Iterative Fibonacci sequence for RV32 (ILP32F calling convention)
#
# Computes F(0)..F(9) using 64-bit unsigned state (F_n, F_{n+1}) held in
# 32-bit register pairs (s1:s2 and s3:s4) with add/sltu carry propagation,
# and prints each value via print_udec64.
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)
    sw      s4, 8(sp)

    la      a0, header_msg
    call    print_str

    li      s1, 0                   # F_0 low  = 0
    li      s2, 0                   # F_0 high = 0
    li      s3, 1                   # F_1 low  = 1
    li      s4, 0                   # F_1 high = 0
    li      s0, 0                   # Loop counter i = 0

.Lfib_loop:
    la      a0, fib_prefix          # "F("
    call    print_str
    mv      a0, s0                  # i
    call    print_udec
    la      a0, fib_mid             # ") = "
    call    print_str
    mv      a0, s1                  # F_i low
    mv      a1, s2                  # F_i high
    call    print_udec64
    li      a0, '\n'
    call    print_char

    # 64-bit addition: (t0, t1) = (s1, s2) + (s3, s4)
    add     t0, s1, s3              # Low word sum
    sltu    t2, t0, s1              # Carry out from low word
    add     t1, s2, s4              # High word sum
    add     t1, t1, t2              # Add carry

    mv      s1, s3                  # F_i     = F_{i+1}
    mv      s2, s4
    mv      s3, t0                  # F_{i+1} = F_i + F_{i+1}
    mv      s4, t1

    addi    s0, s0, 1
    li      t0, 10
    blt     s0, t0, .Lfib_loop

    li      a0, 0                   # Return 0
    lw      s4, 8(sp)
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

    .section .rodata
header_msg:
    .asciz  "First 10 Fibonacci numbers:\n"
fib_prefix:
    .asciz  "F("
fib_mid:
    .asciz  ") = "
