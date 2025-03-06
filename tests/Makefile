CPU_DIR := ../core_RV32I/
TESTBENCH_NAME := top_tb

#! NOTE: "find -name ''" looks for files recursively inside the SRC_DIR
SRC_DIRS := ${CPU_DIR}
SRC_FILE := $(shell find $(SRC_DIRS) -name '*.v') $(shell find $(SRC_DIRS) -name '*.sv') \
			$(shell find $(SRC_DIRS) -name '*.vh') $(shell find $(SRC_DIRS) -name '*.svh')

ifeq (${TESTBENCH_NAME}, control_tb)
    CPP_FILE = sim_main_control.cpp
else ifeq (${TESTBENCH_NAME}, top_tb)
    CPP_FILE = sim_top_main.cpp
else
    CPP_FILE = INVALID_TOP_NAME
endif

# Verilator options
VERILATOR_OPTS = -cc \
    -Wno-PINMISSING \
    --exe \
    --trace \
    --trace-structs \
    --build \
    --timing

 # Make sure to unset this warning when first compiling + check warnings (
 # -Wno-MODDUP \
 # -Wno-COMBDLY \
 # -Wno-NULLPORT \
 # -Wno-UNOPTFLAT

.PHONY: run clean

# target (binary name) : dependencies
obj_dir/V$(TESTBENCH_NAME): ${SRC_DIR}/* $(SRC_FILE)
	verilator $(VERILATOR_OPTS) ${CPP_FILE} $(SRC_FILE) -I$(CPU_DIR) --top $(TESTBENCH_NAME) -j `nproc`


run: obj_dir/V$(TESTBENCH_NAME)
	./obj_dir/V$(TESTBENCH_NAME)

print_sources:
	@echo "SOURCES:"
	@echo ${SRC_FILE}

clean:
	rm -rf obj_dir
