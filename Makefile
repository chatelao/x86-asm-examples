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

ARCHS = x86_64 arm riscv

.PHONY: all clean test $(ARCHS) $(addprefix test-,$(ARCHS)) $(addprefix clean-,$(ARCHS)) $(EXAMPLES)

all: $(ARCHS)

$(ARCHS):
	@for dir in $(EXAMPLES); do \
		$(MAKE) -C examples/$$dir/$@ all || exit 1; \
	done

test: $(addprefix test-,$(ARCHS))

$(addprefix test-,$(ARCHS)): test-%:
	@for dir in $(EXAMPLES); do \
		$(MAKE) -C examples/$$dir/$* test || exit 1; \
	done

clean: $(addprefix clean-,$(ARCHS))

$(addprefix clean-,$(ARCHS)): clean-%:
	@for dir in $(EXAMPLES); do \
		$(MAKE) -C examples/$$dir/$* clean || exit 1; \
	done

$(EXAMPLES):
	@for arch in $(ARCHS); do \
		$(MAKE) -C examples/$@/$$arch all || exit 1; \
	done
