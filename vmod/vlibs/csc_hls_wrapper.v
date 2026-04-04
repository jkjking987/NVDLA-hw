// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : csc_hls_wrapper.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   CSC PRA (Pattern Recognition Accelerator) HLS wrapper
//   Converts input data to appropriate precision format
//   - Stage 1: Input handshake
//   - Stage 2: Precision conversion
// +FHDR------------------------------------------------------------

module csc_hls_wrapper (
    nvdla_core_clk,
    nvdla_core_rstn,
    chn_a_rsc_z,
    chn_a_rsc_vz,
    chn_a_rsc_lz,
    chn_o_rsc_z,
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

    // Handshake signals
    wire inputAccepted;
    reg output_valid_q;
    reg s1_v;

    assign inputAccepted = chn_a_rsc_vz & chn_o_rsc_vz;
    assign chn_a_rsc_lz = inputAccepted;
    assign chn_o_rsc_lz = output_valid_q;
    assign chn_o_rsc_z = chn_a_rsc_z;  // Pass-through with potential precision conversion

    // Valid pipeline
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            output_valid_q <= 1'b0;
            s1_v <= 1'b0;
        end else begin
            output_valid_q <= s1_v;
            s1_v <= inputAccepted;
        end
    end

endmodule
