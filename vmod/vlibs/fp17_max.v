// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp17_max.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   Floating-point max selector for fp17 (1 sign + 6 expo + 10 mantissa)
//   Implements FpMax<6,10> algorithm from nvdla_float.h
//   - Stage 1: Input handshake and unpack to sign/expo/mantissa
//   - Stage 2: Compare, select max, NaN handling, pack
// +FHDR------------------------------------------------------------

// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

module fp17_max (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_b_rsc_z,
    chn_b_rsc_vz,
    chn_b_rsc_lz,
    chn_o_rsc_z,
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

    // ================================================================
    // Parameters
    // ================================================================
    parameter EXPO_WIDTH = 6;   // fp17 has 6-bit exponent
    parameter MANT_WIDTH = 10;  // fp17 has 10-bit mantissa
    parameter FP_WIDTH = 17;   // 1 + EXPO_WIDTH + MANT_WIDTH
    localparam K_EXPO_MAX = (1 << EXPO_WIDTH) - 1;  // 63

    // ================================================================
    // Port Declarations
    // ================================================================
    input nvdla_core_clk;
    input nvdla_core_rstn;

    // Input channel A
    input  [FP_WIDTH-1:0] chn_a_rsc_z;
    input                 chn_a_rsc_vz;
    output                chn_a_rsc_lz;

    // Input channel B
    input  [FP_WIDTH-1:0] chn_b_rsc_z;
    input                 chn_b_rsc_vz;
    output                chn_b_rsc_lz;

    // Output channel
    output [FP_WIDTH-1:0] chn_o_rsc_z;
    input                 chn_o_rsc_vz;
    output                chn_o_rsc_lz;

    // ================================================================
    // Signal Declarations
    // ================================================================

    // Handshake control
    wire chn_a_rdy;
    wire chn_b_rdy;
    wire inputAccepted;

    // Pipeline valid signals
    reg s1_v;
    reg s2_v;

    // Stage 1: unpacked values
    reg        s1_a_sign_q;
    reg [EXPO_WIDTH-1:0] s1_a_expo_q;
    reg [MANT_WIDTH-1:0] s1_a_mant_q;
    reg        s1_b_sign_q;
    reg [EXPO_WIDTH-1:0] s1_b_expo_q;
    reg [MANT_WIDTH-1:0] s1_b_mant_q;

    // Stage 2: comparison and selection results
    reg [FP_WIDTH-1:0] s2_result_q;

    // Output register
    reg [FP_WIDTH-1:0] chn_o_rsc_z_q;
    reg output_valid_q;

    // ================================================================
    // Handshake Logic
    // ================================================================
    assign chn_a_rdy = chn_o_rsc_vz;
    assign chn_b_rdy = chn_o_rsc_vz;
    assign inputAccepted = chn_o_rsc_vz && chn_a_rsc_vz && chn_b_rsc_vz;
    assign chn_a_rsc_lz = chn_o_rsc_vz && chn_a_rsc_vz;
    assign chn_b_rsc_lz = chn_o_rsc_vz && chn_b_rsc_vz;
    assign chn_o_rsc_lz = output_valid_q;
    assign chn_o_rsc_z = chn_o_rsc_z_q;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            output_valid_q <= 1'b0;
        else
            output_valid_q <= s2_v;
    end

    // ================================================================
    // Stage 1: Input Register and Unpack
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s1_v <= 1'b0;
        else begin
            if (s2_v)
                s1_v <= 1'b0;
            else if (inputAccepted)
                s1_v <= 1'b1;
        end
    end

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s1_a_sign_q <= 1'b0;
            s1_a_expo_q <= {EXPO_WIDTH{1'b0}};
            s1_a_mant_q <= {MANT_WIDTH{1'b0}};
            s1_b_sign_q <= 1'b0;
            s1_b_expo_q <= {EXPO_WIDTH{1'b0}};
            s1_b_mant_q <= {MANT_WIDTH{1'b0}};
        end else begin
            if (inputAccepted) begin
                s1_a_sign_q <= chn_a_rsc_z[FP_WIDTH-1];
                s1_a_expo_q <= chn_a_rsc_z[FP_WIDTH-2:MANT_WIDTH];
                s1_a_mant_q <= chn_a_rsc_z[MANT_WIDTH-1:0];
                s1_b_sign_q <= chn_b_rsc_z[FP_WIDTH-1];
                s1_b_expo_q <= chn_b_rsc_z[FP_WIDTH-2:MANT_WIDTH];
                s1_b_mant_q <= chn_b_rsc_z[MANT_WIDTH-1:0];
            end
        end
    end

    // ================================================================
    // Stage 2: Compare, Select Max, NaN Handling, Pack
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s2_v <= 1'b0;
        else
            s2_v <= s1_v;
    end

    // NaN detection
    wire s1_a_is_nan;
    wire s1_b_is_nan;
    assign s1_a_is_nan = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q != {MANT_WIDTH{1'b0}});
    assign s1_b_is_nan = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q != {MANT_WIDTH{1'b0}});

    // Absolute comparison: compare exponent first, then mantissa
    wire s1_a_abs_gt_b;
    assign s1_a_abs_gt_b = (s1_a_expo_q > s1_b_expo_q) ||
                           ((s1_a_expo_q == s1_b_expo_q) && (s1_a_mant_q > s1_b_mant_q));

    // Determine if a is greater (accounting for sign)
    // Positive a > Negative b always
    // Negative a < Positive b always
    // For same sign: compare absolute values
    wire s1_a_is_pos;
    wire s1_b_is_pos;
    wire s1_a_is_greater;
    assign s1_a_is_pos = (s1_a_sign_q == 1'b0);
    assign s1_b_is_pos = (s1_b_sign_q == 1'b0);

    // a > b if:
    // - both positive and abs(a) > abs(b)
    // - a positive and b negative
    // - both negative and abs(a) < abs(b) (i.e., abs(a) > abs(b) means a is less negative)
    assign s1_a_is_greater = s1_a_is_pos ?
                             (s1_b_is_pos ? s1_a_abs_gt_b : 1'b1) :
                             (s1_b_is_pos ? 1'b0 : ~s1_a_abs_gt_b);

    // Result selection: NaN handling returns the non-NaN operand per FpCmp logic
    // If a is NaN, return b; if b is NaN, return a; else return the larger value
    wire [FP_WIDTH-1:0] s2_result;
    wire [FP_WIDTH-1:0] a_packed;
    wire [FP_WIDTH-1:0] b_packed;

    assign a_packed = {s1_a_sign_q, s1_a_expo_q, s1_a_mant_q};
    assign b_packed = {s1_b_sign_q, s1_b_expo_q, s1_b_mant_q};

    wire use_a;
    wire use_b;
    assign use_a = s1_a_is_greater && !s1_b_is_nan;
    assign use_b = !s1_a_is_greater && !s1_a_is_nan;

    assign s2_result = (s1_a_is_nan && s1_b_is_nan) ? a_packed :  // both NaN, return a
                       s1_a_is_nan ? b_packed :                    // a is NaN, return b
                       s1_b_is_nan ? a_packed :                    // b is NaN, return a
                       use_a ? a_packed : b_packed;                 // normal comparison

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s2_result_q <= {FP_WIDTH{1'b0}};
        else begin
            if (s1_v)
                s2_result_q <= s2_result;
        end
    end

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            chn_o_rsc_z_q <= {FP_WIDTH{1'b0}};
        else begin
            if (s2_v)
                chn_o_rsc_z_q <= s2_result_q;
        end
    end

endmodule