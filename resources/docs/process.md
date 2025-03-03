# Architectural notes


# Discovery
## Step 1: Instruction fetch
*Where does the CPU fetch instructions from?*, *What fetches the instructions?*
- The control unit probably fetches instructions
- It fetches instructions at the address of a 32-bit program counter register (PC)
- The fetching itself probably happens using a memory-bus connected to the CPU
- This memory bus needs a certain protocol? Or it can simply fetch one instruction every "external" clock cycle. (given a cpu cycle)


The PC doesn't connect directly to memory, it goes via the MAR.
The CPU needs an
- MBR memory buffer register, used to store information being sent or received from the data-bus.
- MAR-register: memory address register, storing the address to acess memory.

For this purpose.

So
1. Copy the program counter into the MAR. 
2. Data is read according to the memory of the MAR (so this is the data that points to the location MBR needs to go, or points to the location MBR needs to read from)
3. Data goes to the MBR
4. Increment the program counter

## Step 2: Instruction decode
1. Instructions get moved to the IR (instruction register). It gets separated into chunks depending on the type of instruction.
    - Opcode  -> gets decoded and executed by the control unit
    - Address -> data, gets moved to the IR address
    - ...
## Step 3: Instruction execute
Figure out what type of instruction it is.

## Step 4: Memory access
A lot here depends on what type of instruction it is
- Arithmetic instructions where memory needs to be fetched
    - Require addressing of the memory bus
    - After addressing of the memory bus, getting the desired numbers, loading them into registers
    - The ALU is pushed to perform the necessary operations
    - The result is acquired from the ALU.

## Step 5: Write back
Write the results of all arithmetic, read/write operations back into memory through the address bus.

# Questions
### How do we initialize the stack pointer and the program counter?

