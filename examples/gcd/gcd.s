    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate 32-byte shadow space

    # -------------------------------------------------------------------------
    # Euclidean Algorithm for Greatest Common Divisor: GCD(1071, 462) = 21
    # Uses 64-bit unsigned division (divq), where %rdx:%rax is divided by
    # the operand, placing the quotient in %rax and the remainder in %rdx.
    # -------------------------------------------------------------------------

    movq    $1071, %rax             # a = 1071
    movq    $462, %rcx              # b = 462

.Lgcd_loop:
    testq   %rcx, %rcx              # Check if b == 0
    jz      .Lgcd_done
    xorl    %edx, %edx              # Zero upper 64 bits of dividend (%rdx:%rax)
    divq    %rcx                    # %rax = a / b, %rdx = a % b
    movq    %rcx, %rax              # a = b
    movq    %rdx, %rcx              # b = a % b
    jmp     .Lgcd_loop

.Lgcd_done:
    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    movl    $1071, %edx             # 2nd arg: 1071
    movl    $462, %r8d              # 3rd arg: 462
    movq    %rax, %r9               # 4th arg: GCD result (21)
    call    printf

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
fmt_str:
    .asciz  "GCD(%d, %d) = %lld\n"
