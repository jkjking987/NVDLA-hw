// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_csb_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSB (Config Space Bus) interface for CMAC
// - Receives CSB read/write requests
// - Returns responses for read and write transactions
// - Protocol: valid/ready handshake
// +FHDR------------------------------------------------------------

`include "simulate_x_tick.vh"

module NV_NVDLA_CMAC_csb_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,csb2cmac_req_pvld
  ,csb2cmac_req_pd
  ,cmac2csb_resp_pvld
  ,cmac2csb_resp_pd
  ,csb2cmac_req_prdy
  );

//==============================================================
// Port declarations
//==============================================================
input        nvdla_core_clk;
input        nvdla_core_rstn;

// CSB request interface (from CSB master)
input        csb2cmac_req_pvld;       // Request valid
input  [62:0] csb2cmac_req_pd;         // Request payload
output       csb2cmac_req_prdy;        // Request ready

// CSB response interface (to CSB master)
output       cmac2csb_resp_pvld;      // Response valid
output [33:0] cmac2csb_resp_pd;        // Response payload

//==============================================================
// Parameters
//==============================================================
localparam NVDLA_CMAC_A_D_OP_ENABLE_ADDR  = 12'h7008;
localparam NVDLA_CMAC_A_D_MISC_CFG_ADDR   = 12'h700c;

//==============================================================
// Internal signals
//==============================================================
// Request pipeline
reg  [62:0] req_pd_r;
reg         req_pvld_r;

// Decoded request fields
wire [21:0] req_addr;
wire [31:0] req_wdat;
wire        req_write;
wire        req_nposted;
wire [3:0]  req_wrbe;
wire [1:0]  req_level;

// Response data
reg  [33:0] resp_pd_r;
reg         resp_pvld_r;

// Write response data (no data returned on write)
wire [33:0] wr_resp_pd;
wire        wr_resp_pvld;

// Read response data
wire [33:0] rd_resp_pd;
wire        rd_resp_pvld;

//==============================================================
// Request pipeline register
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_pvld_r <= 1'b0;
    req_pd_r   <= '0;
  end else begin
    req_pvld_r <= csb2cmac_req_pvld;
    if (csb2cmac_req_pvld) begin
      req_pd_r   <= csb2cmac_req_pd;
    end
  end
end

//==============================================================
// Decode request packet
//==============================================================
assign req_addr[21:0]  = req_pd_r[21:0];
assign req_wdat[31:0]  = req_pd_r[53:22];
assign req_write       = req_pd_r[54];
assign req_nposted     = req_pd_r[55];
assign req_wrbe[3:0]   = req_pd_r[60:57];
assign req_level[1:0]  = req_pd_r[62:61];

//==============================================================
// Request ready (always ready in this implementation)
//==============================================================
assign csb2cmac_req_prdy = 1'b1;

//==============================================================
// Read response generation
// - Response data will be provided by register file via external logic
// - This module just passes through the read data
//==============================================================
assign rd_resp_pd[31:0] = req_wdat[31:0];  // Placeholder - will be replaced by reg read data
assign rd_resp_pd[32]  = 1'b0;             // No error
assign rd_resp_pd[33]  = 1'b0;            // Read response ID
assign rd_resp_pvld    = req_pvld_r & ~req_write;

//==============================================================
// Write response generation
//==============================================================
assign wr_resp_pd[31:0] = 32'h0;           // Write has no data return
assign wr_resp_pd[32]  = 1'b0;            // No error
assign wr_resp_pd[33]  = 1'b1;            // Write response ID
assign wr_resp_pvld    = req_pvld_r & req_write & req_nposted;

//==============================================================
// Response generation
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    resp_pvld_r <= 1'b0;
    resp_pd_r   <= '0;
  end else begin
    if (rd_resp_pvld) begin
      resp_pvld_r <= 1'b1;
      resp_pd_r   <= rd_resp_pd;
    end else if (wr_resp_pvld) begin
      resp_pvld_r <= 1'b1;
      resp_pd_r   <= wr_resp_pd;
    end else begin
      resp_pvld_r <= 1'b0;
    end
  end
end

assign cmac2csb_resp_pvld = resp_pvld_r;
assign cmac2csb_resp_pd   = resp_pd_r;

endmodule // NV_NVDLA_CMAC_csb_new