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

// Take the relevant instruction

// Perform it with the alu_arg1_in and alu_arg2_in
// Set the output to alu_arg_out

endmodule
