// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp17_add.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   3-stage floating-point adder for fp17 (1 sign + 6 expo + 10 mantissa)
//   Implements FpAdd<6,10> algorithm from nvdla_float.h
//   - Stage 1: Input handshake and unpack to sign/expo/mantissa
//   - Stage 2: Exponent compare, align mantissas, add/subtract
//   - Stage 3: Normalize, RNE rounding, special case handling, pack
// +FHDR------------------------------------------------------------

// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: fp17_add.v

module fp17_add (
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
    parameter EXPO_WIDTH = 6;
    parameter MANT_WIDTH = 10;
    parameter FP_WIDTH = 17;  // 1 + EXPO_WIDTH + MANT_WIDTH
    localparam K_EXPO_MAX = (1 << EXPO_WIDTH) - 1;  // 63
    localparam K_EXPO_BIAS = (1 << (EXPO_WIDTH - 1)) - 1;  // 31
    localparam K_MANT_MORE_WIDTH = MANT_WIDTH + 2;  // 12
    localparam INTERNAL_MANT_WIDTH = K_MANT_MORE_WIDTH + MANT_WIDTH + 1;  // 23

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

    // Stage 2: comparison and alignment results
    reg        s2_a_greater_q;
    reg        s2_is_addition_q;
    reg  [1:0] s2_o_sign_q;
    reg  [EXPO_WIDTH-1:0] s2_o_expo_q;
    reg  [INTERNAL_MANT_WIDTH-1:0] s2_int_mant_q;
    reg        s2_overflow_q;

    // Stage 3: final values before packing
    reg  [1:0] s3_o_sign_q;
    reg  [EXPO_WIDTH-1:0] s3_o_expo_q;
    reg  [MANT_WIDTH-1:0] s3_o_mant_q;

    // Output register
    reg [FP_WIDTH-1:0] chn_o_rsc_z_q;

    // ================================================================
    // Handshake Logic
    // ================================================================
    // Ready when output consumer is ready (handshaking flows through)
    assign chn_a_rdy = chn_o_rsc_vz;
    assign chn_b_rdy = chn_o_rsc_vz;

    // Handshake: accept inputs when consumer ready and inputs valid
    assign inputAccepted = chn_o_rsc_vz && chn_a_rsc_vz && chn_b_rsc_vz;

    // Output handshake
    assign chn_a_rsc_lz = chn_o_rsc_vz && chn_a_rsc_vz;
    assign chn_b_rsc_lz = chn_o_rsc_vz && chn_b_rsc_vz;
    assign chn_o_rsc_lz = output_valid_q;
    assign chn_o_rsc_z = chn_o_rsc_z_q;

    // Output valid control
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            output_valid_q <= 1'b0;
        end else begin
            output_valid_q <= s3_v;
        end
    end

    // ================================================================
    // Stage 1: Input Register and Unpack
    // ================================================================
    // Valid signal for stage 1
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s1_v <= 1'b0;
        end else begin
            if (s3_v) begin
                // Stage 1 will be free after this cycle (output consumed)
                s1_v <= 1'b0;
            end else if (inputAccepted) begin
                s1_v <= 1'b1;
            end
        end
    end

    // Stage 1 data registers
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
                // Unpack input A
                s1_a_sign_q <= chn_a_rsc_z[FP_WIDTH-1];
                s1_a_expo_q <= chn_a_rsc_z[FP_WIDTH-2:MANT_WIDTH];
                s1_a_mant_q <= chn_a_rsc_z[MANT_WIDTH-1:0];
                // Unpack input B
                s1_b_sign_q <= chn_b_rsc_z[FP_WIDTH-1];
                s1_b_expo_q <= chn_b_rsc_z[FP_WIDTH-2:MANT_WIDTH];
                s1_b_mant_q <= chn_b_rsc_z[MANT_WIDTH-1:0];
            end
        end
    end

    // ================================================================
    // Stage 2: Exponent Compare, Alignment, and Addition
    // ================================================================
    // Stage 2 valid signal
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s2_v <= 1'b0;
        end else begin
            if (s3_v) begin
                s2_v <= 1'b0;
            end else begin
                s2_v <= s1_v;
            end
        end
    end

    // Stage 2 combinational logic
    wire        s2_a_greater;
    wire        s2_is_addition;
    wire [1:0]  s2_o_sign;
    wire [EXPO_WIDTH-1:0] s2_o_expo;
    wire [INTERNAL_MANT_WIDTH-1:0] s2_int_mant;
    wire        s2_overflow;

    // Stage 2: compare exponents and determine which operand is larger
    assign s2_a_greater = (s1_a_expo_q > s1_b_expo_q) ||
                          ((s1_a_expo_q == s1_b_expo_q) && (s1_a_mant_q >= s1_b_mant_q));

    // o_expo = max(a_expo, b_expo)
    assign s2_o_expo = s2_a_greater ? s1_a_expo_q : s1_b_expo_q;

    // o_sign follows the sign of the larger operand
    assign s2_o_sign = s2_a_greater ? {1'b0, s1_a_sign_q} : {1'b0, s1_b_sign_q};

    // is_addition when signs are the same
    assign s2_is_addition = (s1_a_sign_q == s1_b_sign_q);

    // Mantissa with implied 1 (for normalized numbers)
    // Zero has implied 0, normalized has implied 1
    wire [MANT_WIDTH:0] a_mant_p1;
    wire [MANT_WIDTH:0] b_mant_p1;
    assign a_mant_p1 = (s1_a_expo_q == {EXPO_WIDTH{1'b0}} && s1_a_mant_q == {MANT_WIDTH{1'b0}})
                       ? {1'b0, s1_a_mant_q}
                       : {1'b1, s1_a_mant_q};
    assign b_mant_p1 = (s1_b_expo_q == {EXPO_WIDTH{1'b0}} && s1_b_mant_q == {MANT_WIDTH{1'b0}})
                       ? {1'b0, s1_b_mant_q}
                       : {1'b1, s1_b_mant_q};

    // Compute right shifts for alignment
    wire [EXPO_WIDTH-1:0] a_right_shift;
    wire [EXPO_WIDTH-1:0] b_right_shift;
    assign a_right_shift = s2_a_greater ? {EXPO_WIDTH{1'b0}} : (s1_b_expo_q - s1_a_expo_q);
    assign b_right_shift = s2_a_greater ? (s1_a_expo_q - s1_b_expo_q) : {EXPO_WIDTH{1'b0}};

    // Left shift amounts for expanding to internal mantissa width
    wire [EXPO_WIDTH:0] a_left_shift;
    wire [EXPO_WIDTH:0] b_left_shift;
    assign a_left_shift = K_MANT_MORE_WIDTH - a_right_shift;
    assign b_left_shift = K_MANT_MORE_WIDTH - b_right_shift;

    // Extended mantissas (11 bits: 1 implied + 10 mantissa bits)
    wire [10:0] a_ext_mant;
    wire [10:0] b_ext_mant;
    assign a_ext_mant = a_mant_p1;
    assign b_ext_mant = b_mant_p1;

    // Shifted mantissas for internal computation
    wire [INTERNAL_MANT_WIDTH-1:0] a_int_mant;
    wire [INTERNAL_MANT_WIDTH-1:0] b_int_mant;
    assign a_int_mant = ({1'b0, a_ext_mant} << a_left_shift);
    assign b_int_mant = ({1'b0, b_ext_mant} << b_left_shift);

    // Select larger and smaller mantissas for add/sub
    wire [INTERNAL_MANT_WIDTH-1:0] addend_larger;
    wire [INTERNAL_MANT_WIDTH-1:0] addend_smaller;
    assign addend_larger  = s2_a_greater ? a_int_mant : b_int_mant;
    assign addend_smaller = s2_a_greater ? b_int_mant : a_int_mant;

    // Add or subtract mantissas (result is INTERNAL_MANT_WIDTH+1 bits)
    wire [INTERNAL_MANT_WIDTH:0] int_mant_p1;
    assign int_mant_p1 = s2_is_addition
                         ? ({1'b0, addend_larger} + {1'b0, addend_smaller})
                         : ({1'b0, addend_larger} - {1'b0, addend_smaller});

    // Detect overflow (carry out from internal mantissa)
    assign s2_overflow = int_mant_p1[INTERNAL_MANT_WIDTH];

    // Handle overflow: shift right by 1 and increment exponent
    assign s2_int_mant = s2_overflow
                          ? (int_mant_p1[INTERNAL_MANT_WIDTH-1:0] >> 1)
                          : int_mant_p1[INTERNAL_MANT_WIDTH-1:0];

    // Stage 2 registers
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s2_a_greater_q <= 1'b0;
            s2_is_addition_q <= 1'b0;
            s2_o_sign_q <= 2'b0;
            s2_o_expo_q <= {EXPO_WIDTH{1'b0}};
            s2_int_mant_q <= {INTERNAL_MANT_WIDTH{1'b0}};
            s2_overflow_q <= 1'b0;
        end else begin
            s2_a_greater_q <= s2_a_greater;
            s2_is_addition_q <= s2_is_addition;
            s2_o_sign_q <= s2_o_sign;
            s2_o_expo_q <= s2_o_expo;
            s2_int_mant_q <= s2_int_mant;
            s2_overflow_q <= s2_overflow;
        end
    end

    // ================================================================
    // Stage 3: Normalize, Round, Special Cases, Pack
    // ================================================================
    // Stage 3 valid signal
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            s3_v <= 1'b0;
        end else begin
            s3_v <= s2_v;
        end
    end

    // Special case detection wires
    wire s2_a_is_nan;
    wire s2_b_is_nan;
    wire s2_a_is_inf;
    wire s2_b_is_inf;
    wire s2_a_is_zero;
    wire s2_b_is_zero;

    assign s2_a_is_nan = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q != {MANT_WIDTH{1'b0}});
    assign s2_b_is_nan = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q != {MANT_WIDTH{1'b0}});
    assign s2_a_is_inf = (s1_a_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_a_mant_q == {MANT_WIDTH{1'b0}});
    assign s2_b_is_inf = (s1_b_expo_q == {EXPO_WIDTH{1'b1}}) && (s1_b_mant_q == {MANT_WIDTH{1'b0}});
    assign s2_a_is_zero = (s1_a_expo_q == {EXPO_WIDTH{1'b0}}) && (s1_a_mant_q == {MANT_WIDTH{1'b0}});
    assign s2_b_is_zero = (s1_b_expo_q == {EXPO_WIDTH{1'b0}}) && (s1_b_mant_q == {MANT_WIDTH{1'b0}});

    // Stage 3 combinational logic for normalization
    wire [EXPO_WIDTH-1:0] s3_expo_norm;
    wire [INTERNAL_MANT_WIDTH-1:0] s3_int_mant_norm;

    // FpNormalize: count leading zeros and shift left
    // Find the position of the leading 1 in the mantissa
    wire [$clog2(INTERNAL_MANT_WIDTH)-1:0] lead_zeros;
    wire mant_is_zero;

    assign mant_is_zero = (s2_int_mant_q == {INTERNAL_MANT_WIDTH{1'b0}});

    // Priority encode to find leading zeros
    assign lead_zeros =
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-1]) ? 4'd0 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-2]) ? 4'd1 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-3]) ? 4'd2 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-4]) ? 4'd3 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-5]) ? 4'd4 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-6]) ? 4'd5 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-7]) ? 4'd6 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-8]) ? 4'd7 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-9]) ? 4'd8 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-10]) ? 4'd9 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-11]) ? 4'd10 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-12]) ? 4'd11 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-13]) ? 4'd12 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-14]) ? 4'd13 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-15]) ? 4'd14 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-16]) ? 4'd15 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-17]) ? 4'd16 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-18]) ? 4'd17 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-19]) ? 4'd18 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-20]) ? 4'd19 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-21]) ? 4'd20 :
        (s2_int_mant_q[INTERNAL_MANT_WIDTH-22]) ? 4'd21 :
        4'd22;

    // If overflow happened, mantissa is already normalized (MSB=1)
    // Otherwise, if no overflow, normalize by left shifting
    assign s3_int_mant_norm = s2_overflow_q
                               ? s2_int_mant_q
                               : (mant_is_zero ? {INTERNAL_MANT_WIDTH{1'b0}} : (s2_int_mant_q << lead_zeros));

    assign s3_expo_norm = s2_overflow_q
                           ? (s2_o_expo_q + 1)
                           : (mant_is_zero ? {EXPO_WIDTH{1'b0}} : (s2_o_expo_q - lead_zeros));

    // RNE Rounding: FpMantRNE<23,11>
    // Input is INTERNAL_MANT_WIDTH=23 bits, output is MantWidth+1=11 bits
    wire [MANT_WIDTH:0] rounded_mant_p1;
    wire rounding_overflow;

    // Extract parts for RNE rounding
    wire [10:0] mant_top;
    wire guard_bit;
    wire sticky_bit;
    wire lsb_bit;

    assign mant_top = s3_int_mant_norm[INTERNAL_MANT_WIDTH-1:MANT_WIDTH];  // Top 11 bits
    assign guard_bit = s3_int_mant_norm[MANT_WIDTH-1];   // Bit 10 (first truncated bit)
    assign sticky_bit = |s3_int_mant_norm[MANT_WIDTH-2:0];  // OR of remaining bits
    assign lsb_bit = mant_top[0];

    // RNE: round up if guard && (sticky || lsb)
    wire round_up;
    assign round_up = guard_bit && (sticky_bit || lsb_bit);

    assign rounded_mant_p1 = mant_top + (round_up ? (MANT_WIDTH+1'd1) : (MANT_WIDTH+1'd0));
    assign rounding_overflow = rounded_mant_p1[MANT_WIDTH];  // MSB of 11-bit result

    // Final mantissa after rounding (remove implied 1)
    wire [MANT_WIDTH-1:0] final_mant;
    assign final_mant = rounding_overflow
                        ? rounded_mant_p1[MANT_WIDTH-1:0]
                        : rounded_mant_p1[MANT_WIDTH-1:0];

    // Final exponent after rounding overflow
    wire [EXPO_WIDTH-1:0] final_expo;
    assign final_expo = rounding_overflow
                         ? (s3_expo_norm + 1)
                         : s3_expo_norm;

    // Handle special cases: NaN, Inf, Zero
    wire [1:0] special_sign;
    wire [EXPO_WIDTH-1:0] special_expo;
    wire [MANT_WIDTH-1:0] special_mant;
    wire is_special;

    // NaN takes priority
    assign is_special = s2_a_is_nan || s2_b_is_nan;
    assign special_sign = s2_a_is_nan ? {1'b0, s1_a_sign_q} :
                          s2_b_is_nan ? {1'b0, s1_b_sign_q} :
                          {1'b0, s2_o_sign_q[0]};
    assign special_expo = s2_a_is_nan ? s1_a_expo_q :
                          s2_b_is_nan ? s1_b_expo_q :
                          {EXPO_WIDTH{1'b1}};
    assign special_mant = s2_a_is_nan ? s1_a_mant_q :
                          s2_b_is_nan ? s1_b_mant_q :
                          {MANT_WIDTH{1'b1}};  // NaN/Inf mantissa

    // Final results
    wire [1:0] result_sign;
    wire [EXPO_WIDTH-1:0] result_expo;
    wire [MANT_WIDTH-1:0] result_mant;

    assign result_sign = is_special ? special_sign :
                         (s2_a_is_zero ? {1'b0, s1_b_sign_q} :
                          s2_b_is_zero ? {1'b0, s1_a_sign_q} :
                          {1'b0, s2_o_sign_q[0]});
    assign result_expo = is_special ? special_expo :
                         (s2_a_is_zero ? s1_b_expo_q :
                          s2_b_is_zero ? s1_a_expo_q :
                          final_expo);
    assign result_mant = is_special ? special_mant :
                         (s2_a_is_zero ? s1_b_mant_q :
                          s2_b_is_zero ? s1_a_mant_q :
                          final_mant);

    // Pack result: FpFloatToSignedBits<6,10>
    wire [FP_WIDTH-1:0] result_packed;
    assign result_packed = {result_sign[0], result_expo, result_mant};

    // Stage 3 registers
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

    // Output register
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            chn_o_rsc_z_q <= {FP_WIDTH{1'b0}};
        end else begin
            if (s3_v) begin
                chn_o_rsc_z_q <= result_packed;
            end
        end
    end

endmodule
