// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_mcif_cvif_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSC Memory Interface module (MCIF/CVIF)
// - Handles data transport to/from external memory
// - MCIF: Interface to L2 cache (higher bandwidth)
// - CVIF: Interface to external memory (via CVI - Cache/External)
// - Arbiter for multiple request sources (data, weight, WMB)
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_mcif_cvif_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  // CSC internal request sources
  ,sc2buf_dat_rd_en_i            //|< i
  ,sc2buf_dat_rd_addr_i          //|< i  [11:0]
  ,sc2buf_dat_rd_en_o            //|> o
  ,sc2buf_dat_rd_addr_o          //|> o  [11:0]
  ,sc2buf_dat_rd_valid_i         //|< i
  ,sc2buf_dat_rd_data_i          //|< i  [511:0]
  ,sc2buf_dat_rd_valid_o         //|> o
  ,sc2buf_dat_rd_data_o          //|> o  [511:0]
  ,sc2buf_wt_rd_en_i             //|< i
  ,sc2buf_wt_rd_addr_i           //|< i  [11:0]
  ,sc2buf_wt_rd_en_o             //|> o
  ,sc2buf_wt_rd_addr_o           //|> o  [11:0]
  ,sc2buf_wt_rd_valid_i          //|< i
  ,sc2buf_wt_rd_data_i           //|< i  [511:0]
  ,sc2buf_wt_rd_valid_o          //|> o
  ,sc2buf_wt_rd_data_o           //|> o  [511:0]
  ,sc2buf_wmb_rd_en_i            //|< i
  ,sc2buf_wmb_rd_addr_i          //|< i  [11:0]
  ,sc2buf_wmb_rd_en_o            //|> o
  ,sc2buf_wmb_rd_addr_o          //|> o  [11:0]
  ,sc2buf_wmb_rd_valid_i         //|< i
  ,sc2buf_wmb_rd_data_i          //|< i  [511:0]
  ,sc2buf_wmb_rd_valid_o         //|> o
  ,sc2buf_wmb_rd_data_o          //|> o  [511:0]
  // CVIF/MCIF external interface
  ,cvif2sc_dat_rd_ready          //|< i
  ,sc2cvif_dat_rd_req            //|> o
  ,sc2cvif_dat_rd_adq            //|> o  [5:0]
  ,cvif2sc_dat_rd_data           //|< i  [511:0]
  ,cvif2sc_dat_rd_valid          //|< i
  ,cvif2sc_wt_rd_ready           //|< i
  ,sc2cvif_wt_rd_req             //|> o
  ,sc2cvif_wt_rd_adq             //|> o  [5:0]
  ,cvif2sc_wt_rd_data            //|< i  [511:0]
  ,cvif2sc_wt_rd_valid           //|< i
  ,cvif2sc_wmb_rd_ready          //|< i
  ,sc2cvif_wmb_rd_req            //|> o
  ,sc2cvif_wmb_rd_adq            //|> o  [5:0]
  ,cvif2sc_wmb_rd_data           //|< i  [511:0]
  ,cvif2sc_wmb_rd_valid          //|< i
  // Credit interface
  ,sc2cvif_rd_cdt             //|< i  [7:0]
  );

//==========================================
// Parameters
//==========================================
parameter NUM_REQS = 3;  // Data, Weight, WMB
parameter REQ_ID_DAT = 2'd0;
parameter REQ_ID_WT  = 2'd1;
parameter REQ_ID_WMB = 2'd2;

parameter [1:0] PRIORITY_HIGH   = 2'd0;
parameter [1:0] PRIORITY_MEDIUM = 2'd1;
parameter [1:0] PRIORITY_LOW    = 2'd2;

//==========================================
// Ports
//==========================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// Data path from CSC to CBUF (input)
input         sc2buf_dat_rd_en_i;
input  [11:0] sc2buf_dat_rd_addr_i;
output        sc2buf_dat_rd_en_o;
output [11:0] sc2buf_dat_rd_addr_o;
input         sc2buf_dat_rd_valid_i;
input  [511:0] sc2buf_dat_rd_data_i;
output        sc2buf_dat_rd_valid_o;
output [511:0] sc2buf_dat_rd_data_o;

// Weight path from CSC to CBUF
input         sc2buf_wt_rd_en_i;
input  [11:0] sc2buf_wt_rd_addr_i;
output        sc2buf_wt_rd_en_o;
output [11:0] sc2buf_wt_rd_addr_o;
input         sc2buf_wt_rd_valid_i;
input  [511:0] sc2buf_wt_rd_data_i;
output        sc2buf_wt_rd_valid_o;
output [511:0] sc2buf_wt_rd_data_o;

