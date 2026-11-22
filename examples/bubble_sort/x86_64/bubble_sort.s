#include "../../../common/x86_64/abi.h"

    .global main
    DEF_FUNC(main)
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx                    # Callee-saved in both Win64 and SysV
    pushq   %r12                    # Callee-saved in both Win64 and SysV
#ifdef _WIN32
    subq    $32, %rsp               # Allocate 32-byte shadow space
#endif

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
    xorl    %r12d, %r12d

.Lprint_loop:
#ifdef _WIN32
    leaq    elem_fmt(%rip), %rcx
    movl    (%rbx,%r12,4), %edx
#else
    leaq    elem_fmt(%rip), %rdi
    movl    (%rbx,%r12,4), %esi
    xorl    %eax, %eax
#endif
    call    printf

    incl    %r12d
    cmpl    $8, %r12d
    jl      .Lprint_loop

#ifdef _WIN32
    leaq    newline(%rip), %rcx
#else
    leaq    newline(%rip), %rdi
#endif
    call    puts

    xorl    %eax, %eax              # Return 0
#ifdef _WIN32
    addq    $32, %rsp
#endif
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

    .data
    .balign 16
arr:
    .long   42, 15, 8, 99, 23, 4, 16, 7

    RODATA_SECTION
elem_fmt:
    .asciz  "%d "
newline:
    .asciz  ""

    GNU_STACK_NOTE
