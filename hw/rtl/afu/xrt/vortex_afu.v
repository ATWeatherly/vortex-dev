`include "vortex_afu.vh"

module vortex_afu #(
	parameter C_S_AXI_CTRL_ADDR_WIDTH = 8,
	parameter C_S_AXI_CTRL_DATA_WIDTH = 32,
	parameter C_M_AXI_MEM_ID_WIDTH 	  = `M_AXI_MEM_ID_WIDTH,
	parameter C_M_AXI_MEM_ADDR_WIDTH  = 64,
	parameter C_M_AXI_MEM_DATA_WIDTH  = `VX_MEM_DATA_WIDTH    
) (
	// System signals
	input wire 									ap_clk,
	input wire 									ap_rst_n,
	
	// AXI4 master interface
	`REPEAT (`M_AXI_MEM_NUM_BANKS, GEN_AXI_MEM, REPEAT_COMMA),

    // AXI4-Lite slave interface
    input  wire                                 s_axi_ctrl_awvalid,
    output wire                                 s_axi_ctrl_awready,
    input  wire [C_S_AXI_CTRL_ADDR_WIDTH-1:0]   s_axi_ctrl_awaddr,
    input  wire                                 s_axi_ctrl_wvalid,
    output wire                                 s_axi_ctrl_wready,
    input  wire [C_S_AXI_CTRL_DATA_WIDTH-1:0]   s_axi_ctrl_wdata,
    input  wire [C_S_AXI_CTRL_DATA_WIDTH/8-1:0] s_axi_ctrl_wstrb,
    input  wire                                 s_axi_ctrl_arvalid,
    output wire                                 s_axi_ctrl_arready,
    input  wire [C_S_AXI_CTRL_ADDR_WIDTH-1:0]   s_axi_ctrl_araddr,
    output wire                                 s_axi_ctrl_rvalid,
    input  wire                                 s_axi_ctrl_rready,
    output wire [C_S_AXI_CTRL_DATA_WIDTH-1:0]   s_axi_ctrl_rdata,
    output wire [1:0]                           s_axi_ctrl_rresp,
    output wire                                 s_axi_ctrl_bvalid,
    input  wire                                 s_axi_ctrl_bready,
    output wire [1:0]                           s_axi_ctrl_bresp,
    
    output wire                                 interrupt 
);

	VX_afu_wrap #(
		.C_S_AXI_CTRL_ADDR_WIDTH (C_S_AXI_CTRL_ADDR_WIDTH),
		.C_S_AXI_CTRL_DATA_WIDTH (C_S_AXI_CTRL_DATA_WIDTH),
		.C_M_AXI_MEM_ID_WIDTH    (C_M_AXI_MEM_ID_WIDTH),
		.C_M_AXI_MEM_ADDR_WIDTH  (C_M_AXI_MEM_ADDR_WIDTH),
		.C_M_AXI_MEM_DATA_WIDTH  (C_M_AXI_MEM_DATA_WIDTH)
	) afu_wrap (
		.ap_clk             (ap_clk),
		.ap_rst_n           (ap_rst_n),

		`REPEAT (`M_AXI_MEM_NUM_BANKS, AXI_MEM_ARGS, REPEAT_COMMA),
		
		.s_axi_ctrl_awvalid (s_axi_ctrl_awvalid),
		.s_axi_ctrl_awready (s_axi_ctrl_awready),
		.s_axi_ctrl_awaddr  (s_axi_ctrl_awaddr),		
		.s_axi_ctrl_wvalid  (s_axi_ctrl_wvalid),
		.s_axi_ctrl_wready  (s_axi_ctrl_wready),
		.s_axi_ctrl_wdata   (s_axi_ctrl_wdata),
		.s_axi_ctrl_wstrb   (s_axi_ctrl_wstrb),
		.s_axi_ctrl_arvalid (s_axi_ctrl_arvalid),
		.s_axi_ctrl_arready (s_axi_ctrl_arready),
		.s_axi_ctrl_araddr  (s_axi_ctrl_araddr),
		.s_axi_ctrl_rvalid  (s_axi_ctrl_rvalid),
		.s_axi_ctrl_rready  (s_axi_ctrl_rready),
		.s_axi_ctrl_rdata   (s_axi_ctrl_rdata),
		.s_axi_ctrl_rresp   (s_axi_ctrl_rresp),
		.s_axi_ctrl_bvalid  (s_axi_ctrl_bvalid),
		.s_axi_ctrl_bready  (s_axi_ctrl_bready),
		.s_axi_ctrl_bresp   (s_axi_ctrl_bresp),

		.interrupt          (interrupt)
	);
	
endmodule
