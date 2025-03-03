# Registers
**NOTE:**
JAL/JALR instructions are used for accelerate function calls and returns, they use x1 and x5.

### Program counter register
(holds address of current instruction)
- PC
## General purpose registers
Each general-purpose register is 32-bits wide

### x0
- Always 0
- Used when e.g.: a 0 is used somewhere in the ALU as an operand.
- This way you don't need to load "0" into a register anywhere.
- You can move one register into another by performing an ADD with the 0 register
- You can compare by simply taking the 0 present in the register
- When a function doesn't have a return address, x1 is set to x0 (= 0)

Most of these things are compiler-level optimization.

### x1 (program control flow return address)
**Program control flow return address holder**

Holds the address where the program execution should continue AFTER a subroutine / function call.
-> So the memory address of the instruction immediately following the instruction made. The code should resume reading instructions here once the execution is done.

After function execution, it retrieves the return address and jumps to that address.

NOTE: the "return address" stored is an address in *INSTRUCTION MEMORY*. So the *Instruction memory address* is stored in *Data memory* temporarily, and when it's pointed to by the *Stack pointer*

1. function call (jal):
    - Stores return address into x1
    - Jumps to the target address
2. function prologue: Save registers function needs (arguments) + return address onto the stack
3. function body: function execution
4. function epilogue:
    - Use jump-instruction (e.g.: jr) to retrieve the address from stack (or wherever it was saved)


### x2
**mainly used as stack pointer**

### x5
Can function as an alternate link register.

### x31