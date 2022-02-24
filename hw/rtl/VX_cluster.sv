`include "VX_define.vh"

module VX_cluster #(
    parameter CLUSTER_ID = 0
) ( 
    `SCOPE_IO_VX_cluster

    // Clock
    input  wire                             clk,
    input  wire                             reset,

`ifdef EXT_TEX_ENABLE
    VX_tex_csr_if.slave                     tex_csr_if,
`endif
`ifdef EXT_RASTER_ENABLE
    VX_raster_csr_if.slave                  raster_csr_if,
`endif
`ifdef EXT_ROP_ENABLE
    VX_rop_csr_if.slave                     rop_csr_if,
`endif


    // Memory request
    output wire                             mem_req_valid,
    output wire                             mem_req_rw,    
    output wire [`L2_MEM_BYTEEN_WIDTH-1:0]  mem_req_byteen,    
    output wire [`L2_MEM_ADDR_WIDTH-1:0]    mem_req_addr,
    output wire [`L2_MEM_DATA_WIDTH-1:0]    mem_req_data,
    output wire [`L2_MEM_TAG_WIDTH-1:0]     mem_req_tag,
    input  wire                             mem_req_ready,

    // Memory response    
    input wire                              mem_rsp_valid,        
    input wire [`L2_MEM_DATA_WIDTH-1:0]     mem_rsp_data,
    input wire [`L2_MEM_TAG_WIDTH-1:0]      mem_rsp_tag,
    output wire                             mem_rsp_ready,

    // Status
    output wire                             busy
); 
    `STATIC_ASSERT((`L2_ENABLE == 0 || `NUM_CORES > 1), ("invalid parameter"))

`ifdef EXT_RASTER_ENABLE

    VX_raster_req_if    raster_req_if();
    VX_raster_rsp_if    raster_rsp_if();
    VX_perf_raster_if   perf_raster_if();
    VX_dcache_req_if    rcache_req_if();
    VX_dcache_rsp_if    rcache_rsp_if();

    assign raster_req_if.valid  = 0; // TODO: remove
    assign raster_req_if.uuid   = 0; // TODO: remove;
    assign raster_req_if.wid    = 0; // TODO: remove;
    assign raster_req_if.tmask  = 0; // TODO: remove;
    assign raster_req_if.PC     = 0; // TODO: remove;
    assign raster_req_if.rd     = 0; // TODO: remove;
    assign raster_req_if.wb     = 0; // TODO: remove;
    `UNUSED_VAR (raster_req_if.ready) // TODO: remove

    // TODO: remove
    `UNUSED_VAR (raster_rsp_if.valid)
    `UNUSED_VAR (raster_rsp_if.uuid)
    `UNUSED_VAR (raster_rsp_if.wid)
    `UNUSED_VAR (raster_rsp_if.tmask)
    `UNUSED_VAR (raster_rsp_if.PC)
    `UNUSED_VAR (raster_rsp_if.rd)
    `UNUSED_VAR (raster_rsp_if.wb)
    `UNUSED_VAR (raster_rsp_if.rem)
    assign raster_rsp_if.ready = 0;

    // TODO: remove
    `UNUSED_VAR (perf_raster_if.mem_reads);
    `UNUSED_VAR (perf_raster_if.mem_latency);

    // TODO: remove
    `UNUSED_VAR (rcache_req_if.valid);
    `UNUSED_VAR (rcache_req_if.rw);
    `UNUSED_VAR (rcache_req_if.byteen);
    `UNUSED_VAR (rcache_req_if.addr);
    `UNUSED_VAR (rcache_req_if.data);     
    `UNUSED_VAR (rcache_req_if.tag);
    assign rcache_req_if.ready = 0;

    // TODO: remove
    assign rcache_rsp_if.valid = 0;
    assign rcache_rsp_if.tmask = 0;
    assign rcache_rsp_if.data = 0;     
    assign rcache_rsp_if.tag = 0;
    `UNUSED_VAR (rcache_rsp_if.ready);

    `RESET_RELAY (raster_reset);

    VX_raster_unit #(
        .NUM_SLICES (1)
    ) raster_unit (
        .clk           (clk),
        .reset         (raster_reset),
    `ifdef PERF_ENABLE
        .perf_raster_if(perf_raster_if),
    `endif
        .raster_req_if (raster_req_if),
        .raster_csr_if (raster_csr_if),
        .raster_rsp_if (raster_rsp_if),
        .cache_req_if  (rcache_req_if),
        .cache_rsp_if  (rcache_rsp_if)
    );

`endif

