// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA (Convolution Data Memory Access) Top-Level Module
// - Integrates CSB interface, register file, and data paths
// - Supports Image mode and Winograd mode convolution
// - Interfaces with MCIF/CVIF for external memory access
// - Connects to CSC (Convolution Sequence Controller) for data output
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  // CSB interface
  ,csb2cdma_req_pvld
  ,csb2cdma_req_prdy
  ,csb2cdma_req_pd
  ,cdma2csb_resp_valid
  ,cdma2csb_resp_prdy
  ,cdma2csb_resp_pd
  // MCIF read response
  ,mcif2cdma_dat_rd_rsp_valid
  ,mcif2cdma_dat_rd_rsp_ready
  ,mcif2cdma_dat_rd_rsp_pd
  ,mcif2cdma_wt_rd_rsp_valid
  ,mcif2cdma_wt_rd_rsp_ready
  ,mcif2cdma_wt_rd_rsp_pd
  // CVIF read response
  ,cvif2cdma_dat_rd_rsp_valid
  ,cvif2cdma_dat_rd_rsp_ready
  ,cvif2cdma_dat_rd_rsp_pd
  ,cvif2cdma_wt_rd_rsp_valid
  ,cvif2cdma_wt_rd_rsp_ready
  ,cvif2cdma_wt_rd_rsp_pd
  // MCIF/CVIF read request ready
  ,cdma_dat2mcif_rd_req_ready
  ,cdma_dat2cvif_rd_req_ready
  ,cdma_wt2mcif_rd_req_ready
  ,cdma_wt2cvif_rd_req_ready
  // CSC interface (data output to cbuf)
  ,cdma2csc_dat_wr_valid
  ,cdma2csc_dat_wr_ready
  ,cdma2csc_dat_wr_addr
  ,cdma2csc_dat_wr_data
  ,cdma2csc_dat_wr_be
  // Status to CSC
  ,cdma2csc_status_valid
  ,cdma2csc_status
  // Done interrupts
  ,cdma2glb_done_intr
  // Power bus
  ,pwrbus_ram_pd
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// CSB interface
input        csb2cdma_req_pvld;
output       csb2cdma_req_prdy;
input  [62:0] csb2cdma_req_pd;
output       cdma2csb_resp_valid;
input        cdma2csb_resp_prdy;
output [33:0] cdma2csb_resp_pd;

// MCIF read response
input        mcif2cdma_dat_rd_rsp_valid;
output       mcif2cdma_dat_rd_rsp_ready;
input  [511:0] mcif2cdma_dat_rd_rsp_pd;
input        mcif2cdma_wt_rd_rsp_valid;
output       mcif2cdma_wt_rd_rsp_ready;
input  [511:0] mcif2cdma_wt_rd_rsp_pd;

// CVIF read response
input        cvif2cdma_dat_rd_rsp_valid;
output       cvif2cdma_dat_rd_rsp_ready;
input  [511:0] cvif2cdma_dat_rd_rsp_pd;
input        cvif2cdma_wt_rd_rsp_valid;
output       cvif2cdma_wt_rd_rsp_ready;
input  [511:0] cvif2cdma_wt_rd_rsp_pd;

// MCIF/CVIF read request ready
input        cdma_dat2mcif_rd_req_ready;
input        cdma_dat2cvif_rd_req_ready;
input        cdma_wt2mcif_rd_req_ready;
input        cdma_wt2cvif_rd_req_ready;

// CSC interface
output        cdma2csc_dat_wr_valid;
input         cdma2csc_dat_wr_ready;
output  [11:0] cdma2csc_dat_wr_addr;
output [1023:0] cdma2csc_dat_wr_data;
output  [7:0] cdma2csc_dat_wr_be;

// Status
output        cdma2csc_status_valid;
output  [1:0] cdma2csc_status;

// Done interrupts
output  [1:0] cdma2glb_done_intr;

// Power bus
input  [31:0] pwrbus_ram_pd;

//===============================================================
// SIGNAL DECLARATION - INTERNAL
//===============================================================
// CSB to register
wire  [11:0] csb_addr;
wire  [31:0] csb_wdat;
wire         csb_wr_en;
wire         csb_rd_en;
wire  [31:0] csb_rdat;
wire         npu_rdy;

