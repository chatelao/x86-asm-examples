# =============================================================================
# RVV 8-Element FP32 Vector Dot Product (Zve32f, SEW=32, LMUL=1)
#
# Computes [1, 2, 3, 4, 5, 6, 7, 8] . [8, 7, 6, 5, 4, 3, 2, 1] = 120.0
# using a strip-mined RVV loop (vsetvli, vle32.v, vfmacc.vv) and a
# horizontal floating-point reduction (vfredusum.vs).
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)

    la      t0, vec_a
    la      t1, vec_b
    li      t2, 8                   # Remaining element count

    # Zero-initialize full vector accumulator v0 and scalar reduction seed v1[0]
    vsetvli t4, zero, e32, m1, ta, ma
    fmv.w.x ft0, zero               # ft0 = 0.0f
    vfmv.v.f v0, ft0                # v0 = [0.0, ...] across all VLMAX lanes
    vfmv.s.f v1, ft0                # v1[0] = 0.0f

.Ldot_loop:
    vsetvli t3, t2, e32, m1, tu, ma # Tail-undisturbed keeps unused v0 lanes 0.0f
    vle32.v v2, (t0)                # Load chunk of vec_a
    vle32.v v3, (t1)                # Load chunk of vec_b
    vfmacc.vv v0, v2, v3            # v0 += v2 * v3

    slli    t4, t3, 2               # Byte advance = vl * 4
    add     t0, t0, t4
    add     t1, t1, t4
    sub     t2, t2, t3
    bnez    t2, .Ldot_loop

    # Reduce all VLMAX lanes of v0 into v1[0]
    vsetvli t4, zero, e32, m1, ta, ma
    vfredusum.vs v1, v0, v1
    vfmv.f.s fa0, v1                # Scalar float result in fa0

    # Save fa0 across print_str (print_str only clobbers caller-saved regs)
    fsw     fa0, 8(sp)
    la      a0, fmt_prefix
    call    print_str
    flw     fa0, 8(sp)
    li      a0, 0                   # Width 0 ("%*.1f" -> "%.1f")
    call    print_f1_w
    li      a0, '\n'
    call    print_char

    li      a0, 0                   # Return 0
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
    .balign 16
vec_a:
    .float  1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
vec_b:
    .float  8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0
fmt_prefix:
    .asciz  "Dot product = "
