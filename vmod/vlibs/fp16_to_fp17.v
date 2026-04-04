// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp16_to_fp17.v
// Author        : Wolley
// Author Email  : wolley@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Floating-point format converter: fp16 (1+5+10) to fp17 (1+6+10)
// Expands 5-bit exponent to 6-bit exponent by adding bias delta.
//
// Key steps:
// 1. Unpack fp16: sign, 5-bit exponent, 10-bit mantissa
// 2. Expand exponent: add bias difference (31 - 15 = 16) to fp16's biased exponent
// 3. Handle special cases: zero, denorm, inf, NaN
// 4. Pack to 17-bit format (1+6+10)
//
// Parameters:
//   I_EXPO_WIDTH = 5  (input exponent width)
//   I_MANT_WIDTH = 10 (input mantissa width)
//   I_FP_WIDTH   = 16 (input total width)
//   O_EXPO_WIDTH = 6  (output exponent width)
//   O_MANT_WIDTH = 10 (output mantissa width)
//   O_FP_WIDTH   = 17 (output total width)
//
// Interface:
//   nvdla_core_clk, nvdla_core_rstn - clock and reset
//   chn_a_rsc_z[15:0], chn_a_rsc_vz, chn_a_rsc_lz - fp16 input
//   chn_o_rsc_z[16:0], chn_o_rsc_vz, chn_o_rsc_lz - fp17 output
// +FHDR------------------------------------------------------------

