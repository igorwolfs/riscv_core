`timescale 1ns/10ps

/*
- Allow reading and writing from registers
- Allow resetting registers on nrst=low
*/

module core_registers (
    input CLK, NRST,
    input AWVALID,
    input [31:0] WDATA,
    input [4:0] AWADDR,
    input [4:0] ARADDR1,
    input [4:0] ARADDR2,
    output [31:0] RDATA1,
    output [31:0] RDATA2
);

reg [31:0] regs [31:0];
integer i;
always @(posedge CLK)
begin
    if (~NRST)
    begin
        for (i=0; i<32; i=i+1)  regs[i] <= 32'b0;
    end
    else if ((AWVALID) && (AWADDR != 5'b0))
        regs[AWADDR] <= WDATA;
    else;
end

assign RDATA1 = regs[ARADDR1];
assign RDATA2 = regs[ARADDR2];

endmodule
