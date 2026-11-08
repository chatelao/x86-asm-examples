CC = x86_64-w64-mingw32-gcc
CFLAGS ?= -Wall -Wextra
TARGET = hello_world.exe
SRC = hello_world.s

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

test: $(TARGET)
	@which wine > /dev/null 2>&1 || (echo "wine not found, skipping execution test" && exit 0)
	@OUTPUT=$$(wine ./$(TARGET) 2>/dev/null | tr -d '\r'); \
	echo "Program output: $$OUTPUT"; \
	test "$$OUTPUT" = "Hello, World!"

clean:
	rm -f $(TARGET)
