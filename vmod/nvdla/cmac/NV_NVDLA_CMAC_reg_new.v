// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_reg_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Register file for CMAC with dual-group scheme for double buffering
// - Group 0 and Group 1 registers
// - Producer/consumer pointer for bank switching
// - Status registers
// - Single (shared) and dual (banked) register groups
// +FHDR------------------------------------------------------------

module NV_NVDLA_CMAC_reg_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,csb2cmac_req_pvld
  ,csb2cmac_req_prdy
  ,csb2cmac_req_pd
  ,cmac2csb_resp_pvld
  ,cmac2csb_resp_pd
  ,reg2dp_op_en
  ,reg2dp_conv_mode
  ,reg2dp_proc_precision
  ,dp2reg_done
  ,dp2reg_consumer
  );

//==============================================================
// Port declarations
//==============================================================
input        nvdla_core_clk;
input        nvdla_core_rstn;

// CSB interface
input        csb2cmac_req_pvld;
output       csb2cmac_req_prdy;
input  [62:0] csb2cmac_req_pd;
output       cmac2csb_resp_pvld;
output [33:0] cmac2csb_resp_pd;

// To datapath
output       reg2dp_op_en;
output       reg2dp_conv_mode;
output [1:0] reg2dp_proc_precision;

// From datapath
input        dp2reg_done;
input        dp2reg_consumer;

//==============================================================
// Parameters
//==============================================================
localparam ADDR_OP_ENABLE = 12'h7008;
localparam ADDR_MISC_CFG  = 12'h700c;
localparam ADDR_STATUS    = 12'h7000;
localparam ADDR_POINTER   = 12'h7004;

localparam OP_ENABLE_OFFSET = ADDR_OP_ENABLE;
localparam MISC_CFG_OFFSET  = ADDR_MISC_CFG;

// Precision encoding
localparam PRECISION_INT8  = 2'b01;
localparam PRECISION_INT16 = 2'b10;
localparam PRECISION_FP16   = 2'b00;

//==============================================================
// Internal signals
//==============================================================
// Request decode
wire [11:0] reg_offset;
wire [31:0] reg_wr_data;
wire        reg_wr_en;
wire        reg_rd_en;

// Single (shared) register group signals
wire [31:0] s_reg_rd_data;
wire        s_reg_wr_en;
wire [11:0] s_reg_offset;
wire [31:0] s_reg_wr_data;
wire        s_reg_match;
wire        producer_pulse;
wire        consumer_pulse;

// Dual register group signals
wire [31:0] d0_reg_rd_data;
wire [31:0] d1_reg_rd_data;
wire        d0_reg_wr_en;
wire        d1_reg_wr_en;
wire [11:0] d0_reg_offset;
wire [11:0] d1_reg_offset;
wire [31:0] d0_reg_wr_data;
wire [31:0] d1_reg_wr_data;

// Dual register outputs
wire        d0_op_en;
wire        d1_op_en;
wire        d0_conv_mode;
wire        d1_conv_mode;
wire  [1:0] d0_proc_precision;
wire  [1:0] d1_proc_precision;
wire        d0_op_en_trigger;
wire        d1_op_en_trigger;

// Consumer pointer
reg         consumer_r;
wire        consumer_w;

// Output muxes
reg         reg2dp_d0_op_en;
reg         reg2dp_d1_op_en;
reg         reg2dp_d0_op_en_w;
reg         reg2dp_d1_op_en_w;
reg  [2:0]  reg2dp_op_en_reg;
reg  [2:0]  reg2dp_op_en_reg_w;
wire        reg2dp_op_en_ori;

// Status
reg  [1:0]  dp2reg_status_0;
reg  [1:0]  dp2reg_status_1;

// Producer (from single register)
wire        producer;

// Register address decode
wire        is_dual_reg;

// Response
reg  [33:0] cmac2csb_resp_pd;
reg         cmac2csb_resp_pvld;
reg         req_pvld_r;
reg  [31:0] req_wdat_r;

//==============================================================
// Request handling
//==============================================================
assign csb2cmac_req_prdy = 1'b1;