// Register to datapath (D0 group)
wire        reg2dp_d0_op_en;
wire  [3:0] reg2dp_d0_data_bank;
wire  [3:0] reg2dp_d0_weight_bank;
wire  [4:0] reg2dp_d0_batches;
wire [26:0] reg2dp_d0_batch_stride;
wire  [2:0] reg2dp_d0_conv_x_stride;
wire  [2:0] reg2dp_d0_conv_y_stride;
wire        reg2dp_d0_cvt_en;
wire  [5:0] reg2dp_d0_cvt_truncate;
wire [15:0] reg2dp_d0_cvt_offset;
wire [15:0] reg2dp_d0_cvt_scale;
wire [31:0] reg2dp_d0_cya;
wire [31:0] reg2dp_d0_datain_addr_high_0;
wire [31:0] reg2dp_d0_datain_addr_high_1;
wire [26:0] reg2dp_d0_datain_addr_low_0;
wire [26:0] reg2dp_d0_datain_addr_low_1;
wire        reg2dp_d0_line_packed;
wire        reg2dp_d0_surf_packed;
wire        reg2dp_d0_datain_ram_type;
wire        reg2dp_d0_datain_format;
wire  [5:0] reg2dp_d0_pixel_format;
wire        reg2dp_d0_pixel_mapping;
wire        reg2dp_d0_pixel_sign_override;
wire [12:0] reg2dp_d0_datain_height;
wire [12:0] reg2dp_d0_datain_width;
wire [12:0] reg2dp_d0_datain_channel;
wire [12:0] reg2dp_d0_datain_height_ext;
wire [12:0] reg2dp_d0_datain_width_ext;
wire [11:0] reg2dp_d0_entries;
wire [11:0] reg2dp_d0_grains;
wire [26:0] reg2dp_d0_line_stride;
wire [26:0] reg2dp_d0_uv_line_stride;
wire [26:0] reg2dp_d0_surf_stride;
wire        reg2dp_d0_mean_format;
wire [15:0] reg2dp_d0_mean_gu;
wire [15:0] reg2dp_d0_mean_ry;
wire [15:0] reg2dp_d0_mean_ax;
wire [15:0] reg2dp_d0_mean_bv;
wire        reg2dp_d0_conv_mode;
wire        reg2dp_d0_data_reuse;
wire  [1:0] reg2dp_d0_in_precision;
wire  [1:0] reg2dp_d0_proc_precision;
wire        reg2dp_d0_skip_data_rls;
wire        reg2dp_d0_skip_weight_rls;
wire        reg2dp_d0_weight_reuse;
wire        reg2dp_d0_nan_to_zero;
wire        reg2dp_d0_op_en_trigger;
wire        reg2dp_d0_dma_en;
wire  [4:0] reg2dp_d0_pixel_x_offset;
wire  [2:0] reg2dp_d0_pixel_y_offset;
wire  [9:0] reg2dp_d0_rsv_per_line;
wire  [9:0] reg2dp_d0_rsv_per_uv_line;
wire  [2:0] reg2dp_d0_rsv_height;
wire  [4:0] reg2dp_d0_rsv_y_index;
wire [31:0] reg2dp_d0_weight_addr_high;
wire [26:0] reg2dp_d0_weight_addr_low;
wire [24:0] reg2dp_d0_weight_bytes;
wire        reg2dp_d0_weight_format;
wire        reg2dp_d0_weight_ram_type;
wire [17:0] reg2dp_d0_byte_per_kernel;
wire [12:0] reg2dp_d0_weight_kernel;
wire [31:0] reg2dp_d0_wgs_addr_high;
wire [26:0] reg2dp_d0_wgs_addr_low;
wire [31:0] reg2dp_d0_wmb_addr_high;
wire [26:0] reg2dp_d0_wmb_addr_low;
wire [20:0] reg2dp_d0_wmb_bytes;
wire  [5:0] reg2dp_d0_pad_bottom;
wire  [4:0] reg2dp_d0_pad_left;
wire  [5:0] reg2dp_d0_pad_right;
wire  [4:0] reg2dp_d0_pad_top;
wire [15:0] reg2dp_d0_pad_value;
wire [3:0]  reg2dp_arb_weight;
wire [3:0]  reg2dp_arb_wmb;
wire        reg2dp_producer;

// Status from datapath
wire  [31:0] dp2reg_d0_nan_data_num;
wire  [31:0] dp2reg_d0_inf_data_num;
wire  [31:0] dp2reg_d0_dat_rd_latency;
wire  [31:0] dp2reg_d0_dat_rd_stall;
wire  [1:0]  dp2reg_status_0;
wire        dp2reg_flush_done;

