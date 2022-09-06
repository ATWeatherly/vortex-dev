#include "cluster.h"

using namespace vortex;

Cluster::Cluster(uint32_t cluster_id, uint32_t cores_per_cluster, ProcessorImpl* processor, const Arch &arch, const DCRS &dcrs) 
  : cluster_id_(cluster_id)
  , cores_(cores_per_cluster)
  , raster_units_(NUM_RASTER_UNITS)
  , rop_units_(NUM_ROP_UNITS)
  , tex_units_(NUM_TEX_UNITS)
  , sharedmems_(cores_per_cluster)
  , processor_(processor)
{
  char sname[100];

  snprintf(sname, 100, "cluster%d-l2cache", cluster_id);
  l2cache_ = CacheSim::Create(sname, CacheSim::Config{
    !L2_ENABLED,
    log2ceil(L2_CACHE_SIZE),  // C
    log2ceil(MEM_BLOCK_SIZE), // B
    log2ceil(L2_NUM_WAYS),  // W
    0,                      // A
    32,                     // address bits  
    L2_NUM_BANKS,           // number of banks
    L2_NUM_PORTS,           // number of ports
    5,                      // request size 
    true,                   // write-through
    false,                  // write response
    0,                      // victim size
    L2_MSHR_SIZE,           // mshr
    2,                      // pipeline latency
  });

  snprintf(sname, 100, "cluster%d-icaches", cluster_id);
  icaches_ = CacheCluster::Create(sname, cores_per_cluster, NUM_ICACHES, CacheSim::Config{
    !ICACHE_ENABLED,
    log2ceil(ICACHE_SIZE),  // C
    log2ceil(L1_LINE_SIZE),// B
    log2ceil(sizeof(uint32_t)), // W
    log2ceil(ICACHE_NUM_WAYS),// A
    32,                     // address bits    
    1,                      // number of banks
    1,                      // number of ports
    1,                      // number of requests
    true,                   // write-through
    false,                  // write response
    0,                      // victim size
    (uint8_t)arch.num_warps(), // mshr
    2,                      // pipeline latency
  });

  icaches_->MemReqPort.bind(&l2cache_->CoreReqPorts.at(0));
  l2cache_->CoreRspPorts.at(0).bind(&icaches_->MemRspPort);

  snprintf(sname, 100, "cluster%d-dcaches", cluster_id);
  dcaches_ = CacheCluster::Create(sname, cores_per_cluster, NUM_DCACHES, CacheSim::Config{
    !DCACHE_ENABLED,
    log2ceil(DCACHE_SIZE),  // C
    log2ceil(L1_LINE_SIZE),// B
    log2ceil(sizeof(Word)), // W
    log2ceil(DCACHE_NUM_WAYS),// A
    32,                     // address bits    
    DCACHE_NUM_BANKS,       // number of banks
    DCACHE_NUM_PORTS,       // number of ports
    (uint8_t)arch.num_threads(), // number of requests
    true,                   // write-through
    false,                  // write response
    0,                      // victim size
    DCACHE_MSHR_SIZE,       // mshr
    4,                      // pipeline latency
  });

  dcaches_->MemReqPort.bind(&l2cache_->CoreReqPorts.at(1));
  l2cache_->CoreRspPorts.at(1).bind(&dcaches_->MemRspPort);
  
  snprintf(sname, 100, "cluster%d-tcaches", cluster_id);
  tcaches_ = CacheCluster::Create(sname, NUM_TEX_UNITS, NUM_TCACHES, CacheSim::Config{
    !TCACHE_ENABLED,
    log2ceil(TCACHE_SIZE),  // C
    log2ceil(L1_LINE_SIZE),// B
    log2ceil(sizeof(uint32_t)), // W
    log2ceil(TCACHE_NUM_WAYS),// A
    32,                     // address bits    
    TCACHE_NUM_BANKS,       // number of banks
    TCACHE_NUM_PORTS,       // number of ports
    (uint8_t)arch.num_threads(), // number of requests
    false,                  // write-through
    false,                  // write response
    0,                      // victim size
    TCACHE_MSHR_SIZE,       // mshr
    4,                      // pipeline latency
  });

  tcaches_->MemReqPort.bind(&l2cache_->CoreReqPorts.at(2));
  l2cache_->CoreRspPorts.at(2).bind(&tcaches_->MemRspPort);

  snprintf(sname, 100, "cluster%d-ocaches", cluster_id);
  ocaches_ = CacheCluster::Create(sname, NUM_ROP_UNITS, NUM_OCACHES, CacheSim::Config{
    !OCACHE_ENABLED,
    log2ceil(OCACHE_SIZE),  // C
    log2ceil(MEM_BLOCK_SIZE), // B
    log2ceil(sizeof(uint32_t)), // W
    log2ceil(OCACHE_NUM_WAYS), // A 
    32,                     // address bits    
    OCACHE_NUM_BANKS,       // number of banks
    OCACHE_NUM_PORTS,       // number of ports
    (uint8_t)arch.num_threads(), // number of requests
    false,                  // write-through
    false,                  // write response
    0,                      // victim size
    OCACHE_MSHR_SIZE,       // mshr
    4,                      // pipeline latency
  });

  ocaches_->MemReqPort.bind(&l2cache_->CoreReqPorts.at(3));
  l2cache_->CoreRspPorts.at(3).bind(&ocaches_->MemRspPort);

  snprintf(sname, 100, "cluster%d-rcaches", cluster_id);
  rcaches_ = CacheCluster::Create(sname, NUM_RASTER_UNITS, NUM_RCACHES, CacheSim::Config{
    !RCACHE_ENABLED,
    log2ceil(RCACHE_SIZE),  // C
    log2ceil(MEM_BLOCK_SIZE), // B
    log2ceil(sizeof(uint32_t)), // W
    log2ceil(RCACHE_NUM_WAYS), // A
    32,                     // address bits    
    RCACHE_NUM_BANKS,       // number of banks
    RCACHE_NUM_PORTS,       // number of ports
    1,                      // number of requests 
    false,                  // write-through
    false,                  // write response
    0,                      // victim size
    RCACHE_MSHR_SIZE,       // mshr
    4,                      // pipeline latency
  });

  rcaches_->MemReqPort.bind(&l2cache_->CoreReqPorts.at(4));
  l2cache_->CoreRspPorts.at(4).bind(&rcaches_->MemRspPort);

  ///////////////////////////////////////////////////////////////////////////

  uint32_t cores_per_raster = cores_per_cluster / NUM_RASTER_UNITS;
  uint32_t cores_per_rop = cores_per_cluster / NUM_ROP_UNITS;
  uint32_t cores_per_tex = cores_per_cluster / NUM_TEX_UNITS;

  // create raster units    
  for (uint32_t i = 0; i < NUM_RASTER_UNITS; ++i) {
    snprintf(sname, 100, "cluster%d-raster_unit%d", cluster_id, i);
    uint32_t raster_idx = cluster_id * NUM_RASTER_UNITS + i;      
    raster_units_.at(i) = RasterUnit::Create(sname, raster_idx, cores_per_raster, arch, dcrs.raster_dcrs, RasterUnit::Config{
      RASTER_TILE_LOGSIZE, 
      RASTER_BLOCK_LOGSIZE
    });
    raster_units_.at(i)->MemReqs.bind(&rcaches_->CoreReqPorts.at(i).at(0));
    rcaches_->CoreRspPorts.at(i).at(0).bind(&raster_units_.at(i)->MemRsps);
  }

  // create rop units
  for (uint32_t i = 0; i < NUM_ROP_UNITS; ++i) {
    snprintf(sname, 100, "cluster%d-rop_unit%d", cluster_id, i);      
    rop_units_.at(i) = RopUnit::Create(sname, cores_per_rop, arch, dcrs.rop_dcrs);
    for (uint32_t j = 0; j < arch.num_threads(); ++j) {
      rop_units_.at(i)->MemReqs.at(j).bind(&ocaches_->CoreReqPorts.at(i).at(j));
      ocaches_->CoreRspPorts.at(i).at(j).bind(&rop_units_.at(i)->MemRsps.at(j));
    }
  }

  // create tex units
  for (uint32_t i = 0; i < NUM_TEX_UNITS; ++i) {
    snprintf(sname, 100, "cluster%d-tex_unit%d", cluster_id, i);      
    tex_units_.at(i) = TexUnit::Create(sname, cores_per_tex, arch, dcrs.tex_dcrs, TexUnit::Config{
      2, // address latency
      6, // sampler latency
    });      
    for (uint32_t j = 0; j < arch.num_threads(); ++j) {
      tex_units_.at(i)->MemReqs.at(j).bind(&tcaches_->CoreReqPorts.at(i).at(j));
      tcaches_->CoreRspPorts.at(i).at(j).bind(&tex_units_.at(i)->MemRsps.at(j));
    }
  }

  // create shared memory blocks
  for (uint32_t i = 0; i < cores_per_cluster; ++i) {
    snprintf(sname, 100, "cluster%d-shared_mem%d", cluster_id, i);
    sharedmems_.at(i) = SharedMem::Create(sname, SharedMem::Config{
      uint32_t(SMEM_LOCAL_SIZE) * arch.num_warps() * arch.num_threads(),
      SMEM_LOCAL_SIZE,
      arch.num_threads(), 
      arch.num_threads(),
      log2ceil(STACK_SIZE),
      1,
      false
    });
  }

  // create cores
  for (uint32_t i = 0; i < cores_per_cluster; ++i) {
    uint32_t raster_idx = i / cores_per_raster;
    uint32_t rop_idx    = i / cores_per_rop;
    uint32_t tex_idx    = i / cores_per_tex;

    uint32_t core_id = cluster_id * cores_per_cluster + i;

    cores_.at(i) = Core::Create(core_id, 
                                this, 
                                arch, 
                                dcrs, 
                                sharedmems_.at(i), 
                                raster_units_.at(raster_idx), 
                                rop_units_.at(rop_idx), 
                                tex_units_.at(tex_idx));

    cores_.at(i)->icache_req_ports.at(0).bind(&icaches_->CoreReqPorts.at(i).at(0));
    icaches_->CoreRspPorts.at(i).at(0).bind(&cores_.at(i)->icache_rsp_ports.at(0));      

    for (uint32_t j = 0; j < arch.num_threads(); ++j) {
      snprintf(sname, 100, "cluster%d-smem_demux%d_%d", cluster_id, i, j);
      auto smem_demux = SMemDemux::Create(sname);
      
      cores_.at(i)->dcache_req_ports.at(j).bind(&smem_demux->ReqIn);
      smem_demux->RspIn.bind(&cores_.at(i)->dcache_rsp_ports.at(j));        
      
      smem_demux->ReqDc.bind(&dcaches_->CoreReqPorts.at(i).at(j));
      dcaches_->CoreRspPorts.at(i).at(j).bind(&smem_demux->RspDc);

      smem_demux->ReqSm.bind(&sharedmems_.at(i)->Inputs.at(j));
      sharedmems_.at(i)->Outputs.at(j).bind(&smem_demux->RspSm);
    }
  }
}

