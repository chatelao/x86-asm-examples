    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate 32-byte shadow space

    # -------------------------------------------------------------------------
    # Binary Search on a sorted 32-bit integer array
    # Searches [3, 7, 12, 19, 25, 31, 42, 58] for target = 25 (index 4).
    # -------------------------------------------------------------------------

    leaq    sorted_arr(%rip), %r10
    movl    $25, %r11d              # Target value = 25
    xorl    %r8d, %r8d              # low = 0
    movl    $7, %r9d                # high = N - 1 = 7
    movl    $-1, %eax               # result index = -1 (not found)

.Lbsearch_loop:
    cmpl    %r9d, %r8d
    jg      .Lbsearch_done

    leal    (%r8,%r9), %ecx         # %ecx = low + high
    shrl    $1, %ecx                # mid = (low + high) >> 1

    movl    (%r10,%rcx,4), %edx     # %edx = sorted_arr[mid]
    cmpl    %r11d, %edx
    je      .Lbsearch_found
    jl      .Lbsearch_right

    leal    -1(%rcx), %r9d          # high = mid - 1
    jmp     .Lbsearch_loop

.Lbsearch_right:
    leal    1(%rcx), %r8d           # low = mid + 1
    jmp     .Lbsearch_loop

.Lbsearch_found:
    movl    %ecx, %eax              # Found at index mid

.Lbsearch_done:
    leaq    fmt_str(%rip), %rcx     # 1st arg: format string
    movl    %r11d, %edx             # 2nd arg: target (25)
    movl    %eax, %r8d              # 3rd arg: index (4)
    call    printf

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
    .balign 16
sorted_arr:
    .long   3, 7, 12, 19, 25, 31, 42, 58
fmt_str:
    .asciz  "Target %d found at index %d\n"
