CC = x86_64-w64-mingw32-gcc
CFLAGS ?= -Wall -Wextra
TARGET = matrix_mul.exe
SRC = matrix_mul.s

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

test: $(TARGET)
	@which wine > /dev/null 2>&1 || (echo "wine not found, skipping execution test" && exit 0)
	@OUTPUT=$$(wine ./$(TARGET) 2>/dev/null | tr -d '\r'); \
	echo "Program output:"; \
	echo "$$OUTPUT"; \
	echo "$$OUTPUT" | grep -q "\[  80.0  70.0  60.0  50.0 \]" && \
	echo "$$OUTPUT" | grep -q "\[ 240.0 214.0 188.0 162.0 \]" && \
	echo "$$OUTPUT" | grep -q "\[ 400.0 358.0 316.0 274.0 \]" && \
	echo "$$OUTPUT" | grep -q "\[ 560.0 502.0 444.0 386.0 \]"

clean:
	rm -f $(TARGET)
