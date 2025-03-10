
`define AXI_MASTER_PORTS(PREFIX, AW, DW)                                        \
    input  wire [AW-1:0]     PREFIX``_AWADDR,                                   \
    input  wire [2:0]        PREFIX``_AWPROT,                                   \
    input  wire              PREFIX``_AWVALID,                                  \
    output wire              PREFIX``_AWREADY,                                  \
                                                                              \
    input  wire [DW-1:0]     PREFIX``_WDATA,                                    \
    input  wire [3:0] PREFIX``_WSTRB,                                    \
    input  wire              PREFIX``_WVALID,                                   \
    output wire              PREFIX``_WREADY,                                   \
                                                                              \
    output wire [1:0]        PREFIX``_BRESP,                                    \
    output wire              PREFIX``_BVALID,                                   \
    input  wire              PREFIX``_BREADY,                                   \
                                                                              \
    input  wire [AW-1:0]     PREFIX``_ARADDR,                                   \
    input  wire [2:0]        PREFIX``_ARPROT,                                   \
    input  wire              PREFIX``_ARVALID,                                  \
    output wire              PREFIX``_ARREADY,                                  \
                                                                              \
    output wire [DW-1:0]     PREFIX``_RDATA,                                    \
    output wire [1:0]        PREFIX``_RRESP,                                    \
    output wire              PREFIX``_RVALID,                                   \
    input  wire              PREFIX``_RREADY


`define AXI_SLAVE_PORTS(SLAVE_NUM, AW, DW)                            \
    output wire [AW-1:0] S``SLAVE_NUM``_AWADDR,                               \
    output wire [2:0]            S``SLAVE_NUM``_AWPROT,                               \
    output wire                  S``SLAVE_NUM``_AWVALID,                              \
    input  wire                  S``SLAVE_NUM``_AWREADY,                              \
                                                                                    \
    output wire [DW-1:0] S``SLAVE_NUM``_WDATA,                                \
    output wire [3:0] 				S``SLAVE_NUM``_WSTRB,                            \
    output wire                     S``SLAVE_NUM``_WVALID,                            \
    input  wire                     S``SLAVE_NUM``_WREADY,                            \
                                                                                    \
    input  wire [1:0]             S``SLAVE_NUM``_BRESP,                               \
    input  wire                   S``SLAVE_NUM``_BVALID,                              \
    output wire                   S``SLAVE_NUM``_BREADY,                              \
                                                                                    \
    output wire [AW-1:0]  S``SLAVE_NUM``_ARADDR,                              \
    output wire [2:0]             S``SLAVE_NUM``_ARPROT,                              \
    output wire                   S``SLAVE_NUM``_ARVALID,                             \
    input  wire                   S``SLAVE_NUM``_ARREADY,                             \
                                                                                    \
    input  wire [DW-1:0]  S``SLAVE_NUM``_RDATA,                               \
    input  wire [1:0]             S``SLAVE_NUM``_RRESP,                               \
    input  wire                   S``SLAVE_NUM``_RVALID,                              \
    output wire                   S``SLAVE_NUM``_RREADY


//=====================================
//  AXI INTERCONNECT MACROS
//=====================================
// SLAVE ASSIGNS

`define AXI_SLAVE_GENERATE_BLOCK(SLAVE_NUM, AXI_AWIDTH, AXI_DWIDTH)              \
generate                                                                       \
if (S``SLAVE_NUM``_EN) begin: GEN_S``SLAVE_NUM                                  \
    // ------------------------------                                          \
    // Write Address/Data -> S<SLAVE_NUM>                                     \
    // ------------------------------                                          \
    assign S``SLAVE_NUM``_AWVALID = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_awvalid : 1'b0; \
    assign S``SLAVE_NUM``_AWADDR  = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_awaddr  : {AXI_AWIDTH{1'b0}}; \
    assign S``SLAVE_NUM``_AWPROT  = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_awprot  : 3'b0;  \
    assign S``SLAVE_NUM``_WVALID  = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_wvalid  : 1'b0;  \
    assign S``SLAVE_NUM``_WDATA   = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_wdata   : {AXI_DWIDTH{1'b0}};  \
    assign S``SLAVE_NUM``_WSTRB   = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_wstrb   : {4'b0};  \
    assign S``SLAVE_NUM``_BREADY  = (SM_mux_swrite == S``SLAVE_NUM``_MUX) ? m_bready  : 1'b0;  \
    assign S``SLAVE_NUM``_ARVALID = (SM_mux_sread == S``SLAVE_NUM``_MUX) ? m_arvalid : 1'b0;   \
    assign S``SLAVE_NUM``_ARADDR  = (SM_mux_sread == S``SLAVE_NUM``_MUX) ? m_araddr  : {AXI_AWIDTH{1'b0}};  \
    assign S``SLAVE_NUM``_ARPROT  = (SM_mux_sread == S``SLAVE_NUM``_MUX) ? m_arprot  : 3'b0;   \
    assign S``SLAVE_NUM``_RREADY  = (SM_mux_sread == S``SLAVE_NUM``_MUX) ? m_rready  : 1'b0;   \
                                                                                \
end else begin: GEN_S``SLAVE_NUM``_DISABLED                                   \
    // ------------------------------                                          \
    // Tie off all signals to/from S<SLAVE_NUM>                               \
    // ------------------------------                                          \
    assign S``SLAVE_NUM``_AWVALID = 1'b0;                                     \
    assign S``SLAVE_NUM``_AWADDR  = {AXI_AWIDTH{1'b0}};                                    \
    assign S``SLAVE_NUM``_AWPROT  = 3'b0;                                     \
                                                                                \
    assign S``SLAVE_NUM``_WVALID  = 1'b0;                                     \
    assign S``SLAVE_NUM``_WDATA   = {AXI_DWIDTH{1'b0}};                                    \
    assign S``SLAVE_NUM``_WSTRB   = {4'b0};                                     \
    assign S``SLAVE_NUM``_BREADY  = 1'b0;                                     \
                                                                                \
    assign S``SLAVE_NUM``_ARVALID = 1'b0;                                     \
    assign S``SLAVE_NUM``_ARADDR  = {AXI_AWIDTH{1'b0}};                                    \
    assign S``SLAVE_NUM``_ARPROT  = 3'b0;                                     \
    assign S``SLAVE_NUM``_RREADY  = 1'b0;                                     \
end                                                                          \
endgenerate


// MASTER ASSIGNS

`define AXI_MASTER_GENERATE_BLOCK(PREFIX, AXI_DWIDTH)             \
    assign PREFIX``_AWREADY= (SM_mux_mwrite == PREFIX``_MUX) ? m_awready : 1'b0; \
    assign PREFIX``_WREADY = (SM_mux_mwrite == PREFIX``_MUX) ? m_wready  : 1'b0; \
    assign PREFIX``_BRESP  = (SM_mux_mwrite == PREFIX``_MUX) ? m_bresp   : 2'b00; \
    assign PREFIX``_BVALID = (SM_mux_mwrite == PREFIX``_MUX) ? m_bvalid  : 1'b0; \
                                                                        \
    assign PREFIX``_ARREADY= (SM_mux_mread == PREFIX``_MUX) ? m_arready : 1'b0; \
    assign PREFIX``_RDATA  = (SM_mux_mread == PREFIX``_MUX) ? m_rdata   : {AXI_DWIDTH{1'b0}}; \
    assign PREFIX``_RRESP  = (SM_mux_mread == PREFIX``_MUX) ? m_rresp   : 2'b00; \
    assign PREFIX``_RVALID = (SM_mux_mread == PREFIX``_MUX) ? m_rvalid  : 1'b0;