// Extract register offset (byte address, we need word address)
assign reg_offset[11:0] = csb2cmac_req_pd[21:0] + 2'b0;  // Byte to word align
assign reg_wr_data[31:0] = csb2cmac_req_pd[53:22];
assign reg_wr_en = csb2cmac_req_pvld & csb2cmac_req_pd[54];  // write bit
assign reg_rd_en = csb2cmac_req_pvld & ~csb2cmac_req_pd[54];

// Determine if accessing dual or single register group
assign is_dual_reg = (reg_offset[11:0] >= OP_ENABLE_OFFSET);

//==============================================================
// Single (shared) register group
// - STATUS and POINTER registers
//==============================================================
assign s_reg_match = (reg_offset[11:0] < OP_ENABLE_OFFSET);

// Register file instance for single regs
NV_NVDLA_CMAC_REG_single u_single_reg (
   .nvdla_core_clk       (nvdla_core_clk)
  ,.nvdla_core_rstn      (nvdla_core_rstn)
  ,.reg_wr_en           (s_reg_wr_en & s_reg_match)
  ,.reg_offset           (reg_offset[11:0])
  ,.reg_wr_data          (reg_wr_data)
  ,.reg_rd_data          (s_reg_rd_data)
  ,.producer             (producer)
  ,.consumer             (consumer_r)
  ,.status_0             (dp2reg_status_0)
  ,.status_1             (dp2reg_status_1)
);

assign s_reg_wr_en   = reg_wr_en & s_reg_match;
assign s_reg_wr_data = reg_wr_data;
assign s_reg_offset  = reg_offset;

// Producer pointer toggles on operation enable
assign producer_pulse = reg_wr_en & s_reg_match & (reg_offset[11:0] == ADDR_POINTER);

