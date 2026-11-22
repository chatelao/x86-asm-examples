# =============================================================================
# Hello World for RV32 bare metal (QEMU riscv32 virt, machine mode)
# Prints a string to the host console via RISC-V semihosting (SYS_WRITE0).
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    la      a0, message             # 1st argument (ILP32) in a0
    call    print_str
    li      a0, 0                   # Return 0
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

    .section .rodata
message:
    .asciz  "Hello, World!\n"
