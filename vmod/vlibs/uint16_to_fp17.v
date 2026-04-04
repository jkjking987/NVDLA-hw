// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : uint16_to_fp17.v
// Author        : Wolley
// Author Email  : wolley@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Unsigned integer to floating-point converter: uint16 to fp17
// Converts 16-bit unsigned integer to fp17 format (1+6+10, bias 31)
//
// Key steps:
// 1. Count leading zeros to find MSB position (0-15)
// 2. Normalize: shift left so MSB is at bit 22 (fp17 significand MSB position)
// 3. Set exponent = 31 + (22 - msb_pos) = 53 - msb_pos
// 4. Handle zero input (special case with zero exponent)
// 5. Pack to 17-bit fp17 format (sign=0, exp, mantissa)
//
// Parameters:
//   I_WIDTH       = 16 (unsigned integer input width)
//   O_EXPO_WIDTH  = 6  (output exponent width)
//   O_MANT_WIDTH  = 10 (output mantissa width)
//   O_FP_WIDTH    = 17 (output total width)
//
// Interface:
//   nvdla_core_clk, nvdla_core_rstn - clock and reset
//   chn_a_rsc_z[15:0], chn_a_rsc_vz, chn_a_rsc_lz - uint16 input
//   chn_o_rsc_z[16:0], chn_o_rsc_vz, chn_o_rsc_lz - fp17 output
// +FHDR------------------------------------------------------------

module uint16_to_fp17
#(
    parameter I_WIDTH       = 16,
    parameter O_EXPO_WIDTH  = 6,
    parameter O_MANT_WIDTH  = 10,
    parameter O_FP_WIDTH    = 17
) (
    // Clock and reset
    input                              nvdla_core_clk,
    input                              nvdla_core_rstn,

    // Input channel (uint16)
    input  [I_WIDTH-1:0]              chn_a_rsc_z,
    input                              chn_a_rsc_vz,
    input                              chn_a_rsc_lz,

    // Output channel (fp17)
    output [O_FP_WIDTH-1:0]            chn_o_rsc_z,
    output                             chn_o_rsc_vz,
    output                             chn_o_rsc_lz
);

    // Local parameters
    localparam O_BIAS       = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 6'd31
    localparam I_MAX_POS    = I_WIDTH - 1;  // 4'd15 (MSB position of 16-bit input)

    // Zero detection
    wire        is_zero;

    // MSB position detection (0-15, where 15 = MSB of 16-bit value)
    wire [3:0]  msb_pos;

    // Normalization shift amount
    wire [3:0]  shift;

    // Intermediate signals for mantissa extraction
    wire [I_WIDTH+O_MANT_WIDTH-1:0]  shifted;  // 25 bits to hold shifted uint16 + mantissa bits

    // Output exponent and mantissa (combinational)
    reg  [O_EXPO_WIDTH-1:0]  o_expo;
    reg  [O_MANT_WIDTH-1:0]  o_mant;

    // Zero detection: NOR of all input bits
    assign is_zero = ~|chn_a_rsc_z;

    // Leading one detector: find MSB position (0-15)
    // Default to 0 for zero input (will result in correct zero output)
    assign msb_pos =
        (chn_a_rsc_z[15]) ? 4'd15 :
        (chn_a_rsc_z[14]) ? 4'd14 :
        (chn_a_rsc_z[13]) ? 4'd13 :
        (chn_a_rsc_z[12]) ? 4'd12 :
        (chn_a_rsc_z[11]) ? 4'd11 :
        (chn_a_rsc_z[10]) ? 4'd10 :
        (chn_a_rsc_z[9])  ? 4'd9  :
        (chn_a_rsc_z[8])  ? 4'd8  :
        (chn_a_rsc_z[7])  ? 4'd7  :
        (chn_a_rsc_z[6])  ? 4'd6  :
        (chn_a_rsc_z[5])  ? 4'd5  :
        (chn_a_rsc_z[4])  ? 4'd4  :
        (chn_a_rsc_z[3])  ? 4'd3  :
        (chn_a_rsc_z[2])  ? 4'd2  :
        (chn_a_rsc_z[1])  ? 4'd1  :
        4'd0;  // Default for zero input

    // Shift amount: how much to left-shift to bring MSB to bit 22
    // For 16-bit input, max shift is 15 (to bring LSB to bit 15, MSB to bit 22)
    // shift = 22 - msb_pos - 1 = 21 - msb_pos? Let's derive:
    // We want: input[msb_pos] -> position 22 in the extended word
    // shifted_word has bits [I_WIDTH-1+shift:0]
    // We want: shifted_word[22] = input[msb_pos]
    // So: I_WIDTH-1 - msb_pos + shift = 22
    // shift = 22 - I_WIDTH + 1 + msb_pos = 9 + msb_pos? No...
    //
    // Actually: shifted = input << shift
    // We want shifted[22] = input[msb_pos]
    // So: msb_pos + shift = 22
    // shift = 22 - msb_pos
    //
    // But for 16-bit input with max msb_pos=15:
    // shift = 22 - 15 = 7 (minimum shift)
    // For msb_pos=0 (value=1):
    // shift = 22 - 0 = 22 (maximum shift)
    //
    // This is equivalent to: shift = 22 - msb_pos = (I_WIDTH-1) + (22-I_WIDTH+1) - msb_pos
    // Which simplifies to: shift = I_MAX_POS + (22 - I_WIDTH + 1) - msb_pos
    // = 15 + (22 - 16 + 1) - msb_pos = 15 + 7 - msb_pos = 22 - msb_pos ✓
    assign shift = 4'd22 - msb_pos;

    // Shifted value: left-shift input to normalize MSB to bit 22
    // Need I_WIDTH + O_MANT_WIDTH bits to hold: 16 << 7 = 23 bits max
    assign shifted = ({1'b0, chn_a_rsc_z} << shift);

    // Output exponent calculation (combinational)
    // Exponent = bias + shift amount
    // For fp17: bias = 31, shift = 22 - msb_pos (to bring MSB to bit 22)
    // exp = 31 + (22 - msb_pos) = 53 - msb_pos
    always @* begin
        if (is_zero) begin
            o_expo = {O_EXPO_WIDTH{1'b0}};
        end else begin
            o_expo = O_BIAS[O_EXPO_WIDTH-1:0] + shift;
        end
    end

    // Output mantissa calculation (combinational)
    // Mantissa bits are bits[21:12] of shifted value (the bits below the implicit 1.0)
    always @* begin
        if (is_zero) begin
            o_mant = {O_MANT_WIDTH{1'b0}};
        end else begin
            o_mant = shifted[21:12];  // Extract 10-bit mantissa from normalized value
        end
    end

    // Pack output fp17: sign=0 (unsigned), exponent, mantissa
    assign chn_o_rsc_z = {1'b0, o_expo, o_mant};

    // Pass through control signals (no latency)
    assign chn_o_rsc_vz = chn_a_rsc_vz;
    assign chn_o_rsc_lz = chn_a_rsc_lz;

endmodule