// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_mcif_cvif_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA MCIF/CVIF Memory Interface Module
// - Handles DMA read requests to external memory
// - MCIF: Main memory interface (DDR)
// - CVIF: Co-processor memory interface
// - Arbiter for prioritizing requests between data and weight paths
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_mcif_cvif_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  // MCIF write response interface
  ,mcif2cdma_dat_wr_rsp_valid
  ,mcif2cdma_dat_wr_rsp_ready
  ,mcif2cdma_wt_wr_rsp_valid
  ,mcif2cdma_wt_wr_rsp_ready
  // CVIF write response interface
  ,cvif2cdma_dat_wr_rsp_valid
  ,cvif2cdma_dat_wr_rsp_ready
  ,cvif2cdma_wt_wr_rsp_valid
  ,cvif2cdma_wt_wr_rsp_ready
  // Register configuration
  ,reg2dp_datain_ram_type
  ,reg2dp_weight_ram_type
  ,reg2dp_arb_weight
  ,reg2dp_arb_wmb
  // Data path read request (from image/winograd/dc paths)
  ,dat2mcif_rd_req_valid
  ,dat2mcif_rd_req_ready
  ,dat2mcif_rd_req_pd
  ,dat2cvif_rd_req_valid
  ,dat2cvif_rd_req_ready
  ,dat2cvif_rd_req_pd
  // Weight path read request
  ,wt2mcif_rd_req_valid
  ,wt2mcif_rd_req_ready
  ,wt2mcif_rd_req_pd
  ,wt2cvif_rd_req_valid
  ,wt2cvif_rd_req_ready
  ,wt2cvif_rd_req_pd
  // WMB (Weight Metadata Buffer) read request
  ,wmb2mcif_rd_req_valid
  ,wmb2mcif_rd_req_ready
  ,wmb2mcif_rd_req_pd
  ,wmb2cvif_rd_req_valid
  ,wmb2cvif_rd_req_ready
  ,wmb2cvif_rd_req_pd
  // WGS (Weight Global Sum) read request
  ,wgs2mcif_rd_req_valid
  ,wgs2mcif_rd_req_ready
  ,wgs2mcif_rd_req_pd
  ,wgs2cvif_rd_req_valid
  ,wgs2cvif_rd_req_ready
  ,wgs2cvif_rd_req_pd
  // Output to MCIF
  ,cdma2mcif_dat_rd_req_valid
  ,cdma2mcif_dat_rd_req_ready
  ,cdma2mcif_dat_rd_req_pd
  ,cdma2mcif_wt_rd_req_valid
  ,cdma2mcif_wt_rd_req_ready
  ,cdma2mcif_wt_rd_req_pd
  // Output to CVIF
  ,cdma2cvif_dat_rd_req_valid
  ,cdma2cvif_dat_rd_req_ready
  ,cdma2cvif_dat_rd_req_pd
  ,cdma2cvif_wt_rd_req_valid
  ,cdma2cvif_wt_rd_req_ready
  ,cdma2cvif_wt_rd_req_pd
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// MCIF write response
input        mcif2cdma_dat_wr_rsp_valid;
output       mcif2cdma_dat_wr_rsp_ready;
input        mcif2cdma_wt_wr_rsp_valid;
output       mcif2cdma_wt_wr_rsp_ready;

// CVIF write response
input        cvif2cdma_dat_wr_rsp_valid;
output       cvif2cdma_dat_wr_rsp_ready;
input        cvif2cdma_wt_wr_rsp_valid;
output       cvif2cdma_wt_wr_rsp_ready;

// Register configuration
input        reg2dp_datain_ram_type;  // 0=MCIF, 1=CVIF
input        reg2dp_weight_ram_type;   // 0=MCIF, 1=CVIF
input  [3:0] reg2dp_arb_weight;        // Weight for data/weight arbitration
input  [3:0] reg2dp_arb_wmb;           // Weight for WMB arbitration

// Data path read requests
input        dat2mcif_rd_req_valid;
output       dat2mcif_rd_req_ready;
input  [78:0] dat2mcif_rd_req_pd;
input        dat2cvif_rd_req_valid;
output       dat2cvif_rd_req_ready;
input  [78:0] dat2cvif_rd_req_pd;

// Weight path read requests
input        wt2mcif_rd_req_valid;
output       wt2mcif_rd_req_ready;
input  [78:0] wt2mcif_rd_req_pd;
input        wt2cvif_rd_req_valid;
output       wt2cvif_rd_req_ready;
input  [78:0] wt2cvif_rd_req_pd;

// WMB read requests
input        wmb2mcif_rd_req_valid;
output       wmb2mcif_rd_req_ready;
input  [78:0] wmb2mcif_rd_req_pd;
input        wmb2cvif_rd_req_valid;
output       wmb2cvif_rd_req_ready;
input  [78:0] wmb2cvif_rd_req_pd;

