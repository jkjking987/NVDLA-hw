// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_BDMA_mcif_cvif_new.v
// Author        : Wolley Hardware Team
// Author Email  : hwteam@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// BDMA MCIF/CVIF Router - routes between BDMA internal engines and
// external memory interfaces (MCIF and CVIF).
//
// Interface Selection:
// - RAM type 0 -> CVIF (Co-processor/Virtual Interface)
// - RAM type 1 -> MCIF (Main memory Interface)
//
// Request Channels: Valid/Ready handshake with packet data
// Response Channels: Valid/Ready handshake with packet data
// - +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_mcif_cvif_new (
    nvdla_core_clk
  , nvdla_core_rstn

  // MCIF Read Interface
  , mcif2bdma_rd_rsp_valid      //|< i
  , mcif2bdma_rd_rsp_ready      //|> o
  , mcif2bdma_rd_rsp_pd         //|< i
  , bdma2mcif_rd_req_valid      //|> o
  , bdma2mcif_rd_req_ready      //|< i
  , bdma2mcif_rd_req_pd         //|> o

  // MCIF Write Interface
  , mcif2bdma_wr_rsp_complete   //|< i
  , bdma2mcif_wr_req_valid      //|> o
  , bdma2mcif_wr_req_ready      //|< i
  , bdma2mcif_wr_req_pd         //|> o

  // CVIF Read Interface
  , cvif2bdma_rd_rsp_valid      //|< i
  , cvif2bdma_rd_rsp_ready      //|> o
  , cvif2bdma_rd_rsp_pd         //|< i
  , bdma2cvif_rd_req_valid      //|> o
  , bdma2cvif_rd_req_ready      //|< i
  , bdma2cvif_rd_req_pd         //|> o

  // CVIF Write Interface
  , cvif2bdma_wr_rsp_complete   //|< i
  , bdma2cvif_wr_req_valid      //|> o
  , bdma2cvif_wr_req_ready      //|< i
  , bdma2cvif_wr_req_pd         //|> o

  // Credit/latency FIFO control
  , bdma2mcif_rd_cdt_lat_fifo_pop  //|> o
  , bdma2cvif_rd_cdt_lat_fifo_pop  //|> o
);

// +FHDR------------------------------------------------------------
// Parameter definitions
// +FHDR------------------------------------------------------------

// +FHDR------------------------------------------------------------
// Port declarations
// +FHDR------------------------------------------------------------
input         nvdla_core_clk;
input         nvdla_core_rstn;

// MCIF Read Interface
input         mcif2bdma_rd_rsp_valid;
output        mcif2bdma_rd_rsp_ready;
input  [513:0] mcif2bdma_rd_rsp_pd;

output        bdma2mcif_rd_req_valid;
input         bdma2mcif_rd_req_ready;
output [78:0] bdma2mcif_rd_req_pd;

// MCIF Write Interface
input         mcif2bdma_wr_rsp_complete;

output        bdma2mcif_wr_req_valid;
input         bdma2mcif_wr_req_ready;
output [514:0] bdma2mcif_wr_req_pd;

// CVIF Read Interface
input         cvif2bdma_rd_rsp_valid;
output        cvif2bdma_rd_rsp_ready;
input  [513:0] cvif2bdma_rd_rsp_pd;

output        bdma2cvif_rd_req_valid;
input         bdma2cvif_rd_req_ready;
output [78:0] bdma2cvif_rd_req_pd;

// CVIF Write Interface
input         cvif2bdma_wr_rsp_complete;

output        bdma2cvif_wr_req_valid;
input         bdma2cvif_wr_req_ready;
output [514:0] bdma2cvif_wr_req_pd;

// Credit/latency FIFO control
output        bdma2mcif_rd_cdt_lat_fifo_pop;
output        bdma2cvif_rd_cdt_lat_fifo_pop;

// +FHDR------------------------------------------------------------
// Wire declarations
// +FHDR------------------------------------------------------------

// MCIF read request passthrough
wire          mcif_rd_req_in_valid;
wire          mcif_rd_req_in_ready;
wire  [78:0]  mcif_rd_req_in_pd;

// CVIF read request passthrough
wire          cvif_rd_req_in_valid;
wire          cvif_rd_req_in_ready;
wire  [78:0]  cvif_rd_req_in_pd;

// MCIF write request passthrough
wire          mcif_wr_req_in_valid;
wire          mcif_wr_req_in_ready;
wire  [514:0] mcif_wr_req_in_pd;

// CVIF write request passthrough
wire          cvif_wr_req_in_valid;
wire          cvif_wr_req_in_ready;
wire  [514:0] cvif_wr_req_in_pd;

