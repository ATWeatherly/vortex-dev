`ifndef VX_RASTER_DCR_IF
`define VX_RASTER_DCR_IF

`include "VX_raster_define.vh"

interface VX_raster_dcr_if ();

    raster_dcrs_t data;

    modport master (
        output data
    );

    modport slave (
        input data
    );

endinterface

`endif
