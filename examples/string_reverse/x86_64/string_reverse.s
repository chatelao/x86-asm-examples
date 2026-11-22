#include "../../../common/x86_64/abi.h"

    # =========================================================================
    # Minimal-size Windows x64 (< 1 KB .exe) and Linux x86-64 ELF program
    #
    # No C runtime on either OS:
    #   - Windows: PE entry point `start` (-nostdlib -e start), output via
    #              kernel32.dll (GetStdHandle + WriteFile + ExitProcess).
    #   - Linux:   ELF entry point `_start` (-nostdlib -e _start), output via
    #              direct Linux syscalls (sys_write = 1, sys_exit = 60).
    # =========================================================================
#ifdef _WIN32
    .global start
    DEF_FUNC(start)
    .text
start:
    subq    $56, %rsp               # 32B shadow + 5th arg + bytesWritten, keeps 16B alignment
#else
    .global _start
    DEF_FUNC(_start)
    .text
_start:
#endif

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
#ifdef _WIN32
    movl    $-11, %ecx              # STD_OUTPUT_HANDLE
    call    *__imp_GetStdHandle(%rip)

    movq    %rax, %rcx              # 1st arg: console handle
    leaq    str_buf(%rip), %rdx     # 2nd arg: reversed string
    movl    $str_len, %r8d          # 3rd arg: byte count (incl. newline)
    leaq    40(%rsp), %r9           # 4th arg: &bytesWritten
    movq    $0, 32(%rsp)            # 5th arg: lpOverlapped = NULL
    call    *__imp_WriteFile(%rip)

    xorl    %ecx, %ecx              # Exit code 0
    call    *__imp_ExitProcess(%rip)
#else
    movl    $1, %eax                # syscall: sys_write
    movl    $1, %edi                # fd = stdout
    leaq    str_buf(%rip), %rsi     # buf = str_buf
    movl    $str_len, %edx          # count = str_len
    syscall

    movl    $60, %eax               # syscall: sys_exit
    xorl    %edi, %edi              # status = 0
    syscall
#endif

    .data
str_buf:
    .ascii  "x86-64 Assembly\n"
    .set    str_len, . - str_buf

    GNU_STACK_NOTE
