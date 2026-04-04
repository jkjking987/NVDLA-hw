// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_reg_model_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP Register Model Module
// - Stores all CDP registers in two groups (group_0 and group_1)
// - Handles dual-entity register architecture with producer/consumer pointer
// - Shadow register implementation for smooth context switching
// - LUT access register handling
//
// Register Groups:
//   group_0: Active when producer_pointer = 0
//   group_1: Active when producer_pointer = 1
//
// Key behaviors:
//   - Registers below 0xF00 are common (not shadowed)
//   - Registers at 0xF00 and above are shadowed (dual-entity)
//   - OP_ENABLE register triggers operation start when written with 1
//   - STATUS register reflects current operation state
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_reg_model_new (
   nvdla_core_clk                        //|< i
  ,nvdla_core_rstn                       //|< i
  // CSB interface
  ,csb_addr                             //|< i [11:0]
  ,csb_wdat                             //|< i [31:0]
  ,csb_rd_en                            //|< i
  ,csb_wr_en                            //|< i
  ,csb_rdat                             //|> o [31:0]
  // Register outputs
  ,nvdla_cdp_cfg_op_en                  //|> o [31:0]
  ,nvdla_cdp_status_0                   //|> o [31:0]
  ,nvdla_cdp_status_1                   //|> o [31:0]
  ,nvdla_cdp_pointer                    //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_access_cfg     //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_access_data     //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_cfg            //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_info           //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_le_start_low   //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_le_start_high  //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_le_end_low     //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_le_end_high    //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_start_low   //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_start_high  //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_end_low     //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_end_high    //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_le_slope_scale //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_le_slope_shift //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_slope_scale //|> o [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_slope_shift //|> o [31:0]
  );

//===============================================================
// PORT DECLARATION
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB interface
input  [11:0] csb_addr;
input  [31:0] csb_wdat;
input         csb_rd_en;
input         csb_wr_en;
output [31:0] csb_rdat;

// Register outputs
output [31:0] nvdla_cdp_cfg_op_en;
output [31:0] nvdla_cdp_status_0;
output [31:0] nvdla_cdp_status_1;
output [31:0] nvdla_cdp_pointer;
output [31:0] nvdla_cdp_reg2dp_lut_access_cfg;
output [31:0] nvdla_cdp_reg2dp_lut_access_data;
output [31:0] nvdla_cdp_reg2dp_lut_cfg;
output [31:0] nvdla_cdp_reg2dp_lut_info;
output [31:0] nvdla_cdp_reg2dp_lut_le_start_low;
output [31:0] nvdla_cdp_reg2dp_lut_le_start_high;
output [31:0] nvdla_cdp_reg2dp_lut_le_end_low;
output [31:0] nvdla_cdp_reg2dp_lut_le_end_high;
output [31:0] nvdla_cdp_reg2dp_lut_lo_start_low;
output [31:0] nvdla_cdp_reg2dp_lut_lo_start_high;
output [31:0] nvdla_cdp_reg2dp_lut_lo_end_low;
output [31:0] nvdla_cdp_reg2dp_lut_lo_end_high;
output [31:0] nvdla_cdp_reg2dp_lut_le_slope_scale;
output [31:0] nvdla_cdp_reg2dp_lut_le_slope_shift;
output [31:0] nvdla_cdp_reg2dp_lut_lo_slope_scale;
output [31:0] nvdla_cdp_reg2dp_lut_lo_slope_shift;

