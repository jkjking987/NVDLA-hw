// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp17_min.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   Floating-point min selector for fp17 (1 sign + 6 expo + 10 mantissa)
//   Implements FpMin<6,10> algorithm from nvdla_float.h
//   - Returns the smaller of two fp17 values
//   - NaN handling: if either input is NaN, output the other
// +FHDR------------------------------------------------------------

// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

module fp17_min (
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
    parameter FP_WIDTH = 17;    // 1 + EXPO_WIDTH + MANT_WIDTH

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
    reg output_valid_q;

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
    // Stage 2: Compare and Select (Min)
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s2_v <= 1'b0;
        else
            s2_v <= s1_v;
    end

    // Special case detection
    wire s1_a_is_nan;
    wire s1_b_is_nan;
    wire s1_a_is_inf;
    wire s1_b_is_inf;
    wire s1_a_is_zero;
    wire s1_b_is_zero;

    assign s1_a_is_nan = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q != {MANT_WIDTH{1'b0}});
    assign s1_b_is_nan = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q != {MANT_WIDTH{1'b0}});
    assign s1_a_is_inf = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q == {MANT_WIDTH{1'b0}});
    assign s1_b_is_inf = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q == {MANT_WIDTH{1'b0}});
    assign s1_a_is_zero = (s1_a_expo_q == {EXPO_WIDTH{1'b0}}) && (s1_a_mant_q == {MANT_WIDTH{1'b0}});
    assign s1_b_is_zero = (s1_b_expo_q == {EXPO_WIDTH{1'b0}}) && (s1_b_mant_q == {MANT_WIDTH{1'b0}});

    // Compare absolute values (exponent first, then mantissa)
    wire abs_a_greater;
    wire abs_b_greater;
    wire exp_a_greater;
    wire exp_b_greater;
    wire mant_a_greater;
    wire mant_b_greater;

    assign exp_a_greater = (s1_a_expo_q > s1_b_expo_q);
    assign exp_b_greater = (s1_a_expo_q < s1_b_expo_q);
    assign mant_a_greater = (s1_a_mant_q > s1_b_mant_q);
    assign mant_b_greater = (s1_a_mant_q < s1_b_mant_q);

    assign abs_a_greater = exp_a_greater || ((s1_a_expo_q == s1_b_expo_q) && mant_a_greater);
    assign abs_b_greater = exp_b_greater || ((s1_a_expo_q == s1_b_expo_q) && mant_b_greater);

    // Determine if a is greater (considering sign)
    wire is_a_positive;
    wire is_b_positive;
    wire is_a_greater;

    assign is_a_positive = (s1_a_sign_q == 1'b0);
    assign is_b_positive = (s1_b_sign_q == 1'b0);

    // Logic from FpCmp: a is greater if:
    // - a positive, b positive: abs comparison result
    // - a positive, b negative: always true
    // - a negative, b positive: always false
    // - a negative, b negative: inverted abs comparison
    wire is_a_greater_raw;
    assign is_a_greater_raw = is_a_positive ?
                              (is_b_positive ? abs_a_greater : 1'b1) :
                              (is_b_positive ? 1'b0 : abs_b_greater);

    // For MIN: return the smaller value
    // If a is greater (raw), return b; otherwise return a
    // But need to handle NaN: if either is NaN, return the other
    wire [FP_WIDTH-1:0] raw_result;
    wire [FP_WIDTH-1:0] nan_result;

    assign raw_result = is_a_greater_raw ? {s1_b_sign_q, s1_b_expo_q, s1_b_mant_q}
                                         : {s1_a_sign_q, s1_a_expo_q, s1_a_mant_q};

    // NaN handling: if a is NaN, return b; if b is NaN, return a
    assign nan_result = s1_a_is_nan ? {s1_b_sign_q, s1_b_expo_q, s1_b_mant_q} :
                        s1_b_is_nan ? {s1_a_sign_q, s1_a_expo_q, s1_a_mant_q} :
                                      raw_result;

    // Special case: INF handling - negative infinity is smaller than any other value
    // positive infinity is larger than any other value
    wire is_neg_inf_a;
    wire is_neg_inf_b;
    wire [FP_WIDTH-1:0] inf_result;

    assign is_neg_inf_a = s1_a_is_inf && (s1_a_sign_q == 1'b1);
    assign is_neg_inf_b = s1_b_is_inf && (s1_b_sign_q == 1'b1);

    // If one is negative infinity and other is not positive infinity, return neg inf
    // If one is positive infinity, return the other
    wire [FP_WIDTH-1:0] cmp_result;
    assign cmp_result = (is_neg_inf_a && !(s1_b_is_inf && (s1_b_sign_q == 1'b0))) ?
                        {s1_a_sign_q, s1_a_expo_q, s1_a_mant_q} :
                        (is_neg_inf_b && !(s1_a_is_inf && (s1_a_sign_q == 1'b0))) ?
                        {s1_b_sign_q, s1_b_expo_q, s1_b_mant_q} :
                        (s1_a_is_inf && (s1_a_sign_q == 1'b0)) ?
                        {s1_b_sign_q, s1_b_expo_q, s1_b_mant_q} :
                        (s1_b_is_inf && (s1_b_sign_q == 1'b0)) ?
                        {s1_a_sign_q, s1_a_expo_q, s1_a_mant_q} :
                        nan_result;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s2_result_q <= {FP_WIDTH{1'b0}};
        else begin
            if (s1_v)
                s2_result_q <= cmp_result;
        end
    end

    // ================================================================
    // Output Register
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            chn_o_rsc_z_q <= {FP_WIDTH{1'b0}};
        else begin
            if (s2_v)
                chn_o_rsc_z_q <= s2_result_q;
        end
    end

endmodule