Cluster::~Cluster() {
  //--
}

void Cluster::attach_ram(RAM* ram) {
  for (auto core : cores_) {
    core->attach_ram(ram);
  }
  for (auto raster_unit : raster_units_) {
    raster_unit->attach_ram(ram);
  }
  for (auto rop_unit : rop_units_) {
    rop_unit->attach_ram(ram);
  }
  for (auto tex_unit : tex_units_) {
    tex_unit->attach_ram(ram);
  }
}

bool Cluster::running() const {
  for (auto& core : cores_) {
    if (core->running())
      return true;
  }
  return false;
}

bool Cluster::getIRegValue(int* value, int reg) const {
  for (auto& core : cores_) {
    if (core->check_exit()) {
      *value = core->getIRegValue(reg);
      return true;
    }
  }
  return false;
}

void Cluster::bind(SimPort<MemReq>* mem_req_port, SimPort<MemRsp>* mem_rsp_port) {    
    l2cache_->MemReqPort.bind(mem_req_port);
    mem_rsp_port->bind(&l2cache_->MemRspPort);
}

ProcessorImpl* Cluster::processor() const {
  return processor_;
}

Cluster::PerfStats Cluster::perf_stats() const {
  Cluster::PerfStats perf;
  perf.icache = icaches_->perf_stats();
  perf.dcache = dcaches_->perf_stats();    
  perf.tcache = tcaches_->perf_stats();
  perf.ocache = ocaches_->perf_stats();
  perf.rcache = rcaches_->perf_stats();
  perf.l2cache = l2cache_->perf_stats();

  for (auto sharedmem : sharedmems_) {
    perf.sharedmem += sharedmem->perf_stats();
  }
  
  for (uint32_t i = 0; i < NUM_RASTER_UNITS; ++i) {
    perf.raster_unit += raster_units_.at(i)->perf_stats();
  }
  
  for (uint32_t i = 0; i < NUM_ROP_UNITS; ++i) {
    perf.rop_unit += rop_units_.at(i)->perf_stats();
  }

  for (uint32_t i = 0; i < NUM_TEX_UNITS; ++i) {
    perf.tex_unit += tex_units_.at(i)->perf_stats();
  }    
  
  return perf;
}