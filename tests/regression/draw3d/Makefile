PROJECT = draw3d

OPTS ?=

VX_CFLAGS += -I$(VORTEX_KN_PATH)/../sim/common -I$(VORTEX_KN_PATH)/../third_party

CXXFLAGS += -I$(VORTEX_KN_PATH)/../sim/common -I$(VORTEX_KN_PATH)/../third_party

LDFLAGS += $(VORTEX_KN_PATH)/../third_party/cocogfx/libcocogfx.a -lpng -lz -lboost_serialization

SRCS = main.cpp $(VORTEX_KN_PATH)/../sim/common/gfxutil.cpp

VX_SRCS = kernel.cpp $(VORTEX_KN_PATH)/../sim/common/graphics.cpp

include ../common.mk
