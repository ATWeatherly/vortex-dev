`include "VX_define.vh"
`include "VX_cache_types.vh"

`IGNORE_WARNINGS_BEGIN
import VX_cache_types::*;
`IGNORE_WARNINGS_END

module VX_cluster #(
    parameter CLUSTER_ID = 0
) ( 
    `SCOPE_IO_VX_cluster

    // Clock
    input  wire                 clk,
    input  wire                 reset,

`ifdef PERF_ENABLE
    VX_perf_memsys_if.master    perf_memsys_if,
    VX_perf_memsys_if.slave     perf_memsys_total_if,
`endif

    input base_dcrs_t           base_dcrs,

`ifdef EXT_TEX_ENABLE
`ifdef PERF_ENABLE
    VX_tex_perf_if.master       perf_tex_if,
    VX_perf_cache_if.master     perf_tcache_if,
    VX_tex_perf_if.slave        perf_tex_total_if,
    VX_perf_cache_if.slave      perf_tcache_total_if,
`endif
    VX_tex_dcr_if.slave         tex_dcr_if,
`endif

`ifdef EXT_RASTER_ENABLE
`ifdef PERF_ENABLE
    VX_raster_perf_if.master    perf_raster_if,
    VX_perf_cache_if.master     perf_rcache_if,
    VX_raster_perf_if.slave     perf_raster_total_if,
    VX_perf_cache_if.slave      perf_rcache_total_if,
`endif
    VX_raster_dcr_if.slave      raster_dcr_if,
`endif

`ifdef EXT_ROP_ENABLE
`ifdef PERF_ENABLE
    VX_rop_perf_if.master       perf_rop_if,
    VX_perf_cache_if.master     perf_ocache_if,
    VX_rop_perf_if.slave        perf_rop_total_if,
    VX_perf_cache_if.slave      perf_ocache_total_if,
`endif
    VX_rop_dcr_if.slave         rop_dcr_if,
`endif

    // Memory
    VX_mem_req_if.master        mem_req_if,
    VX_mem_rsp_if.slave         mem_rsp_if,

    // simulation helper signals
    output wire                 sim_ebreak,
    output wire [`NUM_REGS-1:0][31:0] sim_wb_value,

    // Status
    output wire                 busy
);

`ifdef EXT_RASTER_ENABLE

`ifdef PERF_ENABLE
    VX_raster_perf_if perf_raster_unit_if[`NUM_RASTER_UNITS]();
    `PERF_RASTER_ADD (perf_raster_if, perf_raster_unit_if, `NUM_RASTER_UNITS);
`endif

    VX_cache_req_if #(
        .NUM_REQS  (RCACHE_NUM_REQS), 
        .WORD_SIZE (RCACHE_WORD_SIZE), 
        .TAG_WIDTH (RCACHE_TAG_WIDTH)
    ) rcache_req_if[`NUM_RASTER_UNITS]();

    VX_cache_rsp_if #(
        .NUM_REQS  (RCACHE_NUM_REQS), 
        .WORD_SIZE (RCACHE_WORD_SIZE), 
        .TAG_WIDTH (RCACHE_TAG_WIDTH)
    ) rcache_rsp_if[`NUM_RASTER_UNITS]();

    VX_raster_req_if #(
        .NUM_LANES (`NUM_THREADS)
    ) raster_req_if[`NUM_RASTER_UNITS]();

    // Generate all raster units
    for (genvar i = 0; i < `NUM_RASTER_UNITS; ++i) begin

        `RESET_RELAY (raster_reset, reset);

        VX_raster_unit #( 
            .INSTANCE_ID     ($sformatf("cluster%0d-raster%0d", CLUSTER_ID, i)),
            .INSTANCE_IDX    (CLUSTER_ID * `NUM_RASTER_UNITS + i),
            .NUM_INSTANCES   (`NUM_CLUSTERS * `NUM_RASTER_UNITS),
            .NUM_PES         (`RASTER_NUM_PES),
            .TILE_LOGSIZE    (`RASTER_TILE_LOGSIZE),
            .BLOCK_LOGSIZE   (`RASTER_BLOCK_LOGSIZE),
            .MEM_FIFO_DEPTH  (`RASTER_MEM_FIFO_DEPTH),
            .QUAD_FIFO_DEPTH (`RASTER_QUAD_FIFO_DEPTH),
            .OUTPUT_QUADS    (`NUM_THREADS)
        ) raster_unit (
            .clk           (clk),
            .reset         (raster_reset),
        `ifdef PERF_ENABLE
            .perf_raster_if(perf_raster_unit_if[i]),
        `endif
            .raster_dcr_if (raster_dcr_if),
            .raster_req_if (raster_req_if[i]),
            .cache_req_if  (rcache_req_if[i]),
            .cache_rsp_if  (rcache_rsp_if[i])
        );
    end

    VX_raster_req_if #(
        .NUM_LANES (`NUM_THREADS)
    ) per_socket_raster_req_if[`NUM_SOCKETS]();

    VX_raster_arb #(
        .NUM_INPUTS  (`NUM_RASTER_UNITS),
        .NUM_LANES   (`NUM_THREADS),
        .NUM_OUTPUTS (`NUM_SOCKETS),
        .ARBITER     ("R"),
        .BUFFERED    ((`NUM_SOCKETS != `NUM_RASTER_UNITS) ? 2 : 0)
    ) raster_arb (
        .clk        (clk),
        .reset      (reset),
        .req_in_if  (raster_req_if),
        .req_out_if (per_socket_raster_req_if)
    );    

