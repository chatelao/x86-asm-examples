# Shared build rules for the RV32 + Zve32f (embedded vector) bare-metal examples.
# Each example Makefile sets NAME and includes this file.
#
#   make        - assemble + link $(NAME).elf
#   make run    - run under QEMU (riscv32 virt), output via semihosting
#   make test   - run and compare stdout with expected.txt

RISCV_PREFIX ?= riscv64-unknown-elf-
QEMU_RISCV   ?= qemu-system-riscv32

# ISA: RV32IMF + Zicsr + Zve32f (vectors with up to 32-bit elements, FP32)
#      + Zbb (basic bit-manipulation) + Zbc (carry-less multiply)
RISCV_ARCH ?= rv32imf_zicsr_zve32f_zbb_zbc
# QEMU CPU model providing the above (VLEN = 128 bits; v=true required by QEMU 9.2 for mstatus.VS)
QEMU_CPU   ?= rv32,v=true,f=true,zve32f=true,vlen=128,zbb=true,zbc=true

AS      = $(RISCV_PREFIX)as
LD      = $(RISCV_PREFIX)ld
SIZE    = $(RISCV_PREFIX)size
ASFLAGS = -march=$(RISCV_ARCH) -mabi=ilp32f
LDFLAGS = -m elf32lriscv -T $(RISCV_COMMON)link.ld --gc-sections -nostdlib

RISCV_COMMON := $(dir $(lastword $(MAKEFILE_LIST)))
TARGET  = $(NAME).elf
OBJS    = riscv_startup.o $(NAME).o riscv_io.o

QEMU_RUN = timeout 20 $(QEMU_RISCV) -M virt -cpu $(QEMU_CPU) -bios none \
           -display none -monitor none -serial none \
           -chardev stdio,id=semi -semihosting-config enable=on,target=native,chardev=semi \
           -kernel $(TARGET)

.PHONY: all run test clean

all: $(TARGET)

$(TARGET): $(OBJS) $(RISCV_COMMON)link.ld
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	@$(SIZE) $@

$(NAME).o: $(NAME).s
	$(AS) $(ASFLAGS) $< -o $@

riscv_%.o: $(RISCV_COMMON)%.s
	$(AS) $(ASFLAGS) $< -o $@

run: $(TARGET)
	@$(QEMU_RUN)

test: $(TARGET)
	@which $(QEMU_RISCV) > /dev/null 2>&1 || { echo "$(QEMU_RISCV) not found, skipping execution test"; exit 0; }; \
	$(QEMU_RUN) > output.txt; \
	echo "[riscv] $(NAME) output:"; cat output.txt; \
	diff -u expected.txt output.txt && echo "[riscv] $(NAME): PASS"

clean:
	rm -f $(TARGET) *.o output.txt
