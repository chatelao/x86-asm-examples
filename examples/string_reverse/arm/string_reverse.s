@ =============================================================================
@ In-place String Reversal for Arm Cortex-M55 (bare metal, QEMU mps3-an547)
@ Reverses "x86-64 Assembly" (15 bytes) into "ylbmessA 46-68x" using a
@ two-pointer byte swap with ldrb / strb.
@ =============================================================================
    .syntax unified
    .thumb
    .text
    .thumb_func
    .global main
main:
    push    {r4, lr}

    ldr     r0, =str_buf            @ Left pointer = start of string
    add     r1, r0, #14             @ Right pointer = end of string (len - 1)

.Lrev_loop:
    cmp     r0, r1
    bge     .Lrev_done

    ldrb    r2, [r0]                @ Load left byte
    ldrb    r3, [r1]                @ Load right byte
    strb    r3, [r0], #1            @ Store right byte and advance left
    strb    r2, [r1], #-1           @ Store left byte and retreat right
    b       .Lrev_loop

.Lrev_done:
    ldr     r0, =str_buf
    bl      print_str

    movs    r0, #0                  @ Return 0
    pop     {r4, pc}

    .data
str_buf:
    .asciz  "x86-64 Assembly\n"
