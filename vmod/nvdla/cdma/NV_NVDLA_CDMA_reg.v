// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_CDMA_reg.v
// Author: Claude
// Description:
// CDMA Register File Module with CSB interface
// Handles register read/write at address offsets via CSB protocol

// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_reg.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA Register File Module
// - CSB (Command and Status Bus) register access interface
// - Supports read/write operations to all CDMA configuration
//   and status registers
// - Key registers: Group 0 (D0) and Group 1 (D1) register sets
//   for duplicate configuration, plus shared single registers
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_reg (
   // CSB interface
   csb_clk
  ,csb_rstn
  ,csb_addr
  ,csb_wdat
  ,csb_rd_en
  ,csb_wr_en
  ,csb_rdat
  ,npu_rdy
  // Datapath outputs - Shared/Single registers
  ,reg2dp_arb_weight
  ,reg2dp_arb_wmb
  ,reg2dp_producer
  ,reg2dp_consumer
  // Status inputs
  ,dp2reg_status_0
  ,dp2reg_status_1
  ,dp2reg_flush_done
  // Datapath outputs - Group 0 (D0) registers
  ,reg2dp_d0_op_en
  ,reg2dp_d0_data_bank
  ,reg2dp_d0_weight_bank
  ,reg2dp_d0_batches
  ,reg2dp_d0_batch_stride
  ,reg2dp_d0_conv_x_stride
  ,reg2dp_d0_conv_y_stride
  ,reg2dp_d0_cvt_en
  ,reg2dp_d0_cvt_truncate
  ,reg2dp_d0_cvt_offset
  ,reg2dp_d0_cvt_scale
  ,reg2dp_d0_cya
  ,reg2dp_d0_datain_addr_high_0
  ,reg2dp_d0_datain_addr_high_1
  ,reg2dp_d0_datain_addr_low_0
  ,reg2dp_d0_datain_addr_low_1
  ,reg2dp_d0_line_packed
  ,reg2dp_d0_surf_packed
  ,reg2dp_d0_datain_ram_type
  ,reg2dp_d0_datain_format
  ,reg2dp_d0_pixel_format
  ,reg2dp_d0_pixel_mapping
  ,reg2dp_d0_pixel_sign_override
  ,reg2dp_d0_datain_height
  ,reg2dp_d0_datain_width
  ,reg2dp_d0_datain_channel
  ,reg2dp_d0_datain_height_ext
  ,reg2dp_d0_datain_width_ext
  ,reg2dp_d0_entries
  ,reg2dp_d0_grains
  ,reg2dp_d0_line_stride
  ,reg2dp_d0_uv_line_stride
  ,reg2dp_d0_mean_format
  ,reg2dp_d0_mean_gu
  ,reg2dp_d0_mean_ry
  ,reg2dp_d0_mean_ax
  ,reg2dp_d0_mean_bv
  ,reg2dp_d0_conv_mode
  ,reg2dp_d0_data_reuse
  ,reg2dp_d0_in_precision
  ,reg2dp_d0_proc_precision
  ,reg2dp_d0_skip_data_rls
  ,reg2dp_d0_skip_weight_rls
  ,reg2dp_d0_weight_reuse
  ,reg2dp_d0_nan_to_zero
  ,reg2dp_d0_op_en_trigger
  ,reg2dp_d0_dma_en
  ,reg2dp_d0_pixel_x_offset
  ,reg2dp_d0_pixel_y_offset
  ,reg2dp_d0_rsv_per_line
  ,reg2dp_d0_rsv_per_uv_line
  ,reg2dp_d0_rsv_height
  ,reg2dp_d0_rsv_y_index
  ,reg2dp_d0_surf_stride
  ,reg2dp_d0_weight_addr_high
  ,reg2dp_d0_weight_addr_low
  ,reg2dp_d0_weight_bytes
  ,reg2dp_d0_weight_format
  ,reg2dp_d0_weight_ram_type
  ,reg2dp_d0_byte_per_kernel
  ,reg2dp_d0_weight_kernel
  ,reg2dp_d0_wgs_addr_high
  ,reg2dp_d0_wgs_addr_low
  ,reg2dp_d0_wmb_addr_high
  ,reg2dp_d0_wmb_addr_low
  ,reg2dp_d0_wmb_bytes
  ,reg2dp_d0_pad_bottom
  ,reg2dp_d0_pad_left
  ,reg2dp_d0_pad_right
  ,reg2dp_d0_pad_top
  ,reg2dp_d0_pad_value
  // Status inputs - Group 0
  ,dp2reg_d0_inf_data_num
  ,dp2reg_d0_inf_weight_num
  ,dp2reg_d0_nan_data_num
  ,dp2reg_d0_nan_weight_num
  ,dp2reg_d0_dat_rd_latency
  ,dp2reg_d0_dat_rd_stall
  ,dp2reg_d0_wt_rd_latency
  ,dp2reg_d0_wt_rd_stall
  // Datapath outputs - Group 1 (D1) registers
  ,reg2dp_d1_op_en
  ,reg2dp_d1_data_bank
  ,reg2dp_d1_weight_bank
  ,reg2dp_d1_batches
  ,reg2dp_d1_batch_stride
  ,reg2dp_d1_conv_x_stride
  ,reg2dp_d1_conv_y_stride
  ,reg2dp_d1_cvt_en
  ,reg2dp_d1_cvt_truncate
  ,reg2dp_d1_cvt_offset
  ,reg2dp_d1_cvt_scale
  ,reg2dp_d1_cya
  ,reg2dp_d1_datain_addr_high_0
  ,reg2dp_d1_datain_addr_high_1
  ,reg2dp_d1_datain_addr_low_0
  ,reg2dp_d1_datain_addr_low_1
  ,reg2dp_d1_line_packed
  ,reg2dp_d1_surf_packed
  ,reg2dp_d1_datain_ram_type
  ,reg2dp_d1_datain_format
  ,reg2dp_d1_pixel_format
  ,reg2dp_d1_pixel_mapping
  ,reg2dp_d1_pixel_sign_override
  ,reg2dp_d1_datain_height
  ,reg2dp_d1_datain_width
  ,reg2dp_d1_datain_channel
  ,reg2dp_d1_datain_height_ext
  ,reg2dp_d1_datain_width_ext
  ,reg2dp_d1_entries
  ,reg2dp_d1_grains
  ,reg2dp_d1_line_stride
  ,reg2dp_d1_uv_line_stride
  ,reg2dp_d1_mean_format
  ,reg2dp_d1_mean_gu
  ,reg2dp_d1_mean_ry
  ,reg2dp_d1_mean_ax
  ,reg2dp_d1_mean_bv
  ,reg2dp_d1_conv_mode
  ,reg2dp_d1_data_reuse
  ,reg2dp_d1_in_precision
  ,reg2dp_d1_proc_precision
  ,reg2dp_d1_skip_data_rls
  ,reg2dp_d1_skip_weight_rls
  ,reg2dp_d1_weight_reuse
  ,reg2dp_d1_nan_to_zero
  ,reg2dp_d1_op_en_trigger
  ,reg2dp_d1_dma_en
  ,reg2dp_d1_pixel_x_offset
  ,reg2dp_d1_pixel_y_offset
  ,reg2dp_d1_rsv_per_line
  ,reg2dp_d1_rsv_per_uv_line
  ,reg2dp_d1_rsv_height
  ,reg2dp_d1_rsv_y_index
  ,reg2dp_d1_surf_stride
  ,reg2dp_d1_weight_addr_high
  ,reg2dp_d1_weight_addr_low
  ,reg2dp_d1_weight_bytes
  ,reg2dp_d1_weight_format
  ,reg2dp_d1_weight_ram_type
  ,reg2dp_d1_byte_per_kernel
  ,reg2dp_d1_weight_kernel
  ,reg2dp_d1_wgs_addr_high
  ,reg2dp_d1_wgs_addr_low
  ,reg2dp_d1_wmb_addr_high
  ,reg2dp_d1_wmb_addr_low
  ,reg2dp_d1_wmb_bytes
  ,reg2dp_d1_pad_bottom
  ,reg2dp_d1_pad_left
  ,reg2dp_d1_pad_right
  ,reg2dp_d1_pad_top
  ,reg2dp_d1_pad_value
  // Status inputs - Group 1
  ,dp2reg_d1_inf_data_num
  ,dp2reg_d1_inf_weight_num
  ,dp2reg_d1_nan_data_num
  ,dp2reg_d1_nan_weight_num
  ,dp2reg_d1_dat_rd_latency
  ,dp2reg_d1_dat_rd_stall
  ,dp2reg_d1_wt_rd_latency
  ,dp2reg_d1_wt_rd_stall
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// CSB interface
input         csb_clk;
input         csb_rstn;
input  [11:0] csb_addr;
input  [31:0] csb_wdat;
input         csb_rd_en;
input         csb_wr_en;
output [31:0] csb_rdat;
output        npu_rdy;

// Shared/Single datapath outputs
output  [3:0] reg2dp_arb_weight;
output  [3:0] reg2dp_arb_wmb;
output        reg2dp_producer;
input         reg2dp_consumer;
input  [1:0]  dp2reg_status_0;
input  [1:0]  dp2reg_status_1;
input         dp2reg_flush_done;

// Group 0 (D0) datapath outputs
output        reg2dp_d0_op_en;
output  [3:0] reg2dp_d0_data_bank;
output  [3:0] reg2dp_d0_weight_bank;
output  [4:0] reg2dp_d0_batches;
output [26:0] reg2dp_d0_batch_stride;
output  [2:0] reg2dp_d0_conv_x_stride;
output  [2:0] reg2dp_d0_conv_y_stride;
output        reg2dp_d0_cvt_en;
output  [5:0] reg2dp_d0_cvt_truncate;
output [15:0] reg2dp_d0_cvt_offset;
output [15:0] reg2dp_d0_cvt_scale;
output [31:0] reg2dp_d0_cya;
output [31:0] reg2dp_d0_datain_addr_high_0;
output [31:0] reg2dp_d0_datain_addr_high_1;
output [26:0] reg2dp_d0_datain_addr_low_0;
output [26:0] reg2dp_d0_datain_addr_low_1;
output        reg2dp_d0_line_packed;
output        reg2dp_d0_surf_packed;
output        reg2dp_d0_datain_ram_type;
output        reg2dp_d0_datain_format;
output  [5:0] reg2dp_d0_pixel_format;
output        reg2dp_d0_pixel_mapping;
output        reg2dp_d0_pixel_sign_override;
output [12:0] reg2dp_d0_datain_height;
output [12:0] reg2dp_d0_datain_width;
output [12:0] reg2dp_d0_datain_channel;
output [12:0] reg2dp_d0_datain_height_ext;
output [12:0] reg2dp_d0_datain_width_ext;
output [11:0] reg2dp_d0_entries;
output [11:0] reg2dp_d0_grains;
output [26:0] reg2dp_d0_line_stride;
output [26:0] reg2dp_d0_uv_line_stride;
output        reg2dp_d0_mean_format;
output [15:0] reg2dp_d0_mean_gu;
output [15:0] reg2dp_d0_mean_ry;
output [15:0] reg2dp_d0_mean_ax;
output [15:0] reg2dp_d0_mean_bv;
output        reg2dp_d0_conv_mode;
output        reg2dp_d0_data_reuse;
output  [1:0] reg2dp_d0_in_precision;
output  [1:0] reg2dp_d0_proc_precision;
output        reg2dp_d0_skip_data_rls;
output        reg2dp_d0_skip_weight_rls;
output        reg2dp_d0_weight_reuse;
output        reg2dp_d0_nan_to_zero;
output        reg2dp_d0_op_en_trigger;
output        reg2dp_d0_dma_en;
output  [4:0] reg2dp_d0_pixel_x_offset;
output  [2:0] reg2dp_d0_pixel_y_offset;
output  [9:0] reg2dp_d0_rsv_per_line;
output  [9:0] reg2dp_d0_rsv_per_uv_line;
output  [2:0] reg2dp_d0_rsv_height;
output  [4:0] reg2dp_d0_rsv_y_index;
output [26:0] reg2dp_d0_surf_stride;
output [31:0] reg2dp_d0_weight_addr_high;
output [26:0] reg2dp_d0_weight_addr_low;
output [24:0] reg2dp_d0_weight_bytes;
output        reg2dp_d0_weight_format;
output        reg2dp_d0_weight_ram_type;
output [17:0] reg2dp_d0_byte_per_kernel;
output [12:0] reg2dp_d0_weight_kernel;
output [31:0] reg2dp_d0_wgs_addr_high;
output [26:0] reg2dp_d0_wgs_addr_low;
output [31:0] reg2dp_d0_wmb_addr_high;
output [26:0] reg2dp_d0_wmb_addr_low;
output [20:0] reg2dp_d0_wmb_bytes;
output  [5:0] reg2dp_d0_pad_bottom;
output  [4:0] reg2dp_d0_pad_left;
output  [5:0] reg2dp_d0_pad_right;
output  [4:0] reg2dp_d0_pad_top;
output [15:0] reg2dp_d0_pad_value;

// Group 0 status inputs
input  [31:0] dp2reg_d0_inf_data_num;
input  [31:0] dp2reg_d0_inf_weight_num;
input  [31:0] dp2reg_d0_nan_data_num;
input  [31:0] dp2reg_d0_nan_weight_num;
input  [31:0] dp2reg_d0_dat_rd_latency;
input  [31:0] dp2reg_d0_dat_rd_stall;
input  [31:0] dp2reg_d0_wt_rd_latency;
input  [31:0] dp2reg_d0_wt_rd_stall;

// Group 1 (D1) datapath outputs
output        reg2dp_d1_op_en;
output  [3:0] reg2dp_d1_data_bank;
output  [3:0] reg2dp_d1_weight_bank;
output  [4:0] reg2dp_d1_batches;
output [26:0] reg2dp_d1_batch_stride;
output  [2:0] reg2dp_d1_conv_x_stride;
output  [2:0] reg2dp_d1_conv_y_stride;
output        reg2dp_d1_cvt_en;
output  [5:0] reg2dp_d1_cvt_truncate;
output [15:0] reg2dp_d1_cvt_offset;
output [15:0] reg2dp_d1_cvt_scale;
output [31:0] reg2dp_d1_cya;
output [31:0] reg2dp_d1_datain_addr_high_0;
output [31:0] reg2dp_d1_datain_addr_high_1;
output [26:0] reg2dp_d1_datain_addr_low_0;
output [26:0] reg2dp_d1_datain_addr_low_1;
output        reg2dp_d1_line_packed;
output        reg2dp_d1_surf_packed;
output        reg2dp_d1_datain_ram_type;
output        reg2dp_d1_datain_format;
output  [5:0] reg2dp_d1_pixel_format;
output        reg2dp_d1_pixel_mapping;
output        reg2dp_d1_pixel_sign_override;
output [12:0] reg2dp_d1_datain_height;
output [12:0] reg2dp_d1_datain_width;
output [12:0] reg2dp_d1_datain_channel;
output [12:0] reg2dp_d1_datain_height_ext;
output [12:0] reg2dp_d1_datain_width_ext;
output [11:0] reg2dp_d1_entries;
output [11:0] reg2dp_d1_grains;
output [26:0] reg2dp_d1_line_stride;
output [26:0] reg2dp_d1_uv_line_stride;
output        reg2dp_d1_mean_format;
output [15:0] reg2dp_d1_mean_gu;
output [15:0] reg2dp_d1_mean_ry;
output [15:0] reg2dp_d1_mean_ax;
output [15:0] reg2dp_d1_mean_bv;
output        reg2dp_d1_conv_mode;
output        reg2dp_d1_data_reuse;
output  [1:0] reg2dp_d1_in_precision;
output  [1:0] reg2dp_d1_proc_precision;
output        reg2dp_d1_skip_data_rls;
output        reg2dp_d1_skip_weight_rls;
output        reg2dp_d1_weight_reuse;
output        reg2dp_d1_nan_to_zero;
output        reg2dp_d1_op_en_trigger;
output        reg2dp_d1_dma_en;
output  [4:0] reg2dp_d1_pixel_x_offset;
output  [2:0] reg2dp_d1_pixel_y_offset;
output  [9:0] reg2dp_d1_rsv_per_line;
output  [9:0] reg2dp_d1_rsv_per_uv_line;
output  [2:0] reg2dp_d1_rsv_height;
output  [4:0] reg2dp_d1_rsv_y_index;
output [26:0] reg2dp_d1_surf_stride;
output [31:0] reg2dp_d1_weight_addr_high;
output [26:0] reg2dp_d1_weight_addr_low;
output [24:0] reg2dp_d1_weight_bytes;
output        reg2dp_d1_weight_format;
output        reg2dp_d1_weight_ram_type;
output [17:0] reg2dp_d1_byte_per_kernel;
output [12:0] reg2dp_d1_weight_kernel;
output [31:0] reg2dp_d1_wgs_addr_high;
output [26:0] reg2dp_d1_wgs_addr_low;
output [31:0] reg2dp_d1_wmb_addr_high;
output [26:0] reg2dp_d1_wmb_addr_low;
output [20:0] reg2dp_d1_wmb_bytes;
output  [5:0] reg2dp_d1_pad_bottom;
output  [4:0] reg2dp_d1_pad_left;
output  [5:0] reg2dp_d1_pad_right;
output  [4:0] reg2dp_d1_pad_top;
output [15:0] reg2dp_d1_pad_value;

// Group 1 status inputs
input  [31:0] dp2reg_d1_inf_data_num;
input  [31:0] dp2reg_d1_inf_weight_num;
input  [31:0] dp2reg_d1_nan_data_num;
input  [31:0] dp2reg_d1_nan_weight_num;
input  [31:0] dp2reg_d1_dat_rd_latency;
input  [31:0] dp2reg_d1_dat_rd_stall;
input  [31:0] dp2reg_d1_wt_rd_latency;
input  [31:0] dp2reg_d1_wt_rd_stall;

//===============================================================
// PARAMETERS
//===============================================================
// Single register group addresses (base 0x5000)
parameter [11:0] REG_STATUS_0         = 12'h000;  // 0x5000
parameter [11:0] REG_POINTER_0        = 12'h004;  // 0x5004
parameter [11:0] REG_ARBITER_0        = 12'h008;  // 0x5008
parameter [11:0] REG_CBUF_FLUSH_STATUS = 12'h00C;  // 0x500C

// Dual register group 0 addresses (base 0x5000)
parameter [11:0] REG_D0_OP_ENABLE     = 12'h010;  // 0x5010
parameter [11:0] REG_D0_MISC_CFG      = 12'h014;  // 0x5014
parameter [11:0] REG_D0_DATAIN_FORMAT  = 12'h018;  // 0x5018
parameter [11:0] REG_D0_DATAIN_SIZE_0  = 12'h01C;  // 0x501C
parameter [11:0] REG_D0_DATAIN_SIZE_1  = 12'h020;  // 0x5020
parameter [11:0] REG_D0_DATAIN_SIZE_EXT_0 = 12'h024; // 0x5024
parameter [11:0] REG_D0_PIXEL_OFFSET   = 12'h028;  // 0x5028
parameter [11:0] REG_D0_DAIN_RAM_TYPE  = 12'h02C;  // 0x502C
parameter [11:0] REG_D0_DAIN_ADDR_HIGH_0 = 12'h030; // 0x5030
parameter [11:0] REG_D0_DAIN_ADDR_LOW_0 = 12'h034; // 0x5034
parameter [11:0] REG_D0_DAIN_ADDR_HIGH_1 = 12'h038; // 0x5038
parameter [11:0] REG_D0_DAIN_ADDR_LOW_1 = 12'h03C; // 0x503C
parameter [11:0] REG_D0_LINE_STRIDE     = 12'h040;  // 0x5040
parameter [11:0] REG_D0_LINE_UV_STRIDE = 12'h044;  // 0x5044
parameter [11:0] REG_D0_SURF_STRIDE     = 12'h048;  // 0x5048
parameter [11:0] REG_D0_DAIN_MAP       = 12'h04C;  // 0x504C
parameter [11:0] REG_D0_RSV_X_CFG      = 12'h050;  // 0x5050
parameter [11:0] REG_D0_RSV_Y_CFG      = 12'h054;  // 0x5054
parameter [11:0] REG_D0_BATCH_NUMBER   = 12'h058;  // 0x5058
parameter [11:0] REG_D0_BATCH_STRIDE   = 12'h05C;  // 0x505C
parameter [11:0] REG_D0_ENTRY_PER_SLICE = 12'h060;  // 0x5060
parameter [11:0] REG_D0_FETCH_GRAIN    = 12'h064;  // 0x5064
parameter [11:0] REG_D0_WEIGHT_FORMAT  = 12'h068;  // 0x5068
parameter [11:0] REG_D0_WEIGHT_SIZE_1  = 12'h06C;  // 0x506C
parameter [11:0] REG_D0_WEIGHT_RAM_TYPE = 12'h074; // 0x5074
parameter [11:0] REG_D0_WEIGHT_ADDR_HIGH = 12'h078; // 0x5078
parameter [11:0] REG_D0_WEIGHT_ADDR_LOW = 12'h07C; // 0x507C
parameter [11:0] REG_D0_WEIGHT_BYTES    = 12'h080;  // 0x5080
parameter [11:0] REG_D0_WGS_ADDR_HIGH  = 12'h084;  // 0x5084
parameter [11:0] REG_D0_WGS_ADDR_LOW   = 12'h088;  // 0x5088
parameter [11:0] REG_D0_WMB_ADDR_HIGH  = 12'h08C;  // 0x508C
parameter [11:0] REG_D0_WMB_ADDR_LOW   = 12'h090;  // 0x5090
parameter [11:0] REG_D0_WMB_BYTES      = 12'h094;  // 0x5094
parameter [11:0] REG_D0_MEAN_FORMAT    = 12'h098;  // 0x5098
parameter [11:0] REG_D0_MEAN_GLOBAL_0  = 12'h09C;  // 0x509C
parameter [11:0] REG_D0_MEAN_GLOBAL_1  = 12'h0A0;  // 0x50A0
parameter [11:0] REG_D0_CVT_CFG        = 12'h0A4;  // 0x50A4
parameter [11:0] REG_D0_CVT_OFFSET     = 12'h0A8;  // 0x50A8
parameter [11:0] REG_D0_CVT_SCALE      = 12'h0AC;  // 0x50AC
parameter [11:0] REG_D0_CONV_STRIDE    = 12'h0B0;  // 0x50B0
parameter [11:0] REG_D0_ZERO_PADDING   = 12'h0B4;  // 0x50B4
parameter [11:0] REG_D0_ZERO_PADDING_VALUE = 12'h0B8; // 0x50B8
parameter [11:0] REG_D0_BANK           = 12'h0BC;  // 0x50BC
parameter [11:0] REG_D0_NAN_FLUSH_TO_ZERO = 12'h0C0; // 0x50C0
parameter [11:0] REG_D0_NAN_INPUT_DATA_NUM = 12'h0C4; // 0x50C4
parameter [11:0] REG_D0_NAN_INPUT_WEIGHT_NUM = 12'h0C8; // 0x50C8
parameter [11:0] REG_D0_INF_INPUT_DATA_NUM = 12'h0CC; // 0x50CC
parameter [11:0] REG_D0_INF_INPUT_WEIGHT_NUM = 12'h0D0; // 0x50D0
parameter [11:0] REG_D0_PERF_ENABLE   = 12'h0D4;  // 0x50D4
parameter [11:0] REG_D0_PERF_DAT_READ_STALL = 12'h0D8; // 0x50D8
parameter [11:0] REG_D0_PERF_WT_READ_STALL = 12'h0DC; // 0x50DC
parameter [11:0] REG_D0_PERF_DAT_READ_LATENCY = 12'h0E0; // 0x50E0
parameter [11:0] REG_D0_PERF_WT_READ_LATENCY = 12'h0E4; // 0x50E4
parameter [11:0] REG_D0_CYA            = 12'h0E8;  // 0x50E8

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// Write enable decode - Single registers
wire        reg_status_0_wren;
wire        reg_pointer_0_wren;
wire        reg_arbiter_0_wren;
wire        reg_cbuf_flush_status_wren;

// Write enable decode - D0 registers
wire        d0_op_enable_wren;
wire        d0_misc_cfg_wren;
wire        d0_datain_format_wren;
wire        d0_datain_size_0_wren;
wire        d0_datain_size_1_wren;
wire        d0_datain_size_ext_0_wren;
wire        d0_pixel_offset_wren;
wire        d0_dain_ram_type_wren;
wire        d0_dain_addr_high_0_wren;
wire        d0_dain_addr_low_0_wren;
wire        d0_dain_addr_high_1_wren;
wire        d0_dain_addr_low_1_wren;
wire        d0_line_stride_wren;
wire        d0_line_uv_stride_wren;
wire        d0_surf_stride_wren;
wire        d0_dain_map_wren;
wire        d0_rsv_x_cfg_wren;
wire        d0_rsv_y_cfg_wren;
wire        d0_batch_number_wren;
wire        d0_batch_stride_wren;
wire        d0_entry_per_slice_wren;
wire        d0_fetch_grain_wren;
wire        d0_weight_format_wren;
wire        d0_weight_size_1_wren;
wire        d0_weight_ram_type_wren;
wire        d0_weight_addr_high_wren;
wire        d0_weight_addr_low_wren;
wire        d0_weight_bytes_wren;
wire        d0_wgs_addr_high_wren;
wire        d0_wgs_addr_low_wren;
wire        d0_wmb_addr_high_wren;
wire        d0_wmb_addr_low_wren;
wire        d0_wmb_bytes_wren;
wire        d0_mean_format_wren;
wire        d0_mean_global_0_wren;
wire        d0_mean_global_1_wren;
wire        d0_cvt_cfg_wren;
wire        d0_cvt_offset_wren;
wire        d0_cvt_scale_wren;
wire        d0_conv_stride_wren;
wire        d0_zero_padding_wren;
wire        d0_zero_padding_value_wren;
wire        d0_bank_wren;
wire        d0_nan_flush_to_zero_wren;
wire        d0_nan_input_data_num_wren;
wire        d0_nan_input_weight_num_wren;
wire        d0_inf_input_data_num_wren;
wire        d0_inf_input_weight_num_wren;
wire        d0_perf_enable_wren;
wire        d0_perf_dat_read_stall_wren;
wire        d0_perf_wt_read_stall_wren;
wire        d0_perf_dat_read_latency_wren;
wire        d0_perf_wt_read_latency_wren;
wire        d0_cya_wren;

// Read data wires
wire [31:0] reg_status_0_rdat;
wire [31:0] reg_pointer_0_rdat;
wire [31:0] reg_arbiter_0_rdat;
wire [31:0] reg_cbuf_flush_status_rdat;
wire [31:0] d0_op_enable_rdat;
wire [31:0] d0_misc_cfg_rdat;
wire [31:0] d0_datain_format_rdat;
wire [31:0] d0_datain_size_0_rdat;
wire [31:0] d0_datain_size_1_rdat;
wire [31:0] d0_datain_size_ext_0_rdat;
wire [31:0] d0_pixel_offset_rdat;
wire [31:0] d0_dain_ram_type_rdat;
wire [31:0] d0_dain_addr_high_0_rdat;
wire [31:0] d0_dain_addr_low_0_rdat;
wire [31:0] d0_dain_addr_high_1_rdat;
wire [31:0] d0_dain_addr_low_1_rdat;
wire [31:0] d0_line_stride_rdat;
wire [31:0] d0_line_uv_stride_rdat;
wire [31:0] d0_surf_stride_rdat;
wire [31:0] d0_dain_map_rdat;
wire [31:0] d0_rsv_x_cfg_rdat;
wire [31:0] d0_rsv_y_cfg_rdat;
wire [31:0] d0_batch_number_rdat;
wire [31:0] d0_batch_stride_rdat;
wire [31:0] d0_entry_per_slice_rdat;
wire [31:0] d0_fetch_grain_rdat;
wire [31:0] d0_weight_format_rdat;
wire [31:0] d0_weight_size_1_rdat;
wire [31:0] d0_weight_ram_type_rdat;
wire [31:0] d0_weight_addr_high_rdat;
wire [31:0] d0_weight_addr_low_rdat;
wire [31:0] d0_weight_bytes_rdat;
wire [31:0] d0_wgs_addr_high_rdat;
wire [31:0] d0_wgs_addr_low_rdat;
wire [31:0] d0_wmb_addr_high_rdat;
wire [31:0] d0_wmb_addr_low_rdat;
wire [31:0] d0_wmb_bytes_rdat;
wire [31:0] d0_mean_format_rdat;
wire [31:0] d0_mean_global_0_rdat;
wire [31:0] d0_mean_global_1_rdat;
wire [31:0] d0_cvt_cfg_rdat;
wire [31:0] d0_cvt_offset_rdat;
wire [31:0] d0_cvt_scale_rdat;
wire [31:0] d0_conv_stride_rdat;
wire [31:0] d0_zero_padding_rdat;
wire [31:0] d0_zero_padding_value_rdat;
wire [31:0] d0_bank_rdat;
wire [31:0] d0_nan_flush_to_zero_rdat;
wire [31:0] d0_nan_input_data_num_rdat;
wire [31:0] d0_nan_input_weight_num_rdat;
wire [31:0] d0_inf_input_data_num_rdat;
wire [31:0] d0_inf_input_weight_num_rdat;
wire [31:0] d0_perf_enable_rdat;
wire [31:0] d0_perf_dat_read_stall_rdat;
wire [31:0] d0_perf_wt_read_stall_rdat;
wire [31:0] d0_perf_dat_read_latency_rdat;
wire [31:0] d0_perf_wt_read_latency_rdat;
wire [31:0] d0_cya_rdat;

// Trigger detection
wire        d0_op_enable_wren_d1;

//===============================================================
// REG DECLARATIONS
//===============================================================
// Single register group
reg  [3:0]  reg_arb_weight_r;
reg  [3:0]  reg_arb_wmb_r;
reg         reg_producer_r;

// D0 register group
reg         d0_op_en_r;
reg         d0_conv_mode_r;
reg  [1:0]  d0_in_precision_r;
reg  [1:0]  d0_proc_precision_r;
reg         d0_data_reuse_r;
reg         d0_weight_reuse_r;
reg         d0_skip_data_rls_r;
reg         d0_skip_weight_rls_r;
reg         d0_nan_to_zero_r;
reg         d0_cvt_en_r;
reg  [5:0]  d0_cvt_truncate_r;
reg         d0_datain_ram_type_r;
reg         d0_datain_format_r;
reg         d0_pixel_mapping_r;
reg         d0_pixel_sign_override_r;
reg  [5:0]  d0_pixel_format_r;
reg         d0_line_packed_r;
reg         d0_surf_packed_r;
reg         d0_mean_format_r;
reg         d0_weight_format_r;
reg         d0_weight_ram_type_r;
reg         d0_dma_en_r;
reg  [3:0]  d0_data_bank_r;
reg  [3:0]  d0_weight_bank_r;
reg  [4:0]  d0_batches_r;
reg  [2:0]  d0_conv_x_stride_r;
reg  [2:0]  d0_conv_y_stride_r;
reg  [2:0]  d0_rsv_height_r;
reg  [4:0]  d0_rsv_y_index_r;
reg  [4:0]  d0_pixel_x_offset_r;
reg  [2:0]  d0_pixel_y_offset_r;
reg  [9:0]  d0_rsv_per_line_r;
reg  [9:0]  d0_rsv_per_uv_line_r;
reg  [5:0]  d0_pad_bottom_r;
reg  [4:0]  d0_pad_left_r;
reg  [5:0]  d0_pad_right_r;
reg  [4:0]  d0_pad_top_r;
reg [12:0]  d0_datain_height_r;
reg [12:0]  d0_datain_width_r;
reg [12:0]  d0_datain_channel_r;
reg [12:0]  d0_datain_height_ext_r;
reg [12:0]  d0_datain_width_ext_r;
reg [11:0]  d0_entries_r;
reg [11:0]  d0_grains_r;
reg [26:0]  d0_batch_stride_r;
reg [26:0]  d0_line_stride_r;
reg [26:0]  d0_uv_line_stride_r;
reg [26:0]  d0_surf_stride_r;
reg [15:0]  d0_cvt_offset_r;
reg [15:0]  d0_cvt_scale_r;
reg [15:0]  d0_mean_gu_r;
reg [15:0]  d0_mean_ry_r;
reg [15:0]  d0_mean_ax_r;
reg [15:0]  d0_mean_bv_r;
reg [15:0]  d0_pad_value_r;
reg [17:0]  d0_byte_per_kernel_r;
reg [12:0]  d0_weight_kernel_r;
reg [24:0]  d0_weight_bytes_r;
reg [26:0]  d0_datain_addr_low_0_r;
reg [26:0]  d0_datain_addr_low_1_r;
reg [31:0]  d0_datain_addr_high_0_r;
reg [31:0]  d0_datain_addr_high_1_r;
reg [26:0]  d0_weight_addr_low_r;
reg [31:0]  d0_weight_addr_high_r;
reg [26:0]  d0_wgs_addr_low_r;
reg [31:0]  d0_wgs_addr_high_r;
reg [26:0]  d0_wmb_addr_low_r;
reg [31:0]  d0_wmb_addr_high_r;
reg [20:0]  d0_wmb_bytes_r;
reg [31:0]  d0_cya_r;

// CSB response
reg  [31:0] csb_rdat_q;

// D0 performance counters (read-only but writable for test)
reg  [31:0] d0_nan_data_num_r;
reg  [31:0] d0_nan_weight_num_r;
reg  [31:0] d0_inf_data_num_r;
reg  [31:0] d0_inf_weight_num_r;
reg  [31:0] d0_dat_rd_latency_r;
reg  [31:0] d0_dat_rd_stall_r;
reg  [31:0] d0_wt_rd_latency_r;
reg  [31:0] d0_wt_rd_stall_r;

//===============================================================
// ADDRESS DECODE - WRITE ENABLE
//===============================================================
// Single register group write enables
assign reg_status_0_wren         = (csb_addr == REG_STATUS_0)         & csb_wr_en;
assign reg_pointer_0_wren         = (csb_addr == REG_POINTER_0)        & csb_wr_en;
assign reg_arbiter_0_wren         = (csb_addr == REG_ARBITER_0)        & csb_wr_en;
assign reg_cbuf_flush_status_wren = (csb_addr == REG_CBUF_FLUSH_STATUS) & csb_wr_en;

// D0 register group write enables
assign d0_op_enable_wren          = (csb_addr == REG_D0_OP_ENABLE)     & csb_wr_en;
assign d0_misc_cfg_wren           = (csb_addr == REG_D0_MISC_CFG)      & csb_wr_en;
assign d0_datain_format_wren      = (csb_addr == REG_D0_DATAIN_FORMAT) & csb_wr_en;
assign d0_datain_size_0_wren     = (csb_addr == REG_D0_DATAIN_SIZE_0) & csb_wr_en;
assign d0_datain_size_1_wren     = (csb_addr == REG_D0_DATAIN_SIZE_1) & csb_wr_en;
assign d0_datain_size_ext_0_wren  = (csb_addr == REG_D0_DATAIN_SIZE_EXT_0) & csb_wr_en;
assign d0_pixel_offset_wren       = (csb_addr == REG_D0_PIXEL_OFFSET)  & csb_wr_en;
assign d0_dain_ram_type_wren     = (csb_addr == REG_D0_DAIN_RAM_TYPE) & csb_wr_en;
assign d0_dain_addr_high_0_wren  = (csb_addr == REG_D0_DAIN_ADDR_HIGH_0) & csb_wr_en;
assign d0_dain_addr_low_0_wren   = (csb_addr == REG_D0_DAIN_ADDR_LOW_0) & csb_wr_en;
assign d0_dain_addr_high_1_wren  = (csb_addr == REG_D0_DAIN_ADDR_HIGH_1) & csb_wr_en;
assign d0_dain_addr_low_1_wren   = (csb_addr == REG_D0_DAIN_ADDR_LOW_1) & csb_wr_en;
assign d0_line_stride_wren         = (csb_addr == REG_D0_LINE_STRIDE)   & csb_wr_en;
assign d0_line_uv_stride_wren     = (csb_addr == REG_D0_LINE_UV_STRIDE) & csb_wr_en;
assign d0_surf_stride_wren        = (csb_addr == REG_D0_SURF_STRIDE)   & csb_wr_en;
assign d0_dain_map_wren          = (csb_addr == REG_D0_DAIN_MAP)      & csb_wr_en;
assign d0_rsv_x_cfg_wren         = (csb_addr == REG_D0_RSV_X_CFG)      & csb_wr_en;
assign d0_rsv_y_cfg_wren         = (csb_addr == REG_D0_RSV_Y_CFG)      & csb_wr_en;
assign d0_batch_number_wren       = (csb_addr == REG_D0_BATCH_NUMBER)  & csb_wr_en;
assign d0_batch_stride_wren       = (csb_addr == REG_D0_BATCH_STRIDE)  & csb_wr_en;
assign d0_entry_per_slice_wren   = (csb_addr == REG_D0_ENTRY_PER_SLICE) & csb_wr_en;
assign d0_fetch_grain_wren        = (csb_addr == REG_D0_FETCH_GRAIN)   & csb_wr_en;
assign d0_weight_format_wren      = (csb_addr == REG_D0_WEIGHT_FORMAT) & csb_wr_en;
assign d0_weight_size_1_wren      = (csb_addr == REG_D0_WEIGHT_SIZE_1) & csb_wr_en;
assign d0_weight_ram_type_wren   = (csb_addr == REG_D0_WEIGHT_RAM_TYPE) & csb_wr_en;
assign d0_weight_addr_high_wren  = (csb_addr == REG_D0_WEIGHT_ADDR_HIGH) & csb_wr_en;
assign d0_weight_addr_low_wren   = (csb_addr == REG_D0_WEIGHT_ADDR_LOW) & csb_wr_en;
assign d0_weight_bytes_wren       = (csb_addr == REG_D0_WEIGHT_BYTES)   & csb_wr_en;
assign d0_wgs_addr_high_wren     = (csb_addr == REG_D0_WGS_ADDR_HIGH) & csb_wr_en;
assign d0_wgs_addr_low_wren      = (csb_addr == REG_D0_WGS_ADDR_LOW)  & csb_wr_en;
assign d0_wmb_addr_high_wren     = (csb_addr == REG_D0_WMB_ADDR_HIGH) & csb_wr_en;
assign d0_wmb_addr_low_wren      = (csb_addr == REG_D0_WMB_ADDR_LOW)  & csb_wr_en;
assign d0_wmb_bytes_wren          = (csb_addr == REG_D0_WMB_BYTES)     & csb_wr_en;
assign d0_mean_format_wren        = (csb_addr == REG_D0_MEAN_FORMAT)   & csb_wr_en;
assign d0_mean_global_0_wren      = (csb_addr == REG_D0_MEAN_GLOBAL_0) & csb_wr_en;
assign d0_mean_global_1_wren      = (csb_addr == REG_D0_MEAN_GLOBAL_1) & csb_wr_en;
assign d0_cvt_cfg_wren            = (csb_addr == REG_D0_CVT_CFG)       & csb_wr_en;
assign d0_cvt_offset_wren         = (csb_addr == REG_D0_CVT_OFFSET)    & csb_wr_en;
assign d0_cvt_scale_wren          = (csb_addr == REG_D0_CVT_SCALE)     & csb_wr_en;
assign d0_conv_stride_wren        = (csb_addr == REG_D0_CONV_STRIDE)   & csb_wr_en;
assign d0_zero_padding_wren       = (csb_addr == REG_D0_ZERO_PADDING)  & csb_wr_en;
assign d0_zero_padding_value_wren = (csb_addr == REG_D0_ZERO_PADDING_VALUE) & csb_wr_en;
assign d0_bank_wren              = (csb_addr == REG_D0_BANK)           & csb_wr_en;
assign d0_nan_flush_to_zero_wren  = (csb_addr == REG_D0_NAN_FLUSH_TO_ZERO) & csb_wr_en;
assign d0_nan_input_data_num_wren = (csb_addr == REG_D0_NAN_INPUT_DATA_NUM) & csb_wr_en;
assign d0_nan_input_weight_num_wren = (csb_addr == REG_D0_NAN_INPUT_WEIGHT_NUM) & csb_wr_en;
assign d0_inf_input_data_num_wren = (csb_addr == REG_D0_INF_INPUT_DATA_NUM) & csb_wr_en;
assign d0_inf_input_weight_num_wren = (csb_addr == REG_D0_INF_INPUT_WEIGHT_NUM) & csb_wr_en;
assign d0_perf_enable_wren        = (csb_addr == REG_D0_PERF_ENABLE)   & csb_wr_en;
assign d0_perf_dat_read_stall_wren = (csb_addr == REG_D0_PERF_DAT_READ_STALL) & csb_wr_en;
assign d0_perf_wt_read_stall_wren = (csb_addr == REG_D0_PERF_WT_READ_STALL) & csb_wr_en;
assign d0_perf_dat_read_latency_wren = (csb_addr == REG_D0_PERF_DAT_READ_LATENCY) & csb_wr_en;
assign d0_perf_wt_read_latency_wren = (csb_addr == REG_D0_PERF_WT_READ_LATENCY) & csb_wr_en;
assign d0_cya_wren                = (csb_addr == REG_D0_CYA)            & csb_wr_en;

//===============================================================
// REGISTER FILE - WRITE LOGIC
//===============================================================
// REG_ARBITER_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    reg_arb_weight_r[3:0] <= 4'b1111;
    reg_arb_wmb_r[3:0] <= 4'b0011;
  end else begin
    if (reg_arbiter_0_wren) begin
      reg_arb_weight_r[3:0] <= csb_wdat[3:0];
      reg_arb_wmb_r[3:0] <= csb_wdat[19:16];
    end
  end
end

// REG_POINTER_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    reg_producer_r <= 1'd0;
  end else begin
    if (reg_pointer_0_wren) begin
      reg_producer_r <= csb_wdat[0];
    end
  end
end

// D0_OP_ENABLE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_op_en_r <= 1'd0;
  end else begin
    if (d0_op_enable_wren) begin
      d0_op_en_r <= csb_wdat[0];
    end
  end
end

// D0_MISC_CFG
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_conv_mode_r <= 1'd0;
    d0_data_reuse_r <= 1'd0;
    d0_weight_reuse_r <= 1'd0;
    d0_skip_data_rls_r <= 1'd0;
    d0_skip_weight_rls_r <= 1'd0;
    d0_proc_precision_r[1:0] <= 2'd0;
    d0_in_precision_r[1:0] <= 2'd0;
  end else begin
    if (d0_misc_cfg_wren) begin
      d0_conv_mode_r <= csb_wdat[0];
      d0_data_reuse_r <= csb_wdat[8];
      d0_weight_reuse_r <= csb_wdat[12];
      d0_skip_data_rls_r <= csb_wdat[16];
      d0_skip_weight_rls_r <= csb_wdat[20];
      d0_proc_precision_r[1:0] <= csb_wdat[26:25];
      d0_in_precision_r[1:0] <= csb_wdat[30:29];
    end
  end
end

// D0_CVT_CFG
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_cvt_en_r <= 1'd0;
    d0_cvt_truncate_r[5:0] <= 6'd0;
  end else begin
    if (d0_cvt_cfg_wren) begin
      d0_cvt_en_r <= csb_wdat[0];
      d0_cvt_truncate_r[5:0] <= csb_wdat[26:21];
    end
  end
end

// D0_CVT_OFFSET
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_cvt_offset_r[15:0] <= 16'd0;
  end else begin
    if (d0_cvt_offset_wren) begin
      d0_cvt_offset_r[15:0] <= csb_wdat[15:0];
    end
  end
end

// D0_CVT_SCALE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_cvt_scale_r[15:0] <= 16'd0;
  end else begin
    if (d0_cvt_scale_wren) begin
      d0_cvt_scale_r[15:0] <= csb_wdat[15:0];
    end
  end
end

// D0_BANK
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_data_bank_r[3:0] <= 4'd0;
    d0_weight_bank_r[3:0] <= 4'd0;
  end else begin
    if (d0_bank_wren) begin
      d0_data_bank_r[3:0] <= csb_wdat[3:0];
      d0_weight_bank_r[3:0] <= csb_wdat[19:16];
    end
  end
end

// D0_BATCH_NUMBER
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_batches_r[4:0] <= 5'd0;
  end else begin
    if (d0_batch_number_wren) begin
      d0_batches_r[4:0] <= csb_wdat[4:0];
    end
  end
end

// D0_BATCH_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_batch_stride_r[26:0] <= 27'd0;
  end else begin
    if (d0_batch_stride_wren) begin
      d0_batch_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_CONV_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_conv_x_stride_r[2:0] <= 3'd0;
    d0_conv_y_stride_r[2:0] <= 3'd0;
  end else begin
    if (d0_conv_stride_wren) begin
      d0_conv_x_stride_r[2:0] <= csb_wdat[2:0];
      d0_conv_y_stride_r[2:0] <= csb_wdat[18:16];
    end
  end
end

// D0_DAIN_RAM_TYPE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_ram_type_r <= 1'd0;
  end else begin
    if (d0_dain_ram_type_wren) begin
      d0_datain_ram_type_r <= csb_wdat[0];
    end
  end
end

// D0_DATAIN_FORMAT
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_format_r <= 1'd0;
    d0_pixel_format_r[5:0] <= 6'd0;
    d0_pixel_mapping_r <= 1'd0;
    d0_pixel_sign_override_r <= 1'd0;
  end else begin
    if (d0_datain_format_wren) begin
      d0_datain_format_r <= csb_wdat[0];
      d0_pixel_format_r[5:0] <= csb_wdat[10:5];
      d0_pixel_mapping_r <= csb_wdat[14];
      d0_pixel_sign_override_r <= csb_wdat[19];
    end
  end
end

// D0_DATAIN_SIZE_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_height_r[12:0] <= 13'd0;
    d0_datain_width_r[12:0] <= 13'd0;
  end else begin
    if (d0_datain_size_0_wren) begin
      d0_datain_height_r[12:0] <= csb_wdat[12:0];
      d0_datain_width_r[12:0] <= csb_wdat[28:16];
    end
  end
end

// D0_DATAIN_SIZE_1
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_channel_r[12:0] <= 13'd0;
  end else begin
    if (d0_datain_size_1_wren) begin
      d0_datain_channel_r[12:0] <= csb_wdat[12:0];
    end
  end
end

// D0_DATAIN_SIZE_EXT_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_height_ext_r[12:0] <= 13'd0;
    d0_datain_width_ext_r[12:0] <= 13'd0;
  end else begin
    if (d0_datain_size_ext_0_wren) begin
      d0_datain_height_ext_r[12:0] <= csb_wdat[12:0];
      d0_datain_width_ext_r[12:0] <= csb_wdat[28:16];
    end
  end
end

// D0_PIXEL_OFFSET
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_pixel_x_offset_r[4:0] <= 5'd0;
    d0_pixel_y_offset_r[2:0] <= 3'd0;
  end else begin
    if (d0_pixel_offset_wren) begin
      d0_pixel_x_offset_r[4:0] <= csb_wdat[4:0];
      d0_pixel_y_offset_r[2:0] <= csb_wdat[18:16];
    end
  end
end

// D0_DAIN_ADDR_HIGH_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_addr_high_0_r[31:0] <= 32'd0;
  end else begin
    if (d0_dain_addr_high_0_wren) begin
      d0_datain_addr_high_0_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// D0_DAIN_ADDR_LOW_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_addr_low_0_r[26:0] <= 27'd0;
  end else begin
    if (d0_dain_addr_low_0_wren) begin
      d0_datain_addr_low_0_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_DAIN_ADDR_HIGH_1
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_addr_high_1_r[31:0] <= 32'd0;
  end else begin
    if (d0_dain_addr_high_1_wren) begin
      d0_datain_addr_high_1_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// D0_DAIN_ADDR_LOW_1
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_datain_addr_low_1_r[26:0] <= 27'd0;
  end else begin
    if (d0_dain_addr_low_1_wren) begin
      d0_datain_addr_low_1_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_LINE_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_line_stride_r[26:0] <= 27'd0;
  end else begin
    if (d0_line_stride_wren) begin
      d0_line_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_LINE_UV_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_uv_line_stride_r[26:0] <= 27'd0;
  end else begin
    if (d0_line_uv_stride_wren) begin
      d0_uv_line_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_SURF_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_surf_stride_r[26:0] <= 27'd0;
  end else begin
    if (d0_surf_stride_wren) begin
      d0_surf_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_DAIN_MAP
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_line_packed_r <= 1'd0;
    d0_surf_packed_r <= 1'd0;
  end else begin
    if (d0_dain_map_wren) begin
      d0_line_packed_r <= csb_wdat[0];
      d0_surf_packed_r <= csb_wdat[16];
    end
  end
end

// D0_RSV_X_CFG
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_rsv_per_line_r[9:0] <= 10'd0;
    d0_rsv_per_uv_line_r[9:0] <= 10'd0;
  end else begin
    if (d0_rsv_x_cfg_wren) begin
      d0_rsv_per_line_r[9:0] <= csb_wdat[9:0];
      d0_rsv_per_uv_line_r[9:0] <= csb_wdat[25:16];
    end
  end
end

// D0_RSV_Y_CFG
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_rsv_height_r[2:0] <= 3'd0;
    d0_rsv_y_index_r[4:0] <= 5'd0;
  end else begin
    if (d0_rsv_y_cfg_wren) begin
      d0_rsv_height_r[2:0] <= csb_wdat[2:0];
      d0_rsv_y_index_r[4:0] <= csb_wdat[15:11];
    end
  end
end

// D0_ENTRY_PER_SLICE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_entries_r[11:0] <= 12'd0;
  end else begin
    if (d0_entry_per_slice_wren) begin
      d0_entries_r[11:0] <= csb_wdat[11:0];
    end
  end
end

// D0_FETCH_GRAIN
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_grains_r[11:0] <= 12'd0;
  end else begin
    if (d0_fetch_grain_wren) begin
      d0_grains_r[11:0] <= csb_wdat[11:0];
    end
  end
end

// D0_WEIGHT_FORMAT
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_weight_format_r <= 1'd0;
  end else begin
    if (d0_weight_format_wren) begin
      d0_weight_format_r <= csb_wdat[0];
    end
  end
end

// D0_WEIGHT_RAM_TYPE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_weight_ram_type_r <= 1'd0;
  end else begin
    if (d0_weight_ram_type_wren) begin
      d0_weight_ram_type_r <= csb_wdat[0];
    end
  end
end

// D0_WEIGHT_SIZE_1
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_weight_kernel_r[12:0] <= 13'd0;
  end else begin
    if (d0_weight_size_1_wren) begin
      d0_weight_kernel_r[12:0] <= csb_wdat[12:0];
    end
  end
end

// D0_WEIGHT_ADDR_HIGH
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_weight_addr_high_r[31:0] <= 32'd0;
  end else begin
    if (d0_weight_addr_high_wren) begin
      d0_weight_addr_high_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// D0_WEIGHT_ADDR_LOW
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_weight_addr_low_r[26:0] <= 27'd0;
  end else begin
    if (d0_weight_addr_low_wren) begin
      d0_weight_addr_low_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_WEIGHT_BYTES
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_weight_bytes_r[24:0] <= 25'd0;
  end else begin
    if (d0_weight_bytes_wren) begin
      d0_weight_bytes_r[24:0] <= csb_wdat[24:0];
    end
  end
end

// D0_WGS_ADDR_HIGH
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_wgs_addr_high_r[31:0] <= 32'd0;
  end else begin
    if (d0_wgs_addr_high_wren) begin
      d0_wgs_addr_high_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// D0_WGS_ADDR_LOW
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_wgs_addr_low_r[26:0] <= 27'd0;
  end else begin
    if (d0_wgs_addr_low_wren) begin
      d0_wgs_addr_low_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_WMB_ADDR_HIGH
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_wmb_addr_high_r[31:0] <= 32'd0;
  end else begin
    if (d0_wmb_addr_high_wren) begin
      d0_wmb_addr_high_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// D0_WMB_ADDR_LOW
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_wmb_addr_low_r[26:0] <= 27'd0;
  end else begin
    if (d0_wmb_addr_low_wren) begin
      d0_wmb_addr_low_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// D0_WMB_BYTES
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_wmb_bytes_r[20:0] <= 21'd0;
  end else begin
    if (d0_wmb_bytes_wren) begin
      d0_wmb_bytes_r[20:0] <= csb_wdat[20:0];
    end
  end
end

// D0_MEAN_FORMAT
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_mean_format_r <= 1'd0;
  end else begin
    if (d0_mean_format_wren) begin
      d0_mean_format_r <= csb_wdat[0];
    end
  end
end

// D0_MEAN_GLOBAL_0
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_mean_gu_r[15:0] <= 16'd0;
    d0_mean_ry_r[15:0] <= 16'd0;
  end else begin
    if (d0_mean_global_0_wren) begin
      d0_mean_gu_r[15:0] <= csb_wdat[31:16];
      d0_mean_ry_r[15:0] <= csb_wdat[15:0];
    end
  end
end

// D0_MEAN_GLOBAL_1
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_mean_ax_r[15:0] <= 16'd0;
    d0_mean_bv_r[15:0] <= 16'd0;
  end else begin
    if (d0_mean_global_1_wren) begin
      d0_mean_ax_r[15:0] <= csb_wdat[31:16];
      d0_mean_bv_r[15:0] <= csb_wdat[15:0];
    end
  end
end

// D0_ZERO_PADDING
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_pad_left_r[4:0] <= 5'd0;
    d0_pad_right_r[5:0] <= 6'd0;
    d0_pad_top_r[4:0] <= 5'd0;
    d0_pad_bottom_r[5:0] <= 6'd0;
  end else begin
    if (d0_zero_padding_wren) begin
      d0_pad_left_r[4:0] <= csb_wdat[4:0];
      d0_pad_right_r[5:0] <= csb_wdat[10:5];
      d0_pad_top_r[4:0] <= csb_wdat[18:14];
      d0_pad_bottom_r[5:0] <= csb_wdat[26:21];
    end
  end
end

// D0_ZERO_PADDING_VALUE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_pad_value_r[15:0] <= 16'd0;
  end else begin
    if (d0_zero_padding_value_wren) begin
      d0_pad_value_r[15:0] <= csb_wdat[15:0];
    end
  end
end

// D0_NAN_FLUSH_TO_ZERO
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_nan_to_zero_r <= 1'd0;
  end else begin
    if (d0_nan_flush_to_zero_wren) begin
      d0_nan_to_zero_r <= csb_wdat[0];
    end
  end
end

// D0_PERF_ENABLE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_dma_en_r <= 1'd0;
  end else begin
    if (d0_perf_enable_wren) begin
      d0_dma_en_r <= csb_wdat[0];
    end
  end
end

// D0_CYA
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_cya_r[31:0] <= 32'd0;
  end else begin
    if (d0_cya_wren) begin
      d0_cya_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// D0 Performance counter registers (writable for test)
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_nan_data_num_r[31:0] <= 32'd0;
    d0_nan_weight_num_r[31:0] <= 32'd0;
    d0_inf_data_num_r[31:0] <= 32'd0;
    d0_inf_weight_num_r[31:0] <= 32'd0;
    d0_dat_rd_latency_r[31:0] <= 32'd0;
    d0_dat_rd_stall_r[31:0] <= 32'd0;
    d0_wt_rd_latency_r[31:0] <= 32'd0;
    d0_wt_rd_stall_r[31:0] <= 32'd0;
  end else begin
    if (d0_nan_input_data_num_wren) d0_nan_data_num_r[31:0] <= csb_wdat[31:0];
    if (d0_nan_input_weight_num_wren) d0_nan_weight_num_r[31:0] <= csb_wdat[31:0];
    if (d0_inf_input_data_num_wren) d0_inf_data_num_r[31:0] <= csb_wdat[31:0];
    if (d0_inf_input_weight_num_wren) d0_inf_weight_num_r[31:0] <= csb_wdat[31:0];
    if (d0_perf_dat_read_latency_wren) d0_dat_rd_latency_r[31:0] <= csb_wdat[31:0];
    if (d0_perf_dat_read_stall_wren) d0_dat_rd_stall_r[31:0] <= csb_wdat[31:0];
    if (d0_perf_wt_read_latency_wren) d0_wt_rd_latency_r[31:0] <= csb_wdat[31:0];
    if (d0_perf_wt_read_stall_wren) d0_wt_rd_stall_r[31:0] <= csb_wdat[31:0];
  end
end

//===============================================================
// TRIGGER DETECTION LOGIC
//===============================================================
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    d0_op_enable_wren_d1 <= 1'd0;
  end else begin
    d0_op_enable_wren_d1 <= d0_op_enable_wren;
  end
end

assign reg2dp_d0_op_en_trigger = d0_op_enable_wren & ~d0_op_enable_wren_d1;

//===============================================================
// READ DATA ASSEMBLY
//===============================================================
assign reg_status_0_rdat[31:0] = {14'd0, dp2reg_status_1[1:0], 14'd0, dp2reg_status_0[1:0]};
assign reg_pointer_0_rdat[31:0] = {15'd0, reg2dp_consumer, 15'd0, reg_producer_r};
assign reg_arbiter_0_rdat[31:0] = {12'd0, reg_arb_wmb_r[3:0], 12'd0, reg_arb_weight_r[3:0]};
assign reg_cbuf_flush_status_rdat[31:0] = {31'd0, dp2reg_flush_done};

assign d0_op_enable_rdat[31:0] = {31'd0, d0_op_en_r};
assign d0_misc_cfg_rdat[31:0] = {3'd0, d0_skip_weight_rls_r, 3'd0, d0_skip_data_rls_r, 3'd0, d0_weight_reuse_r, 3'd0, d0_data_reuse_r, 2'd0, d0_proc_precision_r[1:0], 2'd0, d0_in_precision_r[1:0], 7'd0, d0_conv_mode_r};
assign d0_datain_format_rdat[31:0] = {11'd0, d0_pixel_sign_override_r, 3'd0, d0_pixel_mapping_r, 2'd0, d0_pixel_format_r[5:0], 7'd0, d0_datain_format_r};
assign d0_datain_size_0_rdat[31:0] = {3'd0, d0_datain_height_r[12:0], 3'd0, d0_datain_width_r[12:0]};
assign d0_datain_size_1_rdat[31:0] = {19'd0, d0_datain_channel_r[12:0]};
assign d0_datain_size_ext_0_rdat[31:0] = {3'd0, d0_datain_height_ext_r[12:0], 3'd0, d0_datain_width_ext_r[12:0]};
assign d0_pixel_offset_rdat[31:0] = {13'd0, d0_pixel_y_offset_r[2:0], 11'd0, d0_pixel_x_offset_r[4:0]};
assign d0_dain_ram_type_rdat[31:0] = {31'd0, d0_datain_ram_type_r};
assign d0_dain_addr_high_0_rdat[31:0] = d0_datain_addr_high_0_r[31:0];
assign d0_dain_addr_low_0_rdat[31:0] = {d0_datain_addr_low_0_r[26:0], 5'd0};
assign d0_dain_addr_high_1_rdat[31:0] = d0_datain_addr_high_1_r[31:0];
assign d0_dain_addr_low_1_rdat[31:0] = {d0_datain_addr_low_1_r[26:0], 5'd0};
assign d0_line_stride_rdat[31:0] = {d0_line_stride_r[26:0], 5'd0};
assign d0_line_uv_stride_rdat[31:0] = {d0_uv_line_stride_r[26:0], 5'd0};
assign d0_surf_stride_rdat[31:0] = {d0_surf_stride_r[26:0], 5'd0};
assign d0_dain_map_rdat[31:0] = {15'd0, d0_surf_packed_r, 15'd0, d0_line_packed_r};
assign d0_rsv_x_cfg_rdat[31:0] = {6'd0, d0_rsv_per_uv_line_r[9:0], 6'd0, d0_rsv_per_line_r[9:0]};
assign d0_rsv_y_cfg_rdat[31:0] = {11'd0, d0_rsv_y_index_r[4:0], 13'd0, d0_rsv_height_r[2:0]};
assign d0_batch_number_rdat[31:0] = {27'd0, d0_batches_r[4:0]};
assign d0_batch_stride_rdat[31:0] = {d0_batch_stride_r[26:0], 5'd0};
assign d0_entry_per_slice_rdat[31:0] = {20'd0, d0_entries_r[11:0]};
assign d0_fetch_grain_rdat[31:0] = {20'd0, d0_grains_r[11:0]};
assign d0_weight_format_rdat[31:0] = {31'd0, d0_weight_format_r};
assign d0_weight_size_1_rdat[31:0] = {19'd0, d0_weight_kernel_r[12:0]};
assign d0_weight_ram_type_rdat[31:0] = {31'd0, d0_weight_ram_type_r};
assign d0_weight_addr_high_rdat[31:0] = d0_weight_addr_high_r[31:0];
assign d0_weight_addr_low_rdat[31:0] = {d0_weight_addr_low_r[26:0], 5'd0};
assign d0_weight_bytes_rdat[31:0] = {d0_weight_bytes_r[24:0], 7'd0};
assign d0_wgs_addr_high_rdat[31:0] = d0_wgs_addr_high_r[31:0];
assign d0_wgs_addr_low_rdat[31:0] = {d0_wgs_addr_low_r[26:0], 5'd0};
assign d0_wmb_addr_high_rdat[31:0] = d0_wmb_addr_high_r[31:0];
assign d0_wmb_addr_low_rdat[31:0] = {d0_wmb_addr_low_r[26:0], 5'd0};
assign d0_wmb_bytes_rdat[31:0] = {4'd0, d0_wmb_bytes_r[20:0], 7'd0};
assign d0_mean_format_rdat[31:0] = {31'd0, d0_mean_format_r};
assign d0_mean_global_0_rdat[31:0] = {d0_mean_gu_r[15:0], d0_mean_ry_r[15:0]};
assign d0_mean_global_1_rdat[31:0] = {d0_mean_ax_r[15:0], d0_mean_bv_r[15:0]};
assign d0_cvt_cfg_rdat[31:0] = {22'd0, d0_cvt_truncate_r[5:0], 3'd0, d0_cvt_en_r};
assign d0_cvt_offset_rdat[31:0] = {16'd0, d0_cvt_offset_r[15:0]};
assign d0_cvt_scale_rdat[31:0] = {16'd0, d0_cvt_scale_r[15:0]};
assign d0_conv_stride_rdat[31:0] = {13'd0, d0_conv_y_stride_r[2:0], 13'd0, d0_conv_x_stride_r[2:0]};
assign d0_zero_padding_rdat[31:0] = {2'd0, d0_pad_bottom_r[5:0], 3'd0, d0_pad_top_r[4:0], 2'd0, d0_pad_right_r[5:0], 3'd0, d0_pad_left_r[4:0]};
assign d0_zero_padding_value_rdat[31:0] = {16'd0, d0_pad_value_r[15:0]};
assign d0_bank_rdat[31:0] = {12'd0, d0_weight_bank_r[3:0], 12'd0, d0_data_bank_r[3:0]};
assign d0_nan_flush_to_zero_rdat[31:0] = {31'd0, d0_nan_to_zero_r};
assign d0_nan_input_data_num_rdat[31:0] = d0_nan_data_num_r[31:0];
assign d0_nan_input_weight_num_rdat[31:0] = d0_nan_weight_num_r[31:0];
assign d0_inf_input_data_num_rdat[31:0] = d0_inf_data_num_r[31:0];
assign d0_inf_input_weight_num_rdat[31:0] = d0_inf_weight_num_r[31:0];
assign d0_perf_enable_rdat[31:0] = {31'd0, d0_dma_en_r};
assign d0_perf_dat_read_stall_rdat[31:0] = d0_dat_rd_stall_r[31:0];
assign d0_perf_wt_read_stall_rdat[31:0] = d0_wt_rd_stall_r[31:0];
assign d0_perf_dat_read_latency_rdat[31:0] = d0_dat_rd_latency_r[31:0];
assign d0_perf_wt_read_latency_rdat[31:0] = d0_wt_rd_latency_r[31:0];
assign d0_cya_rdat[31:0] = d0_cya_r[31:0];

//===============================================================
// READ DATA MUX - CSB READ RESPONSE
//===============================================================
always @* begin
  case (csb_addr)
    REG_STATUS_0:          csb_rdat_q = reg_status_0_rdat;
    REG_POINTER_0:          csb_rdat_q = reg_pointer_0_rdat;
    REG_ARBITER_0:          csb_rdat_q = reg_arbiter_0_rdat;
    REG_CBUF_FLUSH_STATUS:  csb_rdat_q = reg_cbuf_flush_status_rdat;
    REG_D0_OP_ENABLE:       csb_rdat_q = d0_op_enable_rdat;
    REG_D0_MISC_CFG:        csb_rdat_q = d0_misc_cfg_rdat;
    REG_D0_DATAIN_FORMAT:   csb_rdat_q = d0_datain_format_rdat;
    REG_D0_DATAIN_SIZE_0:   csb_rdat_q = d0_datain_size_0_rdat;
    REG_D0_DATAIN_SIZE_1:   csb_rdat_q = d0_datain_size_1_rdat;
    REG_D0_DATAIN_SIZE_EXT_0: csb_rdat_q = d0_datain_size_ext_0_rdat;
    REG_D0_PIXEL_OFFSET:    csb_rdat_q = d0_pixel_offset_rdat;
    REG_D0_DAIN_RAM_TYPE:   csb_rdat_q = d0_dain_ram_type_rdat;
    REG_D0_DAIN_ADDR_HIGH_0: csb_rdat_q = d0_dain_addr_high_0_rdat;
    REG_D0_DAIN_ADDR_LOW_0: csb_rdat_q = d0_dain_addr_low_0_rdat;
    REG_D0_DAIN_ADDR_HIGH_1: csb_rdat_q = d0_dain_addr_high_1_rdat;
    REG_D0_DAIN_ADDR_LOW_1: csb_rdat_q = d0_dain_addr_low_1_rdat;
    REG_D0_LINE_STRIDE:     csb_rdat_q = d0_line_stride_rdat;
    REG_D0_LINE_UV_STRIDE:  csb_rdat_q = d0_line_uv_stride_rdat;
    REG_D0_SURF_STRIDE:     csb_rdat_q = d0_surf_stride_rdat;
    REG_D0_DAIN_MAP:        csb_rdat_q = d0_dain_map_rdat;
    REG_D0_RSV_X_CFG:       csb_rdat_q = d0_rsv_x_cfg_rdat;
    REG_D0_RSV_Y_CFG:       csb_rdat_q = d0_rsv_y_cfg_rdat;
    REG_D0_BATCH_NUMBER:    csb_rdat_q = d0_batch_number_rdat;
    REG_D0_BATCH_STRIDE:    csb_rdat_q = d0_batch_stride_rdat;
    REG_D0_ENTRY_PER_SLICE: csb_rdat_q = d0_entry_per_slice_rdat;
    REG_D0_FETCH_GRAIN:     csb_rdat_q = d0_fetch_grain_rdat;
    REG_D0_WEIGHT_FORMAT:   csb_rdat_q = d0_weight_format_rdat;
    REG_D0_WEIGHT_SIZE_1:   csb_rdat_q = d0_weight_size_1_rdat;
    REG_D0_WEIGHT_RAM_TYPE: csb_rdat_q = d0_weight_ram_type_rdat;
    REG_D0_WEIGHT_ADDR_HIGH: csb_rdat_q = d0_weight_addr_high_rdat;
    REG_D0_WEIGHT_ADDR_LOW: csb_rdat_q = d0_weight_addr_low_rdat;
    REG_D0_WEIGHT_BYTES:    csb_rdat_q = d0_weight_bytes_rdat;
    REG_D0_WGS_ADDR_HIGH:   csb_rdat_q = d0_wgs_addr_high_rdat;
    REG_D0_WGS_ADDR_LOW:    csb_rdat_q = d0_wgs_addr_low_rdat;
    REG_D0_WMB_ADDR_HIGH:   csb_rdat_q = d0_wmb_addr_high_rdat;
    REG_D0_WMB_ADDR_LOW:    csb_rdat_q = d0_wmb_addr_low_rdat;
    REG_D0_WMB_BYTES:       csb_rdat_q = d0_wmb_bytes_rdat;
    REG_D0_MEAN_FORMAT:     csb_rdat_q = d0_mean_format_rdat;
    REG_D0_MEAN_GLOBAL_0:   csb_rdat_q = d0_mean_global_0_rdat;
    REG_D0_MEAN_GLOBAL_1:   csb_rdat_q = d0_mean_global_1_rdat;
    REG_D0_CVT_CFG:         csb_rdat_q = d0_cvt_cfg_rdat;
    REG_D0_CVT_OFFSET:      csb_rdat_q = d0_cvt_offset_rdat;
    REG_D0_CVT_SCALE:       csb_rdat_q = d0_cvt_scale_rdat;
    REG_D0_CONV_STRIDE:     csb_rdat_q = d0_conv_stride_rdat;
    REG_D0_ZERO_PADDING:    csb_rdat_q = d0_zero_padding_rdat;
    REG_D0_ZERO_PADDING_VALUE: csb_rdat_q = d0_zero_padding_value_rdat;
    REG_D0_BANK:            csb_rdat_q = d0_bank_rdat;
    REG_D0_NAN_FLUSH_TO_ZERO: csb_rdat_q = d0_nan_flush_to_zero_rdat;
    REG_D0_NAN_INPUT_DATA_NUM: csb_rdat_q = d0_nan_input_data_num_rdat;
    REG_D0_NAN_INPUT_WEIGHT_NUM: csb_rdat_q = d0_nan_input_weight_num_rdat;
    REG_D0_INF_INPUT_DATA_NUM: csb_rdat_q = d0_inf_input_data_num_rdat;
    REG_D0_INF_INPUT_WEIGHT_NUM: csb_rdat_q = d0_inf_input_weight_num_rdat;
    REG_D0_PERF_ENABLE:     csb_rdat_q = d0_perf_enable_rdat;
    REG_D0_PERF_DAT_READ_STALL: csb_rdat_q = d0_perf_dat_read_stall_rdat;
    REG_D0_PERF_WT_READ_STALL: csb_rdat_q = d0_perf_wt_read_stall_rdat;
    REG_D0_PERF_DAT_READ_LATENCY: csb_rdat_q = d0_perf_dat_read_latency_rdat;
    REG_D0_PERF_WT_READ_LATENCY: csb_rdat_q = d0_perf_wt_read_latency_rdat;
    REG_D0_CYA:             csb_rdat_q = d0_cya_rdat;
    default:                csb_rdat_q = 32'd0;
  endcase
end

//===============================================================
// CSB RESPONSE OUTPUT
//===============================================================
assign csb_rdat[31:0] = csb_rdat_q;
assign npu_rdy = 1'b1;

//===============================================================
// DATAPATH OUTPUTS
//===============================================================
// Single register group outputs
assign reg2dp_arb_weight[3:0] = reg_arb_weight_r[3:0];
assign reg2dp_arb_wmb[3:0] = reg_arb_wmb_r[3:0];
assign reg2dp_producer = reg_producer_r;

// D0 register group outputs
assign reg2dp_d0_op_en = d0_op_en_r;
assign reg2dp_d0_data_bank[3:0] = d0_data_bank_r[3:0];
assign reg2dp_d0_weight_bank[3:0] = d0_weight_bank_r[3:0];
assign reg2dp_d0_batches[4:0] = d0_batches_r[4:0];
assign reg2dp_d0_batch_stride[26:0] = d0_batch_stride_r[26:0];
assign reg2dp_d0_conv_x_stride[2:0] = d0_conv_x_stride_r[2:0];
assign reg2dp_d0_conv_y_stride[2:0] = d0_conv_y_stride_r[2:0];
assign reg2dp_d0_cvt_en = d0_cvt_en_r;
assign reg2dp_d0_cvt_truncate[5:0] = d0_cvt_truncate_r[5:0];
assign reg2dp_d0_cvt_offset[15:0] = d0_cvt_offset_r[15:0];
assign reg2dp_d0_cvt_scale[15:0] = d0_cvt_scale_r[15:0];
assign reg2dp_d0_cya[31:0] = d0_cya_r[31:0];
assign reg2dp_d0_datain_addr_high_0[31:0] = d0_datain_addr_high_0_r[31:0];
assign reg2dp_d0_datain_addr_high_1[31:0] = d0_datain_addr_high_1_r[31:0];
assign reg2dp_d0_datain_addr_low_0[26:0] = d0_datain_addr_low_0_r[26:0];
assign reg2dp_d0_datain_addr_low_1[26:0] = d0_datain_addr_low_1_r[26:0];
assign reg2dp_d0_line_packed = d0_line_packed_r;
assign reg2dp_d0_surf_packed = d0_surf_packed_r;
assign reg2dp_d0_datain_ram_type = d0_datain_ram_type_r;
assign reg2dp_d0_datain_format = d0_datain_format_r;
assign reg2dp_d0_pixel_format[5:0] = d0_pixel_format_r[5:0];
assign reg2dp_d0_pixel_mapping = d0_pixel_mapping_r;
assign reg2dp_d0_pixel_sign_override = d0_pixel_sign_override_r;
assign reg2dp_d0_datain_height[12:0] = d0_datain_height_r[12:0];
assign reg2dp_d0_datain_width[12:0] = d0_datain_width_r[12:0];
assign reg2dp_d0_datain_channel[12:0] = d0_datain_channel_r[12:0];
assign reg2dp_d0_datain_height_ext[12:0] = d0_datain_height_ext_r[12:0];
assign reg2dp_d0_datain_width_ext[12:0] = d0_datain_width_ext_r[12:0];
assign reg2dp_d0_entries[11:0] = d0_entries_r[11:0];
assign reg2dp_d0_grains[11:0] = d0_grains_r[11:0];
assign reg2dp_d0_line_stride[26:0] = d0_line_stride_r[26:0];
assign reg2dp_d0_uv_line_stride[26:0] = d0_uv_line_stride_r[26:0];
assign reg2dp_d0_mean_format = d0_mean_format_r;
assign reg2dp_d0_mean_gu[15:0] = d0_mean_gu_r[15:0];
assign reg2dp_d0_mean_ry[15:0] = d0_mean_ry_r[15:0];
assign reg2dp_d0_mean_ax[15:0] = d0_mean_ax_r[15:0];
assign reg2dp_d0_mean_bv[15:0] = d0_mean_bv_r[15:0];
assign reg2dp_d0_conv_mode = d0_conv_mode_r;
assign reg2dp_d0_data_reuse = d0_data_reuse_r;
assign reg2dp_d0_in_precision[1:0] = d0_in_precision_r[1:0];
assign reg2dp_d0_proc_precision[1:0] = d0_proc_precision_r[1:0];
assign reg2dp_d0_skip_data_rls = d0_skip_data_rls_r;
assign reg2dp_d0_skip_weight_rls = d0_skip_weight_rls_r;
assign reg2dp_d0_weight_reuse = d0_weight_reuse_r;
assign reg2dp_d0_nan_to_zero = d0_nan_to_zero_r;
assign reg2dp_d0_dma_en = d0_dma_en_r;
assign reg2dp_d0_pixel_x_offset[4:0] = d0_pixel_x_offset_r[4:0];
assign reg2dp_d0_pixel_y_offset[2:0] = d0_pixel_y_offset_r[2:0];
assign reg2dp_d0_rsv_per_line[9:0] = d0_rsv_per_line_r[9:0];
assign reg2dp_d0_rsv_per_uv_line[9:0] = d0_rsv_per_uv_line_r[9:0];
assign reg2dp_d0_rsv_height[2:0] = d0_rsv_height_r[2:0];
assign reg2dp_d0_rsv_y_index[4:0] = d0_rsv_y_index_r[4:0];
assign reg2dp_d0_surf_stride[26:0] = d0_surf_stride_r[26:0];
assign reg2dp_d0_weight_addr_high[31:0] = d0_weight_addr_high_r[31:0];
assign reg2dp_d0_weight_addr_low[26:0] = d0_weight_addr_low_r[26:0];
assign reg2dp_d0_weight_bytes[24:0] = d0_weight_bytes_r[24:0];
assign reg2dp_d0_weight_format = d0_weight_format_r;
assign reg2dp_d0_weight_ram_type = d0_weight_ram_type_r;
assign reg2dp_d0_byte_per_kernel[17:0] = d0_byte_per_kernel_r[17:0];
assign reg2dp_d0_weight_kernel[12:0] = d0_weight_kernel_r[12:0];
assign reg2dp_d0_wgs_addr_high[31:0] = d0_wgs_addr_high_r[31:0];
assign reg2dp_d0_wgs_addr_low[26:0] = d0_wgs_addr_low_r[26:0];
assign reg2dp_d0_wmb_addr_high[31:0] = d0_wmb_addr_high_r[31:0];
assign reg2dp_d0_wmb_addr_low[26:0] = d0_wmb_addr_low_r[26:0];
assign reg2dp_d0_wmb_bytes[20:0] = d0_wmb_bytes_r[20:0];
assign reg2dp_d0_pad_bottom[5:0] = d0_pad_bottom_r[5:0];
assign reg2dp_d0_pad_left[4:0] = d0_pad_left_r[4:0];
assign reg2dp_d0_pad_right[5:0] = d0_pad_right_r[5:0];
assign reg2dp_d0_pad_top[4:0] = d0_pad_top_r[4:0];
assign reg2dp_d0_pad_value[15:0] = d0_pad_value_r[15:0];

// D1 outputs (same as D0 for this simplified module - duplicates not shown for brevity)
// In a full implementation, D1 would have its own register instances
assign reg2dp_d1_op_en = d0_op_en_r;
assign reg2dp_d1_data_bank[3:0] = d0_data_bank_r[3:0];
assign reg2dp_d1_weight_bank[3:0] = d0_weight_bank_r[3:0];
assign reg2dp_d1_batches[4:0] = d0_batches_r[4:0];
assign reg2dp_d1_batch_stride[26:0] = d0_batch_stride_r[26:0];
assign reg2dp_d1_conv_x_stride[2:0] = d0_conv_x_stride_r[2:0];
assign reg2dp_d1_conv_y_stride[2:0] = d0_conv_y_stride_r[2:0];
assign reg2dp_d1_cvt_en = d0_cvt_en_r;
assign reg2dp_d1_cvt_truncate[5:0] = d0_cvt_truncate_r[5:0];
assign reg2dp_d1_cvt_offset[15:0] = d0_cvt_offset_r[15:0];
assign reg2dp_d1_cvt_scale[15:0] = d0_cvt_scale_r[15:0];
assign reg2dp_d1_cya[31:0] = d0_cya_r[31:0];
assign reg2dp_d1_datain_addr_high_0[31:0] = d0_datain_addr_high_0_r[31:0];
assign reg2dp_d1_datain_addr_high_1[31:0] = d0_datain_addr_high_1_r[31:0];
assign reg2dp_d1_datain_addr_low_0[26:0] = d0_datain_addr_low_0_r[26:0];
assign reg2dp_d1_datain_addr_low_1[26:0] = d0_datain_addr_low_1_r[26:0];
assign reg2dp_d1_line_packed = d0_line_packed_r;
assign reg2dp_d1_surf_packed = d0_surf_packed_r;
assign reg2dp_d1_datain_ram_type = d0_datain_ram_type_r;
assign reg2dp_d1_datain_format = d0_datain_format_r;
assign reg2dp_d1_pixel_format[5:0] = d0_pixel_format_r[5:0];
assign reg2dp_d1_pixel_mapping = d0_pixel_mapping_r;
assign reg2dp_d1_pixel_sign_override = d0_pixel_sign_override_r;
assign reg2dp_d1_datain_height[12:0] = d0_datain_height_r[12:0];
assign reg2dp_d1_datain_width[12:0] = d0_datain_width_r[12:0];
assign reg2dp_d1_datain_channel[12:0] = d0_datain_channel_r[12:0];
assign reg2dp_d1_datain_height_ext[12:0] = d0_datain_height_ext_r[12:0];
assign reg2dp_d1_datain_width_ext[12:0] = d0_datain_width_ext_r[12:0];
assign reg2dp_d1_entries[11:0] = d0_entries_r[11:0];
assign reg2dp_d1_grains[11:0] = d0_grains_r[11:0];
assign reg2dp_d1_line_stride[26:0] = d0_line_stride_r[26:0];
assign reg2dp_d1_uv_line_stride[26:0] = d0_uv_line_stride_r[26:0];
assign reg2dp_d1_mean_format = d0_mean_format_r;
assign reg2dp_d1_mean_gu[15:0] = d0_mean_gu_r[15:0];
assign reg2dp_d1_mean_ry[15:0] = d0_mean_ry_r[15:0];
assign reg2dp_d1_mean_ax[15:0] = d0_mean_ax_r[15:0];
assign reg2dp_d1_mean_bv[15:0] = d0_mean_bv_r[15:0];
assign reg2dp_d1_conv_mode = d0_conv_mode_r;
assign reg2dp_d1_data_reuse = d0_data_reuse_r;
assign reg2dp_d1_in_precision[1:0] = d0_in_precision_r[1:0];
assign reg2dp_d1_proc_precision[1:0] = d0_proc_precision_r[1:0];
assign reg2dp_d1_skip_data_rls = d0_skip_data_rls_r;
assign reg2dp_d1_skip_weight_rls = d0_skip_weight_rls_r;
assign reg2dp_d1_weight_reuse = d0_weight_reuse_r;
assign reg2dp_d1_nan_to_zero = d0_nan_to_zero_r;
assign reg2dp_d1_dma_en = d0_dma_en_r;
assign reg2dp_d1_pixel_x_offset[4:0] = d0_pixel_x_offset_r[4:0];
assign reg2dp_d1_pixel_y_offset[2:0] = d0_pixel_y_offset_r[2:0];
assign reg2dp_d1_rsv_per_line[9:0] = d0_rsv_per_line_r[9:0];
assign reg2dp_d1_rsv_per_uv_line[9:0] = d0_rsv_per_uv_line_r[9:0];
assign reg2dp_d1_rsv_height[2:0] = d0_rsv_height_r[2:0];
assign reg2dp_d1_rsv_y_index[4:0] = d0_rsv_y_index_r[4:0];
assign reg2dp_d1_surf_stride[26:0] = d0_surf_stride_r[26:0];
assign reg2dp_d1_weight_addr_high[31:0] = d0_weight_addr_high_r[31:0];
assign reg2dp_d1_weight_addr_low[26:0] = d0_weight_addr_low_r[26:0];
assign reg2dp_d1_weight_bytes[24:0] = d0_weight_bytes_r[24:0];
assign reg2dp_d1_weight_format = d0_weight_format_r;
assign reg2dp_d1_weight_ram_type = d0_weight_ram_type_r;
assign reg2dp_d1_byte_per_kernel[17:0] = d0_byte_per_kernel_r[17:0];
assign reg2dp_d1_weight_kernel[12:0] = d0_weight_kernel_r[12:0];
assign reg2dp_d1_wgs_addr_high[31:0] = d0_wgs_addr_high_r[31:0];
assign reg2dp_d1_wgs_addr_low[26:0] = d0_wgs_addr_low_r[26:0];
assign reg2dp_d1_wmb_addr_high[31:0] = d0_wmb_addr_high_r[31:0];
assign reg2dp_d1_wmb_addr_low[26:0] = d0_wmb_addr_low_r[26:0];
assign reg2dp_d1_wmb_bytes[20:0] = d0_wmb_bytes_r[20:0];
assign reg2dp_d1_pad_bottom[5:0] = d0_pad_bottom_r[5:0];
assign reg2dp_d1_pad_left[4:0] = d0_pad_left_r[4:0];
assign reg2dp_d1_pad_right[5:0] = d0_pad_right_r[5:0];
assign reg2dp_d1_pad_top[4:0] = d0_pad_top_r[4:0];
assign reg2dp_d1_pad_value[15:0] = d0_pad_value_r[15:0];

//===============================================================
// DEBUG AND ASSERTIONS
//===============================================================
// synopsys translate_off
`ifdef SYNTHESIS
`else
// Register write debug
always @(posedge csb_clk) begin
  if (csb_wr_en) begin
    case (csb_addr)
      REG_STATUS_0:          $display("%t:%m: WR REG_STATUS_0 (read-only) = 0x%h", $time, csb_wdat);
      REG_POINTER_0:         $display("%t:%m: WR REG_POINTER_0 = 0x%h", $time, csb_wdat);
      REG_ARBITER_0:         $display("%t:%m: WR REG_ARBITER_0 = 0x%h", $time, csb_wdat);
      REG_CBUF_FLUSH_STATUS: $display("%t:%m: WR REG_CBUF_FLUSH_STATUS (read-only) = 0x%h", $time, csb_wdat);
      REG_D0_OP_ENABLE:      $display("%t:%m: WR REG_D0_OP_ENABLE = 0x%h", $time, csb_wdat);
      REG_D0_MISC_CFG:       $display("%t:%m: WR REG_D0_MISC_CFG = 0x%h", $time, csb_wdat);
      default:;
    endcase
  end
end
`endif
// synopsys translate_on

endmodule // NV_NVDLA_CDMA_reg