#ifndef _COMMON_H_
#define _COMMON_H_

#define KERNEL_ARG_DEV_MEM_ADDR 0x7ffff000

#define FIXED_FRAC 16

typedef struct {
  uint32_t num_tasks;  
  uint32_t task_size;  
  uint64_t src0_addr;
  uint64_t src1_addr;
  uint64_t src2_addr;
  uint64_t src3_addr;
  uint64_t dst_addr;
  bool     use_sw;
} kernel_arg_t;

#endif