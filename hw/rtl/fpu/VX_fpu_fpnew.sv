`include "VX_fpu_define.vh"

`ifdef FPU_FPNEW

`include "cf_math_pkg.sv"
`include "fpnew_pkg.sv"
`include "defs_div_sqrt_mvp.sv"

module VX_fpu_fpnew #(      
    parameter NUM_LANES = 1,
    parameter TAGW      = 1
) (
    input wire clk,
    input wire reset,

    input wire  valid_in,
    output wire ready_in,

    input wire [TAGW-1:0] tag_in,
    
    input wire [`INST_FPU_BITS-1:0] op_type,
    input wire [`INST_FMT_BITS-1:0] fmt,
    input wire [`INST_FRM_BITS-1:0] frm,

    input wire [NUM_LANES-1:0][`XLEN-1:0]  dataa,
    input wire [NUM_LANES-1:0][`XLEN-1:0]  datab,
    input wire [NUM_LANES-1:0][`XLEN-1:0]  datac,
    output wire [NUM_LANES-1:0][`XLEN-1:0] result, 

    output wire has_fflags,
    output wire [NUM_LANES-1:0][`FP_FLAGS_BITS-1:0] fflags,

    output wire [TAGW-1:0] tag_out,

    input wire  ready_out,
    output wire valid_out
);  
    localparam LATENCY_FDIVSQRT = `MAX(`LATENCY_FDIV, `LATENCY_FSQRT);

    localparam fpnew_pkg::fpu_features_t FPU_FEATURES = '{
        Width:         `XLEN,
        EnableVectors: 1'b0,
        EnableNanBox:  1'b1,        
    `ifdef XLEN_64
        FpFmtMask:     5'b11000,
        IntFmtMask:    4'b0011
    `else
        FpFmtMask:     5'b10000,
        IntFmtMask:    4'b0010
    `endif
    };

    localparam fpnew_pkg::fpu_implementation_t FPU_IMPLEMENTATION = '{
      PipeRegs:'{'{`LATENCY_FMA, 0, 0, 0, 0},       // ADDMUL
                 '{default: unsigned'(LATENCY_FDIVSQRT)}, // DIVSQRT
                 '{default: `LATENCY_FNCP},         // NONCOMP
                 '{default: `LATENCY_FCVT}},        // CONV
      UnitTypes:'{'{default: fpnew_pkg::PARALLEL},  // ADDMUL
                  '{default: fpnew_pkg::MERGED},    // DIVSQRT
                  '{default: fpnew_pkg::PARALLEL},  // NONCOMP
                  '{default: fpnew_pkg::MERGED}},   // CONV
      PipeConfig: fpnew_pkg::DISTRIBUTED
    };
    
    wire fpu_ready_in, fpu_valid_in;    
    wire fpu_ready_out, fpu_valid_out;

    reg [TAGW-1:0] fpu_tag_in, fpu_tag_out;
    
    reg [2:0][NUM_LANES-1:0][`XLEN-1:0] fpu_operands;

    wire [NUM_LANES-1:0][`XLEN-1:0] fpu_result;
    fpnew_pkg::status_t [NUM_LANES-1:0] fpu_status;

    reg [fpnew_pkg::OP_BITS-1:0] fpu_op;
    reg [`INST_FRM_BITS-1:0] fpu_rnd;
    reg fpu_op_mod;
    reg fpu_has_fflags, fpu_has_fflags_out;
    reg [fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_src_fmt, fpu_dst_fmt, fpu_int_fmt;

    always @(*) begin
        fpu_op          = 'x;
        fpu_rnd         = frm;  
        fpu_op_mod      = 0;        
        fpu_has_fflags  = 1;
        fpu_operands[0] = dataa;
        fpu_operands[1] = datab;
        fpu_operands[2] = datac;    
        fpu_dst_fmt     = fpnew_pkg::FP32;
        fpu_int_fmt     = fpnew_pkg::INT32;

    `ifdef FLEN_64
        if (fmt[0]) begin
            fpu_dst_fmt = fpnew_pkg::FP64;
        end
    `endif

    `ifdef XLEN_64
        if (fmt[1]) begin
            fpu_int_fmt = fpnew_pkg::INT64;
        end
    `endif

        fpu_src_fmt = fpu_dst_fmt;
        
        case (op_type)
            `INST_FPU_ADD: begin
                fpu_op = fpnew_pkg::ADD;
                fpu_operands[1] = dataa;
                fpu_operands[2] = datab;
            end
            `INST_FPU_SUB: begin 
                fpu_op = fpnew_pkg::ADD; 
                fpu_operands[1] = dataa;
                fpu_operands[2] = datab;
                fpu_op_mod = 1; 
            end
            `INST_FPU_MUL:   begin fpu_op = fpnew_pkg::MUL; end
            `INST_FPU_DIV:   begin fpu_op = fpnew_pkg::DIV; end
            `INST_FPU_SQRT:  begin fpu_op = fpnew_pkg::SQRT; end
            `INST_FPU_MADD:  begin fpu_op = fpnew_pkg::FMADD; end
            `INST_FPU_MSUB:  begin fpu_op = fpnew_pkg::FMADD; fpu_op_mod = 1; end            
            `INST_FPU_NMADD: begin fpu_op = fpnew_pkg::FNMSUB; fpu_op_mod = 1; end
            `INST_FPU_NMSUB: begin fpu_op = fpnew_pkg::FNMSUB; end
        `ifdef FLEN_64
            `INST_FPU_F2F: begin fpu_op = fpnew_pkg::F2F; fpu_src_fmt = fmt[0] ? fpnew_pkg::FP32 : fpnew_pkg::FP64; end
        `endif
            `INST_FPU_F2I,
            `INST_FPU_F2U: begin fpu_op = fpnew_pkg::F2I; fpu_op_mod = op_type[0]; end
            `INST_FPU_I2F,
            `INST_FPU_U2F: begin fpu_op = fpnew_pkg::I2F; fpu_op_mod = op_type[0]; end
            `INST_FPU_CMP: begin fpu_op = fpnew_pkg::CMP; end
            `INST_FPU_MISC:begin
                case (frm)
                    0,1,2: begin fpu_op = fpnew_pkg::SGNJ; fpu_rnd = {1'b0, frm[1:0]}; fpu_has_fflags = 0; end // FSGNJ
                    3:     begin fpu_op = fpnew_pkg::CLASSIFY; fpu_has_fflags = 0; end // CLASS                     
                    4,5:   begin fpu_op = fpnew_pkg::SGNJ; fpu_rnd = 3'b011; fpu_op_mod = ~frm[0]; fpu_has_fflags = 0; end // FMV.X.W, FMV.W.X
                    6,7:   begin fpu_op = fpnew_pkg::MINMAX; fpu_rnd = {2'b00, frm[0]}; end // MIN, MAX
                endcase    
            end
            default:;
        endcase

    `ifdef FPU_RV64_F
        // apply nan-boxing to floating-point operands
        for (integer i = 0; i < NUM_LANES; ++i) begin                    
            if (op_type != `INST_FPU_I2F && op_type != `INST_FPU_U2F) begin
                fpu_operands[0][i] |= 64'hffffffff00000000;
            end
            fpu_operands[1][i] |= 64'hffffffff00000000;
            fpu_operands[2][i] |= 64'hffffffff00000000;        
        end
    `endif
    end  
    
    for (genvar i = 0; i < NUM_LANES; ++i) begin
        if (0 == i) begin
            fpnew_top #( 
                .Features       (FPU_FEATURES),
                .Implementation (FPU_IMPLEMENTATION),
                .TagType        (logic[(TAGW+1)-1:0])
            ) fpnew_core (
                .clk_i          (clk),
                .rst_ni         (~reset),
                .operands_i     ({fpu_operands[2][0], fpu_operands[1][0], fpu_operands[0][0]}),
                .rnd_mode_i     (fpnew_pkg::roundmode_e'(fpu_rnd)),
                .op_i           (fpnew_pkg::operation_e'(fpu_op)),
                .op_mod_i       (fpu_op_mod),
                .src_fmt_i      (fpnew_pkg::fp_format_e'(fpu_src_fmt)),
                .dst_fmt_i      (fpnew_pkg::fp_format_e'(fpu_dst_fmt)),
                .int_fmt_i      (fpnew_pkg::int_format_e'(fpu_int_fmt)),
                .vectorial_op_i (1'b0),
                .tag_i          ({fpu_tag_in, fpu_has_fflags}),
                .in_valid_i     (fpu_valid_in),
                .in_ready_o     (fpu_ready_in),
                .flush_i        (reset),
                .result_o       (fpu_result[0]),
                .status_o       (fpu_status[0]),
                .tag_o          ({fpu_tag_out, fpu_has_fflags_out}),
                .out_valid_o    (fpu_valid_out),
                .out_ready_i    (fpu_ready_out),
                `UNUSED_PIN (busy_o)
            );
        end else begin
            fpnew_top #( 
                .Features       (FPU_FEATURES),
                .Implementation (FPU_IMPLEMENTATION),
                .TagType        (logic)
            ) fpnew_core (
                .clk_i          (clk),
                .rst_ni         (~reset),
                .operands_i     ({fpu_operands[2][i], fpu_operands[1][i], fpu_operands[0][i]}),
                .rnd_mode_i     (fpnew_pkg::roundmode_e'(fpu_rnd)),
                .op_i           (fpnew_pkg::operation_e'(fpu_op)),
                .op_mod_i       (fpu_op_mod),
                .src_fmt_i      (fpnew_pkg::fp_format_e'(fpu_src_fmt)),
                .dst_fmt_i      (fpnew_pkg::fp_format_e'(fpu_dst_fmt)),
                .int_fmt_i      (fpnew_pkg::int_format_e'(fpu_int_fmt)),
                .vectorial_op_i (1'b0),
                .tag_i          (1'b0),
                .in_valid_i     (fpu_valid_in),
                `UNUSED_PIN (in_ready_o),
                .flush_i        (reset),
                .result_o       (fpu_result[i]),
                .status_o       (fpu_status[i]),
                `UNUSED_PIN (tag_o),
                `UNUSED_PIN (out_valid_o),
                .out_ready_i    (fpu_ready_out),
                `UNUSED_PIN (busy_o)
            );
        end
    end

    assign fpu_valid_in = valid_in;
    assign ready_in = fpu_ready_in;

    assign fpu_tag_in = tag_in;    
    assign tag_out = fpu_tag_out;

    assign result = fpu_result;
    
    assign has_fflags = fpu_has_fflags_out;   
    assign fflags = fpu_status;

    assign valid_out = fpu_valid_out;    
    assign fpu_ready_out = ready_out;

endmodule
`endif
