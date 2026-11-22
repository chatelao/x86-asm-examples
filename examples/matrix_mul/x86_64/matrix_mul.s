#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # Save non-volatile registers
    pushq   %r12
    andq    $-64, %rsp              # Align stack to 64 bytes for 512-bit AVX-512 vectors
    subq    $128, %rsp              # 0..31: shadow space, 32..39: 5th arg, 64..127: matrix_c

    # -------------------------------------------------------------------------
    # AVX-512 4x4 Single-Precision (FP32) Matrix Multiplication: C = alpha * A * B
    # Fits an entire 4x4 FP32 matrix (16 floats = 512 bits) in a single ZMM register.
    # Uses AVX-512 upper registers (%zmm16-%zmm20), opmask (%k1), in-lane
    # permutation (vpermilps), 128-bit lane broadcast (vbroadcastf32x4),
    # scalar broadcast (vbroadcastss), and 512-bit fused multiply-add (vfmadd231ps).
    # -------------------------------------------------------------------------

    movl    $0xffff, %eax
    kmovw   %eax, %k1               # Enable all 16 FP32 lanes in AVX-512 opmask %k1

    vpxord  %zmm19, %zmm19, %zmm19  # Zero 512-bit accumulator %zmm19 (holds all 16 floats of C)

    # Load entire 4x4 matrix A (16 floats = 512 bits) into %zmm16 with zero-masking
    vmovups matrix_a(%rip), %zmm16{%k1}{z}

    # k = 0: Broadcast column 0 of each row of A, broadcast row 0 of B, 16-lane FMA
    vpermilps       $0x00, %zmm16, %zmm17
    vbroadcastf32x4 matrix_b+0(%rip), %zmm18
    vfmadd231ps     %zmm18, %zmm17, %zmm19{%k1}

    # k = 1: Broadcast column 1 of each row of A, broadcast row 1 of B, 16-lane FMA
    vpermilps       $0x55, %zmm16, %zmm17
    vbroadcastf32x4 matrix_b+16(%rip), %zmm18
    vfmadd231ps     %zmm18, %zmm17, %zmm19{%k1}

    # k = 2: Broadcast column 2 of each row of A, broadcast row 2 of B, 16-lane FMA
    vpermilps       $0xaa, %zmm16, %zmm17
    vbroadcastf32x4 matrix_b+32(%rip), %zmm18
    vfmadd231ps     %zmm18, %zmm17, %zmm19{%k1}

    # k = 3: Broadcast column 3 of each row of A, broadcast row 3 of B, 16-lane FMA
    vpermilps       $0xff, %zmm16, %zmm17
    vbroadcastf32x4 matrix_b+48(%rip), %zmm18
    vfmadd231ps     %zmm18, %zmm17, %zmm19{%k1}

    # Broadcast scalar alpha (1.0f) across all 16 lanes and scale result
    vbroadcastss    alpha(%rip), %zmm20{%k1}{z}
    vmulps          %zmm20, %zmm19, %zmm19{%k1}

    # Store all 16 floats of result matrix C to 64-byte-aligned stack buffer
    vmovaps %zmm19, 64(%rsp){%k1}
    vzeroupper                      # Clean upper vector state before calling C library

    # ---------------------------- Print inputs ------------------------------
#ifdef _WIN32
    leaq    input_a_msg(%rip), %rcx
    call    puts
    leaq    matrix_a(%rip), %rcx
    call    print_matrix

    leaq    input_b_msg(%rip), %rcx
    call    puts
    leaq    matrix_b(%rip), %rcx
    call    print_matrix

    vcvtss2sd   alpha(%rip), %xmm1, %xmm1
    vmovq       %xmm1, %rdx         # 2nd arg (alpha) in both %xmm1 and %rdx
    leaq        alpha_fmt(%rip), %rcx
    call        printf

    # ---------------------------- Print output ------------------------------
    leaq    header_msg(%rip), %rcx
    call    puts
    leaq    64(%rsp), %rcx          # Result matrix C on the stack
    call    print_matrix
