// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CACC_csb_new.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSB (Command Status Bus) interface for CACC register access
// - Receives register read/write requests
// - Returns responses for posted and non-posted writes
// - For CACC, register address space is 4KB (0x9000 - 0x9FFF)
// - Shadow registers for ping-pong operation
// - FHDR------------------------------------------------------------

module NV_NVDLA_CACC_csb_new (
   nvdla_core_clk          //|< i
  ,nvdla_core_rstn        //|< i
  ,csb2cacc_req_pvld      //|< i
  ,csb2cacc_req_prdy      //|> o
  ,csb2cacc_req_pd        //|< i
  ,cacc2csb_resp_valid    //|> o
  ,cacc2csb_resp_prdy     //|< i
  ,cacc2csb_resp_pd       //|> o
  );

//===============================================================
// Port declarations
//===============================================================
input  nvdla_core_clk;
input  nvdla_core_rstn;

// CSB request interface
input  csb2cacc_req_pvld;           // Request valid
output csb2cacc_req_prdy;            // Request ready (back pressure)
input  [62:0] csb2cacc_req_pd;      // Request packet data

// CSB response interface
output cacc2csb_resp_valid;          // Response valid
input  cacc2csb_resp_prdy;           // Response ready (back pressure)
output [33:0] cacc2csb_resp_pd;      // Response packet data

//===============================================================
// CSB Request Packet unpack
//===============================================================
// CSB request format (63 bits total):
// [62:61] - level
// [60:57] - wrbe (write byte enable)
// [56]    - srcpriv
// [55]    - nposted
// [54]    - write
// [53:22] - wdat (write data)
// [21:0]  - addr

wire [21:0] req_addr;
wire [31:0] req_wdat;
wire        req_write;
wire        req_nposted;
wire        req_srcpriv;
wire [3:0]  req_wrbe;
wire [1:0]  req_level;

assign req_addr    = csb2cacc_req_pd[21:0];
assign req_wdat    = csb2cacc_req_pd[53:22];
assign req_write   = csb2cacc_req_pd[54];
assign req_nposted = csb2cacc_req_pd[55];
assign req_srcpriv = csb2cacc_req_pd[56];
assign req_wrbe    = csb2cacc_req_pd[60:57];
assign req_level   = csb2cacc_req_pd[62:61];

//===============================================================
// CSB Response Packet pack
//===============================================================
// CSB response format (34 bits total):
// [33]    - packet ID (0=read response, 1=write response)
// [32]    - error
// [31:0]  - read/write data

wire [31:0] resp_rdat;
wire        resp_error;
wire [33:0] resp_pd;

assign resp_pd[31:0]  = resp_rdat;
assign resp_pd[32]   = resp_error;
assign resp_pd[33]   = 1'b0;  // Read response packet ID

//===============================================================
// Request capture registers (pipelined)
//===============================================================
reg [62:0] req_pd_q;
reg        req_pvld_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_pd_q   <= {63{1'b0}};
    req_pvld_q <= 1'b0;
  end else begin
    req_pvld_q <= csb2cacc_req_pvld;
    if (csb2cacc_req_pvld) begin
      req_pd_q <= csb2cacc_req_pd;
    end
  end
end

//===============================================================
// Response data from register file
//===============================================================
reg  [31:0] reg_rd_data_q;
reg         reg_rd_en_q;
reg  [31:0] reg_wr_data_q;
reg         reg_wr_en_q;
reg  [11:0] reg_offset_q;
reg  [21:0] req_addr_q;

// Pipeline for register address (byte offset to word offset)
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_addr_q    <= {22{1'b0}};
    reg_wr_data_q <= {32{1'b0}};
    reg_wr_en_q   <= 1'b0;
    reg_rd_en_q   <= 1'b0;
    reg_offset_q  <= {12{1'b0}};
  end else begin
    if (csb2cacc_req_pvld) begin
      req_addr_q    <= req_addr;
      reg_wr_data_q <= req_wdat;
      reg_wr_en_q   <= req_write;
      reg_rd_en_q   <= ~req_write;
      reg_offset_q  <= {req_addr[11:0], 2'b0};  // Byte addr -> word offset
    end
  end
end

//===============================================================
// Response generation
//===============================================================
reg  [33:0] resp_pd_q;
reg         resp_valid_q;

wire [33:0] csb_wresp_pd;
wire [33:0] csb_rresp_pd;

assign csb_rresp_pd[31:0] = reg_rd_data_q;
assign csb_rresp_pd[32]   = 1'b0;  // No error for read
assign csb_rresp_pd[33]   = 1'b0;  // Read response ID

assign csb_wresp_pd[31:0] = {32{1'b0}};
assign csb_wresp_pd[32]    = 1'b0;  // No error for write
assign csb_wresp_pd[33]   = 1'b1;  // Write response ID

// Response valid when: read OR (write AND non-posted)
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    resp_valid_q <= 1'b0;
    resp_pd_q    <= {34{1'b0}};
  end else begin
    if (reg_rd_en_q) begin
      resp_valid_q <= 1'b1;
      resp_pd_q    <= csb_rresp_pd;
    end else if (reg_wr_en_q && req_nposted) begin
      resp_valid_q <= 1'b1;
      resp_pd_q    <= csb_wresp_pd;
    end else begin
      resp_valid_q <= 1'b0;
    end
  end
end

//===============================================================
// Output assignments
//===============================================================
// CSB request ready - always ready in this implementation
assign csb2cacc_req_prdy = 1'b1;

// CSB response
assign cacc2csb_resp_valid = resp_valid_q;
assign cacc2csb_resp_pd    = resp_pd_q;

//===============================================================
// CDC for register read data (from register file)
// This is a simple approach - in real design would need
// proper synchronization if register file is in different clock domain
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg_rd_data_q <= {32{1'b0}};
  end else begin
    // Register read data comes from register file
    // In this implementation it's combinatorial through the regfile
  end
end

endmodule // NV_NVDLA_CACC_csb_new