#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
#ifdef _WIN32
    subq    $32, %rsp               # 32B shadow space (3 pushes + rbp = 32B -> 16B aligned)
#else
    subq    $8, %rsp                # Align stack to 16 bytes
#endif

    # -------------------------------------------------------------------------
    # Iterative Fibonacci sequence using x86-64 xaddq (Exchange and Add)
    # xaddq %rax, %rbx swaps %rax and %rbx while storing %rax + %rbx in %rbx,
    # advancing the Fibonacci state (F_n, F_{n+1}) in a single instruction.
    # -------------------------------------------------------------------------

#ifdef _WIN32
    leaq    header_msg(%rip), %rcx
#else
    leaq    header_msg(%rip), %rdi
#endif
    call    puts

    xorq    %rbx, %rbx              # F_0 = 0
    movq    $1, %r12                # F_1 = 1 (callee-saved in both ABIs)
    xorl    %r13d, %r13d            # Loop counter i = 0 (callee-saved in both ABIs)

.Lfib_loop:
#ifdef _WIN32
    leaq    fib_fmt(%rip), %rcx     # 1st arg: format string
    movl    %r13d, %edx             # 2nd arg: index i
    movq    %rbx, %r8               # 3rd arg: F_i
#else
    leaq    fib_fmt(%rip), %rdi     # 1st arg: format string
    movl    %r13d, %esi             # 2nd arg: index i
    movq    %rbx, %rdx              # 3rd arg: F_i
    xorl    %eax, %eax              # 0 XMM args for variadic printf
#endif
    call    printf

    xaddq   %rbx, %r12              # %rbx = F_{i+1}, %r12 = F_i + F_{i+1}
    incl    %r13d
    cmpl    $10, %r13d
    jl      .Lfib_loop

    xorl    %eax, %eax              # Return 0
#ifdef _WIN32
    addq    $32, %rsp
#else
    addq    $8, %rsp
#endif
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

    RODATA_SECTION
header_msg:
    .asciz  "First 10 Fibonacci numbers:"
fib_fmt:
    .asciz  "F(%d) = %lld\n"

    GNU_STACK_NOTE
