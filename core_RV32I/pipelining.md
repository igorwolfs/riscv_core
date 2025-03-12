# Pipelining
0->1
- INSTRUCTION, PC (imem)

1->2
- RDATA1, RDATA2 (in core_registers)
- funct3, funct7, isimm, imm, reg_awaddr (idecode)

2->4 EX_WB
- ALU_O (alu)
- TAKE_BRANCH (core_cbranch)

2->3
- DMEM_ADDR, ISLOADBS, ISLOADHWS, STRB (core_cmem.v)

3->4 MEM_WB
- RDATA (from core_mem.v)

4->0 WB_FETCH (write back and pc increment, but nothing latched)
- 

# Issue
## Datapath overview
- It's hard to get an overview of the data-path in the CPU
	- It's hard to understand at which stage which instructions will be necessary
	- One needs to view every separate datapath individually for this purpose and write it down somewhere
## Carrying registers
- IMM, REG_AWADDR: needs presence in all further stages

## Different stage crossings
- When we are dealing with
	- One instruction which requires carrying from the EX to the WB stage.
	- One instruction which requires carrying from the MEM to the WB stage.

How do we carry this register from one to the other?
### Option 1
- Carry the register from 0 -> 1
- Carry the register from 1 -> 2
- Stall everything else while read or write is occurring
- Carry register from 2->4


## How should the stall happen?
- We can probably inside our state machine / register transition system insert a if (stall).
- If this stall is enabled no registers will be carried over
- If it is enabeld registers will be carried over.


## Register for each state transition or for each stage?
We have instructions that jump directly from the instruction-decode stage to the write-back stage.
So we can solve this in 2 ways
- We can have an extra register for this transition, and based on the previous instruction the register update can decide to carry registers from this stage along
- We can just keep 1 register called idex, and in the wb-stage a decision can still be made to update from the idex register based on a signal.
	- Best option
	- Although we'll need to perhaps update the names of our registers then so they don't indicate transitions but more end-of-cycles

- So keep only a single register for each stage
- Make sure to perform the carries from the correct registers
	- Based on control signals (e.g.: the instructions from one of the previous stages / control signals should indicate which instruction to carry for which stage)

The instruction decode stage should enable signals that 
- indicate which registers should be carried where to
- which control signals should be enabled