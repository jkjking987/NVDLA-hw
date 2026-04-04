// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp32_to_fp16.v
// Author        : Wolley
// Author Email  : wolley@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Floating-point format converter: fp32 (1+8+23) to fp16 (1+5+10)
// Implements FpWidthDec<8,23,5,10,DENORM_YES,NAN_YES> from nvdla_float.h
//
// Conversion steps:
// 1. Unpack fp32: sign, 8-bit exponent, 23-bit mantissa
// 2. Convert exponent: subtract bias difference (127 - 15 = 112)
// 3. Handle potential overflow/underflow (clamp or set to inf)
// 4. RNE rounding from 23-bit to 10-bit mantissa
// 5. Handle special cases: zero, inf, NaN
// 6. Pack to 16-bit format
// +FHDR------------------------------------------------------------

module fp32_to_fp16 (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_o_rsc_z,
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

// ================================================================
// Parameters
// ================================================================
parameter I_EXPO_WIDTH = 8;
parameter I_MANT_WIDTH = 23;
parameter I_FP_WIDTH   = 32;
parameter O_EXPO_WIDTH = 5;
parameter O_MANT_WIDTH = 10;
parameter O_FP_WIDTH   = 16;

// Bias values
parameter I_BIAS = (1 << (I_EXPO_WIDTH - 1)) - 1;  // 127 for fp32
parameter O_BIAS = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 15 for fp16
parameter EXPO_BIAS_DELTA = I_BIAS - O_BIAS;        // 112

// Exponent max values
parameter I_EXPO_MAX = (1 << I_EXPO_WIDTH) - 1;     // 255 for fp32
parameter O_EXPO_MAX = (1 << O_EXPO_WIDTH) - 1;     // 31 for fp16

// ================================================================
// Ports
// ================================================================
input                             nvdla_core_clk;
input                             nvdla_core_rstn;

input  [I_FP_WIDTH-1:0]           chn_a_rsc_z;
input                             chn_a_rsc_vz;
input                             chn_a_rsc_lz;

output [O_FP_WIDTH-1:0]            chn_o_rsc_z;
output                            chn_o_rsc_vz;
output                            chn_o_rsc_lz;

// ================================================================
// Internal signals - unpacked fp32
// ================================================================
wire                      i_sign;
wire [I_EXPO_WIDTH-1:0]   i_expo;
wire [I_MANT_WIDTH-1:0]   i_mant;

// Unpacked output
reg                       o_sign;
reg [O_EXPO_WIDTH-1:0]    o_expo;
reg [O_MANT_WIDTH-1:0]    o_mant;

// Special case flags
wire                      is_nan;
wire                      is_inf;
wire                      is_zero;

// Denorm detection
wire                      is_denorm;

// Rounding overflow
reg                       mant_overflow;

// Intermediate mantissa with implied bit
wire [I_MANT_WIDTH:0]     i_mant_p1;  // 24 bits: implied 1 + 23-bit mantissa

// Denorm shift amount
reg  [5:0]                denorm_shift;
reg  [I_MANT_WIDTH:0]     denorm_shifted_mant;
reg  [O_MANT_WIDTH-1:0]   denorm_rounded_mant;
reg                       denorm_overflow;

// Output valid/ready handshake
reg                       chn_o_rsc_vz_int;

// ================================================================
// Step 1: Unpack fp32 input
// ================================================================
assign i_sign = chn_a_rsc_z[I_FP_WIDTH-1];
assign i_expo = chn_a_rsc_z[I_FP_WIDTH-2:I_MANT_WIDTH];
assign i_mant = chn_a_rsc_z[I_MANT_WIDTH-1:0];

// ================================================================
// Step 2: Add implied leading 1 to mantissa for normalized values
// ================================================================
assign i_mant_p1 = {1'b1, i_mant};  // Add implied 1 at MSB

// ================================================================
// Step 3: Detect special cases from input fp32
// ================================================================
// NaN: exponent all 1s and mantissa non-zero
assign is_nan   = (i_expo == I_EXPO_MAX) && (i_mant != {I_MANT_WIDTH{1'b0}});

// Inf: exponent all 1s and mantissa zero
assign is_inf   = (i_expo == I_EXPO_MAX) && (i_mant == {I_MANT_WIDTH{1'b0}});

// Zero: exponent and mantissa both zero
assign is_zero = (i_expo == {I_EXPO_WIDTH{1'b0}}) && (i_mant == {I_MANT_WIDTH{1'b0}});

// Denorm: exponent zero but mantissa non-zero
assign is_denorm = (i_expo == {I_EXPO_WIDTH{1'b0}}) && (i_mant != {I_MANT_WIDTH{1'b0}});

// ================================================================
// Denorm shift calculation (combinational)
// ================================================================
always @* begin
    denorm_shift = 6'd0;
    if (is_denorm) begin
        denorm_shift = EXPO_BIAS_DELTA - i_expo + 1;
    end
end

// ================================================================
// Denorm shift operation (combinational)
// ================================================================
always @* begin
    denorm_shifted_mant = {1'b0, i_mant};
    if (is_denorm && (denorm_shift > 0) && (denorm_shift <= I_MANT_WIDTH)) begin
        denorm_shifted_mant = {1'b0, i_mant} >> denorm_shift;
    end
end

// ================================================================
// Denorm rounding (combinational)
// ================================================================
always @* begin
    denorm_rounded_mant = rne_round({1'b0, i_mant});
    denorm_overflow = 1'b0;

    if (is_denorm) begin
        denorm_rounded_mant = rne_round(denorm_shifted_mant);

        // Check if rounding caused overflow
        if (denorm_shifted_mant[I_MANT_WIDTH] ||
            (denorm_shifted_mant[I_MANT_WIDTH-O_MANT_WIDTH] &&
             |denorm_shifted_mant[I_MANT_WIDTH-O_MANT_WIDTH-1:0])) begin
            denorm_overflow = 1'b1;
        end
    end
end

// ================================================================
// Step 4: Main conversion logic (combinational)
// ================================================================
always @* begin
    // Default values
    o_sign         = i_sign;
    o_expo         = {O_EXPO_WIDTH{1'b0}};
    o_mant         = {O_MANT_WIDTH{1'b0}};
    mant_overflow  = 1'b0;

    if (is_nan) begin
        // NaN: preserve sign, set exponent to max, mantissa preserved
        o_sign = i_sign;
        o_expo = O_EXPO_MAX;
        o_mant = i_mant[O_MANT_WIDTH-1:0];
    end else if (is_inf) begin
        // Inf: set to infinity
        o_sign = i_sign;
        o_expo = O_EXPO_MAX - 1;  // 30 for fp16
        o_mant = {O_MANT_WIDTH{1'b1}};  // All 1s for inf
    end else if (is_zero) begin
        // Zero: all bits zero
        o_sign = i_sign;
        o_expo = {O_EXPO_WIDTH{1'b0}};
        o_mant = {O_MANT_WIDTH{1'b0}};
    end else if (i_expo >= (O_EXPO_MAX + EXPO_BIAS_DELTA)) begin
        // Overflow: exponent too large -> infinity
        o_sign = i_sign;
        o_expo = O_EXPO_MAX - 1;
        o_mant = {O_MANT_WIDTH{1'b1}};
    end else if (i_expo < (EXPO_BIAS_DELTA - O_MANT_WIDTH)) begin
        // Underflow: too small even for denorm -> zero
        o_sign = i_sign;
        o_expo = {O_EXPO_WIDTH{1'b0}};
        o_mant = {O_MANT_WIDTH{1'b0}};
    end else if (is_denorm) begin
        // Denormalized number (fp16)
        if (denorm_overflow) begin
            o_expo = 5'd1;
            o_mant = {O_MANT_WIDTH{1'b0}};
        end else begin
            o_expo = {O_EXPO_WIDTH{1'b0}};
            o_mant = denorm_rounded_mant;
        end
    end else begin
        // Normalized number
        // Subtract bias delta from exponent
        o_expo = i_expo - EXPO_BIAS_DELTA;

        // RNE rounding on mantissa (from 23 bits to 10 bits)
        o_mant = rne_round_mant(i_mant_p1);

        // Check for mantissa overflow during rounding
        if (o_mant > {O_MANT_WIDTH{1'b1}}) begin
            mant_overflow = 1'b1;
            o_mant = {O_MANT_WIDTH{1'b0}};
        end

        if (mant_overflow) begin
            o_expo = o_expo + 1;
            if (o_expo == (O_EXPO_MAX - 1)) begin
                // Overflow to infinity
                o_sign = i_sign;
                o_expo = O_EXPO_MAX - 1;
                o_mant = {O_MANT_WIDTH{1'b1}};
            end
        end
    end
end

// ================================================================
// RNE Rounding functions
// ================================================================
// Round 24-bit mantissa (with implied 1) to 10 bits
function [O_MANT_WIDTH-1:0] rne_round_mant;
    input [I_MANT_WIDTH:0] mant_in;  // 24 bits: 1 implied + 23 bits mantissa

    reg [I_MANT_WIDTH-O_MANT_WIDTH-1:0] trunc_bits;  // 12 bits to check
    reg                                   guard_bit;
    reg                                   sticky_bit;
    reg                                   lsb_bit;
    reg                                   round_bit;
    reg [O_MANT_WIDTH-1:0]                mant_sticky;
    reg [O_MANT_WIDTH-1:0]                result;
    reg                                   overflow;

    begin
        // Extract bits for rounding decision
        // mant_in[23] = implied 1
        // mant_in[22:0] = actual mantissa
        // We keep mant_in[22:13] (10 bits), round on mant_in[12:0]
        trunc_bits = mant_in[I_MANT_WIDTH-O_MANT_WIDTH-1:0];  // bits 12:0
        guard_bit  = mant_in[I_MANT_WIDTH-O_MANT_WIDTH];     // bit 13
        sticky_bit = |trunc_bits;                             // OR of all bits below guard
        lsb_bit    = mant_in[I_MANT_WIDTH-O_MANT_WIDTH+1];    // bit 14 (LSB of result)
        round_bit  = guard_bit & (sticky_bit | lsb_bit);       // RNE: round to even

        mant_sticky = mant_in[I_MANT_WIDTH:I_MANT_WIDTH-O_MANT_WIDTH+1];  // upper 10 bits
        result = mant_sticky + {{(O_MANT_WIDTH-1){1'b0}}, round_bit};
        overflow = result[O_MANT_WIDTH];

        if (overflow) begin
            rne_round_mant = {1'b0, {(O_MANT_WIDTH-1){1'b1}}};
        end else begin
            rne_round_mant = result;
        end
    end
endfunction

// Generic RNE round function
function [O_MANT_WIDTH-1:0] rne_round;
    input [I_MANT_WIDTH:0] mant_in;  // 24-bit input

    reg [I_MANT_WIDTH-O_MANT_WIDTH-1:0] trunc_bits;
    reg                                   guard_bit;
    reg                                   sticky_bit;
    reg                                   lsb_bit;
    reg                                   round_bit;
    reg [O_MANT_WIDTH-1:0]                mant_keep;
    reg [O_MANT_WIDTH-1:0]                result;
    reg                                   overflow;

    begin
        trunc_bits = mant_in[I_MANT_WIDTH-O_MANT_WIDTH-1:0];
        guard_bit  = mant_in[I_MANT_WIDTH-O_MANT_WIDTH];
        sticky_bit = |trunc_bits;
        lsb_bit    = mant_in[I_MANT_WIDTH-O_MANT_WIDTH+1];
        round_bit  = guard_bit & (sticky_bit | lsb_bit);

        mant_keep = mant_in[I_MANT_WIDTH:I_MANT_WIDTH-O_MANT_WIDTH+1];
        result = mant_keep + {{(O_MANT_WIDTH-1){1'b0}}, round_bit};
        overflow = result[O_MANT_WIDTH];

        if (overflow) begin
            rne_round = {1'b0, {(O_MANT_WIDTH-1){1'b1}}};
        end else begin
            rne_round = result;
        end
    end
endfunction

// ================================================================
// Output packing and handshake
// ================================================================
assign chn_o_rsc_z = {o_sign, o_expo, o_mant};

// Handshake: pass through valid signal with one cycle latency
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        chn_o_rsc_vz_int <= 1'b0;
    end else begin
        chn_o_rsc_vz_int <= chn_a_rsc_vz;
    end
end

assign chn_o_rsc_vz = chn_o_rsc_vz_int;

// Lossy signal pass-through (combinational)
assign chn_o_rsc_lz = chn_a_rsc_lz;

endmodule