// Image path signals
wire        img2cvt_dat_wr_en;
wire [11:0] img2cvt_dat_wr_addr;
wire [1023:0] img2cvt_dat_wr_data;
wire        img2cvt_dat_wr_hsel;
wire [11:0] img2cvt_dat_wr_info_pd;
wire [127:0] img2cvt_dat_wr_pad_mask;
wire [1023:0] img2cvt_mn_wr_data;
wire        img2status_dat_updt;
wire [11:0] img2status_dat_entries;
wire [11:0] img2status_dat_slices;
wire  [1:0] img2status_state;
wire  [31:0] dp2reg_img_rd_latency;
wire  [31:0] dp2reg_img_rd_stall;

// Winograd path signals
wire        wg2cvt_dat_wr_en;
wire [11:0] wg2cvt_dat_wr_addr;
wire [511:0] wg2cvt_dat_wr_data;
wire        wg2cvt_dat_wr_hsel;
wire [11:0] wg2cvt_dat_wr_info_pd;
wire        wg2status_dat_updt;
wire [11:0] wg2status_dat_entries;
wire [11:0] wg2status_dat_slices;
wire  [1:0] wg2status_state;
wire  [31:0] dp2reg_wg_rd_latency;
wire  [31:0] dp2reg_wg_rd_stall;

// DC path signals (simplified)
wire        dc2cvt_dat_wr_en;
wire [11:0] dc2cvt_dat_wr_addr;
wire [511:0] dc2cvt_dat_wr_data;
wire        dc2cvt_dat_wr_hsel;
wire [11:0] dc2cvt_dat_wr_info_pd;

// Mean shift signals
wire        mn2cvt_dat_out_valid;
wire [1023:0] mn2cvt_dat_out_pd;
wire [31:0] dp2reg_nan_data_num_mn;
wire [31:0] dp2reg_inf_data_num_mn;

// Shared status
wire        cdma_done;

// Select between image/winograd/dc based on conv_mode
wire        use_img_path;
wire        use_wg_path;
wire  [1:0] current_status;

//===============================================================
// CSB INTERFACE MODULE
//===============================================================
NV_NVDLA_CDMA_csb_new u_csb (
   .nvdla_core_clk            (nvdla_core_clk),
   .nvdla_core_rstn           (nvdla_core_rstn),
   .csb2cdma_req_pvld         (csb2cdma_req_pvld),
   .csb2cdma_req_prdy         (csb2cdma_req_prdy),
   .csb2cdma_req_pd           (csb2cdma_req_pd),
   .cdma2csb_resp_valid       (cdma2csb_resp_valid),
   .cdma2csb_resp_prdy        (cdma2csb_resp_prdy),
   .cdma2csb_resp_pd          (cdma2csb_resp_pd),
   .reg2csb_addr              (csb_addr),
   .reg2csb_wdat              (csb_wdat),
   .reg2csb_wr_en             (csb_wr_en),
   .reg2csb_rd_en             (csb_rd_en),
   .csb2reg_rdat              (csb_rdat)
);

