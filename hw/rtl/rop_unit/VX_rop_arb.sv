`include "VX_rop_define.vh"

module VX_rop_arb #(
    parameter NUM_INPUTS     = 1,
    parameter NUM_OUTPUTS    = 1,
    parameter NUM_LANES      = 1,
    parameter BUFFERED       = 0,
    parameter string ARBITER = "R"
) (
    input wire              clk,
    input wire              reset,

    // input requests    
    VX_rop_req_if.slave     req_in_if [NUM_INPUTS],

    // output request
    VX_rop_req_if.master    req_out_if [NUM_OUTPUTS]
);

    localparam REQ_DATAW = `UP(`UUID_BITS) + NUM_LANES * (1 + 2 * `ROP_DIM_BITS + $bits(rgba_t) + `ROP_DEPTH_BITS + 1);

    wire [NUM_INPUTS-1:0]                 req_valid_in;
    wire [NUM_INPUTS-1:0][REQ_DATAW-1:0]  req_data_in;
    wire [NUM_INPUTS-1:0]                 req_ready_in;    
    
    wire [NUM_OUTPUTS-1:0]                req_valid_out;
    wire [NUM_OUTPUTS-1:0][REQ_DATAW-1:0] req_data_out;
    wire [NUM_OUTPUTS-1:0]                req_ready_out;

    for (genvar i = 0; i < NUM_INPUTS; ++i) begin
        assign req_valid_in[i] = req_in_if[i].valid;
        assign req_data_in[i] = {req_in_if[i].uuid, req_in_if[i].mask, req_in_if[i].pos_x, req_in_if[i].pos_y, req_in_if[i].color, req_in_if[i].depth, req_in_if[i].face};
        assign req_in_if[i].ready = req_ready_in[i];
    end

    VX_stream_arb #(            
        .NUM_INPUTS (NUM_INPUTS),
        .NUM_OUTPUTS(NUM_OUTPUTS),
        .DATAW      (REQ_DATAW),
        .ARBITER    (ARBITER),
        .BUFFERED   (BUFFERED),
        .MAX_FANOUT (4)
    ) req_arb (
        .clk        (clk),
        .reset      (reset),
        .valid_in   (req_valid_in),
        .ready_in   (req_ready_in),
        .data_in    (req_data_in),
        .data_out   (req_data_out),
        .valid_out  (req_valid_out),
        .ready_out  (req_ready_out)
    );
    
    for (genvar i = 0; i < NUM_OUTPUTS; ++i) begin
        assign req_out_if[i].valid = req_valid_out[i];
        assign {req_out_if[i].uuid, req_out_if[i].mask, req_out_if[i].pos_x, req_out_if[i].pos_y, req_out_if[i].color, req_out_if[i].depth, req_out_if[i].face} = req_data_out[i];
        assign req_ready_out[i] = req_out_if[i].ready;
    end

endmodule
