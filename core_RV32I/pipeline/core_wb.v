`timescale 1ns / 10ps

/***
Generate control signals in the idecode stage
These control signals should here simply select the correct stage here
- Depending on the action to be performed (memwb_pc+4 | memwb_imm | dmem_rdata, ..) we can perform the appropriate action here.
*/

module core_wb(
    input [31:0] MEMWB_ALU_O,
    input [31:0] MEMWB_PC,
    input [31:0] MEMWB_IMM,
    input [31:0] DMEM_RDATA,
    input MEMWB_ISALU,
    input MEMWB_ISJALR,
    input MEMWB_ISJAL,
	input MEMWB_ISLUI,
    input MEMWB_ISAUIPC,
    input MEMWB_ISLOAD,
    output [31:0] REG_WDATA
);

//! This needs to be somehow pipelined as well
// The alu_o needs to be kept during the exmem stage so it can be written inside the wb stage
// The dmem_rdata should normally be able to use the latched data from the memory fetch.
// The WB codes must be replaced by the signals which should be propagated along the registers
// e.g.: an ALU-result must always send an ALU_EN, the ALU_EN should just be propagated beyond the regular.

assign REG_WDATA = (MEMWB_ISALU) ? MEMWB_ALU_O :
                    (MEMWB_ISJAL | MEMWB_ISJALR) ? (MEMWB_PC + 4) :
                    (MEMWB_ISLUI) ? MEMWB_IMM :
                    (MEMWB_ISAUIPC) ? (MEMWB_PC + MEMWB_IMM) :
                    (MEMWB_ISLOAD) ? (DMEM_RDATA) :
                    32'hDEADBEEF;


endmodule
