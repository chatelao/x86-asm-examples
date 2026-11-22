@ =============================================================================
@ 64-bit Bit Manipulation on Arm Cortex-M55 (bare metal, QEMU mps3-an547)
@ Operates on 0x00F0F0F000001000 held in two 32-bit registers (r4=lo, r5=hi):
@ - popcnt: SWAR parallel bit-count (Armv8-M has no scalar POPCNT instruction)
@ - tzcnt:  Trailing zero count via RBIT + CLZ
@ - lzcnt:  Leading zero count via CLZ
@ - bswap:  64-bit endianness swap via REV on each half + word swap
@ =============================================================================
    .syntax unified
    .thumb
    .text

@ -----------------------------------------------------------------------------
@ popcnt32: SWAR 32-bit population count
@ Input:  r0 = 32-bit word
@ Output: r0 = number of set bits
@ -----------------------------------------------------------------------------
    .thumb_func
popcnt32:
    ldr     r1, =0x55555555
    and     r2, r1, r0, lsr #1
    subs    r0, r0, r2              @ 2-bit sums
    ldr     r1, =0x33333333
    and     r2, r1, r0, lsr #2
    and     r0, r0, r1
    adds    r0, r0, r2              @ 4-bit sums
    adds    r0, r0, r0, lsr #4
    ldr     r1, =0x0F0F0F0F
    and     r0, r0, r1              @ 8-bit sums
    ldr     r1, =0x01010101
    mul     r0, r0, r1              @ Sum all 4 bytes into top byte
    lsrs    r0, r0, #24
    bx      lr

    .thumb_func
    .global main
main:
    push    {r4-r9, r10, lr}

    ldr     r4, =0x00001000         @ Low 32 bits
    ldr     r5, =0x00F0F0F0         @ High 32 bits

    @ 1. Population count (sum of 32-bit popcounts)
    mov     r0, r4
    bl      popcnt32
    mov     r6, r0
    mov     r0, r5
    bl      popcnt32
    add     r6, r6, r0              @ r6 = total popcnt (13)

    @ 2. Trailing zero count via RBIT + CLZ
    cbz     r4, .Ltz_hi
    rbit    r0, r4
    clz     r7, r0                  @ r7 = tzcnt (12)
    b       .Ltz_done
.Ltz_hi:
    rbit    r0, r5
    clz     r7, r0
    adds    r7, r7, #32
.Ltz_done:

    @ 3. Leading zero count via CLZ
    cbz     r5, .Llz_lo
    clz     r8, r5                  @ r8 = lzcnt (8)
    b       .Llz_done
.Llz_lo:
    clz     r8, r4
    adds    r8, r8, #32
.Llz_done:

    @ 4. 64-bit byte swap via REV + word swap
    rev     r9, r5                  @ Swapped low word  = rev(hi)
    rev     r10, r4                 @ Swapped high word = rev(lo)

    @ Print results: "popcnt=13 tzcnt=12 lzcnt=8 bswap=0x00100000F0F0F000\n"
    ldr     r0, =s_popcnt
    bl      print_str
    mov     r0, r6
    bl      print_udec

    ldr     r0, =s_tzcnt
    bl      print_str
    mov     r0, r7
    bl      print_udec

    ldr     r0, =s_lzcnt
    bl      print_str
    mov     r0, r8
    bl      print_udec

    ldr     r0, =s_bswap
    bl      print_str
    mov     r0, r10                 @ High 32 bits first
    movs    r1, #8
    bl      print_hex
    mov     r0, r9                  @ Low 32 bits second
    movs    r1, #8
    bl      print_hex
    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    pop     {r4-r9, r10, pc}

    .section .rodata
s_popcnt:
    .asciz  "popcnt="
s_tzcnt:
    .asciz  " tzcnt="
s_lzcnt:
    .asciz  " lzcnt="
s_bswap:
    .asciz  " bswap=0x"
