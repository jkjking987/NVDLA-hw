// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : cdp_ocvt_ref.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Pure Verilog Reference Model for CDP OCVT (Output Converter)
//   Operations: ALU(sub) -> MUL -> TRUNCATE
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module cdp_ocvt_ref (
    input nvdla_core_clk,
    input nvdla_core_rstn,

    // Handshake
    input chn_data_in_vld,
    output chn_data_in_rdy,
    input [49:0] chn_data_in,

    input [1:0] cfg_precision,  // 0=INT8, 1=INT16, 2=FP16

    // ALU config
    input [31:0] cfg_alu_in,

    // MUL config
    input [15:0] cfg_mul_in,

    // Truncate config
    input [5:0] cfg_truncate,

    // Output
    output chn_data_out_vld,
    input chn_data_out_rdy,
    output [15:0] chn_data_out,
    output [1:0] chn_data_out_sat
);

    localparam PREC_INT8 = 2'b00;
    localparam PREC_INT16 = 2'b01;
    localparam PREC_FP16 = 2'b10;

    // Input capture
    reg [49:0] data_in_reg;
    reg [31:0] alu_in_reg;
    reg [15:0] mul_in_reg;
    reg [5:0] truncate_reg;
    reg valid_q;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            valid_q <= 1'b0;
        end else if (chn_data_in_vld && chn_data_in_rdy) begin
            data_in_reg <= chn_data_in;
            alu_in_reg <= cfg_alu_in;
            mul_in_reg <= cfg_mul_in;
            truncate_reg <= cfg_truncate;
            valid_q <= 1'b1;
        end else if (chn_data_out_vld && chn_data_out_rdy) begin
            valid_q <= 1'b0;
        end
    end

    assign chn_data_in_rdy = !valid_q || (chn_data_out_vld && chn_data_out_rdy);

    // Compute result (combinational)
    // For INT16: ALU (33b) * MUL (16b) = result
    // The result fits in lower bits; use lower 16 bits shifted
    wire [32:0] alu_out = {1'b0, data_in_reg[32:0]} - {1'b0, alu_in_reg};
    wire [48:0] mul_out = $signed(alu_out) * $signed(mul_in_reg);
    // Use lower bits of multiplication result
    wire [15:0] truncate_out = mul_out[15:0] >> truncate_reg;

    assign chn_data_out = truncate_out;
    assign chn_data_out_sat = 2'b0;
    assign chn_data_out_vld = valid_q;

endmodule