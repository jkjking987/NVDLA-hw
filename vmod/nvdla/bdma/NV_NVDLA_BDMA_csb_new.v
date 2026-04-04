// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_BDMA_csb_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// BDMA CSB (Command Status Bus) Interface Module
// - CSB request b_transport implementation with pvld/prdy handshake
// - Register address decoding for all BDMA registers
// - Register write/read handling
// - Response generation for reads and non-posted writes
//
// CSB Protocol:
//   Request payload (63-bit): {level[1:0], nposted, wrbe[3:0], srcpriv, write, wdat[31:0], addr[21:0]}
//   Response payload (33-bit): {error, data[31:0]} for both read and write
//   Read: rsp_type=0, Write: rsp_type=1
//   Posted writes do not generate a response
// +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_csb_new (
   nvdla_core_clk              //|< i
  ,nvdla_core_rstn             //|< i
  // CSB request interface
  ,csb2bdma_req_pvld           //|< i  // request valid
  ,csb2bdma_req_prdy           //|> o  // request ready
  ,csb2bdma_req_pd             //|< i  // request payload [62:0]
  // CSB response interface
  ,bdma2csb_resp_valid         //|> o  // response valid
  ,bdma2csb_resp_pd            //|> o  // response payload [33:0]
  // Datapath outputs (to load/store blocks via reg file)
  ,reg2dp_src_addr_low_v32     //|> o
  ,reg2dp_src_addr_high_v8     //|> o
  ,reg2dp_dst_addr_low_v32     //|> o
  ,reg2dp_dst_addr_high_v8     //|> o
  ,reg2dp_line_size            //|> o
  ,reg2dp_cmd_src_ram_type     //|> o
  ,reg2dp_cmd_dst_ram_type     //|> o
  ,reg2dp_line_repeat_number   //|> o
  ,reg2dp_src_line_stride      //|> o
  ,reg2dp_dst_line_stride      //|> o
  ,reg2dp_surf_repeat_number   //|> o
  ,reg2dp_src_surf_stride      //|> o
  ,reg2dp_dst_surf_stride      //|> o
  ,reg2dp_op_en                //|> o
  ,reg2dp_launch0_grp0_launch //|> o
  ,reg2dp_launch1_grp1_launch //|> o
  ,reg2dp_status_stall_count_en //|> o
  ,reg2dp_op_en_trigger        //|> o
  ,reg2dp_launch0_trigger      //|> o
  ,reg2dp_launch1_trigger      //|> o
  // External status inputs (from load/store blocks)
  ,ext_status_idle             //|< i
  ,ext_status_grp0_busy        //|< i
  ,ext_status_grp1_busy        //|< i
  ,ext_free_slot               //|< i
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB request interface
input         csb2bdma_req_pvld;   // request valid
output        csb2bdma_req_prdy;   // request ready
input  [62:0] csb2bdma_req_pd;    // request payload

// CSB response interface
output        bdma2csb_resp_valid; // response valid
output [33:0] bdma2csb_resp_pd;    // response payload

// Datapath outputs (to load/store datapath)
output [26:0] reg2dp_src_addr_low_v32;
output [31:0] reg2dp_src_addr_high_v8;
output [26:0] reg2dp_dst_addr_low_v32;
output [31:0] reg2dp_dst_addr_high_v8;
output [12:0] reg2dp_line_size;
output        reg2dp_cmd_src_ram_type;
output        reg2dp_cmd_dst_ram_type;
output [23:0] reg2dp_line_repeat_number;
output [26:0] reg2dp_src_line_stride;
output [26:0] reg2dp_dst_line_stride;
output [23:0] reg2dp_surf_repeat_number;
output [26:0] reg2dp_src_surf_stride;
output [26:0] reg2dp_dst_surf_stride;
output        reg2dp_op_en;
output        reg2dp_launch0_grp0_launch;
output        reg2dp_launch1_grp1_launch;
output        reg2dp_status_stall_count_en;
output        reg2dp_op_en_trigger;
output        reg2dp_launch0_trigger;
output        reg2dp_launch1_trigger;

// External status inputs
input         ext_status_idle;
input         ext_status_grp0_busy;
input         ext_status_grp1_busy;
input  [7:0]  ext_free_slot;

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

// Register model outputs (wired to reg file module)
wire  [31:0]  nvdla_bdma_cfg_src_addr_high_0_v8;
wire  [26:0]  nvdla_bdma_cfg_src_addr_low_0_v32;
wire  [31:0]  nvdla_bdma_cfg_dst_addr_high_0_v8;
wire  [26:0]  nvdla_bdma_cfg_dst_addr_low_0_v32;
wire  [12:0]  nvdla_bdma_cfg_line_0_size;
wire          nvdla_bdma_cfg_cmd_0_src_ram_type;
wire          nvdla_bdma_cfg_cmd_0_dst_ram_type;
wire  [23:0]  nvdla_bdma_cfg_line_repeat_0_number;
wire  [26:0]  nvdla_bdma_cfg_src_line_0_stride;
wire  [26:0]  nvdla_bdma_cfg_dst_line_0_stride;
wire  [23:0]  nvdla_bdma_cfg_surf_repeat_0_number;
wire  [26:0]  nvdla_bdma_cfg_src_surf_0_stride;
wire  [26:0]  nvdla_bdma_cfg_dst_surf_0_stride;
wire          nvdla_bdma_cfg_op_0_en;
wire          nvdla_bdma_cfg_launch0_0_grp0_launch;
wire          nvdla_bdma_cfg_launch1_0_grp1_launch;
wire          nvdla_bdma_cfg_status_0_stall_count_en;
wire  [31:0]  nvdla_bdma_status_0_free_slot;
wire          nvdla_bdma_status_0_grp0_busy;
wire          nvdla_bdma_status_0_grp1_busy;
wire          nvdla_bdma_status_0_idle;
wire          nvdla_bdma_cfg_op_0_en_trigger;
wire          nvdla_bdma_cfg_launch0_0_grp0_launch_trigger;
wire          nvdla_bdma_cfg_launch1_0_grp1_launch_trigger;
wire          npu_rdy;  // not used but required by reg interface

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
    req_vld <= csb2bdma_req_pvld;
  end
