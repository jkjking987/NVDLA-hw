// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Top-level CMAC (Convolution MAC) module
// - Integrates CSB interface, register file, configuration logic, and MAC array
// - Performs multiply-accumulate operations for neural network convolution
// - Supports INT8, INT16, and FP16 precision
// - Supports normal and Winograd convolution modes
// +FHDR------------------------------------------------------------

module NV_NVDLA_CMAC_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  ,dla_clk_ovr_on_sync
  ,global_clk_ovr_on_sync
  ,tmc2slcg_disable_clock_gating

  // CSB interface
  ,csb2cmac_a_req_pvld
  ,csb2cmac_a_req_pd
  ,cmac_a2csb_resp_pvld
  ,cmac_a2csb_resp_pd
  ,csb2cmac_a_req_prdy

  // Data input from CSC
  ,sc2mac_dat_pvld
  ,sc2mac_dat_data
  ,sc2mac_dat_mask
  ,sc2mac_dat_pd

  // Weight input from CSC
  ,sc2mac_wt_pvld
  ,sc2mac_wt_data
  ,sc2mac_wt_mask
  ,sc2mac_wt_sel

  // Output to accumulator
  ,mac2accu_pvld
  ,mac2accu_data
  ,mac2accu_mask
  ,mac2accu_mode
  ,mac2accu_pd
  );

//==============================================================
// Parameters
//==============================================================
localparam MAC_CELL_NUM        = 8;
localparam DATA_ELEMENT_NUM    = 128;
localparam TOTAL_RESULT_NUM     = MAC_CELL_NUM * 8;  // 64 results
localparam OUTPUT_BIT_WIDTH    = 22;

//==============================================================
// Port declarations
//==============================================================

// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;
input        dla_clk_ovr_on_sync;
input        global_clk_ovr_on_sync;
input        tmc2slcg_disable_clock_gating;

// CSB interface
input        csb2cmac_a_req_pvld;
input  [62:0] csb2cmac_a_req_pd;
output       cmac_a2csb_resp_pvld;
output [33:0] cmac_a2csb_resp_pd;
output       csb2cmac_a_req_prdy;

// Data input from CSC
input        sc2mac_dat_pvld;
input  [DATA_ELEMENT_NUM-1:0][7:0] sc2mac_dat_data;
input  [127:0] sc2mac_dat_mask;
input  [8:0]   sc2mac_dat_pd;

// Weight input from CSC
input        sc2mac_wt_pvld;
input  [DATA_ELEMENT_NUM-1:0][7:0] sc2mac_wt_data;
input  [127:0] sc2mac_wt_mask;
input  [7:0]   sc2mac_wt_sel;

// Output to accumulator
output       mac2accu_pvld;
output [TOTAL_RESULT_NUM-1:0][OUTPUT_BIT_WIDTH-1:0] mac2accu_data;
output [MAC_CELL_NUM-1:0] mac2accu_mask;
output [7:0]   mac2accu_mode;
output [8:0]   mac2accu_pd;

//==============================================================
// Internal wires
//==============================================================

// CSB to register
wire        csb2reg_req_pvld;
wire        csb2reg_req_prdy;
wire [62:0] csb2reg_req_pd;
wire        reg2csb_resp_pvld;
wire [33:0] reg2csb_resp_pd;

// Register to config
wire        reg2dp_op_en;
wire        reg2dp_conv_mode;
wire  [1:0] reg2dp_proc_precision;
wire        dp2reg_done;
wire        dp2reg_consumer;

// Config to MAC
wire        cfg2mac_op_en;
wire        cfg2mac_conv_mode;
wire  [1:0] cfg2mac_proc_precision;
wire        cfg2mac_dat_pvld;
wire        cfg2mac_wt_pvld;
wire        cfg2mac_done;

// Clock gating
wire [10:0] slcg_op_en;

