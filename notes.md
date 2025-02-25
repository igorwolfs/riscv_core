# Von Neumann Architecture
1. ALU (Arithmetic and Logic Unit)
    - Performs mathematical operations
    - Performs logical operations
2. MMU (memory management unit)
    - Stores instructions and data
3. CU (Control unit)
    - Manages execution of instruction and program.

## Multi-cycled vs single-cycled
### Single-cycled data-path: 
Completes each instruction in a single clock cycle.
- Simpler design, but less efficient

### Multi-cycled data-path
Entire instruction is divided into multiple parts. Each of these parts happen in serial fashion. (e.g.: fetch, compute, ..)
- Each step is implemented in a different cycle, so a single instruction takes multiple steps.
- The control unit here however needs to be more complicated, and extra registers are requierd to hold the results for later operation / computation.

## CPU steps for instruction execution
According to the classic RISC pipeline, instructions are:
1. Instruction fetch: read instruction from memory.
2. Instruction decode: understand what instruction means.
3. Execute: perofrm operation defined in the instruction.
4. Memory access: read required memory locations.
5. Write back: write data to memory if modified.

Or more specifically 
1. emit the contents of PC (the "program counter register") to the address bus;
2. read the instruction opcode from the data bus;
3. increment PC;
4. decode the opcode to discover that it is supposed to be followed by an operand;
5. emit the contents of PC to the address bus;
6. read the operand (in this case 10) from the data bus;
7. increment PC;
8. feed the operand and SI to the adder;
9. emit the result of the adder to the address bus;
10. read AX from the data bus.ä


2 clock domains are used
- One for the 5 steps
- One for the instruction fetch


# Sources
- https://medium.com/programmatic/how-to-design-a-risc-v-processor-12388e1163c
- https://www.geeksforgeeks.org/differences-between-single-cycle-and-multiple-cycle-datapath/
- https://github.com/ucb-bar/riscv-sodor/tree/master
- https://nerdhut.de/2017/07/03/custom-cpu-design-1/
- https://en.wikipedia.org/wiki/Instruction_pipelining
- https://en.wikipedia.org/wiki/Classic_RISC_pipeline
- https://vivonomicon.com/2020/06/13/lets-write-a-minimal-risc-v-cpu-in-nmigen/

# Comes in handy
### If the top file can't be found
Go to the folder and run the following command:

```bash
verilator --cc top_file.sv --exe sim_main.cpp --top fifo_async_circular_parallel_tb -o sim
```

### Running an example in vivado
```bash
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O0 -nostartfiles -nostdlib -T link.ld *.S -o my.elf
riscv32-unknown-elf-objcopy my.elf -O binary my.bin
hexdump -v -e '1/4 "%08x\n"' my.bin > my.hex
riscv32-unknown-elf-objdump -d my.elf > my.txt
```