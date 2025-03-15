`timescale 1ns / 10ps


module core_hcu (
	// This SHOULD be the index as far as I understand, not the data
	input [4:0] REG_ARADDR1,
	input [4:0] REG_ARADDR2,
	input [4:0] EXMEM_REG_AWADDR, // Data Hazards
	input [4:0] MEMWB_REG_AWADDR, // Data Hazards
	input C_REG1_MEMREAD,
	input C_REG2_MEMREAD,
	input C_TAKE_BRANCH,
	input ISJAL,
	input ISJALR,
	output HCU_IDEX_ENABLE,
	output HCU_IDEX_FLUSH,
	output HCU_EXMEM_ENABLE,
	output HCU_EXMEM_FLUSH,
	output HCU_PC_WRITE
);
/*
If data hazard -> insert nop instruction, (should be detected with hazard before ID-phase), if detected NOP should be inserted until done
- Disable the Program increment
- Stall the idecode-stage of the pipeline (since reading the rd1 and rd2 happens on clk-edge idecode->exec)
- Wait until the hcu_data_hazard isn't set anymore
-> How do we make sure this happens? 
Data hazard can occur both with the potential write from mem-instruction as well as the potential write from the wb-instruction
*/


wire hcu_data_hazard = (((REG_ARADDR1 == MEMWB_REG_AWADDR) | (REG_ARADDR1 == EXMEM_REG_AWADDR)) & C_REG1_MEMREAD) ||
						(((REG_ARADDR2 == MEMWB_REG_AWADDR) | (REG_ARADDR2 == EXMEM_REG_AWADDR)) & C_REG2_MEMREAD);

/**
Control (branching) hazard
If branching
- Flush registers exmem, idex
	- Stop all ongoing memory operations
- Set the PC increment to the branch / JAL / JALR increment
JAL(R)
- Build a forwarding unit that, in the decode-step, also decodes the next PC based on the instruction.
NOTE:
- Branches are typically resolved in the exec stage, just like the JAL(R) instructions
	- So flushing is only necessary for the id and the exec-stage.
*/

/**
Control (JAL(R)) hazard
If there's a control hazard
- Detect the control hazard in the exmem stage (if JAL(R)-instruction)
- When such a control hazard is detected:
	- The immediate is decoded in the idex-stage
- (JAL(R) in flush the instruction-decode and the exec stage
- Enable the PC-update.
	- Calculate the immediate update value in the exec stage
	- In the exmem-stage: update the immediate
Best way to do this is probably to have 2 extra signals showing if
	- it is a jal / jalr coming directly from the idecode
	
*/

wire hcu_control_hazard = (C_TAKE_BRANCH | ISJAL | ISJALR) ? 1'b1 : 1'b0;

assign HCU_IDEX_ENABLE = (hcu_data_hazard) ? 1'b0 : 1'b1;
// Should be enabled in case of a control hazard => but the correct value
// BUT: the correct value should be passed on by some control unit.
assign HCU_PC_WRITE = (hcu_data_hazard) ? 1'b0 : 1'b1;
assign HCU_IDEX_FLUSH = (hcu_control_hazard) ? 1'b1 : 1'b0;
assign HCU_EXMEM_FLUSH = 1'b0;

endmodule

/**
INPUTS:
- register reads, register writes, memory fetch, instruction fetch
HAZARDS
- Instruction fetch => If instruction fetch -> wait until the instruction fetch is done, 
- Memory Store / Load => 

*/