//==============================================================
// Dual register groups (for double buffering)
//==============================================================
assign d0_reg_wr_en   = reg_wr_en & is_dual_reg & (producer == 1'b0) & ~reg2dp_d0_op_en;
assign d1_reg_wr_en   = reg_wr_en & is_dual_reg & (producer == 1'b1) & ~reg2dp_d1_op_en;
assign d0_reg_wr_data = reg_wr_data;
assign d1_reg_wr_data = reg_wr_data;
assign d0_reg_offset  = reg_offset;
assign d1_reg_offset  = reg_offset;

// Dual register file instances
NV_NVDLA_CMAC_REG_dual u_dual_reg_d0 (
   .nvdla_core_clk        (nvdla_core_clk)
  ,.nvdla_core_rstn       (nvdla_core_rstn)
  ,.reg_wr_en            (d0_reg_wr_en)
  ,.reg_offset            (d0_reg_offset[11:0])
  ,.reg_wr_data           (d0_reg_wr_data)
  ,.reg_rd_data           (d0_reg_rd_data)
  ,.conv_mode             (d0_conv_mode)
  ,.proc_precision        (d0_proc_precision)
  ,.op_en                (d0_op_en)
  ,.op_en_trigger         (d0_op_en_trigger)
);

NV_NVDLA_CMAC_REG_dual u_dual_reg_d1 (
   .nvdla_core_clk        (nvdla_core_clk)
  ,.nvdla_core_rstn       (nvdla_core_rstn)
  ,.reg_wr_en            (d1_reg_wr_en)
  ,.reg_offset            (d1_reg_offset[11:0])
  ,.reg_wr_data           (d1_reg_wr_data)
  ,.reg_rd_data           (d1_reg_rd_data)
  ,.conv_mode             (d1_conv_mode)
  ,.proc_precision        (d1_proc_precision)
  ,.op_en                (d1_op_en)
  ,.op_en_trigger         (d1_op_en_trigger)
);

//==============================================================
// Consumer pointer management
//==============================================================
assign consumer_w = ~consumer_r;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    consumer_r <= 1'b0;
  end else if (dp2reg_done) begin
    consumer_r <= consumer_w;
  end
end

//==============================================================
// Status generation
//==============================================================
always @* begin
  if (reg2dp_d0_op_en == 1'b0) begin
    dp2reg_status_0 = 2'b00;
  end else if (consumer_r == 1'b1) begin
    dp2reg_status_0 = 2'b10;
  end else begin
    dp2reg_status_0 = 2'b01;
  end
end

always @* begin
  if (reg2dp_d1_op_en == 1'b0) begin
    dp2reg_status_1 = 2'b00;
  end else if (consumer_r == 1'b0) begin
    dp2reg_status_1 = 2'b10;
  end else begin
    dp2reg_status_1 = 2'b01;
  end
end

//==============================================================
// Operation enable logic
//==============================================================
always @* begin
  if ((reg2dp_d0_op_en == 1'b0) && (d0_op_en_trigger == 1'b1)) begin
    reg2dp_d0_op_en_w = reg_wr_data[0];
  end else if (dp2reg_done && (consumer_r == 1'b0)) begin
    reg2dp_d0_op_en_w = 1'b0;
  end else begin
    reg2dp_d0_op_en_w = reg2dp_d0_op_en;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg2dp_d0_op_en <= 1'b0;
  end else begin
    reg2dp_d0_op_en <= reg2dp_d0_op_en_w;
  end
end

always @* begin
  if ((reg2dp_d1_op_en == 1'b0) && (d1_op_en_trigger == 1'b1)) begin
    reg2dp_d1_op_en_w = reg_wr_data[0];
  end else if (dp2reg_done && (consumer_r == 1'b1)) begin
    reg2dp_d1_op_en_w = 1'b0;
  end else begin
    reg2dp_d1_op_en_w = reg2dp_d1_op_en;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg2dp_d1_op_en <= 1'b0;
  end else begin
    reg2dp_d1_op_en <= reg2dp_d1_op_en_w;
  end
end

// Select active op_en based on consumer pointer
assign reg2dp_op_en_ori = consumer_r ? reg2dp_d1_op_en : reg2dp_d0_op_en;

// Pipeline for op_en (3-cycle delay for clock gating)
assign reg2dp_op_en_reg_w = dp2reg_done ? 3'b0 : {reg2dp_op_en_reg[1:0], reg2dp_op_en_ori};

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg2dp_op_en_reg <= 3'b0;
  end else begin
    reg2dp_op_en_reg <= reg2dp_op_en_reg_w;
  end
end

assign reg2dp_op_en = reg2dp_op_en_reg[2];

//==============================================================
// Output selection based on consumer pointer
//==============================================================
assign reg2dp_conv_mode = consumer_r ? d1_conv_mode : d0_conv_mode;
assign reg2dp_proc_precision = consumer_r ? d1_proc_precision : d0_proc_precision;

//==============================================================
// Read data mux
//==============================================================
wire [31:0] reg_rd_data;
assign reg_rd_data = ({32{s_reg_match}} & s_reg_rd_data) |
                     ({32{is_dual_reg & (producer == 1'b0)}} & d0_reg_rd_data) |
                     ({32{is_dual_reg & (producer == 1'b1)}} & d1_reg_rd_data);

//==============================================================
// Response generation
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    req_pvld_r <= 1'b0;
    req_wdat_r <= 32'b0;
  end else begin
    req_pvld_r <= csb2cmac_req_pvld;
    req_wdat_r <= csb2cmac_req_pd[53:22];
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cmac2csb_resp_pvld <= 1'b0;
    cmac2csb_resp_pd   <= '0;
  end else begin
    if (reg_rd_en) begin
      cmac2csb_resp_pvld <= 1'b1;
      cmac2csb_resp_pd[31:0] <= reg_rd_data;
      cmac2csb_resp_pd[32]   <= 1'b0;  // No error
      cmac2csb_resp_pd[33]    <= 1'b0;  // Read response
    end else if (reg_wr_en & csb2cmac_req_pd[55]) begin  // nposted write
      cmac2csb_resp_pvld <= 1'b1;
      cmac2csb_resp_pd[31:0] <= 32'b0;
      cmac2csb_resp_pd[32]   <= 1'b0;  // No error
      cmac2csb_resp_pd[33]    <= 1'b1;  // Write response
    end else begin
      cmac2csb_resp_pvld <= 1'b0;
    end
  end
end

endmodule // NV_NVDLA_CMAC_reg_new