#else
    leaq    input_a_msg(%rip), %rdi
    call    puts
    leaq    matrix_a(%rip), %rdi
    call    print_matrix

    leaq    input_b_msg(%rip), %rdi
    call    puts
    leaq    matrix_b(%rip), %rdi
    call    print_matrix

    vcvtss2sd   alpha(%rip), %xmm0, %xmm0
    leaq        alpha_fmt(%rip), %rdi
    movb        $1, %al             # 1 XMM register
    call        printf

    # ---------------------------- Print output ------------------------------
    leaq    header_msg(%rip), %rdi
    call    puts
    leaq    64(%rsp), %rdi          # Result matrix C on the stack
    call    print_matrix
#endif

    xorl    %eax, %eax              # Return 0
    leaq    -16(%rbp), %rsp
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

# -----------------------------------------------------------------------------
# print_matrix: print a 4x4 FP32 matrix, one row per line.
#   %rcx (Win64) / %rdi (SysV) = pointer to 16 row-major floats
# -----------------------------------------------------------------------------
    DEF_FUNC(print_matrix)
print_matrix:
    pushq   %rbx                    # Non-volatile: row pointer
    pushq   %r12                    # Non-volatile: row counter
#ifdef _WIN32
    subq    $40, %rsp               # 32-byte shadow space + 5th arg; keeps 16-byte alignment
    movq    %rcx, %rbx              # Pointer to current row
#else
    subq    $8, %rsp                # Keep 16-byte stack alignment
    movq    %rdi, %rbx              # Pointer to current row
#endif
    movl    $4, %r12d               # Row loop counter

.Lprint_row:
#ifdef _WIN32
    vcvtss2sd   0(%rbx), %xmm1, %xmm1
    vmovq       %xmm1, %rdx         # 2nd arg (row[0]) in both %xmm1 and %rdx
    vcvtss2sd   4(%rbx), %xmm2, %xmm2
    vmovq       %xmm2, %r8          # 3rd arg (row[1]) in both %xmm2 and %r8
    vcvtss2sd   8(%rbx), %xmm3, %xmm3
    vmovq       %xmm3, %r9          # 4th arg (row[2]) in both %xmm3 and %r9
    vcvtss2sd   12(%rbx), %xmm0, %xmm0
    vmovsd      %xmm0, 32(%rsp)     # 5th arg (row[3]) on stack above shadow space
    leaq        row_fmt(%rip), %rcx # 1st arg (format string) in %rcx
#else
    vcvtss2sd   0(%rbx), %xmm0, %xmm0
    vcvtss2sd   4(%rbx), %xmm1, %xmm1
    vcvtss2sd   8(%rbx), %xmm2, %xmm2
    vcvtss2sd   12(%rbx), %xmm3, %xmm3
    leaq        row_fmt(%rip), %rdi # 1st arg (format string) in %rdi
    movb        $4, %al             # 4 XMM registers passed to variadic printf
#endif
    call        printf

    addq    $16, %rbx               # Advance to next row (4 floats = 16 bytes)
    decl    %r12d
    jnz     .Lprint_row

#ifdef _WIN32
    addq    $40, %rsp
#else
    addq    $8, %rsp
#endif
    popq    %r12
    popq    %rbx
    ret

    RODATA_SECTION
    .balign 64
matrix_a:
    .float   1.0,  2.0,  3.0,  4.0
    .float   5.0,  6.0,  7.0,  8.0
    .float   9.0, 10.0, 11.0, 12.0
    .float  13.0, 14.0, 15.0, 16.0

    .balign 64
matrix_b:
    .float  16.0, 15.0, 14.0, 13.0
    .float  12.0, 11.0, 10.0,  9.0
    .float   8.0,  7.0,  6.0,  5.0
    .float   4.0,  3.0,  2.0,  1.0

alpha:
    .float   1.0

input_a_msg:
    .asciz  "Input matrix A:"
input_b_msg:
    .asciz  "Input matrix B:"
alpha_fmt:
    .asciz  "Input alpha = %.1f\n"
header_msg:
    .asciz  "Result of 4x4 Matrix Multiplication (C = A * B):"
row_fmt:
    .asciz  "[ %5.1f %5.1f %5.1f %5.1f ]\n"

    GNU_STACK_NOTE
