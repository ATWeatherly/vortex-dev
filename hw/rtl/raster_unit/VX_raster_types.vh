`ifndef VX_RASTER_TYPES
`define VX_RASTER_TYPES

`include "VX_define.vh"

package raster_types;

typedef struct packed {
    logic [`RASTER_DCR_DATA_BITS-1:0]    tbuf_addr;      // Tile buffer address
    logic [`RASTER_DCR_DATA_BITS-1:0]    tile_count;     // Number of tiles in the tile buffer
    logic [`RASTER_DCR_DATA_BITS-1:0]    pbuf_addr;      // Primitive (triangle) data buffer start address
    logic [`RASTER_DCR_DATA_BITS-1:0]    pbuf_stride;    // Primitive data stride to fetch vertices
} raster_dcrs_t;

typedef struct packed {
    logic [15:0]      pos_x;
    logic [15:0]      pos_y;
    logic [3:0]       mask;
    logic [3:0][31:0] bcoord_x;
    logic [3:0][31:0] bcoord_y;
    logic [3:0][31:0] bcoord_z;
    logic [15:0]      pid;
} raster_stamp_t;

typedef struct packed {
    raster_stamp_t  stamp;
    logic [1:0]     frag;
    logic [31:0]    grad_x;
    logic [31:0]    grad_y;    
} raster_csrs_t;

endpackage

`endif