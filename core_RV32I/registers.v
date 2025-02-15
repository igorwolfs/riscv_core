`timescale 1ns/10ps

/*
- Allow reading and writing from registers
- Allow resetting registers on nrst=low
*/

module registers (
    input clkin, nrst_in,
    input wr_en,
    input [32:0] wr_data_in,
    input [4:0] wr_idx_in,
    input [4:0] rd_idx1_in,
    input [4:0] rd_idx2_in,
    output [32:0] rd_data1_out,
    output [32:0] rd_data2_out
);

reg [31:0] regs;
always @(posedge clkin)
begin
    if (~nrst_in)
        regs <= 32'b0;
    else if (wr_en)
        regs[wr_idx_in] <= wr_data_in;
    else;
end
assign rd_data_1_out = regs[rd_idx_1_in];
assign rd_data_2_out = regs[rd_idx_2_in];

endmodule