//===============================================================
// REGISTER ADDRESS DEFINITIONS
//===============================================================
// Common register addresses (not shadowed)
localparam ADDR_STATUS        = 12'h000;
localparam ADDR_POINTER       = 12'h004;
localparam ADDR_LUT_ACCESS_CFG = 12'h008;
localparam ADDR_LUT_ACCESS_DATA= 12'h00C;
localparam ADDR_LUT_CFG        = 12'h010;
localparam ADDR_LUT_INFO       = 12'h014;
localparam ADDR_LUT_LE_START_LOW  = 12'h018;
localparam ADDR_LUT_LE_START_HIGH = 12'h01C;
localparam ADDR_LUT_LE_END_LOW    = 12'h020;
localparam ADDR_LUT_LE_END_HIGH    = 12'h024;
localparam ADDR_LUT_LO_START_LOW  = 12'h028;
localparam ADDR_LUT_LO_START_HIGH = 12'h02C;
localparam ADDR_LUT_LO_END_LOW    = 12'h030;
localparam ADDR_LUT_LO_END_HIGH    = 12'h034;
localparam ADDR_LUT_LE_SLOPE_SCALE = 12'h038;
localparam ADDR_LUT_LE_SLOPE_SHIFT  = 12'h03C;
localparam ADDR_LUT_LO_SLOPE_SCALE = 12'h040;
localparam ADDR_LUT_LO_SLOPE_SHIFT  = 12'h044;

// Data path register addresses (shadowed - group specific)
localparam ADDR_OP_ENABLE       = 12'hF00;
localparam ADDR_FUNC_BYPASS     = 12'hF04;
localparam ADDR_DST_BASE_ADDR_LOW  = 12'hF08;
localparam ADDR_DST_BASE_ADDR_HIGH = 12'hF0C;
localparam ADDR_DST_LINE_STRIDE    = 12'hF10;
localparam ADDR_DST_SURFACE_STRIDE = 12'hF14;
localparam ADDR_DST_DMA_CFG        = 12'hF18;
localparam ADDR_DATA_FORMAT        = 12'hF1C;
localparam ADDR_NAN_FLUSH_TO_ZERO  = 12'hF20;
localparam ADDR_LRN_CFG             = 12'hF24;
localparam ADDR_DATIN_OFFSET       = 12'hF28;
localparam ADDR_DATIN_SCALE        = 12'hF2C;
localparam ADDR_DATIN_SHIFTER      = 12'hF30;
localparam ADDR_DATOUT_OFFSET      = 12'hF34;
localparam ADDR_DATOUT_SCALE       = 12'hF38;
localparam ADDR_DATOUT_SHIFTER     = 12'hF3C;
localparam ADDR_PERF_ENABLE        = 12'hF40;
localparam ADDR_PERF_WRITE_STALL   = 12'hF44;
localparam ADDR_CYA                = 12'hFFC;

//===============================================================
// WIRE DECLARATIONS
//===============================================================
wire   [11:0] reg_addr;
wire   [31:0] reg_wdata;
wire          reg_read_en;
wire          reg_write_en;
wire          producer_ptr;

// Write enable signals for shadow registers
wire          wr_en_common;      // Write to common registers
wire          wr_en_group0;     // Write to group_0 shadow registers
wire          wr_en_group1;      // Write to group_1 shadow registers

//===============================================================
// REGISTER STATE
//===============================================================
// Producer pointer register
reg  [31:0] pointer_reg;
reg  [31:0] status_0_reg;
reg  [31:0] status_1_reg;

// Common registers (not shadowed)
reg  [31:0] lut_access_cfg_reg;
reg  [31:0] lut_access_data_reg;
reg  [31:0] lut_cfg_reg;
reg  [31:0] lut_info_reg;
reg  [31:0] lut_le_start_low_reg;
reg  [31:0] lut_le_start_high_reg;
reg  [31:0] lut_le_end_low_reg;
reg  [31:0] lut_le_end_high_reg;
reg  [31:0] lut_lo_start_low_reg;
reg  [31:0] lut_lo_start_high_reg;
reg  [31:0] lut_lo_end_low_reg;
reg  [31:0] lut_lo_end_high_reg;
reg  [31:0] lut_le_slope_scale_reg;
reg  [31:0] lut_le_slope_shift_reg;
reg  [31:0] lut_lo_slope_scale_reg;
reg  [31:0] lut_lo_slope_shift_reg;

