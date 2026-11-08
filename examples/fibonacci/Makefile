CC = x86_64-w64-mingw32-gcc
CFLAGS ?= -Wall -Wextra
TARGET = fibonacci.exe
SRC = fibonacci.s

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

test: $(TARGET)
	@which wine > /dev/null 2>&1 || (echo "wine not found, skipping execution test" && exit 0)
	@OUTPUT=$$(wine ./$(TARGET) 2>/dev/null | tr -d '\r'); \
	echo "Program output:"; \
	echo "$$OUTPUT"; \
	echo "$$OUTPUT" | grep -q "F(0) = 0" && \
	echo "$$OUTPUT" | grep -q "F(9) = 34"

clean:
	rm -f $(TARGET)
