#!/bin/bash
# Build script for CDP ICVT DPI verification with Verilator

set -e

TOP=/workspace
RTL_DIR=$TOP/vmod/nvdla/cdp
VERIF_DIR=$TOP/verif/dpi_test/cdp_icvt
BUILD_DIR=$VERIF_DIR/build
DPI_SRC=$VERIF_DIR/cdp_icvt_ref.c

# Verilator include path
VERILATOR_INCLUDE=/usr/local/share/verilator/include

echo "=== CDP ICVT DPI Build ==="

# Clean
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Compile C reference to object file
echo "Compiling C reference..."
docker run --rm \
    -v $(pwd):$TOP \
    -w $TOP \
    verilator/verilator:latest \
    gcc -I$VERILATOR_INCLUDE -c -o $BUILD_DIR/cdp_icvt_ref.o $DPI_SRC

# Compile RTL with Verilator
echo "Compiling RTL with Verilator..."
docker run --rm \
    -v $(pwd):$TOP \
    -w $TOP \
    verilator/verilator:latest \
    verilator --cc \
        $RTL_DIR/NV_NVDLA_CDP_icvt_new.v \
        $VERIF_DIR/cdp_icvt_dpi_tb.v \
        --exe \
        --build \
        -j 4 \
        --lint-only

echo "Build complete"
