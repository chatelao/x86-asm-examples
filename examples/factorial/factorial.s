    .global main
    .def    main; .scl 2; .type 32; .endef
    .text

# -----------------------------------------------------------------------------
# Recursive 64-bit factorial: uint64_t factorial(uint64_t n)
# Input:  %rcx = n
# Output: %rax = n!
# -----------------------------------------------------------------------------
factorial:
    cmpq    $1, %rcx
    jbe     .Lbase_case

    pushq   %rcx                    # Save current n on stack
    subq    $32, %rsp               # Shadow space for recursive call
    decq    %rcx                    # n - 1
    call    factorial
    addq    $32, %rsp
    popq    %rcx                    # Restore n
    imulq   %rcx, %rax              # %rax = n * factorial(n - 1)
    ret

.Lbase_case:
    movl    $1, %eax
    ret

main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate 32-byte shadow space

    movl    $10, %ecx               # Compute 10!
    call    factorial

    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    movl    $10, %edx               # 2nd arg: n = 10
    movq    %rax, %r8               # 3rd arg: 10! = 3628800
    call    printf

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
fmt_str:
    .asciz  "%d! = %lld\n"