// WMB path from CSC to CBUF
input         sc2buf_wmb_rd_en_i;
input  [11:0] sc2buf_wmb_rd_addr_i;
output        sc2buf_wmb_rd_en_o;
output [11:0] sc2buf_wmb_rd_addr_o;
input         sc2buf_wmb_rd_valid_i;
input  [511:0] sc2buf_wmb_rd_data_i;
output        sc2buf_wmb_rd_valid_o;
output [511:0] sc2buf_wmb_rd_data_o;

// CVIF external interface - Data
input         cvif2sc_dat_rd_ready;
output        sc2cvif_dat_rd_req;
output [5:0]  sc2cvif_dat_rd_adq;
input  [511:0] cvif2sc_dat_rd_data;
input         cvif2sc_dat_rd_valid;

// CVIF external interface - Weight
input         cvif2sc_wt_rd_ready;
output        sc2cvif_wt_rd_req;
output [5:0]  sc2cvif_wt_rd_adq;
input  [511:0] cvif2sc_wt_rd_data;
input         cvif2sc_wt_rd_valid;

// CVIF external interface - WMB
input         cvif2sc_wmb_rd_ready;
output        sc2cvif_wmb_rd_req;
output [5:0]  sc2cvif_wmb_rd_adq;
input  [511:0] cvif2sc_wmb_rd_data;
input         cvif2sc_wmb_rd_valid;

// Credit from CVIF
input  [7:0]  sc2cvif_rd_cdt;

//==========================================
// Internal signals
//==========================================
// Request arbiter state
reg  [1:0]  current_owner;  // Who currently has the bus
reg  [1:0]  next_owner;
reg         request_pending[0:2];  // Each requestor can have pending req

// Credit tracking
reg  [7:0]  credit_count;
reg  [7:0]  credit_snapshot;

// Pipeline registers for request
reg         sc2cvif_dat_rd_req;
reg         sc2cvif_wt_rd_req;
reg         sc2cvif_wmb_rd_req;
reg  [5:0]  sc2cvif_dat_rd_adq;
reg  [5:0]  sc2cvif_wt_rd_adq;
reg  [5:0]  sc2cvif_wmb_rd_adq;

// CVIF response pipeline
reg         dat_rd_received;
reg         wt_rd_received;
reg         wmb_rd_received;
reg  [511:0] cvif_dat_buf;
reg  [511:0] cvif_wt_buf;
reg  [511:0] cvif_wmb_buf;

// Output mux control
reg  [1:0]  output_selector;  // Which input to pass through

// CBUF output
reg         sc2buf_dat_rd_en_o;
reg  [11:0] sc2buf_dat_rd_addr_o;
reg         sc2buf_dat_rd_valid_o;
reg  [511:0] sc2buf_dat_rd_data_o;

reg         sc2buf_wt_rd_en_o;
reg  [11:0] sc2buf_wt_rd_addr_o;
reg         sc2buf_wt_rd_valid_o;
reg  [511:0] sc2buf_wt_rd_data_o;

reg         sc2buf_wmb_rd_en_o;
reg  [11:0] sc2buf_wmb_rd_addr_o;
reg         sc2buf_wmb_rd_valid_o;
reg  [511:0] sc2buf_wmb_rd_data_o;

