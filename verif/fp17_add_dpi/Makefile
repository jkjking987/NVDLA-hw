# +FHDR------------------------------------------------------------
#                 Copyright (c) 2026 Wolley Inc.
#                       ALL RIGHTS RESERVED
# -----------------------------------------------------------------
# Makefile for fp17_add DPI verification
# +FHDR------------------------------------------------------------

# Docker image with iverilog and gcc
DOCKER_IMAGE = esolang/verilog:latest

# Directories
TOP = /workspace
RTL_DIR = $(TOP)/vmod/vlibs
VERIF_DIR = $(TOP)/verif/fp17_add_dpi
C_FILES = $(VERIF_DIR)/fp17_add_ref.c

# Output
BUILD_DIR = $(VERIF_DIR)/build
TB_OUT = $(BUILD_DIR)/fp17_add_tb

# RTL files
RTL_FILES = $(RTL_DIR)/fp17_add.v

# Default target
all: build run

build:
	mkdir -p $(BUILD_DIR)
	docker run --rm \
		-v "$(shell pwd)":$(TOP) \
		-w $(TOP) \
		$(DOCKER_IMAGE) \
		gcc -I. -shared -fPIC -o $(BUILD_DIR)/libfp17_add_ref.so $(C_FILES)

run: build
	@echo "DPI test requires full simulation environment"
	@echo "To run manually:"
	@echo "  1. Compile RTL: iverilog -o $(TB_OUT).vvp $(RTL_FILES) $(VERIF_DIR)/fp17_add_tb.v"
	@echo "  2. Run: vvp $(TB_OUT).vvp"

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all build run clean
