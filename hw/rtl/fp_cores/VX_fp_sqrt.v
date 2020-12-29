`include "VX_define.vh"

`ifndef SYNTHESIS
`include "float_dpi.vh"
`endif

module VX_fp_sqrt #( 
    parameter TAGW = 1,
    parameter LANES = 1
) (
    input wire clk,
    input wire reset,   

    output wire ready_in,
    input wire  valid_in,

    input wire [TAGW-1:0] tag_in,
    
    input wire [`FRM_BITS-1:0] frm,

    input wire [LANES-1:0][31:0]  dataa,
    output wire [LANES-1:0][31:0] result,  

    output wire has_fflags,
    output fflags_t [LANES-1:0] fflags,

    output wire [TAGW-1:0] tag_out,

    input wire  ready_out,
    output wire valid_out
);    
    wire stall = ~ready_out && valid_out;
    wire enable = ~stall;
    
    for (genvar i = 0; i < LANES; i++) begin
    `ifdef QUARTUS
        acl_fsqrt fsqrt (
            .clk    (clk),
            .areset (reset),
            .en     (enable),
            .a      (dataa[i]),
            .q      (result[i])
        );
    `else
        integer fsqrt_h;
        initial begin
            fsqrt_h = dpi_register();
        end
        always @(posedge clk) begin
           dpi_fsqrt (fsqrt_h, enable, dataa[i], `LATENCY_FSQRT, result[i]);
        end
    `endif
    end

    VX_shift_register #(
        .DATAW  (1 + TAGW),
        .DEPTH  (`LATENCY_FSQRT),
        .RESETW (1)
    ) shift_reg (
        .clk      (clk),
        .reset    (reset),
        .enable   (enable),
        .data_in  ({valid_in,  tag_in}),
        .data_out ({valid_out, tag_out})
    );

    assign ready_in = enable;

    `UNUSED_VAR (frm)
    assign has_fflags = 0;
    assign fflags = 0;

endmodule
