// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_reg_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA Register File Module
// - CSB (Command and Status Bus) register access interface
// - Dual register groups (D0/D1) for ping-pong operation
// - Supports read/write operations to all CDMA configuration
//   and status registers
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_reg_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  // CSB interface
  ,csb_addr
  ,csb_wdat
  ,csb_wr_en
  ,csb_rd_en
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
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// CSB interface
input  [11:0] csb_addr;
input  [31:0] csb_wdat;
input         csb_wr_en;
input         csb_rd_en;
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
// Single register group addresses (base 0x000)
parameter [11:0] REG_STATUS_0         = 12'h000;
parameter [11:0] REG_POINTER_0        = 12'h004;
parameter [11:0] REG_ARBITER_0        = 12'h008;
parameter [11:0] REG_CBUF_FLUSH_STATUS = 12'h00C;

// Dual register group 0 addresses (base 0x010)
parameter [11:0] REG_D0_OP_ENABLE     = 12'h010;
parameter [11:0] REG_D0_MISC_CFG      = 12'h014;
parameter [11:0] REG_D0_DATAIN_FORMAT  = 12'h018;
parameter [11:0] REG_D0_DATAIN_SIZE_0  = 12'h01C;
parameter [11:0] REG_D0_DATAIN_SIZE_1  = 12'h020;
parameter [11:0] REG_D0_DATAIN_SIZE_EXT_0 = 12'h024;
parameter [11:0] REG_D0_PIXEL_OFFSET   = 12'h028;
parameter [11:0] REG_D0_DAIN_RAM_TYPE  = 12'h02C;
parameter [11:0] REG_D0_DAIN_ADDR_HIGH_0 = 12'h030;
parameter [11:0] REG_D0_DAIN_ADDR_LOW_0 = 12'h034;
parameter [11:0] REG_D0_DAIN_ADDR_HIGH_1 = 12'h038;
parameter [11:0] REG_D0_DAIN_ADDR_LOW_1 = 12'h03C;
parameter [11:0] REG_D0_LINE_STRIDE     = 12'h040;
parameter [11:0] REG_D0_LINE_UV_STRIDE = 12'h044;
parameter [11:0] REG_D0_SURF_STRIDE     = 12'h048;
parameter [11:0] REG_D0_DAIN_MAP       = 12'h04C;
parameter [11:0] REG_D0_RSV_X_CFG      = 12'h050;
parameter [11:0] REG_D0_RSV_Y_CFG      = 12'h054;
parameter [11:0] REG_D0_BATCH_NUMBER   = 12'h058;
parameter [11:0] REG_D0_BATCH_STRIDE   = 12'h05C;
parameter [11:0] REG_D0_ENTRY_PER_SLICE = 12'h060;
parameter [11:0] REG_D0_FETCH_GRAIN    = 12'h064;
parameter [11:0] REG_D0_WEIGHT_FORMAT  = 12'h068;
parameter [11:0] REG_D0_WEIGHT_SIZE_1  = 12'h06C;
parameter [11:0] REG_D0_WEIGHT_RAM_TYPE = 12'h074;
parameter [11:0] REG_D0_WEIGHT_ADDR_HIGH = 12'h078;
parameter [11:0] REG_D0_WEIGHT_ADDR_LOW = 12'h07C;
parameter [11:0] REG_D0_WEIGHT_BYTES    = 12'h080;
parameter [11:0] REG_D0_WGS_ADDR_HIGH  = 12'h084;
parameter [11:0] REG_D0_WGS_ADDR_LOW   = 12'h088;
parameter [11:0] REG_D0_WMB_ADDR_HIGH  = 12'h08C;
parameter [11:0] REG_D0_WMB_ADDR_LOW   = 12'h090;
parameter [11:0] REG_D0_WMB_BYTES      = 12'h094;
parameter [11:0] REG_D0_MEAN_FORMAT    = 12'h098;
parameter [11:0] REG_D0_MEAN_GLOBAL_0  = 12'h09C;
parameter [11:0] REG_D0_MEAN_GLOBAL_1  = 12'h0A0;
parameter [11:0] REG_D0_CVT_CFG        = 12'h0A4;
parameter [11:0] REG_D0_CVT_OFFSET     = 12'h0A8;
parameter [11:0] REG_D0_CVT_SCALE      = 12'h0AC;
parameter [11:0] REG_D0_CONV_STRIDE    = 12'h0B0;
parameter [11:0] REG_D0_ZERO_PADDING   = 12'h0B4;
parameter [11:0] REG_D0_ZERO_PADDING_VALUE = 12'h0B8;
parameter [11:0] REG_D0_BANK           = 12'h0BC;
parameter [11:0] REG_D0_NAN_FLUSH_TO_ZERO = 12'h0C0;
parameter [11:0] REG_D0_NAN_INPUT_DATA_NUM = 12'h0C4;
parameter [11:0] REG_D0_NAN_INPUT_WEIGHT_NUM = 12'h0C8;
parameter [11:0] REG_D0_INF_INPUT_DATA_NUM = 12'h0CC;
parameter [11:0] REG_D0_INF_INPUT_WEIGHT_NUM = 12'h0D0;
parameter [11:0] REG_D0_PERF_ENABLE   = 12'h0D4;
parameter [11:0] REG_D0_PERF_DAT_READ_STALL = 12'h0D8;
parameter [11:0] REG_D0_PERF_WT_READ_STALL = 12'h0DC;
parameter [11:0] REG_D0_PERF_DAT_READ_LATENCY = 12'h0E0;
parameter [11:0] REG_D0_PERF_WT_READ_LATENCY = 12'h0E4;
parameter [11:0] REG_D0_CYA            = 12'h0E8;

// Dual register group 1 addresses (base 0x100)
parameter [11:0] REG_D1_OP_ENABLE     = 12'h110;
parameter [11:0] REG_D1_MISC_CFG      = 12'h114;
parameter [11:0] REG_D1_DATAIN_FORMAT  = 12'h118;
parameter [11:0] REG_D1_DATAIN_SIZE_0  = 12'h11C;
parameter [11:0] REG_D1_DATAIN_SIZE_1  = 12'h120;
parameter [11:0] REG_D1_DATAIN_SIZE_EXT_0 = 12'h124;
parameter [11:0] REG_D1_PIXEL_OFFSET   = 12'h128;
parameter [11:0] REG_D1_DAIN_RAM_TYPE  = 12'h12C;
parameter [11:0] REG_D1_DAIN_ADDR_HIGH_0 = 12'h130;
parameter [11:0] REG_D1_DAIN_ADDR_LOW_0 = 12'h134;
parameter [11:0] REG_D1_DAIN_ADDR_HIGH_1 = 12'h138;
parameter [11:0] REG_D1_DAIN_ADDR_LOW_1 = 12'h13C;
parameter [11:0] REG_D1_LINE_STRIDE     = 12'h140;
parameter [11:0] REG_D1_LINE_UV_STRIDE = 12'h144;
parameter [11:0] REG_D1_SURF_STRIDE     = 12'h148;
parameter [11:0] REG_D1_DAIN_MAP       = 12'h14C;
parameter [11:0] REG_D1_RSV_X_CFG      = 12'h150;
parameter [11:0] REG_D1_RSV_Y_CFG      = 12'h154;
parameter [11:0] REG_D1_BATCH_NUMBER   = 12'h158;
parameter [11:0] REG_D1_BATCH_STRIDE   = 12'h15C;
parameter [11:0] REG_D1_ENTRY_PER_SLICE = 12'h160;
parameter [11:0] REG_D1_FETCH_GRAIN    = 12'h164;
parameter [11:0] REG_D1_WEIGHT_FORMAT  = 12'h168;
parameter [11:0] REG_D1_WEIGHT_SIZE_1  = 12'h16C;
parameter [11:0] REG_D1_WEIGHT_RAM_TYPE = 12'h174;
parameter [11:0] REG_D1_WEIGHT_ADDR_HIGH = 12'h178;
parameter [11:0] REG_D1_WEIGHT_ADDR_LOW = 12'h17C;
parameter [11:0] REG_D1_WEIGHT_BYTES    = 12'h180;
parameter [11:0] REG_D1_WGS_ADDR_HIGH  = 12'h184;
parameter [11:0] REG_D1_WGS_ADDR_LOW   = 12'h188;
parameter [11:0] REG_D1_WMB_ADDR_HIGH  = 12'h18C;
parameter [11:0] REG_D1_WMB_ADDR_LOW   = 12'h190;
parameter [11:0] REG_D1_WMB_BYTES      = 12'h194;
parameter [11:0] REG_D1_MEAN_FORMAT    = 12'h198;
parameter [11:0] REG_D1_MEAN_GLOBAL_0  = 12'h19C;
parameter [11:0] REG_D1_MEAN_GLOBAL_1  = 12'h1A0;
parameter [11:0] REG_D1_CVT_CFG        = 12'h1A4;
parameter [11:0] REG_D1_CVT_OFFSET     = 12'h1A8;
parameter [11:0] REG_D1_CVT_SCALE      = 12'h1AC;
parameter [11:0] REG_D1_CONV_STRIDE    = 12'h1B0;
parameter [11:0] REG_D1_ZERO_PADDING   = 12'h1B4;
parameter [11:0] REG_D1_ZERO_PADDING_VALUE = 12'h1B8;
parameter [11:0] REG_D1_BANK           = 12'h1BC;
parameter [11:0] REG_D1_NAN_FLUSH_TO_ZERO = 12'h1C0;
parameter [11:0] REG_D1_NAN_INPUT_DATA_NUM = 12'h1C4;
parameter [11:0] REG_D1_NAN_INPUT_WEIGHT_NUM = 12'h1C8;
parameter [11:0] REG_D1_INF_INPUT_DATA_NUM = 12'h1CC;
parameter [11:0] REG_D1_INF_INPUT_WEIGHT_NUM = 12'h1D0;
parameter [11:0] REG_D1_PERF_ENABLE   = 12'h1D4;
parameter [11:0] REG_D1_PERF_DAT_READ_STALL = 12'h1D8;
parameter [11:0] REG_D1_PERF_WT_READ_STALL = 12'h1DC;
parameter [11:0] REG_D1_PERF_DAT_READ_LATENCY = 12'h1E0;
parameter [11:0] REG_D1_PERF_WT_READ_LATENCY = 12'h1E4;
parameter [11:0] REG_D1_CYA            = 12'h1E8;

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
wire        d0_perf_enable_wren;
wire        d0_cya_wren;

