# =============================================================================
# Vector String Reversal using RVV (Zve32f, SEW=8, LMUL=1)
#
# Reverses "x86-64 Assembly" (15 bytes) into "ylbmessA 46-68x" using a
# strip-mined RVV loop: for each chunk of vl bytes from the end of the source,
# vid.v + vrsub.vx builds reversed indices [vl-1, ..., 0] and vrgather.vv
# permutes the bytes in a single vector register.
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)

    la      t0, src_str_end         # t0 = end pointer (just past last char)
    la      t4, src_str
    sub     t1, t0, t4              # Remaining bytes (15)
    la      t2, dst_buf             # t2 = destination write pointer

.Lrev_loop:
    vsetvli t3, t1, e8, m1, ta, ma  # vl = min(remaining, VLMAX)
    sub     t0, t0, t3              # Step back to start of trailing vl-byte chunk
    vle8.v  v0, (t0)                # Load chunk
    vid.v   v1                      # v1 = [0, 1, ..., vl-1]
    addi    t4, t3, -1
    vrsub.vx v1, v1, t4             # v1 = [vl-1, ..., 1, 0]
    vrgather.vv v2, v0, v1          # Permute bytes in reverse order
    vse8.v  v2, (t2)                # Store reversed chunk
    add     t2, t2, t3
    sub     t1, t1, t3
    bnez    t1, .Lrev_loop

    li      t4, '\n'
    sb      t4, 0(t2)               # Append newline
    sb      zero, 1(t2)             # Null-terminate

    la      a0, dst_buf
    call    print_str

    li      a0, 0                   # Return 0
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
src_str:
    .ascii  "x86-64 Assembly"
src_str_end:

    .bss
    .balign 16
dst_buf:
    .space  17                      # Reversed string (15) + '\n' + '\0'
