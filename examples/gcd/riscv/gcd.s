# =============================================================================
# Euclidean Algorithm for Greatest Common Divisor on RV32M
#
# Computes GCD(1071, 462) = 21 using unsigned remainder (remu).
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)

    li      s0, 1071                # a = 1071
    li      t0, 462                 # b = 462

.Lgcd_loop:
    beqz    t0, .Lgcd_done          # Done when b == 0
    remu    t1, s0, t0              # t1 = a % b
    mv      s0, t0                  # a = b
    mv      t0, t1                  # b = a % b
    j       .Lgcd_loop

.Lgcd_done:
    la      a0, fmt_prefix          # "GCD(1071, 462) = "
    call    print_str
    mv      a0, s0                  # GCD result (21)
    call    print_udec
    li      a0, '\n'
    call    print_char

    li      a0, 0                   # Return 0
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
fmt_prefix:
    .asciz  "GCD(1071, 462) = "