// Write enable decode - D1 registers
wire        d1_op_enable_wren;
wire        d1_misc_cfg_wren;
wire        d1_datain_format_wren;
wire        d1_datain_size_0_wren;
wire        d1_datain_size_1_wren;
wire        d1_datain_size_ext_0_wren;
wire        d1_pixel_offset_wren;
wire        d1_dain_ram_type_wren;
wire        d1_dain_addr_high_0_wren;
wire        d1_dain_addr_low_0_wren;
wire        d1_dain_addr_high_1_wren;
wire        d1_dain_addr_low_1_wren;
wire        d1_line_stride_wren;
wire        d1_line_uv_stride_wren;
wire        d1_surf_stride_wren;
wire        d1_dain_map_wren;
wire        d1_rsv_x_cfg_wren;
wire        d1_rsv_y_cfg_wren;
wire        d1_batch_number_wren;
wire        d1_batch_stride_wren;
wire        d1_entry_per_slice_wren;
wire        d1_fetch_grain_wren;
wire        d1_weight_format_wren;
wire        d1_weight_size_1_wren;
wire        d1_weight_ram_type_wren;
wire        d1_weight_addr_high_wren;
wire        d1_weight_addr_low_wren;
wire        d1_weight_bytes_wren;
wire        d1_wgs_addr_high_wren;
wire        d1_wgs_addr_low_wren;
wire        d1_wmb_addr_high_wren;
wire        d1_wmb_addr_low_wren;
wire        d1_wmb_bytes_wren;
wire        d1_mean_format_wren;
wire        d1_mean_global_0_wren;
wire        d1_mean_global_1_wren;
wire        d1_cvt_cfg_wren;
wire        d1_cvt_offset_wren;
wire        d1_cvt_scale_wren;
wire        d1_conv_stride_wren;
wire        d1_zero_padding_wren;
wire        d1_zero_padding_value_wren;
wire        d1_bank_wren;
wire        d1_nan_flush_to_zero_wren;
wire        d1_perf_enable_wren;
wire        d1_cya_wren;

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
reg  [12:0] d0_datain_height_r;
reg  [12:0] d0_datain_width_r;
reg  [12:0] d0_datain_channel_r;
reg  [12:0] d0_datain_height_ext_r;
reg  [12:0] d0_datain_width_ext_r;
reg  [11:0] d0_entries_r;
reg  [11:0] d0_grains_r;
reg  [26:0] d0_batch_stride_r;
reg  [26:0] d0_line_stride_r;
reg  [26:0] d0_uv_line_stride_r;
reg  [26:0] d0_surf_stride_r;
reg  [15:0] d0_cvt_offset_r;
reg  [15:0] d0_cvt_scale_r;
reg  [15:0] d0_mean_gu_r;
reg  [15:0] d0_mean_ry_r;
reg  [15:0] d0_mean_ax_r;
reg  [15:0] d0_mean_bv_r;
reg  [15:0] d0_pad_value_r;
reg  [17:0] d0_byte_per_kernel_r;
reg  [12:0] d0_weight_kernel_r;
reg  [24:0] d0_weight_bytes_r;
reg  [26:0] d0_datain_addr_low_0_r;
reg  [26:0] d0_datain_addr_low_1_r;
reg  [31:0] d0_datain_addr_high_0_r;
reg  [31:0] d0_datain_addr_high_1_r;
reg  [26:0] d0_weight_addr_low_r;
reg  [31:0] d0_weight_addr_high_r;
reg  [26:0] d0_wgs_addr_low_r;
reg  [31:0] d0_wgs_addr_high_r;
reg  [26:0] d0_wmb_addr_low_r;
reg  [31:0] d0_wmb_addr_high_r;
reg  [20:0] d0_wmb_bytes_r;
reg  [31:0] d0_cya_r;

// D1 register group
reg         d1_op_en_r;
reg         d1_conv_mode_r;
reg  [1:0]  d1_in_precision_r;
reg  [1:0]  d1_proc_precision_r;
reg         d1_data_reuse_r;
reg         d1_weight_reuse_r;
reg         d1_skip_data_rls_r;
reg         d1_skip_weight_rls_r;
reg         d1_nan_to_zero_r;
reg         d1_cvt_en_r;
reg  [5:0]  d1_cvt_truncate_r;
reg         d1_datain_ram_type_r;
reg         d1_datain_format_r;
reg         d1_pixel_mapping_r;
reg         d1_pixel_sign_override_r;
reg  [5:0]  d1_pixel_format_r;
reg         d1_line_packed_r;
reg         d1_surf_packed_r;
reg         d1_mean_format_r;
reg         d1_weight_format_r;
reg         d1_weight_ram_type_r;
reg         d1_dma_en_r;
reg  [3:0]  d1_data_bank_r;
reg  [3:0]  d1_weight_bank_r;
reg  [4:0]  d1_batches_r;
reg  [2:0]  d1_conv_x_stride_r;
reg  [2:0]  d1_conv_y_stride_r;
reg  [2:0]  d1_rsv_height_r;
reg  [4:0]  d1_rsv_y_index_r;
reg  [4:0]  d1_pixel_x_offset_r;
reg  [2:0]  d1_pixel_y_offset_r;
reg  [9:0]  d1_rsv_per_line_r;
reg  [9:0]  d1_rsv_per_uv_line_r;
reg  [5:0]  d1_pad_bottom_r;
reg  [4:0]  d1_pad_left_r;
reg  [5:0]  d1_pad_right_r;
reg  [4:0]  d1_pad_top_r;
reg  [12:0] d1_datain_height_r;
reg  [12:0] d1_datain_width_r;
reg  [12:0] d1_datain_channel_r;
reg  [12:0] d1_datain_height_ext_r;
reg  [12:0] d1_datain_width_ext_r;
reg  [11:0] d1_entries_r;
reg  [11:0] d1_grains_r;
reg  [26:0] d1_batch_stride_r;
reg  [26:0] d1_line_stride_r;
reg  [26:0] d1_uv_line_stride_r;
reg  [26:0] d1_surf_stride_r;
reg  [15:0] d1_cvt_offset_r;
reg  [15:0] d1_cvt_scale_r;
reg  [15:0] d1_mean_gu_r;
reg  [15:0] d1_mean_ry_r;
reg  [15:0] d1_mean_ax_r;
reg  [15:0] d1_mean_bv_r;
reg  [15:0] d1_pad_value_r;
reg  [17:0] d1_byte_per_kernel_r;
reg  [12:0] d1_weight_kernel_r;
reg  [24:0] d1_weight_bytes_r;
reg  [26:0] d1_datain_addr_low_0_r;
reg  [26:0] d1_datain_addr_low_1_r;
reg  [31:0] d1_datain_addr_high_0_r;
reg  [31:0] d1_datain_addr_high_1_r;
reg  [26:0] d1_weight_addr_low_r;
reg  [31:0] d1_weight_addr_high_r;
reg  [26:0] d1_wgs_addr_low_r;
reg  [31:0] d1_wgs_addr_high_r;
reg  [26:0] d1_wmb_addr_low_r;
reg  [31:0] d1_wmb_addr_high_r;
reg  [20:0] d1_wmb_bytes_r;
reg  [31:0] d1_cya_r;

// CSB response
reg  [31:0] csb_rdat_q;

// OP_EN trigger detection
reg         d0_op_en_wren_d1;
reg         d1_op_en_wren_d1;

//===============================================================
// ADDRESS DECODE - WRITE ENABLE
//===============================================================
// Single register group write enables
assign reg_status_0_wren         = (csb_addr == REG_STATUS_0)         & csb_wr_en;
assign reg_pointer_0_wren         = (csb_addr == REG_POINTER_0)        & csb_wr_en;
assign reg_arbiter_0_wren         = (csb_addr == REG_ARBITER_0)        & csb_wr_en;
assign reg_cbuf_flush_status_wren = (csb_addr == REG_CBUF_FLUSH_STATUS) & csb_wr_en;

