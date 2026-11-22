@ =============================================================================
@ Arm Helium (MVE) 4x4 Single-Precision (FP32) Matrix Multiplication
@ Computes C = alpha * A * B where A, B, C are 4x4 row-major FP32 matrices.
@ Each row of B (4 floats = 128 bits) is held in a Q-register (q4..q7), and
@ each row of C is accumulated using vector-by-scalar vmul.f32 / vfma.f32
@ (Qd, Qn, Rm) followed by scaling by alpha.
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, r5, r6, lr}
    vpush   {d8-d15}                @ Preserve callee-saved q4..q7 (s16..s31)
    sub     sp, sp, #64             @ 64-byte stack buffer for result matrix C

    ldr     r4, =matrix_a
    ldr     r5, =matrix_b
    ldr     r6, =alpha
    ldr     r12, [r6]               @ r12 = alpha (IEEE-754 bits)

    @ Load all 4 rows of B into q4..q7
    vldrw.32 q4, [r5, #0]           @ B[0][0..3]
    vldrw.32 q5, [r5, #16]          @ B[1][0..3]
    vldrw.32 q6, [r5, #32]          @ B[2][0..3]
    vldrw.32 q7, [r5, #48]          @ B[3][0..3]

    mov     r1, sp                  @ r1 = &C[0][0]
    movs    r2, #4                  @ 4 rows of A

.Lrow_loop:
    ldr     r0, [r4], #4            @ A[i][0]
    vmul.f32 q0, q4, r0             @ C[i] = A[i][0] * B[0]
    ldr     r0, [r4], #4            @ A[i][1]
    vfma.f32 q0, q5, r0             @ C[i] += A[i][1] * B[1]
    ldr     r0, [r4], #4            @ A[i][2]
    vfma.f32 q0, q6, r0             @ C[i] += A[i][2] * B[2]
    ldr     r0, [r4], #4            @ A[i][3]
    vfma.f32 q0, q7, r0             @ C[i] += A[i][3] * B[3]
    vmul.f32 q0, q0, r12            @ C[i] *= alpha
    vstrw.32 q0, [r1], #16          @ Store C[i][0..3]
    subs    r2, r2, #1
    bne     .Lrow_loop

    @ ---------------------------- Print inputs ------------------------------
    ldr     r0, =input_a_msg
    bl      print_str
    ldr     r0, =matrix_a
    bl      print_matrix

    ldr     r0, =input_b_msg
    bl      print_str
    ldr     r0, =matrix_b
    bl      print_matrix

    ldr     r0, =alpha_msg
    bl      print_str
    ldr     r0, =alpha
    vldr.f32 s0, [r0]
    movs    r0, #0
    bl      print_f1_w
    movs    r0, #'\n'
    bl      print_char

    @ ---------------------------- Print output ------------------------------
    ldr     r0, =header_msg
    bl      print_str
    mov     r0, sp
    bl      print_matrix

    movs    r0, #0                  @ Return 0
    add     sp, sp, #64
    vpop    {d8-d15}
    pop     {r4, r5, r6, pc}

@ -----------------------------------------------------------------------------
@ print_matrix: print a 4x4 FP32 matrix, one row per line.
@   r0 = pointer to 16 row-major floats
@ -----------------------------------------------------------------------------
    .thumb_func
print_matrix:
    push    {r4, r5, r6, lr}
    mov     r4, r0                  @ Current element pointer
    movs    r5, #4                  @ Row counter

.Lprint_row:
    ldr     r0, =row_open
    bl      print_str
    movs    r6, #4                  @ Column counter

.Lprint_col:
    vldr.f32 s0, [r4]
    adds    r4, r4, #4
    movs    r0, #5                  @ %5.1f
    bl      print_f1_w
    movs    r0, #' '
    bl      print_char
    subs    r6, r6, #1
    bne     .Lprint_col

    ldr     r0, =row_close
    bl      print_str
    subs    r5, r5, #1
    bne     .Lprint_row

    pop     {r4, r5, r6, pc}

    .section .rodata
    .balign 16
matrix_a:
    .float   1.0,  2.0,  3.0,  4.0
    .float   5.0,  6.0,  7.0,  8.0
    .float   9.0, 10.0, 11.0, 12.0
    .float  13.0, 14.0, 15.0, 16.0

    .balign 16
matrix_b:
    .float  16.0, 15.0, 14.0, 13.0
    .float  12.0, 11.0, 10.0,  9.0
    .float   8.0,  7.0,  6.0,  5.0
    .float   4.0,  3.0,  2.0,  1.0

alpha:
    .float   1.0

input_a_msg:
    .asciz  "Input matrix A:\n"
input_b_msg:
    .asciz  "Input matrix B:\n"
alpha_msg:
    .asciz  "Input alpha = "
header_msg:
    .asciz  "Result of 4x4 Matrix Multiplication (C = A * B):\n"
row_open:
    .asciz  "[ "
row_close:
    .asciz  "]\n"
