`include "VX_rop_define.vh"

module VX_rop_csr #( 
    parameter CORE_ID = 0
) (
    input wire clk,
    input wire reset,

    // Inputs
    VX_gpu_csr_if.slave rop_csr_if,

    // Output
    output rop_csrs_t rop_csrs
);

    // CSR registers

    rop_csrs_t reg_csrs;

    // CSRs write

    always @(posedge clk) begin
        if (reset) begin
            reg_csrs <= '0;
        end else if (rop_csr_if.write_enable) begin
            case (rop_csr_if.write_addr)
                `CSR_ROP_RT_IDX:;
                `CSR_ROP_SAMPLE_IDX:;
                default:;
            endcase
        end
    end

    assign rop_csr_if.read_data = 'x;

    assign rop_csrs = reg_csrs;

    `UNUSED_VAR (rop_csr_if.read_enable)
    `UNUSED_VAR (rop_csr_if.read_uuid)
    `UNUSED_VAR (rop_csr_if.read_wid)
    `UNUSED_VAR (rop_csr_if.read_tmask)
    
    `UNUSED_VAR (rop_csr_if.write_data)    
    `UNUSED_VAR (rop_csr_if.write_uuid)
    `UNUSED_VAR (rop_csr_if.write_wid)
    `UNUSED_VAR (rop_csr_if.write_tmask)

`ifdef DBG_TRACE_TEX
    always @(posedge clk) begin
        if (rop_csr_if.write_enable) begin
            dpi_trace(1, "%d: core%0d-rop-csr-write: wid=%0d, tmask=%b, state=", $time, CORE_ID, rop_csr_if.write_wid, rop_csr_if.write_tmask);
            trace_rop_csr(1, rop_csr_if.write_addr);
            dpi_trace(1, ", data=");
            `TRACE_ARRAY1D(1, rop_csr_if.write_data, `NUM_THREADS);
            dpi_trace(1, " (#%0d)\n", rop_csr_if.write_uuid);
        end
    end
`endif

endmodule
