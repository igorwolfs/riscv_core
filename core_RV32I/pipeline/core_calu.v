module core_calu (
	input [31:0] INSTRUCTION,
)


endmodule

/**

ARGUMENTS
- ENABLE signal (future, in case of pipelining for the TOP CTRL block to enable)
- opcode_in
- arguments in
- funct3, funct7 in
- Immediate in
- output: register read signals
- output: register write signals (result from alu)
DECODED FROM INSTRUCTIONS
- output: ALU arguments (arg1, arg2, immediate)
- output: ALU operation
*/