// WGS read requests
input        wgs2mcif_rd_req_valid;
output       wgs2mcif_rd_req_ready;
input  [78:0] wgs2mcif_rd_req_pd;
input        wgs2cvif_rd_req_valid;
output       wgs2cvif_rd_req_ready;
input  [78:0] wgs2cvif_rd_req_pd;

// Output to MCIF
output        cdma2mcif_dat_rd_req_valid;
input         cdma2mcif_dat_rd_req_ready;
output  [78:0] cdma2mcif_dat_rd_req_pd;
output        cdma2mcif_wt_rd_req_valid;
input         cdma2mcif_wt_rd_req_ready;
output  [78:0] cdma2mcif_wt_rd_req_pd;

// Output to CVIF
output        cdma2cvif_dat_rd_req_valid;
input         cdma2cvif_dat_rd_req_ready;
output  [78:0] cdma2cvif_dat_rd_req_pd;
output        cdma2cvif_wt_rd_req_valid;
input         cdma2cvif_wt_rd_req_ready;
output  [78:0] cdma2cvif_wt_rd_req_pd;

//===============================================================
// PARAMETERS
//===============================================================
// RAM type
localparam        RAM_MC = 1'b0;
localparam        RAM_CVIF = 1'b1;

// Request type encoding in pd[78:76]
localparam [2:0] REQ_TYPE_DAT = 3'd0;
localparam [2:0] REQ_TYPE_WT = 3'd1;
localparam [2:0] REQ_TYPE_WMB = 3'd2;
localparam [2:0] REQ_TYPE_WGS = 3'd3;

// Arbitration state
localparam [1:0] ARB_STATE_IDLE   = 2'd0;
localparam [1:0] ARB_STATE_DAT     = 2'd1;
localparam [1:0] ARB_STATE_WT      = 2'd2;
localparam [1:0] ARB_STATE_WMB_WGS = 2'd3;

//===============================================================
// SIGNAL DECLARATION
//===============================================================
// Arbitration
reg  [1:0]  arb_state_q;
reg  [1:0]  arb_state_next;
reg  [2:0]  arb_counter_q;
reg  [2:0]  arb_counter_next;
wire       dat_req_pending;
wire       wt_req_pending;
wire       wmb_req_pending;
wire       wgs_req_pending;
wire       any_req_pending;

// MCIF request hold
reg         mcif_dat_req_hold;
reg  [78:0] mcif_dat_req_pd_hold;
reg         mcif_wt_req_hold;
reg  [78:0] mcif_wt_req_pd_hold;

// CVIF request hold
reg         cvif_dat_req_hold;
reg  [78:0] cvif_dat_req_pd_hold;
reg         cvif_wt_req_hold;
reg  [78:0] cvif_wt_req_pd_hold;

// Ready signals
reg         dat2mcif_rd_req_ready_r;
reg         dat2cvif_rd_req_ready_r;
reg         wt2mcif_rd_req_ready_r;
reg         wt2cvif_rd_req_ready_r;
reg         wmb2mcif_rd_req_ready_r;
reg         wmb2cvif_rd_req_ready_r;
reg         wgs2mcif_rd_req_ready_r;
reg         wgs2cvif_rd_req_ready_r;

// Response ready
reg         mcif2cdma_dat_wr_rsp_ready_r;
reg         mcif2cdma_wt_wr_rsp_ready_r;
reg         cvif2cdma_dat_wr_rsp_ready_r;
reg         cvif2cdma_wt_wr_rsp_ready_r;

//===============================================================
// REQUEST TRACKING
//===============================================================
// Track pending requests
assign dat_req_pending = dat2mcif_rd_req_valid || dat2cvif_rd_req_valid ||
                        mcif_dat_req_hold || cvif_dat_req_hold;
assign wt_req_pending = wt2mcif_rd_req_valid || wt2cvif_rd_req_valid ||
                       mcif_wt_req_hold || cvif_wt_req_hold;
assign wmb_req_pending = wmb2mcif_rd_req_valid || wmb2cvif_rd_req_valid;
assign wgs_req_pending = wgs2mcif_rd_req_valid || wgs2cvif_rd_req_valid;
assign any_req_pending = dat_req_pending || wt_req_pending || wmb_req_pending || wgs_req_pending;

//===============================================================
// ARBITRATION STATE MACHINE
//===============================================================
// Sequencer
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    arb_state_q <= ARB_STATE_IDLE;
    arb_counter_q <= 3'd0;
  end else begin
    arb_state_q <= arb_state_next;
    arb_counter_q <= arb_counter_next;
  end
end

