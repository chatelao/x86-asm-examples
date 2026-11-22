@ =============================================================================
@ CPUID Processor Identification for Arm Cortex-M55 (QEMU mps3-an547)
@ Reads SCB->CPUID (0xE000ED00) and decodes:
@   - Implementer [31:24] (0x41 = Arm)
@   - Variant     [23:20] (r in rXpY)
@   - PartNo      [15:4]  (0xD22 = Cortex-M55)
@   - Revision    [3:0]   (p in rXpY)
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4-r7, lr}

    ldr     r0, =0xE000ED00         @ SCB->CPUID
    ldr     r4, [r0]

    ubfx    r5, r4, #24, #8         @ Implementer [31:24]
    ubfx    r6, r4, #4, #12         @ PartNo      [15:4]
    ubfx    r7, r4, #20, #4         @ Variant     [23:20]

    ldr     r0, =s_prefix
    bl      print_str

    cmp     r5, #0x41               @ 0x41 = Arm
    bne     .Lvendor_unknown
    ldr     r0, =s_arm
    bl      print_str
    b       .Lprint_cpuid
.Lvendor_unknown:
    ldr     r0, =s_unknown
    bl      print_str

.Lprint_cpuid:
    ldr     r0, =s_cpuid
    bl      print_str
    mov     r0, r4
    movs    r1, #8
    bl      print_hex

    ldr     r0, =s_part
    bl      print_str
    ldr     r0, =0xD22              @ Cortex-M55 PartNo
    cmp     r6, r0
    bne     .Lpart_unknown
    ldr     r0, =s_cm55
    bl      print_str
    b       .Lprint_rev
.Lpart_unknown:
    ldr     r0, =s_hex_prefix
    bl      print_str
    mov     r0, r6
    movs    r1, #3
    bl      print_hex

.Lprint_rev:
    ldr     r0, =s_r
    bl      print_str
    mov     r0, r7                  @ Variant (r)
    bl      print_udec
    movs    r0, #'p'
    bl      print_char
    and     r0, r4, #0xF            @ Revision (p)
    bl      print_udec
    ldr     r0, =s_end
    bl      print_str

    movs    r0, #0                  @ Return 0
    pop     {r4-r7, pc}

    .section .rodata
s_prefix:
    .asciz  "CPU Vendor: "
s_arm:
    .asciz  "Arm"
s_unknown:
    .asciz  "Unknown"
s_cpuid:
    .asciz  " (CPUID: 0x"
s_part:
    .asciz  ", Part: "
s_cm55:
    .asciz  "Cortex-M55"
s_hex_prefix:
    .asciz  "0x"
s_r:
    .asciz  " r"
s_end:
    .asciz  ")\n"
