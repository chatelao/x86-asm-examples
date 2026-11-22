# Shared build rules for x86-64 assembly examples (Windows PE and Linux ELF).
# Each example Makefile sets NAME and includes this file.
#
# Usage:
#   make                     - build for host OS (linux ELF on Linux, .exe on Windows)
#   make TARGET_OS=windows   - cross-build Windows .exe via MinGW-w64
#   make TARGET_OS=linux     - build native Linux ELF binary
#   make test                - run & verify output (natively on Linux, via Wine for .exe)

HOST_OS := $(shell uname -s | tr A-Z a-z)
ifneq (,$(findstring mingw,$(HOST_OS))$(findstring msys,$(HOST_OS))$(findstring cygwin,$(HOST_OS)))
  DEFAULT_OS := windows
else
  DEFAULT_OS := linux
endif

TARGET_OS ?= $(DEFAULT_OS)
SRC        = $(NAME).s

ifeq ($(TARGET_OS),windows)
  CC      = x86_64-w64-mingw32-gcc
  CFLAGS ?= -Wall -Wextra
  TARGET  = $(NAME).exe
  PREPROC = -x assembler-with-cpp
else
  CC      = gcc
  CFLAGS ?= -Wall -Wextra -no-pie
  TARGET  = $(NAME)
  PREPROC = -x assembler-with-cpp
endif

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(PREPROC) $< -o $@

ifeq ($(TARGET_OS),windows)
test: $(TARGET)
	@which wine > /dev/null 2>&1 || (echo "wine not found, skipping execution test" && exit 0)
	@which wine > /dev/null 2>&1 || exit 0; \
	OUTPUT=$$(WINEDEBUG=-all wine ./$(TARGET) 2>/dev/null | tr -d '\r'); \
	echo "[x86_64/windows] $(NAME) output:"; \
	echo "$$OUTPUT"; \
	$(TEST_CMD)
else
test: $(TARGET)
	@OUTPUT=$$(./$(TARGET)); \
	echo "[x86_64/linux] $(NAME) output:"; \
	echo "$$OUTPUT"; \
	$(TEST_CMD)
endif

clean:
	rm -f $(NAME) $(NAME).exe $(NAME).o
