// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CACC_new.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CACC (Convolution Accumulator) Top-Level Module
// - Receives MAC results from MAC_A and MAC_B
// - Accumulates partial sums in assembly buffer
// - Reshapes/truncates data for delivery
// - Outputs to SDP via delivery buffer
// - Register interface via CSB
// - Clock gating via SLCG
// - FHDR------------------------------------------------------------

module NV_NVDLA_CACC_new (
   nvdla_core_clk              //|< i
  ,nvdla_core_rstn             //|< i

  // CSB interface
  ,csb2cacc_req_pvld           //|< i
  ,csb2cacc_req_prdy          //|> o
  ,csb2cacc_req_pd             //|< i  [62:0]
  ,cacc2csb_resp_valid         //|> o
  ,cacc2csb_resp_prdy          //|< i
  ,cacc2csb_resp_pd            //|> o  [33:0]

  // MAC A interface
  ,mac_a2accu_pvld            //|< i
  ,mac_a2accu_mask            //|< i  [7:0]
  ,mac_a2accu_mode            //|< i  [7:0]
  ,mac_a2accu_pd              //|< i  [8:0]
  ,mac_a2accu_data0           //|< i  [175:0]
  ,mac_a2accu_data1           //|< i  [175:0]
  ,mac_a2accu_data2           //|< i  [175:0]
  ,mac_a2accu_data3           //|< i  [175:0]
  ,mac_a2accu_data4           //|< i  [175:0]
  ,mac_a2accu_data5           //|< i  [175:0]
  ,mac_a2accu_data6           //|< i  [175:0]
  ,mac_a2accu_data7           //|< i  [175:0]

  // MAC B interface
  ,mac_b2accu_pvld            //|< i
  ,mac_b2accu_mask            //|< i  [7:0]
  ,mac_b2accu_mode            //|< i  [7:0]
  ,mac_b2accu_pd              //|< i  [8:0]
  ,mac_b2accu_data0           //|< i  [175:0]
  ,mac_b2accu_data1           //|< i  [175:0]
  ,mac_b2accu_data2           //|< i  [175:0]
  ,mac_b2accu_data3           //|< i  [175:0]
  ,mac_b2accu_data4           //|< i  [175:0]
  ,mac_b2accu_data5           //|< i  [175:0]
  ,mac_b2accu_data6           //|< i  [175:0]
  ,mac_b2accu_data7           //|< i  [175:0]

  // Output to SDP
  ,cacc2sdp_valid             //|> o
  ,cacc2sdp_ready             //|< i
  ,cacc2sdp_pd                 //|> o  [513:0]

  // Credit to SC
  ,accu2sc_credit_vld         //|> o
  ,accu2sc_credit_size         //|> o  [2:0]

  // Interrupt to GLB
  ,cacc2glb_done_intr_pd      //|> o  [1:0]

  // Clock gating control
  ,dla_clk_ovr_on_sync        //|< i
  ,global_clk_ovr_on_sync      //|< i
  ,tmc2slcg_disable_clock_gating //|< i

  // Power bus
  ,pwrbus_ram_pd              //|< i  [31:0]
  );

//===============================================================
// Port declarations
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB interface
input         csb2cacc_req_pvld;
output        csb2cacc_req_prdy;
input  [62:0] csb2cacc_req_pd;
output        cacc2csb_resp_valid;
input         cacc2csb_resp_prdy;
output [33:0] cacc2csb_resp_pd;

// MAC A interface
input         mac_a2accu_pvld;
input  [7:0]  mac_a2accu_mask;
input  [7:0]  mac_a2accu_mode;
input  [8:0]  mac_a2accu_pd;
input  [175:0] mac_a2accu_data0;
input  [175:0] mac_a2accu_data1;
input  [175:0] mac_a2accu_data2;
input  [175:0] mac_a2accu_data3;
input  [175:0] mac_a2accu_data4;
input  [175:0] mac_a2accu_data5;
input  [175:0] mac_a2accu_data6;
input  [175:0] mac_a2accu_data7;

