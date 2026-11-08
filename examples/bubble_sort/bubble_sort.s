    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # Save non-volatile registers (Windows x64 ABI)
    pushq   %rsi
    subq    $32, %rsp               # Allocate 32-byte shadow space

    # -------------------------------------------------------------------------
    # In-place 32-bit Integer Bubble Sort
    # Sorts [42, 15, 8, 99, 23, 4, 16, 7] -> [4, 7, 8, 15, 16, 23, 42, 99]
    # using scaled-index addressing (%rbx,%rcx,4).
    # -------------------------------------------------------------------------

    leaq    arr(%rip), %rbx
    movl    $7, %r8d                # Outer loop bound: N - 1 = 7

.Louter_loop:
    xorl    %ecx, %ecx              # Inner loop index j = 0

.Linner_loop:
    movl    (%rbx,%rcx,4), %eax     # %eax = arr[j]
    movl    4(%rbx,%rcx,4), %edx    # %edx = arr[j + 1]
    cmpl    %edx, %eax
    jle     .Lno_swap

    movl    %edx, (%rbx,%rcx,4)     # Swap arr[j] and arr[j + 1]
    movl    %eax, 4(%rbx,%rcx,4)

.Lno_swap:
    incl    %ecx
    cmpl    %r8d, %ecx
    jl      .Linner_loop

    decl    %r8d
    jnz     .Louter_loop

    # Print sorted array elements
    xorl    %esi, %esi
.Lprint_loop:
    leaq    elem_fmt(%rip), %rcx
    movl    (%rbx,%rsi,4), %edx
    call    printf
    incl    %esi
    cmpl    $8, %esi
    jl      .Lprint_loop

    leaq    newline(%rip), %rcx
    call    puts

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rsi
    popq    %rbx
    popq    %rbp
    ret

    .data
    .balign 16
arr:
    .long   42, 15, 8, 99, 23, 4, 16, 7

    .section .rdata,"dr"
elem_fmt:
    .asciz  "%d "
newline:
    .asciz  ""
