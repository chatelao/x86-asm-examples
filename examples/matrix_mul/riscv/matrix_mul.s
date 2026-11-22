# =============================================================================
# RVV 4x4 Single-Precision (FP32) Matrix Multiplication: C = alpha * A * B
#
# Uses Zve32f with VLEN=128 (SEW=32, LMUL=1 -> 4 floats per vector register),
# so each row of B fits in a single vector register (v4..v7). Each row i of C
# is accumulated via C[i] = sum_k A[i][k] * B[k] using vfmacc.vf, then scaled
# by alpha via vfmul.vf and stored to matrix_c on the stack.
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -96             # 64 bytes for matrix_c + saved regs (16B aligned)
    sw      ra, 92(sp)
    sw      s0, 88(sp)
    sw      s1, 84(sp)
    sw      s2, 80(sp)

    # Set VL = 4, SEW = 32-bit float, LMUL = 1
    vsetivli zero, 4, e32, m1, ta, ma

    # Preload all 4 rows of B into v4..v7
    la      t0, matrix_b
    vle32.v v4, (t0)                # B[0]
    addi    t0, t0, 16
    vle32.v v5, (t0)                # B[1]
    addi    t0, t0, 16
    vle32.v v6, (t0)                # B[2]
    addi    t0, t0, 16
    vle32.v v7, (t0)                # B[3]

    la      t0, alpha
    flw     ft4, 0(t0)              # ft4 = alpha (1.0f)
    fmv.w.x ft5, zero               # ft5 = 0.0f

    la      t1, matrix_a            # Pointer to current row of A
    mv      t2, sp                  # Pointer to current row of C (64 bytes at sp)
    li      t3, 4                   # Row counter

.Lrow_loop:
    vfmv.v.f v0, ft5                # Zero accumulator row C[i]

    flw     ft0, 0(t1)              # A[i][0]
    vfmacc.vf v0, ft0, v4           # C[i] += A[i][0] * B[0]

    flw     ft1, 4(t1)              # A[i][1]
    vfmacc.vf v0, ft1, v5           # C[i] += A[i][1] * B[1]

    flw     ft2, 8(t1)              # A[i][2]
    vfmacc.vf v0, ft2, v6           # C[i] += A[i][2] * B[2]

    flw     ft3, 12(t1)             # A[i][3]
    vfmacc.vf v0, ft3, v7           # C[i] += A[i][3] * B[3]

    vfmul.vf v0, v0, ft4            # C[i] *= alpha
    vse32.v v0, (t2)                # Store row C[i]

    addi    t1, t1, 16
    addi    t2, t2, 16
    addi    t3, t3, -1
    bnez    t3, .Lrow_loop

    # ---------------------------- Print inputs ------------------------------
    la      a0, input_a_msg
    call    print_str
    la      a0, matrix_a
    call    print_matrix

    la      a0, input_b_msg
    call    print_str
    la      a0, matrix_b
    call    print_matrix

    la      a0, alpha_prefix
    call    print_str
    la      t0, alpha
    flw     fa0, 0(t0)
    li      a0, 0
    call    print_f1_w
    li      a0, '\n'
    call    print_char

    # ---------------------------- Print output ------------------------------
    la      a0, header_msg
    call    print_str
    mv      a0, sp                  # Result matrix C on the stack
    call    print_matrix

    li      a0, 0                   # Return 0
    lw      s2, 80(sp)
    lw      s1, 84(sp)
    lw      s0, 88(sp)
    lw      ra, 92(sp)
    addi    sp, sp, 96
    ret

# -----------------------------------------------------------------------------
# print_matrix(a0 = const float *m): print a 4x4 FP32 matrix, one row per line.
# Format per row: "[ %5.1f %5.1f %5.1f %5.1f ]\n"
# -----------------------------------------------------------------------------
print_matrix:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    sw      s1, 4(sp)
    sw      s2, 0(sp)

    mv      s0, a0                  # Row pointer
    li      s1, 4                   # Row counter

.Lprint_row:
    la      a0, row_open            # "[ "
    call    print_str

    li      s2, 4                   # Column counter
.Lprint_col:
    flw     fa0, 0(s0)
    li      a0, 5                   # Width 5 ("%5.1f")
    call    print_f1_w
    li      a0, ' '
    call    print_char
    addi    s0, s0, 4
    addi    s2, s2, -1
    bnez    s2, .Lprint_col

    la      a0, row_close           # "]\n"
    call    print_str

    addi    s1, s1, -1
    bnez    s1, .Lprint_row

    lw      s2, 0(sp)
    lw      s1, 4(sp)
    lw      s0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

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
alpha_prefix:
    .asciz  "Input alpha = "
header_msg:
    .asciz  "Result of 4x4 Matrix Multiplication (C = A * B):\n"
row_open:
    .asciz  "[ "
row_close:
    .asciz  "]\n"
