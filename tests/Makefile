CPU_DIR := ../core_RV32I/
VHDL_LIBS := ../vhdl_libs/
TESTBENCH_NAME := top_tb

#! NOTE: "find -name ''" looks for files recursively inside the SRC_DIR
SRC_DIRS := ${CPU_DIR} ${VHDL_LIBS}
SRC_FILE := $(shell find $(SRC_DIRS) -name '*.v') $(shell find $(SRC_DIRS) -name '*.sv') \
			$(shell find $(SRC_DIRS) -name '*.vh') $(shell find $(SRC_DIRS) -name '*.svh')

ifeq (${TESTBENCH_NAME}, top_tb)
    CPP_FILE = sim_top_main.cpp
else
    CPP_FILE = INVALID_TOP_NAME
endif

# Verilator options
VERILATOR_OPTS = -cc \
    --exe \
    --trace \
    --trace-structs \
    --build \
    --timing \
    -Wno-PINMISSING \
    -Wno-ASSIGNIN \
    -Wno-UNSIGNED  \
    -Wno-WIDTHEXPAND

 # Make sure to unset this warning when first compiling + check warnings (
 # -Wno-MODDUP \
 # -Wno-COMBDLY \
 # -Wno-NULLPORT \
 # -Wno-WIDTHEXPAND\ #! WARNING: This is a very risky macro to ignore, be VERY CERTAIN when using it.
 # -Wno-UNOPTFLAT
    #    -Wno-COMBDLY \
    # -Wno-UNSIGNED \
    # -Wno-WIDTHEXPAND\

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
