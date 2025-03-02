`timescale 1ns/10ps

module imemory #(parameter mem_content_path = "tests/my.hex") (
    input CLK,
    // read
    input [31:0] ARADDR,
    output [31:0] RDATA
);

reg [31:0] RAM [255:0];

assign RDATA = RAM[ARADDR];

endmodule
