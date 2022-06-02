`include "VX_define.vh"

module VX_dispatch (
    input wire              clk,
    input wire              reset,

    // inputs
    VX_dispatch_if.slave    dispatch_if,
    VX_gpr_rsp_if.slave     gpr_rsp_if,

    // outputs
    VX_alu_req_if.master    alu_req_if,
    VX_lsu_req_if.master    lsu_req_if,
    VX_csr_req_if.master    csr_req_if,
`ifdef EXT_F_ENABLE
    VX_fpu_req_if.master    fpu_req_if,
`endif
    VX_gpu_req_if.master    gpu_req_if    
);
    wire [`NT_BITS-1:0] tid;
    wire alu_req_ready;
    wire lsu_req_ready;
    wire csr_req_ready;
`ifdef EXT_F_ENABLE
    wire fpu_req_ready;
`endif
    wire gpu_req_ready;

    VX_lzc #(
        .N       (`NUM_THREADS),
        .REVERSE (1)
    ) tid_select (
        .data_in  (dispatch_if.tmask),
        .data_out (tid),
        `UNUSED_PIN (valid_out)
    );

    wire [31:0] next_PC = dispatch_if.PC + 4;

    // ALU unit

    wire alu_req_valid = dispatch_if.valid && (dispatch_if.ex_type == `EX_ALU);
    wire [`INST_ALU_BITS-1:0] alu_op_type = `INST_ALU_BITS'(dispatch_if.op_type);
    
    VX_skid_buffer #(
        .DATAW   (`UUID_BITS + `NW_BITS + `NUM_THREADS + 32 + 32 + `INST_ALU_BITS + `INST_MOD_BITS + 32 + 1 + 1 + `NR_BITS + 1 + `NT_BITS + (2 * `NUM_THREADS * 32)),
        .OUT_REG (1)
    ) alu_buffer (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (alu_req_valid),
        .ready_in  (alu_req_ready),
        .data_in   ({dispatch_if.uuid, dispatch_if.wid, dispatch_if.tmask, dispatch_if.PC, next_PC,            alu_op_type,        dispatch_if.op_mod, dispatch_if.imm, dispatch_if.use_PC, dispatch_if.use_imm, dispatch_if.rd, dispatch_if.wb, tid,            gpr_rsp_if.rs1_data, gpr_rsp_if.rs2_data}),
        .data_out  ({alu_req_if.uuid,  alu_req_if.wid,  alu_req_if.tmask,  alu_req_if.PC,  alu_req_if.next_PC, alu_req_if.op_type, alu_req_if.op_mod,  alu_req_if.imm,  alu_req_if.use_PC,  alu_req_if.use_imm,  alu_req_if.rd,  alu_req_if.wb,  alu_req_if.tid, alu_req_if.rs1_data, alu_req_if.rs2_data}),
        .valid_out (alu_req_if.valid),
        .ready_out (alu_req_if.ready)
    );

    // lsu unit

    wire lsu_req_valid = dispatch_if.valid && (dispatch_if.ex_type == `EX_LSU);
    wire [`INST_LSU_BITS-1:0] lsu_op_type = `INST_LSU_BITS'(dispatch_if.op_type);
    wire lsu_is_fence = `INST_LSU_IS_FENCE(dispatch_if.op_mod);

    VX_skid_buffer #(
        .DATAW   (`UUID_BITS + `NW_BITS + `NUM_THREADS + 32 + `INST_LSU_BITS + 1 + 32 + `NR_BITS + 1 + (2 * `NUM_THREADS * 32)),
        .OUT_REG (1)
    ) lsu_buffer (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (lsu_req_valid),
        .ready_in  (lsu_req_ready),
        .data_in   ({dispatch_if.uuid, dispatch_if.wid, dispatch_if.tmask, dispatch_if.PC, lsu_op_type,        lsu_is_fence,        dispatch_if.imm,   dispatch_if.rd, dispatch_if.wb, gpr_rsp_if.rs1_data,  gpr_rsp_if.rs2_data}),
        .data_out  ({lsu_req_if.uuid,  lsu_req_if.wid,  lsu_req_if.tmask,  lsu_req_if.PC,  lsu_req_if.op_type, lsu_req_if.is_fence, lsu_req_if.offset, lsu_req_if.rd,  lsu_req_if.wb,  lsu_req_if.base_addr, lsu_req_if.store_data}),
        .valid_out (lsu_req_if.valid),
        .ready_out (lsu_req_if.ready)
    );

    // csr unit

    wire csr_req_valid = dispatch_if.valid && (dispatch_if.ex_type == `EX_CSR);
    wire [`INST_CSR_BITS-1:0] csr_op_type = `INST_CSR_BITS'(dispatch_if.op_type);
    wire [`CSR_ADDR_BITS-1:0] csr_addr = dispatch_if.imm[`CSR_ADDR_BITS-1:0];
    wire [`NRI_BITS-1:0] csr_imm = dispatch_if.imm[`CSR_ADDR_BITS +: `NRI_BITS];

    VX_skid_buffer #(
        .DATAW   (`UUID_BITS + `NW_BITS + `NUM_THREADS + 32 + `INST_CSR_BITS + `CSR_ADDR_BITS + `NR_BITS + 1 + 1 + `NRI_BITS + `NT_BITS + (`NUM_THREADS * 32)),
        .OUT_REG (1)
    ) csr_buffer (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (csr_req_valid),
        .ready_in  (csr_req_ready),
        .data_in   ({dispatch_if.uuid, dispatch_if.wid, dispatch_if.tmask, dispatch_if.PC, csr_op_type,        csr_addr,        dispatch_if.rd, dispatch_if.wb, dispatch_if.use_imm, csr_imm,        tid,            gpr_rsp_if.rs1_data}),
        .data_out  ({csr_req_if.uuid,  csr_req_if.wid,  csr_req_if.tmask,  csr_req_if.PC,  csr_req_if.op_type, csr_req_if.addr, csr_req_if.rd,  csr_req_if.wb,  csr_req_if.use_imm,  csr_req_if.imm, csr_req_if.tid, csr_req_if.rs1_data}),
        .valid_out (csr_req_if.valid),
        .ready_out (csr_req_if.ready)
    );

    // fpu unit

