#include <iostream>
#include <vector>
#include <unistd.h>
#include <string.h>
#include <chrono>
#include <cmath>
#include <assert.h>
#include <vortex.h>
#include "common.h"
#include "utils.h"

using namespace cocogfx;

#define RT_CHECK(_expr)                                         \
   do {                                                         \
     int _ret = _expr;                                          \
     if (0 == _ret)                                             \
       break;                                                   \
     printf("Error: '%s' returned %d!\n", #_expr, (int)_ret);   \
	 cleanup();			                                              \
     exit(-1);                                                  \
   } while (false)

///////////////////////////////////////////////////////////////////////////////

const char* kernel_file = "kernel.bin";
const char* input_file  = "palette64.png";
const char* output_file = "output.png";
const char* reference_file  = nullptr;
int wrap    = TEX_WRAP_CLAMP;
int filter  = TEX_FILTER_POINT;
float scale = 1.0f;
int format  = TEX_FORMAT_A8R8G8B8;
ePixelFormat eformat = FORMAT_A8R8G8B8;
bool use_sw = false;

vx_device_h device = nullptr;
vx_buffer_h staging_buf = nullptr;
kernel_arg_t kernel_arg;

static void show_usage() {
   std::cout << "Vortex Texture Test." << std::endl;
   std::cout << "Usage: [-k: kernel] [-i image] [-o image] [-r reference] [-s scale] [-w wrap] [-f format] [-g filter] [-z no_hw] [-h: help]" << std::endl;
}

static void parse_args(int argc, char **argv) {
  int c;
  while ((c = getopt(argc, argv, "zi:o:k:w:f:g:s:r:h?")) != -1) {
    switch (c) {
    case 'i':
      input_file = optarg;
      break;
    case 'o':
      output_file = optarg;
      break;
    case 'r':
      reference_file = optarg;
      break;
    case 's':
      scale = std::stof(optarg, NULL);
      break;
    case 'w':
      wrap = std::atoi(optarg);
      break;
    case 'z':
      use_sw = true;
      break;
    case 'f': {
      format  = std::atoi(optarg);
      switch (format) {
      case TEX_FORMAT_A8R8G8B8: eformat = FORMAT_A8R8G8B8; break;
      case TEX_FORMAT_R5G6B5: eformat = FORMAT_R5G6B5; break;
      case TEX_FORMAT_A1R5G5B5: eformat = FORMAT_A1R5G5B5; break;
      case TEX_FORMAT_A4R4G4B4: eformat = FORMAT_A4R4G4B4; break;
      case TEX_FORMAT_A8L8: eformat = FORMAT_A8L8; break;
      case TEX_FORMAT_L8: eformat = FORMAT_L8; break;
      case TEX_FORMAT_A8: eformat = FORMAT_A8; break;
      default:
        std::cout << "Error: invalid format: " << format << std::endl;
        exit(1);
      }      
    } break;
    case 'g':
      filter = std::atoi(optarg);
      break;
    case 'k':
      kernel_file = optarg;
      break;
    case 'h':
    case '?': {
      show_usage();
      exit(0);
    } break;
    default:
      show_usage();
      exit(-1);
    }
  }
}

void cleanup() {
  if (staging_buf) {
    vx_buf_free(staging_buf);
  }
  if (device) {
    vx_mem_free(device, kernel_arg.src_addr);
    vx_mem_free(device, kernel_arg.dst_addr);
    vx_dev_close(device);
  }
}

int render(const kernel_arg_t& kernel_arg, 
           uint32_t buf_size,
           uint32_t width,
           uint32_t height) {
  auto time_start = std::chrono::high_resolution_clock::now();

  // start device
  std::cout << "start device" << std::endl;
  RT_CHECK(vx_start(device));

  // wait for completion
  std::cout << "wait for completion" << std::endl;
  RT_CHECK(vx_ready_wait(device, MAX_TIMEOUT));
  
  auto time_end = std::chrono::high_resolution_clock::now();
  double elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(time_end - time_start).count();
  printf("Elapsed time: %lg ms\n", elapsed);

  // download destination buffer
  std::cout << "download destination buffer" << std::endl;
  RT_CHECK(vx_copy_from_dev(staging_buf, kernel_arg.dst_addr, buf_size, 0));

  std::vector<uint8_t> dst_pixels(buf_size);
  auto buf_ptr = (uint8_t*)vx_host_ptr(staging_buf);
  for (uint32_t i = 0; i < buf_size; ++i) {
    dst_pixels[i] = buf_ptr[i];
  } 

  // save output image
  std::cout << "save output image" << std::endl;  
  //dump_image(dst_pixels, width, height, 4);  
  RT_CHECK(SaveImage(output_file, FORMAT_A8R8G8B8, dst_pixels, width, height));

  return 0;
}

int main(int argc, char *argv[]) {
  std::vector<uint8_t> src_pixels;
  std::vector<uint32_t> mip_offsets;
  uint32_t src_width;
  uint32_t src_height;
  
  // parse command arguments
  parse_args(argc, argv);

  {
    std::vector<uint8_t> staging;  
    RT_CHECK(LoadImage(input_file, eformat, staging, &src_width, &src_height));  
    // check power of two support
    if (!ispow2(src_width) || !ispow2(src_height)) {
      std::cout << "Error: only power of two textures supported: width=" << src_width << ", heigth=" << src_height << std::endl;
      return -1;
    }
    uint32_t src_bpp = Format::GetInfo(eformat).BytePerPixel;
    uint32_t src_pitch = src_width * src_bpp;
    //dump_image(staging, src_width, src_height, src_bpp);
    RT_CHECK(GenerateMipmaps(src_pixels, mip_offsets, staging, eformat, src_width, src_height, src_pitch));    
  }  

  uint32_t src_logwidth  = log2ceil(src_width);
  uint32_t src_logheight = log2ceil(src_height);

  uint32_t src_bufsize = src_pixels.size();

  uint32_t dst_width   = (uint32_t)(src_width * scale);
  uint32_t dst_height  = (uint32_t)(src_height * scale);
  uint32_t dst_bpp     = 4;
  uint32_t dst_bufsize = dst_bpp * dst_width * dst_height;

  // open device connection
  std::cout << "open device connection" << std::endl;
  RT_CHECK(vx_dev_open(&device));

  uint64_t isa_flags;
  RT_CHECK(vx_dev_caps(device, VX_CAPS_ISA_FLAGS, &isa_flags));
  if (0 == (isa_flags & VX_ISA_EXT_TEX)) {
    std::cout << "texture extension not supported!" << std::endl;
    return -1;
  }

  uint64_t max_cores, max_warps, max_threads;
  RT_CHECK(vx_dev_caps(device, VX_CAPS_MAX_CORES, &max_cores));
  RT_CHECK(vx_dev_caps(device, VX_CAPS_MAX_WARPS, &max_warps));
  RT_CHECK(vx_dev_caps(device, VX_CAPS_MAX_THREADS, &max_threads));  

  uint32_t num_tasks = max_cores * max_warps * max_threads;

  std::cout << "number of tasks: " << std::dec << num_tasks << std::endl;
  std::cout << "source staging_buf: width=" << src_width << ", heigth=" << src_height << ", size=" << src_bufsize << " bytes" << std::endl;
  std::cout << "destination staging_buf: width=" << dst_width << ", heigth=" << dst_height << ", size=" << dst_bufsize << " bytes" << std::endl;

  // upload program
  std::cout << "upload program" << std::endl;  
  RT_CHECK(vx_upload_kernel_file(device, kernel_file));

  // allocate device memory
  std::cout << "allocate device memory" << std::endl;  
  uint64_t src_addr, dst_addr;
  RT_CHECK(vx_mem_alloc(device, src_bufsize, &src_addr));
  RT_CHECK(vx_mem_alloc(device, dst_bufsize, &dst_addr));

  std::cout << "src_addr=0x" << std::hex << src_addr << std::endl;
  std::cout << "dst_addr=0x" << std::hex << dst_addr << std::endl;

  // allocate staging buffer  
  std::cout << "allocate staging buffer" << std::endl;    
  uint32_t alloc_size = std::max<uint32_t>(sizeof(kernel_arg_t), 
                            std::max<uint32_t>(src_bufsize, dst_bufsize));
  RT_CHECK(vx_buf_alloc(device, alloc_size, &staging_buf));
  
  // upload kernel argument
  std::cout << "upload kernel argument" << std::endl;
  {
    kernel_arg.use_sw     = use_sw;
    kernel_arg.num_tasks  = std::min<uint32_t>(num_tasks, dst_height);
    kernel_arg.format     = format;
    kernel_arg.filter     = filter;
    kernel_arg.wrapu      = wrap;
    kernel_arg.wrapv      = wrap;    
    
    kernel_arg.src_addr      = src_addr;
    kernel_arg.src_logwidth  = src_logwidth;
    kernel_arg.src_logheight = src_logheight;
    for (uint32_t i = 0; i < mip_offsets.size(); ++i) {
      assert(i < TEX_LOD_MAX);
      kernel_arg.mip_offs[i] = mip_offsets.at(i); 
    }

    kernel_arg.dst_width  = dst_width;
    kernel_arg.dst_height = dst_height;
    kernel_arg.dst_stride = dst_bpp;
    kernel_arg.dst_pitch  = dst_bpp * dst_width;    
    kernel_arg.dst_addr   = dst_addr;

    auto buf_ptr = (uint8_t*)vx_host_ptr(staging_buf);
    memcpy(buf_ptr, &kernel_arg, sizeof(kernel_arg_t));
    RT_CHECK(vx_copy_to_dev(staging_buf, KERNEL_ARG_DEV_MEM_ADDR, sizeof(kernel_arg_t), 0));
  }

  // upload source buffer
  std::cout << "upload source buffer" << std::endl;      
  {    
    auto buf_ptr = (uint8_t*)vx_host_ptr(staging_buf);
    for (uint32_t i = 0; i < src_bufsize; ++i) {
      buf_ptr[i] = src_pixels[i];
    }      
    RT_CHECK(vx_copy_to_dev(staging_buf, kernel_arg.src_addr, src_bufsize, 0));
  }

  // clear destination buffer
  std::cout << "clear destination buffer" << std::endl;      
  {    
    auto buf_ptr = (uint32_t*)vx_host_ptr(staging_buf);
    for (uint32_t i = 0; i < (dst_bufsize/4); ++i) {
      buf_ptr[i] = 0xdeadbeef;
    }    
    RT_CHECK(vx_copy_to_dev(staging_buf, kernel_arg.dst_addr, dst_bufsize, 0));  
  }

	// configure texture units
	vx_dcr_write(device, DCR_TEX_STAGE,   0);
	vx_dcr_write(device, DCR_TEX_LOGDIM,  (src_logheight << 16) | src_logwidth);	
	vx_dcr_write(device, DCR_TEX_FORMAT,  format);
	vx_dcr_write(device, DCR_TEX_WRAP,    (wrap << 16) | wrap);
	vx_dcr_write(device, DCR_TEX_FILTER,  (filter ? TEX_FILTER_BILINEAR : TEX_FILTER_POINT));
	vx_dcr_write(device, DCR_TEX_ADDR,    src_addr);
	for (uint32_t i = 0; i < mip_offsets.size(); ++i) {
    assert(i < TEX_LOD_MAX);
		vx_dcr_write(device, DCR_TEX_MIPOFF(i), mip_offsets.at(i));
	};

  // render
  std::cout << "render" << std::endl;
  RT_CHECK(render(kernel_arg, dst_bufsize, dst_width, dst_height));

  // cleanup
  std::cout << "cleanup" << std::endl;  
  cleanup();

  if (reference_file) {
    auto errors = CompareImages(output_file, reference_file, FORMAT_A8R8G8B8);
    if (0 == errors) {
      std::cout << "PASSED!" << std::endl;
    } else {
      std::cout << "FAILED!" << std::endl;
      return errors;
    }
  } 

  return 0;
}