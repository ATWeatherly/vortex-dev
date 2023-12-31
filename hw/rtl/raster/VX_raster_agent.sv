`include "VX_raster_define.vh"

module VX_raster_agent #(
    parameter CORE_ID = 0
) (
    input wire clk,
    input wire reset,

    // Inputs    
    VX_raster_agent_if.slave raster_agent_if,    
    VX_raster_req_if.slave raster_req_if,
        
    // Outputs
    VX_commit_if.master    raster_commit_if,
    VX_gpu_csr_if.slave    raster_csr_if    
);
    `UNUSED_PARAM (CORE_ID)

    localparam UUID_WIDTH = `UP(`UUID_BITS);
    localparam NW_WIDTH   = `UP(`NW_BITS);

    wire raster_rsp_valid, raster_rsp_ready;

    // CSRs access

    wire csr_write_enable = raster_req_if.valid && raster_agent_if.valid && raster_rsp_ready;

    VX_raster_csr #(
        .CORE_ID (CORE_ID)
    ) raster_csr (
        .clk            (clk),
        .reset          (reset),
        // inputs
        .write_enable   (csr_write_enable),    
        .write_uuid     (raster_agent_if.uuid),
        .write_wid      (raster_agent_if.wid),
        .write_tmask    (raster_agent_if.tmask),
        .write_data     (raster_req_if.stamps),
        // outputs
        .raster_csr_if  (raster_csr_if)
    );

    // it is possible to have ready = f(valid) when using arbiters, 
    // because of that we need to decouple raster_agent_if and raster_commit_if handshake with a pipe register

    assign raster_agent_if.ready = raster_req_if.valid && raster_rsp_ready;

    assign raster_req_if.ready = raster_agent_if.valid && raster_rsp_ready;

    assign raster_rsp_valid = raster_agent_if.valid && raster_req_if.valid;

    wire [`NUM_THREADS-1:0][31:0] response_data;

    for (genvar i = 0; i < `NUM_THREADS; ++i) begin
        assign response_data[i] = {31'(raster_req_if.stamps[i].pid), ~raster_req_if.done};
    end

    VX_skid_buffer #(
        .DATAW (UUID_WIDTH + NW_WIDTH + `NUM_THREADS + 32 + `NR_BITS + (`NUM_THREADS * 32))
    ) rsp_sbuf (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (raster_rsp_valid),
        .ready_in  (raster_rsp_ready), 
        .data_in   ({raster_agent_if.uuid,  raster_agent_if.wid,  raster_agent_if.tmask,  raster_agent_if.PC,  raster_agent_if.rd,  response_data}),
        .data_out  ({raster_commit_if.uuid, raster_commit_if.wid, raster_commit_if.tmask, raster_commit_if.PC, raster_commit_if.rd, raster_commit_if.data}),
        .valid_out (raster_commit_if.valid),
        .ready_out (raster_commit_if.ready)
    );

    assign raster_commit_if.wb  = 1'b1;
    assign raster_commit_if.eop = 1'b1;

`ifdef DBG_TRACE_RASTER
    always @(posedge clk) begin
        if (raster_agent_if.valid && raster_agent_if.ready) begin
            for (integer i = 0; i < `NUM_THREADS; ++i) begin
                `TRACE(1, ("%d: core%0d-raster-stamp[%0d]: wid=%0d, PC=0x%0h, tmask=%b, done=%b, x=%0d, y=%0d, mask=%0d, pid=%0d, bcoords={{0x%0h, 0x%0h, 0x%0h}, {0x%0h, 0x%0h, 0x%0h}, {0x%0h, 0x%0h, 0x%0h}, {0x%0h, 0x%0h, 0x%0h}} (#%0d)\n", 
                    $time, CORE_ID, i, raster_agent_if.wid, raster_agent_if.PC, raster_agent_if.tmask,
                    raster_req_if.done,
                    raster_req_if.stamps[i].pos_x,  raster_req_if.stamps[i].pos_y, raster_req_if.stamps[i].mask, raster_req_if.stamps[i].pid,
                    raster_req_if.stamps[i].bcoords[0][0], raster_req_if.stamps[i].bcoords[1][0], raster_req_if.stamps[i].bcoords[2][0], 
                    raster_req_if.stamps[i].bcoords[0][1], raster_req_if.stamps[i].bcoords[1][1], raster_req_if.stamps[i].bcoords[2][1], 
                    raster_req_if.stamps[i].bcoords[0][2], raster_req_if.stamps[i].bcoords[1][2], raster_req_if.stamps[i].bcoords[2][2], 
                    raster_req_if.stamps[i].bcoords[0][3], raster_req_if.stamps[i].bcoords[1][3], raster_req_if.stamps[i].bcoords[2][3], raster_agent_if.uuid));
            end
        end
    end
`endif

endmodule