// D0 register group write enables
assign d0_op_enable_wren         = (csb_addr == REG_D0_OP_ENABLE)         & csb_wr_en;
assign d0_misc_cfg_wren          = (csb_addr == REG_D0_MISC_CFG)          & csb_wr_en;
assign d0_datain_format_wren      = (csb_addr == REG_D0_DATAIN_FORMAT)     & csb_wr_en;
assign d0_datain_size_0_wren      = (csb_addr == REG_D0_DATAIN_SIZE_0)     & csb_wr_en;
assign d0_datain_size_1_wren      = (csb_addr == REG_D0_DATAIN_SIZE_1)     & csb_wr_en;
assign d0_datain_size_ext_0_wren  = (csb_addr == REG_D0_DATAIN_SIZE_EXT_0) & csb_wr_en;
assign d0_pixel_offset_wren       = (csb_addr == REG_D0_PIXEL_OFFSET)       & csb_wr_en;
assign d0_dain_ram_type_wren      = (csb_addr == REG_D0_DAIN_RAM_TYPE)     & csb_wr_en;
assign d0_dain_addr_high_0_wren   = (csb_addr == REG_D0_DAIN_ADDR_HIGH_0)  & csb_wr_en;
assign d0_dain_addr_low_0_wren   = (csb_addr == REG_D0_DAIN_ADDR_LOW_0)   & csb_wr_en;
assign d0_dain_addr_high_1_wren   = (csb_addr == REG_D0_DAIN_ADDR_HIGH_1)  & csb_wr_en;
assign d0_dain_addr_low_1_wren   = (csb_addr == REG_D0_DAIN_ADDR_LOW_1)   & csb_wr_en;
assign d0_line_stride_wren        = (csb_addr == REG_D0_LINE_STRIDE)        & csb_wr_en;
assign d0_line_uv_stride_wren     = (csb_addr == REG_D0_LINE_UV_STRIDE)    & csb_wr_en;
assign d0_surf_stride_wren        = (csb_addr == REG_D0_SURF_STRIDE)        & csb_wr_en;
assign d0_dain_map_wren           = (csb_addr == REG_D0_DAIN_MAP)           & csb_wr_en;
assign d0_rsv_x_cfg_wren          = (csb_addr == REG_D0_RSV_X_CFG)          & csb_wr_en;
assign d0_rsv_y_cfg_wren          = (csb_addr == REG_D0_RSV_Y_CFG)          & csb_wr_en;
assign d0_batch_number_wren       = (csb_addr == REG_D0_BATCH_NUMBER)      & csb_wr_en;
assign d0_batch_stride_wren       = (csb_addr == REG_D0_BATCH_STRIDE)      & csb_wr_en;
assign d0_entry_per_slice_wren    = (csb_addr == REG_D0_ENTRY_PER_SLICE)    & csb_wr_en;
assign d0_fetch_grain_wren        = (csb_addr == REG_D0_FETCH_GRAIN)       & csb_wr_en;
assign d0_weight_format_wren      = (csb_addr == REG_D0_WEIGHT_FORMAT)      & csb_wr_en;
assign d0_weight_size_1_wren      = (csb_addr == REG_D0_WEIGHT_SIZE_1)      & csb_wr_en;
assign d0_weight_ram_type_wren    = (csb_addr == REG_D0_WEIGHT_RAM_TYPE)    & csb_wr_en;
assign d0_weight_addr_high_wren   = (csb_addr == REG_D0_WEIGHT_ADDR_HIGH)  & csb_wr_en;
assign d0_weight_addr_low_wren    = (csb_addr == REG_D0_WEIGHT_ADDR_LOW)   & csb_wr_en;
assign d0_weight_bytes_wren       = (csb_addr == REG_D0_WEIGHT_BYTES)       & csb_wr_en;
assign d0_wgs_addr_high_wren      = (csb_addr == REG_D0_WGS_ADDR_HIGH)     & csb_wr_en;
assign d0_wgs_addr_low_wren       = (csb_addr == REG_D0_WGS_ADDR_LOW)      & csb_wr_en;
assign d0_wmb_addr_high_wren      = (csb_addr == REG_D0_WMB_ADDR_HIGH)     & csb_wr_en;
assign d0_wmb_addr_low_wren       = (csb_addr == REG_D0_WMB_ADDR_LOW)      & csb_wr_en;
assign d0_wmb_bytes_wren          = (csb_addr == REG_D0_WMB_BYTES)         & csb_wr_en;
assign d0_mean_format_wren        = (csb_addr == REG_D0_MEAN_FORMAT)       & csb_wr_en;
assign d0_mean_global_0_wren     = (csb_addr == REG_D0_MEAN_GLOBAL_0)     & csb_wr_en;
assign d0_mean_global_1_wren     = (csb_addr == REG_D0_MEAN_GLOBAL_1)     & csb_wr_en;
assign d0_cvt_cfg_wren            = (csb_addr == REG_D0_CVT_CFG)            & csb_wr_en;
assign d0_cvt_offset_wren         = (csb_addr == REG_D0_CVT_OFFSET)        & csb_wr_en;
assign d0_cvt_scale_wren         = (csb_addr == REG_D0_CVT_SCALE)         & csb_wr_en;
assign d0_conv_stride_wren       = (csb_addr == REG_D0_CONV_STRIDE)       & csb_wr_en;
assign d0_zero_padding_wren       = (csb_addr == REG_D0_ZERO_PADDING)      & csb_wr_en;
assign d0_zero_padding_value_wren = (csb_addr == REG_D0_ZERO_PADDING_VALUE) & csb_wr_en;
assign d0_bank_wren               = (csb_addr == REG_D0_BANK)              & csb_wr_en;
assign d0_nan_flush_to_zero_wren = (csb_addr == REG_D0_NAN_FLUSH_TO_ZERO) & csb_wr_en;
assign d0_perf_enable_wren        = (csb_addr == REG_D0_PERF_ENABLE)       & csb_wr_en;
assign d0_cya_wren                = (csb_addr == REG_D0_CYA)               & csb_wr_en;

// D1 register group write enables
assign d1_op_enable_wren         = (csb_addr == REG_D1_OP_ENABLE)         & csb_wr_en;
assign d1_misc_cfg_wren          = (csb_addr == REG_D1_MISC_CFG)          & csb_wr_en;
assign d1_datain_format_wren      = (csb_addr == REG_D1_DATAIN_FORMAT)     & csb_wr_en;
assign d1_datain_size_0_wren      = (csb_addr == REG_D1_DATAIN_SIZE_0)     & csb_wr_en;
assign d1_datain_size_1_wren      = (csb_addr == REG_D1_DATAIN_SIZE_1)     & csb_wr_en;
assign d1_datain_size_ext_0_wren  = (csb_addr == REG_D1_DATAIN_SIZE_EXT_0) & csb_wr_en;
assign d1_pixel_offset_wren       = (csb_addr == REG_D1_PIXEL_OFFSET)       & csb_wr_en;
assign d1_dain_ram_type_wren      = (csb_addr == REG_D1_DAIN_RAM_TYPE)     & csb_wr_en;
assign d1_dain_addr_high_0_wren   = (csb_addr == REG_D1_DAIN_ADDR_HIGH_0)  & csb_wr_en;
assign d1_dain_addr_low_0_wren   = (csb_addr == REG_D1_DAIN_ADDR_LOW_0)   & csb_wr_en;
assign d1_dain_addr_high_1_wren   = (csb_addr == REG_D1_DAIN_ADDR_HIGH_1)  & csb_wr_en;
assign d1_dain_addr_low_1_wren   = (csb_addr == REG_D1_DAIN_ADDR_LOW_1)   & csb_wr_en;
assign d1_line_stride_wren        = (csb_addr == REG_D1_LINE_STRIDE)        & csb_wr_en;
assign d1_line_uv_stride_wren     = (csb_addr == REG_D1_LINE_UV_STRIDE)    & csb_wr_en;
assign d1_surf_stride_wren        = (csb_addr == REG_D1_SURF_STRIDE)        & csb_wr_en;
assign d1_dain_map_wren           = (csb_addr == REG_D1_DAIN_MAP)           & csb_wr_en;
assign d1_rsv_x_cfg_wren          = (csb_addr == REG_D1_RSV_X_CFG)          & csb_wr_en;
assign d1_rsv_y_cfg_wren          = (csb_addr == REG_D1_RSV_Y_CFG)          & csb_wr_en;
assign d1_batch_number_wren       = (csb_addr == REG_D1_BATCH_NUMBER)      & csb_wr_en;
assign d1_batch_stride_wren       = (csb_addr == REG_D1_BATCH_STRIDE)      & csb_wr_en;
assign d1_entry_per_slice_wren    = (csb_addr == REG_D1_ENTRY_PER_SLICE)    & csb_wr_en;
assign d1_fetch_grain_wren        = (csb_addr == REG_D1_FETCH_GRAIN)       & csb_wr_en;
assign d1_weight_format_wren      = (csb_addr == REG_D1_WEIGHT_FORMAT)      & csb_wr_en;
assign d1_weight_size_1_wren      = (csb_addr == REG_D1_WEIGHT_SIZE_1)      & csb_wr_en;
assign d1_weight_ram_type_wren    = (csb_addr == REG_D1_WEIGHT_RAM_TYPE)    & csb_wr_en;
assign d1_weight_addr_high_wren   = (csb_addr == REG_D1_WEIGHT_ADDR_HIGH)  & csb_wr_en;
assign d1_weight_addr_low_wren    = (csb_addr == REG_D1_WEIGHT_ADDR_LOW)   & csb_wr_en;
assign d1_weight_bytes_wren       = (csb_addr == REG_D1_WEIGHT_BYTES)       & csb_wr_en;
assign d1_wgs_addr_high_wren      = (csb_addr == REG_D1_WGS_ADDR_HIGH)     & csb_wr_en;
assign d1_wgs_addr_low_wren       = (csb_addr == REG_D1_WGS_ADDR_LOW)      & csb_wr_en;
assign d1_wmb_addr_high_wren      = (csb_addr == REG_D1_WMB_ADDR_HIGH)     & csb_wr_en;
assign d1_wmb_addr_low_wren       = (csb_addr == REG_D1_WMB_ADDR_LOW)      & csb_wr_en;
assign d1_wmb_bytes_wren          = (csb_addr == REG_D1_WMB_BYTES)         & csb_wr_en;
assign d1_mean_format_wren        = (csb_addr == REG_D1_MEAN_FORMAT)       & csb_wr_en;
assign d1_mean_global_0_wren     = (csb_addr == REG_D1_MEAN_GLOBAL_0)     & csb_wr_en;
assign d1_mean_global_1_wren     = (csb_addr == REG_D1_MEAN_GLOBAL_1)     & csb_wr_en;
assign d1_cvt_cfg_wren            = (csb_addr == REG_D1_CVT_CFG)            & csb_wr_en;
assign d1_cvt_offset_wren         = (csb_addr == REG_D1_CVT_OFFSET)        & csb_wr_en;
assign d1_cvt_scale_wren          = (csb_addr == REG_D1_CVT_SCALE)         & csb_wr_en;
assign d1_conv_stride_wren        = (csb_addr == REG_D1_CONV_STRIDE)       & csb_wr_en;
assign d1_zero_padding_wren       = (csb_addr == REG_D1_ZERO_PADDING)      & csb_wr_en;
assign d1_zero_padding_value_wren = (csb_addr == REG_D1_ZERO_PADDING_VALUE) & csb_wr_en;
assign d1_bank_wren               = (csb_addr == REG_D1_BANK)              & csb_wr_en;
assign d1_nan_flush_to_zero_wren  = (csb_addr == REG_D1_NAN_FLUSH_TO_ZERO) & csb_wr_en;
assign d1_perf_enable_wren        = (csb_addr == REG_D1_PERF_ENABLE)       & csb_wr_en;
assign d1_cya_wren                = (csb_addr == REG_D1_CYA)               & csb_wr_en;

