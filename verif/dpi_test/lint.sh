#!/bin/bash
cd /workspace
verilator --lint-only verif/dpi_test/dpi_sum_tb.v
echo "Exit code: $?"