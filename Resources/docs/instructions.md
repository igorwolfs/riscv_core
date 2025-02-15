# Instruction Types
## U-type instructions
### LUI
Load upper immmediate to program counter. Writes the value to a register.
- rd = imm << 12

### AUIPC
Add upper immediate to program counter.
The immediate is calculated RELATIVE to the program counter.
- rd = PC + (imm << 12)

## Load (Immediate)-instructions
Below are all the load from memory instructions. Depending on the specific instruction the data loaded from memory needs to be treated as a uint16, uint8, int8, int16.

So then the byte / half-word will be padded by zeros / ones depending on the sign.

### lb
Load signed byte
### lh
Load signed half-word
### lw
Load half-word (32-bits in our case).
### lbu
Load unsigned byte
### lhu
Load unsigned half-word 

## Jump-intructions
### JAL
Jump-and link, jump to a known address and save the return address for function calls
- J-immediate encodes a signed offset.
- JAL stores address of instruction following jump (pc+4) into register rd.
- x1: return address
- x5: alternate link register

### JALR
Jump to an address in a register WITHOUT saving a return address 
- used for return functions where the address is already saved
- I-encoding
    - 12-bit I-immediate is added to rsl.
    - least-significant bit of the result is set to 0
    - address of the instruction is written to rd.
- Used to enable 2-instruction sequence to be able to jump 32-bits.

## Branching instructions
Note: use jump-instructions for unconditional jumps. Branch instructions only for conditional jumps.
- Depending on whether the condition is fulfilled (== >= <= !=)

## System instructions
Make sure to raise an error when either the ecall or ebreak instruction is called.

# Instruction fields
### rd-field
Indicates where to write the result of an instruction to.

### funct3, funct7
Give more information about what sub-operation should be done within an opcode.

### imm
Immediate field, it encodes an immediate to do an operation with.

### rs1, rs2
Indicate which of the 32 registers need to be used to perform the operation in the CPU.

## R-Type math instructions
Instructions used to indicate arithmetic and logic operators such as
- add, subtract, xor, or, and, ..

On 2 register values

## I-Type math instructions
Directly beform an arithmetic / logic operator on a register with an immediate number.
