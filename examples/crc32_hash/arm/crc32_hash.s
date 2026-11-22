@ =============================================================================
@ Software CRC-32C (Castagnoli) Checksum for Arm Cortex-M55 (QEMU mps3-an547)
@ Armv8-M lacks hardware CRC instructions, so this computes the reflected
@ CRC-32C (polynomial 0x82F63B78, init 0xFFFFFFFF, final XOR 0xFFFFFFFF)
@ bitwise over the 12-byte buffer "Hello, CRC32".
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, r5, r6, lr}

    ldr     r1, =payload            @ Pointer to input string
    mvn     r4, #0                  @ Initial CRC-32C seed = 0xFFFFFFFF
    ldr     r3, =0x82F63B78         @ Reflected Castagnoli polynomial

.Lbyte_loop:
    ldrb    r2, [r1], #1
    cbz     r2, .Lcrc_done          @ Stop at NUL terminator
    eor     r4, r4, r2              @ Mix next byte into low 8 bits of CRC

    movs    r5, #8                  @ Process 8 bits LSB-first
.Lbit_loop:
    lsrs    r4, r4, #1              @ Shift out LSB into carry
    it      cs
    eorcs   r4, r4, r3              @ XOR polynomial if shifted-out bit was 1
    subs    r5, r5, #1
    bne     .Lbit_loop
    b       .Lbyte_loop

.Lcrc_done:
    mvn     r4, r4                  @ Finalize CRC-32C via bitwise inversion

    ldr     r0, =prefix_str
    bl      print_str
    ldr     r0, =payload
    bl      print_str
    ldr     r0, =mid_str
    bl      print_str
    mov     r0, r4
    movs    r1, #8
    bl      print_hex
    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    pop     {r4, r5, r6, pc}

    .section .rodata
payload:
    .asciz  "Hello, CRC32"
prefix_str:
    .asciz  "CRC32C(\""
mid_str:
    .asciz  "\") = 0x"
