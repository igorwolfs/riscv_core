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


## Issue with third instruction
- Dat ahazard not asserted
- Instruction is present at the ifid_pc
	- This is where the data hazard should be asserted when seeing the instruction at the idex_pc.
	- Only a memory hazard is asserted however
add t0 to 0 and put to program counter
So the reg1_raddr should be t0 (x5)
This should conflict with the waddr of the 0x4 instruction (also x5)

Because of the if REG_RADDR_1 == REG_WADDR_IDEX OR REG_RADDR_2 == REG_WADDR_IDEX etc..
Now for some reason REG_ARADDR1 and REG_ARADDR2 are both 0
because a nop instruction was inserted, but the PC is 0x8 what?
For some reason the instruction out turned to 0x13 although it was latched to the correct 0x28113 before.
There was no write involved.

- imm: should be 0x8 (0x8+0xc = 0x14)
- isjal should be 1
- At the end of the exec stage
	- Everything should be replaced by nops
	- The PC_NEXT should be changed to PC+imm
	- The PC_WRITE should be enabled

- The issue seems to be
	- The instruction fetch has priority
	- So everything blocks on the instruction fetch, even a flush
	- SOLUTION: 
		- give the flush priority over this particular memory hazard (ifetch memory hazard)
		- 

## JAL Issues

For some reason teh PC is decrementing? 
- No idea really why that is happening.
- The JAL instruction suddenly went back to PC 10, then 8 and then c

It seems like the JAL immediate is 0x8
- But the moment the idex register is equal to that value, everything probably gets flushed due to the hcu_control_hazard
- At the same time as the flush there is a memory hazard

So everything probably gets flushed, while
- If the memory hazard is an instruction fetch: it should prioritize the flush
- If the memory hazard is a data-memory one, it should prioritize the data-memory hazard over the control hazard.


So 
1. Data memory hazard
2. Control hazard
3. Instruction memory hazard
4. Data hazard

HOWEVER:
- We'll have an issue when
	- There is a control hazard
	- The instruction fetch is ongoing.
	- How do we cancel the instruction fetch here and disable all axi-bus communication on the instruction-fetch bus?
FOR NOW just flush in case of control hazard and not data memory hazard.
- Or maybe the idex register should just be stalled instead of being flushed?
- Because the control hazard is actually only enabled by idex signals.
	- So the idex signals should normally only be stalled (although they can also simply be executed)
	- But when it's an imem-only the instruction fetch can in-fact be stopped.

### PC high
The issue now is the PC_WRITE is held for too long.
- Normally the PC_WRITE should have been held high the moment the idex_pc and idex_imm registers got filled with the 0cx and 0x8
So
- That probably happened
- But once that happened the instruction fetch for some reason 
	- Didn't increment accordingly?
	- Didn't break off the fetch and start again.

So
- Check the PC increment with the idex immediate
- Check how you can break-off the ifetch when in control hazard mode.

### Control hazard stays high
So now the issue seems to be that 
- the control hazard keeps the idex-instruction from moving on.
- Because the idex instruction isn't moving on, the control hazard stays on.

CONCLUSION: the idex needs to be enabled on a control hazard here if there is no dmem issue
- However then the idex will simply catch the ifetch values.
- So it should be done in 2 cycles
1. The idex register should be flushed, but only in case there is no data memory hazard.

### Question
- Should everything be disabled until the hazard is over?
	- I believe so
- DMEM hazard
	- exmem, idex and ifid should be disabled
	- PC write should be stalled
- CONTROL hazard
	- IDEX should be flushed
	- IFID should be flushed
	- EXMEM should be updated
	- PC should be updated
- IMEM hazard
	- Everything after idex can be enabled
	- EXMEM enabled because we know the relevant data is fetched there
	- PC write should be disabled
	- IFID should be disabled
	- IDEX can be enabled?
		- It takes it's data from the ifid
		- So it should be enabled if there's a valid ifid
		- The ifid will then be flushed, which will lead to a NOP in the idex register on the next cycle
- DATA hazard
	- Should basically do the same thing
	- except it should flush the idex register?
		- The idex still needs to be executed
		- The next exmem will then be a NOP
		- It should be flushed, because 
			- otherwise the IDEX will take over the IFID
			- The IFID was then the instruction with the data hazard
		- So the IFID should be on hold
		- The IDEX should be flushed

NOTE: 
- flushing the idex means the idex will be executed and then replaced by a NOP
- holding the idex means the idex will not be updated with a previous value