//===============================================================
// REGISTER WRITE LOGIC - SINGLE REGISTERS
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg_arb_weight_r <= 4'd0;
    reg_arb_wmb_r <= 4'd0;
    reg_producer_r <= 1'd0;
  end else begin
    if (reg_arbiter_0_wren)
      reg_arb_weight_r <= csb_wdat[3:0];
    if (reg_arbiter_0_wren)
      reg_arb_wmb_r <= csb_wdat[7:4];
    if (reg_pointer_0_wren)
      reg_producer_r <= csb_wdat[0];
  end
end

//===============================================================
// REGISTER WRITE LOGIC - D0 REGISTERS
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d0_op_en_r <= 1'b0;
    d0_conv_mode_r <= 1'b0;
    d0_in_precision_r <= 2'd0;
    d0_proc_precision_r <= 2'd0;
    d0_data_reuse_r <= 1'b0;
    d0_weight_reuse_r <= 1'b0;
    d0_skip_data_rls_r <= 1'b0;
    d0_skip_weight_rls_r <= 1'b0;
    d0_nan_to_zero_r <= 1'b0;
    d0_cvt_en_r <= 1'b0;
    d0_cvt_truncate_r <= 6'd0;
    d0_datain_ram_type_r <= 1'b0;
    d0_datain_format_r <= 1'b0;
    d0_pixel_mapping_r <= 1'b0;
    d0_pixel_sign_override_r <= 1'b0;
    d0_pixel_format_r <= 6'd0;
    d0_line_packed_r <= 1'b0;
    d0_surf_packed_r <= 1'b0;
    d0_mean_format_r <= 1'b0;
    d0_weight_format_r <= 1'b0;
    d0_weight_ram_type_r <= 1'b0;
    d0_dma_en_r <= 1'b0;
    d0_data_bank_r <= 4'd0;
    d0_weight_bank_r <= 4'd0;
    d0_batches_r <= 5'd0;
    d0_conv_x_stride_r <= 3'd0;
    d0_conv_y_stride_r <= 3'd0;
    d0_rsv_height_r <= 3'd0;
    d0_rsv_y_index_r <= 5'd0;
    d0_pixel_x_offset_r <= 5'd0;
    d0_pixel_y_offset_r <= 3'd0;
    d0_rsv_per_line_r <= 10'd0;
    d0_rsv_per_uv_line_r <= 10'd0;
    d0_pad_bottom_r <= 6'd0;
    d0_pad_left_r <= 5'd0;
    d0_pad_right_r <= 6'd0;
    d0_pad_top_r <= 5'd0;
    d0_datain_height_r <= 13'd0;
    d0_datain_width_r <= 13'd0;
    d0_datain_channel_r <= 13'd0;
    d0_datain_height_ext_r <= 13'd0;
    d0_datain_width_ext_r <= 13'd0;
    d0_entries_r <= 12'd0;
    d0_grains_r <= 12'd0;
    d0_batch_stride_r <= 27'd0;
    d0_line_stride_r <= 27'd0;
    d0_uv_line_stride_r <= 27'd0;
    d0_surf_stride_r <= 27'd0;
    d0_cvt_offset_r <= 16'd0;
    d0_cvt_scale_r <= 16'd0;
    d0_mean_gu_r <= 16'd0;
    d0_mean_ry_r <= 16'd0;
    d0_mean_ax_r <= 16'd0;
    d0_mean_bv_r <= 16'd0;
    d0_pad_value_r <= 16'd0;
    d0_byte_per_kernel_r <= 18'd0;
    d0_weight_kernel_r <= 13'd0;
    d0_weight_bytes_r <= 25'd0;
    d0_datain_addr_low_0_r <= 27'd0;
    d0_datain_addr_low_1_r <= 27'd0;
    d0_datain_addr_high_0_r <= 32'd0;
    d0_datain_addr_high_1_r <= 32'd0;
    d0_weight_addr_low_r <= 27'd0;
    d0_weight_addr_high_r <= 32'd0;
    d0_wgs_addr_low_r <= 27'd0;
    d0_wgs_addr_high_r <= 32'd0;
    d0_wmb_addr_low_r <= 27'd0;
    d0_wmb_addr_high_r <= 32'd0;
    d0_wmb_bytes_r <= 21'd0;
    d0_cya_r <= 32'd0;
  end else begin
    if (d0_misc_cfg_wren) begin
      d0_conv_mode_r <= csb_wdat[0];
      d0_in_precision_r <= csb_wdat[2:1];
      d0_proc_precision_r <= csb_wdat[4:3];
      d0_data_reuse_r <= csb_wdat[5];
      d0_weight_reuse_r <= csb_wdat[6];
      d0_skip_data_rls_r <= csb_wdat[7];
      d0_skip_weight_rls_r <= csb_wdat[8];
      d0_nan_to_zero_r <= csb_wdat[9];
    end
    if (d0_op_enable_wren)
      d0_op_en_r <= csb_wdat[0];
    if (d0_datain_format_wren) begin
      d0_datain_format_r <= csb_wdat[0];
      d0_pixel_format_r <= csb_wdat[6:1];
      d0_pixel_mapping_r <= csb_wdat[7];
      d0_pixel_sign_override_r <= csb_wdat[8];
    end
    if (d0_datain_size_0_wren) begin
      d0_datain_width_r <= csb_wdat[12:0];
      d0_datain_height_r <= csb_wdat[25:13];
    end
    if (d0_datain_size_1_wren)
      d0_datain_channel_r <= csb_wdat[12:0];
    if (d0_datain_size_ext_0_wren) begin
      d0_datain_width_ext_r <= csb_wdat[12:0];
      d0_datain_height_ext_r <= csb_wdat[25:13];
    end
    if (d0_pixel_offset_wren) begin
      d0_pixel_x_offset_r <= csb_wdat[4:0];
      d0_pixel_y_offset_r <= csb_wdat[7:5];
    end
    if (d0_dain_ram_type_wren)
      d0_datain_ram_type_r <= csb_wdat[0];
    if (d0_dain_addr_high_0_wren)
      d0_datain_addr_high_0_r <= csb_wdat[31:0];
    if (d0_dain_addr_low_0_wren)
      d0_datain_addr_low_0_r <= csb_wdat[26:0];
    if (d0_dain_addr_high_1_wren)
      d0_datain_addr_high_1_r <= csb_wdat[31:0];
    if (d0_dain_addr_low_1_wren)
      d0_datain_addr_low_1_r <= csb_wdat[26:0];
    if (d0_line_stride_wren)
      d0_line_stride_r <= csb_wdat[26:0];
    if (d0_line_uv_stride_wren)
      d0_uv_line_stride_r <= csb_wdat[26:0];
    if (d0_surf_stride_wren)
      d0_surf_stride_r <= csb_wdat[26:0];
    if (d0_dain_map_wren) begin
      d0_line_packed_r <= csb_wdat[0];
      d0_surf_packed_r <= csb_wdat[1];
    end
    if (d0_rsv_x_cfg_wren) begin
      d0_rsv_per_line_r <= csb_wdat[9:0];
      d0_rsv_per_uv_line_r <= csb_wdat[19:10];
    end
    if (d0_rsv_y_cfg_wren) begin
      d0_rsv_height_r <= csb_wdat[2:0];
      d0_rsv_y_index_r <= csb_wdat[7:3];
    end
    if (d0_batch_number_wren)
      d0_batches_r <= csb_wdat[4:0];
    if (d0_batch_stride_wren)
      d0_batch_stride_r <= csb_wdat[26:0];
    if (d0_entry_per_slice_wren)
      d0_entries_r <= csb_wdat[11:0];
    if (d0_fetch_grain_wren)
      d0_grains_r <= csb_wdat[11:0];
    if (d0_weight_format_wren)
      d0_weight_format_r <= csb_wdat[0];
    if (d0_weight_size_1_wren)
      d0_weight_kernel_r <= csb_wdat[12:0];
    if (d0_weight_ram_type_wren)
      d0_weight_ram_type_r <= csb_wdat[0];
    if (d0_weight_addr_high_wren)
      d0_weight_addr_high_r <= csb_wdat[31:0];
    if (d0_weight_addr_low_wren)
      d0_weight_addr_low_r <= csb_wdat[26:0];
    if (d0_weight_bytes_wren)
      d0_weight_bytes_r <= csb_wdat[24:0];
    if (d0_wgs_addr_high_wren)
      d0_wgs_addr_high_r <= csb_wdat[31:0];
    if (d0_wgs_addr_low_wren)
      d0_wgs_addr_low_r <= csb_wdat[26:0];
    if (d0_wmb_addr_high_wren)
      d0_wmb_addr_high_r <= csb_wdat[31:0];
    if (d0_wmb_addr_low_wren)
      d0_wmb_addr_low_r <= csb_wdat[26:0];
    if (d0_wmb_bytes_wren)
      d0_wmb_bytes_r <= csb_wdat[20:0];
    if (d0_mean_format_wren)
      d0_mean_format_r <= csb_wdat[0];
    if (d0_mean_global_0_wren) begin
      d0_mean_ry_r <= csb_wdat[15:0];
      d0_mean_gu_r <= csb_wdat[31:16];
    end
    if (d0_mean_global_1_wren) begin
      d0_mean_bv_r <= csb_wdat[15:0];
      d0_mean_ax_r <= csb_wdat[31:16];
    end
    if (d0_cvt_cfg_wren) begin
      d0_cvt_en_r <= csb_wdat[0];
      d0_cvt_truncate_r <= csb_wdat[6:1];
    end
    if (d0_cvt_offset_wren)
      d0_cvt_offset_r <= csb_wdat[15:0];
    if (d0_cvt_scale_wren)
      d0_cvt_scale_r <= csb_wdat[15:0];
    if (d0_conv_stride_wren) begin
      d0_conv_x_stride_r <= csb_wdat[2:0];
      d0_conv_y_stride_r <= csb_wdat[5:3];
    end
    if (d0_zero_padding_wren) begin
      d0_pad_left_r <= csb_wdat[4:0];
      d0_pad_right_r <= csb_wdat[10:6];
      d0_pad_top_r <= csb_wdat[16:12];
      d0_pad_bottom_r <= csb_wdat[22:18];
    end
    if (d0_zero_padding_value_wren)
      d0_pad_value_r <= csb_wdat[15:0];
    if (d0_bank_wren) begin
      d0_data_bank_r <= csb_wdat[3:0];
      d0_weight_bank_r <= csb_wdat[7:4];
    end
    if (d0_nan_flush_to_zero_wren)
      d0_nan_to_zero_r <= csb_wdat[0];
    if (d0_perf_enable_wren)
      d0_dma_en_r <= csb_wdat[0];
    if (d0_cya_wren)
      d0_cya_r <= csb_wdat[31:0];
  end
