// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp16_to_fp32.v
// Author        : Claude Code
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Floating-point format converter: fp16 (1+5+10) to fp32 (1+8+23)
// - Unpack fp16: sign, 5-bit exponent, 10-bit mantissa
// - Expand exponent: add bias difference (127 - 15 = 112)
// - Shift mantissa from 10 bits to 23 bits (left-shift by 13)
// - Handle special cases: zero, inf, NaN pass through
// - Pack to 32-bit format
// +FHDR------------------------------------------------------------

module fp16_to_fp32 (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_o_rsc_z,
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

// Parameters
parameter I_EXPO_WIDTH = 5;
parameter I_MANT_WIDTH = 10;
parameter I_FP_WIDTH   = 16;
parameter O_EXPO_WIDTH = 8;
parameter O_MANT_WIDTH = 23;
parameter O_FP_WIDTH   = 32;

// Bias values
parameter I_BIAS = (1 << (I_EXPO_WIDTH - 1)) - 1;  // 15 for fp16
parameter O_BIAS = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 127 for fp32
parameter BIAS_DIFF = O_BIAS - I_BIAS;             // 112

// Input port declarations
input                                  nvdla_core_clk;
input                                  nvdla_core_rstn;
input  [I_FP_WIDTH-1:0]               chn_a_rsc_z;
input                                  chn_a_rsc_vz;
input                                  chn_a_rsc_lz;

// Output port declarations
output [O_FP_WIDTH-1:0]                chn_o_rsc_z;
output                                 chn_o_rsc_vz;
output                                 chn_o_rsc_lz;

// -----------------------------------------------------------------
// unpack fp16
// -----------------------------------------------------------------
wire                                  fp16_sign;
wire [I_EXPO_WIDTH-1:0]               fp16_expo;
wire [I_MANT_WIDTH-1:0]               fp16_mant;

assign fp16_sign = chn_a_rsc_z[I_FP_WIDTH-1];
assign fp16_expo = chn_a_rsc_z[I_FP_WIDTH-2:I_MANT_WIDTH];
assign fp16_mant = chn_a_rsc_z[I_MANT_WIDTH-1:0];

// -----------------------------------------------------------------
// Decode special cases from fp16
// -----------------------------------------------------------------
wire                                  fp16_is_zero;
wire                                  fp16_is_inf;
wire                                  fp16_is_nan;
wire                                  fp16_is_denorm;

assign fp16_is_zero = (fp16_expo == {I_EXPO_WIDTH{1'b0}}) && (fp16_mant == {I_MANT_WIDTH{1'b0}});
assign fp16_is_inf  = (fp16_expo == {I_EXPO_WIDTH{1'b1}}) && (fp16_mant == {I_MANT_WIDTH{1'b0}});
assign fp16_is_nan  = (fp16_expo == {I_EXPO_WIDTH{1'b1}}) && (fp16_mant != {I_MANT_WIDTH{1'b0}});
assign fp16_is_denorm = (fp16_expo == {I_EXPO_WIDTH{1'b0}}) && (fp16_mant != {I_MANT_WIDTH{1'b0}});

// -----------------------------------------------------------------
// Compute fp32 outputs
// -----------------------------------------------------------------
wire [O_EXPO_WIDTH-1:0]               fp32_expo;
wire [O_MANT_WIDTH-1:0]               fp32_mant;

assign fp32_expo = fp16_expo + BIAS_DIFF[O_EXPO_WIDTH-1:0];
assign fp32_mant = {fp16_mant, {O_MANT_WIDTH-I_MANT_WIDTH{1'b0}}};

// -----------------------------------------------------------------
// Handle denormalized fp16: shift right until exponent becomes 1
// -----------------------------------------------------------------
wire [I_MANT_WIDTH-1:0]               denorm_mant_shifted;
wire [$clog2(I_MANT_WIDTH):0]         denorm_shift_count;
wire [O_MANT_WIDTH-1:0]                denorm_fp32_mant;

    // Count leading zeros in mantissa to determine shift
    reg [$clog2(I_MANT_WIDTH):0] shift_cnt;
    integer i;
    always @* begin
        shift_cnt = I_MANT_WIDTH;
        for (i = 0; i < I_MANT_WIDTH; i = i + 1) begin
            if (fp16_mant[I_MANT_WIDTH-1-i] && (shift_cnt == I_MANT_WIDTH)) begin
                shift_cnt = i;
            end
        end
    end
    assign denorm_shift_count = shift_cnt;

    // Shift mantissa right for denormalized representation
    wire [I_MANT_WIDTH-1:0] mant_for_shift;
    assign mant_for_shift = fp16_mant;

    wire [I_MANT_WIDTH+16-1:0] mant_shifted_ext;
    assign mant_shifted_ext = {mant_for_shift, {16{1'b0}}} >> denorm_shift_count;
    assign denorm_mant_shifted = mant_shifted_ext[I_MANT_WIDTH-1:0];

    // Denorm fp32 mantissa: shifted mantissa with 13 zero bits appended
    assign denorm_fp32_mant = {denorm_mant_shifted, {O_MANT_WIDTH-I_MANT_WIDTH{1'b0}}};

// -----------------------------------------------------------------
// Final output assignment
// -----------------------------------------------------------------
reg [O_FP_WIDTH-1:0]                  chn_o_rsc_z_int;
reg                                   chn_o_rsc_vz_int;

always @* begin
    chn_o_rsc_z_int = {O_FP_WIDTH{1'b0}};
    chn_o_rsc_vz_int = 1'b0;

    if (chn_a_rsc_vz) begin
        chn_o_rsc_vz_int = 1'b1;

        if (fp16_is_zero) begin
            // Zero: sign=0, exponent=0, mantissa=0
            chn_o_rsc_z_int = {fp16_sign, {O_EXPO_WIDTH{1'b0}}, {O_MANT_WIDTH{1'b0}}};
        end else if (fp16_is_inf) begin
            // Infinity: sign preserved, exponent=all1s, mantissa=0
            chn_o_rsc_z_int = {fp16_sign, {O_EXPO_WIDTH{1'b1}}, {O_MANT_WIDTH{1'b0}}};
        end else if (fp16_is_nan) begin
            // NaN: sign preserved, exponent=all1s, mantissa preserved (with top bits)
            chn_o_rsc_z_int = {fp16_sign, {O_EXPO_WIDTH{1'b1}}, fp16_mant, {O_MANT_WIDTH-I_MANT_WIDTH{1'b0}}};
        end else if (fp16_is_denorm) begin
            // Denormalized: convert to normalized fp32 with exponent=1
            chn_o_rsc_z_int = {fp16_sign, {{O_EXPO_WIDTH-1{1'b0}}, 1'b1}, denorm_fp32_mant};
        end else begin
            // Normalized: sign + expanded exponent + shifted mantissa
            chn_o_rsc_z_int = {fp16_sign, fp32_expo, fp32_mant};
        end
    end else begin
        chn_o_rsc_z_int = {O_FP_WIDTH{1'b0}};
    end
end

// -----------------------------------------------------------------
// Output assignment
// -----------------------------------------------------------------
assign chn_o_rsc_z  = chn_o_rsc_z_int;
assign chn_o_rsc_vz = chn_o_rsc_vz_int;
assign chn_o_rsc_lz = chn_a_rsc_lz;

endmodule
