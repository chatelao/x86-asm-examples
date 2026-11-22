# Shared build rules for the Arm Cortex-M55 (Helium/MVE) bare-metal examples.
# Each example Makefile sets NAME and includes this file.
#
#   make        - assemble + link $(NAME).elf
#   make run    - run under QEMU (mps3-an547), output via semihosting
#   make test   - run and compare stdout with expected.txt

ARM_PREFIX ?= arm-none-eabi-
QEMU_ARM   ?= qemu-system-arm

AS      = $(ARM_PREFIX)as
LD      = $(ARM_PREFIX)ld
SIZE    = $(ARM_PREFIX)size
ASFLAGS = -march=armv8.1-m.main+mve.fp+fp.dp -mfloat-abi=hard -mthumb
LDFLAGS = -T $(ARM_COMMON)link.ld --gc-sections -nostdlib

ARM_COMMON := $(dir $(lastword $(MAKEFILE_LIST)))
TARGET  = $(NAME).elf
OBJS    = $(NAME).o arm_startup.o arm_io.o

QEMU_RUN = timeout 20 $(QEMU_ARM) -M mps3-an547 -display none -monitor none -serial none \
           -chardev stdio,id=semi -semihosting-config enable=on,target=native,chardev=semi \
           -kernel $(TARGET)

.PHONY: all run test clean

all: $(TARGET)

$(TARGET): $(OBJS) $(ARM_COMMON)link.ld
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	@$(SIZE) $@

$(NAME).o: $(NAME).s
	$(AS) $(ASFLAGS) $< -o $@

arm_%.o: $(ARM_COMMON)%.s
	$(AS) $(ASFLAGS) $< -o $@

run: $(TARGET)
	@$(QEMU_RUN)

test: $(TARGET)
	@which $(QEMU_ARM) > /dev/null 2>&1 || { echo "$(QEMU_ARM) not found, skipping execution test"; exit 0; }; \
	$(QEMU_RUN) > output.txt; \
	echo "[arm] $(NAME) output:"; cat output.txt; \
	diff -u expected.txt output.txt && echo "[arm] $(NAME): PASS"

clean:
	rm -f $(TARGET) *.o output.txt
