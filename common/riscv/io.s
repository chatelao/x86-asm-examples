# =============================================================================
# Tiny semihosting console library for bare-metal RV32 (ILP32F calling convention)
#
#   print_str(a0 = const char *s)                 SYS_WRITE0
#   print_char(a0 = char c)                       SYS_WRITEC
#   print_udec(a0 = uint32_t v)                   "%u"
#   print_dec(a0 = int32_t v)                     "%d"
#   print_dec_w(a0 = int32_t v, a1 = width)       "%*d"  (right-aligned)
#   print_udec64(a0 = lo, a1 = hi)                "%llu"
#   print_hex(a0 = uint32_t v, a1 = digits)       "%0*X"
#   print_f1_w(fa0 = float v, a0 = width)         "%*.1f"
#   semihost_call(a0 = operation, a1 = parameter) -> a0
#
# Only caller-saved registers (a*, t*, ft*, v*) are clobbered.
# =============================================================================
    .text

    .equ    SYS_WRITEC, 0x03
    .equ    SYS_WRITE0, 0x04

# -----------------------------------------------------------------------------
# RISC-V semihosting trap: the magic sequence must be uncompressed and must not
# straddle a page boundary, hence norvc + 16-byte alignment.
    .global semihost_call
    .balign 16
semihost_call:
    .option push
    .option norvc
    slli    zero, zero, 0x1f        # Entry NOP
    ebreak                          # Break to debugger / QEMU semihosting
    srai    zero, zero, 7           # NOP encoding semihosting call number 7
    .option pop
    ret

# -----------------------------------------------------------------------------
    .global print_str
print_str:
    mv      a1, a0
    li      a0, SYS_WRITE0
    j       semihost_call

# -----------------------------------------------------------------------------
    .global print_char
print_char:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sb      a0, 0(sp)
    mv      a1, sp
    li      a0, SYS_WRITEC
    call    semihost_call
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# -----------------------------------------------------------------------------
    .global print_udec
print_udec:
    li      a1, 0                   # width 0
    li      a2, 0                   # not negative
    li      a3, -1                  # no fractional digit
    j       fmt_print

# -----------------------------------------------------------------------------
    .global print_dec
print_dec:
    li      a1, 0
    # fall through
    .global print_dec_w
print_dec_w:
    sltz    a2, a0                  # negative flag
    bgez    a0, 1f
    neg     a0, a0                  # magnitude (INT_MIN works as unsigned)
1:  li      a3, -1
    j       fmt_print

# -----------------------------------------------------------------------------
# print_f1_w: print a float with one decimal, right-aligned in `width` chars.
    .global print_f1_w
print_f1_w:
    mv      a1, a0                  # width
    li      t0, 0x41200000          # 10.0f
    fmv.w.x ft0, t0
    fmul.s  ft0, fa0, ft0
    fcvt.w.s t1, ft0, rne           # round(v * 10) to nearest-even
    sltz    a2, t1
    bgez    t1, 1f
    neg     t1, t1
1:  li      t2, 10
    divu    a0, t1, t2              # integer part
    remu    a3, t1, t2              # fractional digit
    j       fmt_print

# -----------------------------------------------------------------------------
# fmt_print: a0 = magnitude, a1 = width, a2 = negative flag, a3 = frac digit/-1
# Builds the text right-to-left in a stack buffer, then prints it.
fmt_print:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    addi    t0, sp, 39              # t0 = write cursor (end of buffer)
    sb      zero, 0(t0)
    bltz    a3, 1f
    addi    a3, a3, '0'
    addi    t0, t0, -1
    sb      a3, 0(t0)               # fractional digit
    li      t1, '.'
    addi    t0, t0, -1
    sb      t1, 0(t0)
1:  li      t2, 10
2:  remu    t1, a0, t2
    divu    a0, a0, t2
    addi    t1, t1, '0'
    addi    t0, t0, -1
    sb      t1, 0(t0)
    bnez    a0, 2b
    beqz    a2, 3f
    li      t1, '-'
    addi    t0, t0, -1
    sb      t1, 0(t0)
3:  addi    t3, sp, 39
    sub     t3, t3, t0              # current length
    li      t1, 32
    ble     a1, t1, 4f
    mv      a1, t1                  # clamp width to buffer size
4:  li      t1, ' '
5:  bge     t3, a1, 6f
    addi    t0, t0, -1
    sb      t1, 0(t0)               # left-pad with spaces
    addi    t3, t3, 1
    j       5b
6:  mv      a0, t0
    call    print_str
    lw      ra, 44(sp)
    addi    sp, sp, 48
    ret

# -----------------------------------------------------------------------------
# print_hex: a0 = value, a1 = number of hex digits (1..8), uppercase
    .global print_hex
print_hex:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    addi    t0, sp, 9
    sb      zero, 0(t0)
    li      t3, 10
1:  andi    t1, a0, 0xF
    addi    t2, t1, '0'
    blt     t1, t3, 2f
    addi    t2, t1, 'A' - 10
2:  addi    t0, t0, -1
    sb      t2, 0(t0)
    srli    a0, a0, 4
    addi    a1, a1, -1
    bgtz    a1, 1b
    mv      a0, t0
    call    print_str
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# -----------------------------------------------------------------------------
# print_udec64: a0 = low word, a1 = high word. 64-bit / 10 is done with 32-bit
# divu/remu in three steps (high word, then two 16-bit halves of the low word).
    .global print_udec64
print_udec64:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    addi    t0, sp, 31
    sb      zero, 0(t0)
    li      t6, 10
1:  remu    t1, a1, t6              # rem  = hi % 10
    divu    a1, a1, t6              # q_hi = hi / 10
    srli    t2, a0, 16
    slli    t1, t1, 16
    or      t2, t2, t1              # t = rem:lo[31:16]
    divu    t3, t2, t6              # q1
    remu    t1, t2, t6
    slli    t2, a0, 16
    srli    t2, t2, 16
    slli    t1, t1, 16
    or      t2, t2, t1              # t = rem:lo[15:0]
    divu    t4, t2, t6              # q0
    remu    t1, t2, t6              # digit
    slli    t3, t3, 16
    or      a0, t3, t4              # q_lo
    addi    t1, t1, '0'
    addi    t0, t0, -1
    sb      t1, 0(t0)
    or      t2, a0, a1
    bnez    t2, 1b
    mv      a0, t0
    call    print_str
    lw      ra, 44(sp)
    addi    sp, sp, 48
    ret
