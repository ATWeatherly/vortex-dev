`include "VX_define.vh"

interface VX_cmt_to_csr_if ();

    wire [`PERF_CTR_BITS-1:0] instret;

    modport master (
        output instret
    );

    modport slave (
        input  instret
    );

endinterface
