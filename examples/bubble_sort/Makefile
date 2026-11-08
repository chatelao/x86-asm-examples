CC = x86_64-w64-mingw32-gcc
CFLAGS ?= -Wall -Wextra
TARGET = bubble_sort.exe
SRC = bubble_sort.s

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

test: $(TARGET)
	@which wine > /dev/null 2>&1 || (echo "wine not found, skipping execution test" && exit 0)
	@OUTPUT=$$(wine ./$(TARGET) 2>/dev/null | tr -d '\r'); \
	echo "Program output: $$OUTPUT"; \
	echo "$$OUTPUT" | grep -q "4 7 8 15 16 23 42 99"

clean:
	rm -f $(TARGET)
