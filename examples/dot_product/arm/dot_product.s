@ =============================================================================
@ Arm Helium (MVE) 8-Element FP32 Vector Dot Product (Cortex-M55)
@ Computes [1, 2, 3, 4, 5, 6, 7, 8] . [8, 7, 6, 5, 4, 3, 2, 1] = 120.0
@ using 128-bit Q-registers (vldrw.32, vmul.f32, vfma.f32) and horizontal
@ reduction across the four FP32 lanes of q2 (s8..s11).
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, lr}
    vpush   {d8}                    @ Preserve callee-saved s16/s17

    ldr     r0, =vec_a
    ldr     r1, =vec_b

    vldrw.32 q0, [r0]               @ Load vec_a[0..3]
    vldrw.32 q1, [r1]               @ Load vec_b[0..3]
    vmul.f32 q2, q0, q1             @ q2 = vec_a[0..3] * vec_b[0..3]

    vldrw.32 q0, [r0, #16]          @ Load vec_a[4..7]
    vldrw.32 q1, [r1, #16]          @ Load vec_b[4..7]
    vfma.f32 q2, q0, q1             @ q2 += vec_a[4..7] * vec_b[4..7]

    @ Reduce the 4 FP32 lanes of q2 (aliased as s8, s9, s10, s11) to s16
    vadd.f32 s0, s8, s9
    vadd.f32 s1, s10, s11
    vadd.f32 s16, s0, s1            @ s16 = 120.0

    ldr     r0, =prefix_str
    bl      print_str

    vmov.f32 s0, s16                @ 1st float arg: dot product
    movs    r0, #0                  @ width = 0
    bl      print_f1_w

    movs    r0, #'\n'
    bl      print_char

    movs    r0, #0                  @ Return 0
    vpop    {d8}
    pop     {r4, pc}

    .section .rodata
    .balign 16
vec_a:
    .float  1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
    .balign 16
vec_b:
    .float  8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0
prefix_str:
    .asciz  "Dot product = "
