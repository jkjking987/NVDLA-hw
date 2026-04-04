// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_csb_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSB (Configuration Bus) interface for CSC module
// Handles register read/write requests from CSB master
// - Decodes address and writes to appropriate register group
// - Returns read data on CSB response port
// - Supports dual register groups for ping-pong operation
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_csb_new (
   nvdla_core_clk             //|< i
  ,nvdla_core_rstn            //|< i
  ,csb2csc_req_pvld          //|< i
  ,csb2csc_req_prdy          //|> o
  ,csb2csc_req_pd            //|< i  [62:0]
  ,csc2csb_resp_valid        //|> o
  ,csc2csb_resp_pd           //|> o  [33:0]
  ,reg_wr_en                  //|> o
  ,reg_rd_en                  //|> o
  ,reg_wr_data                //|> o  [31:0]
  ,reg_offset                 //|> o  [11:0]
  ,reg2dp_producer            //|< i
  ,reg2dp_d0_op_en            //|< i
  ,reg2dp_d1_op_en            //|< i
  );

//==========================================
// Parameters
//==========================================
parameter [31:0] CSC_REG_BASE_ADDR = 32'h6000;

//==========================================
// Ports
//==========================================
input  [62:0] csb2csc_req_pd;
input         csb2csc_req_pvld;
input         nvdla_core_clk;
input         nvdla_core_rstn;
input         reg2dp_producer;
input         reg2dp_d0_op_en;
input         reg2dp_d1_op_en;

output [33:0] csc2csb_resp_pd;
output        csc2csb_resp_valid;
output        csb2csc_req_prdy;
output        reg_wr_en;
output        reg_rd_en;
output [31:0] reg_wr_data;
output [11:0] reg_offset;

//==========================================
// Internal signals
//==========================================
reg  [62:0] req_pd_q;
reg         req_pvld_q;
reg  [21:0] req_addr;
reg  [31:0] req_wdat;
reg         req_write;
reg         req_nposted;
reg  [3:0]  req_wrbe;
reg  [33:0] csc2csb_resp_pd;
reg         csc2csb_resp_valid;

wire        reg_wr_en;
wire        reg_rd_en;
wire [31:0] reg_wr_data;
wire [11:0] reg_offset;
wire [31:0] reg_rd_data;
wire        select_s;
wire        select_d0;
wire        select_d1;
wire        csb_rresp_error;
wire        csb_wresp_error;
wire [31:0] csb_rresp_rdat;
wire [33:0] csb_rresp_pd_w;
wire [33:0] csb_wresp_pd_w;

//==========================================
// Request data capture (CDC from CSB domain)
//==========================================
// 2-FF synchronizer for request valid
reg cxs_req_pvld_sync1;
reg cxs_req_pvld_sync2;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cxs_req_pvld_sync1 <= 1'b0;
    cxs_req_pvld_sync2 <= 1'b0;
  end else begin
    cxs_req_pvld_sync1 <= csb2csc_req_pvld;
    cxs_req_pvld_sync2 <= cxs_req_pvld_sync1;
  end
end

// Request payload capture
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_pd_q <= {63{1'b0}};
  end else if (cxs_req_pvld_sync2) begin
    req_pd_q <= csb2csc_req_pd;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_pvld_q <= 1'b0;
  end else begin
    req_pvld_q <= cxs_req_pvld_sync2;
  end
end

//==========================================
// Request decode
//==========================================
// PKT_UNPACK_WIRE( csb2xx_16m_be_lvl , req_ , req_pd )
assign req_addr[21:0]  = req_pd_q[21:0];
assign req_wdat[31:0]  = req_pd_q[53:22];
assign req_write       = req_pd_q[54];
assign req_nposted     = req_pd_q[55];
assign req_wrbe[3:0]   = req_pd_q[60:57];

// Address is word-aligned in CSB master, byte-aligned in regfile
assign reg_offset[11:0] = {req_addr[9:0], 2'b0};
assign reg_wr_data[31:0] = req_wdat[31:0];

assign reg_wr_en = req_pvld_q & req_write;
assign reg_rd_en = req_pvld_q & ~req_write;

//==========================================
// Register group selection
//==========================================
// Each subunit has 4KB address space
// Single regs: 0x6000 - 0x6007
// Dual regs:   0x6008 - 0x606F
assign select_s  = (reg_offset[11:0] < 12'h008);
assign select_d0 = (reg_offset[11:0] >= 12'h008) & (reg2dp_producer == 1'b0);
assign select_d1 = (reg_offset[11:0] >= 12'h008) & (reg2dp_producer == 1'b1);

//==========================================
// Response generation
//==========================================
// Read response packing
// PKT_PACK_WIRE_ID( nvdla_xx2csb_resp , dla_xx2csb_rd_erpt , csb_rresp_ , csb_rresp_pd_w )
assign csb_rresp_pd_w[31:0] = reg_rd_data[31:0];
assign csb_rresp_pd_w[32]   = csb_rresp_error;
assign csb_rresp_pd_w[33]    = 1'b0;  // PKT_nvdla_xx2csb_resp_dla_xx2csb_rd_erpt_ID

// Write response packing
// PKT_PACK_WIRE_ID( nvdla_xx2csb_resp , dla_xx2csb_wr_erpt , csb_wresp_ , csb_wresp_pd_w )
assign csb_wresp_pd_w[31:0] = {32{1'b0}};
assign csb_wresp_pd_w[32]   = csb_wresp_error;
assign csb_wresp_pd_w[33]   = 1'b1;  // PKT_nvdla_xx2csb_resp_dla_xx2csb_wr_erpt_ID

assign csb_rresp_error = 1'b0;
assign csb_wresp_error = 1'b0;

// Read data from correct register group based on selection
assign reg_rd_data = ({32{select_s}}  & 32'h0) |  // Single regs
                     ({32{select_d0}} & 32'h0) |  // D0 regs - handled externally
                     ({32{select_d1}} & 32'h0);  // D1 regs - handled externally

// Response valid generation
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    csc2csb_resp_valid <= 1'b0;
  end else begin
    csc2csb_resp_valid <= (reg_wr_en & req_nposted) | reg_rd_en;
  end
end

// Response data generation
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    csc2csb_resp_pd <= {34{1'b0}};
  end else begin
    if (reg_rd_en) begin
      csc2csb_resp_pd <= csb_rresp_pd_w;
    end else if (reg_wr_en & req_nposted) begin
      csc2csb_resp_pd <= csb_wresp_pd_w;
    end
  end
end

//==========================================
// Ready signal generation
//==========================================
assign csb2csc_req_prdy = 1'b1;  // Always ready to accept requests

endmodule // NV_NVDLA_CSC_csb_new