// Combinational next state
always @* begin
  arb_state_next = arb_state_q;
  arb_counter_next = arb_counter_q;

  case (arb_state_q)
    ARB_STATE_IDLE: begin
      if (dat_req_pending) begin
        arb_state_next = ARB_STATE_DAT;
        arb_counter_next = 3'd0;
      end else if (wt_req_pending) begin
        arb_state_next = ARB_STATE_WT;
        arb_counter_next = 3'd0;
      end else if (wmb_req_pending || wgs_req_pending) begin
        arb_state_next = ARB_STATE_WMB_WGS;
        arb_counter_next = 3'd0;
      end
    end

    ARB_STATE_DAT: begin
      arb_counter_next = arb_counter_q + 3'd1;
      if (arb_counter_q >= reg2dp_arb_weight) begin
        if (wt_req_pending) begin
          arb_state_next = ARB_STATE_WT;
          arb_counter_next = 3'd0;
        end else if (wmb_req_pending || wgs_req_pending) begin
          arb_state_next = ARB_STATE_WMB_WGS;
          arb_counter_next = 3'd0;
        end else if (!dat_req_pending) begin
          arb_state_next = ARB_STATE_IDLE;
        end
      end
    end

    ARB_STATE_WT: begin
      arb_counter_next = arb_counter_q + 3'd1;
      if (arb_counter_q >= reg2dp_arb_weight) begin
        if (dat_req_pending) begin
          arb_state_next = ARB_STATE_DAT;
          arb_counter_next = 3'd0;
        end else if (wmb_req_pending || wgs_req_pending) begin
          arb_state_next = ARB_STATE_WMB_WGS;
          arb_counter_next = 3'd0;
        end else if (!wt_req_pending) begin
          arb_state_next = ARB_STATE_IDLE;
        end
      end
    end

    ARB_STATE_WMB_WGS: begin
      arb_counter_next = arb_counter_q + 3'd1;
      if (arb_counter_q >= reg2dp_arb_wmb) begin
        if (dat_req_pending) begin
          arb_state_next = ARB_STATE_DAT;
          arb_counter_next = 3'd0;
        end else if (wt_req_pending) begin
          arb_state_next = ARB_STATE_WT;
          arb_counter_next = 3'd0;
        end else if (!wmb_req_pending && !wgs_req_pending) begin
          arb_state_next = ARB_STATE_IDLE;
        end
      end
    end

    default: arb_state_next = ARB_STATE_IDLE;
  endcase
end

//===============================================================
// REQUEST HOLD LOGIC
//===============================================================
// Hold data requests when their target interface is busy
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mcif_dat_req_hold <= 1'b0;
    mcif_dat_req_pd_hold <= 79'd0;
    cvif_dat_req_hold <= 1'b0;
    cvif_dat_req_pd_hold <= 79'd0;
    mcif_wt_req_hold <= 1'b0;
    mcif_wt_req_pd_hold <= 79'd0;
    cvif_wt_req_hold <= 1'b0;
    cvif_wt_req_pd_hold <= 79'd0;
  end else begin
    // Data requests to MCIF
    if (dat2mcif_rd_req_valid && dat2mcif_rd_req_ready_r) begin
      mcif_dat_req_hold <= 1'b0;
    end else if (dat2mcif_rd_req_valid && !cdma2mcif_dat_rd_req_ready) begin
      mcif_dat_req_hold <= 1'b1;
      mcif_dat_req_pd_hold <= dat2mcif_rd_req_pd;
    end

    // Data requests to CVIF
    if (dat2cvif_rd_req_valid && dat2cvif_rd_req_ready_r) begin
      cvif_dat_req_hold <= 1'b0;
    end else if (dat2cvif_rd_req_valid && !cdma2cvif_dat_rd_req_ready) begin
      cvif_dat_req_hold <= 1'b1;
      cvif_dat_req_pd_hold <= dat2cvif_rd_req_pd;
    end

    // Weight requests to MCIF
    if (wt2mcif_rd_req_valid && wt2mcif_rd_req_ready_r) begin
      mcif_wt_req_hold <= 1'b0;
    end else if (wt2mcif_rd_req_valid && !cdma2mcif_wt_rd_req_ready) begin
      mcif_wt_req_hold <= 1'b1;
      mcif_wt_req_pd_hold <= wt2mcif_rd_req_pd;
    end

    // Weight requests to CVIF
    if (wt2cvif_rd_req_valid && wt2cvif_rd_req_ready_r) begin
      cvif_wt_req_hold <= 1'b0;
    end else if (wt2cvif_rd_req_valid && !cdma2cvif_wt_rd_req_ready) begin
      cvif_wt_req_hold <= 1'b1;
      cvif_wt_req_pd_hold <= wt2cvif_rd_req_pd;
    end
  end
end

