// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : cdp_icvt_ref.c
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   C Reference Model for CDP ICVT (Input Converter)
//   DPI export for Verilator verification
//   Operations: ALU(sub) -> MUL -> TRUNCATE
// +FHDR------------------------------------------------------------

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// CDP ICVT INT16 reference
// DPI function signature must match the import in testbench
void cdp_icvt_ref(
    int data_in,       // Input data
    int alu_in,        // ALU operand
    int mul_in,        // MUL operand
    int truncate,      // Truncate shift amount
    int *data_out     // Output result (passed by reference)
) {
    // ALU: subtract
    int alu_out = data_in - alu_in;

    // MUL: multiply (result fits in lower bits)
    int mul_out = alu_out * mul_in;

    // TRUNCATE: shift right
    int truncate_out = mul_out >> truncate;

    *data_out = truncate_out & 0xFFFF;  // Output is 16-bit
}

#ifdef __cplusplus
}
#endif
