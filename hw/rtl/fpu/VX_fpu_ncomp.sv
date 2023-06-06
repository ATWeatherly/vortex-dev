`include "VX_fpu_define.vh"

/// Modified port of noncomp module from fpnew Libray 
/// reference: https://github.com/pulp-platform/fpnew

module VX_fpu_ncomp #(
    parameter NUM_LANES = 1,
    parameter TAGW = 1
) (
    input wire clk,
    input wire reset,

    output wire ready_in,
    input wire  valid_in,

    input wire [TAGW-1:0] tag_in,
    
    input wire [`INST_MOD_BITS-1:0] op_mod,

    input wire [NUM_LANES-1:0][31:0]  dataa,
    input wire [NUM_LANES-1:0][31:0]  datab,
    output wire [NUM_LANES-1:0][31:0] result, 

    output wire has_fflags,
    output wire [NUM_LANES-1:0][`FP_FLAGS_BITS-1:0] fflags,

    output wire [TAGW-1:0] tag_out,

    input wire  ready_out,
    output wire valid_out
);  
    localparam  EXP_BITS = 8;
    localparam  MAN_BITS = 23;
        
    localparam  NEG_INF     = 32'h00000001,
                NEG_NORM    = 32'h00000002,
                NEG_SUBNORM = 32'h00000004,
                NEG_ZERO    = 32'h00000008,
                POS_ZERO    = 32'h00000010,
                POS_SUBNORM = 32'h00000020,
                POS_NORM    = 32'h00000040,
                POS_INF     = 32'h00000080,
                //SIG_NAN   = 32'h00000100,
                QUT_NAN     = 32'h00000200;

    wire [NUM_LANES-1:0]        a_sign, b_sign;
    wire [NUM_LANES-1:0][7:0]   a_exponent, b_exponent;
    wire [NUM_LANES-1:0][22:0]  a_mantissa, b_mantissa;
    fclass_t [NUM_LANES-1:0]    a_fclass, b_fclass;
    wire [NUM_LANES-1:0]        a_smaller, ab_equal;

    // Setup
    for (genvar i = 0; i < NUM_LANES; ++i) begin
        assign     a_sign[i] = dataa[i][31]; 
        assign a_exponent[i] = dataa[i][30:23];
        assign a_mantissa[i] = dataa[i][22:0];

        assign     b_sign[i] = datab[i][31]; 
        assign b_exponent[i] = datab[i][30:23];
        assign b_mantissa[i] = datab[i][22:0];

        VX_fpu_class #( 
            .EXP_BITS (EXP_BITS),
            .MAN_BITS (MAN_BITS)
        ) fp_class_a (
            .exp_i  (a_exponent[i]),
            .man_i  (a_mantissa[i]),
            .clss_o (a_fclass[i])
        );

        VX_fpu_class #( 
            .EXP_BITS (EXP_BITS),
            .MAN_BITS (MAN_BITS)
        ) fp_class_b (
            .exp_i  (b_exponent[i]),
            .man_i  (b_mantissa[i]),
            .clss_o (b_fclass[i])
        );

        assign a_smaller[i] = $signed(dataa[i]) < $signed(datab[i]);
        assign ab_equal[i]  = (dataa[i] == datab[i]) | (a_fclass[i].is_zero & b_fclass[i].is_zero);
    end  

    // Pipeline stage0

    wire                        valid_in_s0;
    wire [TAGW-1:0]             tag_in_s0;
    wire [`INST_MOD_BITS-1:0]   op_mod_s0;
    wire [NUM_LANES-1:0][31:0]  dataa_s0, datab_s0;
    wire [NUM_LANES-1:0]        a_sign_s0, b_sign_s0;
    wire [NUM_LANES-1:0][7:0]   a_exponent_s0;
    wire [NUM_LANES-1:0][22:0]  a_mantissa_s0;
    fclass_t [NUM_LANES-1:0]    a_fclass_s0, b_fclass_s0;
    wire [NUM_LANES-1:0]        a_smaller_s0, ab_equal_s0;

    wire stall;

    VX_pipe_register #(
        .DATAW  (1 + TAGW + `INST_MOD_BITS + NUM_LANES * (2 * 32 + 1 + 1 + 8 + 23 + 2 * $bits(fclass_t) + 1 + 1)),
        .RESETW (1),
        .DEPTH  (0)
    ) pipe_reg0 (
        .clk      (clk),
        .reset    (reset),
        .enable   (!stall),
        .data_in  ({valid_in,    tag_in,    op_mod,    dataa,    datab,    a_sign,    b_sign,    a_exponent,    a_mantissa,    a_fclass,    b_fclass,    a_smaller,    ab_equal}),
        .data_out ({valid_in_s0, tag_in_s0, op_mod_s0, dataa_s0, datab_s0, a_sign_s0, b_sign_s0, a_exponent_s0, a_mantissa_s0, a_fclass_s0, b_fclass_s0, a_smaller_s0, ab_equal_s0})
    ); 

    // FCLASS
    reg [NUM_LANES-1:0][31:0] fclass_mask;  // generate a 10-bit mask for integer reg
    for (genvar i = 0; i < NUM_LANES; ++i) begin
        always @(*) begin 
            if (a_fclass_s0[i].is_normal) begin
                fclass_mask[i] = a_sign_s0[i] ? NEG_NORM : POS_NORM;
            end 
            else if (a_fclass_s0[i].is_inf) begin
                fclass_mask[i] = a_sign_s0[i] ? NEG_INF : POS_INF;
            end 
            else if (a_fclass_s0[i].is_zero) begin
                fclass_mask[i] = a_sign_s0[i] ? NEG_ZERO : POS_ZERO;
            end 
            else if (a_fclass_s0[i].is_subnormal) begin
                fclass_mask[i] = a_sign_s0[i] ? NEG_SUBNORM : POS_SUBNORM;
            end 
            else if (a_fclass_s0[i].is_nan) begin
                fclass_mask[i] = {22'h0, a_fclass_s0[i].is_quiet, a_fclass_s0[i].is_signaling, 8'h0};
            end 
            else begin                     
                fclass_mask[i] = QUT_NAN;
            end
        end
    end

    // Min/Max    
    reg [NUM_LANES-1:0][31:0] fminmax_res;
    for (genvar i = 0; i < NUM_LANES; ++i) begin
        always @(*) begin
            if (a_fclass_s0[i].is_nan && b_fclass_s0[i].is_nan)
                fminmax_res[i] = {1'b0, 8'hff, 1'b1, 22'd0}; // canonical qNaN
            else if (a_fclass_s0[i].is_nan) 
                fminmax_res[i] = datab_s0[i];
            else if (b_fclass_s0[i].is_nan) 
                fminmax_res[i] = dataa_s0[i];
            else begin 
                fminmax_res[i] = op_mod_s0[0] ? (a_smaller_s0[i] ? dataa_s0[i] : datab_s0[i]): // FMIN
                                                (a_smaller_s0[i] ? datab_s0[i] : dataa_s0[i]); // FMAX
            end
        end
    end

    // Sign injection    
    reg [NUM_LANES-1:0][31:0] fsgnj_res;    // result of sign injection
    for (genvar i = 0; i < NUM_LANES; ++i) begin
        always @(*) begin
            case (op_mod_s0[1:0])
                0: fsgnj_res[i] = { b_sign_s0[i], a_exponent_s0[i], a_mantissa_s0[i]};
                1: fsgnj_res[i] = {~b_sign_s0[i], a_exponent_s0[i], a_mantissa_s0[i]};
          default: fsgnj_res[i] = { a_sign_s0[i] ^ b_sign_s0[i], a_exponent_s0[i], a_mantissa_s0[i]};
            endcase
        end
    end

    // Comparison    
    reg [NUM_LANES-1:0][31:0] fcmp_res;  // result of comparison
    reg [NUM_LANES-1:0] fcmp_fflags_NV;  // comparison fflags
    for (genvar i = 0; i < NUM_LANES; ++i) begin
        always @(*) begin
            case (op_mod_s0[1:0])
                `INST_FRM_RNE: begin // LE                    
                    if (a_fclass_s0[i].is_nan || b_fclass_s0[i].is_nan) begin
                        fcmp_res[i]       = 32'h0;
                        fcmp_fflags_NV[i] = 1'b1;
                    end else begin
                        fcmp_res[i] = {31'h0, (a_smaller_s0[i] | ab_equal_s0[i])};
                        fcmp_fflags_NV[i] = 1'b0;
                    end
                end
                `INST_FRM_RTZ: begin // LS
                    if (a_fclass_s0[i].is_nan || b_fclass_s0[i].is_nan) begin
                        fcmp_res[i]       = 32'h0;
                        fcmp_fflags_NV[i] = 1'b1;
                    end else begin
                        fcmp_res[i] = {31'h0, (a_smaller_s0[i] & ~ab_equal_s0[i])};
                        fcmp_fflags_NV[i] = 1'b0;
                    end                    
                end
                `INST_FRM_RDN: begin // EQ
                    if (a_fclass_s0[i].is_nan || b_fclass_s0[i].is_nan) begin
                        fcmp_res[i]       = 32'h0;
                        fcmp_fflags_NV[i] = a_fclass_s0[i].is_signaling | b_fclass_s0[i].is_signaling; 
                    end else begin
                        fcmp_res[i] = {31'h0, ab_equal_s0[i]};
                        fcmp_fflags_NV[i] = 1'b0;
                    end
                end
                default: begin
                    fcmp_res[i]       = 'x;
                    fcmp_fflags_NV[i] = 'x;                        
                end
            endcase
        end
    end

    // outputs

    reg [NUM_LANES-1:0][31:0] tmp_result;
    reg [NUM_LANES-1:0] tmp_fflags_NV;

    for (genvar i = 0; i < NUM_LANES; ++i) begin
        always @(*) begin 
            case (op_mod_s0)
                0,1,2: begin
                    // SGNJ
                    tmp_result[i] = fsgnj_res[i];
                    tmp_fflags_NV[i] = 'x;
                end
                3: begin
                    // CLASS
                    tmp_result[i] = fclass_mask[i];
                    tmp_fflags_NV[i] = 'x;
                end
                4,5: begin
                    // FMV
                    tmp_result[i] = dataa_s0[i];
                    tmp_fflags_NV[i] = 'x;
                end                
                6,7: begin
                    // MIN/MAX
                    tmp_result[i] = fminmax_res[i];
                    tmp_fflags_NV[i] = a_fclass_s0[i].is_signaling | b_fclass_s0[i].is_signaling;
                end                
            default: begin
                    // CMP (8, 9, 10)
                    tmp_result[i] = fcmp_res[i];
                    tmp_fflags_NV[i] = fcmp_fflags_NV[i];
                end
            endcase
        end
    end

    wire has_fflags_s0 = (op_mod_s0 >= 6);

    assign stall = ~ready_out && valid_out;

    wire [NUM_LANES-1:0] fflags_NV;

    VX_pipe_register #(
        .DATAW  (1 + TAGW + (NUM_LANES * 32) + 1 + (NUM_LANES * 1)),
        .RESETW (1)
    ) pipe_reg1 (
        .clk      (clk),
        .reset    (reset),
        .enable   (!stall),
        .data_in  ({valid_in_s0, tag_in_s0, tmp_result, has_fflags_s0, tmp_fflags_NV}),
        .data_out ({valid_out,   tag_out,   result,     has_fflags,    fflags_NV})
    );

    assign ready_in = ~stall;

    for (genvar i = 0; i < NUM_LANES; ++i) begin
                           // NV,         DZ,   OF,   UF,   NX
        assign fflags[i] = {fflags_NV[i], 1'b0, 1'b0, 1'b0, 1'b0};
    end

endmodule