// Shadow registers for group_0
reg  [31:0] op_enable_g0;
reg  [31:0] func_bypass_g0;
reg  [31:0] dst_base_addr_low_g0;
reg  [31:0] dst_base_addr_high_g0;
reg  [31:0] dst_line_stride_g0;
reg  [31:0] dst_surface_stride_g0;
reg  [31:0] dst_dma_cfg_g0;
reg  [31:0] data_format_g0;
reg  [31:0] nan_flush_to_zero_g0;
reg  [31:0] lrn_cfg_g0;
reg  [31:0] datin_offset_g0;
reg  [31:0] datin_scale_g0;
reg  [31:0] datin_shifter_g0;
reg  [31:0] datout_offset_g0;
reg  [31:0] datout_scale_g0;
reg  [31:0] datout_shifter_g0;
reg  [31:0] perf_enable_g0;
reg  [31:0] perf_write_stall_g0;
reg  [31:0] cya_g0;

// Shadow registers for group_1
reg  [31:0] op_enable_g1;
reg  [31:0] func_bypass_g1;
reg  [31:0] dst_base_addr_low_g1;
reg  [31:0] dst_base_addr_high_g1;
reg  [31:0] dst_line_stride_g1;
reg  [31:0] dst_surface_stride_g1;
reg  [31:0] dst_dma_cfg_g1;
reg  [31:0] data_format_g1;
reg  [31:0] nan_flush_to_zero_g1;
reg  [31:0] lrn_cfg_g1;
reg  [31:0] datin_offset_g1;
reg  [31:0] datin_scale_g1;
reg  [31:0] datin_shifter_g1;
reg  [31:0] datout_offset_g1;
reg  [31:0] datout_scale_g1;
reg  [31:0] datout_shifter_g1;
reg  [31:0] perf_enable_g1;
reg  [31:0] perf_write_stall_g1;
reg  [31:0] cya_g1;

//===============================================================
// WRITE ENABLE LOGIC
//===============================================================
assign reg_addr = csb_addr;
assign reg_wdata = csb_wdat;
assign reg_read_en = csb_rd_en;
assign reg_write_en = csb_wr_en;

// Producer pointer - determines which group is active for writes
assign producer_ptr = pointer_reg[0];

// Write enables based on register address and producer pointer
// Common registers are written to both groups
assign wr_en_common = reg_write_en & (reg_addr < 12'hF00);

// Shadow registers are written to the active group only
assign wr_en_group0 = reg_write_en & (reg_addr >= 12'hF00) & ~producer_ptr;
assign wr_en_group1 = reg_write_en & (reg_addr >= 12'hF00) & producer_ptr;

//===============================================================
// COMMON REGISTER WRITE LOGIC
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    pointer_reg <= 32'h0;
    status_0_reg <= 32'h0;
    status_1_reg <= 32'h0;
    lut_access_cfg_reg <= 32'h0;
    lut_access_data_reg <= 32'h0;
    lut_cfg_reg <= 32'h0;
    lut_info_reg <= 32'h0;
    lut_le_start_low_reg <= 32'h0;
    lut_le_start_high_reg <= 32'h0;
    lut_le_end_low_reg <= 32'h0;
    lut_le_end_high_reg <= 32'h0;
    lut_lo_start_low_reg <= 32'h0;
    lut_lo_start_high_reg <= 32'h0;
    lut_lo_end_low_reg <= 32'h0;
    lut_lo_end_high_reg <= 32'h0;
    lut_le_slope_scale_reg <= 32'h0;
    lut_le_slope_shift_reg <= 32'h0;
    lut_lo_slope_scale_reg <= 32'h0;
    lut_lo_slope_shift_reg <= 32'h0;
  end else begin
    // Pointer register - write to both groups
    if (wr_en_common & (reg_addr == ADDR_POINTER)) begin
      pointer_reg <= reg_wdata;
    end

    // Status registers - write to both groups
    if (wr_en_common & (reg_addr == ADDR_STATUS)) begin
      status_0_reg <= reg_wdata;
      status_1_reg <= reg_wdata;
    end

    // LUT access registers
    if (wr_en_common & (reg_addr == ADDR_LUT_ACCESS_CFG)) begin
      lut_access_cfg_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_ACCESS_DATA)) begin
      lut_access_data_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_CFG)) begin
      lut_cfg_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_INFO)) begin
      lut_info_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LE_START_LOW)) begin
      lut_le_start_low_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LE_START_HIGH)) begin
      lut_le_start_high_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LE_END_LOW)) begin
      lut_le_end_low_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LE_END_HIGH)) begin
      lut_le_end_high_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LO_START_LOW)) begin
      lut_lo_start_low_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LO_START_HIGH)) begin
      lut_lo_start_high_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LO_END_LOW)) begin
      lut_lo_end_low_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LO_END_HIGH)) begin
      lut_lo_end_high_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LE_SLOPE_SCALE)) begin
      lut_le_slope_scale_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LE_SLOPE_SHIFT)) begin
      lut_le_slope_shift_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LO_SLOPE_SCALE)) begin
      lut_lo_slope_scale_reg <= reg_wdata;
    end
    if (wr_en_common & (reg_addr == ADDR_LUT_LO_SLOPE_SHIFT)) begin
      lut_lo_slope_shift_reg <= reg_wdata;
    end
  end
