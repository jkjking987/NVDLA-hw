// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp32_mul.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   3-stage floating-point multiplier for fp32 (1 sign + 8 expo + 23 mantissa)
//   Implements FpMul<8,23> algorithm from nvdla_float.h
//   - Stage 1: Input handshake and unpack to sign/expo/mantissa
//   - Stage 2: Multiply mantissas, add exponents, normalize
//   - Stage 3: RNE rounding, special case handling, pack
// +FHDR------------------------------------------------------------

// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

module fp32_mul (
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
    parameter EXPO_WIDTH = 8;    // fp32 has 8-bit exponent
    parameter MANT_WIDTH = 23;  // fp32 has 23-bit mantissa
    parameter FP_WIDTH = 32;    // 1 + EXPO_WIDTH + MANT_WIDTH
    localparam K_EXPO_MAX = (1 << EXPO_WIDTH) - 1;  // 255
    localparam K_EXPO_BIAS = (1 << (EXPO_WIDTH - 1)) - 1;  // 127
    localparam K_P_MANT_WIDTH = 2 * MANT_WIDTH + 1;  // 47 (product mantissa width)

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
    reg s3_v;

    // Stage 1: unpacked values
    reg        s1_a_sign_q;
    reg [EXPO_WIDTH-1:0] s1_a_expo_q;
    reg [MANT_WIDTH-1:0] s1_a_mant_q;
    reg        s1_b_sign_q;
    reg [EXPO_WIDTH-1:0] s1_b_expo_q;
    reg [MANT_WIDTH-1:0] s1_b_mant_q;

    // Stage 2: multiplication results
    reg        s2_o_sign_q;
    reg [EXPO_WIDTH-1:0] s2_o_expo_q;
    reg [K_P_MANT_WIDTH-1:0] s2_product_mant_q;
    reg        s2_is_zero_q;
    reg        s2_is_inf_q;
    reg        s2_a_is_nan_q;
    reg        s2_b_is_nan_q;
    // Store original operand values for NaN propagation
    reg        s2_a_sign_q;
    reg [EXPO_WIDTH-1:0] s2_a_expo_q;
    reg [MANT_WIDTH-1:0] s2_a_mant_q;
    reg        s2_b_sign_q;
    reg [EXPO_WIDTH-1:0] s2_b_expo_q;
    reg [MANT_WIDTH-1:0] s2_b_mant_q;

    // Stage 3: final values before packing
    reg  [1:0] s3_o_sign_q;
    reg  [EXPO_WIDTH-1:0] s3_o_expo_q;
    reg  [MANT_WIDTH-1:0] s3_o_mant_q;

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
            output_valid_q <= s3_v;
    end

    // ================================================================
    // Stage 1: Input Register and Unpack
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s1_v <= 1'b0;
        else begin
            if (s3_v)
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
    // Stage 2: Multiply Mantissas, Add Exponents, Normalize
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s2_v <= 1'b0;
        else begin
            if (s3_v)
                s2_v <= 1'b0;
            else
                s2_v <= s1_v;
        end
    end

    wire        s2_o_sign;
    wire [EXPO_WIDTH-1:0] s2_o_expo;
    wire [K_P_MANT_WIDTH-1:0] s2_product_mant;
    wire        s2_is_zero;
    wire        s2_is_inf;
    wire        s2_a_is_nan;
    wire        s2_b_is_nan;

    // Special case detection
    wire s1_a_is_nan;
    wire s1_b_is_nan;
    wire s1_a_is_inf;
    wire s1_b_is_inf;
    wire s1_a_is_zero;
    wire s1_b_is_zero;

    assign s1_a_is_nan  = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q != {MANT_WIDTH{1'b0}});
    assign s1_b_is_nan  = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q != {MANT_WIDTH{1'b0}});
    assign s1_a_is_inf  = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q == {MANT_WIDTH{1'b0}});
    assign s1_b_is_inf  = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q == {MANT_WIDTH{1'b0}});
    assign s1_a_is_zero = (s1_a_expo_q == {EXPO_WIDTH{1'b0}}) && (s1_a_mant_q == {MANT_WIDTH{1'b0}});
    assign s1_b_is_zero = (s1_b_expo_q == {EXPO_WIDTH{1'b0}}) && (s1_b_mant_q == {MANT_WIDTH{1'b0}});

    // Sign = a_sign XOR b_sign
    assign s2_o_sign = s1_a_sign_q ^ s1_b_sign_q;

    // Mantissa multiplication: 24-bit * 24-bit = 48-bit product
    // Add implied 1 to mantissa (unless operand is zero)
    wire [MANT_WIDTH:0] a_mant_p1;
    wire [MANT_WIDTH:0] b_mant_p1;
    assign a_mant_p1 = s1_a_is_zero
                       ? {1'b0, s1_a_mant_q}
                       : {1'b1, s1_a_mant_q};
    assign b_mant_p1 = s1_b_is_zero
                       ? {1'b0, s1_b_mant_q}
                       : {1'b1, s1_b_mant_q};

    wire [2*MANT_WIDTH+1:0] product_full;  // 48-bit product
    assign product_full = a_mant_p1 * b_mant_p1;

    // Exponent calculation and normalization
    wire [EXPO_WIDTH:0] sum_expo;  // 9-bit to avoid overflow
    wire [EXPO_WIDTH-1:0] raw_expo;

    assign sum_expo = s1_a_expo_q + s1_b_expo_q;
    assign raw_expo = sum_expo - K_EXPO_BIAS;

    // Check for zero result
    assign s2_is_zero = s1_a_is_zero || s1_b_is_zero || (raw_expo < {{EXPO_WIDTH{1'b0}}, 1'b1});

    // Check for overflow/inf
    assign s2_is_inf = (raw_expo >= {1'b0, K_EXPO_MAX}) && !s2_is_zero;

    // Normalized exponent
    wire need_shift_left;
    wire need_shift_right;
    wire product_top_bit;

    assign product_top_bit = product_full[K_P_MANT_WIDTH-1];  // bit 46 (MSB of 47-bit product)

    assign need_shift_right = product_top_bit;
    assign need_shift_left  = ~product_top_bit && !s2_is_zero && !s2_is_inf;

    wire [EXPO_WIDTH-1:0] expo_normalized;
    wire [K_P_MANT_WIDTH-2:0] product_mant_shifted;

    assign expo_normalized = need_shift_right
                             ? (raw_expo + 1)
                             : (need_shift_left ? (raw_expo - 1) : raw_expo);

    assign product_mant_shifted = need_shift_right
                                  ? product_full[K_P_MANT_WIDTH-2:0]
                                  : (need_shift_left
                                     ? {product_full[K_P_MANT_WIDTH-3:0], 1'b0}
                                     : product_full[K_P_MANT_WIDTH-2:0]);

    assign s2_o_expo = s2_is_zero
                       ? {EXPO_WIDTH{1'b0}}
                       : (s2_is_inf ? {EXPO_WIDTH{1'b1}} : expo_normalized);

    assign s2_product_mant = {product_top_bit, product_mant_shifted};

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s2_o_sign_q     <= 1'b0;
            s2_o_expo_q     <= {EXPO_WIDTH{1'b0}};
            s2_product_mant_q <= {K_P_MANT_WIDTH{1'b0}};
            s2_is_zero_q   <= 1'b0;
            s2_is_inf_q     <= 1'b0;
            s2_a_is_nan_q   <= 1'b0;
            s2_b_is_nan_q   <= 1'b0;
            s2_a_sign_q     <= 1'b0;
            s2_a_expo_q     <= {EXPO_WIDTH{1'b0}};
            s2_a_mant_q     <= {MANT_WIDTH{1'b0}};
            s2_b_sign_q     <= 1'b0;
            s2_b_expo_q     <= {EXPO_WIDTH{1'b0}};
            s2_b_mant_q     <= {MANT_WIDTH{1'b0}};
        end else begin
            s2_o_sign_q     <= s2_o_sign;
            s2_o_expo_q     <= s2_o_expo;
            s2_product_mant_q <= s2_product_mant;
            s2_is_zero_q    <= s2_is_zero;
            s2_is_inf_q     <= s2_is_inf;
            s2_a_is_nan_q   <= s1_a_is_nan;
            s2_b_is_nan_q   <= s1_b_is_nan;
            s2_a_sign_q     <= s1_a_sign_q;
            s2_a_expo_q     <= s1_a_expo_q;
            s2_a_mant_q     <= s1_a_mant_q;
            s2_b_sign_q     <= s1_b_sign_q;
            s2_b_expo_q     <= s1_b_expo_q;
            s2_b_mant_q     <= s1_b_mant_q;
        end
    end

    // ================================================================
    // Stage 3: Normalize, Round, Special Cases, Pack
    // ================================================================
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            s3_v <= 1'b0;
        else
            s3_v <= s2_v;
    end

    // RNE rounding: extract mantissa bits for rounding decision
    wire [MANT_WIDTH:0] mant_to_round;  // 24 bits: 1 implicit + 23 explicit
    wire guard_bit;
    wire round_bit;
    wire sticky_bit;
    wire lsb_bit;
    wire round_up;

    assign mant_to_round = s2_product_mant_q[K_P_MANT_WIDTH-2:K_MANT_WIDTH-1];  // bits [46:23]
    assign guard_bit = s2_product_mant_q[MANT_WIDTH-1];  // bit 22
    assign round_bit = s2_product_mant_q[MANT_WIDTH-2];  // bit 21
    assign sticky_bit = |s2_product_mant_q[MANT_WIDTH-3:0];  // bits [20:0]
    assign lsb_bit = mant_to_round[0];  // LSB of the 23-bit mantissa

    assign round_up = guard_bit && (sticky_bit || round_bit || lsb_bit);

    wire [MANT_WIDTH:0] rounded_mant;
    wire rounding_overflow;

    assign rounded_mant = mant_to_round + (round_up ? (MANT_WIDTH+1'd1) : (MANT_WIDTH+1'd0));
    assign rounding_overflow = rounded_mant[MANT_WIDTH];  // carry out = overflow

    wire [MANT_WIDTH-1:0] final_mant;
    wire [EXPO_WIDTH-1:0] final_expo;

    assign final_mant = rounding_overflow
                         ? rounded_mant[MANT_WIDTH-1:0]
                         : rounded_mant[MANT_WIDTH-1:0];
    assign final_expo = s2_o_expo_q + (rounding_overflow ? {{EXPO_WIDTH-1{1'b0}}, 1'b1} : {EXPO_WIDTH{1'b0}});

    // Special case handling
    wire [1:0] special_sign;
    wire [EXPO_WIDTH-1:0] special_expo;
    wire [MANT_WIDTH-1:0] special_mant;
    wire is_special;

    assign is_special = s2_a_is_nan_q || s2_b_is_nan_q;
    assign special_sign = s2_a_is_nan_q
                          ? {1'b0, s2_a_sign_q}
                          : {1'b0, s2_b_sign_q};
    assign special_expo = s2_a_is_nan_q
                          ? s2_a_expo_q
                          : s2_b_expo_q;
    assign special_mant = s2_a_is_nan_q
                          ? s2_a_mant_q
                          : s2_b_mant_q;

    wire [1:0] result_sign;
    wire [EXPO_WIDTH-1:0] result_expo;
    wire [MANT_WIDTH-1:0] result_mant;

    assign result_sign = is_special
                         ? special_sign
                         : {1'b0, s2_o_sign_q};
    assign result_expo = is_special
                         ? special_expo
                         : (s2_is_inf_q ? {EXPO_WIDTH{1'b1}} : final_expo);
    assign result_mant = is_special
                          ? special_mant
                          : (s2_is_inf_q ? {MANT_WIDTH{1'b1}} : final_mant);

    wire [FP_WIDTH-1:0] result_packed;
    assign result_packed = {result_sign[0], result_expo, result_mant};

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s3_o_sign_q <= 2'b0;
            s3_o_expo_q <= {EXPO_WIDTH{1'b0}};
            s3_o_mant_q <= {MANT_WIDTH{1'b0}};
        end else begin
            s3_o_sign_q <= result_sign;
            s3_o_expo_q <= result_expo;
            s3_o_mant_q <= result_mant;
        end
    end

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            chn_o_rsc_z_q <= {FP_WIDTH{1'b0}};
        else begin
            if (s3_v)
                chn_o_rsc_z_q <= result_packed;
        end
    end

endmodule