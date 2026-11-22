#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
#ifdef _WIN32
    subq    $32, %rsp               # Allocate shadow space for Windows x64 ABI
    leaq    message(%rip), %rcx     # 1st arg in Windows x64 is %rcx
#else
    leaq    message(%rip), %rdi     # 1st arg in System V AMD64 is %rdi
#endif
    call    puts
    xorl    %eax, %eax              # Return 0
#ifdef _WIN32
    addq    $32, %rsp
#endif
    popq    %rbp
    ret

    RODATA_SECTION
message:
    .asciz  "Hello, World!"

    GNU_STACK_NOTE
