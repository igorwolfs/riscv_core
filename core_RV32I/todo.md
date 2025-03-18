## Introducing store instructions
- Nothing seems to be written into the store
- There also seems a data hazard between 
	- 0x14
	- 0x18
So check if that data hazard is resolved after
It seems like for some reason the SP is set to 0 after 1 cycle.
- hcu data hazard goes high when store word instruction appears inside the ifid instruction.

So the issue seems to be that because of a data hazard
- The the memwb stays on for 2 ycles
- And perhaps the write-data command suddenly changes or something?
	- Which leads a different value to be written twice

So
- Check the idex_rdata1 next to each instruction and see if it changes throughout
- If it does we need to make sure that we flush the idex and introduce a NOP inside the exmem instead of what we are doing now.

So it seems that 
- alu_o changes but the exmem_pc stays the same.
- Which is weird because it should be flushed together with the reg_rdata1?
	- If alu_o changes it means reg_rdata1 also changes
	- If reg_rdata1 changes it's because the idex register is being updated
- But since there is a data hazard, the idex shouldn't be latched? It should be flushed even.

So it seems like
- there is a data hazard
- there is an imem memory hazard
So because of the data hazard
- We need to flush the idex stage
With the memory hazard
- We simply need to pauze everything until the imem is ready

BUT: because the imem hazard only stops everything up until idex
- The exmem keeps taking instructions from the idex
- So the alu keeps operating
But the question is why do the arguments change to 0?
- The ifid is supposed to stall? So there's not supposed to be a change in instruction?
- Check the instruction 0x14
- Check why exmem_alu_o changes for this instruction
	 - so why ALU_O changes for this instruction
	 - So why - change for this instruction
	 	- reg_rdata1  (no change)
		- imm (change)



I think the idex was simply disabled while

- there was an instruction fetch ongoing
- there was a data-hazard

While there needs to be a flush in case of a data-hazard, but the data-hazard has lower prio.
The instruction memory just needs everything to stall until idex
- But stuff will still be passed on to the exmem repeatedly? 
	- So load/stores will occur again and again
	- Writes to registers will occur again and again

The data hazard needs the 

# Putting It All Together
## Detect IMEM Hazard
– e.g., the fetch interface isn’t ready.

## Control Signals
PCWrite = 0; (stall the PC)
IF_IDWrite = 0; (stall the IF/ID register)
ID_EXWrite = 0; (stall the ID/EX register)

## Allow EX/MEM, MEM/WB
Let EX/MEM, MEM/WB registers clock normally, so the instruction(s) already in those stages continue forward and complete.

## Result
The instruction in IF stays put (waiting for memory).
The instruction in ID also stays put (so it doesn’t re-read the same IF/ID).
No duplication occurs in EX.
As soon as the hazard is gone, you un-stall the front, fetch new instructions, and proceed normally.
That’s the usual textbook logic to avoid repeating instructions during a front-end (instruction‐fetch) stall.

# CHATGPT IS STUPID
## Continuing:
- IFID store word instruction continues after the write-back (OK)
- 0x18 - 0x112623
- exmem doesn't trigger the data memory hazard.
- So the memory peripheral is not busy fetching
- So EXMEM_C_ISSTORE isn't enabled?

The moment EXMEM_C_ISSTORE is high
- The clock-cycle after DMEM should be triggered
- DMEM HAZARD should be high

DMEM_HAZARD is only high 2 cycles after.
Probably because
- EXMEM_C_ISSTORE is enabled
- on the next cycle there is a single-cycle LOAD / STORE trigger
- This single-cycle takes 1 clock cycle to trigger (which is already too long)

So perhaps we need a direct exmem_c_isload / exmem_c_isstore signal to the dmem peripheral instead of a single cycle.
This will go on until it's done.
And then afterwards we'll somehow need to disable the memory peripheral from executing the load / store one more time.