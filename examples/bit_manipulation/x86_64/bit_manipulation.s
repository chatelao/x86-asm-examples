#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
#ifdef _WIN32
    subq    $48, %rsp               # 32B shadow space + 5th arg + alignment
#endif

    # -------------------------------------------------------------------------
    # Hardware Bit Manipulation (ABM / BMI1 / x86-64):
    # - popcntq: Count number of set 1-bits (Hamming weight)
    # - tzcntq:  Count trailing zero bits (least significant side)
    # - lzcntq:  Count leading zero bits (most significant side)
    # - bswapq:  Reverse byte order (64-bit endianness swap)
    # -------------------------------------------------------------------------

    movabsq $0x00F0F0F000001000, %rax
#ifdef _WIN32
    popcntq %rax, %rdx              # 2nd arg: 13 set bits
    tzcntq  %rax, %r8               # 3rd arg: 12 trailing zeros
    lzcntq  %rax, %r9               # 4th arg: 8 leading zeros
    movq    %rax, %rcx
    bswapq  %rcx                    # %rcx = 0x00100000F0F0F000
    movq    %rcx, 32(%rsp)          # 5th arg: byte-swapped value
    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
#else
    popcntq %rax, %rsi              # 2nd arg: 13 set bits
    tzcntq  %rax, %rdx              # 3rd arg: 12 trailing zeros
    lzcntq  %rax, %rcx              # 4th arg: 8 leading zeros
    movq    %rax, %r8
    bswapq  %r8                     # 5th arg: 0x00100000F0F0F000
    leaq    fmt_str(%rip), %rdi     # 1st arg: format string
    xorl    %eax, %eax              # 0 XMM args
#endif
    call    printf

    xorl    %eax, %eax              # Return 0
#ifdef _WIN32
    addq    $48, %rsp
#endif
    popq    %rbp
    ret

    RODATA_SECTION
fmt_str:
    .asciz  "popcnt=%lld tzcnt=%lld lzcnt=%lld bswap=0x%016llX\n"

    GNU_STACK_NOTE
