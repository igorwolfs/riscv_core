`timescale 1ns/10ps

// 1 MB: 0b1111_11111111_11111111 = 20 bits = 0xFFFFF

module top_tb ();

//! >>> TEST
reg NRST = 1, CLK = 0;

initial
begin
    NRST = 0;
    #15;
    NRST = 1;
    #100;
end

always #5 CLK = ~CLK; //255  65536*8
wire UART_TX_DSER, UART_RX_DSER;
assign UART_RX_DSER = UART_TX_DSER;
    riscv_mcu #(.INT_MEM_SIZE(128), .AXI_AWIDTH(32), .AXI_DWIDTH(32)) riscv_mcu_inst (
    .CLK(CLK),
    .NRST(NRST),
    .UART_TX_DSER(UART_TX_DSER),
    .UART_RX_DSER(UART_RX_DSER)
   );

//! <<< TEST
endmodule

/*

module top_tb #(parameter INTERNAL_MEMORY=1'b0, parameter MEMSIZE=(65536*8),//4*1024*1024 // 16 MB of memory
    parameter AXI_AWIDTH=32, parameter AXI_DWIDTH=32); // 4 MB (in bytes)
    // Check addressing bits required (equal to 2 + the memory size (2 due to array size being 32-bits each))
    parameter MEMMAX_ADDR_IDX = $clog2(MEMSIZE)+1;
    reg sysclk = 0, NRST = 1;
    integer sig_file;

    // **** External memory interface (when INTERNAL_MEMORY = 0) ****
    // *** FILE HANDLING
    reg [31:0] ext_memory [0:MEMSIZE-1]; // 16 MB of memory
    integer i;
    string mem_path, sig_path, siglog_path;
    initial begin
        if (!$value$plusargs("MEM_PATH=%s", mem_path)) mem_path = "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscof_work/rv32i_m/I/src/sll-01.S/dut/my.hex";
        if (!$value$plusargs("SIG_PATH=%s", sig_path)) sig_path = "/home/iwolfs/Work/Projects/fpga_project/risc5/riscv-riscof/riscof_work/rv32i_m/I/src/sll-01.S/dut/my.sig";
        // Load memory file
        $readmemh(mem_path, ext_memory);

        // Open signature file
        sig_file = $fopen(sig_path, "w");
        if (sig_file == 0) begin
            $display("Error: Could not open sisgnature file %s", sig_path);

            $finish;
        end
    end

    // *** MEMORY INTERFACING
    // Instruction / Data Memory Test Interface
    wire [31:0] imem_rdata, dmem_rdata, dmem_wdata, dmem_wdata_read;
    wire dmem_wvalid;
    // Memory read logic  (Making sure any special address space is ignored)
    assign dmem_wdata_read = ext_memory[host_axi_awaddr[MEMMAX_ADDR_IDX:2]];
    assign dmem_rdata = ext_memory[host_axi_araddr[MEMMAX_ADDR_IDX:2]];
    assign imem_rdata = ext_memory[imem_axi_araddr[MEMMAX_ADDR_IDX:2]];  // Instruction fetch

    //! NOTE: Make sure to add 2 bits here to the host_axi_awaddr so it fits the 32-bit address bus
    //! Probably the best way is to declare host_axi_awaddr_extended with 2 0-bits to the right and n-32-AXI_AWIDTH bits to the left
    // WRONG: apparently the AXI bus needs to be 32-bits everywhere since it needs to be able to pass addresses like 0xF0000000.

    always @(posedge sysclk)
    begin
        if (!NRST);
        else
        begin
            if (dmem_wvalid)
            begin
                if (host_axi_awaddr == 32'hF0000004)
                begin
                    // Write to file
                    $fdisplay(sig_file, "%h", dmem_wdata);
                end
                else if ((dmem_wdata == 32'hCAFECAFE) && (host_axi_awaddr == 32'hF0000000))
                begin
                    $display("Finishing simulation.");
                    $fclose(sig_file);
                    $finish;
                end
                else
                    ext_memory[host_axi_awaddr[MEMMAX_ADDR_IDX:2]] <= dmem_wdata;
            end
            else;
         end
    end

    // ***** CLOCK *****
    always #5 sysclk = ~sysclk;

    // **** CORE ****
    core_top #(
        .AXI_AWIDTH(AXI_AWIDTH),
        .AXI_DWIDTH(AXI_DWIDTH)
    ) core_inst (
        // SYSTEM
        .CLK(sysclk),
        .NRST(NRST),

        // *** DATA MEMORY / PERIPHERAL INTERFACE ***
        .HOST_AXI_AWADDR(host_axi_awaddr), .HOST_AXI_AWVALID(host_axi_awvalid),
        .HOST_AXI_AWREADY(host_axi_awready), .HOST_AXI_WDATA(host_axi_wdata),
        .HOST_AXI_WSTRB(host_axi_wstrb), .HOST_AXI_WVALID(host_axi_wvalid),
        .HOST_AXI_WREADY(host_axi_wready), .HOST_AXI_BRESP(host_axi_bresp),
        .HOST_AXI_BVALID(host_axi_bvalid), .HOST_AXI_BREADY(host_axi_bready),
        .HOST_AXI_ARADDR(host_axi_araddr), .HOST_AXI_ARVALID(host_axi_arvalid),
        .HOST_AXI_ARREADY(host_axi_arready), .HOST_AXI_RDATA(host_axi_rdata),
        .HOST_AXI_RRESP(host_axi_rresp), .HOST_AXI_RVALID(host_axi_rvalid),
        .HOST_AXI_RREADY(host_axi_rready),

        // *** INSTRUCTION MEMORY INTERFACE ***
        .IMEM_AXI_ARADDR(imem_axi_araddr), .IMEM_AXI_ARVALID(imem_axi_arvalid),
        .IMEM_AXI_ARREADY(imem_axi_arready), .IMEM_AXI_RDATA(imem_axi_rdata),
        .IMEM_AXI_RRESP(imem_axi_rresp), .IMEM_AXI_RVALID(imem_axi_rvalid),
        .IMEM_AXI_RREADY(imem_axi_rready)
    );


    initial
    begin
        NRST = 0;
        #15;
        NRST = 1;
        #100;
    end



    // *** DATA MEMORY / PERIPHERAL INTERFACE ***
    // Write Address Bus
    wire [AXI_AWIDTH-1:0] host_axi_awaddr;
    wire host_axi_awvalid, host_axi_awready;
    // Read Address Bus
    wire [AXI_DWIDTH-1:0] host_axi_wdata;
    wire [3:0] host_axi_wstrb;
    wire host_axi_wvalid, host_axi_wready;
    // Response Bus
    wire [1:0] host_axi_bresp;
    wire host_axi_bvalid, host_axi_bready;
    // Address Read Bus
    wire [AXI_AWIDTH-1:0] host_axi_araddr;
    wire host_axi_arvalid, host_axi_arready;
    // Data Read Bus
    wire [AXI_DWIDTH-1:0] host_axi_rdata;
    wire [1:0] host_axi_rresp;
    wire host_axi_rvalid, host_axi_rready;
    
    // *** INSTRUCTION MEMORY INTERFACE ***
    // Read Address Bus
    wire [AXI_AWIDTH-1:0] imem_axi_araddr;
    wire imem_axi_arvalid, imem_axi_arready;
    // Read Data Bus
    wire [AXI_DWIDTH-1:0] imem_axi_rdata;
    wire [1:0] imem_axi_rresp;
    wire imem_axi_rvalid, imem_axi_rready;

    // *** DATA MEMORY READ / WRITE AXI LOGIC
    dmemory #(.RISCOF_TEST_MODE(1), .INT_DMEM_SIZE(1),
    .AXI_AWIDTH(AXI_AWIDTH), .AXI_DWIDTH(AXI_DWIDTH)) dmem_inst (
        .AXI_ACLK(sysclk), .AXI_ARESETN(NRST),
        
        .AXI_AWADDR(host_axi_awaddr), .AXI_AWVALID(host_axi_awvalid),
        .AXI_AWREADY(host_axi_awready), .AXI_WDATA(host_axi_wdata),
        .AXI_WSTRB(host_axi_wstrb), .AXI_WVALID(host_axi_wvalid),
        .AXI_WREADY(host_axi_wready), .AXI_BRESP(host_axi_bresp),
        .AXI_BVALID(host_axi_bvalid), .AXI_BREADY(host_axi_bready),
        
        .AXI_ARADDR(host_axi_araddr), .AXI_ARVALID(host_axi_arvalid),
        .AXI_ARREADY(host_axi_arready), .AXI_RDATA(host_axi_rdata),
        .AXI_RRESP(host_axi_rresp), .AXI_RVALID(host_axi_rvalid),
        .AXI_RREADY(host_axi_rready),

        .DMEM_RDATA(dmem_rdata), .DMEM_WDATA(dmem_wdata), .DMEM_WDATA_READ(dmem_wdata_read),
        .DMEM_WVALID(dmem_wvalid)
    );


    // *** INSTRUCTION MEMORY READ / WRITE AXI LOGIC
    imemory #(
        .RISCOF_TEST_MODE(1),
        .IMEM_SIZE(1),
        .AXI_AWIDTH(AXI_AWIDTH),
        .AXI_DWIDTH(AXI_DWIDTH)
    ) imem_inst (
        .AXI_ACLK(sysclk), .AXI_ARESETN(NRST),

        .AXI_ARADDR(imem_axi_araddr), .AXI_ARVALID(imem_axi_arvalid),
        .AXI_ARREADY(imem_axi_arready), .AXI_RDATA(imem_axi_rdata),
        .AXI_RRESP(imem_axi_rresp), .AXI_RVALID(imem_axi_rvalid),
        .AXI_RREADY(imem_axi_rready),
        .IMEM_RDATA(imem_rdata)
    );
    
endmodule
*/

/**
Could I integrate the dmemory and imemory module in here?
- Create an optional AXI-bus adapter inside dmemory for test cases, with rdata, wdata, wen signals
    - keep the tb logic the way it was

//! NOTE: AXI can ONLY read / write a full data-bus (so 32-bits), it uses the strobe to select individual bytes.
*/