#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # %rbx is clobbered by cpuid and callee-saved in both ABIs
#ifdef _WIN32
    subq    $56, %rsp               # 0..31: shadow space, 32..47: vendor string buffer (+8B align)
#else
    subq    $24, %rsp               # 0..15: vendor string buffer (+8B align)
#endif

    # -------------------------------------------------------------------------
    # CPUID Processor Vendor Identification
    # Executes cpuid with %eax = 0 to retrieve the 12-character ASCII vendor ID
    # returned across %ebx (bytes 0..3), %edx (bytes 4..7), and %ecx (bytes 8..11).
    # -------------------------------------------------------------------------

    xorl    %eax, %eax              # CPUID leaf 0: Highest Function Parameter & Manufacturer ID
    cpuid
#ifdef _WIN32
    movl    %ebx, 32(%rsp)          # First 4 characters  (e.g. "Genu" or "Auth")
    movl    %edx, 36(%rsp)          # Middle 4 characters (e.g. "ineI" or "enti")
    movl    %ecx, 40(%rsp)          # Last 4 characters   (e.g. "ntel" or "cAMD")
    movb    $0,   44(%rsp)          # Null-terminate the 12-byte vendor string

    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    leaq    32(%rsp), %rdx          # 2nd arg: pointer to vendor ID string
    movl    %eax, %r8d              # 3rd arg: max supported basic CPUID leaf
#else
    movl    %ebx, 0(%rsp)           # First 4 characters
    movl    %edx, 4(%rsp)           # Middle 4 characters
    movl    %ecx, 8(%rsp)           # Last 4 characters
    movb    $0,   12(%rsp)          # Null-terminate the 12-byte vendor string

    leaq    fmt_str(%rip), %rdi     # 1st arg: format string
    leaq    0(%rsp), %rsi           # 2nd arg: pointer to vendor ID string
    movl    %eax, %edx              # 3rd arg: max supported basic CPUID leaf
    xorl    %eax, %eax              # 0 XMM args
#endif
    call    printf

    xorl    %eax, %eax              # Return 0
#ifdef _WIN32
    addq    $56, %rsp
#else
    addq    $24, %rsp
#endif
    popq    %rbx
    popq    %rbp
    ret

    RODATA_SECTION
fmt_str:
    .asciz  "CPU Vendor: %s (Max Basic Leaf: 0x%X)\n"

    GNU_STACK_NOTE
