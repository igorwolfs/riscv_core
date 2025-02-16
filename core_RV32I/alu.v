`timescale 1ns/10ps

/**
An ALU "normally" doesn't require any 
- Registers
- reset signals
Since it is supposed to be purely combinatorial.
*/

module alu(
    input alu_cid_in,
    input alu_arg1_in,
    input alu_arg2_in,
    output alu_arg_out
);

// Switch - case with the CID
// Perform the relevant alu-logic in the case statement, and register the output

endmodule
