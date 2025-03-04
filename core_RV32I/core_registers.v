`timescale 1ns/10ps

/*
- Allow reading and writing from registers
- Allow resetting registers on nrst=low
*/

module core_registers (
    input CLK, NRST,
    input AWVALID,
    input [31:0] WDATA,
    input [4:0] AWID,
    input [4:0] ARID1,
    input [4:0] ARID2,
    output [31:0] RDATA1,
    output [31:0] RDATA2
);

reg [31:0] regs [31:0];
integer i;
always @(posedge CLK)
begin
    if (~NRST)
        for (i=0; i<32; i=i+1)  regs[i] <= 32'b0;
    else if ((AWVALID) && (AWID != 5'b0))
        regs[AWID] <= WDATA;
    else;
end
assign RDATA1 = regs[ARID1];
assign RDATA2 = regs[ARID2];

endmodule
