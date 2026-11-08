    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate 32-byte shadow space

    # -------------------------------------------------------------------------
    # AVX 256-bit 8-Element FP32 Vector Dot Product
    # Computes [1, 2, 3, 4, 5, 6, 7, 8] . [8, 7, 6, 5, 4, 3, 2, 1] = 120.0
    # using 256-bit %ymm registers, vmulps, vextractf128, and vhaddps.
    # -------------------------------------------------------------------------

    vmovups         vec_a(%rip), %ymm0
    vmulps          vec_b(%rip), %ymm0, %ymm0   # 8-lane parallel FP32 multiplication
    vextractf128    $1, %ymm0, %xmm1            # Extract upper 128 bits (4 floats)
    vaddps          %xmm1, %xmm0, %xmm0         # Fold 8 floats -> 4 floats in %xmm0
    vhaddps         %xmm0, %xmm0, %xmm0         # Horizontal add: 4 floats -> 2 floats
    vhaddps         %xmm0, %xmm0, %xmm0         # Horizontal add: 2 floats -> scalar sum
    vzeroupper

    vcvtss2sd       %xmm0, %xmm0, %xmm1         # Promote float to double for printf
    vmovq           %xmm1, %rdx                 # 2nd arg in both %xmm1 and %rdx (Windows x64 ABI)
    leaq            fmt_str(%rip), %rcx         # 1st arg: format string
    call            printf

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
    .balign 32
vec_a:
    .float  1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
vec_b:
    .float  8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0
fmt_str:
    .asciz  "Dot product = %.1f\n"
