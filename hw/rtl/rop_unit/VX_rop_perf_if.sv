`include "VX_rop_define.vh"

import VX_rop_types::*;

interface VX_rop_perf_if ();

    wire [`PERF_CTR_BITS-1:0] mem_reads;
    wire [`PERF_CTR_BITS-1:0] mem_writes;
    wire [`PERF_CTR_BITS-1:0] mem_latency;

    modport master (
        output mem_reads,
        output mem_writes,
        output mem_latency
    );

    modport slave (
        input mem_reads,
        input mem_writes,
        input mem_latency
    );

endinterface
