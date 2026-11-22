/* Linker script for QEMU mps3-an547 (Cortex-M55). Everything runs from ITCM
 * (which is RAM, so .data needs no copy); the stack lives in DTCM. */
ENTRY(Reset_Handler)

MEMORY
{
    ITCM (rwx) : ORIGIN = 0x00000000, LENGTH = 512K
    DTCM (rw)  : ORIGIN = 0x20000000, LENGTH = 512K
}

SECTIONS
{
    .text : {
        KEEP(*(.vectors))
        *(.text*)
        *(.rodata*)
        . = ALIGN(16);
    } > ITCM

    .data : {
        *(.data*)
        . = ALIGN(16);
    } > ITCM

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(16);
        __bss_end = .;
    } > DTCM

    __stack_top = ORIGIN(DTCM) + LENGTH(DTCM);

    /DISCARD/ : { *(.ARM.attributes*) *(.comment) }
}
