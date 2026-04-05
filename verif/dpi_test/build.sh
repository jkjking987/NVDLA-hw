#!/bin/bash
cd /workspace
rm -rf obj_dir verilator.dpi.* *.cc *.h

# Compile with DPI support
verilator -Wall \
    --cc \
    --exe \
    --build \
    -j 0 \
    verif/dpi_test/dpi_sum_tb.v \
    verif/dpi_test/dpi_sum.c \
    -o obj_dir/VltTop

echo "Done"