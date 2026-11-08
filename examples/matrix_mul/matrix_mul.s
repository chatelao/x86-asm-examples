    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # Save non-volatile registers (Windows x64 ABI)
    pushq   %rsi
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

    # Print header message
    leaq    header_msg(%rip), %rcx
    call    puts

    # Print each of the 4 rows of C using Windows x64 variadic calling convention
    leaq    64(%rsp), %rbx          # Pointer to current row of C
    movl    $4, %esi                # Row loop counter

.Lprint_row:
    vcvtss2sd   0(%rbx), %xmm1, %xmm1
    vmovq       %xmm1, %rdx         # 2nd arg (row[0]) in both %xmm1 and %rdx
    vcvtss2sd   4(%rbx), %xmm2, %xmm2
    vmovq       %xmm2, %r8          # 3rd arg (row[1]) in both %xmm2 and %r8
    vcvtss2sd   8(%rbx), %xmm3, %xmm3
    vmovq       %xmm3, %r9          # 4th arg (row[2]) in both %xmm3 and %r9
    vcvtss2sd   12(%rbx), %xmm0, %xmm0
    vmovsd      %xmm0, 32(%rsp)     # 5th arg (row[3]) on stack above shadow space
    leaq        row_fmt(%rip), %rcx # 1st arg (format string) in %rcx
    call        printf

    addq    $16, %rbx               # Advance to next row (4 floats = 16 bytes)
    decl    %esi
    jnz     .Lprint_row

    xorl    %eax, %eax              # Return 0
    leaq    -16(%rbp), %rsp
    popq    %rsi
    popq    %rbx
    popq    %rbp
    ret

    .section .rdata,"dr"
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

header_msg:
    .asciz  "Result of 4x4 Matrix Multiplication (C = A * B):"
row_fmt:
    .asciz  "[ %5.1f %5.1f %5.1f %5.1f ]\n"