`endif

`ifdef EXT_ROP_ENABLE

`ifdef PERF_ENABLE
    VX_rop_perf_if perf_rop_unit_if[`NUM_ROP_UNITS]();
    `PERF_ROP_ADD (perf_rop_if, perf_rop_unit_if, `NUM_ROP_UNITS);
`endif

    VX_cache_req_if #(
        .NUM_REQS  (OCACHE_NUM_REQS), 
        .WORD_SIZE (OCACHE_WORD_SIZE), 
        .TAG_WIDTH (OCACHE_TAG_WIDTH)
    ) ocache_req_if[`NUM_ROP_UNITS]();

    VX_cache_rsp_if #(
        .NUM_REQS  (OCACHE_NUM_REQS), 
        .WORD_SIZE (OCACHE_WORD_SIZE), 
        .TAG_WIDTH (OCACHE_TAG_WIDTH)
    ) ocache_rsp_if[`NUM_ROP_UNITS]();

    VX_rop_req_if #(
        .NUM_LANES (`NUM_THREADS)
    ) per_socket_rop_req_if[`NUM_SOCKETS]();

    VX_rop_req_if #(
        .NUM_LANES (`NUM_THREADS)
    ) rop_req_if[`NUM_ROP_UNITS]();

    VX_rop_arb #(
        .NUM_INPUTS  (`NUM_SOCKETS),
        .NUM_LANES   (`NUM_THREADS),
        .NUM_OUTPUTS (`NUM_ROP_UNITS),
        .ARBITER     ("R"),
        .BUFFERED    ((`NUM_SOCKETS != `NUM_ROP_UNITS) ? 2 : 0)
    ) rop_arb (
        .clk        (clk),
        .reset      (reset),
        .req_in_if  (per_socket_rop_req_if),
        .req_out_if (rop_req_if)
    );

    // Generate all rop units
    for (genvar i = 0; i < `NUM_ROP_UNITS; ++i) begin

        `RESET_RELAY (rop_reset, reset);

        VX_rop_unit #(
            .INSTANCE_ID ($sformatf("cluster%0d-rop%0d", CLUSTER_ID, i)),
            .NUM_LANES   (`NUM_THREADS)
        ) rop_unit (
            .clk           (clk),
            .reset         (rop_reset),
        `ifdef PERF_ENABLE
            .perf_rop_if   (perf_rop_unit_if[i]),
        `endif
            .rop_dcr_if    (rop_dcr_if),
            .rop_req_if    (rop_req_if[i]),            
            .cache_req_if  (ocache_req_if[i]),
            .cache_rsp_if  (ocache_rsp_if[i])
        );
    end

`endif

`ifdef EXT_TEX_ENABLE

`ifdef PERF_ENABLE
    VX_tex_perf_if perf_tex_unit_if[`NUM_TEX_UNITS]();
    `PERF_TEX_ADD (perf_tex_if, perf_tex_unit_if, `NUM_TEX_UNITS);
`endif

    VX_cache_req_if #(
        .NUM_REQS  (TCACHE_NUM_REQS), 
        .WORD_SIZE (TCACHE_WORD_SIZE), 
        .TAG_WIDTH (TCACHE_TAG_WIDTH)
    ) tcache_req_if[`NUM_TEX_UNITS]();

    VX_cache_rsp_if #(
        .NUM_REQS  (TCACHE_NUM_REQS), 
        .WORD_SIZE (TCACHE_WORD_SIZE), 
        .TAG_WIDTH (TCACHE_TAG_WIDTH)
    ) tcache_rsp_if[`NUM_TEX_UNITS]();

    VX_tex_req_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`TEX_REQ_ARB1_TAG_WIDTH)
    ) per_socket_tex_req_if[`NUM_SOCKETS]();

    VX_tex_rsp_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`TEX_REQ_ARB1_TAG_WIDTH)
    ) per_socket_tex_rsp_if[`NUM_SOCKETS]();

    VX_tex_req_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`TEX_REQ_ARB2_TAG_WIDTH)
    ) tex_req_if[`NUM_TEX_UNITS]();

    VX_tex_rsp_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`TEX_REQ_ARB2_TAG_WIDTH)
    ) tex_rsp_if[`NUM_TEX_UNITS]();

    VX_tex_arb #(
        .NUM_INPUTS   (`NUM_SOCKETS),
        .NUM_LANES    (`NUM_THREADS),
        .NUM_OUTPUTS  (`NUM_TEX_UNITS),
        .TAG_WIDTH    (`TEX_REQ_ARB1_TAG_WIDTH),
        .ARBITER      ("R"),
        .BUFFERED_REQ ((`NUM_SOCKETS != `NUM_TEX_UNITS) ? 2 : 0)
    ) tex_arb (
        .clk        (clk),
        .reset      (reset),
        .req_in_if  (per_socket_tex_req_if),
        .rsp_in_if  (per_socket_tex_rsp_if),
        .req_out_if (tex_req_if),
        .rsp_out_if (tex_rsp_if)
    );

    // Generate all texture units
    for (genvar i = 0; i < `NUM_TEX_UNITS; ++i) begin

        `RESET_RELAY (tex_reset, reset);

        VX_tex_unit #(
            .INSTANCE_ID ($sformatf("cluster%0d-tex%0d", CLUSTER_ID, i)),
            .NUM_LANES   (`NUM_THREADS),
            .TAG_WIDTH   (`TEX_REQ_ARB2_TAG_WIDTH)
        ) tex_unit (
            .clk          (clk),
            .reset        (tex_reset),
        `ifdef PERF_ENABLE
            .perf_tex_if  (perf_tex_unit_if[i]),
        `endif 
            .tex_dcr_if   (tex_dcr_if),
            .tex_req_if   (tex_req_if[i]),
            .tex_rsp_if   (tex_rsp_if[i]),
            .cache_req_if (tcache_req_if[i]),
            .cache_rsp_if (tcache_rsp_if[i])
        );
    end
            