// MAC B interface
input         mac_b2accu_pvld;
input  [7:0]  mac_b2accu_mask;
input  [7:0]  mac_b2accu_mode;
input  [8:0]  mac_b2accu_pd;
input  [175:0] mac_b2accu_data0;
input  [175:0] mac_b2accu_data1;
input  [175:0] mac_b2accu_data2;
input  [175:0] mac_b2accu_data3;
input  [175:0] mac_b2accu_data4;
input  [175:0] mac_b2accu_data5;
input  [175:0] mac_b2accu_data6;
input  [175:0] mac_b2accu_data7;

// Output to SDP
output        cacc2sdp_valid;
input         cacc2sdp_ready;
output [513:0] cacc2sdp_pd;

// Credit to SC
output        accu2sc_credit_vld;
output [2:0]  accu2sc_credit_size;

// Interrupt
output [1:0]  cacc2glb_done_intr_pd;

// Clock gating
input         dla_clk_ovr_on_sync;
input         global_clk_ovr_on_sync;
input         tmc2slcg_disable_clock_gating;

// Power bus
input  [31:0] pwrbus_ram_pd;

//===============================================================
// Wire declarations
//===============================================================

// CSB to register file
wire [11:0]  reg_offset;
wire [31:0]  reg_wr_data;
wire         reg_wr_en;
wire         reg_rd_en;
wire [31:0]  reg_rd_data;

// Register to data path
wire [4:0]   reg2dp_batches;
wire [4:0]   reg2dp_clip_truncate;
wire         reg2dp_conv_mode;
wire [31:0]  reg2dp_cya;
wire [26:0]  reg2dp_dataout_addr;
wire [12:0]  reg2dp_dataout_channel;
wire [12:0]  reg2dp_dataout_height;
wire [12:0]  reg2dp_dataout_width;
wire         reg2dp_line_packed;
wire [18:0]  reg2dp_line_stride;
wire         reg2dp_op_en;
wire [1:0]   reg2dp_proc_precision;
wire         reg2dp_surf_packed;
wire [18:0]  reg2dp_surf_stride;

// Data path to register
wire         dp2reg_done;
wire [31:0]  dp2reg_sat_count;
wire         dp2reg_consumer;

// SLCG control
wire [6:0]   slcg_op_en;

// Assembly buffer interface
wire [4:0]   abuf_wr_addr;
wire [767:0]  abuf_wr_data_0;
wire [767:0]  abuf_wr_data_1;
wire [767:0]  abuf_wr_data_2;
wire [767:0]  abuf_wr_data_3;
wire [543:0]  abuf_wr_data_4;
wire [543:0]  abuf_wr_data_5;
wire [543:0]  abuf_wr_data_6;
wire [543:0]  abuf_wr_data_7;
wire [7:0]   abuf_wr_en;
wire [4:0]   abuf_rd_addr;
wire [7:0]   abuf_rd_en;
wire [767:0]  abuf_rd_data_0;
wire [767:0]  abuf_rd_data_1;
wire [767:0]  abuf_rd_data_2;
wire [767:0]  abuf_rd_data_3;
wire [543:0]  abuf_rd_data_4;
wire [543:0]  abuf_rd_data_5;
wire [543:0]  abuf_rd_data_6;
wire [543:0]  abuf_rd_data_7;

// Delivery buffer interface
wire [4:0]   dbuf_wr_addr_0;
wire [4:0]   dbuf_wr_addr_1;
wire [4:0]   dbuf_wr_addr_2;
wire [4:0]   dbuf_wr_addr_3;
wire [4:0]   dbuf_wr_addr_4;
wire [4:0]   dbuf_wr_addr_5;
wire [4:0]   dbuf_wr_addr_6;
wire [4:0]   dbuf_wr_addr_7;
wire [511:0] dbuf_wr_data_0;
wire [511:0] dbuf_wr_data_1;
wire [511:0] dbuf_wr_data_2;
wire [511:0] dbuf_wr_data_3;
wire [511:0] dbuf_wr_data_4;
wire [511:0] dbuf_wr_data_5;
wire [511:0] dbuf_wr_data_6;
wire [511:0] dbuf_wr_data_7;
wire [7:0]   dbuf_wr_en;
wire [4:0]   dbuf_rd_addr;
wire [7:0]   dbuf_rd_en;
wire [511:0] dbuf_rd_data_0;
wire [511:0] dbuf_rd_data_1;
wire [511:0] dbuf_rd_data_2;
wire [511:0] dbuf_rd_data_3;
wire [511:0] dbuf_rd_data_4;
wire [511:0] dbuf_rd_data_5;
wire [511:0] dbuf_rd_data_6;
wire [511:0] dbuf_rd_data_7;
wire         dbuf_rd_layer_end;
wire         dbuf_rd_ready;

