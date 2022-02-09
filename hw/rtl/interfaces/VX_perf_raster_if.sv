`ifndef VX_PERF_RASTER_IF
`define VX_PERF_RASTER_IF

`include "VX_define.vh"

interface VX_perf_raster_if ();

    wire [`PERF_CTR_BITS-1:0] mem_reads;
    wire [`PERF_CTR_BITS-1:0] mem_latency;

    modport master (
        output mem_reads,
        output mem_latency
    );

    modport slave (
        input mem_reads,
        input mem_latency
    );

endinterface

`endif