// Read response routing
wire          mcif_rd_rsp_in_valid;
wire          mcif_rd_rsp_in_ready;
wire [513:0]  mcif_rd_rsp_in_pd;

wire          cvif_rd_rsp_in_valid;
wire          cvif_rd_rsp_in_ready;
wire [513:0]  cvif_rd_rsp_in_pd;

// Internal credit tracking
reg           mcif_rd_cdt_lat_fifo_pop_q;
reg           cvif_rd_cdt_lat_fifo_pop_q;

// +FHDR------------------------------------------------------------
// Reg declarations
// +FHDR------------------------------------------------------------

// +FHDR------------------------------------------------------------
// MCIF Read Request Passthrough
// +FHDR------------------------------------------------------------
assign mcif_rd_req_in_valid = bdma2mcif_rd_req_valid;
assign bdma2mcif_rd_req_ready = mcif_rd_req_in_ready;
assign mcif_rd_req_in_pd[78:0] = bdma2mcif_rd_req_pd[78:0];

// +FHDR------------------------------------------------------------
// CVIF Read Request Passthrough
// +FHDR------------------------------------------------------------
assign cvif_rd_req_in_valid = bdma2cvif_rd_req_valid;
assign bdma2cvif_rd_req_ready = cvif_rd_req_in_ready;
assign cvif_rd_req_in_pd[78:0] = bdma2cvif_rd_req_pd[78:0];

// +FHDR------------------------------------------------------------
// MCIF Write Request Passthrough
// +FHDR------------------------------------------------------------
assign mcif_wr_req_in_valid = bdma2mcif_wr_req_valid;
assign bdma2mcif_wr_req_ready = mcif_wr_req_in_ready;
assign mcif_wr_req_in_pd[514:0] = bdma2mcif_wr_req_pd[514:0];

// +FHDR------------------------------------------------------------
// CVIF Write Request Passthrough
// +FHDR------------------------------------------------------------
assign cvif_wr_req_in_valid = bdma2cvif_wr_req_valid;
assign bdma2cvif_wr_req_ready = cvif_wr_req_in_ready;
assign cvif_wr_req_in_pd[514:0] = bdma2cvif_wr_req_pd[514:0];

// +FHDR------------------------------------------------------------
// MCIF Read Response Passthrough
// +FHDR------------------------------------------------------------
assign mcif_rd_rsp_in_valid = mcif2bdma_rd_rsp_valid;
assign mcif2bdma_rd_rsp_ready = mcif_rd_rsp_in_ready;
assign mcif_rd_rsp_in_pd[513:0] = mcif2bdma_rd_rsp_pd[513:0];

// +FHDR------------------------------------------------------------
// CVIF Read Response Passthrough
// +FHDR------------------------------------------------------------
assign cvif_rd_rsp_in_valid = cvif2bdma_rd_rsp_valid;
assign cvif2bdma_rd_rsp_ready = cvif_rd_rsp_in_ready;
assign cvif_rd_rsp_in_pd[513:0] = cvif2bdma_rd_rsp_pd[513:0];

// +FHDR------------------------------------------------------------
// Credit/latency FIFO pop generation
// - Pop when read response is consumed
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mcif_rd_cdt_lat_fifo_pop_q <= 1'b0;
    cvif_rd_cdt_lat_fifo_pop_q <= 1'b0;
  end else begin
    mcif_rd_cdt_lat_fifo_pop_q <= mcif_rd_rsp_in_valid & mcif_rd_rsp_in_ready;
    cvif_rd_cdt_lat_fifo_pop_q <= cvif_rd_rsp_in_valid & cvif_rd_rsp_in_ready;
  end
end

assign bdma2mcif_rd_cdt_lat_fifo_pop = mcif_rd_cdt_lat_fifo_pop_q;
assign bdma2cvif_rd_cdt_lat_fifo_pop = cvif_rd_cdt_lat_fifo_pop_q;

// +FHDR------------------------------------------------------------
// Internal ready signal assignment
// +FHDR------------------------------------------------------------
assign mcif_rd_req_in_ready = bdma2mcif_rd_req_ready;
assign cvif_rd_req_in_ready = bdma2cvif_rd_req_ready;
assign mcif_wr_req_in_ready = bdma2mcif_wr_req_ready;
assign cvif_wr_req_in_ready = bdma2cvif_wr_req_ready;
assign mcif_rd_rsp_in_ready = mcif2bdma_rd_rsp_ready;
assign cvif_rd_rsp_in_ready = cvif2bdma_rd_rsp_ready;

endmodule // NV_NVDLA_BDMA_mcif_cvif_new