module fp16_to_fp17
#(
    parameter I_EXPO_WIDTH = 5,
    parameter I_MANT_WIDTH = 10,
    parameter I_FP_WIDTH   = 16,
    parameter O_EXPO_WIDTH = 6,
    parameter O_MANT_WIDTH = 10,
    parameter O_FP_WIDTH   = 17
) (
    // Clock and reset
    input                              nvdla_core_clk,
    input                              nvdla_core_rstn,

    // Input channel (fp16)
    input  [I_FP_WIDTH-1:0]            chn_a_rsc_z,
    input                              chn_a_rsc_vz,
    input                              chn_a_rsc_lz,

    // Output channel (fp17)
    output [O_FP_WIDTH-1:0]            chn_o_rsc_z,
    output                             chn_o_rsc_vz,
    output                             chn_o_rsc_lz
);

    // Local parameters
    localparam I_EXPO_MAX   = (1 << I_EXPO_WIDTH) - 1;  // 5'd31 = 5'b11111
    localparam I_MANT_MAX   = (1 << I_MANT_WIDTH) - 1;  // 10'd1023
    localparam O_EXPO_MAX   = (1 << O_EXPO_WIDTH) - 1;  // 6'd63 = 6'b111111
    localparam O_MANT_MAX   = (1 << O_MANT_WIDTH) - 1;  // 10'd1023
    localparam I_BIAS       = (1 << (I_EXPO_WIDTH - 1)) - 1;  // 5'd15
    localparam O_BIAS       = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 6'd31
    localparam EXP_BIAS_DELTA = O_BIAS - I_BIAS;  // 6'd16

    // Input unpacked signals
    wire        i_sign;
    wire [I_EXPO_WIDTH-1:0] i_expo;
    wire [I_MANT_WIDTH-1:0] i_mant;

    // Output unpacked signals
    wire        o_sign;
    reg [O_EXPO_WIDTH-1:0] o_expo;
    reg [O_MANT_WIDTH-1:0] o_mant;

    // Special case flags
    wire        is_zero;
    wire        is_inf;
    wire        is_nan;
    wire        is_denorm;

    // Denorm handling
    wire [I_MANT_WIDTH-1:0] zero_count;
    wire [O_EXPO_WIDTH-1:0] o_expo_denorm;
    wire [I_MANT_WIDTH:0]   i_mant_shifted;

    // Unpack input fp16 (bit 15 = sign, bits[14:10] = exponent, bits[9:0] = mantissa)
    assign i_sign = chn_a_rsc_z[I_FP_WIDTH - 1];
    assign i_expo = chn_a_rsc_z[I_FP_WIDTH - 2 -: I_EXPO_WIDTH];
    assign i_mant = chn_a_rsc_z[I_MANT_WIDTH - 1:0];

    // Special case detection
    assign is_zero = (i_expo == {I_EXPO_WIDTH{1'b0}}) && (i_mant == {I_MANT_WIDTH{1'b0}});
    assign is_inf  = (i_expo == I_EXPO_MAX[I_EXPO_WIDTH-1:0]) && (i_mant == {I_MANT_WIDTH{1'b0}});
    assign is_nan  = (i_expo == I_EXPO_MAX[I_EXPO_WIDTH-1:0]) && (i_mant != {I_MANT_WIDTH{1'b0}});
    assign is_denorm = (i_expo == {I_EXPO_WIDTH{1'b0}}) && (i_mant != {I_MANT_WIDTH{1'b0}});

    // Count leading zeros in mantissa for denorm renormalization
    // This is the IntLeadZero function: count zeros before first 1
    assign zero_count =
        (i_mant[9]) ? 4'd0 :
        (i_mant[8]) ? 4'd1 :
        (i_mant[7]) ? 4'd2 :
        (i_mant[6]) ? 4'd3 :
        (i_mant[5]) ? 4'd4 :
        (i_mant[4]) ? 4'd5 :
        (i_mant[3]) ? 4'd6 :
        (i_mant[2]) ? 4'd7 :
        (i_mant[1]) ? 4'd8 :
        (i_mant[0]) ? 4'd9 :
        4'd10;

    // Denorm exponent: EXP_BIAS_DELTA - zero_count
    assign o_expo_denorm = EXP_BIAS_DELTA[O_EXPO_WIDTH-1:0] - zero_count[O_EXPO_WIDTH-1:0];

    // Denorm mantissa: left shift by (zero_count + 1), add implied MSB
    // i_mant_shifted has I_MANT_WIDTH+1 bits to capture the shifted result
    assign i_mant_shifted = ({1'b1, i_mant} << (zero_count + 4'd1));

    // Output sign - pass through from input
    assign o_sign = i_sign;

    // Output exponent calculation
    always @* begin
        if (is_zero) begin
            o_expo = {O_EXPO_WIDTH{1'b0}};
        end else if (is_inf) begin
            // Inf: set exponent to O_EXPO_MAX
            o_expo = {O_EXPO_WIDTH{1'b1}};
        end else if (is_nan) begin
            // NaN: set exponent to O_EXPO_MAX, mantissa pass through
            o_expo = {O_EXPO_WIDTH{1'b1}};
        end else if (is_denorm) begin
            // Denorm: exponent = EXP_BIAS_DELTA - zero_count
            o_expo = o_expo_denorm;
        end else begin
            // Normal: add bias delta to biased exponent
            o_expo = i_expo + EXP_BIAS_DELTA[O_EXPO_WIDTH-1:0];
        end
    end

    // Output mantissa calculation
    always @* begin
        if (is_zero) begin
            o_mant = {O_MANT_WIDTH{1'b0}};
        end else if (is_inf) begin
            o_mant = {O_MANT_WIDTH{1'b0}};
        end else if (is_nan) begin
            // NaN: mantissa pass through
            o_mant = i_mant;
        end else if (is_denorm) begin
            // Denorm: take upper O_MANT_WIDTH bits after shift
            o_mant = i_mant_shifted[I_MANT_WIDTH:I_MANT_WIDTH - O_MANT_WIDTH + 1];
        end else begin
            // Normal: mantissa pass through
            o_mant = i_mant;
        end
    end

    // Pack output fp17
    assign chn_o_rsc_z = {o_sign, o_expo, o_mant};

    // Pass through control signals
    assign chn_o_rsc_vz = chn_a_rsc_vz;
    assign chn_o_rsc_lz = chn_a_rsc_lz;

endmodule