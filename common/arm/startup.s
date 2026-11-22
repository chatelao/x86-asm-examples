@ =============================================================================
@ Minimal bare-metal startup for Arm Cortex-M55 (Armv8.1-M Mainline + Helium/MVE)
@ Target: QEMU "mps3-an547" (Arm SSE-300 subsystem, Cortex-M55 with FPU + MVE)
@
@ Memory map used (see link.ld):
@   0x00000000  ITCM (512 KB)  - vector table, code, read-only and RW data
@   0x20000000  DTCM (512 KB)  - stack (grows down from 0x20080000)
@
@ The reset handler enables the FPU / MVE coprocessors, calls `main`, and then
@ reports the program exit to the host via Arm semihosting (SYS_EXIT).
@ =============================================================================
    .syntax unified
    .thumb

    .section .vectors, "a"
    .balign 128
    .global __vectors
__vectors:
    .word   __stack_top             @ 0: Initial main stack pointer
    .word   Reset_Handler           @ 1: Reset
    .word   Fault_Handler           @ 2: NMI
    .word   Fault_Handler           @ 3: HardFault
    .word   Fault_Handler           @ 4: MemManage
    .word   Fault_Handler           @ 5: BusFault
    .word   Fault_Handler           @ 6: UsageFault
    .word   Fault_Handler           @ 7: SecureFault

    .text
    .thumb_func
    .global Reset_Handler
Reset_Handler:
    @ Enable full access to CP10/CP11 (FPU and MVE) in CPACR (and NSACR)
    ldr     r0, =0xE000ED88         @ CPACR
    ldr     r1, [r0]
    orr     r1, r1, #(0xF << 20)    @ CP10 + CP11 = full access
    str     r1, [r0]
    dsb
    isb

    bl      main                    @ int main(void)

    @ Exit to host: SYS_EXIT(ADP_Stopped_ApplicationExit) on success,
    @ ADP_Stopped_RunTimeErrorUnknown otherwise.
    ldr     r1, =0x20026            @ ADP_Stopped_ApplicationExit
    cmp     r0, #0
    it      ne
    ldrne   r1, =0x20023            @ ADP_Stopped_RunTimeErrorUnknown
    movs    r0, #0x18               @ SYS_EXIT
    bkpt    #0xAB
1:  b       1b

    .thumb_func
Fault_Handler:
    ldr     r0, =fault_msg
    bl      print_str
    ldr     r1, =0x20023            @ ADP_Stopped_RunTimeErrorUnknown
    movs    r0, #0x18               @ SYS_EXIT
    bkpt    #0xAB
1:  b       1b

    .section .rodata
fault_msg:
    .asciz  "*** CPU fault ***\n"
