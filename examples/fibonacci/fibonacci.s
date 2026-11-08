    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # Save non-volatile registers (Windows x64 ABI)
    pushq   %rsi
    pushq   %rdi
    subq    $40, %rsp               # 32B shadow space + 8B alignment

    # -------------------------------------------------------------------------
    # Iterative Fibonacci sequence using x86-64 xaddq (Exchange and Add)
    # xaddq %rax, %rbx swaps %rax and %rbx while storing %rax + %rbx in %rbx,
    # advancing the Fibonacci state (F_n, F_{n+1}) in a single instruction.
    # -------------------------------------------------------------------------

    leaq    header_msg(%rip), %rcx
    call    puts

    xorq    %rbx, %rbx              # F_0 = 0
    movq    $1, %rsi                # F_1 = 1
    xorl    %edi, %edi              # Loop counter i = 0

.Lfib_loop:
    leaq    fib_fmt(%rip), %rcx     # 1st arg: format string
    movl    %edi, %edx              # 2nd arg: index i
    movq    %rbx, %r8               # 3rd arg: F_i
    call    printf

    xaddq   %rbx, %rsi              # %rbx = F_{i+1}, %rsi = F_i + F_{i+1}

    incl    %edi
    cmpl    $10, %edi
    jl      .Lfib_loop

    xorl    %eax, %eax              # Return 0
    addq    $40, %rsp
    popq    %rdi
    popq    %rsi
    popq    %rbx
    popq    %rbp
    ret

    .section .rdata,"dr"
header_msg:
    .asciz  "First 10 Fibonacci numbers:"
fib_fmt:
    .asciz  "F(%d) = %lld\n"
