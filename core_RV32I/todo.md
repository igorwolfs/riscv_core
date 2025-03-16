## Third instruction = Progress
- The instruction propagates to the last sttage
- Nothing seems to be executed however?
Does it wait for the previous instruction though?
- The 0x8 is in fact waiting for the 0x4 to complete execution.

So check the ALU signals, and check why some things aren't written when they are supposed to be
- Check ALU_O as well

- The RDATA actually gets latched a cycle after the write so this shouldn't be the cause
- Check the RDATA1 and RDATA2
- The value is probably transported through but the write is probably simply not enabled

## Stalling memwb
The issue seems to be that the memwb_alu_o doesn't get written to the memwb-stage together with the program counter
- the program counter is one step behind for some reason.
- Or maybe it's not behind at all, maybe the alu_o latched is the wrong one for some reason.

That is in fact correct.

- the idex_pc latched is 0x8.
- The alu_o was 3fffffff already before the idex_pc latch to 0x8.
- The 0x3fffffff doesn't get latched anymore 

Questions
- Why does the ALU_O suddenly change without the idex_pc changing?
	- I thought the rdata-indices actually changed on the idex edge only?
	- Probably because the idex_pc does change, but it's just not visible

## Find the earliest error
- 0x28113 is fetched
- 0x28113 is latched into ifid a cycle after the fetch
- Then a data hazard occurs.
- When the write is done the data-hazard is dropped
	- HCU_PC_Write is held high
- Then the PC write is triggered again
	- ifid was latched

## Question
- Is it normal that the ifid isn't enabled together with the other signals?
- Doesn't that lead to errors?
	- What if an instruction is latched, and the next instruction is decoded before the current one is latched or vice versa?
	- Opposite side: it doesn't really matter probably because the instruction fetch latch always happens before everything else.


## IFID JUMP
Bow for some reason the IFID jumpst from 0 to 8.
- This is probably because the HCU_PC_WRITE is enabled for 2 clock cycles while it should only be enabled for 1.
- The HCU_PC_WRITE can ONLY be enabled when the idex stage is enabled
	- I guess that is indeed what is happening now.
	- But why is the idex and exmem stage enabled for 2 cycles, but the ifid isn't?
	- I thought the instruction fetching itself (MEM_BUSY) should make everything stop working.
- hcu_ifid_enabled is only enabled on done (so combinatorially)
- Make sure to increment the PC at the exec edge? Ask chatgpt how this normally happens.
The reality is you don't know if a PC will be ready at the IMEM_DONE time, so incrementing it then doesn't seem to make a lot of sense, especially when starting to add MEM_DONE operations.

Or maybe not
- The PC should be incremented in the IF stage
- Add an extra register to store the instruction that was fetched.

### Fix the double-cycle instruction fetch
- the problem is an ill-asserted hazard
- In reality the done signal should have been asserted only once
- And a memory hazard should have been asserted the rest of the time.
- What I did

## Issue with second instruction increment
For some reason the instruction 0x4 latches registers late enough, hwoever the alu_o result doesn't correspond with the expected one.
- Check the arguments of the alu-operation
- check the alu output

It seems like the data hazard signal suddenly stopped.
On this stop the pipeline kept going.
However:
- the ifid instruction somehow bypassed the idex-stage?
- The ALU_O signal was already 0x400000000 before the idex_pc was 0x4 How is that possible?
- The IFID instruction kept steady
- The idex_pc took over the ifid pc
- So there all the updates went well?

It seems like the ALU_O suddenly just changed for no reason
- the idex_reg_rdata1 is 0x4
- the idex_pc is 0x4
- So the alu_o should be 0x3fffffff

The imm_decode for some reason is 0xfffffffff?
- It should be -1


It seems like ALU_I1 was 0x40000000 and suddenly became 0x0 after the pipeline register updates.

So with PC = 0x4 in the exmem state the situation should be
- idex: reg_rdata1: 0x40000000 OK
- idex: imm: 0xffffffff OK
- The data_out should be 0x3fffffff

But the ALU_I1 for some reason is 0x0 instead of idex_reg_rdata1. Why?

00028113
