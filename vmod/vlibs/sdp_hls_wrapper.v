// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : sdp_hls_wrapper.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   SDP (Second Data Processor) HLS wrapper
//   - SDP_X: ALU + MUL processing
//   - SDP_Y: ALU + MUL + LUT processing
//   - SDP_C: Channel-wise processing
// +FHDR------------------------------------------------------------

module sdp_hls_wrapper (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_data_in_rsc_z,
    chn_data_in_rsc_vz,
    chn_data_in_rsc_lz,
    chn_x1_alu_rsc_z,
    chn_x1_alu_rsc_vz,
    chn_x1_alu_rsc_lz,
    chn_x1_mul_rsc_z,
    chn_x1_mul_rsc_vz,
    chn_x1_mul_rsc_lz,
    chn_x2_alu_rsc_z,
    chn_x2_alu_rsc_vz,
    chn_x2_alu_rsc_lz,
    chn_x2_mul_rsc_z,
    chn_x2_mul_rsc_vz,
    chn_x2_mul_rsc_lz,
    chn_y_alu_rsc_z,
    chn_y_alu_rsc_vz,
    chn_y_alu_rsc_lz,
    chn_y_mul_rsc_z,
    chn_y_mul_rsc_vz,
    chn_y_mul_rsc_lz,
    chn_o_rsc_z,
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

    parameter I_WIDTH = 32;
    parameter ALU_WIDTH = 16;
    parameter MUL_WIDTH = 16;
    parameter O_WIDTH = 16;

    input nvdla_core_clk;
    input nvdla_core_rstn;

    // Data input
    input  [I_WIDTH-1:0] chn_data_in_rsc_z;
    input                 chn_data_in_rsc_vz;
    output                chn_data_in_rsc_lz;

    // X1 ALU/MUL inputs
    input  [ALU_WIDTH-1:0] chn_x1_alu_rsc_z;
    input                 chn_x1_alu_rsc_vz;
    output                chn_x1_alu_rsc_lz;
    input  [MUL_WIDTH-1:0] chn_x1_mul_rsc_z;
    input                 chn_x1_mul_rsc_vz;
    output                chn_x1_mul_rsc_lz;

    // X2 ALU/MUL inputs
    input  [ALU_WIDTH-1:0] chn_x2_alu_rsc_z;
    input                 chn_x2_alu_rsc_vz;
    output                chn_x2_alu_rsc_lz;
    input  [MUL_WIDTH-1:0] chn_x2_mul_rsc_z;
    input                 chn_x2_mul_rsc_vz;
    output                chn_x2_mul_rsc_lz;

    // Y ALU/MUL inputs
    input  [ALU_WIDTH-1:0] chn_y_alu_rsc_z;
    input                 chn_y_alu_rsc_vz;
    output                chn_y_alu_rsc_lz;
    input  [MUL_WIDTH-1:0] chn_y_mul_rsc_z;
    input                 chn_y_mul_rsc_vz;
    output                chn_y_mul_rsc_lz;

    // Output
    output [O_WIDTH-1:0] chn_o_rsc_z;
    input                 chn_o_rsc_vz;
    output                chn_o_rsc_lz;

    wire inputAccepted;
    reg output_valid_q;
    reg s1_v;

    assign inputAccepted = chn_data_in_rsc_vz & chn_x1_alu_rsc_vz & chn_x1_mul_rsc_vz &
                          chn_x2_alu_rsc_vz & chn_x2_mul_rsc_vz &
                          chn_y_alu_rsc_vz & chn_y_mul_rsc_vz & chn_o_rsc_vz;

    assign chn_data_in_rsc_lz = inputAccepted;
    assign chn_x1_alu_rsc_lz = inputAccepted;
    assign chn_x1_mul_rsc_lz = inputAccepted;
    assign chn_x2_alu_rsc_lz = inputAccepted;
    assign chn_x2_mul_rsc_lz = inputAccepted;
    assign chn_y_alu_rsc_lz = inputAccepted;
    assign chn_y_mul_rsc_lz = inputAccepted;
    assign chn_o_rsc_lz = output_valid_q;

    // Pipeline stages
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            output_valid_q <= 1'b0;
            s1_v <= 1'b0;
        end else begin
            output_valid_q <= s1_v;
            s1_v <= inputAccepted;
        end
    end

    // SDP processing: pass-through for now
    // Actual implementation would include ALU/MUL/LUT stages
    wire [O_WIDTH-1:0] result;
    assign result = chn_data_in_rsc_z[O_WIDTH-1:0];

    reg [O_WIDTH-1:0] chn_o_rsc_z_q;
    assign chn_o_rsc_z = chn_o_rsc_z_q;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            chn_o_rsc_z_q <= {O_WIDTH{1'b0}};
        else if (s1_v)
            chn_o_rsc_z_q <= result;
    end

endmodule
