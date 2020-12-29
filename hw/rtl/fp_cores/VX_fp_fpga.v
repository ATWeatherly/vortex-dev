`include "VX_define.vh"

module VX_fp_fpga #( 
    parameter TAGW = 1
) (
    input wire clk,
    input wire reset,

    input wire  valid_in,
    output wire ready_in,

    input wire [TAGW-1:0] tag_in,
    
    input wire [`FPU_BITS-1:0] op_type,
    input wire [`MOD_BITS-1:0] frm,

    input wire [`NUM_THREADS-1:0][31:0]  dataa,
    input wire [`NUM_THREADS-1:0][31:0]  datab,
    input wire [`NUM_THREADS-1:0][31:0]  datac,
    output wire [`NUM_THREADS-1:0][31:0] result, 

    output wire has_fflags,
    output fflags_t [`NUM_THREADS-1:0] fflags,

    output wire [TAGW-1:0] tag_out,

    input wire  ready_out,
    output wire valid_out
);
    localparam NUM_FPC  = 5;
    localparam FPC_BITS = `LOG2UP(NUM_FPC);
    
    wire [NUM_FPC-1:0] per_core_ready_in;
    wire [NUM_FPC-1:0][`NUM_THREADS-1:0][31:0] per_core_result;
    wire [NUM_FPC-1:0][TAGW-1:0] per_core_tag_out;
    reg [NUM_FPC-1:0] per_core_ready_out;
    wire [NUM_FPC-1:0] per_core_valid_out;
    
    wire [NUM_FPC-1:0] per_core_has_fflags;  
    fflags_t [NUM_FPC-1:0][`NUM_THREADS-1:0] per_core_fflags;  

    reg [FPC_BITS-1:0] core_select;
    reg do_madd, do_sub, do_neg, is_itof, is_signed;

    always @(*) begin
        do_madd   = 'x;
        do_sub    = 'x;        
        do_neg    = 'x;
        is_itof   = 'x;
        is_signed = 'x;
        case (op_type)
            `FPU_ADD:    begin core_select = 0; do_madd = 0; do_sub = 0; do_neg = 0; end
            `FPU_SUB:    begin core_select = 0; do_madd = 0; do_sub = 1; do_neg = 0; end
            `FPU_MUL:    begin core_select = 0; do_madd = 0; do_sub = 0; do_neg = 1; end
            `FPU_MADD:   begin core_select = 0; do_madd = 1; do_sub = 0; do_neg = 0; end
            `FPU_MSUB:   begin core_select = 0; do_madd = 1; do_sub = 1; do_neg = 0; end
            `FPU_NMADD:  begin core_select = 0; do_madd = 1; do_sub = 0; do_neg = 1; end
            `FPU_NMSUB:  begin core_select = 0; do_madd = 1; do_sub = 1; do_neg = 1; end
            `FPU_DIV:    begin core_select = 1; end
            `FPU_SQRT:   begin core_select = 2; end
            `FPU_CVTWS:  begin core_select = 3; is_itof = 0; is_signed = 1; end
            `FPU_CVTWUS: begin core_select = 3; is_itof = 0; is_signed = 0; end
            `FPU_CVTSW:  begin core_select = 3; is_itof = 1; is_signed = 1; end
            `FPU_CVTSWU: begin core_select = 3; is_itof = 1; is_signed = 0; end
            default:     begin core_select = 4; end
        endcase
    end

    VX_fp_fma #(
        .TAGW (TAGW),
        .LANES(`NUM_THREADS)
    ) fp_fma (
        .clk        (clk), 
        .reset      (reset),   
        .valid_in   (valid_in && (core_select == 0)),
        .ready_in   (per_core_ready_in[0]),    
        .tag_in     (tag_in),  
        .frm        (frm),
        .do_madd    (do_madd),
        .do_sub     (do_sub),
        .do_neg     (do_neg),
        .dataa      (dataa), 
        .datab      (datab),    
        .datac      (datac),   
        .has_fflags (per_core_has_fflags[0]),
        .fflags     (per_core_fflags[0]),
        .result     (per_core_result[0]),
        .tag_out    (per_core_tag_out[0]),
        .ready_out  (per_core_ready_out[0]),
        .valid_out  (per_core_valid_out[0])
    );

    VX_fp_div #(
        .TAGW (TAGW),
        .LANES(`NUM_THREADS)
    ) fp_div (
        .clk        (clk), 
        .reset      (reset),   
        .valid_in   (valid_in && (core_select == 1)),
        .ready_in   (per_core_ready_in[1]),    
        .tag_in     (tag_in),
        .frm        (frm),  
        .dataa      (dataa), 
        .datab      (datab),   
        .has_fflags (per_core_has_fflags[1]),
        .fflags     (per_core_fflags[1]),   
        .result     (per_core_result[1]),
        .tag_out    (per_core_tag_out[1]),
        .ready_out  (per_core_ready_out[1]),
        .valid_out  (per_core_valid_out[1])
    );

    VX_fp_sqrt #(
        .TAGW (TAGW),
        .LANES(`NUM_THREADS)
    ) fp_sqrt (
        .clk        (clk), 
        .reset      (reset),   
        .valid_in   (valid_in && (core_select == 2)),
        .ready_in   (per_core_ready_in[2]),    
        .tag_in     (tag_in),
        .frm        (frm),    
        .dataa      (dataa), 
        .has_fflags (per_core_has_fflags[2]),
        .fflags     (per_core_fflags[2]),
        .result     (per_core_result[2]),
        .tag_out    (per_core_tag_out[2]),
        .ready_out  (per_core_ready_out[2]),
        .valid_out  (per_core_valid_out[2])
    );

    VX_fp_cvt #(
        .TAGW (TAGW),
        .LANES(`NUM_THREADS)
    ) fp_cvt (
        .clk        (clk), 
        .reset      (reset),   
        .valid_in   (valid_in && (core_select == 3)),
        .ready_in   (per_core_ready_in[3]),    
        .tag_in     (tag_in), 
        .frm        (frm),
        .is_itof    (is_itof),   
        .is_signed  (is_signed),        
        .dataa      (dataa),  
        .has_fflags (per_core_has_fflags[3]),
        .fflags     (per_core_fflags[3]),
        .result     (per_core_result[3]),
        .tag_out    (per_core_tag_out[3]),
        .ready_out  (per_core_ready_out[3]),
        .valid_out  (per_core_valid_out[3])
    );

    VX_fp_ncomp #(
        .TAGW (TAGW),
        .LANES(`NUM_THREADS)
    ) fp_ncomp (
        .clk        (clk),
        .reset      (reset),   
        .valid_in   (valid_in && (core_select == 4)),
        .ready_in   (per_core_ready_in[4]),        
        .tag_in     (tag_in),        
        .op_type    (op_type),
        .frm        (frm),
        .dataa      (dataa),
        .datab      (datab),        
        .result     (per_core_result[4]), 
        .has_fflags (per_core_has_fflags[4]),
        .fflags     (per_core_fflags[4]),
        .tag_out    (per_core_tag_out[4]),
        .ready_out  (per_core_ready_out[4]),
        .valid_out  (per_core_valid_out[4])
    );

    reg has_fflags_n;
    fflags_t [`NUM_THREADS-1:0] fflags_n;
    reg [`NUM_THREADS-1:0][31:0] result_n;
    reg [TAGW-1:0] tag_out_n;

    always @(*) begin
        per_core_ready_out = 0;
        has_fflags_n       = 'x;
        fflags_n           = 'x;
        result_n           = 'x;
        tag_out_n          = 'x;
        for (integer i = 0; i < NUM_FPC; i++) begin
            if (per_core_valid_out[i]) begin                
                has_fflags_n = per_core_has_fflags[i];
                fflags_n     = per_core_fflags[i];
                result_n     = per_core_result[i];
                tag_out_n    = per_core_tag_out[i];
                per_core_ready_out[i] = ready_out;
                break;
            end
        end
    end

    assign valid_out  = (| per_core_valid_out);
    assign has_fflags = has_fflags_n;
    assign tag_out    = tag_out_n;
    assign result     = result_n;    
    assign fflags     = fflags_n;

    assign ready_in = per_core_ready_in[core_select];

endmodule