end

//===============================================================
// REGISTER WRITE LOGIC - D1 REGISTERS
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d1_op_en_r <= 1'b0;
    d1_conv_mode_r <= 1'b0;
    d1_in_precision_r <= 2'd0;
    d1_proc_precision_r <= 2'd0;
    d1_data_reuse_r <= 1'b0;
    d1_weight_reuse_r <= 1'b0;
    d1_skip_data_rls_r <= 1'b0;
    d1_skip_weight_rls_r <= 1'b0;
    d1_nan_to_zero_r <= 1'b0;
    d1_cvt_en_r <= 1'b0;
    d1_cvt_truncate_r <= 6'd0;
    d1_datain_ram_type_r <= 1'b0;
    d1_datain_format_r <= 1'b0;
    d1_pixel_mapping_r <= 1'b0;
    d1_pixel_sign_override_r <= 1'b0;
    d1_pixel_format_r <= 6'd0;
    d1_line_packed_r <= 1'b0;
    d1_surf_packed_r <= 1'b0;
    d1_mean_format_r <= 1'b0;
    d1_weight_format_r <= 1'b0;
    d1_weight_ram_type_r <= 1'b0;
    d1_dma_en_r <= 1'b0;
    d1_data_bank_r <= 4'd0;
    d1_weight_bank_r <= 4'd0;
    d1_batches_r <= 5'd0;
    d1_conv_x_stride_r <= 3'd0;
    d1_conv_y_stride_r <= 3'd0;
    d1_rsv_height_r <= 3'd0;
    d1_rsv_y_index_r <= 5'd0;
    d1_pixel_x_offset_r <= 5'd0;
    d1_pixel_y_offset_r <= 3'd0;
    d1_rsv_per_line_r <= 10'd0;
    d1_rsv_per_uv_line_r <= 10'd0;
    d1_pad_bottom_r <= 6'd0;
    d1_pad_left_r <= 5'd0;
    d1_pad_right_r <= 6'd0;
    d1_pad_top_r <= 5'd0;
    d1_datain_height_r <= 13'd0;
    d1_datain_width_r <= 13'd0;
    d1_datain_channel_r <= 13'd0;
    d1_datain_height_ext_r <= 13'd0;
    d1_datain_width_ext_r <= 13'd0;
    d1_entries_r <= 12'd0;
    d1_grains_r <= 12'd0;
    d1_batch_stride_r <= 27'd0;
    d1_line_stride_r <= 27'd0;
    d1_uv_line_stride_r <= 27'd0;
    d1_surf_stride_r <= 27'd0;
    d1_cvt_offset_r <= 16'd0;
    d1_cvt_scale_r <= 16'd0;
    d1_mean_gu_r <= 16'd0;
    d1_mean_ry_r <= 16'd0;
    d1_mean_ax_r <= 16'd0;
    d1_mean_bv_r <= 16'd0;
    d1_pad_value_r <= 16'd0;
    d1_byte_per_kernel_r <= 18'd0;
    d1_weight_kernel_r <= 13'd0;
    d1_weight_bytes_r <= 25'd0;
    d1_datain_addr_low_0_r <= 27'd0;
    d1_datain_addr_low_1_r <= 27'd0;
    d1_datain_addr_high_0_r <= 32'd0;
    d1_datain_addr_high_1_r <= 32'd0;
    d1_weight_addr_low_r <= 27'd0;
    d1_weight_addr_high_r <= 32'd0;
    d1_wgs_addr_low_r <= 27'd0;
    d1_wgs_addr_high_r <= 32'd0;
    d1_wmb_addr_low_r <= 27'd0;
    d1_wmb_addr_high_r <= 32'd0;
    d1_wmb_bytes_r <= 21'd0;
    d1_cya_r <= 32'd0;
  end else begin
    if (d1_misc_cfg_wren) begin
      d1_conv_mode_r <= csb_wdat[0];
      d1_in_precision_r <= csb_wdat[2:1];
      d1_proc_precision_r <= csb_wdat[4:3];
      d1_data_reuse_r <= csb_wdat[5];
      d1_weight_reuse_r <= csb_wdat[6];
      d1_skip_data_rls_r <= csb_wdat[7];
      d1_skip_weight_rls_r <= csb_wdat[8];
      d1_nan_to_zero_r <= csb_wdat[9];
    end
    if (d1_op_enable_wren)
      d1_op_en_r <= csb_wdat[0];
    if (d1_datain_format_wren) begin
      d1_datain_format_r <= csb_wdat[0];
      d1_pixel_format_r <= csb_wdat[6:1];
      d1_pixel_mapping_r <= csb_wdat[7];
      d1_pixel_sign_override_r <= csb_wdat[8];
    end
    if (d1_datain_size_0_wren) begin
      d1_datain_width_r <= csb_wdat[12:0];
      d1_datain_height_r <= csb_wdat[25:13];
    end
    if (d1_datain_size_1_wren)
      d1_datain_channel_r <= csb_wdat[12:0];
    if (d1_datain_size_ext_0_wren) begin
      d1_datain_width_ext_r <= csb_wdat[12:0];
      d1_datain_height_ext_r <= csb_wdat[25:13];
    end
    if (d1_pixel_offset_wren) begin
      d1_pixel_x_offset_r <= csb_wdat[4:0];
      d1_pixel_y_offset_r <= csb_wdat[7:5];
    end
    if (d1_dain_ram_type_wren)
      d1_datain_ram_type_r <= csb_wdat[0];
    if (d1_dain_addr_high_0_wren)
      d1_datain_addr_high_0_r <= csb_wdat[31:0];
    if (d1_dain_addr_low_0_wren)
      d1_datain_addr_low_0_r <= csb_wdat[26:0];
    if (d1_dain_addr_high_1_wren)
      d1_datain_addr_high_1_r <= csb_wdat[31:0];
    if (d1_dain_addr_low_1_wren)
      d1_datain_addr_low_1_r <= csb_wdat[26:0];
    if (d1_line_stride_wren)
      d1_line_stride_r <= csb_wdat[26:0];
    if (d1_line_uv_stride_wren)
      d1_uv_line_stride_r <= csb_wdat[26:0];
    if (d1_surf_stride_wren)
      d1_surf_stride_r <= csb_wdat[26:0];
    if (d1_dain_map_wren) begin
      d1_line_packed_r <= csb_wdat[0];
      d1_surf_packed_r <= csb_wdat[1];
    end
    if (d1_rsv_x_cfg_wren) begin
      d1_rsv_per_line_r <= csb_wdat[9:0];
      d1_rsv_per_uv_line_r <= csb_wdat[19:10];
    end
    if (d1_rsv_y_cfg_wren) begin
      d1_rsv_height_r <= csb_wdat[2:0];
      d1_rsv_y_index_r <= csb_wdat[7:3];
    end
    if (d1_batch_number_wren)
      d1_batches_r <= csb_wdat[4:0];
    if (d1_batch_stride_wren)
      d1_batch_stride_r <= csb_wdat[26:0];
    if (d1_entry_per_slice_wren)
      d1_entries_r <= csb_wdat[11:0];
    if (d1_fetch_grain_wren)
      d1_grains_r <= csb_wdat[11:0];
    if (d1_weight_format_wren)
      d1_weight_format_r <= csb_wdat[0];
    if (d1_weight_size_1_wren)
      d1_weight_kernel_r <= csb_wdat[12:0];
    if (d1_weight_ram_type_wren)
      d1_weight_ram_type_r <= csb_wdat[0];
    if (d1_weight_addr_high_wren)
      d1_weight_addr_high_r <= csb_wdat[31:0];
    if (d1_weight_addr_low_wren)
      d1_weight_addr_low_r <= csb_wdat[26:0];
    if (d1_weight_bytes_wren)
      d1_weight_bytes_r <= csb_wdat[24:0];
    if (d1_wgs_addr_high_wren)
      d1_wgs_addr_high_r <= csb_wdat[31:0];
    if (d1_wgs_addr_low_wren)
      d1_wgs_addr_low_r <= csb_wdat[26:0];
    if (d1_wmb_addr_high_wren)
      d1_wmb_addr_high_r <= csb_wdat[31:0];
    if (d1_wmb_addr_low_wren)
      d1_wmb_addr_low_r <= csb_wdat[26:0];
    if (d1_wmb_bytes_wren)
      d1_wmb_bytes_r <= csb_wdat[20:0];
    if (d1_mean_format_wren)
      d1_mean_format_r <= csb_wdat[0];
    if (d1_mean_global_0_wren) begin
      d1_mean_ry_r <= csb_wdat[15:0];
      d1_mean_gu_r <= csb_wdat[31:16];
    end
    if (d1_mean_global_1_wren) begin
      d1_mean_bv_r <= csb_wdat[15:0];
      d1_mean_ax_r <= csb_wdat[31:16];
    end
    if (d1_cvt_cfg_wren) begin
      d1_cvt_en_r <= csb_wdat[0];
      d1_cvt_truncate_r <= csb_wdat[6:1];
    end
    if (d1_cvt_offset_wren)
      d1_cvt_offset_r <= csb_wdat[15:0];
    if (d1_cvt_scale_wren)
      d1_cvt_scale_r <= csb_wdat[15:0];
    if (d1_conv_stride_wren) begin
      d1_conv_x_stride_r <= csb_wdat[2:0];
      d1_conv_y_stride_r <= csb_wdat[5:3];
    end
    if (d1_zero_padding_wren) begin
      d1_pad_left_r <= csb_wdat[4:0];
      d1_pad_right_r <= csb_wdat[10:6];
      d1_pad_top_r <= csb_wdat[16:12];
      d1_pad_bottom_r <= csb_wdat[22:18];
    end
    if (d1_zero_padding_value_wren)
      d1_pad_value_r <= csb_wdat[15:0];
    if (d1_bank_wren) begin
      d1_data_bank_r <= csb_wdat[3:0];
      d1_weight_bank_r <= csb_wdat[7:4];
    end
    if (d1_nan_flush_to_zero_wren)
      d1_nan_to_zero_r <= csb_wdat[0];
    if (d1_perf_enable_wren)
      d1_dma_en_r <= csb_wdat[0];
    if (d1_cya_wren)
      d1_cya_r <= csb_wdat[31:0];
  end
