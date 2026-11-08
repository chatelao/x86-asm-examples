EXAMPLES = \
	hello_world \
	matrix_mul \
	fibonacci \
	factorial \
	gcd \
	bit_manipulation \
	string_reverse \
	bubble_sort \
	binary_search \
	dot_product \
	crc32_hash \
	cpuid_vendor

.PHONY: all clean test $(EXAMPLES)

all: $(EXAMPLES)

$(EXAMPLES):
	$(MAKE) -C examples/$@ all

test:
	@for dir in $(EXAMPLES); do \
		$(MAKE) -C examples/$$dir test || exit 1; \
	done

clean:
	@for dir in $(EXAMPLES); do \
		$(MAKE) -C examples/$$dir clean || exit 1; \
	done
