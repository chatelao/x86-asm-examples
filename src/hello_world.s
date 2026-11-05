    .global main
    .def    main; .scl 2; .type 32; .endef
    .text
main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp               # Allocate shadow space for Windows x64 ABI

    leaq    message(%rip), %rcx     # 1st argument in Windows x64 calling convention is %rcx
    call    puts

    xorl    %eax, %eax              # Return 0
    addq    $32, %rsp
    popq    %rbp
    ret

    .section .rdata,"dr"
message:
    .asciz  "Hello, World!"