end

//===============================================================
// SHADOW REGISTER WRITE LOGIC - GROUP_0
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_enable_g0 <= 32'h0;
    func_bypass_g0 <= 32'h0;
    dst_base_addr_low_g0 <= 32'h0;
    dst_base_addr_high_g0 <= 32'h0;
    dst_line_stride_g0 <= 32'h0;
    dst_surface_stride_g0 <= 32'h0;
    dst_dma_cfg_g0 <= 32'h0;
    data_format_g0 <= 32'h0;
    nan_flush_to_zero_g0 <= 32'h0;
    lrn_cfg_g0 <= 32'h0;
    datin_offset_g0 <= 32'h0;
    datin_scale_g0 <= 32'h0;
    datin_shifter_g0 <= 32'h0;
    datout_offset_g0 <= 32'h0;
    datout_scale_g0 <= 32'h0;
    datout_shifter_g0 <= 32'h0;
    perf_enable_g0 <= 32'h0;
    perf_write_stall_g0 <= 32'h0;
    cya_g0 <= 32'h0;
  end else begin
    if (wr_en_group0) begin
      case (reg_addr)
        ADDR_OP_ENABLE:       op_enable_g0 <= reg_wdata;
        ADDR_FUNC_BYPASS:     func_bypass_g0 <= reg_wdata;
        ADDR_DST_BASE_ADDR_LOW:  dst_base_addr_low_g0 <= reg_wdata;
        ADDR_DST_BASE_ADDR_HIGH: dst_base_addr_high_g0 <= reg_wdata;
        ADDR_DST_LINE_STRIDE:    dst_line_stride_g0 <= reg_wdata;
        ADDR_DST_SURFACE_STRIDE: dst_surface_stride_g0 <= reg_wdata;
        ADDR_DST_DMA_CFG:        dst_dma_cfg_g0 <= reg_wdata;
        ADDR_DATA_FORMAT:        data_format_g0 <= reg_wdata;
        ADDR_NAN_FLUSH_TO_ZERO:  nan_flush_to_zero_g0 <= reg_wdata;
        ADDR_LRN_CFG:             lrn_cfg_g0 <= reg_wdata;
        ADDR_DATIN_OFFSET:       datin_offset_g0 <= reg_wdata;
        ADDR_DATIN_SCALE:        datin_scale_g0 <= reg_wdata;
        ADDR_DATIN_SHIFTER:      datin_shifter_g0 <= reg_wdata;
        ADDR_DATOUT_OFFSET:      datout_offset_g0 <= reg_wdata;
        ADDR_DATOUT_SCALE:       datout_scale_g0 <= reg_wdata;
        ADDR_DATOUT_SHIFTER:     datout_shifter_g0 <= reg_wdata;
        ADDR_PERF_ENABLE:        perf_enable_g0 <= reg_wdata;
        ADDR_PERF_WRITE_STALL:   perf_write_stall_g0 <= reg_wdata;
        ADDR_CYA:                cya_g0 <= reg_wdata;
        default: ;
      endcase
    end
  end
