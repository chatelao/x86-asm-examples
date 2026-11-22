# =============================================================================
# RISC-V Machine CSR Identification (mvendorid, marchid, mimpid, misa, vlenb)
#
# Reads standard machine-mode CSRs via Zicsr csrr instructions, decodes the
# misa MXL field (bits [31:30]) and extension bitmask (bits [25:0]) into an
# ISA string, and reports the vector register length from vlenb (0xC22).
# =============================================================================
    .text
    .global main
main:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    sw      s0, 40(sp)
    sw      s1, 36(sp)
    sw      s2, 32(sp)

    csrr    s0, mvendorid           # JEDEC manufacturer ID
    csrr    s1, marchid             # Microarchitecture ID
    csrr    s2, mimpid              # Implementation ID

    # Line 1: "CPU Vendor: 0x........ (marchid 0x........, mimpid 0x........)\n"
    la      a0, str_vendor
    call    print_str
    mv      a0, s0
    li      a1, 8
    call    print_hex

    la      a0, str_marchid
    call    print_str
    mv      a0, s1
    li      a1, 8
    call    print_hex

    la      a0, str_mimpid
    call    print_str
    mv      a0, s2
    li      a1, 8
    call    print_hex

    la      a0, str_rparen_nl
    call    print_str

    # Decode misa into stack buffer at 0(sp)
    csrr    s0, misa
    srli    t0, s0, 30              # MXL = misa[31:30] (1=32, 2=64, 3=128)
    li      a0, 32
    li      t1, 1
    beq     t0, t1, .Lmxl_done
    li      a0, 64
    li      t1, 2
    beq     t0, t1, .Lmxl_done
    li      a0, 128
.Lmxl_done:
    mv      s1, a0                  # Save XLEN (32/64/128)

    # Build extension string for bits 0..25 ('A'..'Z') in sp[0..27]
    mv      t0, sp                  # Write cursor
    li      t1, 0                   # Bit index 0..25
    li      t2, 26
.Lisa_loop:
    srl     t3, s0, t1
    andi    t3, t3, 1
    beqz    t3, .Lisa_next
    addi    t4, t1, 'A'
    sb      t4, 0(t0)
    addi    t0, t0, 1
.Lisa_next:
    addi    t1, t1, 1
    blt     t1, t2, .Lisa_loop
    sb      zero, 0(t0)             # Null-terminate extension letters

    # Line 2: "ISA: RV<xlen><extensions>\n"
    la      a0, str_isa
    call    print_str
    mv      a0, s1
    call    print_udec
    mv      a0, sp
    call    print_str
    li      a0, '\n'
    call    print_char

    # Line 3: "VLEN: <vlenb * 8> bits\n"
    csrr    s0, 0xC22               # vlenb CSR (vector register length in bytes)
    slli    s0, s0, 3               # Convert bytes -> bits
    la      a0, str_vlen
    call    print_str
    mv      a0, s0
    call    print_udec
    la      a0, str_bits_nl
    call    print_str

    li      a0, 0                   # Return 0
    lw      s2, 32(sp)
    lw      s1, 36(sp)
    lw      s0, 40(sp)
    lw      ra, 44(sp)
    addi    sp, sp, 48
    ret

    .section .rodata
str_vendor:
    .asciz  "CPU Vendor: 0x"
str_marchid:
    .asciz  " (marchid 0x"
str_mimpid:
    .asciz  ", mimpid 0x"
str_rparen_nl:
    .asciz  ")\n"
str_isa:
    .asciz  "ISA: RV"
str_vlen:
    .asciz  "VLEN: "
str_bits_nl:
    .asciz  " bits\n"