end

//===============================================================
// OP_EN TRIGGER DETECTION
//===============================================================
// Detect rising edge of OP_EN for D0
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d0_op_en_wren_d1 <= 1'b0;
  end else begin
    d0_op_en_wren_d1 <= d0_op_enable_wren;
  end
end
assign reg2dp_d0_op_en_trigger = d0_op_enable_wren & ~d0_op_en_wren_d1;

// Detect rising edge of OP_EN for D1
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d1_op_en_wren_d1 <= 1'b0;
  end else begin
    d1_op_en_wren_d1 <= d1_op_enable_wren;
  end
end
assign reg2dp_d1_op_en_trigger = d1_op_enable_wren & ~d1_op_en_wren_d1;

//===============================================================
// OUTPUT ASSIGNMENTS - SHARED REGISTERS
//===============================================================
assign reg2dp_arb_weight = reg_arb_weight_r;
assign reg2dp_arb_wmb = reg_arb_wmb_r;
assign reg2dp_producer = reg_producer_r;

//===============================================================
// OUTPUT ASSIGNMENTS - D0 REGISTERS
//===============================================================
assign reg2dp_d0_op_en = d0_op_en_r;
assign reg2dp_d0_data_bank = d0_data_bank_r;
assign reg2dp_d0_weight_bank = d0_weight_bank_r;
assign reg2dp_d0_batches = d0_batches_r;
assign reg2dp_d0_batch_stride = d0_batch_stride_r;
assign reg2dp_d0_conv_x_stride = d0_conv_x_stride_r;
assign reg2dp_d0_conv_y_stride = d0_conv_y_stride_r;
assign reg2dp_d0_cvt_en = d0_cvt_en_r;
assign reg2dp_d0_cvt_truncate = d0_cvt_truncate_r;
assign reg2dp_d0_cvt_offset = d0_cvt_offset_r;
assign reg2dp_d0_cvt_scale = d0_cvt_scale_r;
assign reg2dp_d0_cya = d0_cya_r;
assign reg2dp_d0_datain_addr_high_0 = d0_datain_addr_high_0_r;
assign reg2dp_d0_datain_addr_high_1 = d0_datain_addr_high_1_r;
assign reg2dp_d0_datain_addr_low_0 = d0_datain_addr_low_0_r;
assign reg2dp_d0_datain_addr_low_1 = d0_datain_addr_low_1_r;
assign reg2dp_d0_line_packed = d0_line_packed_r;
assign reg2dp_d0_surf_packed = d0_surf_packed_r;
assign reg2dp_d0_datain_ram_type = d0_datain_ram_type_r;
assign reg2dp_d0_datain_format = d0_datain_format_r;
assign reg2dp_d0_pixel_format = d0_pixel_format_r;
assign reg2dp_d0_pixel_mapping = d0_pixel_mapping_r;
assign reg2dp_d0_pixel_sign_override = d0_pixel_sign_override_r;
assign reg2dp_d0_datain_height = d0_datain_height_r;
assign reg2dp_d0_datain_width = d0_datain_width_r;
assign reg2dp_d0_datain_channel = d0_datain_channel_r;
assign reg2dp_d0_datain_height_ext = d0_datain_height_ext_r;
assign reg2dp_d0_datain_width_ext = d0_datain_width_ext_r;
assign reg2dp_d0_entries = d0_entries_r;
assign reg2dp_d0_grains = d0_grains_r;
assign reg2dp_d0_line_stride = d0_line_stride_r;
assign reg2dp_d0_uv_line_stride = d0_uv_line_stride_r;
assign reg2dp_d0_mean_format = d0_mean_format_r;
assign reg2dp_d0_mean_gu = d0_mean_gu_r;
assign reg2dp_d0_mean_ry = d0_mean_ry_r;
assign reg2dp_d0_mean_ax = d0_mean_ax_r;
assign reg2dp_d0_mean_bv = d0_mean_bv_r;
assign reg2dp_d0_conv_mode = d0_conv_mode_r;
assign reg2dp_d0_data_reuse = d0_data_reuse_r;
assign reg2dp_d0_in_precision = d0_in_precision_r;
assign reg2dp_d0_proc_precision = d0_proc_precision_r;
assign reg2dp_d0_skip_data_rls = d0_skip_data_rls_r;
assign reg2dp_d0_skip_weight_rls = d0_skip_weight_rls_r;
assign reg2dp_d0_weight_reuse = d0_weight_reuse_r;
assign reg2dp_d0_nan_to_zero = d0_nan_to_zero_r;
assign reg2dp_d0_dma_en = d0_dma_en_r;
assign reg2dp_d0_pixel_x_offset = d0_pixel_x_offset_r;
assign reg2dp_d0_pixel_y_offset = d0_pixel_y_offset_r;
assign reg2dp_d0_rsv_per_line = d0_rsv_per_line_r;
assign reg2dp_d0_rsv_per_uv_line = d0_rsv_per_uv_line_r;
assign reg2dp_d0_rsv_height = d0_rsv_height_r;
assign reg2dp_d0_rsv_y_index = d0_rsv_y_index_r;
assign reg2dp_d0_surf_stride = d0_surf_stride_r;
assign reg2dp_d0_weight_addr_high = d0_weight_addr_high_r;
assign reg2dp_d0_weight_addr_low = d0_weight_addr_low_r;
assign reg2dp_d0_weight_bytes = d0_weight_bytes_r;
assign reg2dp_d0_weight_format = d0_weight_format_r;
assign reg2dp_d0_weight_ram_type = d0_weight_ram_type_r;
assign reg2dp_d0_byte_per_kernel = d0_byte_per_kernel_r;
assign reg2dp_d0_weight_kernel = d0_weight_kernel_r;
assign reg2dp_d0_wgs_addr_high = d0_wgs_addr_high_r;
assign reg2dp_d0_wgs_addr_low = d0_wgs_addr_low_r;
assign reg2dp_d0_wmb_addr_high = d0_wmb_addr_high_r;
assign reg2dp_d0_wmb_addr_low = d0_wmb_addr_low_r;
assign reg2dp_d0_wmb_bytes = d0_wmb_bytes_r;
assign reg2dp_d0_pad_bottom = d0_pad_bottom_r;
assign reg2dp_d0_pad_left = d0_pad_left_r;
assign reg2dp_d0_pad_right = d0_pad_right_r;
assign reg2dp_d0_pad_top = d0_pad_top_r;
assign reg2dp_d0_pad_value = d0_pad_value_r;

