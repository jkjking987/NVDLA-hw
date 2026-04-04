// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp17_to_fp32.v
// Author        : Wolley Hardware Team
// Author Email  : hw@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Floating-point format converter: fp17 (1+6+10) to fp32 (1+8+23)
// - Unpack fp17: sign, 6-bit exponent, 10-bit mantissa
// - Expand exponent: add bias difference (127 - 31 = 96)
// - Shift mantissa from 10 bits to 23 bits (left shift by 13)
// - Handle special cases: zero, inf, NaN pass through
// - Pack to 32-bit format
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module fp17_to_fp32 (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_o_rsc_z,
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

// Clock and reset
input  nvdla_core_clk;
input  nvdla_core_rstn;

// Input channel (fp17: 1+6+10 = 17 bits)
input  [16:0] chn_a_rsc_z;
input         chn_a_rsc_vz;
input         chn_a_rsc_lz;

// Output channel (fp32: 1+8+23 = 32 bits)
output [31:0] chn_o_rsc_z;
output        chn_o_rsc_vz;
output        chn_o_rsc_lz;

// -----------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------
parameter I_EXPO_WIDTH = 6;
parameter I_MANT_WIDTH = 10;
parameter I_FP_WIDTH   = 17;
parameter O_EXPO_WIDTH = 8;
parameter O_MANT_WIDTH = 23;
parameter O_FP_WIDTH   = 32;

localparam I_BIAS = (1 << (I_EXPO_WIDTH - 1)) - 1;  // 31 for 6-bit exponent
localparam O_BIAS = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 127 for 8-bit exponent
localparam BIAS_DIFF = O_BIAS - I_BIAS;             // 96
localparam MANT_SHIFT = O_MANT_WIDTH - I_MANT_WIDTH; // 13 bits shift

// -----------------------------------------------------------------
// Input stage registers
// -----------------------------------------------------------------
reg [I_FP_WIDTH-1:0]  fp17_reg;
reg                   chn_a_rsc_vz_reg;
reg                   chn_a_rsc_lz_reg;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        fp17_reg         <= {I_FP_WIDTH{1'b0}};
        chn_a_rsc_vz_reg <= 1'b0;
        chn_a_rsc_lz_reg <= 1'b0;
    end else begin
        if (chn_a_rsc_vz) begin
            fp17_reg         <= chn_a_rsc_z;
            chn_a_rsc_vz_reg <= chn_a_rsc_vz;
            chn_a_rsc_lz_reg <= chn_a_rsc_lz;
        end else begin
            chn_a_rsc_vz_reg <= 1'b0;
            chn_a_rsc_lz_reg <= 1'b0;
        end
    end
end

// -----------------------------------------------------------------
// Unpack fp17
// -----------------------------------------------------------------
wire                  fp17_sign;
wire [I_EXPO_WIDTH-1:0] fp17_expo;
wire [I_MANT_WIDTH-1:0] fp17_mant;

assign fp17_sign = fp17_reg[I_FP_WIDTH-1];
assign fp17_expo = fp17_reg[I_FP_WIDTH-2:I_MANT_WIDTH];
assign fp17_mant = fp17_reg[I_MANT_WIDTH-1:0];

// -----------------------------------------------------------------
// Special case detection
// -----------------------------------------------------------------
// Zero: exponent and mantissa all zeros
wire is_zero = (fp17_expo == {I_EXPO_WIDTH{1'b0}}) && (fp17_mant == {I_MANT_WIDTH{1'b0}});

// Infinity: exponent all ones, mantissa all zeros
wire is_inf = (fp17_expo == {I_EXPO_WIDTH{1'b1}}) && (fp17_mant == {I_MANT_WIDTH{1'b0}});

// NaN: exponent all ones, mantissa non-zero
wire is_nan = (fp17_expo == {I_EXPO_WIDTH{1'b1}}) && (fp17_mant != {I_MANT_WIDTH{1'b0}});

// Subnormal (fp17): exponent all zeros, mantissa non-zero
wire is_subnormal = (fp17_expo == {I_EXPO_WIDTH{1'b0}}) && (fp17_mant != {I_MANT_WIDTH{1'b0}});

// -----------------------------------------------------------------
// Exponent expansion
// -----------------------------------------------------------------
// For normal values: new_expo = old_expo + BIAS_DIFF
// For subnormal: handled separately below
wire [O_EXPO_WIDTH-1:0] expo_normal;
assign expo_normal = fp17_expo[O_EXPO_WIDTH-1:0] + BIAS_DIFF[O_EXPO_WIDTH-1:0];

// For subnormal fp17, we need to shift the mantissa right to normalize
// The effective exponent becomes 1 - I_BIAS (leading 0 before mantissa)
// Then apply bias difference to get fp32 exponent
wire [O_EXPO_WIDTH-1:0] expo_subnormal;
wire [I_MANT_WIDTH-1:0] subnormal_mant;
wire [O_MANT_WIDTH-1:0] subnormal_mant_shifted;

// Count leading zeros in subnormal mantissa for normalization
// For 10-bit mantissa, CLZ result is 0-9
wire [3:0] clz_count;
assign clz_count = (fp17_mant[9:8] == 2'b00) ? 4'd2 :
                    (fp17_mant[9:7] == 3'b000) ? 4'd3 :
                    (fp17_mant[9:6] == 4'b0000) ? 4'd4 :
                    (fp17_mant[9:5] == 5'b00000) ? 4'd5 :
                    (fp17_mant[9:4] == 6'b000000) ? 4'd6 :
                    (fp17_mant[9:3] == 7'b0000000) ? 4'd7 :
                    (fp17_mant[9:2] == 8'b00000000) ? 4'd8 :
                    (fp17_mant[9] == 1'b0) ? 4'd9 : 4'd0;

// Subnormal exponent: (1 - I_BIAS) + BIAS_DIFF = 1 - I_BIAS + BIAS_DIFF = 1 - 31 + 96 = 66
// But we also need to account for the left shift by clz_count
// Effective exponent after normalization: 1 - I_BIAS - clz_count + BIAS_DIFF
// = 1 - 31 - clz_count + 96 = 66 - clz_count
wire [O_EXPO_WIDTH-1:0] expo_subnormal_calc;
assign expo_subnormal_calc = 8'd66 - {4'b0, clz_count};

// Shift subnormal mantissa left by clz_count positions
// The implicit 1. is not present in subnormal, so we shift until leading 1 appears
assign subnormal_mant_shifted = {fp17_mant, {O_MANT_WIDTH-I_MANT_WIDTH{1'b0}}} << clz_count;

// Use subnormal exponent when is_subnormal, otherwise use normal exponent
wire [O_EXPO_WIDTH-1:0] fp32_expo;
assign fp32_expo = is_subnormal ? expo_subnormal_calc : expo_normal;

// -----------------------------------------------------------------
// Mantissa expansion (10 bits -> 23 bits)
// -----------------------------------------------------------------
// For normal values: left shift by 13
// For subnormal: already shifted above
wire [O_MANT_WIDTH-1:0] fp32_mant_normal;
assign fp32_mant_normal = {fp17_mant, {O_MANT_WIDTH-I_MANT_WIDTH{1'b0}}};

wire [O_MANT_WIDTH-1:0] fp32_mant;
assign fp32_mant = is_subnormal ? subnormal_mant_shifted : fp32_mant_normal;

// -----------------------------------------------------------------
// Handle special cases and pack fp32
// -----------------------------------------------------------------
reg [O_FP_WIDTH-1:0] fp32_result;
reg                  fp32_vz;
reg                  fp32_lz;

always @* begin
    fp32_result = {O_FP_WIDTH{1'b0}};
    if (is_zero) begin
        // Zero: all bits zero
        fp32_result = {O_FP_WIDTH{1'b0}};
    end else if (is_inf) begin
        // Infinity: exponent all ones, mantissa zero
        fp32_result = {1'b0, {O_EXPO_WIDTH{1'b1}}, {O_MANT_WIDTH{1'b0}}};
    end else if (is_nan) begin
        // NaN: exponent all ones, mantissa non-zero (preserve payload)
        fp32_result = {1'b0, {O_EXPO_WIDTH{1'b1}}, fp32_mant};
    end else begin
        // Normal number or subnormal
        fp32_result = {fp17_sign, fp32_expo, fp32_mant};
    end
end

// -----------------------------------------------------------------
// Output stage
// -----------------------------------------------------------------
reg [31:0] chn_o_rsc_z_int;
reg        chn_o_rsc_vz_int;
reg        chn_o_rsc_lz_int;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        chn_o_rsc_z_int  <= {O_FP_WIDTH{1'b0}};
        chn_o_rsc_vz_int <= 1'b0;
        chn_o_rsc_lz_int <= 1'b0;
    end else begin
        chn_o_rsc_z_int  <= fp32_result;
        chn_o_rsc_vz_int <= chn_a_rsc_vz_reg;
        chn_o_rsc_lz_int <= chn_a_rsc_lz_reg;
    end
end

assign chn_o_rsc_z  = chn_o_rsc_z_int;
assign chn_o_rsc_vz = chn_o_rsc_vz_int;
assign chn_o_rsc_lz = chn_o_rsc_lz_int;

endmodule
