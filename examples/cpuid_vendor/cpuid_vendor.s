    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # %rbx is clobbered by cpuid and non-volatile in Windows x64 ABI
    subq    $56, %rsp               # 0..31: shadow space, 32..47: 13-byte vendor string buffer

    # -------------------------------------------------------------------------
    # CPUID Processor Vendor Identification
    # Executes cpuid with %eax = 0 to retrieve the 12-character ASCII vendor ID
    # returned across %ebx (bytes 0..3), %edx (bytes 4..7), and %ecx (bytes 8..11).
    # -------------------------------------------------------------------------

    xorl    %eax, %eax              # CPUID leaf 0: Highest Function Parameter & Manufacturer ID
    cpuid

    movl    %ebx, 32(%rsp)          # First 4 characters  (e.g. "Genu" or "Auth")
    movl    %edx, 36(%rsp)          # Middle 4 characters (e.g. "ineI" or "enti")
    movl    %ecx, 40(%rsp)          # Last 4 characters   (e.g. "ntel" or "cAMD")
    movb    $0,   44(%rsp)          # Null-terminate the 12-byte vendor string

    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    leaq    32(%rsp), %rdx          # 2nd arg: pointer to vendor ID string
    movl    %eax, %r8d              # 3rd arg: max supported basic CPUID leaf
    call    printf

    xorl    %eax, %eax              # Return 0
    addq    $56, %rsp
    popq    %rbx
    popq    %rbp
    ret

    .section .rdata,"dr"
fmt_str:
    .asciz  "CPU Vendor: %s (Max Basic Leaf: 0x%X)\n"