`ifdef EXT_ROP_ENABLE

    VX_rop_req_if       rop_req_if();
    VX_perf_rop_if      perf_rop_if(); 
    VX_dcache_req_if    ccache_req_if();
    VX_dcache_rsp_if    ccache_rsp_if();

    assign rop_req_if.valid  = 0; // TODO: remove
    assign rop_req_if.uuid   = 0; // TODO: remove
    assign rop_req_if.wid    = 0; // TODO: remove
    assign rop_req_if.tmask  = 0; // TODO: remove
    assign rop_req_if.PC     = 0; // TODO: remove
    assign rop_req_if.rd     = 0; // TODO: remove
    assign rop_req_if.wb     = 0; // TODO: remove
    assign rop_req_if.x      = 0; // TODO: remove
    assign rop_req_if.y      = 0; // TODO: remove
    assign rop_req_if.z      = 0; // TODO: remove
    assign rop_req_if.color  = 0; // TODO: remove
    `UNUSED_VAR (rop_req_if.ready) // TODO: remove

    // TODO: remove
    `UNUSED_VAR (perf_rop_if.mem_reads);
    `UNUSED_VAR (perf_rop_if.mem_writes);
    `UNUSED_VAR (perf_rop_if.mem_latency);

    // TODO: remove
    `UNUSED_VAR (ccache_req_if.valid);
    `UNUSED_VAR (ccache_req_if.rw);
    `UNUSED_VAR (ccache_req_if.byteen);
    `UNUSED_VAR (ccache_req_if.addr);
    `UNUSED_VAR (ccache_req_if.data);     
    `UNUSED_VAR (ccache_req_if.tag);
    assign ccache_req_if.ready = 0;

    // TODO: remove
    assign ccache_rsp_if.valid = 0;
    assign ccache_rsp_if.tmask = 0;
    assign ccache_rsp_if.data = 0;     
    assign ccache_rsp_if.tag = 0;
    `UNUSED_VAR (ccache_rsp_if.ready);

    `RESET_RELAY (rop_reset);

    VX_rop_unit #(
        .NUM_SLICES (`NUM_THREADS)
    ) rop_unit (
        .clk           (clk),
        .reset         (rop_reset),
    `ifdef PERF_ENABLE
        .perf_rop_if   (perf_rop_if),
    `endif
        .rop_req_if    (rop_req_if),
        .rop_csr_if    (rop_csr_if),
        .cache_req_if  (ccache_req_if),
        .cache_rsp_if  (ccache_rsp_if)
    );