// Clock signals
wire         nvdla_op_gated_clk_0;
wire         nvdla_op_gated_clk_1;
wire         nvdla_op_gated_clk_2;
wire         nvdla_cell_gated_clk_0;
wire         nvdla_cell_gated_clk_1;
wire         nvdla_cell_gated_clk_2;
wire         nvdla_cell_gated_clk_3;

//===============================================================
// CSB Interface
//===============================================================
NV_NVDLA_CACC_csb_new u_csb (
   .nvdla_core_clk         (nvdla_core_clk)
  ,.nvdla_core_rstn        (nvdla_core_rstn)
  ,.csb2cacc_req_pvld      (csb2cacc_req_pvld)
  ,.csb2cacc_req_prdy      (csb2cacc_req_prdy)
  ,.csb2cacc_req_pd        (csb2cacc_req_pd[62:0])
  ,.cacc2csb_resp_valid    (cacc2csb_resp_valid)
  ,.cacc2csb_resp_prdy     (cacc2csb_resp_prdy)
  ,.cacc2csb_resp_pd       (cacc2csb_resp_pd[33:0])
  );

// CSB response needs register read data - connect through regfile
// This is a simplified connection - in real design would need proper timing

//===============================================================
// Register File
//===============================================================
NV_NVDLA_CACC_reg_new u_regfile (
   .nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn        (nvdla_core_rstn)
  ,.reg_offset             (reg_offset[11:0])
  ,.reg_wr_data            (reg_wr_data[31:0])
  ,.reg_wr_en              (reg_wr_en)
  ,.reg_rd_en              (reg_rd_en)
  ,.reg_rd_data            (reg_rd_data[31:0])
  ,.reg2dp_batches         (reg2dp_batches[4:0])
  ,.reg2dp_clip_truncate   (reg2dp_clip_truncate[4:0])
  ,.reg2dp_conv_mode       (reg2dp_conv_mode)
  ,.reg2dp_cya             (reg2dp_cya[31:0])
  ,.reg2dp_dataout_addr    (reg2dp_dataout_addr[26:0])
  ,.reg2dp_dataout_channel  (reg2dp_dataout_channel[12:0])
  ,.reg2dp_dataout_height   (reg2dp_dataout_height[12:0])
  ,.reg2dp_dataout_width    (reg2dp_dataout_width[12:0])
  ,.reg2dp_line_packed     (reg2dp_line_packed)
  ,.reg2dp_line_stride      (reg2dp_line_stride[18:0])
  ,.reg2dp_op_en           (reg2dp_op_en)
  ,.reg2dp_proc_precision   (reg2dp_proc_precision[1:0])
  ,.reg2dp_surf_packed     (reg2dp_surf_packed)
  ,.reg2dp_surf_stride      (reg2dp_surf_stride[18:0])
  ,.dp2reg_done            (dp2reg_done)
  ,.dp2reg_sat_count       (dp2reg_sat_count[31:0])
  ,.dp2reg_consumer        (dp2reg_consumer)
  ,.slcg_op_en             (slcg_op_en[6:0])
  );

// Connect CSB to register file
assign reg_offset = csb2cacc_req_pd[33:22];  // Byte address from request
assign reg_wr_data = csb2cacc_req_pd[53:22]; // Write data from request
assign reg_wr_en = csb2cacc_req_pvld & csb2cacc_req_pd[54];  // write bit
assign reg_rd_en = csb2cacc_req_pvld & ~csb2cacc_req_pd[54]; // read bit

// CSB response data from register file
assign cacc2csb_resp_pd[33:0] = {1'b0, 1'b0, reg_rd_data[31:0]};  // Read response

