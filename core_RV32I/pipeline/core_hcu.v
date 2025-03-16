`timescale 1ns / 10ps


module core_hcu (
	// This SHOULD be the index as far as I understand, not the data
	input [4:0] REG_ARADDR1,
	input [4:0] REG_ARADDR2,
	input [4:0] IDEX_REG_AWADDR,
	input IDEX_REG_AWVALID,
	input [4:0] EXMEM_REG_AWADDR, // Data Hazards
	input EXMEM_REG_AWVALID,
	input [4:0] MEMWB_REG_AWADDR, // Data Hazards
	input MEMWB_REG_AWVALID,
	input C_REG1_MEMREAD,
	input C_REG2_MEMREAD,
	input C_TAKE_BRANCH,
	input ISJAL,
	input ISJALR,
	input HCU_MEM_BUSY,
	input HCU_IMEM_DONE,
	output reg HCU_IFID_ENABLE,
	output reg HCU_IFID_FLUSH,
	output reg HCU_IDEX_ENABLE,
	output reg HCU_IDEX_FLUSH,
	output reg HCU_EXMEM_ENABLE,
	output reg HCU_EXMEM_FLUSH,
	output reg HCU_MEMWB_ENABLE,
	output reg HCU_PC_WRITE // Fetch an instruction on each PC_WRITE
);
/*
! DATA HAZARD
If data hazard -> UNTIL data_hazard is not set anymore
- Disable the Program increment
- Stall the idecode-stage of the pipeline (since reading the rd1 and rd2 happens on clk-edge idecode->exec)
-> How do we make sure this happens?
*/

wire idex_data_hazard, exmem_data_hazard, memwb_data_hazard;

assign idex_data_hazard = (((REG_ARADDR1 == IDEX_REG_AWADDR) & C_REG1_MEMREAD) |
							((REG_ARADDR2 == IDEX_REG_AWADDR) & C_REG2_MEMREAD)) & IDEX_REG_AWVALID;

assign exmem_data_hazard = (((REG_ARADDR1 == EXMEM_REG_AWADDR) & C_REG1_MEMREAD) |
							((REG_ARADDR2 == EXMEM_REG_AWADDR) & C_REG2_MEMREAD)) & EXMEM_REG_AWVALID;

assign memwb_data_hazard = (((REG_ARADDR1 == MEMWB_REG_AWADDR) & C_REG1_MEMREAD) |
							((REG_ARADDR2 == MEMWB_REG_AWADDR) & C_REG2_MEMREAD)) & MEMWB_REG_AWVALID;

//? Shouldn't we also disable updates of the ifid on data hazards?
assign hcu_data_hazard = (idex_data_hazard | exmem_data_hazard | memwb_data_hazard);

/*
! CONTROL HAZARD
BRANCHING / JAL / JAL(R) (detected through branch_taken, isjal, isjalr)
- Flush registers exmem, idex
- PC increment should be set through cpc_update_inst
- set pc_increment ON
? FUTURE: Build a forwarding unit that, in the decode-step, also decodes the next PC based on the instruction.
*/
wire hcu_control_hazard;
assign hcu_control_hazard = (C_TAKE_BRANCH | ISJAL | ISJALR) ? 1'b1 : 1'b0;

/*
! MEMORY READ/WRITE HAZARD
IFETCH, LOAD, STORE delay (detected through CMEM_DONE, IFETCH_DONE)
*/

wire hcu_mem_hazard;
assign hcu_mem_hazard = (HCU_MEM_BUSY); // Should be done in each stage in order to proceed


always @(*)
begin
	HCU_IFID_ENABLE = 1'b1;
	HCU_IDEX_ENABLE = 1'b1;
	HCU_EXMEM_ENABLE = 1'b1;
	HCU_MEMWB_ENABLE = 1'b1;
	HCU_PC_WRITE = 1'b1;
	HCU_IFID_FLUSH = 1'b0;
	HCU_IDEX_FLUSH = 1'b0;
	HCU_EXMEM_FLUSH = 1'b0;

	if (hcu_mem_hazard)
		HCU_EXMEM_ENABLE = 1'b0;

	if (hcu_data_hazard | hcu_mem_hazard)
	begin
		HCU_PC_WRITE = 1'b0;
		HCU_IFID_ENABLE = 1'b0;
		if (HCU_EXMEM_ENABLE)
		begin
			HCU_IDEX_FLUSH = 1'b1;
			HCU_IDEX_ENABLE = 1'b0;
		end
		else
			HCU_IDEX_ENABLE = 1'b0;
	end
	if (hcu_mem_hazard)
		HCU_MEMWB_ENABLE = 1'b0;
	
	if (hcu_control_hazard)
	begin
		HCU_IDEX_FLUSH = 1'b1;
		HCU_IFID_FLUSH = 1'b1;
	end
end

// SIGNALS
// assign HCU_IFID_ENABLE = !HCU_IMEM_DONE ? 1'b0 : 1'b1;
// assign HCU_IDEX_ENABLE = (hcu_data_hazard | hcu_mem_hazard) ? 1'b0 : 1'b1;
// assign HCU_EXMEM_ENABLE = hcu_mem_hazard ? 1'b0 : 1'b1;
// assign HCU_PC_WRITE = (hcu_data_hazard | hcu_mem_hazard) ? 1'b0 : 1'b1;

// assign HCU_IFID_FLUSH = (hcu_control_hazard) ? 1'b1 : 1'b0;
// assign HCU_IDEX_FLUSH = (hcu_control_hazard) ? 1'b1 : 1'b0;

// assign HCU_EXMEM_FLUSH = 1'b0;

endmodule

/**
INPUTS:
- register reads, register writes, memory fetch, instruction fetch
HAZARDS
- Instruction fetch => If instruction fetch -> wait until the instruction fetch is done, 
- Memory Store / Load => 

*/