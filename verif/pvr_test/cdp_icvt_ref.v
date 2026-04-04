// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : cdp_icvt_ref.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Pure Verilog Reference Model for CDP ICVT (Input Converter)
//   Mimics cdp_icvt.cpp
//   Operations: ALU(sub) -> MUL -> TRUNCATE
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module cdp_icvt_ref #(
    parameter DATA_IN_WIDTH = 16,
    parameter ALU_IN_WIDTH = 16,
    parameter MUL_IN_WIDTH = 16,
    parameter TRUNCATE_WIDTH = 8,
    parameter DATA_OUT_WIDTH = 16
) (
    input nvdla_core_clk,
    input nvdla_core_rstn,

    // Handshake
    input chn_data_in_vld,
    output chn_data_in_rdy,
    input [DATA_IN_WIDTH-1:0] chn_data_in,

    input [1:0] cfg_precision,  // 0=INT8, 1=INT16, 2=FP16

    // ALU config
    input [ALU_IN_WIDTH-1:0] cfg_alu_in,

    // MUL config
    input [MUL_IN_WIDTH-1:0] cfg_mul_in,

    // Truncate config
    input [TRUNCATE_WIDTH-1:0] cfg_truncate,

    // Output
    output chn_data_out_vld,
    input chn_data_out_rdy,
    output [DATA_OUT_WIDTH-1:0] chn_data_out
);

    localparam PREC_INT8 = 2'b00;
    localparam PREC_INT16 = 2'b01;
    localparam PREC_FP16 = 2'b10;

    reg [DATA_IN_WIDTH-1:0] data_in_reg;
    reg [ALU_IN_WIDTH-1:0] alu_in_reg;
    reg [MUL_IN_WIDTH-1:0] mul_in_reg;
    reg [TRUNCATE_WIDTH-1:0] truncate_reg;
    reg [1:0] precision_reg;
    reg valid_q;

    wire [DATA_OUT_WIDTH-1:0] alu_out;
    wire [DATA_OUT_WIDTH-1:0] mul_out;
    wire [DATA_OUT_WIDTH-1:0] truncate_out;

    // Input capture
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            valid_q <= 1'b0;
        end else if (chn_data_in_vld && chn_data_in_rdy) begin
            data_in_reg <= chn_data_in;
            alu_in_reg <= cfg_alu_in;
            mul_in_reg <= cfg_mul_in;
            truncate_reg <= cfg_truncate;
            precision_reg <= cfg_precision;
            valid_q <= 1'b1;
        end else if (chn_data_out_vld && chn_data_out_rdy) begin
            valid_q <= 1'b0;
        end
    end

    assign chn_data_in_rdy = !valid_q || (chn_data_out_vld && chn_data_out_rdy);

    // ALU - subtraction
    assign alu_out = data_in_reg - alu_in_reg;

    // MUL - multiplication
    assign mul_out = alu_out * mul_in_reg;

    // TRUNCATE - right shift
    assign truncate_out = mul_out >> truncate_reg;

    // Output
    assign chn_data_out = truncate_out;
    assign chn_data_out_vld = valid_q;

endmodule