end

//===============================================================
// SHADOW REGISTER WRITE LOGIC - GROUP_1
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_enable_g1 <= 32'h0;
    func_bypass_g1 <= 32'h0;
    dst_base_addr_low_g1 <= 32'h0;
    dst_base_addr_high_g1 <= 32'h0;
    dst_line_stride_g1 <= 32'h0;
    dst_surface_stride_g1 <= 32'h0;
    dst_dma_cfg_g1 <= 32'h0;
    data_format_g1 <= 32'h0;
    nan_flush_to_zero_g1 <= 32'h0;
    lrn_cfg_g1 <= 32'h0;
    datin_offset_g1 <= 32'h0;
    datin_scale_g1 <= 32'h0;
    datin_shifter_g1 <= 32'h0;
    datout_offset_g1 <= 32'h0;
    datout_scale_g1 <= 32'h0;
    datout_shifter_g1 <= 32'h0;
    perf_enable_g1 <= 32'h0;
    perf_write_stall_g1 <= 32'h0;
    cya_g1 <= 32'h0;
  end else begin
    if (wr_en_group1) begin
      case (reg_addr)
        ADDR_OP_ENABLE:       op_enable_g1 <= reg_wdata;
        ADDR_FUNC_BYPASS:     func_bypass_g1 <= reg_wdata;
        ADDR_DST_BASE_ADDR_LOW:  dst_base_addr_low_g1 <= reg_wdata;
        ADDR_DST_BASE_ADDR_HIGH: dst_base_addr_high_g1 <= reg_wdata;
        ADDR_DST_LINE_STRIDE:    dst_line_stride_g1 <= reg_wdata;
        ADDR_DST_SURFACE_STRIDE: dst_surface_stride_g1 <= reg_wdata;
        ADDR_DST_DMA_CFG:        dst_dma_cfg_g1 <= reg_wdata;
        ADDR_DATA_FORMAT:        data_format_g1 <= reg_wdata;
        ADDR_NAN_FLUSH_TO_ZERO:  nan_flush_to_zero_g1 <= reg_wdata;
        ADDR_LRN_CFG:             lrn_cfg_g1 <= reg_wdata;
        ADDR_DATIN_OFFSET:       datin_offset_g1 <= reg_wdata;
        ADDR_DATIN_SCALE:        datin_scale_g1 <= reg_wdata;
        ADDR_DATIN_SHIFTER:      datin_shifter_g1 <= reg_wdata;
        ADDR_DATOUT_OFFSET:      datout_offset_g1 <= reg_wdata;
        ADDR_DATOUT_SCALE:       datout_scale_g1 <= reg_wdata;
        ADDR_DATOUT_SHIFTER:     datout_shifter_g1 <= reg_wdata;
        ADDR_PERF_ENABLE:        perf_enable_g1 <= reg_wdata;
        ADDR_PERF_WRITE_STALL:   perf_write_stall_g1 <= reg_wdata;
        ADDR_CYA:                cya_g1 <= reg_wdata;
        default: ;
      endcase
    end
  end
end

//===============================================================
// READ DATA OUTPUT
//===============================================================
reg [31:0] csb_rdat_reg;

