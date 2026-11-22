# =============================================================================
# Hardware-Accelerated CRC-32C Checksum using Zbc Carry-Less Multiply
#
# Computes the CRC-32C (Castagnoli, reflected polynomial 0x82F63B78, init
# 0xFFFFFFFF, final XOR 0xFFFFFFFF) of the 12-byte buffer "Hello, CRC32"
# using 32-bit word-at-a-time Barrett reduction with Zbc clmul / clmulr:
#   q   = clmul(crc ^ word, K_barrett)   where K_barrett = 0xDEA713F1
#   crc = clmulr(q, P_ref)               where P_ref     = 0x82F63B78
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)

    la      t0, payload             # 12-byte aligned buffer ("Hello, CRC32")
    li      t1, 3                   # 3 x 32-bit words (12 bytes)
    li      s0, 0xFFFFFFFF          # Initial CRC-32C seed
    li      t2, 0xDEA713F1          # Reflected Barrett constant floor(x^64 / P)
    li      t3, 0x82F63B78          # Reflected CRC-32C polynomial

.Lcrc_word_loop:
    lw      t4, 0(t0)               # Load 4 bytes (little-endian)
    xor     t4, s0, t4              # x = crc ^ word
    clmul   t4, t4, t2              # q = clmul(x, K_barrett)
    clmulr  s0, t4, t3              # crc = clmulr(q, P_ref)
    addi    t0, t0, 4
    addi    t1, t1, -1
    bnez    t1, .Lcrc_word_loop

    not     s0, s0                  # Finalize CRC-32C via bitwise inversion

    # Print: CRC32C("Hello, CRC32") = 0x25EF37B5
    la      a0, fmt_prefix
    call    print_str
    la      a0, payload
    call    print_str
    la      a0, fmt_mid
    call    print_str
    mv      a0, s0
    li      a1, 8
    call    print_hex
    li      a0, '\n'
    call    print_char

    li      a0, 0                   # Return 0
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
    .balign 4
payload:
    .asciz  "Hello, CRC32"
fmt_prefix:
    .asciz  "CRC32C(\""
fmt_mid:
    .asciz  "\") = 0x"
