@ =============================================================================
@ Tiny semihosting console library for bare-metal Arm Cortex-M (AAPCS, hard-float)
@
@   print_str(r0 = const char *s)                 SYS_WRITE0
@   print_char(r0 = char c)                       SYS_WRITEC
@   print_udec(r0 = uint32_t v)                   "%u"
@   print_dec(r0 = int32_t v)                     "%d"
@   print_dec_w(r0 = int32_t v, r1 = width)       "%*d"  (right-aligned)
@   print_udec64(r0 = lo, r1 = hi)                "%llu"
@   print_hex(r0 = uint32_t v, r1 = digits)       "%0*X"
@   print_f1_w(s0 = float v, r0 = width)          "%*.1f"
@
@ All routines preserve r4-r11 and s16-s31 as required by the AAPCS.
@ Semihosting calls use "bkpt 0xAB" with r0 = operation, r1 = parameter.
@ =============================================================================
    .syntax unified
    .thumb
    .text

    .equ    SYS_WRITEC, 0x03
    .equ    SYS_WRITE0, 0x04

@ -----------------------------------------------------------------------------
    .thumb_func
    .global print_str
print_str:
    mov     r1, r0
    movs    r0, #SYS_WRITE0
    bkpt    #0xAB
    bx      lr

@ -----------------------------------------------------------------------------
    .thumb_func
    .global print_char
print_char:
    push    {r0, lr}                @ Character is the low byte of [sp]
    mov     r1, sp
    movs    r0, #SYS_WRITEC
    bkpt    #0xAB
    pop     {r0, pc}

@ -----------------------------------------------------------------------------
    .thumb_func
    .global print_udec
print_udec:
    movs    r1, #0                  @ width 0
    movs    r2, #0                  @ not negative
    mov     r3, #-1                 @ no fractional digit
    b       fmt_print

@ -----------------------------------------------------------------------------
    .thumb_func
    .global print_dec
print_dec:
    movs    r1, #0
    @ fall through
    .thumb_func
    .global print_dec_w
print_dec_w:
    movs    r2, #0
    cmp     r0, #0
    itt     lt
    rsblt   r0, r0, #0              @ magnitude (INT_MIN works as unsigned)
    movlt   r2, #1
    mov     r3, #-1
    b       fmt_print

@ -----------------------------------------------------------------------------
@ print_f1_w: print a float with one decimal, right-aligned in `width` chars.
@ Rounds v * 10 to the nearest integer using the FPU (vcvtr), then splits it.
    .thumb_func
    .global print_f1_w
print_f1_w:
    mov     r1, r0                  @ width
    vmov.f32 s1, #10.0
    vmul.f32 s0, s0, s1
    vcvtr.s32.f32 s0, s0            @ round-to-nearest (FPSCR default mode)
    vmov    r12, s0
    movs    r2, #0
    cmp     r12, #0
    itt     lt
    rsblt   r12, r12, #0
    movlt   r2, #1
    movs    r3, #10
    udiv    r0, r12, r3             @ integer part
    mls     r3, r0, r3, r12         @ fractional digit
    b       fmt_print

@ -----------------------------------------------------------------------------
@ fmt_print: r0 = magnitude, r1 = width, r2 = negative flag, r3 = frac digit/-1
@ Builds the text right-to-left in a stack buffer, then prints it.
    .thumb_func
fmt_print:
    push    {r4-r7, lr}
    sub     sp, sp, #44
    add     r4, sp, #39             @ r4 = write cursor (end of buffer)
    movs    r5, #0
    strb    r5, [r4]                @ NUL terminator
    cmp     r3, #0
    blt     1f
    adds    r3, r3, #'0'
    strb    r3, [r4, #-1]!          @ fractional digit
    movs    r3, #'.'
    strb    r3, [r4, #-1]!
1:  movs    r6, #10
2:  udiv    r5, r0, r6              @ q = v / 10
    mls     r7, r5, r6, r0          @ r = v - q * 10
    adds    r7, r7, #'0'
    strb    r7, [r4, #-1]!
    movs    r0, r5
    cmp     r0, #0
    bne     2b
    cbz     r2, 3f
    movs    r7, #'-'
    strb    r7, [r4, #-1]!
3:  add     r5, sp, #39
    subs    r5, r5, r4              @ current length
    cmp     r1, #32
    it      gt
    movgt   r1, #32                 @ clamp width to buffer size
    movs    r7, #' '
4:  cmp     r5, r1
    bge     5f
    strb    r7, [r4, #-1]!          @ left-pad with spaces
    adds    r5, r5, #1
    b       4b
5:  mov     r0, r4
    bl      print_str
    add     sp, sp, #44
    pop     {r4-r7, pc}

@ -----------------------------------------------------------------------------
@ print_hex: r0 = value, r1 = number of hex digits (1..8), uppercase
    .thumb_func
    .global print_hex
print_hex:
    push    {r4, lr}
    sub     sp, sp, #16
    add     r4, sp, #9
    movs    r2, #0
    strb    r2, [r4]
1:  and     r2, r0, #0xF
    cmp     r2, #10
    ite     lt
    addlt   r2, r2, #'0'
    addge   r2, r2, #('A' - 10)
    strb    r2, [r4, #-1]!
    lsrs    r0, r0, #4
    subs    r1, r1, #1
    bgt     1b
    mov     r0, r4
    bl      print_str
    add     sp, sp, #16
    pop     {r4, pc}

@ -----------------------------------------------------------------------------
@ print_udec64: r0 = low word, r1 = high word. 64-bit / 10 is done with 32-bit
@ udiv in three steps (high word, then two 16-bit halves of the low word).
    .thumb_func
    .global print_udec64
print_udec64:
    push    {r4-r8, lr}
    sub     sp, sp, #32
    add     r4, sp, #31
    movs    r2, #0
    strb    r2, [r4]
    movs    r8, #10
1:  udiv    r5, r1, r8              @ q_hi = hi / 10
    mls     r6, r5, r8, r1          @ rem  = hi % 10
    lsrs    r2, r0, #16
    orr     r2, r2, r6, lsl #16     @ t = rem:lo[31:16]
    udiv    r7, r2, r8
    mls     r6, r7, r8, r2
    uxth    r2, r0
    orr     r2, r2, r6, lsl #16     @ t = rem:lo[15:0]
    udiv    r3, r2, r8
    mls     r6, r3, r8, r2          @ final remainder = digit
    orr     r0, r3, r7, lsl #16     @ q_lo
    mov     r1, r5                  @ q_hi
    adds    r6, r6, #'0'
    strb    r6, [r4, #-1]!
    orrs    r2, r0, r1
    bne     1b
    mov     r0, r4
    bl      print_str
    add     sp, sp, #32
    pop     {r4-r8, pc}
