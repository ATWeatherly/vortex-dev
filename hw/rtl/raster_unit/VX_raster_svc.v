`include "VX_raster_define.vh"

module VX_raster_svc #(
    parameter CORE_ID = 0
) (
    input wire clk,
    input wire reset,

    // Inputs    
    VX_raster_svc_if.slave  raster_svc_req_if,    
    VX_raster_req_if.master raster_req_if,
        
    // Outputs
    VX_commit_if.master     raster_svc_rsp_if,
    VX_gpu_csr_if.slave     raster_csr_if    
);
    // CSRs access

    VX_raster_csr #(
        .CORE_ID    (CORE_ID)
    ) raster_csr (
        .clk        (clk),
        .reset      (reset),

        // inputs        
        .raster_req_if (raster_req_if),

        // outputs
        .raster_csr_if (raster_csr_if)
    );

    assign raster_req_if.valid = 0;
    assign raster_req_if.tmask = 0;

    `UNUSED_VAR (raster_svc_req_if.valid)
    `UNUSED_VAR (raster_svc_req_if.uuid)
    `UNUSED_VAR (raster_svc_req_if.wid)
    `UNUSED_VAR (raster_svc_req_if.tmask)
    `UNUSED_VAR (raster_svc_req_if.PC)
    `UNUSED_VAR (raster_svc_req_if.rd)
    `UNUSED_VAR (raster_svc_req_if.wb)
    assign raster_svc_req_if.ready = 0;

    assign raster_svc_rsp_if.valid = 0;

endmodule