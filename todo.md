# Peripherals
- Define clear regions for data memory, instruction memory and peripherals
- Make sure to generate an extra bus for outside communication when dealing with non-simulation cases.
- Add peripheral bus
	- Work with axi-lite
	- assign memory addresses to peripheral
	- Make sure the intermediate bus does some kind-of address space check
	- Pass the request onto the bus (with perhaps an extra intermediate register)
- Add an axi-wrapper around the UART module handling the responses and requests

# Processor
- Make sure to keep the core as a one-integrated piece with the memory controller
- Put the IO outside of the CPU-core
	- Keeps it easy to actually test the CPU-core 
		- pipelining
		- memory-controlles
		- new instructions
Using the riscv-testbench

# Boot-ROM
- Think about adding some BOOT-ROM that can initialize the processor completely before running anything
- separate peripheral with instructions and data that keeps the boot-loader
- Entry code starts here, runs this first before running anything else.

# Linux
You CAN in fact run linux on a 32-bit RISC5-cpu, you DO however need an MMU: https://www.reddit.com/r/FPGA/comments/g7ucvd/requirements_for_a_riscv_core_to_be_able_to_run/.

# AXI
## AXI Data Memory
- Separate data-memory slave interface should be put inside the axi-data memory bus
- RA-bus: accepts the read address
- R-bus: reads data on RA
- Request-response 
	- Not really necessary here, except if we're going to propagate the read/write instructions to the bus level.

- WA-bus: accepts the write-address
- W-bus: writes data on WA
### Strobe
To avoid having to code all 2**4 possible cases of strobing (every byte can be strobed in any order), make sure to have 4 separate buffers, each of them 8-bits.

Access to these buffers is then separately controlled using strobing.


## AXI Instruction Memory
- Separate instruction memory slave interface should be put inside the axi-instruction memory bus
- Instruction memory should only have a read-part, the write-part can safely be ignored.

### Include axi-peripherals into the riscv-mcu and connect them to the control circuitry
MAIN ISSUE:
- We need to stall the PC if an instruction is still being executed
- So we need a default pc = pc, or non-increment 
	- IF the axi-memory bus is still being talked to.

### Instruction memory fetch
Pipelining needs to be the basis of all this

1. Set the SM to instruction fetch
2. Once the instruction is fetched, set the SM to instruction decode
3. Execute the instruction
	a. If ALU, perform combinatorially + move to NEXT_INSTR
	b. If memory instruction -> perform memory fetch, stall, once done -> move to NEXT_INSTR
	
### Global control module
- Make sure to add the global control moduel
- Add all signals
- Try connecting everything
- Add the jump control to it as well

### Jump control
