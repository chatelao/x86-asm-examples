    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate 32-byte shadow space

    # -------------------------------------------------------------------------
    # Hardware-Accelerated CRC-32C Checksum (SSE4.2 crc32q / crc32b)
    # Computes the CRC-32C hash of the 12-byte buffer "Hello, CRC32"
    # using a 64-bit crc32q step followed by four 8-bit crc32b steps.
    # -------------------------------------------------------------------------

    leaq    payload(%rip), %r8
    movl    $0xFFFFFFFF, %eax       # Initial CRC-32C seed

    crc32q  0(%r8), %rax            # Process first 8 bytes ("Hello, C") in one instruction
    crc32b  8(%r8), %eax            # Process byte 8  ('R')
    crc32b  9(%r8), %eax            # Process byte 9  ('C')
    crc32b  10(%r8), %eax           # Process byte 10 ('3')
    crc32b  11(%r8), %eax           # Process byte 11 ('2')

    notl    %eax                    # Finalize CRC-32C via bitwise inversion

    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    movq    %r8, %rdx               # 2nd arg: payload string
    movl    %eax, %r8d              # 3rd arg: CRC-32C value
    call    printf

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
payload:
    .asciz  "Hello, CRC32"
fmt_str:
    .asciz  "CRC32C(\"%s\") = 0x%08X\n"
