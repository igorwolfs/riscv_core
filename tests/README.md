# Testing / Deployment
## Compilation Instructions
In order to compile a C-snippet and generate an appropriate hex-file to run on the CPU.

### Step 1: execute the following commands with the toolchain:

```bash
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
    -O0 -nostartfiles -nostdlib \
    -T link.ld \
    main.c startup.S \
    -o main.elf

riscv32-unknown-elf-objcopy main.elf -O binary main.bin
hexdump -v -e '1/4 "%08x\n"' main.bin > my.hex
riscv32-unknown-elf-objdump -d main.elf > main.txt
```

### Step 2: Change path to hex inside the memory.sv file
Change the default inside the 
```verilog
if (!$value$plusargs("MEM_PATH=%s", mem_path)) mem_path = "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscv_core/tests/add-01.S/dut/my.hex";
	$readmemh(mem_path, ram);

$display("Memory module initialized");
```

Or add the path as argument when running the simulation (check the riscv-riscof testbench riscv_core plugin).

### Step 3: Enable settings for simulation / real-time usage
Examples:
- enable the second slave peripheral on the bus (S1_EN), to enable UART if required.

- (sim only) enable the third slave peripheral on the bus (S2_EN) in case something needs to be written to a file, check the axi_file_handler.sv.

- Inside memory, define the TEST_ENABLED macro if you want to pass the memory to be loaded into RAM through an additional argument. (used for riscof-testbench)

- Make sure enough memory is allocated inside the memory-peripheral to contain the instructions, stack, globals, etc..

### Step 4: Running the simulation / Synthesising

In order to synthesize everything