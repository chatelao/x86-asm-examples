# =============================================================================
# Minimal bare-metal startup for RV32IMF + Zve32f (embedded vector extension)
# Target: QEMU "virt" machine (qemu-system-riscv32 -bios none), machine mode.
#
# Memory map used (see link.ld):
#   0x80000000  DRAM - code, data, stack (stack grows down from end of 1 MB)
#
# _start sets up the stack, enables the FPU (mstatus.FS) and the vector unit
# (mstatus.VS), installs a trap handler, calls `main`, and reports the exit
# status to the host via RISC-V semihosting (SYS_EXIT).
# =============================================================================
    .section .text.init, "ax"
    .global _start
_start:
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop
    la      sp, __stack_top

    li      t0, (1 << 13) | (1 << 9) # mstatus.FS = Initial, mstatus.VS = Initial
    csrs    mstatus, t0
    csrwi   fcsr, 0                 # Round-to-nearest-even, clear FP flags

    la      t0, trap_handler
    csrw    mtvec, t0

    # Zero .bss
    la      t0, __bss_start
    la      t1, __bss_end
1:  bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b
2:
    call    main                    # int main(void)

    # SYS_EXIT: on RV32 the parameter is the reason code itself
    li      a1, 0x20026             # ADP_Stopped_ApplicationExit
    beqz    a0, 3f
    li      a1, 0x20023             # ADP_Stopped_RunTimeErrorUnknown
3:  li      a0, 0x18                # SYS_EXIT
    call    semihost_call
4:  j       4b

    .balign 4
trap_handler:
    la      a0, trap_msg
    call    print_str
    li      a1, 0x20023
    li      a0, 0x18
    call    semihost_call
5:  j       5b

    .section .rodata
trap_msg:
    .asciz  "*** CPU trap ***\n"