//===============================================================
// REGISTER FILE MODULE
//===============================================================
NV_NVDLA_CDMA_reg_new u_reg (
   .nvdla_core_clk            (nvdla_core_clk),
   .nvdla_core_rstn           (nvdla_core_rstn),
   .csb_addr                  (csb_addr),
   .csb_wdat                  (csb_wdat),
   .csb_wr_en                 (csb_wr_en),
   .csb_rd_en                 (csb_rd_en),
   .csb_rdat                  (csb_rdat),
   .npu_rdy                   (npu_rdy),
   .reg2dp_arb_weight         (reg2dp_arb_weight),
   .reg2dp_arb_wmb            (reg2dp_arb_wmb),
   .reg2dp_producer           (reg2dp_producer),
   .reg2dp_d0_op_en           (reg2dp_d0_op_en),
   .reg2dp_d0_data_bank       (reg2dp_d0_data_bank),
   .reg2dp_d0_weight_bank     (reg2dp_d0_weight_bank),
   .reg2dp_d0_batches         (reg2dp_d0_batches),
   .reg2dp_d0_batch_stride    (reg2dp_d0_batch_stride),
   .reg2dp_d0_conv_x_stride   (reg2dp_d0_conv_x_stride),
   .reg2dp_d0_conv_y_stride   (reg2dp_d0_conv_y_stride),
   .reg2dp_d0_cvt_en          (reg2dp_d0_cvt_en),
   .reg2dp_d0_cvt_truncate    (reg2dp_d0_cvt_truncate),
   .reg2dp_d0_cvt_offset      (reg2dp_d0_cvt_offset),
   .reg2dp_d0_cvt_scale       (reg2dp_d0_cvt_scale),
   .reg2dp_d0_cya             (reg2dp_d0_cya),
   .reg2dp_d0_datain_addr_high_0 (reg2dp_d0_datain_addr_high_0),
   .reg2dp_d0_datain_addr_high_1 (reg2dp_d0_datain_addr_high_1),
   .reg2dp_d0_datain_addr_low_0 (reg2dp_d0_datain_addr_low_0),
   .reg2dp_d0_datain_addr_low_1 (reg2dp_d0_datain_addr_low_1),
   .reg2dp_d0_line_packed      (reg2dp_d0_line_packed),
   .reg2dp_d0_surf_packed      (reg2dp_d0_surf_packed),
   .reg2dp_d0_datain_ram_type  (reg2dp_d0_datain_ram_type),
   .reg2dp_d0_datain_format    (reg2dp_d0_datain_format),
   .reg2dp_d0_pixel_format     (reg2dp_d0_pixel_format),
   .reg2dp_d0_pixel_mapping     (reg2dp_d0_pixel_mapping),
   .reg2dp_d0_pixel_sign_override (reg2dp_d0_pixel_sign_override),
   .reg2dp_d0_datain_height    (reg2dp_d0_datain_height),
   .reg2dp_d0_datain_width     (reg2dp_d0_datain_width),
   .reg2dp_d0_datain_channel   (reg2dp_d0_datain_channel),
   .reg2dp_d0_datain_height_ext (reg2dp_d0_datain_height_ext),
   .reg2dp_d0_datain_width_ext  (reg2dp_d0_datain_width_ext),
   .reg2dp_d0_entries          (reg2dp_d0_entries),
   .reg2dp_d0_grains           (reg2dp_d0_grains),
   .reg2dp_d0_line_stride      (reg2dp_d0_line_stride),
   .reg2dp_d0_uv_line_stride   (reg2dp_d0_uv_line_stride),
   .reg2dp_d0_mean_format      (reg2dp_d0_mean_format),
   .reg2dp_d0_mean_gu          (reg2dp_d0_mean_gu),
   .reg2dp_d0_mean_ry          (reg2dp_d0_mean_ry),
   .reg2dp_d0_mean_ax          (reg2dp_d0_mean_ax),
   .reg2dp_d0_mean_bv          (reg2dp_d0_mean_bv),
   .reg2dp_d0_conv_mode        (reg2dp_d0_conv_mode),
   .reg2dp_d0_data_reuse       (reg2dp_d0_data_reuse),
   .reg2dp_d0_in_precision     (reg2dp_d0_in_precision),
   .reg2dp_d0_proc_precision   (reg2dp_d0_proc_precision),
   .reg2dp_d0_skip_data_rls    (reg2dp_d0_skip_data_rls),
   .reg2dp_d0_skip_weight_rls  (reg2dp_d0_skip_weight_rls),
   .reg2dp_d0_weight_reuse     (reg2dp_d0_weight_reuse),
   .reg2dp_d0_nan_to_zero      (reg2dp_d0_nan_to_zero),
   .reg2dp_d0_op_en_trigger    (reg2dp_d0_op_en_trigger),
   .reg2dp_d0_dma_en           (reg2dp_d0_dma_en),
   .reg2dp_d0_pixel_x_offset   (reg2dp_d0_pixel_x_offset),
   .reg2dp_d0_pixel_y_offset   (reg2dp_d0_pixel_y_offset),
   .reg2dp_d0_rsv_per_line     (reg2dp_d0_rsv_per_line),
   .reg2dp_d0_rsv_per_uv_line  (reg2dp_d0_rsv_per_uv_line),
   .reg2dp_d0_rsv_height       (reg2dp_d0_rsv_height),
   .reg2dp_d0_rsv_y_index      (reg2dp_d0_rsv_y_index),
   .reg2dp_d0_surf_stride       (reg2dp_d0_surf_stride),
   .reg2dp_d0_weight_addr_high  (reg2dp_d0_weight_addr_high),
   .reg2dp_d0_weight_addr_low   (reg2dp_d0_weight_addr_low),
   .reg2dp_d0_weight_bytes      (reg2dp_d0_weight_bytes),
   .reg2dp_d0_weight_format     (reg2dp_d0_weight_format),
   .reg2dp_d0_weight_ram_type   (reg2dp_d0_weight_ram_type),
   .reg2dp_d0_byte_per_kernel   (reg2dp_d0_byte_per_kernel),
   .reg2dp_d0_weight_kernel     (reg2dp_d0_weight_kernel),
   .reg2dp_d0_wgs_addr_high     (reg2dp_d0_wgs_addr_high),
   .reg2dp_d0_wgs_addr_low      (reg2dp_d0_wgs_addr_low),
   .reg2dp_d0_wmb_addr_high     (reg2dp_d0_wmb_addr_high),
   .reg2dp_d0_wmb_addr_low      (reg2dp_d0_wmb_addr_low),
   .reg2dp_d0_wmb_bytes         (reg2dp_d0_wmb_bytes),
   .reg2dp_d0_pad_bottom        (reg2dp_d0_pad_bottom),
   .reg2dp_d0_pad_left          (reg2dp_d0_pad_left),
   .reg2dp_d0_pad_right         (reg2dp_d0_pad_right),
   .reg2dp_d0_pad_top           (reg2dp_d0_pad_top),
   .reg2dp_d0_pad_value         (reg2dp_d0_pad_value),
   .dp2reg_d0_nan_data_num      (dp2reg_d0_nan_data_num),
   .dp2reg_d0_inf_data_num      (dp2reg_d0_inf_data_num),
   .dp2reg_d0_dat_rd_latency    (dp2reg_d0_dat_rd_latency),
   .dp2reg_d0_dat_rd_stall      (dp2reg_d0_dat_rd_stall),
   .dp2reg_d0_inf_weight_num    (32'd0),
   .dp2reg_d0_nan_weight_num    (32'd0),
   .dp2reg_d0_wt_rd_latency     (32'd0),
   .dp2reg_d0_wt_rd_stall       (32'd0),
   .dp2reg_status_0             (dp2reg_status_0),
   .dp2reg_flush_done          (dp2reg_flush_done),
   // D1 group - not used in simplified version, connect to D0
   .reg2dp_d1_op_en           (),
   .reg2dp_d1_data_bank       (),
   .reg2dp_d1_weight_bank     (),
   .reg2dp_d1_batches         (),
   .reg2dp_d1_batch_stride    (),
   .reg2dp_d1_conv_x_stride   (),
   .reg2dp_d1_conv_y_stride   (),
   .reg2dp_d1_cvt_en          (),
   .reg2dp_d1_cvt_truncate    (),
   .reg2dp_d1_cvt_offset      (),
   .reg2dp_d1_cvt_scale       (),
   .reg2dp_d1_cya             (),
   .reg2dp_d1_datain_addr_high_0 (),
   .reg2dp_d1_datain_addr_high_1 (),
   .reg2dp_d1_datain_addr_low_0 (),
   .reg2dp_d1_datain_addr_low_1 (),
   .reg2dp_d1_line_packed      (),
   .reg2dp_d1_surf_packed      (),
   .reg2dp_d1_datain_ram_type  (),
   .reg2dp_d1_datain_format    (),
   .reg2dp_d1_pixel_format     (),
   .reg2dp_d1_pixel_mapping     (),
   .reg2dp_d1_pixel_sign_override (),
   .reg2dp_d1_datain_height    (),
   .reg2dp_d1_datain_width     (),
   .reg2dp_d1_datain_channel   (),
   .reg2dp_d1_datain_height_ext (),
   .reg2dp_d1_datain_width_ext  (),
   .reg2dp_d1_entries          (),
   .reg2dp_d1_grains           (),
   .reg2dp_d1_line_stride      (),
   .reg2dp_d1_uv_line_stride   (),
   .reg2dp_d1_mean_format      (),
   .reg2dp_d1_mean_gu          (),
   .reg2dp_d1_mean_ry          (),
   .reg2dp_d1_mean_ax          (),
   .reg2dp_d1_mean_bv          (),
   .reg2dp_d1_conv_mode        (),
   .reg2dp_d1_data_reuse       (),
   .reg2dp_d1_in_precision     (),
   .reg2dp_d1_proc_precision   (),
   .reg2dp_d1_skip_data_rls    (),
   .reg2dp_d1_skip_weight_rls  (),
   .reg2dp_d1_weight_reuse     (),
   .reg2dp_d1_nan_to_zero      (),
   .reg2dp_d1_op_en_trigger    (),
   .reg2dp_d1_dma_en           (),
   .reg2dp_d1_pixel_x_offset   (),
   .reg2dp_d1_pixel_y_offset   (),
   .reg2dp_d1_rsv_per_line     (),
   .reg2dp_d1_rsv_per_uv_line  (),
   .reg2dp_d1_rsv_height       (),
   .reg2dp_d1_rsv_y_index      (),
   .reg2dp_d1_surf_stride       (),
   .reg2dp_d1_weight_addr_high  (),
   .reg2dp_d1_weight_addr_low   (),
   .reg2dp_d1_weight_bytes      (),
   .reg2dp_d1_weight_format     (),
   .reg2dp_d1_weight_ram_type   (),
   .reg2dp_d1_byte_per_kernel   (),
   .reg2dp_d1_weight_kernel     (),
   .reg2dp_d1_wgs_addr_high     (),
   .reg2dp_d1_wgs_addr_low      (),
   .reg2dp_d1_wmb_addr_high     (),
   .reg2dp_d1_wmb_addr_low      (),
   .reg2dp_d1_wmb_bytes         (),
   .reg2dp_d1_pad_bottom        (),
   .reg2dp_d1_pad_left          (),
   .reg2dp_d1_pad_right         (),
   .reg2dp_d1_pad_top           (),
   .reg2dp_d1_pad_value         (),
   .dp2reg_d1_nan_data_num      (32'd0),
   .dp2reg_d1_inf_data_num      (32'd0),
   .dp2reg_d1_dat_rd_latency    (32'd0),
   .dp2reg_d1_dat_rd_stall      (32'd0),
   .dp2reg_d1_inf_weight_num    (32'd0),
   .dp2reg_d1_nan_weight_num    (32'd0),
   .dp2reg_d1_wt_rd_latency     (32'd0),
   .dp2reg_d1_wt_rd_stall       (32'd0),
   .dp2reg_status_1             (2'd0)
);

//===============================================================
// IMAGE MODE DATA PATH
//===============================================================
NV_NVDLA_CDMA_image_new u_img (
   .nvdla_core_clk            (nvdla_core_clk),
   .nvdla_core_rstn           (nvdla_core_rstn),
   .mcif2img_dat_rd_rsp_valid (mcif2cdma_dat_rd_rsp_valid),
   .mcif2img_dat_rd_rsp_ready (mcif2cdma_dat_rd_rsp_ready),
   .mcif2img_dat_rd_rsp_pd    (mcif2cdma_dat_rd_rsp_pd),
   .cvif2img_dat_rd_rsp_valid (cvif2cdma_dat_rd_rsp_valid),
   .cvif2img_dat_rd_rsp_ready (cvif2cdma_dat_rd_rsp_ready),
   .cvif2img_dat_rd_rsp_pd    (cvif2cdma_dat_rd_rsp_pd),
   .img_dat2mcif_rd_req_ready (cdma_dat2mcif_rd_req_ready),
   .img_dat2cvif_rd_req_ready (cdma_dat2cvif_rd_req_ready),
   .reg2dp_op_en              (reg2dp_d0_op_en),
   .reg2dp_conv_mode          (reg2dp_d0_conv_mode),
   .reg2dp_in_precision       (reg2dp_d0_in_precision),
   .reg2dp_proc_precision     (reg2dp_d0_proc_precision),
   .reg2dp_datain_ram_type     (reg2dp_d0_datain_ram_type),
   .reg2dp_datain_addr_high_0  (reg2dp_d0_datain_addr_high_0),
   .reg2dp_datain_addr_low_0   (reg2dp_d0_datain_addr_low_0),
   .reg2dp_datain_addr_high_1  (reg2dp_d0_datain_addr_high_1),
   .reg2dp_datain_addr_low_1   (reg2dp_d0_datain_addr_low_1),
   .reg2dp_datain_width        (reg2dp_d0_datain_width),
   .reg2dp_datain_height       (reg2dp_d0_datain_height),
   .reg2dp_datain_channel      (reg2dp_d0_datain_channel),
   .reg2dp_line_stride         (reg2dp_d0_line_stride),
   .reg2dp_uv_line_stride      (reg2dp_d0_uv_line_stride),
   .reg2dp_pixel_format        (reg2dp_d0_pixel_format),
   .reg2dp_pixel_mapping       (reg2dp_d0_pixel_mapping),
   .reg2dp_pixel_x_offset      (reg2dp_d0_pixel_x_offset),
   .reg2dp_pixel_y_offset      (reg2dp_d0_pixel_y_offset),
   .reg2dp_pixel_sign_override (reg2dp_d0_pixel_sign_override),
   .reg2dp_mean_format         (reg2dp_d0_mean_format),
   .reg2dp_mean_ry             (reg2dp_d0_mean_ry),
   .reg2dp_mean_gu             (reg2dp_d0_mean_gu),
   .reg2dp_mean_bv             (reg2dp_d0_mean_bv),
   .reg2dp_mean_ax             (reg2dp_d0_mean_ax),
   .reg2dp_data_bank           (reg2dp_d0_data_bank),
   .reg2dp_pad_left            (reg2dp_d0_pad_left),
   .reg2dp_pad_right           (reg2dp_d0_pad_right),
   .reg2dp_pad_top             (reg2dp_d0_pad_top),
   .reg2dp_pad_bottom          (reg2dp_d0_pad_bottom),
   .reg2dp_pad_value           (reg2dp_d0_pad_value),
   .reg2dp_dma_en              (reg2dp_d0_dma_en),
   .sc2cdma_dat_pending_req    (1'b0),
   .status2dma_free_entries     (12'd0),
   .status2dma_valid_slices    (12'd0),
   .status2dma_wr_idx          (12'd0),
   .status2dma_fsm_switch      (1'b0),
   .img2cvt_dat_wr_en          (img2cvt_dat_wr_en),
   .img2cvt_dat_wr_addr        (img2cvt_dat_wr_addr),
   .img2cvt_dat_wr_data        (img2cvt_dat_wr_data),
   .img2cvt_dat_wr_hsel        (img2cvt_dat_wr_hsel),
   .img2cvt_dat_wr_info_pd     (img2cvt_dat_wr_info_pd),
   .img2cvt_dat_wr_pad_mask    (img2cvt_dat_wr_pad_mask),
   .img2cvt_mn_wr_data         (img2cvt_mn_wr_data),
   .img2sbuf_p0_wr_en          (),
   .img2sbuf_p0_wr_addr        (),
   .img2sbuf_p0_wr_data        (),
   .img2sbuf_p1_wr_en          (),
   .img2sbuf_p1_wr_addr        (),
   .img2sbuf_p1_wr_data        (),
   .img2sbuf_p0_rd_en          (),
   .img2sbuf_p0_rd_addr        (),
   .img2sbuf_p0_rd_data        (256'd0),
   .img2sbuf_p1_rd_en          (),
   .img2sbuf_p1_rd_addr        (),
   .img2sbuf_p1_rd_data        (256'd0),
   .img2status_dat_updt        (img2status_dat_updt),
   .img2status_dat_entries     (img2status_dat_entries),
   .img2status_dat_slices      (img2status_dat_slices),
   .img2status_state           (img2status_state),
   .dp2reg_img_rd_latency      (dp2reg_img_rd_latency),
   .dp2reg_img_rd_stall        (dp2reg_img_rd_stall)
);

//===============================================================
// WINOGRAD MODE DATA PATH
//===============================================================
NV_NVDLA_CDMA_winograd_new u_wg (
   .nvdla_core_clk            (nvdla_core_clk),
   .nvdla_core_rstn           (nvdla_core_rstn),
   .mcif2wg_dat_rd_rsp_valid  (mcif2cdma_dat_rd_rsp_valid),
   .mcif2wg_dat_rd_rsp_ready  (mcif2cdma_dat_rd_rsp_ready),
   .mcif2wg_dat_rd_rsp_pd     (mcif2cdma_dat_rd_rsp_pd),
   .cvif2wg_dat_rd_rsp_valid  (cvif2cdma_dat_rd_rsp_valid),
   .cvif2wg_dat_rd_rsp_ready  (cvif2cdma_dat_rd_rsp_ready),
   .cvif2wg_dat_rd_rsp_pd     (cvif2cdma_dat_rd_rsp_pd),
   .wg_dat2mcif_rd_req_ready  (cdma_dat2mcif_rd_req_ready),
   .wg_dat2cvif_rd_req_ready  (cdma_dat2cvif_rd_req_ready),
   .reg2dp_op_en              (reg2dp_d0_op_en),
   .reg2dp_conv_mode          (reg2dp_d0_conv_mode),
   .reg2dp_in_precision       (reg2dp_d0_in_precision),
   .reg2dp_proc_precision     (reg2dp_d0_proc_precision),
   .reg2dp_datain_ram_type     (reg2dp_d0_datain_ram_type),
   .reg2dp_datain_addr_high_0  (reg2dp_d0_datain_addr_high_0),
   .reg2dp_datain_addr_low_0   (reg2dp_d0_datain_addr_low_0),
   .reg2dp_datain_width        (reg2dp_d0_datain_width),
   .reg2dp_datain_height       (reg2dp_d0_datain_height),
   .reg2dp_datain_channel      (reg2dp_d0_datain_channel),
   .reg2dp_datain_width_ext    (reg2dp_d0_datain_width_ext),
   .reg2dp_datain_height_ext   (reg2dp_d0_datain_height_ext),
   .reg2dp_line_stride         (reg2dp_d0_line_stride),
   .reg2dp_surf_stride         (reg2dp_d0_surf_stride),
   .reg2dp_entries            (reg2dp_d0_entries),
   .reg2dp_grains             (reg2dp_d0_grains),
   .reg2dp_conv_x_stride      (reg2dp_d0_conv_x_stride),
   .reg2dp_conv_y_stride      (reg2dp_d0_conv_y_stride),
   .reg2dp_data_bank          (reg2dp_d0_data_bank),
   .sc2cdma_dat_pending_req   (1'b0),
   .status2dma_free_entries   (12'd0),
   .status2dma_valid_slices   (12'd0),
   .status2dma_wr_idx         (12'd0),
   .status2dma_fsm_switch     (1'b0),
   .wg2cvt_dat_wr_en          (wg2cvt_dat_wr_en),
   .wg2cvt_dat_wr_addr        (wg2cvt_dat_wr_addr),
   .wg2cvt_dat_wr_data        (wg2cvt_dat_wr_data),
   .wg2cvt_dat_wr_hsel        (wg2cvt_dat_wr_hsel),
   .wg2cvt_dat_wr_info_pd     (wg2cvt_dat_wr_info_pd),
   .wg2sbuf_p0_wr_en          (),
   .wg2sbuf_p0_wr_addr        (),
   .wg2sbuf_p0_wr_data        (),
   .wg2sbuf_p0_rd_en          (),
   .wg2sbuf_p0_rd_addr        (),
   .wg2sbuf_p0_rd_data        (256'd0),
   .wg2sbuf_p1_wr_en          (),
   .wg2sbuf_p1_wr_addr        (),
   .wg2sbuf_p1_wr_data        (),
   .wg2sbuf_p1_rd_en          (),
   .wg2sbuf_p1_rd_addr        (),
   .wg2sbuf_p1_rd_data        (256'd0),
   .wg2status_dat_updt        (wg2status_dat_updt),
   .wg2status_dat_entries     (wg2status_dat_entries),
   .wg2status_dat_slices      (wg2status_dat_slices),
   .wg2status_state           (wg2status_state),
   .dp2reg_wg_rd_latency      (dp2reg_wg_rd_latency),
   .dp2reg_wg_rd_stall        (dp2reg_wg_rd_stall)
);

//===============================================================
// PATH SELECTION LOGIC
//===============================================================
// Select active path based on conv_mode
assign use_img_path = reg2dp_d0_op_en && (reg2dp_d0_conv_mode == 1'b0);
assign use_wg_path = reg2dp_d0_op_en && (reg2dp_d0_conv_mode == 1'b1);

// Select output data based on path
assign cdma2csc_dat_wr_valid = use_img_path ? img2cvt_dat_wr_en :
                               use_wg_path ? wg2cvt_dat_wr_en : 1'b0;
assign cdma2csc_dat_wr_addr = use_img_path ? img2cvt_dat_wr_addr :
                              use_wg_path ? wg2cvt_dat_wr_addr : 12'd0;
assign cdma2csc_dat_wr_data = use_img_path ? img2cvt_dat_wr_data :
                              use_wg_path ? {512'd0, wg2cvt_dat_wr_data} : 1024'd0;
assign cdma2csc_dat_wr_be = 8'hFF;  // All bytes valid

// Select status
assign current_status = use_img_path ? img2status_state :
                        use_wg_path ? wg2status_state : 2'd0;

// Done interrupt generation
assign cdma_done = (current_status == 2'd2);  // Done state
assign cdma2glb_done_intr = {cdma_done, cdma_done};
assign cdma2csc_status_valid = img2status_dat_updt || wg2status_dat_updt;
assign cdma2csc_status = current_status;

// NaN/Inf counter aggregation
assign dp2reg_d0_nan_data_num = dp2reg_img_rd_latency[15:0] + dp2reg_wg_rd_latency[15:0];
assign dp2reg_d0_inf_data_num = dp2reg_img_rd_stall[15:0] + dp2reg_wg_rd_stall[15:0];
assign dp2reg_d0_dat_rd_latency = dp2reg_img_rd_latency;
assign dp2reg_d0_dat_rd_stall = dp2reg_img_rd_stall;

endmodule // NV_NVDLA_CDMA_new