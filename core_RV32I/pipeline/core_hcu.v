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
	input HCU_IMEM_BUSY,
	input HCU_DMEM_BUSY,
	input HCU_IMEM_DONE,
	output reg HCU_IFID_WRITE,
	output reg HCU_IFID_FLUSH,
	output reg HCU_IDEX_WRITE,
	output reg HCU_IDEX_FLUSH,
	output reg HCU_EXMEM_WRITE,
	output reg HCU_EXMEM_FLUSH,
	output reg HCU_MEMWB_WRITE,
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
*/

wire hcu_imem_hazard;
assign hcu_dmem_hazard = (HCU_DMEM_BUSY);
assign hcu_imem_hazard = (HCU_IMEM_BUSY); // Should be done in each stage in order to proceed


always @(*)
begin
	HCU_IFID_WRITE = 1'b1;
	HCU_IDEX_WRITE = 1'b1;
	HCU_EXMEM_WRITE = 1'b1;
	HCU_MEMWB_WRITE = 1'b1;
	HCU_PC_WRITE = 1'b1;
	HCU_IFID_FLUSH = 1'b0;
	HCU_IDEX_FLUSH = 1'b0;
	HCU_EXMEM_FLUSH = 1'b0;

	if (hcu_dmem_hazard)
	begin
		// Stall everything before (and including) the dmem stage
		HCU_EXMEM_WRITE = 1'b0;
		HCU_IDEX_WRITE = 1'b0;
		HCU_IFID_WRITE = 1'b0;
		HCU_PC_WRITE = 1'b0;
	end
	else if (hcu_control_hazard)
	begin
		HCU_IDEX_FLUSH = 1'b1; // Should be flushed, but idex should be executed and passed to memwb -> control hazard will go low.
		HCU_IFID_FLUSH = 1'b1;
	end
	else if (hcu_imem_hazard | hcu_data_hazard)
	begin
		HCU_PC_WRITE = 1'b0;
		HCU_IFID_WRITE = 1'b0;
		HCU_IDEX_WRITE = 1'b0;
		if (hcu_data_hazard)
		begin
			HCU_IDEX_FLUSH = 1'b1;
		end
	end
	else;
end
endmodule