`ifdef EXT_F_ENABLE
    wire fpu_req_valid = dispatch_if.valid && (dispatch_if.ex_type == `EX_FPU);
    wire [`INST_FPU_BITS-1:0] fpu_op_type = `INST_FPU_BITS'(dispatch_if.op_type);
        
    VX_skid_buffer #(
        .DATAW   (`UUID_BITS + `NW_BITS + `NUM_THREADS + 32 + `INST_FPU_BITS + `INST_MOD_BITS + `NR_BITS + 1 + (3 * `NUM_THREADS * 32)),
        .OUT_REG (1)
    ) fpu_buffer (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (fpu_req_valid),
        .ready_in  (fpu_req_ready),
        .data_in   ({dispatch_if.uuid, dispatch_if.wid, dispatch_if.tmask, dispatch_if.PC, fpu_op_type,        dispatch_if.op_mod, dispatch_if.rd, dispatch_if.wb, gpr_rsp_if.rs1_data, gpr_rsp_if.rs2_data, gpr_rsp_if.rs3_data}),
        .data_out  ({fpu_req_if.uuid,  fpu_req_if.wid,  fpu_req_if.tmask,  fpu_req_if.PC,  fpu_req_if.op_type, fpu_req_if.op_mod,  fpu_req_if.rd,  fpu_req_if.wb,  fpu_req_if.rs1_data, fpu_req_if.rs2_data, fpu_req_if.rs3_data}),
        .valid_out (fpu_req_if.valid),
        .ready_out (fpu_req_if.ready)
    );
`else
    `UNUSED_VAR (gpr_rsp_if.rs3_data)
`endif

    // gpu unit

    wire gpu_req_valid = dispatch_if.valid && (dispatch_if.ex_type == `EX_GPU);
    wire [`INST_GPU_BITS-1:0] gpu_op_type = `INST_GPU_BITS'(dispatch_if.op_type);

    VX_skid_buffer #(
        .DATAW   (`UUID_BITS + `NW_BITS + `NUM_THREADS + 32 + 32 + `INST_GPU_BITS + `INST_MOD_BITS + `NR_BITS + 1 + `NT_BITS  + (3 * `NUM_THREADS * 32)),
        .OUT_REG (1)
    ) gpu_buffer (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (gpu_req_valid),
        .ready_in  (gpu_req_ready),
        .data_in   ({dispatch_if.uuid, dispatch_if.wid, dispatch_if.tmask, dispatch_if.PC, next_PC,            gpu_op_type,        dispatch_if.op_mod, dispatch_if.rd, dispatch_if.wb, tid,            gpr_rsp_if.rs1_data, gpr_rsp_if.rs2_data, gpr_rsp_if.rs3_data}),
        .data_out  ({gpu_req_if.uuid,  gpu_req_if.wid,  gpu_req_if.tmask,  gpu_req_if.PC,  gpu_req_if.next_PC, gpu_req_if.op_type, gpu_req_if.op_mod,  gpu_req_if.rd,  gpu_req_if.wb,  gpu_req_if.tid, gpu_req_if.rs1_data, gpu_req_if.rs2_data, gpu_req_if.rs3_data}),
        .valid_out (gpu_req_if.valid),
        .ready_out (gpu_req_if.ready)
    ); 

    // can take next request?
    reg ready_r;
    always @(*) begin
        case (dispatch_if.ex_type) 
        `EX_ALU: ready_r = alu_req_ready;
        `EX_LSU: ready_r = lsu_req_ready;
        `EX_CSR: ready_r = csr_req_ready;
    `ifdef EXT_F_ENABLE
        `EX_FPU: ready_r = fpu_req_ready;
    `endif
        `EX_GPU: ready_r = gpu_req_ready;
        default: ready_r = 1'b1; // ignore NOPs
        endcase
    end
    assign dispatch_if.ready = ready_r;
    
endmodule
