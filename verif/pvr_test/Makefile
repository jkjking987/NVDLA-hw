# Pure Verilog Reference Model Verification Framework
# For NVDLA Core Modules

DOCKER_IMAGE = esolang/verilog:latest
TOP = /workspace

.PHONY: all clean bdma cdma csc cdp sdp pdp cmac cacc

all: bdma

bdma:
	@echo "=== BDMA Verification ==="
	cd $(TOP) && docker run --rm -v "$(TOP)":$(TOP) -w $(TOP) $(DOCKER_IMAGE) \
		iverilog -o verif/pvr_test/bdma_tb.vvp \
		verif/pvr_test/bdma_ref.v \
		vmod/nvdla/bdma/NV_NVDLA_BDMA_new.v \
		vmod/nvdla/bdma/NV_NVDLA_BDMA_csb_new.v \
		vmod/nvdla/bdma/NV_NVDLA_BDMA_reg_new.v \
		vmod/nvdla/bdma/NV_NVDLA_BDMA_load_new.v \
		vmod/nvdla/bdma/NV_NVDLA_BDMA_store_new.v \
		vmod/nvdla/bdma/NV_NVDLA_BDMA_mcif_cvif_new.v \
		2>&1 | head -20

clean:
	rm -rf verif/pvr_test/*.vvp verif/pvr_test/*.out