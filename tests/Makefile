CPU_DIR := ../core_RV32I/
TESTBENCH_DIR := ${CPU_DIR}testbenches/
TESTBENCH_NAME := control_tb

SRC_DIRS := ${CPU_DIR} ${TESTBENCH_DIR}
SRC_FILE := $(shell find $(SRC_DIRS) -name '*.v') $(shell find $(SRC_DIRS) -name '*.sv')
INCLUDE_FILES =  $(shell find $(SRC_DIRS) -name '*.vh') $(shell find $(SRC_DIRS) -name '*.svh')

ifeq (${TESTBENCH_NAME}, control_tb)
    CPP_FILE = sim_main_control.cpp
else ifeq (${TESTBENCH_NAME}, top_tb)
    CPP_FILE = top.cpp
else
    CPP_FILE = INVALID_TOP_NAME
endif

# Verilator options
VERILATOR_OPTS = -cc \
    -Wno-NULLPORT \
    -Wno-COMBDLY \
    -Wno-PINMISSING \
    -Wno-MODDUP \
    -Wno-UNOPTFLAT \
    --exe \
    --trace \
    --trace-structs \
    --build \
    --timing

 # Make sure to unset this warning when first compiling + check warnings (
 # -Wno-UNOPTFLAT

.PHONY: run clean

# target (binary name) : dependencies
obj_dir/V$(TESTBENCH_NAME): ${SRC_DIR}/* $(SRC_FILE)
	verilator \
	-cc \
	-Wno-NULLPORT -Wno-COMBDLY -Wno-PINMISSING -Wno-MODDUP -Wno-UNOPTFLAT \
	--exe \
	--trace \
	--trace-structs \
	--build \
	--timing \
	sim_main_control.cpp \
	../core_RV32I/define.vh \
	../core_RV32I/mcu.v \
	../core_RV32I/dmemory.v \
	../core_RV32I/imemory.v \
	../core_RV32I/core.v \
	../core_RV32I/control.v \
	../core_RV32I/alu.v \
	../core_RV32I/single_ff.v \
	../core_RV32I/registers.v \
	../core_RV32I/testbenches/top_tb.sv \
	../core_RV32I/testbenches/control_tb.sv \
	-I../core_RV32I \
	--top top_tb \
	-j `nproc`
# verilator $(VERILATOR_OPTS) ${CPP_FILE} $(SRC_FILE) -I$(INCLUDE_FILES) --top $(TOP_NAME) -j `nproc`
# verilator	-cc	-Wno-NULLPORT	-Wno-COMBDLY	-Wno-PINMISSING	-Wno-MODDUP	--exe	--trace	--trace-structs	--build	--timing	src/sim_main.cpp	$(SRC_FILE)	-I$(SRC_DIR)	--top	$(TOP_NAME)	-j	`nproc`

run: obj_dir/V$(TESTBENCH_NAME)
	./obj_dir/V$(TESTBENCH_NAME)

print_sources:
	@echo "SOURCES:"
	@echo ${SRC_FILE}
	@echo "INCLUDES:"
	@echo ${INCLUDE_FILES}

clean:
	rm -rf obj_dir