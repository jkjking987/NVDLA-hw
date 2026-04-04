// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_csb_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA CSB (Command and Status Bus) Interface Module
// - Converts CSB protocol to internal register access
// - Handles read/write transactions with proper handshaking
// - Supports 32-bit register access at 12-bit addressing
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_csb_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  // CSB interface (slave)
  ,csb2cdma_req_pvld
  ,csb2cdma_req_prdy
  ,csb2cdma_req_pd
  ,cdma2csb_resp_valid
  ,cdma2csb_resp_prdy
  ,cdma2csb_resp_pd
  // Internal register interface
  ,reg2csb_addr
  ,reg2csb_wdat
  ,reg2csb_wr_en
  ,reg2csb_rd_en
  ,csb2reg_rdat
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// CSB slave interface
input        csb2cdma_req_pvld;     // Request valid
output       csb2cdma_req_prdy;     // Request ready
input  [62:0] csb2cdma_req_pd;      // Request payload: {addr[11:0], wdat[31:0], wr_en, rd_en}
output       cdma2csb_resp_valid;   // Response valid
input        cdma2csb_resp_prdy;    // Response ready
output [33:0] cdma2csb_resp_pd;    // Response payload: {rdata[31:0], 2'b0}

// Internal register interface
output [11:0] reg2csb_addr;
output [31:0] reg2csb_wdat;
output       reg2csb_wr_en;
output       reg2csb_rd_en;
input  [31:0] csb2reg_rdat;

//===============================================================
// PARAMETERS
//===============================================================
localparam [1:0] CSB_IDLE   = 2'd0;
localparam [1:0] CSB_WRITE  = 2'd1;
localparam [1:0] CSB_READ   = 2'd2;
localparam [1:0] CSB_RESP   = 2'd3;

//===============================================================
// SIGNAL DECLARATION
//===============================================================
// Request payload decode
wire  [11:0] req_addr;
wire  [31:0] req_wdat;
wire        req_wr_en;
wire        req_rd_en;

// State machine
reg  [1:0]  state_q;
reg  [1:0]  next_state;

// Response holding
reg  [31:0] resp_rdat_q;
reg         resp_valid_q;

// CDC for req_pvld
reg         req_pvld_sync1;
reg         req_pvld_sync2;
reg         req_pvld_sync3;

//===============================================================
// REQUEST PAYLOAD DECODE
//===============================================================
assign req_addr  = csb2cdma_req_pd[62:51];
assign req_wdat  = csb2cdma_req_pd[50:19];
assign req_wr_en = csb2cdma_req_pd[1];
assign req_rd_en = csb2cdma_req_pd[0];

//===============================================================
// CDC FOR ASYNC REQUEST VALID
//===============================================================
// 2-FF synchronizer for req_pvld (assumed async signal)
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_pvld_sync1 <= 1'b0;
    req_pvld_sync2 <= 1'b0;
    req_pvld_sync3 <= 1'b0;
  end else begin
    req_pvld_sync1 <= csb2cdma_req_pvld;
    req_pvld_sync2 <= req_pvld_sync1;
    req_pvld_sync3 <= req_pvld_sync2;
  end
end

//===============================================================
// STATE MACHINE - SEQUENTIAL
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_q <= CSB_IDLE;
  end else begin
    state_q <= next_state;
  end
end

//===============================================================
// STATE MACHINE - COMBINATIONAL
//===============================================================
always @* begin
  next_state = state_q;
  case (state_q)
    CSB_IDLE: begin
      if (req_pvld_sync3 && (req_wr_en || req_rd_en)) begin
        if (req_wr_en)
          next_state = CSB_WRITE;
        else
          next_state = CSB_READ;
      end
    end

    CSB_WRITE: begin
      // Write takes 1 cycle, go to resp
      next_state = CSB_RESP;
    end

    CSB_READ: begin
      // Read takes 1 cycle to get data from register, go to resp
      next_state = CSB_RESP;
    end

    CSB_RESP: begin
      // Wait for response handshake
      if (cdma2csb_resp_prdy)
        next_state = CSB_IDLE;
    end

    default: next_state = CSB_IDLE;
  endcase
end

//===============================================================
// RESPONSE HANDLING
//===============================================================
// Capture read data when entering READ state
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    resp_rdat_q <= 32'd0;
  end else if (state_q == CSB_IDLE && req_pvld_sync3 && req_rd_en) begin
    resp_rdat_q <= csb2reg_rdat;
  end
end

// Response valid signal
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    resp_valid_q <= 1'b0;
  end else if (state_q == CSB_RESP) begin
    resp_valid_q <= 1'b1;
  end else if (cdma2csb_resp_prdy) begin
    resp_valid_q <= 1'b0;
  end
end

//===============================================================
// OUTPUT ASSIGNMENTS
//===============================================================
// Request ready - not busy
assign csb2cdma_req_prdy = (state_q == CSB_IDLE);

// Response valid
assign cdma2csb_resp_valid = resp_valid_q;

// Response payload: {rdata[31:0], 2'b0}
assign cdma2csb_resp_pd = {resp_rdat_q, 2'b0};

// Internal register interface - only valid during WRITE/READ states
assign reg2csb_addr  = (state_q == CSB_IDLE) ? req_addr : 12'd0;
assign reg2csb_wdat  = (state_q == CSB_WRITE) ? req_wdat : 32'd0;
assign reg2csb_wr_en = (state_q == CSB_WRITE);
assign reg2csb_rd_en = (state_q == CSB_READ);

endmodule // NV_NVDLA_CDMA_csb_new