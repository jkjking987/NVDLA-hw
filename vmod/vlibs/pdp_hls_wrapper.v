// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : pdp_hls_wrapper.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   PDP (Pooling Data Processor) HLS wrapper
//   - Stage 0: Pooling stage 0 calculation (width/height)
//   - Stage 1: Pooling stage 1 calculation
// +FHDR------------------------------------------------------------

module pdp_hls_wrapper (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,         // 16-bit input
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_o_rsc_z,         // 16-bit output
    chn_o_rsc_vz,
    chn_o_rsc_lz
);

    parameter I_WIDTH = 16;
    parameter O_WIDTH = 16;

    input nvdla_core_clk;
    input nvdla_core_rstn;
    input  [I_WIDTH-1:0] chn_a_rsc_z;
    input                 chn_a_rsc_vz;
    output                chn_a_rsc_lz;
    output [O_WIDTH-1:0] chn_o_rsc_z;
    input                 chn_o_rsc_vz;
    output                chn_o_rsc_lz;

    wire inputAccepted;
    reg output_valid_q;
    reg s1_v;

    assign inputAccepted = chn_a_rsc_vz & chn_o_rsc_vz;
    assign chn_a_rsc_lz = inputAccepted;
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

    // Pass-through pooling result
    reg [O_WIDTH-1:0] chn_o_rsc_z_q;
    assign chn_o_rsc_z = chn_o_rsc_z_q;

    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn)
            chn_o_rsc_z_q <= {O_WIDTH{1'b0}};
        else if (s1_v)
            chn_o_rsc_z_q <= chn_a_rsc_z;
    end

endmodule