//===============================================================
// SLCG (Switchable Clock Gate) Instances
//===============================================================
// SLCG for operation-level clock gating
NV_NVDLA_CACC_slcg u_slcg_op_0 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[0])
  ,.slcg_en_src_1           (1'b1)
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_op_gated_clk_0)
  );

NV_NVDLA_CACC_slcg u_slcg_op_1 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[1])
  ,.slcg_en_src_1           (1'b1)
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_op_gated_clk_1)
  );

NV_NVDLA_CACC_slcg u_slcg_op_2 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[2])
  ,.slcg_en_src_1           (1'b1)
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_op_gated_clk_2)
  );

// SLCG for cell-level clock gating
NV_NVDLA_CACC_slcg u_slcg_cell_0 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[3])
  ,.slcg_en_src_1           (slcg_op_en[3])  // Cell enable from calc
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_cell_gated_clk_0)
  );

NV_NVDLA_CACC_slcg u_slcg_cell_1 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[4])
  ,.slcg_en_src_1           (slcg_op_en[4])
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_cell_gated_clk_1)
  );

NV_NVDLA_CACC_slcg u_slcg_cell_2 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[5])
  ,.slcg_en_src_1           (slcg_op_en[5])
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_cell_gated_clk_2)
  );

NV_NVDLA_CACC_slcg u_slcg_cell_3 (
   .dla_clk_ovr_on_sync    (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync  (global_clk_ovr_on_sync)
  ,.nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.slcg_en_src_0           (slcg_op_en[6])
  ,.slcg_en_src_1           (slcg_op_en[6])
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_core_gated_clk    (nvdla_cell_gated_clk_3)
  );

//===============================================================
// Calculator
//===============================================================
NV_NVDLA_CACC_calc_new u_calculator (
   .nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.reg2dp_op_en           (reg2dp_op_en)
  ,.reg2dp_conv_mode       (reg2dp_conv_mode)
  ,.reg2dp_proc_precision   (reg2dp_proc_precision[1:0])
  ,.reg2dp_clip_truncate   (reg2dp_clip_truncate[4:0])
  ,.mac_a2accu_pvld        (mac_a2accu_pvld)
  ,.mac_a2accu_mask        (mac_a2accu_mask[7:0])
  ,.mac_a2accu_mode        (mac_a2accu_mode[7:0])
  ,.mac_a2accu_pd          (mac_a2accu_pd[8:0])
  ,.mac_a2accu_data0       (mac_a2accu_data0[175:0])
  ,.mac_a2accu_data1       (mac_a2accu_data1[175:0])
  ,.mac_a2accu_data2       (mac_a2accu_data2[175:0])
  ,.mac_a2accu_data3       (mac_a2accu_data3[175:0])
  ,.mac_a2accu_data4       (mac_a2accu_data4[175:0])
  ,.mac_a2accu_data5       (mac_a2accu_data5[175:0])
  ,.mac_a2accu_data6       (mac_a2accu_data6[175:0])
  ,.mac_a2accu_data7       (mac_a2accu_data7[175:0])
  ,.mac_b2accu_pvld        (mac_b2accu_pvld)
  ,.mac_b2accu_mask        (mac_b2accu_mask[7:0])
  ,.mac_b2accu_mode        (mac_b2accu_mode[7:0])
  ,.mac_b2accu_pd          (mac_b2accu_pd[8:0])
  ,.mac_b2accu_data0       (mac_b2accu_data0[175:0])
  ,.mac_b2accu_data1       (mac_b2accu_data1[175:0])
  ,.mac_b2accu_data2       (mac_b2accu_data2[175:0])
  ,.mac_b2accu_data3       (mac_b2accu_data3[175:0])
  ,.mac_b2accu_data4       (mac_b2accu_data4[175:0])
  ,.mac_b2accu_data5       (mac_b2accu_data5[175:0])
  ,.mac_b2accu_data6       (mac_b2accu_data6[175:0])
  ,.mac_b2accu_data7       (mac_b2accu_data7[175:0])
  ,.abuf_wr_addr           (abuf_wr_addr[4:0])
  ,.abuf_wr_data_0         (abuf_wr_data_0[767:0])
  ,.abuf_wr_data_1         (abuf_wr_data_1[767:0])
  ,.abuf_wr_data_2         (abuf_wr_data_2[767:0])
  ,.abuf_wr_data_3         (abuf_wr_data_3[767:0])
  ,.abuf_wr_data_4         (abuf_wr_data_4[543:0])
  ,.abuf_wr_data_5         (abuf_wr_data_5[543:0])
  ,.abuf_wr_data_6         (abuf_wr_data_6[543:0])
  ,.abuf_wr_data_7         (abuf_wr_data_7[543:0])
  ,.abuf_wr_en             (abuf_wr_en[7:0])
  ,.abuf_rd_addr           (abuf_rd_addr[4:0])
  ,.abuf_rd_en             (abuf_rd_en[7:0])
  ,.abuf_rd_data_0         (abuf_rd_data_0[767:0])
  ,.abuf_rd_data_1         (abuf_rd_data_1[767:0])
  ,.abuf_rd_data_2         (abuf_rd_data_2[767:0])
  ,.abuf_rd_data_3         (abuf_rd_data_3[767:0])
  ,.abuf_rd_data_4         (abuf_rd_data_4[543:0])
  ,.abuf_rd_data_5         (abuf_rd_data_5[543:0])
  ,.abuf_rd_data_6         (abuf_rd_data_6[543:0])
  ,.abuf_rd_data_7         (abuf_rd_data_7[543:0])
  ,.dbuf_wr_addr_0         (dbuf_wr_addr_0[4:0])
  ,.dbuf_wr_addr_1         (dbuf_wr_addr_1[4:0])
  ,.dbuf_wr_addr_2         (dbuf_wr_addr_2[4:0])
  ,.dbuf_wr_addr_3         (dbuf_wr_addr_3[4:0])
  ,.dbuf_wr_addr_4         (dbuf_wr_addr_4[4:0])
  ,.dbuf_wr_addr_5         (dbuf_wr_addr_5[4:0])
  ,.dbuf_wr_addr_6         (dbuf_wr_addr_6[4:0])
  ,.dbuf_wr_addr_7         (dbuf_wr_addr_7[4:0])
  ,.dbuf_wr_data_0         (dbuf_wr_data_0[511:0])
  ,.dbuf_wr_data_1         (dbuf_wr_data_1[511:0])
  ,.dbuf_wr_data_2         (dbuf_wr_data_2[511:0])
  ,.dbuf_wr_data_3         (dbuf_wr_data_3[511:0])
  ,.dbuf_wr_data_4         (dbuf_wr_data_4[511:0])
  ,.dbuf_wr_data_5         (dbuf_wr_data_5[511:0])
  ,.dbuf_wr_data_6         (dbuf_wr_data_6[511:0])
  ,.dbuf_wr_data_7         (dbuf_wr_data_7[511:0])
  ,.dbuf_wr_en             (dbuf_wr_en[7:0])
  ,.dp2reg_done            (dp2reg_done)
  ,.dp2reg_sat_count       (dp2reg_sat_count[31:0])
  );

//===============================================================
// Buffer Module (Assembly + Delivery)
//===============================================================
NV_NVDLA_CACC_buff_new u_buffer (
   .nvdla_core_clk          (nvdla_core_clk)
  ,.nvdla_core_rstn         (nvdla_core_rstn)
  ,.pwrbus_ram_pd           (pwrbus_ram_pd[31:0])
  ,.abuf_wr_addr            (abuf_wr_addr[4:0])
  ,.abuf_wr_data_0          (abuf_wr_data_0[767:0])
  ,.abuf_wr_data_1          (abuf_wr_data_1[767:0])
  ,.abuf_wr_data_2          (abuf_wr_data_2[767:0])
  ,.abuf_wr_data_3          (abuf_wr_data_3[767:0])
  ,.abuf_wr_data_4          (abuf_wr_data_4[543:0])
  ,.abuf_wr_data_5          (abuf_wr_data_5[543:0])
  ,.abuf_wr_data_6          (abuf_wr_data_6[543:0])
  ,.abuf_wr_data_7          (abuf_wr_data_7[543:0])
  ,.abuf_wr_en              (abuf_wr_en[7:0])
  ,.abuf_rd_addr            (abuf_rd_addr[4:0])
  ,.abuf_rd_en              (abuf_rd_en[7:0])
  ,.abuf_rd_data_0          (abuf_rd_data_0[767:0])
  ,.abuf_rd_data_1          (abuf_rd_data_1[767:0])
  ,.abuf_rd_data_2          (abuf_rd_data_2[767:0])
  ,.abuf_rd_data_3          (abuf_rd_data_3[767:0])
  ,.abuf_rd_data_4          (abuf_rd_data_4[543:0])
  ,.abuf_rd_data_5          (abuf_rd_data_5[543:0])
  ,.abuf_rd_data_6          (abuf_rd_data_6[543:0])
  ,.abuf_rd_data_7          (abuf_rd_data_7[543:0])
  ,.dbuf_wr_addr_0          (dbuf_wr_addr_0[4:0])
  ,.dbuf_wr_addr_1          (dbuf_wr_addr_1[4:0])
  ,.dbuf_wr_addr_2          (dbuf_wr_addr_2[4:0])
  ,.dbuf_wr_addr_3          (dbuf_wr_addr_3[4:0])
  ,.dbuf_wr_addr_4          (dbuf_wr_addr_4[4:0])
  ,.dbuf_wr_addr_5          (dbuf_wr_addr_5[4:0])
  ,.dbuf_wr_addr_6          (dbuf_wr_addr_6[4:0])
  ,.dbuf_wr_addr_7          (dbuf_wr_addr_7[4:0])
  ,.dbuf_wr_data_0          (dbuf_wr_data_0[511:0])
  ,.dbuf_wr_data_1          (dbuf_wr_data_1[511:0])
  ,.dbuf_wr_data_2          (dbuf_wr_data_2[511:0])
  ,.dbuf_wr_data_3          (dbuf_wr_data_3[511:0])
  ,.dbuf_wr_data_4          (dbuf_wr_data_4[511:0])
  ,.dbuf_wr_data_5          (dbuf_wr_data_5[511:0])
  ,.dbuf_wr_data_6          (dbuf_wr_data_6[511:0])
  ,.dbuf_wr_data_7          (dbuf_wr_data_7[511:0])
  ,.dbuf_wr_en              (dbuf_wr_en[7:0])
  ,.dbuf_rd_addr            (dbuf_rd_addr[4:0])
  ,.dbuf_rd_en              (dbuf_rd_en[7:0])
  ,.dbuf_rd_data_0          (dbuf_rd_data_0[511:0])
  ,.dbuf_rd_data_1          (dbuf_rd_data_1[511:0])
  ,.dbuf_rd_data_2          (dbuf_rd_data_2[511:0])
  ,.dbuf_rd_data_3          (dbuf_rd_data_3[511:0])
  ,.dbuf_rd_data_4          (dbuf_rd_data_4[511:0])
  ,.dbuf_rd_data_5          (dbuf_rd_data_5[511:0])
  ,.dbuf_rd_data_6          (dbuf_rd_data_6[511:0])
  ,.dbuf_rd_data_7          (dbuf_rd_data_7[511:0])
  ,.dbuf_rd_layer_end       (dbuf_rd_layer_end)
  ,.dbuf_rd_ready           (dbuf_rd_ready)
  );

//===============================================================
// Delivery Controller (simplified)
// Connects delivery buffer to SDP interface
//===============================================================
// In a full implementation, this would handle the complex SDP
// data formatting and delivery sequence

// Assign delivery outputs - simplified
assign cacc2sdp_valid = dbuf_rd_ready;
assign cacc2sdp_pd[511:0] = dbuf_rd_data_0;
assign cacc2sdp_pd[513:512] = 2'b0;  // Padding

// Credit signaling
assign accu2sc_credit_vld = dp2reg_done;
assign accu2sc_credit_size = 3'd1;  // Simplified

// Interrupt
assign cacc2glb_done_intr_pd = {dp2reg_done, dp2reg_done};

endmodule // NV_NVDLA_CACC_new