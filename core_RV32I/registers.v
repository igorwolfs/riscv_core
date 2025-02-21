`timescale 1ns/10ps

/*
- Allow reading and writing from registers
- Allow resetting registers on nrst=low
*/

module registers (
    input clkin, nrst_in,
    input wr_en,
    input [31:0] wr_data_in,
    input [4:0] wr_idx_in,
    input [4:0] rd_idx1_in,
    input [4:0] rd_idx2_in,
    output [31:0] rd_data1_out,
    output [31:0] rd_data2_out
);

reg [31:0] regs [31:0];
integer i;
always @(posedge clkin)
begin
    if (~nrst_in)
        for (i=0; i<32; i=i+1)  regs[i] <= 32'b0;
    else if (wr_en)
        regs[wr_idx_in] <= wr_data_in;
    else;
end
assign rd_data1_out = regs[rd_idx1_in];
assign rd_data2_out = regs[rd_idx2_in];

endmodule
