# Debug interface

# PCPI interface
Enables communication with an accelerator.

## (picorv32_pcpi_fast_mul)
### Signals
- Valid
- insn
- rs1, rs2
- wr, rd
- wait
- ready

### Architecture
- Instruction handling happens combinatorially (always @* block): 
	- Contains various instructions incoming through pcppi_insn
	- mul, mulh, mulhsu, mulhu

- A synchronous block
	- Checks the instruction
	- Writes the relevant data from the pcpi-bus into local register data
	- Sets the active-bits indicating the multiplication start

- A synchronous block
	- For pipelinging, with possibility of gating off registers

## Fast Division


## Memory
