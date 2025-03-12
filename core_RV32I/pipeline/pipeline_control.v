`timescale 1ns/10ps

`include "define.vh"

module pipeline_control (
	output reg C_INSTR_FETCH,
	output reg C_ALU,
	output reg C_DECODE,
	output reg C_REG_AWVALID,
	output reg C_CMEM,
	output reg C_DOSTORE,
	output reg C_DOLOAD,
	output reg C_BRANCH,
	output reg C_PC_UPDATE,
	output reg [3:0] C_WB_CODE,
	input CLK,
	input NRST,
	input C_IMEM_DONE,
	input C_MEM_DONE,
	input C_TAKE_BRANCH,
	input [6:0] OPCODE
);

  // ==============================================
  // CENTRAL LOGIC
  // ==============================================

localparam S_IFETCH = 0;
localparam S_IDECODE = 1;  // Normally the register read should be done here as well
localparam S_EXEC = 2;
localparam S_MEM = 3;
localparam S_WB = 4;

reg [3:0] next_state;

// ASSIGN NEXT STATE DEPENDING ON WHETHER S_IFETCH WAS SUCCESFULL
always @(*) begin
  C_INSTR_FETCH = 1'b0;
  C_ALU = 1'b0;
  C_DECODE = 1'b0;
  C_REG_AWVALID = 1'b0;
  C_CMEM = 1'b0;
  C_DOSTORE = 1'b0;
  C_DOLOAD = 1'b0;
  C_BRANCH = 1'b0;
  C_PC_UPDATE = 1'b0;
  C_WB_CODE = `WB_CODE_NONE;
  next_state = S_IFETCH;
  case (state_machine)
	S_IFETCH: begin
	  // Instruction fetch
	  C_INSTR_FETCH = 1'b1;
	  if (C_IMEM_DONE) begin
		next_state = S_IDECODE;
	  end else begin
		next_state = S_IFETCH;
	  end
	end
	S_IDECODE: begin
	  C_DECODE = 1'b1;
	  // Register read and decode stage (takes 1 cycle, always)
	  case (OPCODE)
		`OPCODE_J_JAL, `OPCODE_I_JALR, `OPCODE_U_LUI, `OPCODE_U_AUIPC:
			next_state = S_WB;
		default: 
			next_state = S_EXEC;
	  endcase
	end
	S_EXEC:
	begin
	  case (OPCODE)
		`OPCODE_R: begin
		  next_state = S_WB;
		  C_ALU = 1'b1;
		end
		`OPCODE_I_ALU: begin
		  next_state = S_WB;  // Go to next state, by default immediate is not used
		  C_ALU = 1'b1;
		end
		`OPCODE_I_LOAD, `OPCODE_S: begin
		  next_state = S_MEM;
		  C_CMEM = 1'b1;  // Latches the memory control signal
		end
		`OPCODE_B: begin
		  next_state = S_WB;
		  C_BRANCH   = 1'b1;
		end
		default: next_state = S_WB;
	  endcase
	end
	S_MEM:
	case (OPCODE)
	  // Memory control signals (raddr, load, loadbs, loadhws, store, strb) are latched
	  `OPCODE_I_LOAD: begin
		C_DOLOAD = 1'b1;
		if (C_MEM_DONE)  // DMEM AXI STALL
		  next_state = S_WB;
		else next_state = S_MEM;
	  end
	  `OPCODE_S: begin
		C_DOSTORE = 1'b1;
		if (C_MEM_DONE)  // DMEM AXI STALL
		  next_state = S_WB;
		else next_state = S_MEM;
	  end
	  default: next_state = S_WB;
	endcase
	S_WB: begin
	  // PC increment calculation from immediates
	  next_state  = S_IFETCH;
	  C_PC_UPDATE = 1'b1;
	  case (OPCODE)
		`OPCODE_R, `OPCODE_I_ALU: begin
		  C_WB_CODE = `WB_CODE_ALU;
		  C_REG_AWVALID = 1'b1;
		end
		`OPCODE_B: begin
		  if (C_TAKE_BRANCH) C_WB_CODE = `WB_CODE_BRANCH;
		  else;
		end
		`OPCODE_I_LOAD: begin
		  C_WB_CODE = `WB_CODE_LOAD;
		  C_REG_AWVALID = 1'b1;
		end
		`OPCODE_S: begin
		  C_WB_CODE = `WB_CODE_STORE;
		end
		`OPCODE_J_JAL: begin
		  C_WB_CODE = `WB_CODE_JAL;
		  C_REG_AWVALID = 1'b1;
		end

		`OPCODE_I_JALR: begin
		  C_WB_CODE = `WB_CODE_JALR;
		  C_REG_AWVALID = 1'b1;
		  // FLAG TO INDICATE RS1+IMM -> PC instead of IMM += PC
		end
		`OPCODE_U_LUI: begin
		  C_WB_CODE = `WB_CODE_LUI;
		  C_REG_AWVALID = 1'b1;
		  // Make sure the imm is written here
		end
		`OPCODE_U_AUIPC: begin
		  C_WB_CODE = `WB_CODE_AUIPC;
		  C_REG_AWVALID = 1'b1;
		  // Make sure the imm + PC is written here
		end
		default: ;
	  endcase
	end
  endcase
end

reg [3:0] state_machine;

always @(posedge CLK) begin
  if (!NRST) state_machine <= S_IFETCH;
  else state_machine <= next_state;
end

endmodule
