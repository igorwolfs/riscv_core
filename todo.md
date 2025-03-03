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
