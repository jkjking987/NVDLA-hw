#!/bin/bash
# Run CDP ICVT DPI verification with Verilator

set -e

WORK_DIR=/c/Users/jkjki/Desktop/NVDLA-hw/verif/dpi_test/cdp_icvt
RTL_DIR=/c/Users/jkjki/Desktop/NVDLA-hw/vmod/nvdla/cdp
TOP_DIR=/c/Users/jkjki/Desktop/NVDLA-hw

cd $WORK_DIR

echo "=== CDP ICVT DPI Verification ==="

# Clean - remove both build and obj_dir
rm -rf build obj_dir

# Compile with Verilator using sh -c to bypass ENTRYPOINT
MSYS_NO_PATHCONV=1 docker run --rm --entrypoint /bin/sh \
    -v "$TOP_DIR":"$TOP_DIR" \
    -w "$WORK_DIR" \
    verilator/verilator:latest \
    -c "verilator --binary --cc \
        -Wno-TIMESCALEMOD \
        -Wno-WIDTHEXPAND \
        -Wno-WIDTHTRUNC \
        -I$RTL_DIR \
        $RTL_DIR/NV_NVDLA_CDP_icvt_new.v \
        cdp_icvt_dpi_tb.v \
        cdp_icvt_ref.c \
        --build"

echo "Build complete. Running..."
MSYS_NO_PATHCONV=1 docker run --rm --entrypoint /bin/sh \
    -v "$TOP_DIR":"$TOP_DIR" \
    -w "$WORK_DIR" \
    verilator/verilator:latest \
    -c "./obj_dir/VNV_NVDLA_CDP_icvt_new"

echo "=== Done ==="
