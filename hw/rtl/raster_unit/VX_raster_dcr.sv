`include "VX_raster_define.vh"

module VX_raster_dcr #(  
    parameter CORE_ID = 0
) (
    input wire clk,
    input wire reset,

    // Inputs
    VX_dcr_write_if.slave   dcr_write_if,

    // Output
    output raster_dcrs_t    raster_dcrs
);

    `UNUSED_VAR (reset)

    // DCR registers
    raster_dcrs_t dcrs;

    // DCRs write
    always @(posedge clk) begin
        if (dcr_write_if.valid) begin
            case (dcr_write_if.addr)
                `DCR_RASTER_TBUF_ADDR: begin 
                    dcrs.tbuf_addr <= dcr_write_if.data[`RASTER_DCR_DATA_BITS-1:0];
                end
                `DCR_RASTER_TILE_COUNT: begin 
                    dcrs.tile_count <= dcr_write_if.data[`RASTER_TILE_BITS-1:0];
                end
                `DCR_RASTER_PBUF_ADDR: begin 
                    dcrs.pbuf_addr <= dcr_write_if.data[`RASTER_DCR_DATA_BITS-1:0];
                end
                `DCR_RASTER_PBUF_STRIDE: begin 
                    dcrs.pbuf_stride <= dcr_write_if.data[`RASTER_STRIDE_BITS-1:0];
                end
               `DCR_RASTER_DST_SIZE: begin 
                    dcrs.dst_width  <= dcr_write_if.data[0 +: `RASTER_DIM_BITS];
                    dcrs.dst_height <= dcr_write_if.data[16 +: `RASTER_DIM_BITS];
                end
            endcase
        end
    end

    // DCRs read
    assign raster_dcrs = dcrs;

`ifdef DBG_TRACE_RASTER
    always @(posedge clk) begin
        if (dcr_write_if.valid) begin
            `TRACE(1, ("%d: raster-dcr: state=", $time));
            trace_raster_state(1, dcr_write_if.addr);
            `TRACE(1, (", data=0x%0h\n", dcr_write_if.data));
        end
    end
`endif

endmodule
