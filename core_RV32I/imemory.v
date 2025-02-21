`timescale 1ns/10ps

module imemory #(parameter mem_content_path = "tests/my.hex") (
    input clkin,
    // read
    input [31:0] rd_addr_in,
    output [31:0] rd_data_out
);

reg [31:0] RAM [255:0];

assign rd_data_out = RAM[rd_addr_in];

endmodule
