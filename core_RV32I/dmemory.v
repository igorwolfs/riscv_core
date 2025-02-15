`timescale 1ns/10ps

module dmemory
(
    input clkin,
    input nrst_in,
    // WRITE
    input wr_en_in,
    input [31:0] wr_idx_in,
    input [31:0] wr_data_in,
    // READ
    input [31:0] rd_idx_in,
    output [31:0] rd_data_out
);

reg ROM[255:0];
always @(posedge clkin)
begin
    if (wr_en_in)
    begin
        ROM[wr_idx_in] <= wr_data_in;
    end
end

assign rd_data_out = ROM[rd_idx_in];
endmodule
