    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $48, %rsp               # 32B shadow space + 5th/6th args on stack

    # -------------------------------------------------------------------------
    # Hardware Bit Manipulation (ABM / BMI1 / x86-64):
    # - popcntq: Count number of set 1-bits (Hamming weight)
    # - tzcntq:  Count trailing zero bits (least significant side)
    # - lzcntq:  Count leading zero bits (most significant side)
    # - bswapq:  Reverse byte order (64-bit endianness swap)
    # -------------------------------------------------------------------------

    movabsq $0x00F0F0F000001000, %rax

    popcntq %rax, %rdx              # %rdx = 13 set bits
    tzcntq  %rax, %r8               # %r8  = 12 trailing zeros
    lzcntq  %rax, %r9               # %r9  = 8 leading zeros

    movq    %rax, %rcx
    bswapq  %rcx                    # %rcx = 0x00100000F0F0F000

    movq    %rcx, 32(%rsp)          # 5th arg: byte-swapped value
    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    call    printf

    xorl    %eax, %eax              # Return 0
    addq    $48, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
fmt_str:
    .asciz  "popcnt=%lld tzcnt=%lld lzcnt=%lld bswap=0x%016llX\n"
