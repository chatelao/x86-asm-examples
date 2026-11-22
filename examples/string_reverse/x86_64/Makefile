HOST_OS := $(shell uname -s | tr A-Z a-z)
ifneq (,$(findstring mingw,$(HOST_OS))$(findstring msys,$(HOST_OS))$(findstring cygwin,$(HOST_OS)))
  DEFAULT_OS := windows
else
  DEFAULT_OS := linux
endif

TARGET_OS ?= $(DEFAULT_OS)
SRC        = string_reverse.s

ifeq ($(TARGET_OS),windows)
  CC      = x86_64-w64-mingw32-gcc
  AS      = x86_64-w64-mingw32-as
  LD      = x86_64-w64-mingw32-ld
  TARGET  = string_reverse.exe
  LDFLAGS = -s -nostdlib -e start \
            --file-alignment 16 --section-alignment 16 \
            --disable-dynamicbase --disable-reloc-section --disable-high-entropy-va \
            --no-insert-timestamp --subsystem console
  LIBS    = -lkernel32
else
  CC      = gcc
  LD      = ld
  TARGET  = string_reverse
  LDFLAGS = -s -nostdlib -e _start
endif

.PHONY: all clean test

all: $(TARGET)

ifeq ($(TARGET_OS),windows)
$(TARGET): $(SRC)
	gcc -E -D_WIN32 -x assembler-with-cpp $< -o string_reverse.tmp.s
	$(AS) string_reverse.tmp.s -o string_reverse.o
	$(LD) $(LDFLAGS) string_reverse.o $(LIBS) -o $@
	@rm -f string_reverse.tmp.s string_reverse.o
	@echo "$(TARGET): $$(stat -c %s $@) bytes"

test: $(TARGET)
	@SIZE=$$(stat -c %s $(TARGET)); test $$SIZE -lt 1024 || (echo "$(TARGET) is $$SIZE bytes, expected < 1024" && exit 1)
	@which wine > /dev/null 2>&1 || (echo "wine not found, skipping execution test" && exit 0)
	@which wine > /dev/null 2>&1 || exit 0; \
	OUTPUT=$$(WINEDEBUG=-all wine ./$(TARGET) 2>/dev/null | tr -d '\r'); \
	echo "[x86_64/windows] string_reverse output: $$OUTPUT"; \
	test "$$OUTPUT" = "ylbmessA 46-68x"
else
$(TARGET): $(SRC)
	$(CC) -c -x assembler-with-cpp $< -o string_reverse.o
	$(LD) $(LDFLAGS) string_reverse.o -o $@
	@rm -f string_reverse.o
	@echo "$(TARGET): $$(stat -c %s $@) bytes"

test: $(TARGET)
	@OUTPUT=$$(./$(TARGET)); \
	echo "[x86_64/linux] string_reverse output: $$OUTPUT"; \
	test "$$OUTPUT" = "ylbmessA 46-68x"
endif

clean:
	rm -f string_reverse string_reverse.exe string_reverse.o string_reverse.tmp.s
