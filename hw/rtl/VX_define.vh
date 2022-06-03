`ifndef VX_DEFINE_VH
`define VX_DEFINE_VH

`include "VX_platform.vh"
`include "VX_config.vh"
`include "VX_types.vh"

///////////////////////////////////////////////////////////////////////////////

`define NW_BITS         `LOG2UP(`NUM_WARPS)

`define NT_BITS         `LOG2UP(`NUM_THREADS)

`define NC_BITS         `LOG2UP(`NUM_CORES)

`define NB_BITS         `LOG2UP(`NUM_BARRIERS)

`define NUM_IREGS       32

`define NRI_BITS        `LOG2UP(`NUM_IREGS)

`ifdef EXT_F_ENABLE
`define NUM_REGS        (2 * `NUM_IREGS)
`else
`define NUM_REGS        `NUM_IREGS
`endif

`define NR_BITS         `LOG2UP(`NUM_REGS)

`define CSR_ADDR_BITS   12

`define DCR_ADDR_BITS   12

`define PERF_CTR_BITS   44

`define UUID_BITS       44

///////////////////////////////////////////////////////////////////////////////

`define EX_NOP          3'h0
`define EX_ALU          3'h1
`define EX_LSU          3'h2
`define EX_CSR          3'h3
`define EX_FPU          3'h4
`define EX_GPU          3'h5
`define EX_BITS         3

///////////////////////////////////////////////////////////////////////////////

`define INST_LUI        7'b0110111
`define INST_AUIPC      7'b0010111
`define INST_JAL        7'b1101111
`define INST_JALR       7'b1100111
`define INST_B          7'b1100011 // branch instructions
`define INST_L          7'b0000011 // load instructions
`define INST_S          7'b0100011 // store instructions
`define INST_I          7'b0010011 // immediate instructions
`define INST_R          7'b0110011 // register instructions
`define INST_FENCE      7'b0001111 // Fence instructions
`define INST_SYS        7'b1110011 // system instructions

`define INST_FL         7'b0000111 // float load instruction
`define INST_FS         7'b0100111 // float store  instruction
`define INST_FMADD      7'b1000011  
`define INST_FMSUB      7'b1000111
`define INST_FNMSUB     7'b1001011
`define INST_FNMADD     7'b1001111 
`define INST_FCI        7'b1010011 // float common instructions

// Custom extension opcodes
`define INST_EXT1       7'b0001011 // 0x0B
`define INST_EXT2       7'b0101011 // 0x2B
`define INST_EXT3       7'b1011011 // 0x5B
`define INST_EXT4       7'b1111011 // 0x7B

///////////////////////////////////////////////////////////////////////////////

`define INST_FRM_RNE    3'b000  // round to nearest even
`define INST_FRM_RTZ    3'b001  // round to zero
`define INST_FRM_RDN    3'b010  // round to -inf
`define INST_FRM_RUP    3'b011  // round to +inf
`define INST_FRM_RMM    3'b100  // round to nearest max magnitude
`define INST_FRM_DYN    3'b111  // dynamic mode
`define INST_FRM_BITS   3

///////////////////////////////////////////////////////////////////////////////

`define INST_OP_BITS    4
`define INST_MOD_BITS   3

///////////////////////////////////////////////////////////////////////////////

`define INST_ALU_ADD         4'b0000
`define INST_ALU_LUI         4'b0010
`define INST_ALU_AUIPC       4'b0011
`define INST_ALU_SLTU        4'b0100
`define INST_ALU_SLT         4'b0101
`define INST_ALU_SRL         4'b1000
`define INST_ALU_SRA         4'b1001
`define INST_ALU_SUB         4'b1011
`define INST_ALU_AND         4'b1100
`define INST_ALU_OR          4'b1101
`define INST_ALU_XOR         4'b1110
`define INST_ALU_SLL         4'b1111
`define INST_ALU_OTHER       4'b0111
`define INST_ALU_BITS        4
`define INST_ALU_OP(x)       x[`INST_ALU_BITS-1:0]
`define INST_ALU_OP_CLASS(x) x[3:2]
`define INST_ALU_SIGNED(x)   x[0]
`define INST_ALU_IS_BR(x)    x[0]
`define INST_ALU_IS_MUL(x)   x[1]

`define INST_BR_EQ           4'b0000
`define INST_BR_NE           4'b0010
`define INST_BR_LTU          4'b0100 
`define INST_BR_GEU          4'b0110 
`define INST_BR_LT           4'b0101
`define INST_BR_GE           4'b0111
`define INST_BR_JAL          4'b1000
`define INST_BR_JALR         4'b1001
`define INST_BR_ECALL        4'b1010
`define INST_BR_EBREAK       4'b1011
`define INST_BR_URET         4'b1100
`define INST_BR_SRET         4'b1101
`define INST_BR_MRET         4'b1110
`define INST_BR_OTHER        4'b1111
`define INST_BR_BITS         4
`define INST_BR_NEG(x)       x[1]
`define INST_BR_LESS(x)      x[2]
`define INST_BR_STATIC(x)    x[3]

`define INST_MUL_MUL         3'h0
`define INST_MUL_MULH        3'h1
`define INST_MUL_MULHSU      3'h2
`define INST_MUL_MULHU       3'h3
`define INST_MUL_DIV         3'h4
`define INST_MUL_DIVU        3'h5
`define INST_MUL_REM         3'h6
`define INST_MUL_REMU        3'h7
`define INST_MUL_BITS        3
`define INST_MUL_IS_DIV(x)   x[2]

`define INST_FMT_B           3'b000
`define INST_FMT_H           3'b001
`define INST_FMT_W           3'b010
`define INST_FMT_BU          3'b100
`define INST_FMT_HU          3'b101

`define INST_LSU_LB          4'b0000 
`define INST_LSU_LH          4'b0001
`define INST_LSU_LW          4'b0010
`define INST_LSU_LBU         4'b0100
`define INST_LSU_LHU         4'b0101
`define INST_LSU_SB          4'b1000 
`define INST_LSU_SH          4'b1001
`define INST_LSU_SW          4'b1010
`define INST_LSU_BITS        4
`define INST_LSU_FMT(x)      x[2:0]
`define INST_LSU_WSIZE(x)    x[1:0]
`define INST_LSU_IS_MEM(x)   (3'h0 == x)
`define INST_LSU_IS_FENCE(x) (3'h1 == x)

`define INST_FENCE_BITS      1
`define INST_FENCE_D         1'h0
`define INST_FENCE_I         1'h1

`define INST_CSR_RW          2'h1
`define INST_CSR_RS          2'h2
`define INST_CSR_RC          2'h3
`define INST_CSR_OTHER       2'h0
`define INST_CSR_BITS        2

`define INST_FPU_ADD         4'h0 
`define INST_FPU_SUB         4'h4 
`define INST_FPU_MUL         4'h8 
`define INST_FPU_DIV         4'hC
`define INST_FPU_CVTWS       4'h1  // FCVT.W.S
`define INST_FPU_CVTWUS      4'h5  // FCVT.WU.S
`define INST_FPU_CVTSW       4'h9  // FCVT.S.W
`define INST_FPU_CVTSWU      4'hD  // FCVT.S.WU
`define INST_FPU_SQRT        4'h2
`define INST_FPU_CLASS       4'h6  
`define INST_FPU_CMP         4'hA
`define INST_FPU_MISC        4'hE  // SGNJ, SGNJN, SGNJX, FMIN, FMAX, MVXW, MVWX 
`define INST_FPU_MADD        4'h3 
`define INST_FPU_MSUB        4'h7   
`define INST_FPU_NMSUB       4'hB   
`define INST_FPU_NMADD       4'hF
`define INST_FPU_BITS        4

`define INST_GPU_TMC         4'h0
`define INST_GPU_WSPAWN      4'h1 
`define INST_GPU_SPLIT       4'h2
`define INST_GPU_JOIN        4'h3
`define INST_GPU_BAR         4'h4
`define INST_GPU_PRED        4'h5

`define INST_GPU_TEX         4'h6
`define INST_GPU_RASTER      4'h7
`define INST_GPU_ROP         4'h8
`define INST_GPU_CMOV        4'h9
`define INST_GPU_IMADD       4'hA
`define INST_GPU_BITS        4

///////////////////////////////////////////////////////////////////////////////

// non-cacheable tag bits
`define NC_TAG_BITS             1

// cache address type bits
`ifdef SM_ENABLE
`define CACHE_ADDR_TYPE_BITS    (`NC_TAG_BITS + 1)
`else
`define CACHE_ADDR_TYPE_BITS    `NC_TAG_BITS
`endif

`define ARB_SEL_BITS(I, O)      ((I > O) ? `CLOG2((I + O - 1) / O) : 0)

`define CACHE_MEM_TAG_WIDTH(mshr_size, num_banks) \
        (`LOG2UP(mshr_size) + `CLOG2(num_banks) + `NC_TAG_BITS)
        
`define CACHE_BYPASS_TAG_WIDTH(num_reqs, line_size, word_size, tag_width) \
        (`CLOG2(num_reqs) + `CLOG2(line_size / word_size) + tag_width + `NC_TAG_BITS)

