// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_csb_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP CSB (Command Status Bus) Interface Module
// - CSB request b_transport implementation with pvld/prdy handshake
// - Register address decoding for all CDP registers
// - Register write/read handling
// - Response generation for reads and non-posted writes
//
// CSB Protocol:
//   Request payload (63-bit): {level[1:0], nposted, wrbe[3:0], srcpriv, write, wdat[31:0], addr[21:0]}
//   Response payload (33-bit): {error, data[31:0]} for both read and write
//   Read: rsp_type=0, Write: rsp_type=1
//   Posted writes do not generate a response
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_csb_new (
   nvdla_core_clk                   //|< i
  ,nvdla_core_rstn                 //|< i
  // CSB request interface
  ,csb2cdp_req_pvld               //|< i  // request valid
  ,csb2cdp_req_prdy               //|> o  // request ready
  ,csb2cdp_req_pd                 //|< i  // request payload [62:0]
  // CSB response interface
  ,cdp2csb_resp_valid             //|> o  // response valid
  ,cdp2csb_resp_pd                //|> o  // response payload [33:0]
  // Register file interface
  ,reg2dp_op_en                   //|> o
  ,reg2dp_op_en_trigger           //|> o
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB request interface
input         csb2cdp_req_pvld;   // request valid
output        csb2cdp_req_prdy;   // request ready
input  [62:0] csb2cdp_req_pd;    // request payload

// CSB response interface
output        cdp2csb_resp_valid; // response valid
output [33:0] cdp2csb_resp_pd;    // response payload

// Register file outputs
output        reg2dp_op_en;
output        reg2dp_op_en_trigger;

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// CSB request fields (extracted from 63-bit payload)
// req_pd[62:61] = level (NC)
// req_pd[60:57] = wrbe (NC)
// req_pd[56]    = srcpriv (NC)
// req_pd[55]    = nposted
// req_pd[54]    = write
// req_pd[53:22] = wdat
// req_pd[21:0]  = addr
wire   [1:0]  req_level_nc;
wire          req_nposted;
wire   [3:0]  req_wrbe_nc;
wire          req_srcpriv_nc;
wire          req_write;
wire  [31:0]  req_wdat;
wire  [21:0]  req_addr;

// Register interface
wire   [11:0] reg_offset;
wire          reg_wr_en;
wire          reg_rd_en;
wire  [31:0]  reg_wr_data;
wire  [31:0]  reg_rd_data;

// CSB response generation
wire          rsp_rd_vld;
wire          rsp_wr_vld;
wire          rsp_vld;
wire  [32:0]  rsp_rd_pd;
wire  [32:0]  rsp_wr_pd;
wire  [33:0]  rsp_pd;
wire          rsp_rd_error;
wire          rsp_wr_error;
wire  [31:0]  rsp_rd_rdat;
wire  [31:0]  rsp_wr_rdat;

// Register model outputs
wire  [31:0]  nvdla_cdp_cfg_op_en;
wire  [31:0]  nvdla_cdp_status_0;
wire  [31:0]  nvdla_cdp_status_1;
wire  [31:0]  nvdla_cdp_pointer;
wire  [31:0]  nvdla_cdp_reg2dp_lut_access_cfg;
wire  [31:0]  nvdla_cdp_reg2dp_lut_access_data;
wire  [31:0]  nvdla_cdp_reg2dp_lut_cfg;
wire  [31:0]  nvdla_cdp_reg2dp_lut_info;
wire  [31:0]  nvdla_cdp_reg2dp_lut_le_start_low;
wire  [31:0]  nvdla_cdp_reg2dp_lut_le_start_high;
wire  [31:0]  nvdla_cdp_reg2dp_lut_le_end_low;
wire  [31:0]  nvdla_cdp_reg2dp_lut_le_end_high;
wire  [31:0]  nvdla_cdp_reg2dp_lut_lo_start_low;
wire  [31:0]  nvdla_cdp_reg2dp_lut_lo_start_high;
wire  [31:0]  nvdla_cdp_reg2dp_lut_lo_end_low;
wire  [31:0]  nvdla_cdp_reg2dp_lut_lo_end_high;
wire  [31:0]  nvdla_cdp_reg2dp_lut_le_slope_scale;
wire  [31:0]  nvdla_cdp_reg2dp_lut_le_slope_shift;
wire  [31:0]  nvdla_cdp_reg2dp_lut_lo_slope_scale;
wire  [31:0]  nvdla_cdp_reg2dp_lut_lo_slope_shift;

//===============================================================
// REQ INTERFACE - b_transport style with pvld/prdy handshake
//===============================================================
// req_vld: register the incoming valid signal
reg    req_vld;
reg   [62:0] req_pd;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_vld <= 1'b0;
  end else begin
    req_vld <= csb2cdp_req_pvld;
  end
end

// req_pd: capture the full request payload when valid
always @(posedge nvdla_core_clk) begin
  if (csb2cdp_req_pvld == 1'b1) begin
    req_pd <= csb2cdp_req_pd;
  end else if (csb2cdp_req_pvld == 1'b0) begin
    // hold value
  end else begin
    req_pd <= 'bx;  // spyglass disable STARC-2.10.1.6 W443
  end
end

// Ready whenever we are not busy processing a request
assign csb2cdp_req_prdy = 1'b1;

//===============================================================
// REQUEST - Extract fields from 63-bit CSB request payload
//===============================================================
// req_pd[62:61] = level (not connected)
assign req_level_nc   = req_pd[62:61];
// req_pd[60:57] = write byte enable (not connected for now)
assign req_wrbe_nc    = req_pd[60:57];
// req_pd[56] = srcpriv (not connected)
assign req_srcpriv_nc = req_pd[56];
// req_pd[55] = nposted (1=non-posted, 0=posted)
assign req_nposted    = req_pd[55];
// req_pd[54] = write (1=write, 0=read)
assign req_write      = req_pd[54];
// req_pd[53:22] = write data
assign req_wdat       = req_pd[53:22];
// req_pd[21:0] = register address (lower 22 bits of 32-bit address)
assign req_addr       = req_pd[21:0];

// Register address: {addr[9:0], 2'b00} -> 12-bit aligned offset
assign reg_offset     = {req_addr[9:0], 2'b00};
assign reg_wr_en      = req_vld & req_write;
assign reg_rd_en      = req_vld & ~req_write;
assign reg_wr_data    = req_wdat;

//===============================================================
// REGISTER FILE MODULE INSTANCE
//===============================================================
NV_NVDLA_CDP_reg_new u_reg (
   .csb_clk                          (nvdla_core_clk)                        //|< i
  ,.csb_rstn                         (nvdla_core_rstn)                       //|< i
  ,.csb_addr                         (reg_offset[11:0])                      //|< w
  ,.csb_wdat                         (reg_wr_data[31:0])                     //|< w
  ,.csb_rd_en                        (reg_rd_en)                             //|< w
  ,.csb_wr_en                        (reg_wr_en)                             //|< w
  ,.csb_rdat                         (reg_rd_data[31:0])                     //|> w
  ,.reg2dp_op_en                     (reg2dp_op_en)                          //|> o
  ,.reg2dp_op_en_trigger             (reg2dp_op_en_trigger)                  //|> o
  ,.nvdla_cdp_cfg_op_en              (nvdla_cdp_cfg_op_en)                   //|< w
  ,.nvdla_cdp_status_0               (nvdla_cdp_status_0)                     //|< w
  ,.nvdla_cdp_status_1               (nvdla_cdp_status_1)                    //|< w
  ,.nvdla_cdp_pointer                (nvdla_cdp_pointer)                    //|< w
  ,.nvdla_cdp_reg2dp_lut_access_cfg  (nvdla_cdp_reg2dp_lut_access_cfg)      //|< w
  ,.nvdla_cdp_reg2dp_lut_access_data (nvdla_cdp_reg2dp_lut_access_data)     //|< w
  ,.nvdla_cdp_reg2dp_lut_cfg         (nvdla_cdp_reg2dp_lut_cfg)             //|< w
  ,.nvdla_cdp_reg2dp_lut_info        (nvdla_cdp_reg2dp_lut_info)             //|< w
  ,.nvdla_cdp_reg2dp_lut_le_start_low  (nvdla_cdp_reg2dp_lut_le_start_low)  //|< w
  ,.nvdla_cdp_reg2dp_lut_le_start_high (nvdla_cdp_reg2dp_lut_le_start_high) //|< w
  ,.nvdla_cdp_reg2dp_lut_le_end_low    (nvdla_cdp_reg2dp_lut_le_end_low)    //|< w
  ,.nvdla_cdp_reg2dp_lut_le_end_high   (nvdla_cdp_reg2dp_lut_le_end_high)   //|< w
  ,.nvdla_cdp_reg2dp_lut_lo_start_low  (nvdla_cdp_reg2dp_lut_lo_start_low)  //|< w
  ,.nvdla_cdp_reg2dp_lut_lo_start_high (nvdla_cdp_reg2dp_lut_lo_start_high) //|< w
  ,.nvdla_cdp_reg2dp_lut_lo_end_low    (nvdla_cdp_reg2dp_lut_lo_end_low)    //|< w
  ,.nvdla_cdp_reg2dp_lut_lo_end_high   (nvdla_cdp_reg2dp_lut_lo_end_high)   //|< w
  ,.nvdla_cdp_reg2dp_lut_le_slope_scale (nvdla_cdp_reg2dp_lut_le_slope_scale) //|< w
  ,.nvdla_cdp_reg2dp_lut_le_slope_shift  (nvdla_cdp_reg2dp_lut_le_slope_shift) //|< w
  ,.nvdla_cdp_reg2dp_lut_lo_slope_scale (nvdla_cdp_reg2dp_lut_lo_slope_scale) //|< w
  ,.nvdla_cdp_reg2dp_lut_lo_slope_shift  (nvdla_cdp_reg2dp_lut_lo_slope_shift) //|< w
  );

//===============================================================
// RESPONSE - Generate read and write responses
//===============================================================
// Read response packet: {error, rdat}
// Write response packet: {error, 32'd0}
assign rsp_rd_pd[32]   = rsp_rd_error;
assign rsp_rd_pd[31:0] = rsp_rd_rdat;

assign rsp_wr_pd[32]   = rsp_wr_error;
assign rsp_wr_pd[31:0] = rsp_wr_rdat;

// Read valid: request is valid AND it is a read operation
assign rsp_rd_vld  = req_vld & ~req_write;
assign rsp_rd_rdat = {32{rsp_rd_vld}} & reg_rd_data;
assign rsp_rd_error = 1'b0;  // no read error in this implementation

// Write valid: request is valid AND it is a write AND is non-posted
// Posted writes (nposted=0) do NOT generate a response
assign rsp_wr_vld  = req_vld & req_write & req_nposted;
assign rsp_wr_rdat = {32{1'b0}};
assign rsp_wr_error = 1'b0;  // no write error in this implementation

// Combined response valid and payload
assign rsp_vld = rsp_rd_vld | rsp_wr_vld;

// Response payload: {rsp_type, error, data}
// rsp_type: 0 for read, 1 for write
assign rsp_pd[33]   = ({1{rsp_rd_vld}} & 1'h0)
                     | ({1{rsp_wr_vld}} & 1'h1);

assign rsp_pd[32:0] = ({33{rsp_rd_vld}} & rsp_rd_pd)
                    | ({33{rsp_wr_vld}} & rsp_wr_pd);

//===============================================================
// RESPONSE REGISTERS - Register the response outputs
//===============================================================
reg    cdp2csb_resp_valid_reg;
reg   [33:0] cdp2csb_resp_pd_reg;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cdp2csb_resp_valid_reg <= 1'b0;
  end else begin
    cdp2csb_resp_valid_reg <= rsp_vld;
  end
end

always @(posedge nvdla_core_clk) begin
  if (rsp_vld == 1'b1) begin
    cdp2csb_resp_pd_reg <= rsp_pd;
  end else if (rsp_vld == 1'b0) begin
    // hold value
  end else begin
    cdp2csb_resp_pd_reg <= 'bx;  // spyglass disable STARC-2.10.1.6 W443
  end
end

assign cdp2csb_resp_valid = cdp2csb_resp_valid_reg;
assign cdp2csb_resp_pd    = cdp2csb_resp_pd_reg;

//===============================================================
// REGISTER MODEL INSTANCE
//===============================================================
// CDP Register Model - handles register access and storage
NV_NVDLA_CDP_reg_model_new u_reg_model (
   .nvdla_core_clk                        (nvdla_core_clk)                          //|< i
  ,.nvdla_core_rstn                       (nvdla_core_rstn)                         //|< i
  ,.csb_addr                             (reg_offset[11:0])                        //|< w
  ,.csb_wdat                             (reg_wr_data[31:0])                       //|< w
  ,.csb_rd_en                            (reg_rd_en)                               //|< w
  ,.csb_wr_en                            (reg_wr_en)                               //|< w
  ,.csb_rdat                             (reg_rd_data[31:0])                       //|> w
  ,.nvdla_cdp_cfg_op_en                  (nvdla_cdp_cfg_op_en)                     //|> w
  ,.nvdla_cdp_status_0                   (nvdla_cdp_status_0)                      //|> w
  ,.nvdla_cdp_status_1                   (nvdla_cdp_status_1)                      //|> w
  ,.nvdla_cdp_pointer                    (nvdla_cdp_pointer)                       //|> w
  ,.nvdla_cdp_reg2dp_lut_access_cfg      (nvdla_cdp_reg2dp_lut_access_cfg)        //|> w
  ,.nvdla_cdp_reg2dp_lut_access_data     (nvdla_cdp_reg2dp_lut_access_data)       //|> w
  ,.nvdla_cdp_reg2dp_lut_cfg             (nvdla_cdp_reg2dp_lut_cfg)                //|> w
  ,.nvdla_cdp_reg2dp_lut_info            (nvdla_cdp_reg2dp_lut_info)               //|> w
  ,.nvdla_cdp_reg2dp_lut_le_start_low    (nvdla_cdp_reg2dp_lut_le_start_low)     //|> w
  ,.nvdla_cdp_reg2dp_lut_le_start_high   (nvdla_cdp_reg2dp_lut_le_start_high)    //|> w
  ,.nvdla_cdp_reg2dp_lut_le_end_low      (nvdla_cdp_reg2dp_lut_le_end_low)       //|> w
  ,.nvdla_cdp_reg2dp_lut_le_end_high     (nvdla_cdp_reg2dp_lut_le_end_high)      //|> w
  ,.nvdla_cdp_reg2dp_lut_lo_start_low    (nvdla_cdp_reg2dp_lut_lo_start_low)     //|> w
  ,.nvdla_cdp_reg2dp_lut_lo_start_high   (nvdla_cdp_reg2dp_lut_lo_start_high)    //|> w
  ,.nvdla_cdp_reg2dp_lut_lo_end_low      (nvdla_cdp_reg2dp_lut_lo_end_low)       //|> w
  ,.nvdla_cdp_reg2dp_lut_lo_end_high     (nvdla_cdp_reg2dp_lut_lo_end_high)       //|> w
  ,.nvdla_cdp_reg2dp_lut_le_slope_scale  (nvdla_cdp_reg2dp_lut_le_slope_scale)  //|> w
  ,.nvdla_cdp_reg2dp_lut_le_slope_shift   (nvdla_cdp_reg2dp_lut_le_slope_shift)  //|> w
  ,.nvdla_cdp_reg2dp_lut_lo_slope_scale  (nvdla_cdp_reg2dp_lut_lo_slope_scale)  //|> w
  ,.nvdla_cdp_reg2dp_lut_lo_slope_shift   (nvdla_cdp_reg2dp_lut_lo_slope_shift)  //|> w
  );

endmodule // NV_NVDLA_CDP_csb_new