always @(*) begin
  if (reg_read_en) begin
    if (reg_addr < 12'hF00) begin
      // Common registers
      case (reg_addr)
        ADDR_STATUS:         csb_rdat_reg = status_0_reg;
        ADDR_POINTER:        csb_rdat_reg = pointer_reg;
        ADDR_LUT_ACCESS_CFG: csb_rdat_reg = lut_access_cfg_reg;
        ADDR_LUT_ACCESS_DATA: csb_rdat_reg = lut_access_data_reg;
        ADDR_LUT_CFG:        csb_rdat_reg = lut_cfg_reg;
        ADDR_LUT_INFO:       csb_rdat_reg = lut_info_reg;
        ADDR_LUT_LE_START_LOW:  csb_rdat_reg = lut_le_start_low_reg;
        ADDR_LUT_LE_START_HIGH: csb_rdat_reg = lut_le_start_high_reg;
        ADDR_LUT_LE_END_LOW:    csb_rdat_reg = lut_le_end_low_reg;
        ADDR_LUT_LE_END_HIGH:   csb_rdat_reg = lut_le_end_high_reg;
        ADDR_LUT_LO_START_LOW:  csb_rdat_reg = lut_lo_start_low_reg;
        ADDR_LUT_LO_START_HIGH: csb_rdat_reg = lut_lo_start_high_reg;
        ADDR_LUT_LO_END_LOW:    csb_rdat_reg = lut_lo_end_low_reg;
        ADDR_LUT_LO_END_HIGH:   csb_rdat_reg = lut_lo_end_high_reg;
        ADDR_LUT_LE_SLOPE_SCALE: csb_rdat_reg = lut_le_slope_scale_reg;
        ADDR_LUT_LE_SLOPE_SHIFT:  csb_rdat_reg = lut_le_slope_shift_reg;
        ADDR_LUT_LO_SLOPE_SCALE: csb_rdat_reg = lut_lo_slope_scale_reg;
        ADDR_LUT_LO_SLOPE_SHIFT:  csb_rdat_reg = lut_lo_slope_shift_reg;
        default:               csb_rdat_reg = 32'h0;
      endcase
    end else begin
      // Shadow registers - read from producer's group
      if (producer_ptr == 1'b0) begin
        case (reg_addr)
          ADDR_OP_ENABLE:       csb_rdat_reg = op_enable_g0;
          ADDR_FUNC_BYPASS:     csb_rdat_reg = func_bypass_g0;
          ADDR_DST_BASE_ADDR_LOW:  csb_rdat_reg = dst_base_addr_low_g0;
          ADDR_DST_BASE_ADDR_HIGH: csb_rdat_reg = dst_base_addr_high_g0;
          ADDR_DST_LINE_STRIDE:    csb_rdat_reg = dst_line_stride_g0;
          ADDR_DST_SURFACE_STRIDE: csb_rdat_reg = dst_surface_stride_g0;
          ADDR_DST_DMA_CFG:        csb_rdat_reg = dst_dma_cfg_g0;
          ADDR_DATA_FORMAT:        csb_rdat_reg = data_format_g0;
          ADDR_NAN_FLUSH_TO_ZERO:  csb_rdat_reg = nan_flush_to_zero_g0;
          ADDR_LRN_CFG:             csb_rdat_reg = lrn_cfg_g0;
          ADDR_DATIN_OFFSET:       csb_rdat_reg = datin_offset_g0;
          ADDR_DATIN_SCALE:        csb_rdat_reg = datin_scale_g0;
          ADDR_DATIN_SHIFTER:      csb_rdat_reg = datin_shifter_g0;
          ADDR_DATOUT_OFFSET:      csb_rdat_reg = datout_offset_g0;
          ADDR_DATOUT_SCALE:       csb_rdat_reg = datout_scale_g0;
          ADDR_DATOUT_SHIFTER:     csb_rdat_reg = datout_shifter_g0;
          ADDR_PERF_ENABLE:        csb_rdat_reg = perf_enable_g0;
          ADDR_PERF_WRITE_STALL:   csb_rdat_reg = perf_write_stall_g0;
          ADDR_CYA:                csb_rdat_reg = cya_g0;
          default:                 csb_rdat_reg = 32'h0;
        endcase
      end else begin
        case (reg_addr)
          ADDR_OP_ENABLE:       csb_rdat_reg = op_enable_g1;
          ADDR_FUNC_BYPASS:     csb_rdat_reg = func_bypass_g1;
          ADDR_DST_BASE_ADDR_LOW:  csb_rdat_reg = dst_base_addr_low_g1;
          ADDR_DST_BASE_ADDR_HIGH: csb_rdat_reg = dst_base_addr_high_g1;
          ADDR_DST_LINE_STRIDE:    csb_rdat_reg = dst_line_stride_g1;
          ADDR_DST_SURFACE_STRIDE: csb_rdat_reg = dst_surface_stride_g1;
          ADDR_DST_DMA_CFG:        csb_rdat_reg = dst_dma_cfg_g1;
          ADDR_DATA_FORMAT:        csb_rdat_reg = data_format_g1;
          ADDR_NAN_FLUSH_TO_ZERO:  csb_rdat_reg = nan_flush_to_zero_g1;
          ADDR_LRN_CFG:             csb_rdat_reg = lrn_cfg_g1;
          ADDR_DATIN_OFFSET:       csb_rdat_reg = datin_offset_g1;
          ADDR_DATIN_SCALE:        csb_rdat_reg = datin_scale_g1;
          ADDR_DATIN_SHIFTER:      csb_rdat_reg = datin_shifter_g1;
          ADDR_DATOUT_OFFSET:      csb_rdat_reg = datout_offset_g1;
          ADDR_DATOUT_SCALE:       csb_rdat_reg = datout_scale_g1;
          ADDR_DATOUT_SHIFTER:     csb_rdat_reg = datout_shifter_g1;
          ADDR_PERF_ENABLE:        csb_rdat_reg = perf_enable_g1;
          ADDR_PERF_WRITE_STALL:   csb_rdat_reg = perf_write_stall_g1;
          ADDR_CYA:                csb_rdat_reg = cya_g1;
          default:                 csb_rdat_reg = 32'h0;
        endcase
      end
    end
  end else begin
    csb_rdat_reg = 32'h0;
  end
end

assign csb_rdat = csb_rdat_reg;

//===============================================================
// OUTPUT ASSIGNMENTS
//===============================================================
// Select active group's OP_ENABLE based on producer pointer
assign nvdla_cdp_cfg_op_en = producer_ptr ? op_enable_g1 : op_enable_g0;
assign nvdla_cdp_status_0 = status_0_reg;
assign nvdla_cdp_status_1 = status_1_reg;
assign nvdla_cdp_pointer = pointer_reg;
assign nvdla_cdp_reg2dp_lut_access_cfg = lut_access_cfg_reg;
assign nvdla_cdp_reg2dp_lut_access_data = lut_access_data_reg;
assign nvdla_cdp_reg2dp_lut_cfg = lut_cfg_reg;
assign nvdla_cdp_reg2dp_lut_info = lut_info_reg;
assign nvdla_cdp_reg2dp_lut_le_start_low = lut_le_start_low_reg;
assign nvdla_cdp_reg2dp_lut_le_start_high = lut_le_start_high_reg;
assign nvdla_cdp_reg2dp_lut_le_end_low = lut_le_end_low_reg;
assign nvdla_cdp_reg2dp_lut_le_end_high = lut_le_end_high_reg;
assign nvdla_cdp_reg2dp_lut_lo_start_low = lut_lo_start_low_reg;
assign nvdla_cdp_reg2dp_lut_lo_start_high = lut_lo_start_high_reg;
assign nvdla_cdp_reg2dp_lut_lo_end_low = lut_lo_end_low_reg;
assign nvdla_cdp_reg2dp_lut_lo_end_high = lut_lo_end_high_reg;
assign nvdla_cdp_reg2dp_lut_le_slope_scale = lut_le_slope_scale_reg;
assign nvdla_cdp_reg2dp_lut_le_slope_shift = lut_le_slope_shift_reg;
assign nvdla_cdp_reg2dp_lut_lo_slope_scale = lut_lo_slope_scale_reg;
assign nvdla_cdp_reg2dp_lut_lo_slope_shift = lut_lo_slope_shift_reg;

endmodule // NV_NVDLA_CDP_reg_model_new