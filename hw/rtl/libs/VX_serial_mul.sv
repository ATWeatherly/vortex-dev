`include "VX_platform.vh"

// Iterative integer multiplier 
// An adaptation of ZipCPU algorithm for a multi-lane elastic architecture.
// https://zipcpu.com/zipcpu/2021/07/03/slowmpy.html

`TRACING_OFF
module VX_serial_mul #(
    parameter A_WIDTH = 1,
    parameter B_WIDTH = A_WIDTH,
    parameter R_WIDTH = A_WIDTH + B_WIDTH,
    parameter SIGNED  = 0,
    parameter LANES   = 1
) (
    input wire                          clk,
    input wire                          reset,

    input wire                          valid_in,
    output wire                         ready_in,
        
    input wire                          ready_out,
    output wire                         valid_out,

    input wire [LANES-1:0][A_WIDTH-1:0] dataa,
    input wire [LANES-1:0][B_WIDTH-1:0] datab,
    output wire [LANES-1:0][R_WIDTH-1:0] result
);
    localparam X_WIDTH = SIGNED ? `MAX(A_WIDTH, B_WIDTH) : A_WIDTH;
    localparam Y_WIDTH = SIGNED ? `MAX(A_WIDTH, B_WIDTH) : B_WIDTH;
    localparam P_WIDTH = X_WIDTH + Y_WIDTH;

    localparam CNTRW = $clog2(X_WIDTH);

    reg [LANES-1:0][X_WIDTH-1:0] a;
	reg [LANES-1:0][Y_WIDTH-1:0] b;
	reg [LANES-1:0][P_WIDTH-1:0] p;

    reg [CNTRW-1:0] cntr;
    reg busy, done;

    wire push = valid_in && ready_in;
    wire pop = valid_out && ready_out;

    always @(posedge clk) begin
        if (reset) begin
            busy  <= 0;
            done  <= 0;
        end else begin
            if (push) begin
                busy <= 1;
            end
            if (busy && cntr == 0) begin
                done <= 1;
            end
            if (pop) begin                
                busy <= 0;
                done <= 0;
            end
        end
        cntr <= cntr - CNTRW'(1);
        if (push) begin
            cntr <= CNTRW'(X_WIDTH-1);
        end
    end

    for (genvar i = 0; i < LANES; ++i) begin
        wire [X_WIDTH-1:0] axb = b[i][0] ? a[i] : '0;

        always @(posedge clk) begin
            if (push) begin
                if (SIGNED) begin
                    a[i] <= X_WIDTH'($signed(dataa[i]));
                    b[i] <= Y_WIDTH'($signed(datab[i]));
                end else begin			
                    a[i] <= dataa[i];
                    b[i] <= datab[i];
                end
                p[i] <= 0;
            end else if (busy) begin			
                b[i] <= (b[i] >> 1);
                p[i][Y_WIDTH-2:0] <= p[i][Y_WIDTH-1:1];
                if (SIGNED) begin
                    if (cntr == 0) begin
                        p[i][P_WIDTH-1:Y_WIDTH-1] <= {1'b0, p[i][P_WIDTH-1:Y_WIDTH]} + {1'b0, axb[X_WIDTH-1], ~axb[X_WIDTH-2:0]};
                    end else begin
                        p[i][P_WIDTH-1:Y_WIDTH-1] <= {1'b0, p[i][P_WIDTH-1:Y_WIDTH]} + {1'b0, ~axb[X_WIDTH-1], axb[X_WIDTH-2:0]};
                    end
                end else begin
                    p[i][P_WIDTH-1:Y_WIDTH-1] <= {1'b0, p[i][P_WIDTH-1:Y_WIDTH]} + ((b[i][0]) ? {1'b0, a[i]} : 0);
                end
            end
        end

        if (SIGNED) begin
            assign result[i] = R_WIDTH'(p[i][P_WIDTH-1:0] + {1'b1, {(X_WIDTH-2){1'b0}}, 1'b1, {(Y_WIDTH){1'b0}}});
        end else begin
            assign result[i] = R_WIDTH'(p[i]);
        end
    end
    `UNUSED_VAR (p)

    assign ready_in  = ~busy && ~done;
    assign valid_out = done;

endmodule
`TRACING_ON