//===============================================================
// READY SIGNAL GENERATION
//===============================================================
// Ready when not holding a request and arbiter grants access
always @* begin
  dat2mcif_rd_req_ready_r = 1'b0;
  dat2cvif_rd_req_ready_r = 1'b0;
  wt2mcif_rd_req_ready_r = 1'b0;
  wt2cvif_rd_req_ready_r = 1'b0;
  wmb2mcif_rd_req_ready_r = 1'b0;
  wmb2cvif_rd_req_ready_r = 1'b0;
  wgs2mcif_rd_req_ready_r = 1'b0;
  wgs2cvif_rd_req_ready_r = 1'b0;

  case (arb_state_q)
    ARB_STATE_DAT: begin
      dat2mcif_rd_req_ready_r = cdma2mcif_dat_rd_req_ready;
      dat2cvif_rd_req_ready_r = cdma2cvif_dat_rd_req_ready;
    end

    ARB_STATE_WT: begin
      wt2mcif_rd_req_ready_r = cdma2mcif_wt_rd_req_ready;
      wt2cvif_rd_req_ready_r = cdma2cvif_wt_rd_req_ready;
    end

    ARB_STATE_WMB_WGS: begin
      wmb2mcif_rd_req_ready_r = 1'b1;
      wmb2cvif_rd_req_ready_r = 1'b1;
      wgs2mcif_rd_req_ready_r = 1'b1;
      wgs2cvif_rd_req_ready_r = 1'b1;
    end

    default: begin
      // In IDLE, accept any request
      dat2mcif_rd_req_ready_r = cdma2mcif_dat_rd_req_ready;
      dat2cvif_rd_req_ready_r = cdma2cvif_dat_rd_req_ready;
      wt2mcif_rd_req_ready_r = cdma2mcif_wt_rd_req_ready;
      wt2cvif_rd_req_ready_r = cdma2cvif_wt_rd_req_ready;
    end
  endcase
end

// Response ready signals
always @* begin
  mcif2cdma_dat_wr_rsp_ready_r = 1'b1;
  mcif2cdma_wt_wr_rsp_ready_r = 1'b1;
  cvif2cdma_dat_wr_rsp_ready_r = 1'b1;
  cvif2cdma_wt_wr_rsp_ready_r = 1'b1;
end

//===============================================================
// OUTPUT ASSIGNMENT
//===============================================================
// MCIF data read request - pass through or from hold
assign cdma2mcif_dat_rd_req_valid = dat2mcif_rd_req_valid || mcif_dat_req_hold;
assign cdma2mcif_dat_rd_req_pd = mcif_dat_req_hold ? mcif_dat_req_pd_hold : dat2mcif_rd_req_pd;

// MCIF weight read request
assign cdma2mcif_wt_rd_req_valid = wt2mcif_rd_req_valid || mcif_wt_req_hold;
assign cdma2mcif_wt_rd_req_pd = mcif_wt_req_hold ? mcif_wt_req_pd_hold : wt2mcif_rd_req_pd;

// CVIF data read request
assign cdma2cvif_dat_rd_req_valid = dat2cvif_rd_req_valid || cvif_dat_req_hold;
assign cdma2cvif_dat_rd_req_pd = cvif_dat_req_hold ? cvif_dat_req_pd_hold : dat2cvif_rd_req_pd;

// CVIF weight read request
assign cdma2cvif_wt_rd_req_valid = wt2cvif_rd_req_valid || cvif_wt_req_hold;
assign cdma2cvif_wt_rd_req_pd = cvif_wt_req_hold ? cvif_wt_req_pd_hold : wt2cvif_rd_req_pd;

// Ready signals to input paths
assign dat2mcif_rd_req_ready = dat2mcif_rd_req_ready_r;
assign dat2cvif_rd_req_ready = dat2cvif_rd_req_ready_r;
assign wt2mcif_rd_req_ready = wt2mcif_rd_req_ready_r;
assign wt2cvif_rd_req_ready = wt2cvif_rd_req_ready_r;
assign wmb2mcif_rd_req_ready = wmb2mcif_rd_req_ready_r;
assign wmb2cvif_rd_req_ready = wmb2cvif_rd_req_ready_r;
assign wgs2mcif_rd_req_ready = wgs2mcif_rd_req_ready_r;
assign wgs2cvif_rd_req_ready = wgs2cvif_rd_req_ready_r;

// Response ready
assign mcif2cdma_dat_wr_rsp_ready = mcif2cdma_dat_wr_rsp_ready_r;
assign mcif2cdma_wt_wr_rsp_ready = mcif2cdma_wt_wr_rsp_ready_r;
assign cvif2cdma_dat_wr_rsp_ready = cvif2cdma_dat_wr_rsp_ready_r;
assign cvif2cdma_wt_wr_rsp_ready = cvif2cdma_wt_wr_rsp_ready_r;

endmodule // NV_NVDLA_CDMA_mcif_cvif_new