//==============================================================
// CSB interface instantiation
//==============================================================
NV_NVDLA_CMAC_csb_new u_csb (
   .nvdla_core_clk       (nvdla_core_clk)
  ,.nvdla_core_rstn      (nvdla_core_rstn)
  ,.csb2cmac_req_pvld    (csb2cmac_a_req_pvld)
  ,.csb2cmac_req_pd      (csb2cmac_a_req_pd)
  ,.cmac2csb_resp_pvld   (cmac_a2csb_resp_pvld)
  ,.cmac2csb_resp_pd     (cmac_a2csb_resp_pd)
  ,.csb2cmac_req_prdy   (csb2cmac_a_req_prdy)
);

//==============================================================
// Register file instantiation
//==============================================================
NV_NVDLA_CMAC_reg_new u_reg (
   .nvdla_core_clk       (nvdla_core_clk)
  ,.nvdla_core_rstn      (nvdla_core_rstn)
  ,.csb2cmac_req_pvld    (csb2cmac_a_req_pvld)
  ,.csb2cmac_req_prdy   (csb2cmac_a_req_prdy)
  ,.csb2cmac_req_pd      (csb2cmac_a_req_pd)
  ,.cmac2csb_resp_pvld   (cmac_a2csb_resp_pvld)
  ,.cmac2csb_resp_pd     (cmac_a2csb_resp_pd)
  ,.reg2dp_op_en         (reg2dp_op_en)
  ,.reg2dp_conv_mode     (reg2dp_conv_mode)
  ,.reg2dp_proc_precision (reg2dp_proc_precision)
  ,.dp2reg_done          (dp2reg_done)
  ,.dp2reg_consumer      (dp2reg_consumer)
);

//==============================================================
// Configuration logic instantiation
//==============================================================
NV_NVDLA_CMAC_cfg_new u_cfg (
   .nvdla_core_clk       (nvdla_core_clk)
  ,.nvdla_core_rstn      (nvdla_core_rstn)
  ,.reg2dp_op_en         (reg2dp_op_en)
  ,.reg2dp_conv_mode     (reg2dp_conv_mode)
  ,.reg2dp_proc_precision (reg2dp_proc_precision)
  ,.mac2accu_pvld        (mac2accu_pvld)
  ,.cfg2mac_op_en        (cfg2mac_op_en)
  ,.cfg2mac_conv_mode    (cfg2mac_conv_mode)
  ,.cfg2mac_proc_precision (cfg2mac_proc_precision)
  ,.cfg2mac_dat_pvld     (cfg2mac_dat_pvld)
  ,.cfg2mac_wt_pvld      (cfg2mac_wt_pvld)
  ,.cfg2mac_done         (cfg2mac_done)
  ,.dp2reg_done          (dp2reg_done)
  ,.slcg_op_en           (slcg_op_en)
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
);

//==============================================================
// MAC array instantiation
//==============================================================
NV_NVDLA_CMAC_mac_new u_mac (
   .nvdla_core_clk       (nvdla_core_clk)
  ,.nvdla_core_rstn      (nvdla_core_rstn)
  ,.cfg_op_en            (cfg2mac_op_en)
  ,.cfg_conv_mode        (cfg2mac_conv_mode)
  ,.cfg_proc_precision   (cfg2mac_proc_precision)
  ,.sc2mac_dat_pvld      (sc2mac_dat_pvld)
  ,.sc2mac_dat_data      (sc2mac_dat_data)
  ,.sc2mac_dat_mask      (sc2mac_dat_mask)
  ,.sc2mac_wt_pvld       (sc2mac_wt_pvld)
  ,.sc2mac_wt_data       (sc2mac_wt_data)
  ,.sc2mac_wt_mask       (sc2mac_wt_mask)
  ,.sc2mac_wt_sel        (sc2mac_wt_sel)
  ,.mac2accu_pvld        (mac2accu_pvld)
  ,.mac2accu_data        (mac2accu_data)
  ,.mac2accu_mask        (mac2accu_mask)
  ,.mac2accu_mode        (mac2accu_mode)
  ,.mac2accu_pd          (mac2accu_pd)
);

//==============================================================
// Consumer pointer logic (toggle on done)
//==============================================================
reg consumer_r;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    consumer_r <= 1'b0;
  end else if (dp2reg_done) begin
    consumer_r <= ~consumer_r;
  end
end

endmodule // NV_NVDLA_CMAC_new