@ =============================================================================
@ Hello World for Arm Cortex-M55, bare metal (QEMU mps3-an547)
@ Prints a string to the host console via Arm semihosting (SYS_WRITE0).
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, lr}
    ldr     r0, =message            @ 1st argument (AAPCS) in r0
    bl      print_str
    movs    r0, #0                  @ Return 0
    pop     {r4, pc}

    .section .rodata
message:
    .asciz  "Hello, World!\n"
