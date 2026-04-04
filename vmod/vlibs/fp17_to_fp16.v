// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp17_to_fp16.v
// Author        : Wolley
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Floating-point format converter: FP17 (1+6+10) to FP16 (1+5+10)
// - Unpack fp17: sign, 6-bit exponent, 10-bit mantissa
// - Convert exponent: subtract bias difference (31 - 15 = 16)
// - Handle overflow/underflow
// - Handle special cases: zero, inf, NaN pass through
// - Pack to 16-bit format (5-bit exponent)
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module fp17_to_fp16 (
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
    parameter I_EXPO_WIDTH = 6;
    parameter I_MANT_WIDTH = 10;
    parameter I_FP_WIDTH   = 17;
    parameter O_EXPO_WIDTH = 5;
    parameter O_MANT_WIDTH = 10;
    parameter O_FP_WIDTH   = 16;

    // Bias values
    localparam I_BIAS = (1 << (I_EXPO_WIDTH - 1)) - 1;  // 31 for 6-bit exp
    localparam O_BIAS = (1 << (O_EXPO_WIDTH - 1)) - 1;  // 15 for 5-bit exp
    localparam BIAS_DIFF = I_BIAS - O_BIAS;              // 16

    // Input interface
    input                                     nvdla_core_clk;
    input                                     nvdla_core_rstn;
    input      [I_FP_WIDTH-1:0]               chn_a_rsc_z;
    input                                     chn_a_rsc_vz;
    output                                    chn_a_rsc_lz;

    // Output interface
    output     [O_FP_WIDTH-1:0]               chn_o_rsc_z;
    output                                    chn_o_rsc_vz;
    input                                     chn_o_rsc_lz;

    // -----------------------------------------------------------------
    // Unpack fp17: sign & exponent & mantissa
    // -----------------------------------------------------------------
    wire                                      i_sign;
    wire [I_EXPO_WIDTH-1:0]                  i_expo;
    wire [I_MANT_WIDTH-1:0]                  i_mant;

    assign i_sign = chn_a_rsc_z[I_FP_WIDTH-1];
    assign i_expo = chn_a_rsc_z[I_FP_WIDTH-2 -: I_EXPO_WIDTH];
    assign i_mant = chn_a_rsc_z[I_MANT_WIDTH-1:0];

    // -----------------------------------------------------------------
    // Special case detection
    // -----------------------------------------------------------------
    wire                                      i_is_zero;
    wire                                      i_is_inf;
    wire                                      i_is_nan;
    wire                                      i_is_denorm;

    assign i_is_zero = (i_expo == {I_EXPO_WIDTH{1'b0}}) && (i_mant == {I_MANT_WIDTH{1'b0}});
    assign i_is_inf  = (i_expo == {I_EXPO_WIDTH{1'b1}}) && (i_mant == {I_MANT_WIDTH{1'b0}});
    assign i_is_nan  = (i_expo == {I_EXPO_WIDTH{1'b1}}) && (i_mant != {I_MANT_WIDTH{1'b0}});
    assign i_is_denorm = (i_expo == {I_EXPO_WIDTH{1'b0}}) && (i_mant != {I_MANT_WIDTH{1'b0}});

    // -----------------------------------------------------------------
    // Exponent conversion: subtract bias difference
    // -----------------------------------------------------------------
    wire signed [I_EXPO_WIDTH:0]             i_expo_unbiased;  // signed for underflow check
    wire signed [O_EXPO_WIDTH:0]             o_expo_converted;

    assign i_expo_unbiased = $signed({1'b0, i_expo}) - I_BIAS;
    assign o_expo_converted = i_expo_unbiased - BIAS_DIFF;

    // -----------------------------------------------------------------
    // Handle exponent special cases
    // -----------------------------------------------------------------
    wire                                      expo_overflow;   // > 30 (max for 5-bit)
    wire                                      expo_underflow;  // <= 0
    wire [O_EXPO_WIDTH-1:0]                  o_expo_normal;
    wire [O_EXPO_WIDTH-1:0]                  o_expo_final;

    assign expo_overflow = (o_expo_converted > (1 << O_EXPO_WIDTH) - 1);  // > 31
    assign expo_underflow = (o_expo_converted <= 0);

    // Normal exponent (biased)
    assign o_expo_normal = o_expo_converted[O_EXPO_WIDTH-1:0];

    // Final exponent selection
    wire [O_EXPO_WIDTH-1:0]                  expo_selected;
    always @* begin
        if (i_is_zero || i_is_denorm || expo_underflow) begin
            expo_selected = {O_EXPO_WIDTH{1'b0}};
        end else if (expo_overflow) begin
            expo_selected = {O_EXPO_WIDTH{1'b1}};
        end else begin
            expo_selected = o_expo_normal;
        end
    end

    assign o_expo_final = expo_selected;

    // -----------------------------------------------------------------
    // Mantissa handling
    // -----------------------------------------------------------------
    // For denormals in fp17, we need to right-shift mantissa
    // Denorm shift: (1 - unbiased_exp) bits
    wire [I_MANT_WIDTH:0]                    i_mant_ext;  // extra bit for overflow
    wire [O_MANT_WIDTH:0]                    o_mant_shifted;
    wire [O_MANT_WIDTH-1:0]                  o_mant_final;

    assign i_mant_ext = {1'b1, i_mant};  // add implicit 1 for normalized, or leading 0 for denorm

    // Underflow: shift right by (1 - converted_exp)
    wire signed [O_EXPO_WIDTH:0]             shift_amount;
    assign shift_amount = 1 - o_expo_converted;

    // Right shift for underflow case
    wire [O_MANT_WIDTH:0]                    mant_shift_result;
    wire [O_MANT_WIDTH:0]                    mant_shift_mask;
    assign mant_shift_mask = (shift_amount >= (O_MANT_WIDTH + 1)) ?
                             {O_MANT_WIDTH+1{1'b1}} :
                             ({{O_MANT_WIDTH+1{1'b0}}} | ({{O_MANT_WIDTH+1{1'b0}}, 1'b1} << shift_amount));
    assign mant_shift_result = (i_mant_ext >> shift_amount) & mant_shift_mask;

    // For overflow/inf/NaN: mantissa is zero
    // For normal: mantissa passes through (without implicit bit)
    // For denorm/underflow: shifted mantissa
    always @* begin
        if (i_is_inf || i_is_nan) begin
            o_mant_final = {O_MANT_WIDTH{1'b0}};
        end else if (expo_underflow || i_is_denorm) begin
            o_mant_final = mant_shift_result[O_MANT_WIDTH-1:0];
        end else begin
            o_mant_final = i_mant;
        end
    end

    // -----------------------------------------------------------------
    // Pack output fp16
    // -----------------------------------------------------------------
    wire [O_FP_WIDTH-1:0]                    o_fp;

    assign o_fp = {i_sign, o_expo_final, o_mant_final};

    // -----------------------------------------------------------------
    // Output register with valid/ready handshake
    // -----------------------------------------------------------------
    reg                                      chn_o_rsc_vz_int;
    reg [O_FP_WIDTH-1:0]                     chn_o_rsc_z_int;

    // Input register stage
    reg                                      chn_a_rsc_vz_reg;
    reg [I_FP_WIDTH-1:0]                     chn_a_rsc_z_reg;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            chn_a_rsc_vz_reg <= 1'b0;
            chn_a_rsc_z_reg <= {I_FP_WIDTH{1'b0}};
        end else begin
            chn_a_rsc_vz_reg <= chn_a_rsc_vz;
            chn_a_rsc_z_reg <= chn_a_rsc_z;
        end
    end

    // Output generation
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            chn_o_rsc_vz_int <= 1'b0;
            chn_o_rsc_z_int <= {O_FP_WIDTH{1'b0}};
        end else if (chn_a_rsc_vz_reg) begin
            chn_o_rsc_vz_int <= 1'b1;
            chn_o_rsc_z_int <= o_fp;
        end else if (chn_o_rsc_lz) begin
            chn_o_rsc_vz_int <= 1'b0;
        end
    end

    assign chn_o_rsc_z = chn_o_rsc_z_int;
    assign chn_o_rsc_vz = chn_o_rsc_vz_int;

    // Backpressure: hold input when output not ready
    assign chn_a_rsc_lz = chn_o_rsc_vz_int && !chn_o_rsc_lz;

endmodule