`endif

    wire [`NUM_CORES-1:0]                       per_core_mem_req_valid;
    wire [`NUM_CORES-1:0]                       per_core_mem_req_rw;    
    wire [`NUM_CORES-1:0][`DCACHE_MEM_BYTEEN_WIDTH-1:0] per_core_mem_req_byteen;    
    wire [`NUM_CORES-1:0][`DCACHE_MEM_ADDR_WIDTH-1:0] per_core_mem_req_addr;
    wire [`NUM_CORES-1:0][`DCACHE_MEM_DATA_WIDTH-1:0] per_core_mem_req_data;
    wire [`NUM_CORES-1:0][`L1_MEM_TAG_WIDTH-1:0] per_core_mem_req_tag;
    wire [`NUM_CORES-1:0]                       per_core_mem_req_ready;

    wire [`NUM_CORES-1:0]                       per_core_mem_rsp_valid;            
    wire [`NUM_CORES-1:0][`DCACHE_MEM_DATA_WIDTH-1:0] per_core_mem_rsp_data;
    wire [`NUM_CORES-1:0][`L1_MEM_TAG_WIDTH-1:0] per_core_mem_rsp_tag;
    wire [`NUM_CORES-1:0]                       per_core_mem_rsp_ready;

    wire [`NUM_CORES-1:0]                       per_core_busy;

    for (genvar i = 0; i < `NUM_CORES; i++) begin

        `RESET_RELAY (core_reset);

        VX_core #(
            .CORE_ID(i + (CLUSTER_ID * `NUM_CORES))
        ) core (
            `SCOPE_BIND_VX_cluster_core(i)

            .clk            (clk),
            .reset          (core_reset),

        `ifdef EXT_TEX_ENABLE
            .tex_csr_if     (tex_csr_if),
        `endif

            .mem_req_valid  (per_core_mem_req_valid[i]),
            .mem_req_rw     (per_core_mem_req_rw   [i]),                
            .mem_req_byteen (per_core_mem_req_byteen[i]),                
            .mem_req_addr   (per_core_mem_req_addr [i]),
            .mem_req_data   (per_core_mem_req_data [i]),
            .mem_req_tag    (per_core_mem_req_tag  [i]),
            .mem_req_ready  (per_core_mem_req_ready[i]),
                     
            .mem_rsp_valid  (per_core_mem_rsp_valid[i]),                
            .mem_rsp_data   (per_core_mem_rsp_data [i]),
            .mem_rsp_tag    (per_core_mem_rsp_tag  [i]),
            .mem_rsp_ready  (per_core_mem_rsp_ready[i]),

            .busy           (per_core_busy         [i])
        );
    end
    
    assign busy = (| per_core_busy);

    if (`L2_ENABLE) begin
    `ifdef PERF_ENABLE
        VX_perf_cache_if perf_l2cache_if();
    `endif

        `RESET_RELAY (l2_reset);

        VX_cache #(
            .CACHE_ID           (`L2_CACHE_ID),
            .CACHE_SIZE         (`L2_CACHE_SIZE),
            .CACHE_LINE_SIZE    (`L2_CACHE_LINE_SIZE),
            .NUM_BANKS          (`L2_NUM_BANKS),
            .NUM_PORTS          (`L2_NUM_PORTS),
            .WORD_SIZE          (`L2_WORD_SIZE),
            .NUM_REQS           (`L2_NUM_REQS),
            .CREQ_SIZE          (`L2_CREQ_SIZE),
            .CRSQ_SIZE          (`L2_CRSQ_SIZE),
            .MSHR_SIZE          (`L2_MSHR_SIZE),
            .MRSQ_SIZE          (`L2_MRSQ_SIZE),
            .MREQ_SIZE          (`L2_MREQ_SIZE),
            .WRITE_ENABLE       (1),          
            .CORE_TAG_WIDTH     (`L1_MEM_TAG_WIDTH),
            .CORE_TAG_ID_BITS   (0),
            .MEM_TAG_WIDTH      (`L2_MEM_TAG_WIDTH),
            .NC_ENABLE          (1)
        ) l2cache (
            `SCOPE_BIND_VX_cluster_l2cache
              
            .clk                (clk),
            .reset              (l2_reset),

        `ifdef PERF_ENABLE
            .perf_cache_if      (perf_l2cache_if),
        `endif

            // Core request
            .core_req_valid     (per_core_mem_req_valid),
            .core_req_rw        (per_core_mem_req_rw),
            .core_req_byteen    (per_core_mem_req_byteen),
            .core_req_addr      (per_core_mem_req_addr),
            .core_req_data      (per_core_mem_req_data),  
            .core_req_tag       (per_core_mem_req_tag),  
            .core_req_ready     (per_core_mem_req_ready),

            // Core response
            .core_rsp_valid     (per_core_mem_rsp_valid),
            .core_rsp_data      (per_core_mem_rsp_data),
            .core_rsp_tag       (per_core_mem_rsp_tag),
            .core_rsp_ready     (per_core_mem_rsp_ready),
            `UNUSED_PIN (core_rsp_tmask),

            // Memory request
            .mem_req_valid      (mem_req_valid),
            .mem_req_rw         (mem_req_rw),        
            .mem_req_byteen     (mem_req_byteen),
            .mem_req_addr       (mem_req_addr),
            .mem_req_data       (mem_req_data),
            .mem_req_tag        (mem_req_tag),
            .mem_req_ready      (mem_req_ready),
            
            // Memory response
            .mem_rsp_valid      (mem_rsp_valid),
            .mem_rsp_tag        (mem_rsp_tag),
            .mem_rsp_data       (mem_rsp_data),
            .mem_rsp_ready      (mem_rsp_ready)
        );

    end else begin

        `RESET_RELAY (mem_arb_reset);

        VX_mem_arb #(
            .NUM_REQS     (`NUM_CORES),
            .DATA_WIDTH   (`DCACHE_MEM_DATA_WIDTH),
            .ADDR_WIDTH   (`DCACHE_MEM_ADDR_WIDTH),           
            .TAG_IN_WIDTH (`L1_MEM_TAG_WIDTH),            
            .TYPE         ("R"),
            .TAG_SEL_IDX  (1), // Skip 0 for NC flag
            .BUFFERED_REQ (1),
            .BUFFERED_RSP (1)
        ) mem_arb (
            .clk            (clk),
            .reset          (mem_arb_reset),

            // Core request
            .req_valid_in   (per_core_mem_req_valid),
            .req_rw_in      (per_core_mem_req_rw),
            .req_byteen_in  (per_core_mem_req_byteen),
            .req_addr_in    (per_core_mem_req_addr),
            .req_data_in    (per_core_mem_req_data),  
            .req_tag_in     (per_core_mem_req_tag),  
            .req_ready_in   (per_core_mem_req_ready),

            // Memory request
            .req_valid_out  (mem_req_valid),
            .req_rw_out     (mem_req_rw),        
            .req_byteen_out (mem_req_byteen),        
            .req_addr_out   (mem_req_addr),
            .req_data_out   (mem_req_data),
            .req_tag_out    (mem_req_tag),
            .req_ready_out  (mem_req_ready),

            // Core response
            .rsp_valid_out  (per_core_mem_rsp_valid),
            .rsp_data_out   (per_core_mem_rsp_data),
            .rsp_tag_out    (per_core_mem_rsp_tag),
            .rsp_ready_out  (per_core_mem_rsp_ready),
            
            // Memory response
            .rsp_valid_in   (mem_rsp_valid),
            .rsp_tag_in     (mem_rsp_tag),
            .rsp_data_in    (mem_rsp_data),
            .rsp_ready_in   (mem_rsp_ready)
        );

    end

endmodule
