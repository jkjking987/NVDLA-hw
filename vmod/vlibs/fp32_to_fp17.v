// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp32_to_fp17.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Floating-point format converter: fp32 (1+8+23) to fp17 (1+6+10)
// - Unpack fp32: sign, 8-bit exponent, 23-bit mantissa
// - Convert exponent: subtract bias difference (127 - 31 = 96)
// - Handle potential overflow/underflow
// - RNE rounding from 23-bit to 10-bit mantissa
// - Handle special cases: zero, inf, NaN
// - Pack to 17-bit format (6-bit exponent)
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module fp32_to_fp17 (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_o_rsc_z,
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

// Clock and Reset
input  nvdla_core_clk;
input  nvdla_core_rstn;

// Parameters
parameter I_EXPO_WIDTH = 8;
parameter I_MANT_WIDTH = 23;
parameter I_FP_WIDTH   = 32;
parameter O_EXPO_WIDTH = 6;
parameter O_MANT_WIDTH = 10;
parameter O_FP_WIDTH   = 17;

parameter I_BIAS = (1 << (I_EXPO_WIDTH - 1)) - 1;  // 127
parameter O_BIAS = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 31
parameter BIAS_DIFF = I_BIAS - O_BIAS;              // 96
parameter O_EXPO_MAX = (1 << O_EXPO_WIDTH) - 1;    // 63
parameter O_EXPO_MIN = 0;

// Input Interface (fp32)
input  [I_FP_WIDTH-1:0] chn_a_rsc_z;
input                   chn_a_rsc_vz;
input                   chn_a_rsc_lz;

// Output Interface (fp17)
output [O_FP_WIDTH-1:0] chn_o_rsc_z;
output                  chn_o_rsc_vz;
output                  chn_o_rsc_lz;

// -----------------------------------------------------------------
// Internal Signals
// -----------------------------------------------------------------
// Unpacked fp32 components
wire                    fp32_sign;
wire [I_EXPO_WIDTH-1:0] fp32_expo;
wire [I_MANT_WIDTH-1:0] fp32_mant;

// Special case flags
wire                    fp32_is_nan;
wire                    fp32_is_inf;
wire                    fp32_is_zero;
wire                    fp32_is_subnorm;

// Converted exponent
wire signed [I_EXPO_WIDTH:0] expo_converted;  // signed for overflow check
wire [O_EXPO_WIDTH-1:0]      expo_out;
wire                         expo_overflow;

// RNE rounding signals
wire                   mant_round_bit;
wire                   mant_sticky_bit;
wire                   mant_rne_add;

// Mantissa after rounding
wire [O_MANT_WIDTH-1:0] mant_rounded;
wire                    mant_carry;

// Final output
reg  [O_FP_WIDTH-1:0] chn_o_rsc_z;
reg                   chn_o_rsc_vz;
reg                   chn_o_rsc_lz;

// Valid/ready handshake delay
reg                   pipe_valid_q;

// -----------------------------------------------------------------
// Step 1: Unpack fp32
// -----------------------------------------------------------------
assign fp32_sign = chn_a_rsc_z[I_FP_WIDTH-1];
assign fp32_expo = chn_a_rsc_z[I_FP_WIDTH-2:I_MANT_WIDTH];
assign fp32_mant = chn_a_rsc_z[I_MANT_WIDTH-1:0];

// -----------------------------------------------------------------
// Step 2: Detect special cases
// -----------------------------------------------------------------
assign fp32_is_nan   = (fp32_expo == {I_EXPO_WIDTH{1'b1}}) && (fp32_mant != {I_MANT_WIDTH{1'b0}});
assign fp32_is_inf   = (fp32_expo == {I_EXPO_WIDTH{1'b1}}) && (fp32_mant == {I_MANT_WIDTH{1'b0}});
assign fp32_is_zero  = (fp32_expo == {I_EXPO_WIDTH{1'b0}}) && (fp32_mant == {I_MANT_WIDTH{1'b0}});
assign fp32_is_subnorm = (fp32_expo == {I_EXPO_WIDTH{1'b0}}) && (fp32_mant != {I_MANT_WIDTH{1'b0}});

// -----------------------------------------------------------------
// Step 3: Exponent conversion
// -----------------------------------------------------------------
// For normal values: expo_out = fp32_expo - BIAS_DIFF
// For subnormal fp32: treat as if exponent = 1, then subtract BIAS_DIFF
wire [I_EXPO_WIDTH-1:0] fp32_expo_eff;
assign fp32_expo_eff = fp32_is_subnorm ? I_EXPO_WIDTH'(1) : fp32_expo;

// Converted exponent (may be negative or exceed output range)
assign expo_converted = $signed({1'b0, fp32_expo_eff}) - BIAS_DIFF;

// Overflow detection
assign expo_overflow  = (expo_converted > O_EXPO_MAX);

// Clamp exponent to valid output range
assign expo_out = (expo_converted > O_EXPO_MAX) ? O_EXPO_MAX :
                  (expo_converted < O_EXPO_MIN) ? O_EXPO_MIN :
                  expo_converted[O_EXPO_WIDTH-1:0];

// -----------------------------------------------------------------
// Step 4: Mantissa handling and RNE rounding
// -----------------------------------------------------------------
// For normal/subnormal fp32, implicit leading 1 is added
// fp32_mant with implicit 1: {1'b1, fp32_mant} for normal, {1'b0, fp32_mant} shifted for subnormal

// mant_normalized is not used in this simplified flow, keeping logic in mant_full below

// RNE rounding: round to nearest, tie to even
// We need to round from I_MANT_WIDTH bits (with implicit 1) to O_MANT_WIDTH bits
// mant_normalized has I_MANT_WIDTH+1 bits (bit[I_MANT_WIDTH] is the integer part)
// We need O_MANT_WIDTH bits of mantissa output, rounding from bit O_MANT_WIDTH-1

wire [I_MANT_WIDTH:0] mant_full;  // Full mantissa with integer bit
assign mant_full = fp32_is_zero ? {I_MANT_WIDTH+1{1'b0}} :
                   fp32_is_nan  ? {I_MANT_WIDTH+1{1'b0}} :
                   fp32_is_inf  ? {I_MANT_WIDTH+1{1'b0}} :
                   fp32_is_subnorm ? {1'b0, fp32_mant} >> (BIAS_DIFF - 1) :  // subnormal already shifted
                                   {1'b1, fp32_mant};

// For rounding: we extract O_MANT_WIDTH+1 bits from mant_full
// mant_full[23] = integer bit (implicit 1), mant_full[22:0] = fraction
// We need to round mant_full[(I_MANT_WIDTH-1) : (I_MANT_WIDTH - O_MANT_WIDTH)] to O_MANT_WIDTH bits

wire [O_MANT_WIDTH:0] mant_for_round;  // O_MANT_WIDTH + 1 bits for rounding
assign mant_for_round = (I_MANT_WIDTH >= O_MANT_WIDTH) ?
                        mant_full[I_MANT_WIDTH : I_MANT_WIDTH - O_MANT_WIDTH] :
                        {mant_full, {O_MANT_WIDTH - I_MANT_WIDTH{1'b0}}};

// mant_for_round[O_MANT_WIDTH] is the round bit
// mant_for_round[O_MANT_WIDTH-1:0] is the mantissa to keep
// Bits beyond are sticky

// Sticky = OR of all bits to the right of the round bit
wire [O_MANT_WIDTH-1:0] mant_lower;
wire [I_MANT_WIDTH-O_MANT_WIDTH-1:0] mant_lower_disc;
assign mant_lower = mant_for_round[O_MANT_WIDTH-1:0];
assign mant_lower_disc = (I_MANT_WIDTH > O_MANT_WIDTH) ?
                         mant_full[I_MANT_WIDTH - O_MANT_WIDTH - 1 : 0] :
                         {I_MANT_WIDTH - O_MANT_WIDTH{1'b0}};

assign mant_sticky_bit = (I_MANT_WIDTH > O_MANT_WIDTH) ? |mant_lower_disc : 1'b0;
assign mant_round_bit  = mant_for_round[O_MANT_WIDTH];

// RNE: round up if (round_bit AND (sticky OR (mant_even == 0)))
// Actually: round up if round_bit AND (sticky OR (lsb_of_mant == 1))
wire mant_even;
assign mant_even = mant_lower[0];
wire mant_rne_cond;
assign mant_rne_cond = mant_round_bit && (mant_sticky_bit || (!mant_even));
assign mant_rne_add = mant_rne_cond;

// mant_rounded = mant_lower + (mant_rne_add ? 1 : 0)
assign {mant_carry, mant_rounded} = mant_lower + (mant_rne_add ? {{O_MANT_WIDTH-1{1'b0}}, 1'b1} : {O_MANT_WIDTH{1'b0}});

// Handle case where rounding overflows (e.g., all 1s becoming all 0s with carry)
// If mant_carry = 1, we need to increment exponent as well
wire mant_overflow_rne;
assign mant_overflow_rne = mant_carry;

// -----------------------------------------------------------------
// Step 5: Handle special cases output
// -----------------------------------------------------------------
// NaN: exponent=all1, mantissa!=0 -> quiet NaN in fp17
// Keep sign, set exponent to all 1s, mantissa to non-zero (quiet NaN)
wire [O_EXPO_WIDTH-1:0] expo_nan;
assign expo_nan = {O_EXPO_WIDTH{1'b1}};

// Inf: exponent=all1, mantissa=0 -> infinity in fp17
wire [O_EXPO_WIDTH-1:0] expo_inf;
assign expo_inf = {O_EXPO_WIDTH{1'b1}};

// Zero: exponent=0, mantissa=0
wire [O_EXPO_WIDTH-1:0] expo_zero;
assign expo_zero = {O_EXPO_WIDTH{1'b0}};

// -----------------------------------------------------------------
// Step 6: Pack output
// -----------------------------------------------------------------
wire [O_FP_WIDTH-1:0] fp17_normal;
wire [O_FP_WIDTH-1:0] fp17_out_pre;

assign fp17_normal = {fp32_sign, expo_out, mant_rounded};

// Handle overflow from rounding: increment exponent
wire [O_EXPO_WIDTH-1:0] expo_overflow_adj;
assign expo_overflow_adj = expo_out + {{O_EXPO_WIDTH-1{1'b0}}, 1'b1};
wire [O_FP_WIDTH-1:0] fp17_overflow_adj;
assign fp17_overflow_adj = {fp32_sign, expo_overflow_adj, mant_rounded};

// Select output based on special case
assign fp17_out_pre = fp32_is_nan  ? {fp32_sign, expo_nan, {O_MANT_WIDTH-1{1'b0}}, 1'b1} :  // quiet NaN
                       fp32_is_inf  ? {fp32_sign, expo_inf, {O_MANT_WIDTH{1'b0}}} :
                       fp32_is_zero ? {fp32_sign, expo_zero, {O_MANT_WIDTH{1'b0}}} :
                       (expo_overflow || mant_overflow_rne) ? fp17_overflow_adj :
                       fp17_normal;

// -----------------------------------------------------------------
// Output Register (valid/ready pipeline)
// -----------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pipe_valid_q <= 1'b0;
    end else begin
        pipe_valid_q <= chn_a_rsc_vz;
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        chn_o_rsc_z  <= {O_FP_WIDTH{1'b0}};
        chn_o_rsc_vz <= 1'b0;
    end else begin
        chn_o_rsc_z  <= fp17_out_pre;
        chn_o_rsc_vz <= pipe_valid_q;
    end
end

// -----------------------------------------------------------------
// Output ready signal (always ready in this simple implementation)
// -----------------------------------------------------------------
always @* begin
    chn_o_rsc_lz = 1'b0;  // Always ready
end

endmodule