`define CACHE_NC_BYPASS_TAG_WIDTH(num_reqs, line_size, word_size, tag_width) \
        (`CLOG2(num_reqs) + `CLOG2(line_size / word_size) + tag_width)

`define CACHE_NC_MEM_TAG_WIDTH(mshr_size, num_banks, num_reqs, line_size, word_size, tag_width) \
        `MAX(`CACHE_MEM_TAG_WIDTH(mshr_size, num_banks), `CACHE_NC_BYPASS_TAG_WIDTH(num_reqs, line_size, word_size, tag_width))

////////////////////////// Icache Definitions /////////////////////////////////

// Word size in bytes
`define ICACHE_WORD_SIZE        4
`define ICACHE_ADDR_WIDTH       (32 - `CLOG2(`ICACHE_WORD_SIZE))

// Block size in bytes
`define ICACHE_LINE_SIZE        `L1_BLOCK_SIZE

// Core request tag Id bits       
`define ICACHE_TAG_ID_BITS      `NW_BITS

// Core request tag bits
`define ICACHE_TAG_WIDTH        (`UUID_BITS + `ICACHE_TAG_ID_BITS)

// Input request size
`define ICACHE_NUM_REQS         1

// Number of banks
`define ICACHE_NUM_BANKS        1

// Memory request data bits
`define ICACHE_MEM_DATA_WIDTH   (`ICACHE_LINE_SIZE * 8)

