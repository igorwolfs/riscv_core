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

1. Instruction fetch: read instruction from memory.
2. Instruction decode: understand what instruction means.
3. Execute: perofrm operation defined in the instruction.
4. Memory access: read required memory locations.
5. Write back: write data to memory if modified.

2 clock domains are used
- One for the 5 steps
- One for the instruction fetch



# Sources
- https://medium.com/programmatic/how-to-design-a-risc-v-processor-12388e1163c
- https://www.geeksforgeeks.org/differences-between-single-cycle-and-multiple-cycle-datapath/
- https://github.com/ucb-bar/riscv-sodor/tree/master
- https://nerdhut.de/2017/07/03/custom-cpu-design-1/