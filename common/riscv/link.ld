/* Linker script for QEMU riscv32 "virt" (-bios none): DRAM at 0x80000000. */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 1M
}

SECTIONS
{
    .text : {
        KEEP(*(.text.init))
        *(.text*)
    } > RAM

    .rodata : {
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(16);
    } > RAM

    .data : {
        *(.data*)
        __global_pointer$ = . + 0x800;
        *(.sdata*)
        . = ALIGN(16);
    } > RAM

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(16);
        __bss_end = .;
    } > RAM

    __stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /DISCARD/ : { *(.riscv.attributes) *(.comment) }
}