// Memory request address bits
`define ICACHE_MEM_ADDR_WIDTH   (32 - `CLOG2(`ICACHE_LINE_SIZE))

// Memory request tag bits
`ifdef ICACHE_ENABLE
`define ICACHE_MEM_TAG_WIDTH    `CACHE_MEM_TAG_WIDTH(`ICACHE_MSHR_SIZE, `ICACHE_NUM_BANKS)
`else
`define ICACHE_MEM_TAG_WIDTH    `CACHE_BYPASS_TAG_WIDTH(`ICACHE_NUM_REQS, `ICACHE_LINE_SIZE, `ICACHE_WORD_SIZE, `ICACHE_TAG_WIDTH)
`endif

////////////////////////// Dcache Definitions /////////////////////////////////

// Word size in bytes
`define DCACHE_WORD_SIZE        4
`define DCACHE_ADDR_WIDTH       (32 - `CLOG2(`DCACHE_WORD_SIZE))

// Block size in bytes
`define DCACHE_LINE_SIZE        `L1_BLOCK_SIZE

// Input request size
`define DCACHE_NUM_REQS         `NUM_THREADS

// Memory request size
`define LSU_MEM_REQS            `NUM_THREADS

// Batch select bits
`define DCACHE_NUM_BATCHES      ((`LSU_MEM_REQS + `DCACHE_NUM_REQS - 1) / `DCACHE_NUM_REQS)
`define DCACHE_BATCH_SEL_BITS   `CLOG2(`DCACHE_NUM_BATCHES)

// Core request tag Id bits
`define LSUQ_TAG_BITS           (`CLOG2(`LSUQ_SIZE) + `DCACHE_BATCH_SEL_BITS)
`define DCACHE_TAG_ID_BITS      (`LSUQ_TAG_BITS + `CACHE_ADDR_TYPE_BITS)

// Core request tag bits
`define DCACHE_TAG_WIDTH        (`UUID_BITS + `DCACHE_TAG_ID_BITS)
 
// Memory request data bits
`define DCACHE_MEM_DATA_WIDTH   (`DCACHE_LINE_SIZE * 8)

// Memory request address bits
`define DCACHE_MEM_ADDR_WIDTH   (32 - `CLOG2(`DCACHE_LINE_SIZE))

// Memory byte enable bits
`define DCACHE_MEM_BYTEEN_WIDTH `DCACHE_LINE_SIZE

// Memory request tag bits
`define DCACHE_NOSM_TAG_WIDTH   (`DCACHE_TAG_WIDTH - `SM_ENABLED)
`ifdef DCACHE_ENABLE
`define DCACHE_MEM_TAG_WIDTH    `CACHE_NC_MEM_TAG_WIDTH(`DCACHE_MSHR_SIZE, `DCACHE_NUM_BANKS, `DCACHE_NUM_REQS, `DCACHE_LINE_SIZE, `DCACHE_WORD_SIZE, `DCACHE_NOSM_TAG_WIDTH)
`else
`define DCACHE_MEM_TAG_WIDTH    `CACHE_NC_BYPASS_TAG_WIDTH(`DCACHE_NUM_REQS, `DCACHE_LINE_SIZE, `DCACHE_WORD_SIZE, `DCACHE_TAG_WIDTH)
`endif

////////////////////////// Texture Unit Definitions ///////////////////////////

//                              uuid,         wid,       PC,   rd,    
`define TEX_REQ_TAG_WIDTH       (`UUID_BITS + `NW_BITS + 32 + `NR_BITS)
`define TEX_REQX_TAG_WIDTH      (`TEX_REQ_TAG_WIDTH + `ARB_SEL_BITS(`NUM_CORES, `NUM_TEX_UNITS))

////////////////////////// Tcache Definitions /////////////////////////////////

// Word size in bytes
`define TCACHE_WORD_SIZE        4
`define TCACHE_ADDR_WIDTH       (32 - `CLOG2(`TCACHE_WORD_SIZE))

// Block size in bytes
`define TCACHE_LINE_SIZE        `L2_LINE_SIZE

// Input request size
`define TCACHE_NUM_REQS         `NUM_THREADS

// Memory request size
`define TEX_MEM_REQS            (4 * `NUM_THREADS)

// Batch select bits
`define TCACHE_BATCH_SEL_BITS   `CLOG2((`TEX_MEM_REQS + `TCACHE_NUM_REQS - 1) / `TCACHE_NUM_REQS)

// Core request tag Id bits       
`define TCACHE_TAG_ID_BITS      (`CLOG2(`TEX_MEM_PENDING_SIZE) + `TCACHE_BATCH_SEL_BITS)

// Core request tag bits
`define TCACHE_TAG_WIDTH        (`TCACHE_TAG_ID_BITS + `CLOG2(`NUM_TEX_UNITS))

