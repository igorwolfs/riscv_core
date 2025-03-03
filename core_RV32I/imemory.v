`timescale 1ns/10ps

module imemory #(parameter IMEM_SIZE = 1024) (
    input CLK,
    // read
    input [31:0] ARADDR,
    output [31:0] RDATA
);

reg [31:0] RAM [IMEM_SIZE-1:0];

assign RDATA = RAM[ARADDR];

endmodule
