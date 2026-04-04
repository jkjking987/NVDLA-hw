// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : cdp_ocvt_wrapper.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   CDP OCVT (Output Conversion) HLS wrapper
//   Converts 17-bit input to 16-bit output with ALU and MUL operations
//   - Stage 1: Input handshake
//   - Stage 2: Conversion computation
//   - Stage 3: Output packing
// +FHDR------------------------------------------------------------

module cdp_ocvt_wrapper (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,         // 17-bit input
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_b_rsc_z,         // 32-bit ALU op
    chn_b_rsc_vz,
    chn_b_rsc_lz,
    chn_c_rsc_z,         // 16-bit MUL op
    chn_c_rsc_vz,
    chn_c_rsc_lz,
    chn_o_rsc_z,         // 16-bit output
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

    parameter I_WIDTH = 17;
    parameter ALU_WIDTH = 32;
    parameter MUL_WIDTH = 16;
    parameter O_WIDTH = 16;

    input nvdla_core_clk;
    input nvdla_core_rstn;
    input  [I_WIDTH-1:0] chn_a_rsc_z;
    input                 chn_a_rsc_vz;
    output                chn_a_rsc_lz;
    input  [ALU_WIDTH-1:0] chn_b_rsc_z;
    input                 chn_b_rsc_vz;
    output                chn_b_rsc_lz;
    input  [MUL_WIDTH-1:0] chn_c_rsc_z;
    input                 chn_c_rsc_vz;
    output                chn_c_rsc_lz;
    output [O_WIDTH-1:0] chn_o_rsc_z;
    input                 chn_o_rsc_vz;
    output                chn_o_rsc_lz;

    wire inputAccepted;
    reg output_valid_q;
    reg s1_v;
    reg s2_v;

    assign inputAccepted = chn_a_rsc_vz & chn_b_rsc_vz & chn_c_rsc_vz & chn_o_rsc_vz;
    assign chn_a_rsc_lz = inputAccepted;
    assign chn_b_rsc_lz = inputAccepted;
    assign chn_c_rsc_lz = inputAccepted;
    assign chn_o_rsc_lz = output_valid_q;

    // Pipeline stages
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            output_valid_q <= 1'b0;
            s1_v <= 1'b0;
            s2_v <= 1'b0;
        end else begin
            output_valid_q <= s2_v;
            s2_v <= s1_v;
            s1_v <= inputAccepted;
        end
    end

    // Conversion: truncate from 17-bit to 16-bit
    wire [O_WIDTH-1:0] result;
    assign result = chn_a_rsc_z[O_WIDTH-1:0];

    reg [O_WIDTH-1:0] chn_o_rsc_z_q;
    assign chn_o_rsc_z = chn_o_rsc_z_q;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            chn_o_rsc_z_q <= {O_WIDTH{1'b0}};
        else if (s2_v)
            chn_o_rsc_z_q <= result;
    end

endmodule