// Memory request data bits
`define TCACHE_MEM_DATA_WIDTH   (`TCACHE_LINE_SIZE * 8)

// Memory request address bits
`define TCACHE_MEM_ADDR_WIDTH   (32 - `CLOG2(`TCACHE_LINE_SIZE))

// Memory byte enable bits
`define TCACHE_MEM_BYTEEN_WIDTH `TCACHE_LINE_SIZE

// Input request size
`define TCACHE_NUM_REQS         `NUM_THREADS

// Memory request tag bits
`ifdef TCACHE_ENABLE
`define TCACHE_MEM_TAG_WIDTH    `CACHE_MEM_TAG_WIDTH(`TCACHE_MSHR_SIZE, `TCACHE_NUM_BANKS, `TCACHE_NUM_REQS, `TCACHE_LINE_SIZE, `TCACHE_WORD_SIZE, `TCACHE_TAG_WIDTH)
`else
`define TCACHE_MEM_TAG_WIDTH    `CACHE_BYPASS_TAG_WIDTH(`TCACHE_NUM_REQS, `TCACHE_LINE_SIZE, `TCACHE_WORD_SIZE, `TCACHE_TAG_WIDTH)
`endif

////////////////////////// Rcache Definitions /////////////////////////////////

// Word size in bytes
`define RCACHE_WORD_SIZE        4
`define RCACHE_ADDR_WIDTH       (32 - `CLOG2(`RCACHE_WORD_SIZE))