end

// req_pd: capture the full request payload when valid
always @(posedge nvdla_core_clk) begin
  if (csb2bdma_req_pvld == 1'b1) begin
    req_pd <= csb2bdma_req_pd;
  end else if (csb2bdma_req_pvld == 1'b0) begin
    // hold value
  end else begin
    req_pd <= 'bx;  // spyglass disable STARC-2.10.1.6 W443
  end
end

// Ready whenever we are not busy processing a request
assign csb2bdma_req_prdy = 1'b1;

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

assign rsp_pd[33]   = ({1{rsp_rd_vld}} & 1'h0)
                    | ({1{rsp_wr_vld}} & 1'h1);

assign rsp_pd[32:0] = ({33{rsp_rd_vld}} & rsp_rd_pd)
                   | ({33{rsp_wr_vld}} & rsp_wr_pd);

//===============================================================
// RESPONSE REGISTERS - Register the response outputs
//===============================================================
reg    bdma2csb_resp_valid_reg;
reg   [33:0] bdma2csb_resp_pd_reg;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    bdma2csb_resp_valid_reg <= 1'b0;
  end else begin
    bdma2csb_resp_valid_reg <= rsp_vld;
  end
end

always @(posedge nvdla_core_clk) begin
  if (rsp_vld == 1'b1) begin
    bdma2csb_resp_pd_reg <= rsp_pd;
  end else if (rsp_vld == 1'b0) begin
    // hold value
  end else begin
    bdma2csb_resp_pd_reg <= 'bx;  // spyglass disable STARC-2.10.1.6 W443
  end
end

assign bdma2csb_resp_valid = bdma2csb_resp_valid_reg;
assign bdma2csb_resp_pd    = bdma2csb_resp_pd_reg;

//===============================================================
// REGISTER FILE MODULE INSTANCE
//===============================================================
NV_NVDLA_BDMA_reg_new u_reg (
   .csb_clk                               (nvdla_core_clk)                               //|< i
  ,.csb_rstn                              (nvdla_core_rstn)                              //|< i
  ,.csb_addr                              (reg_offset[11:0])                            //|< w
  ,.csb_wdat                              (reg_wr_data[31:0])                            //|< w
  ,.csb_rd_en                            (reg_rd_en)                                    //|< w
  ,.csb_wr_en                            (reg_wr_en)                                    //|< w
  ,.csb_rdat                              (reg_rd_data[31:0])                            //|> w
  ,.npu_rdy                               (npu_rdy)                                      //|> w
  ,.reg2dp_src_addr_low_v32              (reg2dp_src_addr_low_v32)    //|> w
  ,.reg2dp_src_addr_high_v8              (reg2dp_src_addr_high_v8)    //|> w
  ,.reg2dp_dst_addr_low_v32              (reg2dp_dst_addr_low_v32)    //|> w
  ,.reg2dp_dst_addr_high_v8              (reg2dp_dst_addr_high_v8)    //|> w
  ,.reg2dp_line_size                      (reg2dp_line_size)            //|> w
  ,.reg2dp_cmd_src_ram_type              (reg2dp_cmd_src_ram_type)           //|> w
  ,.reg2dp_cmd_dst_ram_type              (reg2dp_cmd_dst_ram_type)           //|> w
  ,.reg2dp_line_repeat_number            (reg2dp_line_repeat_number)  //|> w
  ,.reg2dp_src_line_stride               (reg2dp_src_line_stride)    //|> w
  ,.reg2dp_dst_line_stride               (reg2dp_dst_line_stride)    //|> w
  ,.reg2dp_surf_repeat_number            (reg2dp_surf_repeat_number)  //|> w
  ,.reg2dp_src_surf_stride               (reg2dp_src_surf_stride)    //|> w
  ,.reg2dp_dst_surf_stride               (reg2dp_dst_surf_stride)    //|> w
  ,.reg2dp_op_en                         (reg2dp_op_en)                      //|> w
  ,.reg2dp_trig                          (reg2dp_trig)       //|> w
  ,.reg2dp_status_stall_count_en         (reg2dp_status_stall_count_en)       //|> w
  ,.reg2dp_op_en_trigger                 (reg2dp_op_en_trigger)     //|> w
  ,.reg2dp_trig_trigger                  (reg2dp_trig_trigger)             //|> w
  ,.ext_status_idle                      (ext_status_idle)                            //|< i
  ,.ext_status_grp0_busy                (ext_status_grp0_busy)                        //|< i
  ,.ext_status_grp1_busy                (ext_status_grp1_busy)                        //|< i
  ,.ext_free_slot                        (ext_free_slot[7:0])                         //|< i
  );


//===============================================================
// DATAPATH OUTPUTS - Directly from register file
// (register file now outputs reg2dp_* directly)
//===============================================================

// synoff nets
// monitor nets
// debug nets
// tie high nets
// tie low nets
// no connect nets
// not all bits used nets
// todo nets

endmodule // NV_NVDLA_BDMA_csb_new