//==========================================
// Credit management
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    credit_count[7:0] <= 8'd0;
  end else begin
    // Consume credit on request
    if (sc2cvif_dat_rd_req || sc2cvif_wt_rd_req || sc2cvif_wmb_rd_req) begin
      credit_count[7:0] <= credit_count[7:0] - 8'd1;
    end

    // Replenish credit on response
    if (cvif2sc_dat_rd_valid || cvif2sc_wt_rd_valid || cvif2sc_wmb_rd_valid) begin
      credit_count[7:0] <= credit_count[7:0] + 8'd1;
    end

    // Initialize
    if (credit_count[7:0] == 8'd0)
      credit_count[7:0] <= sc2cvif_rd_cdt[7:0];
  end
end

//==========================================
// Request generation
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    sc2cvif_dat_rd_req <= 1'b0;
    sc2cvif_wt_rd_req <= 1'b0;
    sc2cvif_wmb_rd_req <= 1'b0;
    sc2cvif_dat_rd_adq[5:0] <= 6'd0;
    sc2cvif_wt_rd_adq[5:0] <= 6'd0;
    sc2cvif_wmb_rd_adq[5:0] <= 6'd0;
  end else begin
    // Request data when CSC needs it
    if (sc2buf_dat_rd_en_i && credit_count[7:0] > 8'd0) begin
      sc2cvif_dat_rd_req <= 1'b1;
      sc2cvif_dat_rd_adq[5:0] <= 6'd0;  // ADQ is per-channel
    end else begin
      sc2cvif_dat_rd_req <= 1'b0;
    end

    // Request weight when CSC needs it
    if (sc2buf_wt_rd_en_i && credit_count[7:0] > 8'd0) begin
      sc2cvif_wt_rd_req <= 1'b1;
      sc2cvif_wt_rd_adq[5:0] <= 6'd0;
    end else begin
      sc2cvif_wt_rd_req <= 1'b0;
    end

    // Request WMB when CSC needs it
    if (sc2buf_wmb_rd_en_i && credit_count[7:0] > 8'd0) begin
      sc2cvif_wmb_rd_req <= 1'b1;
      sc2cvif_wmb_rd_adq[5:0] <= 6'd0;
    end else begin
      sc2cvif_wmb_rd_req <= 1'b0;
    end
  end
end

//==========================================
// Response handling with arbitration
//==========================================
// Round-robin arbitration for responses
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    current_owner[1:0] <= PRIORITY_HIGH;
  end else begin
    if (cvif2sc_dat_rd_valid || cvif2sc_wt_rd_valid || cvif2sc_wmb_rd_valid) begin
      // Rotate owner on each beat
      case (current_owner[1:0])
        REQ_ID_DAT: current_owner[1:0] <= REQ_ID_WT;
        REQ_ID_WT:  current_owner[1:0] <= REQ_ID_WMB;
        REQ_ID_WMB: current_owner[1:0] <= REQ_ID_DAT;
        default:    current_owner[1:0] <= PRIORITY_HIGH;
      endcase
    end
  end
end

// Response pipeline
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dat_rd_received <= 1'b0;
    wt_rd_received <= 1'b0;
    wmb_rd_received <= 1'b0;
    cvif_dat_buf[511:0] <= {512{1'b0}};
    cvif_wt_buf[511:0] <= {512{1'b0}};
    cvif_wmb_buf[511:0] <= {512{1'b0}};
  end else begin
    // Capture CVIF responses
    if (cvif2sc_dat_rd_valid) begin
      dat_rd_received <= 1'b1;
      cvif_dat_buf[511:0] <= cvif2sc_dat_rd_data[511:0];
    end else if (sc2buf_dat_rd_valid_o) begin
      dat_rd_received <= 1'b0;
    end

    if (cvif2sc_wt_rd_valid) begin
      wt_rd_received <= 1'b1;
      cvif_wt_buf[511:0] <= cvif2sc_wt_rd_data[511:0];
    end else if (sc2buf_wt_rd_valid_o) begin
      wt_rd_received <= 1'b0;
    end

    if (cvif2sc_wmb_rd_valid) begin
      wmb_rd_received <= 1'b1;
      cvif_wmb_buf[511:0] <= cvif2sc_wmb_rd_data[511:0];
    end else if (sc2buf_wmb_rd_valid_o) begin
      wmb_rd_received <= 1'b0;
    end
  end
end

//==========================================
// Output multiplexing
//==========================================
always @(*) begin
  // Default: pass through direct connection
  sc2buf_dat_rd_en_o = sc2buf_dat_rd_en_i;
  sc2buf_dat_rd_addr_o[11:0] = sc2buf_dat_rd_addr_i[11:0];
  sc2buf_dat_rd_valid_o = sc2buf_dat_rd_valid_i;
  sc2buf_dat_rd_data_o[511:0] = sc2buf_dat_rd_data_i[511:0];

  sc2buf_wt_rd_en_o = sc2buf_wt_rd_en_i;
  sc2buf_wt_rd_addr_o[11:0] = sc2buf_wt_rd_addr_i[11:0];
  sc2buf_wt_rd_valid_o = sc2buf_wt_rd_valid_i;
  sc2buf_wt_rd_data_o[511:0] = sc2buf_wt_rd_data_i[511:0];

  sc2buf_wmb_rd_en_o = sc2buf_wmb_rd_en_i;
  sc2buf_wmb_rd_addr_o[11:0] = sc2buf_wmb_rd_addr_i[11:0];
  sc2buf_wmb_rd_valid_o = sc2buf_wmb_rd_valid_i;
  sc2buf_wmb_rd_data_o[511:0] = sc2buf_wmb_rd_data_i[511:0];
end

// Note: In a full implementation, there would be a real memory arbiter here
// that handles conflicts between CSC and other masters (CDMA, CACC, CDP, etc.)
// For this re-implementation, we use direct pass-through as the existing RTL does

endmodule // NV_NVDLA_CSC_mcif_cvif_new