// Block size in bytes
`define RCACHE_LINE_SIZE        `L2_LINE_SIZE

// Input request size
`define RCACHE_NUM_REQS         `RCACHE_NUM_BANKS
 
// Raster memory request size
`define RASTER_MEM_REQS         9

// Batch select bits
`define RCACHE_BATCH_SEL_BITS   `CLOG2((`RASTER_MEM_REQS + `RCACHE_NUM_REQS - 1) / `RCACHE_NUM_REQS)

// Core request tag Id bits       
`define RCACHE_TAG_ID_BITS      (`CLOG2(`RASTER_MEM_PENDING_SIZE) + `RCACHE_BATCH_SEL_BITS)

// Core request tag bits
`define RCACHE_TAG_WIDTH        (`RCACHE_TAG_ID_BITS + `CLOG2(`NUM_RASTER_UNITS))

// Memory request data bits
`define RCACHE_MEM_DATA_WIDTH   (`RCACHE_LINE_SIZE * 8)

// Memory request address bits
`define RCACHE_MEM_ADDR_WIDTH   (32 - `CLOG2(`RCACHE_LINE_SIZE))

// Memory request tag bits
`ifdef RCACHE_ENABLE
`define RCACHE_MEM_TAG_WIDTH    `CACHE_MEM_TAG_WIDTH(`RCACHE_MSHR_SIZE, `RCACHE_NUM_BANKS, `RCACHE_NUM_REQS, `RCACHE_LINE_SIZE, `RCACHE_WORD_SIZE, `RCACHE_TAG_WIDTH)
`else
`define RCACHE_MEM_TAG_WIDTH    `CACHE_BYPASS_TAG_WIDTH(`RCACHE_NUM_REQS, `RCACHE_LINE_SIZE, `RCACHE_WORD_SIZE, `RCACHE_TAG_WIDTH)
`endif

////////////////////////// Ocache Definitions /////////////////////////////////

// Word size in bytes
`define OCACHE_WORD_SIZE        4
`define OCACHE_ADDR_WIDTH       (32 - `CLOG2(`OCACHE_WORD_SIZE))

// Block size in bytes
`define OCACHE_LINE_SIZE        `L2_LINE_SIZE

// Input request size
`define OCACHE_NUM_REQS         `OCACHE_NUM_BANKS

// ROP memory request size
`define ROP_MEM_REQS            (2 * `NUM_THREADS)

