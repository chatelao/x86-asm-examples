#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text

# -----------------------------------------------------------------------------
# Recursive 64-bit factorial: uint64_t factorial(uint64_t n)
# Input:  %rcx (Win64) / %rdi (SysV) = n
# Output: %rax = n!
# -----------------------------------------------------------------------------
    DEF_FUNC(factorial)
factorial:
#ifdef _WIN32
    cmpq    $1, %rcx
    jbe     .Lbase_case
    pushq   %rcx                    # Save n across recursive call
    subq    $32, %rsp               # Shadow space
    decq    %rcx                    # n - 1
    call    factorial
    addq    $32, %rsp
    popq    %rcx
    imulq   %rcx, %rax              # %rax = n * factorial(n - 1)
    ret
#else
    cmpq    $1, %rdi
    jbe     .Lbase_case
    pushq   %rdi                    # Save n across recursive call (16B aligned after call)
    decq    %rdi                    # n - 1
    call    factorial
    popq    %rdi
    imulq   %rdi, %rax              # %rax = n * factorial(n - 1)
    ret
#endif

.Lbase_case:
    movl    $1, %eax
    ret

main:
    pushq   %rbp
    movq    %rsp, %rbp
#ifdef _WIN32
    subq    $32, %rsp               # Allocate 32-byte shadow space
    movl    $10, %ecx               # Compute 10!
    call    factorial
    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    movl    $10, %edx               # 2nd arg: n = 10
    movq    %rax, %r8               # 3rd arg: 10! = 3628800
#else
    movl    $10, %edi               # Compute 10!
    call    factorial
    leaq    fmt_str(%rip), %rdi     # 1st arg: format string
    movl    $10, %esi               # 2nd arg: n = 10
    movq    %rax, %rdx              # 3rd arg: 10! = 3628800
    xorl    %eax, %eax              # 0 XMM args
#endif
    call    printf

    xorl    %eax, %eax              # Return 0
#ifdef _WIN32
    addq    $32, %rsp
#endif
    popq    %rbp
    ret

    RODATA_SECTION
fmt_str:
    .asciz  "%d! = %lld\n"

    GNU_STACK_NOTE
