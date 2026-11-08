    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate 32-byte shadow space

    # -------------------------------------------------------------------------
    # In-place String Reversal using two-pointer byte swaps
    # Reverses "x86-64 Assembly" (15 bytes) into "ylbmessA 46-68x"
    # -------------------------------------------------------------------------

    leaq    str_buf(%rip), %rcx     # Left pointer = start of string
    leaq    str_buf+14(%rip), %rdx  # Right pointer = end of string (len - 1)

.Lrev_loop:
    cmpq    %rdx, %rcx
    jge     .Lrev_done

    movzbl  (%rcx), %eax            # Load left byte
    movzbl  (%rdx), %r8d            # Load right byte
    movb    %r8b, (%rcx)            # Store right byte at left pointer
    movb    %al, (%rdx)             # Store left byte at right pointer

    incq    %rcx
    decq    %rdx
    jmp     .Lrev_loop

.Lrev_done:
    leaq    str_buf(%rip), %rcx     # 1st arg: reversed string
    call    puts

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .data
str_buf:
    .asciz  "x86-64 Assembly"