// Batch select bits
`define OCACHE_BATCH_SEL_BITS   `CLOG2((`ROP_MEM_REQS + `OCACHE_NUM_REQS - 1) / `OCACHE_NUM_REQS)

// Core request tag Id bits       
`define OCACHE_TAG_ID_BITS      (`CLOG2(`ROP_MEM_PENDING_SIZE) + `OCACHE_BATCH_SEL_BITS)

// Core request tag bits
`define OCACHE_TAG_WIDTH        (`OCACHE_TAG_ID_BITS + `CLOG2(`NUM_ROP_UNITS))

// Memory request data bits
`define OCACHE_MEM_DATA_WIDTH   (`OCACHE_LINE_SIZE * 8)

// Memory request address bits
`define OCACHE_MEM_ADDR_WIDTH   (32 - `CLOG2(`OCACHE_LINE_SIZE))

// Memory request tag bits
`ifdef OCACHE_ENABLE
`define OCACHE_MEM_TAG_WIDTH    `CACHE_MEM_TAG_WIDTH(`OCACHE_MSHR_SIZE, `OCACHE_NUM_BANKS, `OCACHE_NUM_REQS, `OCACHE_LINE_SIZE, `OCACHE_WORD_SIZE, `OCACHE_TAG_WIDTH)
`else
`define OCACHE_MEM_TAG_WIDTH    `CACHE_BYPASS_TAG_WIDTH(`OCACHE_NUM_REQS, `OCACHE_LINE_SIZE, `OCACHE_WORD_SIZE, `OCACHE_TAG_WIDTH)
`endif

/////////////////////////////// L1 Definitions ////////////////////////////////

`define _2_MEM_TAG_IN_WIDTH     `MAX(`ICACHE_MEM_TAG_WIDTH, `DCACHE_MEM_TAG_WIDTH)
`ifdef TCACHE_ENABLE
`define _3_MEM_TAG_IN_WIDTH     `MAX(`TCACHE_MEM_TAG_WIDTH, `_2_MEM_TAG_IN_WIDTH)
`else
`define _3_MEM_TAG_IN_WIDTH     `_2_MEM_TAG_IN_WIDTH
`endif
`ifdef RCACHE_ENABLE
`define _4_MEM_TAG_IN_WIDTH     `MAX(`RCACHE_MEM_TAG_WIDTH, `_3_MEM_TAG_IN_WIDTH)
`else
`define _4_MEM_TAG_IN_WIDTH     `_3_MEM_TAG_IN_WIDTH
`endif
`ifdef OCACHE_ENABLE
`define _5_MEM_TAG_IN_WIDTH     `MAX(`OCACHE_MEM_TAG_WIDTH, `_4_MEM_TAG_IN_WIDTH)
`else
`define _5_MEM_TAG_IN_WIDTH     `_4_MEM_TAG_IN_WIDTH
`endif
`define L1_MEM_TAG_WIDTH        `_5_MEM_TAG_IN_WIDTH

`define NUM_L1_INPUTS           (2 + `EXT_TEX_ENABLED + `EXT_RASTER_ENABLED + `EXT_ROP_ENABLED)

/////////////////////////////// L2 Definitions ////////////////////////////////

// Word size in bytes
`define L2_WORD_SIZE            `DCACHE_LINE_SIZE
`define L2_ADDR_WIDTH           (32-`CLOG2(`L2_WORD_SIZE))

// Block size in bytes
`ifdef L2_ENABLE
`define L2_LINE_SIZE            `MEM_BLOCK_SIZE
`else
`define L2_LINE_SIZE            `L2_WORD_SIZE
`endif

// Core request tag bits
`define L2_TAG_WIDTH            (`L1_MEM_TAG_WIDTH + `CLOG2(`NUM_L1_INPUTS))

// Memory request data bits
`define L2_MEM_DATA_WIDTH       (`L2_LINE_SIZE * 8)

// Memory request address bits
`define L2_MEM_ADDR_WIDTH       (32 - `CLOG2(`L2_LINE_SIZE))

// Memory byte enable bits
`define L2_MEM_BYTEEN_WIDTH     `L2_LINE_SIZE

// Input request size
`define L2_NUM_REQS             `NUM_CORES

// Memory request tag bits
`ifdef L2_ENABLE
`define L2_MEM_TAG_WIDTH        `CACHE_NC_MEM_TAG_WIDTH(`L2_MSHR_SIZE, `L2_NUM_BANKS, `L2_NUM_REQS, `L2_LINE_SIZE, `L2_WORD_SIZE, `L2_TAG_WIDTH)
`else
`define L2_MEM_TAG_WIDTH        `CACHE_NC_BYPASS_TAG_WIDTH(`L2_NUM_REQS, `L2_LINE_SIZE, `L2_WORD_SIZE, `L2_TAG_WIDTH)
`endif

/////////////////////////////// L3 Definitions ////////////////////////////////

// Word size in bytes
`define L3_WORD_SIZE            `L2_LINE_SIZE
`define L3_ADDR_WIDTH           (32 - `CLOG2(`L3_WORD_SIZE))

// Block size in bytes
`ifdef L3_ENABLE
`define L3_LINE_SIZE            `MEM_BLOCK_SIZE
`else
`define L3_LINE_SIZE            `L3_WORD_SIZE
`endif

// Core request tag bits
`define L3_TAG_WIDTH            (`L2_MEM_TAG_WIDTH + `CLOG2(`NUM_CLUSTERS))

// Memory request data bits
`define L3_MEM_DATA_WIDTH       (`L3_LINE_SIZE * 8)

