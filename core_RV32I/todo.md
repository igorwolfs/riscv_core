## TODO
- Now it seems we're dealing with some kind-of bus interconnect issue.
	- The instruction being passed is "undefined" for some reason
	- Check the interconnect, what signals are coming in, and the RAM

## Issue with PC
Now it seems the PC is jumping from 0x8 to 0x3 for some reason.
- Let's check how the JAL instruction does now.
- Now it seems like the isjal instruction isn't propagated at all for some reason.
	- Which is correct

Check the islui instruction and if it does what it should
 - The islui-instruction seems to propagate correctly
 - At the end of propagation
	- LUI does load 0x40000 into the register

Addi
- addi seems to still subtract 1 from 0x0 instead of stalling and using the value from 0x40000000 put there by the lui instruction.
- Check if the ALU signal is propagated correctly
- isalu seems to be propagating well through the pipeline
- shortly after that it triggers again due to
	- ADDI sp, t0, 0
	- So t0 is moved here to the stack pointer
## Is the pipeline stalled correctly?s
- The add immediate should not be latched to idex before the wb is completed
- Don't assert the data hazard if writing is not involved
	- Should there also be a hazard in case the IDEX_REG_AWADDR == REG_ARADDR1 or REG_ARADDR2?
	- When does the RDATA get latched? At the idex edge
	- So before the rdata gets latched, we should trigger the hazard
So if the idex_reg_awaddr sees a hazard in the RDATA1, RDATA2 the hazard signal should already be triggered
- Then the idex should simply pass until the wb stage
- When the wb stage is finished it should allow latching of the idex stage again.
ALSO
- A check should be done for mem_stage_creg_awvalid and mem_staage_awaddr != 0 before triggering a hazard

## Incremented PC to 40000000
Now for some reason the PC is incremented to the LUI value.
- So that means that 
	- The PC_WRITE was enabled 
	- There was a wrong idecode somewhere

## HCU data hazard
- Fix the HCU data hazard issue.

## PC update
Why does the PC get updated
Probably because of some invalid instruction passing through.
- It seems like "deadbeef" is latched as an instruction.
	- Why is the latching happening? 
	- Is DONE set? Maybe not and maybe that's the issue
	- Maybe the combinatorial instruction which is latched every clock cycle should only be latched when an instruction is fetched
	- But then the busy should also be high which it's not
		- So that indicates no current fetching?
- Check the axi signals of imem

### Issue
- For some reason the PC_WRITE goes high
	- PC write goes high 
		- Signal for a new fetch to start
		- Signal for a PC increment
		- NOT a signal for an ifetch -> idecode transition.
- IFID transition
	- Happens every clock cycle
	- Should happen ONLY after a valid instruction was fetched (so after IFETCH_BUSY goes low)
	- So there should be a separate signal for this (on negedge IFETCH_BUSY -> update)
	- Or on ALL IFETCH HIGH -> do update
	- So only fetch an instruction on the data-valid

### PC update
Now the PC updates too quickly for some reason.
- Now it seems that HCU_PC_WRITE is jsut 1 all the time
- It seems that busy is just 0 all the time.

WHY?
- It seems like the data hazard is triggered on fetching the second instruction
- The instruction the doesn't proceed through the pipeline
- Because of this the data hazard signal stays high.
- The issue seems to be that the 40002b7 instruction (PC 0) doesn't proceed through the pipeline
	And therefor never does a WB
ISSUE
- So the IDEX Stall is enabled
	- This means the idex register should not be updated with the next instruction
	- It should be updated with a NOP
	- BUT the instruction should still propagate
- Because of that the idex doesn't propagate to the exmem.



## ALU Issue
Now for some reason the ALU doesn't indicate the sum was done for some reason.
- For some reason the 0x4 doesn't propagate from idex_pc to exmem_pc
- The memwb does propagate but for some reason doesn't show a value
So for some reason the idex_pc deosn't propagate to the exmem stage while the ifid does propagate to the idex

### Q
Why is the hcu_exmem_enable not high? It should be high to enable updating the exmem from the idex

- Because of an HCU memory hazard it raises it's not being updated
- So we need to wait until the memory hazard is over.
	- We need to keep track of the idex registers
	- We need to make sure the execute step doesn't do aynthing for now
		- Probably by inserting a NOP
	- And then on the exmem_enable the idex instruction should be again passed on.

So:
IF a stage is stalled, the next stage is not enabled
- then we should simply keep stalling the stage
IF a stage is stalled, the next stage is enabled
- then we should flush the stage

Example:
- If the idex is stalled
- the exmem is not enabled
	- Then the idex should be flushed.

- So now for some random reason there is an error in the way the immediate is transferred.
- the c_islui is transferred one clock-edge later than the actual immediate
- the pc is transferred 1 clock cycle after the immediate
- So there is perhaps something wrong with the immediate latch?