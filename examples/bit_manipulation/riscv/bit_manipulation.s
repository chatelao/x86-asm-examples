# =============================================================================
# Hardware Bit Manipulation (RV32 Zbb)
#
# Operates on the 64-bit value 0x00F0F0F000001000 split into two 32-bit halves:
# - cpop:  Count set 1-bits (Hamming weight) across both halves
# - ctz:   Count trailing zero bits (checking low word first, then high + 32)
# - clz:   Count leading zero bits (checking high word first, then low + 32)
# - rev8:  Byte-swap each 32-bit half and swap halves for 64-bit endianness swap
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

    li      t0, 0x00001000          # Low 32 bits  of 0x00F0F0F000001000
    li      t1, 0x00F0F0F0          # High 32 bits of 0x00F0F0F000001000

    # Population count (13 set bits)
    cpop    t2, t0
    cpop    t3, t1
    add     s0, t2, t3              # s0 = popcnt

    # Trailing zero count (12 trailing zeros)
    beqz    t0, .Lctz_hi
    ctz     s1, t0                  # Low word is non-zero
    j       .Lctz_done
.Lctz_hi:
    ctz     t2, t1
    addi    s1, t2, 32
.Lctz_done:

    # Leading zero count (8 leading zeros)
    beqz    t1, .Lclz_lo
    clz     s2, t1                  # High word is non-zero
    j       .Lclz_done
.Lclz_lo:
    clz     t2, t0
    addi    s2, t2, 32
.Lclz_done:

    # 64-bit byte swap -> 0x00100000F0F0F000
    rev8    s3, t0                  # New high word = rev8(lo)
    rev8    s4, t1                  # New low word  = rev8(hi)

    # Print: "popcnt=13 tzcnt=12 lzcnt=8 bswap=0x00100000F0F0F000\n"
    la      a0, str_popcnt
    call    print_str
    mv      a0, s0
    call    print_udec

    la      a0, str_tzcnt
    call    print_str
    mv      a0, s1
    call    print_udec

    la      a0, str_lzcnt
    call    print_str
    mv      a0, s2
    call    print_udec

    la      a0, str_bswap
    call    print_str
    mv      a0, s3                  # High 32 bits first
    li      a1, 8
    call    print_hex
    mv      a0, s4                  # Low 32 bits second
    li      a1, 8
    call    print_hex
    li      a0, '\n'
    call    print_char

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
str_popcnt:
    .asciz  "popcnt="
str_tzcnt:
    .asciz  " tzcnt="
str_lzcnt:
    .asciz  " lzcnt="
str_bswap:
    .asciz  " bswap=0x"