//===============================================================
// OUTPUT ASSIGNMENTS - D1 REGISTERS
//===============================================================
assign reg2dp_d1_op_en = d1_op_en_r;
assign reg2dp_d1_data_bank = d1_data_bank_r;
assign reg2dp_d1_weight_bank = d1_weight_bank_r;
assign reg2dp_d1_batches = d1_batches_r;
assign reg2dp_d1_batch_stride = d1_batch_stride_r;
assign reg2dp_d1_conv_x_stride = d1_conv_x_stride_r;
assign reg2dp_d1_conv_y_stride = d1_conv_y_stride_r;
assign reg2dp_d1_cvt_en = d1_cvt_en_r;
assign reg2dp_d1_cvt_truncate = d1_cvt_truncate_r;
assign reg2dp_d1_cvt_offset = d1_cvt_offset_r;
assign reg2dp_d1_cvt_scale = d1_cvt_scale_r;
assign reg2dp_d1_cya = d1_cya_r;
assign reg2dp_d1_datain_addr_high_0 = d1_datain_addr_high_0_r;
assign reg2dp_d1_datain_addr_high_1 = d1_datain_addr_high_1_r;
assign reg2dp_d1_datain_addr_low_0 = d1_datain_addr_low_0_r;
assign reg2dp_d1_datain_addr_low_1 = d1_datain_addr_low_1_r;
assign reg2dp_d1_line_packed = d1_line_packed_r;
assign reg2dp_d1_surf_packed = d1_surf_packed_r;
assign reg2dp_d1_datain_ram_type = d1_datain_ram_type_r;
assign reg2dp_d1_datain_format = d1_datain_format_r;
assign reg2dp_d1_pixel_format = d1_pixel_format_r;
assign reg2dp_d1_pixel_mapping = d1_pixel_mapping_r;
assign reg2dp_d1_pixel_sign_override = d1_pixel_sign_override_r;
assign reg2dp_d1_datain_height = d1_datain_height_r;
assign reg2dp_d1_datain_width = d1_datain_width_r;
assign reg2dp_d1_datain_channel = d1_datain_channel_r;
assign reg2dp_d1_datain_height_ext = d1_datain_height_ext_r;
assign reg2dp_d1_datain_width_ext = d1_datain_width_ext_r;
assign reg2dp_d1_entries = d1_entries_r;
assign reg2dp_d1_grains = d1_grains_r;
assign reg2dp_d1_line_stride = d1_line_stride_r;
assign reg2dp_d1_uv_line_stride = d1_uv_line_stride_r;
assign reg2dp_d1_mean_format = d1_mean_format_r;
assign reg2dp_d1_mean_gu = d1_mean_gu_r;
assign reg2dp_d1_mean_ry = d1_mean_ry_r;
assign reg2dp_d1_mean_ax = d1_mean_ax_r;
assign reg2dp_d1_mean_bv = d1_mean_bv_r;
assign reg2dp_d1_conv_mode = d1_conv_mode_r;
assign reg2dp_d1_data_reuse = d1_data_reuse_r;
assign reg2dp_d1_in_precision = d1_in_precision_r;
assign reg2dp_d1_proc_precision = d1_proc_precision_r;
assign reg2dp_d1_skip_data_rls = d1_skip_data_rls_r;
assign reg2dp_d1_skip_weight_rls = d1_skip_weight_rls_r;
assign reg2dp_d1_weight_reuse = d1_weight_reuse_r;
assign reg2dp_d1_nan_to_zero = d1_nan_to_zero_r;
assign reg2dp_d1_dma_en = d1_dma_en_r;
assign reg2dp_d1_pixel_x_offset = d1_pixel_x_offset_r;
assign reg2dp_d1_pixel_y_offset = d1_pixel_y_offset_r;
assign reg2dp_d1_rsv_per_line = d1_rsv_per_line_r;
assign reg2dp_d1_rsv_per_uv_line = d1_rsv_per_uv_line_r;
assign reg2dp_d1_rsv_height = d1_rsv_height_r;
assign reg2dp_d1_rsv_y_index = d1_rsv_y_index_r;
assign reg2dp_d1_surf_stride = d1_surf_stride_r;
assign reg2dp_d1_weight_addr_high = d1_weight_addr_high_r;
assign reg2dp_d1_weight_addr_low = d1_weight_addr_low_r;
assign reg2dp_d1_weight_bytes = d1_weight_bytes_r;
assign reg2dp_d1_weight_format = d1_weight_format_r;
assign reg2dp_d1_weight_ram_type = d1_weight_ram_type_r;
assign reg2dp_d1_byte_per_kernel = d1_byte_per_kernel_r;
assign reg2dp_d1_weight_kernel = d1_weight_kernel_r;
assign reg2dp_d1_wgs_addr_high = d1_wgs_addr_high_r;
assign reg2dp_d1_wgs_addr_low = d1_wgs_addr_low_r;
assign reg2dp_d1_wmb_addr_high = d1_wmb_addr_high_r;
assign reg2dp_d1_wmb_addr_low = d1_wmb_addr_low_r;
assign reg2dp_d1_wmb_bytes = d1_wmb_bytes_r;
assign reg2dp_d1_pad_bottom = d1_pad_bottom_r;
assign reg2dp_d1_pad_left = d1_pad_left_r;
assign reg2dp_d1_pad_right = d1_pad_right_r;
assign reg2dp_d1_pad_top = d1_pad_top_r;
assign reg2dp_d1_pad_value = d1_pad_value_r;

