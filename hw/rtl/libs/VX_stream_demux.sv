`include "VX_platform.vh"

module VX_stream_demux #(
    parameter NUM_REQS      = 1,
    parameter LANES         = 1,
    parameter DATAW         = 1,
    parameter ARBITER       = "",
    parameter LOCK_ENABLE   = 1,
    parameter BUFFERED      = 0    
) (
    input  wire clk,
    input  wire reset,

    input wire [LANES-1:0][`UP(LOG_NUM_REQS)-1:0] sel_in,

    input  wire [LANES-1:0]            valid_in,
    input  wire [LANES-1:0][DATAW-1:0] data_in,    
    output wire [LANES-1:0]            ready_in,

    output wire [NUM_REQS-1:0][LANES-1:0]            valid_out,
    output wire [NUM_REQS-1:0][LANES-1:0][DATAW-1:0] data_out,
    input  wire [NUM_REQS-1:0][LANES-1:0]            ready_out
  );

    parameter LOG_NUM_REQS = `LOG2UP(NUM_REQS);
  
    if (NUM_REQS > 1)  begin

        wire [LANES-1:0] sel_fire = valid_in & ready_in; 

        wire [NUM_REQS-1:0][LANES-1:0] sel_ready;
        
        wire [LANES-1:0][LOG_NUM_REQS-1:0] sel_index;
        wire [LANES-1:0][NUM_REQS-1:0]     sel_onehot;

        if (ARBITER != "") begin   
            `UNUSED_VAR (sel_in)        
            wire [NUM_REQS-1:0]     arb_requests;
            wire [LOG_NUM_REQS-1:0] arb_index;
            wire [NUM_REQS-1:0]     arb_onehot;
            wire                    arb_enable;

            if (LANES > 1) begin
                for (genvar i = 0; i < NUM_REQS; i++) begin
                    assign arb_requests[i] = (| sel_ready[i]);
                end
                assign arb_enable = (| sel_fire);
            end else begin
                for (genvar i = 0; i < NUM_REQS; i++) begin
                    assign arb_requests[i] = sel_ready[i];
                end
                assign arb_enable = sel_fire;
            end

            VX_generic_arbiter #(
                .NUM_REQS    (NUM_REQS),
                .LOCK_ENABLE (1),
                .TYPE        (ARBITER)
            ) arb (
                .clk          (clk),
                .reset        (reset),
                .requests     (arb_requests),  
                .enable       (arb_enable),
                `UNUSED_PIN (grant_valid),
                .grant_index  (arb_index),
                .grant_onehot (arb_onehot)
            );

            for (genvar i = 0; i < LANES; i++) begin
                assign sel_index[i] = arb_index;
                assign sel_onehot[i] = arb_onehot;
            end            
        end else begin
            `UNUSED_VAR (sel_fire)
            assign sel_index = sel_in;
            reg [LANES-1:0][NUM_REQS-1:0] sel_onehot_r;
            always @(*) begin
                for (integer i = 0; i < LANES; ++i) begin
                    sel_onehot_r[i]            = '0;
                    sel_onehot_r[i][sel_in[i]] = 1;
                end
            end
            assign sel_onehot = sel_onehot_r;
        end

        for (genvar j = 0; j < LANES; ++j) begin

            assign ready_in[j] = sel_ready[sel_index[j]][j]; 

            for (genvar i = 0; i < NUM_REQS; i++) begin

                wire sel_valid = valid_in[j] & sel_onehot[j][i];

                VX_skid_buffer #(
                    .DATAW    (DATAW),
                    .PASSTHRU (0 == BUFFERED),
                    .OUT_REG  (2 == BUFFERED)
                ) out_buffer (
                    .clk       (clk),
                    .reset     (reset),
                    .valid_in  (sel_valid),        
                    .data_in   (data_in[j]),
                    .ready_in  (sel_ready[i][j]),      
                    .valid_out (valid_out[i][j]),
                    .data_out  (data_out[i][j]),
                    .ready_out (ready_out[i][j])
                );
            end
        end

    end else begin

        `UNUSED_VAR (clk)
        `UNUSED_VAR (reset)
        `UNUSED_VAR (sel_in)
        
        assign valid_out = valid_in;        
        assign data_out  = data_in;
        assign ready_in  = ready_out;

    end
    
endmodule
