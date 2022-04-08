`include "VX_raster_define.vh"

interface VX_raster_perf_if ();

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
