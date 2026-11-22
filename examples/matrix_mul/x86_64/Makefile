NAME = matrix_mul
TEST_CMD = \
	echo "$$OUTPUT" | grep -q "Input matrix A:" && \
	echo "$$OUTPUT" | grep -q "\[   1.0   2.0   3.0   4.0 \]" && \
	echo "$$OUTPUT" | grep -q "Input matrix B:" && \
	echo "$$OUTPUT" | grep -q "\[  16.0  15.0  14.0  13.0 \]" && \
	echo "$$OUTPUT" | grep -q "Input alpha = 1.0" && \
	echo "$$OUTPUT" | grep -q "\[  80.0  70.0  60.0  50.0 \]" && \
	echo "$$OUTPUT" | grep -q "\[ 240.0 214.0 188.0 162.0 \]" && \
	echo "$$OUTPUT" | grep -q "\[ 400.0 358.0 316.0 274.0 \]" && \
	echo "$$OUTPUT" | grep -q "\[ 560.0 502.0 444.0 386.0 \]"
include ../../../common/x86_64/x86_64.mk