`endif

`ifdef EXT_F_ENABLE

    VX_fpu_req_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`FPU_REQ_ARB1_TAG_WIDTH)
    ) per_socket_fpu_req_if[`NUM_SOCKETS]();

    VX_fpu_rsp_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`FPU_REQ_ARB1_TAG_WIDTH)
    ) per_socket_fpu_rsp_if[`NUM_SOCKETS]();

    VX_fpu_req_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`FPU_REQ_ARB2_TAG_WIDTH)
    ) fpu_req_if[`NUM_FPU_UNITS]();

    VX_fpu_rsp_if #(
        .NUM_LANES (`NUM_THREADS),
        .TAG_WIDTH (`FPU_REQ_ARB2_TAG_WIDTH)
    ) fpu_rsp_if[`NUM_FPU_UNITS]();

    VX_fpu_arb #(
        .NUM_INPUTS   (`NUM_SOCKETS),
        .NUM_LANES    (`NUM_THREADS),
        .NUM_OUTPUTS  (`NUM_FPU_UNITS),
        .TAG_WIDTH    (`FPU_REQ_ARB1_TAG_WIDTH),
        .ARBITER      ("R"),
        .BUFFERED_REQ ((`NUM_SOCKETS != `NUM_FPU_UNITS) ? 2 : 0)
    ) fpu_arb (
        .clk        (clk),
        .reset      (reset),
        .req_in_if  (per_socket_fpu_req_if),
        .rsp_in_if  (per_socket_fpu_rsp_if),
        .req_out_if (fpu_req_if),
        .rsp_out_if (fpu_rsp_if)
    );

    // Generate all floating-point units
    for (genvar i = 0; i < `NUM_FPU_UNITS; ++i) begin

        `RESET_RELAY (fpu_reset, reset);

        VX_fpu_unit #(
            .INSTANCE_ID ($sformatf("cluster%0d-fpu", CLUSTER_ID)),
            .NUM_LANES   (`NUM_THREADS),
            .TAG_WIDTH   (`FPU_REQ_ARB2_TAG_WIDTH)
        ) fpu_unit (
            .clk        (clk),
            .reset      (fpu_reset),        
            .fpu_req_if (fpu_req_if[i]), 
            .fpu_rsp_if (fpu_rsp_if[i])  
        );
    end

`endif

    VX_cache_req_if #(
        .NUM_REQS  (DCACHE_NUM_REQS), 
        .WORD_SIZE (DCACHE_WORD_SIZE), 
        .TAG_WIDTH (DCACHE_ARB_TAG_WIDTH)
    ) per_socket_dcache_req_if[`NUM_SOCKETS]();

    VX_cache_rsp_if #(
        .NUM_REQS  (DCACHE_NUM_REQS), 
        .WORD_SIZE (DCACHE_WORD_SIZE), 
        .TAG_WIDTH (DCACHE_ARB_TAG_WIDTH)
    ) per_socket_dcache_rsp_if[`NUM_SOCKETS]();
    
    VX_cache_req_if #(
        .NUM_REQS  (ICACHE_NUM_REQS), 
        .WORD_SIZE (ICACHE_WORD_SIZE), 
        .TAG_WIDTH (ICACHE_ARB_TAG_WIDTH)
    ) per_socket_icache_req_if[`NUM_SOCKETS]();

    VX_cache_rsp_if #(
        .NUM_REQS  (ICACHE_NUM_REQS), 
        .WORD_SIZE (ICACHE_WORD_SIZE), 
        .TAG_WIDTH (ICACHE_ARB_TAG_WIDTH)
    ) per_socket_icache_rsp_if[`NUM_SOCKETS]();    

    VX_mem_unit #(
        .CLUSTER_ID (CLUSTER_ID)
    ) mem_unit (
        .clk                (clk),
        .reset              (reset),

    `ifdef PERF_ENABLE
        .perf_memsys_if     (perf_memsys_if),
    `endif

        .dcache_req_if      (per_socket_dcache_req_if),
        .dcache_rsp_if      (per_socket_dcache_rsp_if),
        
        .icache_req_if      (per_socket_icache_req_if),
        .icache_rsp_if      (per_socket_icache_rsp_if),

    `ifdef EXT_TEX_ENABLE
    `ifdef PERF_ENABLE
        .perf_tcache_if     (perf_tcache_if),
    `endif
        .tcache_req_if      (tcache_req_if),
        .tcache_rsp_if      (tcache_rsp_if),
    `endif

    `ifdef EXT_RASTER_ENABLE
    `ifdef PERF_ENABLE
        .perf_rcache_if     (perf_rcache_if),
    `endif
        .rcache_req_if      (rcache_req_if),
        .rcache_rsp_if      (rcache_rsp_if),
    `endif 

    `ifdef EXT_ROP_ENABLE
    `ifdef PERF_ENABLE
        .perf_ocache_if     (perf_ocache_if),
    `endif
        .ocache_req_if      (ocache_req_if),
        .ocache_rsp_if      (ocache_rsp_if),
    `endif

        .mem_req_if         (mem_req_if),
        .mem_rsp_if         (mem_rsp_if)
    );

    ///////////////////////////////////////////////////////////////////////////

    wire [`NUM_SOCKETS-1:0] per_socket_sim_ebreak;
    wire [`NUM_SOCKETS-1:0][`NUM_REGS-1:0][31:0] per_socket_sim_wb_value;
    assign sim_ebreak = per_socket_sim_ebreak[0];
    assign sim_wb_value = per_socket_sim_wb_value[0];
    `UNUSED_VAR (per_socket_sim_ebreak)
    `UNUSED_VAR (per_socket_sim_wb_value)

    wire [`NUM_SOCKETS-1:0] per_socket_busy;

    // Generate all sockets
    for (genvar i = 0; i < `NUM_SOCKETS; ++i) begin

        `RESET_RELAY_EX (socket_reset, reset, (`NUM_SOCKETS > 1));

        `BUFFER_EX (socket_base_dcrs, base_dcrs, (`NUM_SOCKETS > 1));

        VX_socket #(
            .SOCKET_ID ((CLUSTER_ID * `NUM_SOCKETS) + i)
        ) socket (
            `SCOPE_BIND_VX_cluster_socket(i)

            .clk            (clk),
            .reset          (socket_reset),

        `ifdef PERF_ENABLE
            .perf_memsys_if (perf_memsys_total_if),
        `endif
            
            .base_dcrs      (socket_base_dcrs),

            .dcache_req_if  (per_socket_dcache_req_if[i]),
            .dcache_rsp_if  (per_socket_dcache_rsp_if[i]),

            .icache_req_if  (per_socket_icache_req_if[i]),
            .icache_rsp_if  (per_socket_icache_rsp_if[i]),

        `ifdef EXT_F_ENABLE
            .fpu_req_if     (per_socket_fpu_req_if[i]),
            .fpu_rsp_if     (per_socket_fpu_rsp_if[i]),
        `endif

        `ifdef EXT_TEX_ENABLE
        `ifdef PERF_ENABLE
            .perf_tex_if    (perf_tex_total_if),
            .perf_tcache_if (perf_tcache_total_if),
        `endif
            .tex_req_if     (per_socket_tex_req_if[i]),
            .tex_rsp_if     (per_socket_tex_rsp_if[i]),
        `endif

        `ifdef EXT_RASTER_ENABLE
        `ifdef PERF_ENABLE
            .perf_raster_if (perf_raster_total_if),
            .perf_rcache_if (perf_rcache_total_if),
        `endif
            .raster_req_if  (per_socket_raster_req_if[i]),
        `endif
        
        `ifdef EXT_ROP_ENABLE
        `ifdef PERF_ENABLE
            .perf_rop_if    (perf_rop_total_if),
            .perf_ocache_if (perf_ocache_total_if),
        `endif
            .rop_req_if     (per_socket_rop_req_if[i]),
        `endif

            .sim_ebreak     (per_socket_sim_ebreak[i]),
            .sim_wb_value   (per_socket_sim_wb_value[i]),
            .busy           (per_socket_busy[i])
        );
    end
    
    assign busy = (| per_socket_busy);

endmodule
