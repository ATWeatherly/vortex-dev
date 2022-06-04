`include "VX_define.vh"

module VX_cache_arb #(    
    parameter NUM_INPUTS     = 1, 
    parameter NUM_OUTPUTS    = 1,
    parameter NUM_LANES      = 1,
    parameter DATA_SIZE      = 1,
    parameter TAG_WIDTH      = 1,
    parameter TAG_SEL_IDX    = 0,   
    parameter BUFFERED_REQ   = 0,
    parameter BUFFERED_RSP   = 0,
    parameter string ARBITER = "R"
) (
    input wire              clk,
    input wire              reset,

    // input requests        
    VX_cache_req_if.slave   req_in_if [NUM_INPUTS],

    // input responses
    VX_cache_rsp_if.master  rsp_in_if [NUM_INPUTS],
    
    // output request
    VX_cache_req_if.master  req_out_if [NUM_OUTPUTS],

    // output response
    VX_cache_rsp_if.slave   rsp_out_if [NUM_OUTPUTS]
);     

    localparam ADDR_WIDTH    = (32-`CLOG2(DATA_SIZE));
    localparam DATA_WIDTH    = (8 * DATA_SIZE);
    localparam LOG_NUM_REQS  = `ARB_SEL_BITS(NUM_INPUTS, NUM_OUTPUTS);
    localparam TAG_OUT_WIDTH = TAG_WIDTH + LOG_NUM_REQS;    
    localparam REQ_DATAW = TAG_OUT_WIDTH + ADDR_WIDTH + 1 + DATA_SIZE + DATA_WIDTH;
    localparam RSP_DATAW = TAG_WIDTH + DATA_WIDTH;

    `STATIC_ASSERT ((NUM_INPUTS >= NUM_OUTPUTS), ("invalid parameter"))

    wire [NUM_INPUTS-1:0][NUM_LANES-1:0]                 req_valid_in;
    wire [NUM_INPUTS-1:0][NUM_LANES-1:0][REQ_DATAW-1:0]  req_data_in;
    wire [NUM_INPUTS-1:0][NUM_LANES-1:0]                 req_ready_in;
    
    wire [NUM_OUTPUTS-1:0][NUM_LANES-1:0]                req_valid_out;
    wire [NUM_OUTPUTS-1:0][NUM_LANES-1:0][REQ_DATAW-1:0] req_data_out;
    wire [NUM_OUTPUTS-1:0][NUM_LANES-1:0]                req_ready_out;

    for (genvar i = 0; i < NUM_INPUTS; ++i) begin
        for (genvar j = 0; j < NUM_LANES; ++j) begin

            assign req_valid_in[i][j] = req_in_if[i].valid[j];
            assign req_in_if[i].ready[j] = req_ready_in[i][j];

            if (NUM_INPUTS > NUM_OUTPUTS) begin
                wire [TAG_OUT_WIDTH-1:0] req_tag_in;
                localparam r = i / NUM_OUTPUTS;
                VX_bits_insert #( 
                    .N   (TAG_WIDTH),
                    .S   (LOG_NUM_REQS),
                    .POS (TAG_SEL_IDX)
                ) bits_insert (
                    .data_in  (req_in_if[i].tag[j]),
                    .sel_in   (LOG_NUM_REQS'(r)),
                    .data_out (req_tag_in)
                );
                assign req_data_in[i][j] = {req_tag_in, req_in_if[i].addr[j], req_in_if[i].rw[j], req_in_if[i].byteen[j], req_in_if[i].data[j]};
            end else begin
                assign req_data_in[i][j] = {req_in_if[i].tag[j], req_in_if[i].addr[j], req_in_if[i].rw[j], req_in_if[i].byteen[j], req_in_if[i].data[j]};
            end            
        end
    end

    VX_stream_arb #(            
        .NUM_INPUTS (NUM_INPUTS),
        .NUM_LANES  (NUM_LANES),
        .DATAW      (REQ_DATAW),
        .BUFFERED   (BUFFERED_REQ),
        .ARBITER    (ARBITER)
    ) req_arb (
        .clk       (clk),
        .reset     (reset),
        .valid_in  (req_valid_in),
        .data_in   (req_data_in),
        .ready_in  (req_ready_in),
        .valid_out (req_valid_out),
        .data_out  (req_data_out),
        .ready_out (req_ready_out)
    );

    for (genvar i = 0; i < NUM_OUTPUTS; ++i) begin
        for (genvar j = 0; j < NUM_LANES; ++j) begin
            assign req_out_if[i].valid[j] = req_valid_out[i][j];
            assign {req_out_if[i].tag[j], req_out_if[i].addr[j], req_out_if[i].rw[j], req_out_if[i].byteen[j], req_out_if[i].data[j]} = req_data_out[i][j];
            assign req_ready_out[i][j] = req_out_if[i].ready[j];
        end
    end

    ///////////////////////////////////////////////////////////////////////////

     for (genvar i = 0; i < NUM_LANES; ++i) begin

        wire [NUM_INPUTS-1:0]                 rsp_valid_out;
        wire [NUM_INPUTS-1:0][RSP_DATAW-1:0]  rsp_data_out;
        wire [NUM_INPUTS-1:0]                 rsp_ready_out;

        wire [NUM_OUTPUTS-1:0]                rsp_valid_in;
        wire [NUM_OUTPUTS-1:0][RSP_DATAW-1:0] rsp_data_in;
        wire [NUM_OUTPUTS-1:0]                rsp_ready_in;

        if (NUM_INPUTS > NUM_OUTPUTS) begin

            wire [NUM_OUTPUTS-1:0][LOG_NUM_REQS-1:0] rsp_sel_in;

            for (genvar j = 0; j < NUM_OUTPUTS; ++j) begin
                wire [TAG_WIDTH-1:0] rsp_tag_out;

                VX_bits_remove #( 
                    .N   (TAG_OUT_WIDTH),
                    .S   (LOG_NUM_REQS),
                    .POS (TAG_SEL_IDX)
                ) bits_remove (
                    .data_in  (rsp_out_if[j].tag[i]),
                    .data_out (rsp_tag_out)
                );

                assign rsp_valid_in[j] = rsp_out_if[j].valid[i];
                assign rsp_data_in[j] = {rsp_tag_out, rsp_out_if[j].data[i]};
                assign rsp_out_if[j].ready[i] = rsp_ready_in[j];

                if (NUM_INPUTS > 1) begin
                    assign rsp_sel_in[j] = rsp_out_if[j].tag[i][TAG_SEL_IDX +: LOG_NUM_REQS];
                end else begin
                    assign rsp_sel_in[j] = 0;
                end
            end        

            VX_stream_switch #(
                .NUM_INPUTS  (NUM_OUTPUTS),
                .NUM_OUTPUTS (NUM_INPUTS),        
                .DATAW       (RSP_DATAW),
                .BUFFERED    (BUFFERED_RSP)
            ) rsp_switch (
                .clk       (clk),
                .reset     (reset),
                .sel_in    (rsp_sel_in),
                .valid_in  (rsp_valid_in),
                .data_in   (rsp_data_in),
                .ready_in  (rsp_ready_in),
                .valid_out (rsp_valid_out),
                .data_out  (rsp_data_out),
                .ready_out (rsp_ready_out)
            );

        end else begin
            
            for (genvar j = 0; j < NUM_OUTPUTS; ++j) begin
                assign rsp_valid_in[j] = rsp_out_if[j].valid[i];
                assign rsp_data_in[j] = {rsp_out_if[j].tag[i], rsp_out_if[j].data[i]};
                assign rsp_out_if[j].ready[i] = rsp_ready_in[j];
            end

            VX_stream_arb #(            
                .NUM_INPUTS  (NUM_OUTPUTS),
                .NUM_OUTPUTS (NUM_INPUTS),
                .DATAW       (RSP_DATAW),
                .BUFFERED    (BUFFERED_RSP),
                .ARBITER     (ARBITER)
            ) req_arb (
                .clk       (clk),
                .reset     (reset),
                .valid_in  (rsp_valid_in),
                .data_in   (rsp_data_in),
                .ready_in  (rsp_ready_in),
                .valid_out (rsp_valid_out),
                .data_out  (rsp_data_out),
                .ready_out (rsp_ready_out)
            );

        end
        
        for (genvar j = 0; j < NUM_INPUTS; ++j) begin
            assign rsp_in_if[j].valid[i] = rsp_valid_out[j];
            assign {rsp_in_if[j].tag[i], rsp_in_if[j].data[i]} = rsp_data_out[j];
            assign rsp_ready_out[j] = rsp_in_if[j].ready[i];
        end
    end    

endmodule
