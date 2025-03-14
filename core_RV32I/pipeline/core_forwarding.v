module core_forwarding (
	input C_TAKE_BRANCH,
	input [31:0] MEMWB_IMM,
	input [31:0] PC,
	output [31:0] PC_NEXT;
);

// Calculates the next program-counter increment based on the instruction (JAL(R) / BRANCHING)
/**
So
- We must know the increment for a JAL and JAL(R) instruction at the end of the exec stage (instruction decode stage -> later)
- We must know the branch needs to be taken at the end of the EXEC-stage
	- Then the branch_taken-signal will go high
	- Or the JAL(R) signal will go high
	- When these signals will go high we'll need to
		- flush the pipeline in the HCU-unit
		- set the pc_next to the pipeline-registered pc_next using the memwb_imm
Later you can think about adding an an adder inside the instruction decode unit.
*/

reg [31:0] pc_next;
always @(*) begin
pc_next = pc + 4;
case (c_wb_code) // Make sure this code is somehow already determined inside the ifetch stage
	`WB_CODE_JAL, `WB_CODE_BRANCH: pc_next = pc + memwb_imm;
	`WB_CODE_JALR: pc_next = reg_rdata1 + memwb_imm;
	default: pc_next = pc + 4;
endcase
end

assign PC_NEXT = (C_TAKE_BRANCH) ? PC + MEMWB_IMM :
				(c_wb_code == `WB_CODE_JAL)

// 


endmodule