//===============================================================
// CSB READ DATA LOGIC
//===============================================================
always @* begin
  case (csb_addr)
    // Single registers
    REG_STATUS_0:         csb_rdat_q = {30'd0, dp2reg_status_1, dp2reg_status_0};
    REG_POINTER_0:        csb_rdat_q = {30'd0, reg2dp_consumer, reg_producer_r};
    REG_ARBITER_0:        csb_rdat_q = {24'd0, reg_arb_wmb_r, reg_arb_weight_r};
    REG_CBUF_FLUSH_STATUS: csb_rdat_q = {31'd0, dp2reg_flush_done};

    // D0 registers
    REG_D0_OP_ENABLE:     csb_rdat_q = {31'd0, d0_op_en_r};
    REG_D0_MISC_CFG:       csb_rdat_q = {22'd0, d0_nan_to_zero_r, d0_skip_weight_rls_r,
                                          d0_skip_data_rls_r, d0_weight_reuse_r,
                                          d0_data_reuse_r, d0_proc_precision_r,
                                          d0_in_precision_r, d0_conv_mode_r};
    REG_D0_DATAIN_FORMAT:  csb_rdat_q = {23'd0, d0_pixel_sign_override_r, d0_pixel_mapping_r,
                                          d0_pixel_format_r, d0_datain_format_r};
    REG_D0_DATAIN_SIZE_0:  csb_rdat_q = {19'd0, d0_datain_height_r, d0_datain_width_r};
    REG_D0_DATAIN_SIZE_1:  csb_rdat_q = {19'd0, d0_datain_channel_r};
    REG_D0_DATAIN_SIZE_EXT_0: csb_rdat_q = {19'd0, d0_datain_height_ext_r, d0_datain_width_ext_r};
    REG_D0_PIXEL_OFFSET:   csb_rdat_q = {24'd0, d0_pixel_y_offset_r, d0_pixel_x_offset_r};
    REG_D0_DAIN_RAM_TYPE:  csb_rdat_q = {31'd0, d0_datain_ram_type_r};
    REG_D0_DAIN_ADDR_HIGH_0: csb_rdat_q = d0_datain_addr_high_0_r;
    REG_D0_DAIN_ADDR_LOW_0: csb_rdat_q = {5'd0, d0_datain_addr_low_0_r};
    REG_D0_DAIN_ADDR_HIGH_1: csb_rdat_q = d0_datain_addr_high_1_r;
    REG_D0_DAIN_ADDR_LOW_1: csb_rdat_q = {5'd0, d0_datain_addr_low_1_r};
    REG_D0_LINE_STRIDE:    csb_rdat_q = {5'd0, d0_line_stride_r};
    REG_D0_LINE_UV_STRIDE: csb_rdat_q = {5'd0, d0_uv_line_stride_r};
    REG_D0_SURF_STRIDE:    csb_rdat_q = {5'd0, d0_surf_stride_r};
    REG_D0_DAIN_MAP:       csb_rdat_q = {30'd0, d0_surf_packed_r, d0_line_packed_r};
    REG_D0_RSV_X_CFG:      csb_rdat_q = {12'd0, d0_rsv_per_uv_line_r, d0_rsv_per_line_r};
    REG_D0_RSV_Y_CFG:      csb_rdat_q = {24'd0, d0_rsv_y_index_r, d0_rsv_height_r};
    REG_D0_BATCH_NUMBER:   csb_rdat_q = {27'd0, d0_batches_r};
    REG_D0_BATCH_STRIDE:   csb_rdat_q = {5'd0, d0_batch_stride_r};
    REG_D0_ENTRY_PER_SLICE: csb_rdat_q = {20'd0, d0_entries_r};
    REG_D0_FETCH_GRAIN:    csb_rdat_q = {20'd0, d0_grains_r};
    REG_D0_WEIGHT_FORMAT:  csb_rdat_q = {31'd0, d0_weight_format_r};
    REG_D0_WEIGHT_SIZE_1:  csb_rdat_q = {19'd0, d0_weight_kernel_r};
    REG_D0_WEIGHT_RAM_TYPE: csb_rdat_q = {31'd0, d0_weight_ram_type_r};
    REG_D0_WEIGHT_ADDR_HIGH: csb_rdat_q = d0_weight_addr_high_r;
    REG_D0_WEIGHT_ADDR_LOW: csb_rdat_q = {5'd0, d0_weight_addr_low_r};
    REG_D0_WEIGHT_BYTES:   csb_rdat_q = {7'd0, d0_weight_bytes_r};
    REG_D0_WGS_ADDR_HIGH:  csb_rdat_q = d0_wgs_addr_high_r;
    REG_D0_WGS_ADDR_LOW:   csb_rdat_q = {5'd0, d0_wgs_addr_low_r};
    REG_D0_WMB_ADDR_HIGH:  csb_rdat_q = d0_wmb_addr_high_r;
    REG_D0_WMB_ADDR_LOW:   csb_rdat_q = {5'd0, d0_wmb_addr_low_r};
    REG_D0_WMB_BYTES:      csb_rdat_q = {11'd0, d0_wmb_bytes_r};
    REG_D0_MEAN_FORMAT:    csb_rdat_q = {31'd0, d0_mean_format_r};
    REG_D0_MEAN_GLOBAL_0:   csb_rdat_q = {d0_mean_gu_r, d0_mean_ry_r};
    REG_D0_MEAN_GLOBAL_1:  csb_rdat_q = {d0_mean_ax_r, d0_mean_bv_r};
    REG_D0_CVT_CFG:         csb_rdat_q = {25'd0, d0_cvt_truncate_r, d0_cvt_en_r};
    REG_D0_CVT_OFFSET:     csb_rdat_q = {16'd0, d0_cvt_offset_r};
    REG_D0_CVT_SCALE:      csb_rdat_q = {16'd0, d0_cvt_scale_r};
    REG_D0_CONV_STRIDE:    csb_rdat_q = {26'd0, d0_conv_y_stride_r, d0_conv_x_stride_r};
    REG_D0_ZERO_PADDING:   csb_rdat_q = {9'd0, d0_pad_bottom_r, d0_pad_top_r,
                                          d0_pad_right_r, d0_pad_left_r};
    REG_D0_ZERO_PADDING_VALUE: csb_rdat_q = {16'd0, d0_pad_value_r};
    REG_D0_BANK:           csb_rdat_q = {24'd0, d0_weight_bank_r, d0_data_bank_r};
    REG_D0_NAN_FLUSH_TO_ZERO: csb_rdat_q = {31'd0, d0_nan_to_zero_r};
    REG_D0_PERF_ENABLE:    csb_rdat_q = {31'd0, d0_dma_en_r};
    REG_D0_CYA:            csb_rdat_q = d0_cya_r;

    // D1 registers
    REG_D1_OP_ENABLE:     csb_rdat_q = {31'd0, d1_op_en_r};
    REG_D1_MISC_CFG:       csb_rdat_q = {22'd0, d1_nan_to_zero_r, d1_skip_weight_rls_r,
                                          d1_skip_data_rls_r, d1_weight_reuse_r,
                                          d1_data_reuse_r, d1_proc_precision_r,
                                          d1_in_precision_r, d1_conv_mode_r};
    REG_D1_DATAIN_FORMAT:  csb_rdat_q = {23'd0, d1_pixel_sign_override_r, d1_pixel_mapping_r,
                                          d1_pixel_format_r, d1_datain_format_r};
    REG_D1_DATAIN_SIZE_0:  csb_rdat_q = {19'd0, d1_datain_height_r, d1_datain_width_r};
    REG_D1_DATAIN_SIZE_1:  csb_rdat_q = {19'd0, d1_datain_channel_r};
    REG_D1_DATAIN_SIZE_EXT_0: csb_rdat_q = {19'd0, d1_datain_height_ext_r, d1_datain_width_ext_r};
    REG_D1_PIXEL_OFFSET:   csb_rdat_q = {24'd0, d1_pixel_y_offset_r, d1_pixel_x_offset_r};
    REG_D1_DAIN_RAM_TYPE:  csb_rdat_q = {31'd0, d1_datain_ram_type_r};
    REG_D1_DAIN_ADDR_HIGH_0: csb_rdat_q = d1_datain_addr_high_0_r;
    REG_D1_DAIN_ADDR_LOW_0: csb_rdat_q = {5'd0, d1_datain_addr_low_0_r};
    REG_D1_DAIN_ADDR_HIGH_1: csb_rdat_q = d1_datain_addr_high_1_r;
    REG_D1_DAIN_ADDR_LOW_1: csb_rdat_q = {5'd0, d1_datain_addr_low_1_r};
    REG_D1_LINE_STRIDE:    csb_rdat_q = {5'd0, d1_line_stride_r};
    REG_D1_LINE_UV_STRIDE: csb_rdat_q = {5'd0, d1_uv_line_stride_r};
    REG_D1_SURF_STRIDE:    csb_rdat_q = {5'd0, d1_surf_stride_r};
    REG_D1_DAIN_MAP:       csb_rdat_q = {30'd0, d1_surf_packed_r, d1_line_packed_r};
    REG_D1_RSV_X_CFG:      csb_rdat_q = {12'd0, d1_rsv_per_uv_line_r, d1_rsv_per_line_r};
    REG_D1_RSV_Y_CFG:      csb_rdat_q = {24'd0, d1_rsv_y_index_r, d1_rsv_height_r};
    REG_D1_BATCH_NUMBER:   csb_rdat_q = {27'd0, d1_batches_r};
    REG_D1_BATCH_STRIDE:   csb_rdat_q = {5'd0, d1_batch_stride_r};
    REG_D1_ENTRY_PER_SLICE: csb_rdat_q = {20'd0, d1_entries_r};
    REG_D1_FETCH_GRAIN:    csb_rdat_q = {20'd0, d1_grains_r};
    REG_D1_WEIGHT_FORMAT:  csb_rdat_q = {31'd0, d1_weight_format_r};
    REG_D1_WEIGHT_SIZE_1:  csb_rdat_q = {19'd0, d1_weight_kernel_r};
    REG_D1_WEIGHT_RAM_TYPE: csb_rdat_q = {31'd0, d1_weight_ram_type_r};
    REG_D1_WEIGHT_ADDR_HIGH: csb_rdat_q = d1_weight_addr_high_r;
    REG_D1_WEIGHT_ADDR_LOW: csb_rdat_q = {5'd0, d1_weight_addr_low_r};
    REG_D1_WEIGHT_BYTES:   csb_rdat_q = {7'd0, d1_weight_bytes_r};
    REG_D1_WGS_ADDR_HIGH:  csb_rdat_q = d1_wgs_addr_high_r;
    REG_D1_WGS_ADDR_LOW:   csb_rdat_q = {5'd0, d1_wgs_addr_low_r};
    REG_D1_WMB_ADDR_HIGH:  csb_rdat_q = d1_wmb_addr_high_r;
    REG_D1_WMB_ADDR_LOW:   csb_rdat_q = {5'd0, d1_wmb_addr_low_r};
    REG_D1_WMB_BYTES:      csb_rdat_q = {11'd0, d1_wmb_bytes_r};
    REG_D1_MEAN_FORMAT:    csb_rdat_q = {31'd0, d1_mean_format_r};
    REG_D1_MEAN_GLOBAL_0:   csb_rdat_q = {d1_mean_gu_r, d1_mean_ry_r};
    REG_D1_MEAN_GLOBAL_1:  csb_rdat_q = {d1_mean_ax_r, d1_mean_bv_r};
    REG_D1_CVT_CFG:         csb_rdat_q = {25'd0, d1_cvt_truncate_r, d1_cvt_en_r};
    REG_D1_CVT_OFFSET:     csb_rdat_q = {16'd0, d1_cvt_offset_r};
    REG_D1_CVT_SCALE:      csb_rdat_q = {16'd0, d1_cvt_scale_r};
    REG_D1_CONV_STRIDE:    csb_rdat_q = {26'd0, d1_conv_y_stride_r, d1_conv_x_stride_r};
    REG_D1_ZERO_PADDING:   csb_rdat_q = {9'd0, d1_pad_bottom_r, d1_pad_top_r,
                                          d1_pad_right_r, d1_pad_left_r};
    REG_D1_ZERO_PADDING_VALUE: csb_rdat_q = {16'd0, d1_pad_value_r};
    REG_D1_BANK:           csb_rdat_q = {24'd0, d1_weight_bank_r, d1_data_bank_r};
    REG_D1_NAN_FLUSH_TO_ZERO: csb_rdat_q = {31'd0, d1_nan_to_zero_r};
    REG_D1_PERF_ENABLE:    csb_rdat_q = {31'd0, d1_dma_en_r};
    REG_D1_CYA:            csb_rdat_q = d1_cya_r;

    default: csb_rdat_q = 32'd0;
  endcase
end

assign csb_rdat = csb_rdat_q;

// NPU ready - always ready when not in reset
assign npu_rdy = nvdla_core_rstn;

endmodule // NV_NVDLA_CDMA_reg_new