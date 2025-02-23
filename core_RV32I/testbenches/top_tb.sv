`timescale 1ns/10ps

// 1 MB: 0b1111_11111111_11111111 = 20 bits = 0xFFFFF

module top_tb #(parameter INTERNAL_MEMORY=1'b0, parameter MEMSIZE=4*1024*1024) (); // 4 MB (in bytes)
    reg sysclk = 0, nrst_in = 1;
    integer sig_file;

    // **** External memory interface (when INTERNAL_MEMORY = 0) ****
    // *** FILE HANDLING
    reg [31:0] ext_memory [0:MEMSIZE-1]; // 16 MB of memory
    string mem_path, sig_path;
    initial begin
        if (!$value$plusargs("MEM_PATH=%s", mem_path)) mem_path = "tests/my.hex";
        if (!$value$plusargs("SIG_PATH=%s", sig_path)) sig_path = "tests/my.sig";

        // Load memory file
        $readmemh(mem_path, ext_memory);

        // Open signature file
        sig_file = $fopen(sig_path, "w");
        if (sig_file == 0) begin
            $display("Error: Could not open signature file %s", sig_path);
            $finish;
        end
    end

    // *** MEMORY INTERFACING
    // Data Memory Interface
    wire [31:0] dmem_rd_addr, dmem_rd_data, dmem_wr_addr, dmem_wr_data;
    wire dmem_wr_en;

    // Instruction Memory Interface
    wire [31:0] imem_addr, imem_data;


    // Memory read logic  (Making sure any special address space is ignored)
    assign dmem_rd_data = ext_memory[dmem_rd_addr[23:2]];
    assign imem_data = ext_memory[imem_addr[23:2]];  // Instruction fetch


    // Memory write logic
    always @(posedge sysclk) begin
        if (dmem_wr_en)
            begin
            if (dmem_wr_addr[31:28] == 4'h0) begin
                // Normal memory write
                ext_memory[dmem_wr_addr[23:2]] <= dmem_wr_data;
            end
            else if (dmem_wr_addr == 32'hF0000004) // Address for signature write
                begin
                ext_memory[dmem_wr_addr[23:2]] <= dmem_wr_data;
                // Example: Write to signature file on memory writes
                $fdisplay(sig_file, "Write to addr %h: data %h\r\n", dmem_wr_addr, dmem_wr_data);
                end
            else if ((dmem_wr_addr == 32'hCAFECAFE) && (dmem_wr_data == 32'hF0000000))
                begin
                $display("Finishing simulation.");
                $fclose(sig_file);
                $finish;
                end
            else;
            end
        else;
    end

    // **** CORE ****
    core #(.INTERNAL_MEMORY(INTERNAL_MEMORY)) core_t (.sysclk(sysclk), .nrst_in(nrst_in),
    // Data
    .dmem_rd_addr(dmem_rd_addr), .dmem_rd_data(dmem_rd_data), .dmem_wr_addr(dmem_wr_addr),
    .dmem_wr_data(dmem_wr_data), .dmem_wr_en(dmem_wr_en),
    // Instructions
    .imem_addr(imem_addr), .imem_data(imem_data));

    always #5 sysclk = ~sysclk;
    initial
    begin
        nrst_in = 0;
        #10;
        nrst_in = 1;
    end
endmodule
