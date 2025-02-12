# Registers
### General purpose registers (x0 .. x31)
32 registers of 32 bits wide.

- x0 (hardwired to be 0)
- x1 (general purpoe)
    - usually holds return address for a call
    - x5 can be an alternate link register
- x2 (usually used a stack pointer)

- x31 (general purpose)

**NOTE:**
 JAL/JALR instructions are used for accelerate function calls and returns, they use x1 and x5.

### Program counter register 
(holds address of current instruction)
- PC

# Instructions
There are 4 core instruction formats

They are usually aligned 32-bit. (IALIGN-bit)
-> Can be relaxed to IAALIGN-16 however for special instructions.
## Instruction fields
- rs1, rs2: source registers
- rd: destination register
- funct3: bits 12-14 of the instruction: used to specify variants within a particular opcode such as
    - Arithmetic operations(ADD, SUB, XOR, OR, AND)
    - Branch instructions (BEQ, BNE, BLT, BGE)
- funct7: bits 25-31 of the instruction word, provide additional differentiation for the R-type instruction
    - ADD, SUB, MUL
- imm (Immediate) Field is an immediate value embedded directly in the instruction. The purpose depends on the instruction itself

## Integer computational instructions
Mostly done in
- I-type format (for register-immediate)
- R-type format (for register-register operations)

### Integer-register Immediate instructions
- ADDI
- SLTI
- ANDI, ORI, XORI (logical operations with immediate)
- SLLI, SRLI (left / right-shift)

### NOP-instruction
Advances the PC, increments any performance counters.
- ADDI x0, x0, 0

### Control Transfer Instructions
Instructions that force the program counter to jump to a certain place in memory. They are all PC-relative.

On access-fault or instruction page-fault, exception is reported on target instruction. NOT on the jump / branch instruction.

#### Unconditional jumps
- JAL (Jump and Link)
    - J-immediate encodes a signed offset.
    - JAL stores address of instruction following jump (pc+4) into register rd.
    - x1: return address
    - x5: alternate link register
- JALR (jump and link register)
    - I-encoding
        - 12-bit I-immediate is added to rsl.
        - least-significant bit of the result is set to 0
        - address of the instruction is written to rd.
    - Used to enable 2-instruction sequence to be able to jump 32-bits.

Misalignment exception generated if target not aligned to 4-byte boundary.

#### Conditional branches
B-type instruction format is used.

- BEQ: branch if equal
- BNE: branch if not equal
- ..

## Load and store instructions
Transfer values between registers and memory.

## Memory ordering instructions
### Fence-instruction
Used to perform I/O and memory access.

## Environment Call and Breakpoints
2 main classes
- atomically read-modify-write control and status registers (CSR)
    - See chapter 7
- Other (potentially) priviliged instructions
### Instructions
- ECALL: used to make a service request
- EEI: defines how parameters are passed for the request
- EBREAK: 
    - returns control to debugging environment
    - Semi-hosting execution environment


## Hint instructions
Used to communicate performance hints.
- simple RISCV processor can function without them.

## CSR Instructions
Mostly used for counters, timers and floating point status.