// Memory request address bits
`define L3_MEM_ADDR_WIDTH       (32 - `CLOG2(`L3_LINE_SIZE))

// Memory byte enable bits
`define L3_MEM_BYTEEN_WIDTH     `L3_LINE_SIZE

// Input request size
`define L3_NUM_REQS             `NUM_CLUSTERS

// Memory request tag bits
`ifdef L3_ENABLE
`define L3_MEM_TAG_WIDTH        `CACHE_NC_MEM_TAG_WIDTH(`L3_MSHR_SIZE, `L3_NUM_BANKS, `L3_NUM_REQS, `L3_LINE_SIZE, `L3_WORD_SIZE, `L3_TAG_WIDTH)
`else
`define L3_MEM_TAG_WIDTH        `CACHE_NC_BYPASS_TAG_WIDTH(`L3_NUM_REQS, `L3_LINE_SIZE, `L3_WORD_SIZE, `L3_TAG_WIDTH)
`endif

///////////////////////////////////////////////////////////////////////////////

`define VX_MEM_BYTEEN_WIDTH     `L3_MEM_BYTEEN_WIDTH   
`define VX_MEM_ADDR_WIDTH       `L3_MEM_ADDR_WIDTH
`define VX_MEM_DATA_WIDTH       `L3_MEM_DATA_WIDTH
`define VX_MEM_TAG_WIDTH        `L3_MEM_TAG_WIDTH
`define VX_DCR_ADDR_WIDTH       `DCR_ADDR_BITS
`define VX_DCR_DATA_WIDTH       32

`define TO_FULL_ADDR(x)         {x, (32-$bits(x))'(0)}

///////////////////////////////////////////////////////////////////////////////

`define ASSIGN_VX_MEM_REQ_IF(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.rw     = src.rw;     \
    assign dst.byteen = src.byteen; \
    assign dst.addr   = src.addr;   \
    assign dst.data   = src.data;   \
    assign dst.tag    = src.tag;    \
    assign src.ready  = dst.ready

`define ASSIGN_VX_MEM_RSP_IF(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.data   = src.data;   \
    assign dst.tag    = src.tag;    \
    assign src.ready  = dst.ready

`define ASSIGN_VX_MEM_REQ_IF_XTAG(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.rw     = src.rw;     \
    assign dst.byteen = src.byteen; \
    assign dst.addr   = src.addr;   \
    assign dst.data   = src.data;   \
    assign src.ready  = dst.ready

`define ASSIGN_VX_MEM_RSP_IF_XTAG(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.data   = src.data;   \
    assign src.ready  = dst.ready

`define ASSIGN_VX_CACHE_REQ_IF(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.rw     = src.rw;     \
    assign dst.byteen = src.byteen; \
    assign dst.addr   = src.addr;   \
    assign dst.data   = src.data;   \
    assign dst.tag    = src.tag;    \
    assign src.ready  = dst.ready

`define ASSIGN_VX_CACHE_RSP_IF(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.data   = src.data;   \
    assign dst.tag    = src.tag;    \
    assign src.ready  = dst.ready

`define ASSIGN_VX_CACHE_REQ_IF_XTAG(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.rw     = src.rw;     \
    assign dst.byteen = src.byteen; \
    assign dst.addr   = src.addr;   \
    assign dst.data   = src.data;   \
    assign src.ready  = dst.ready

`define ASSIGN_VX_CACHE_RSP_IF_XTAG(dst, src) \
    assign dst.valid  = src.valid;  \
    assign dst.data   = src.data;   \
    assign src.ready  = dst.ready

`define CACHE_REQ_TO_MEM(dst, src, i) \
    assign dst[i].valid = src.valid[i]; \
    assign dst[i].rw = src.rw[i]; \
    assign dst[i].byteen = src.byteen[i]; \
    assign dst[i].addr = src.addr[i]; \
    assign dst[i].data = src.data[i]; \
    assign dst[i].tag = src.tag[i]; \
    assign src.ready[i] = dst[i].ready

`define CACHE_RSP_FROM_MEM(dst, src, i) \
    assign dst.valid[i] = src[i].valid; \
    assign dst.data[i] = src[i].data; \
    assign dst.tag[i] = src[i].tag; \
    assign src[i].ready = dst.ready[i]

`define ASSIGN_VX_RASTER_REQ_IF(dst, src) \
    assign dst.valid = src.valid; \
    assign dst.stamps = src.stamps; \
    assign dst.empty = src.empty; \
    assign src.ready = dst.ready

`endif