`define IN_RANGE_EN(SLAVE_NUM, ADDR_SIG) \
    ( S``SLAVE_NUM``_EN && ((ADDR_SIG) >= ADDR_S``SLAVE_NUM``_START) && ((ADDR_SIG) <= ADDR_S``SLAVE_NUM``_END) )


`define AXI_PORTMAP(PREFIX_UC, PREFIX_LC)                         \
        .PREFIX_UC``AWADDR  ( PREFIX_LC``awaddr  ),                   \
        .PREFIX_UC``AWVALID ( PREFIX_LC``awvalid ),                   \
        .PREFIX_UC``AWREADY ( PREFIX_LC``awready ),                   \
                                                                                        \
        .PREFIX_UC``WDATA   ( PREFIX_LC``wdata   ),                   \
        .PREFIX_UC``WSTRB   ( PREFIX_LC``wstrb   ),                   \
        .PREFIX_UC``WVALID  ( PREFIX_LC``wvalid  ),                   \
        .PREFIX_UC``WREADY  ( PREFIX_LC``wready  ),                   \
                                                                                        \
        .PREFIX_UC``BRESP   ( PREFIX_LC``bresp   ),                   \
        .PREFIX_UC``BVALID  ( PREFIX_LC``bvalid  ),                   \
        .PREFIX_UC``BREADY  ( PREFIX_LC``bready  ),                   \
                                                                                        \
        .PREFIX_UC``ARADDR  ( PREFIX_LC``araddr  ),                   \
        .PREFIX_UC``ARVALID ( PREFIX_LC``arvalid ),                   \
        .PREFIX_UC``ARREADY ( PREFIX_LC``arready ),                   \
                                                                                        \
        .PREFIX_UC``RDATA   ( PREFIX_LC``rdata   ),                   \
        .PREFIX_UC``RRESP   ( PREFIX_LC``rresp   ),                   \
        .PREFIX_UC``RVALID  ( PREFIX_LC``rvalid  ),                   \
        .PREFIX_UC``RREADY  ( PREFIX_LC``rready  )

`define AXI_WIRES(PREFIX, AW, DW)                                         \
        /* Write Address Channel */                                           \
        wire [AW-1:0] PREFIX``awaddr;                                    \
        wire          PREFIX``awvalid, PREFIX``awready;             \
                                                                              \
        /* Write Data Channel */                                              \
        wire [DW-1:0]    PREFIX``wdata;                                  \
        wire [(DW/8)-1:0]PREFIX``wstrb; /* typically 4 bits if DW=32 */  \
        wire             PREFIX``wvalid, PREFIX``wready;            \
                                                                              \
        /* Write Response Channel */                                          \
        wire [1:0] PREFIX``bresp;                                        \
        wire       PREFIX``bvalid, PREFIX``bready;                  \
                                                                              \
        /* Read Address Channel */                                            \
        wire [AW-1:0] PREFIX``araddr;                                    \
        wire          PREFIX``arvalid, PREFIX``arready;             \
                                                                              \
        /* Read Data Channel */                                               \
        wire [DW-1:0] PREFIX``rdata;                                     \
        wire [1:0]    PREFIX``rresp;                                     \
        wire          PREFIX``rvalid, PREFIX``rready
    