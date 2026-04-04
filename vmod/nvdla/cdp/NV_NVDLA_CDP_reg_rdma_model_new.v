// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_reg_rdma_model_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP RDMA Register Model Module
// - Stores all CDP RDMA registers in two groups (group_0 and group_1)
// - Handles dual-entity register architecture with producer/consumer pointer
// - Shadow register implementation for smooth context switching
//
// Register Groups:
//   group_0: Active when producer_pointer = 0
//   group_1: Active when producer_pointer = 1
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_reg_rdma_model_new (
   nvdla_core_clk                        //|< i
  ,nvdla_core_rstn                       //|< i
  // CSB interface
  ,csb_addr                             //|< i [11:0]
  ,csb_wdat                             //|< i [31:0]
  ,csb_rd_en                            //|< i
  ,csb_wr_en                            //|< i
  ,csb_rdat                             //|> o [31:0]
  // Register outputs
  ,nvdla_cdp_rdma_cfg_op_en                  //|> o [31:0]
  ,nvdla_cdp_rdma_status_0                   //|> o [31:0]
  ,nvdla_cdp_rdma_status_1                   //|> o [31:0]
  ,nvdla_cdp_rdma_pointer                    //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_base_addr_low  //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_base_addr_high //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_line_stride    //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_surface_stride //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_dma_cfg        //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_data_format        //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_operation_mode     //|> o [31:0]
  ,nvdla_cdp_rdma_reg2dp_perf_enable        //|> o [31:0]
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
output [31:0] nvdla_cdp_rdma_cfg_op_en;
output [31:0] nvdla_cdp_rdma_status_0;
output [31:0] nvdla_cdp_rdma_status_1;
output [31:0] nvdla_cdp_rdma_pointer;
output [31:0] nvdla_cdp_rdma_reg2dp_src_base_addr_low;
output [31:0] nvdla_cdp_rdma_reg2dp_src_base_addr_high;
output [31:0] nvdla_cdp_rdma_reg2dp_src_line_stride;
output [31:0] nvdla_cdp_rdma_reg2dp_src_surface_stride;
output [31:0] nvdla_cdp_rdma_reg2dp_src_dma_cfg;
output [31:0] nvdla_cdp_rdma_reg2dp_data_format;
output [31:0] nvdla_cdp_rdma_reg2dp_operation_mode;
output [31:0] nvdla_cdp_rdma_reg2dp_perf_enable;

//===============================================================
// REGISTER ADDRESS DEFINITIONS
//===============================================================
// Common register addresses (not shadowed)
localparam ADDR_STATUS        = 12'h000;
localparam ADDR_POINTER       = 12'h004;

// Data path register addresses (shadowed - group specific)
localparam ADDR_OP_ENABLE       = 12'hF00;
localparam ADDR_SRC_BASE_ADDR_LOW  = 12'hF04;
localparam ADDR_SRC_BASE_ADDR_HIGH = 12'hF08;
localparam ADDR_SRC_LINE_STRIDE    = 12'hF0C;
localparam ADDR_SRC_SURFACE_STRIDE = 12'hF10;
localparam ADDR_SRC_DMA_CFG        = 12'hF14;
localparam ADDR_DATA_FORMAT        = 12'hF18;
localparam ADDR_OPERATION_MODE      = 12'hF1C;
localparam ADDR_PERF_ENABLE         = 12'hF20;
localparam ADDR_PERF_READ_STALL    = 12'hF24;
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

// Shadow registers for group_0
reg  [31:0] op_enable_g0;
reg  [31:0] src_base_addr_low_g0;
reg  [31:0] src_base_addr_high_g0;
reg  [31:0] src_line_stride_g0;
reg  [31:0] src_surface_stride_g0;
reg  [31:0] src_dma_cfg_g0;
reg  [31:0] data_format_g0;
reg  [31:0] operation_mode_g0;
reg  [31:0] perf_enable_g0;
reg  [31:0] perf_read_stall_g0;
reg  [31:0] cya_g0;

// Shadow registers for group_1
reg  [31:0] op_enable_g1;
reg  [31:0] src_base_addr_low_g1;
reg  [31:0] src_base_addr_high_g1;
reg  [31:0] src_line_stride_g1;
reg  [31:0] src_surface_stride_g1;
reg  [31:0] src_dma_cfg_g1;
reg  [31:0] data_format_g1;
reg  [31:0] operation_mode_g1;
reg  [31:0] perf_enable_g1;
reg  [31:0] perf_read_stall_g1;
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
  end
end

//===============================================================
// SHADOW REGISTER WRITE LOGIC - GROUP_0
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_enable_g0 <= 32'h0;
    src_base_addr_low_g0 <= 32'h0;
    src_base_addr_high_g0 <= 32'h0;
    src_line_stride_g0 <= 32'h0;
    src_surface_stride_g0 <= 32'h0;
    src_dma_cfg_g0 <= 32'h0;
    data_format_g0 <= 32'h0;
    operation_mode_g0 <= 32'h0;
    perf_enable_g0 <= 32'h0;
    perf_read_stall_g0 <= 32'h0;
    cya_g0 <= 32'h0;
  end else begin
    if (wr_en_group0) begin
      case (reg_addr)
        ADDR_OP_ENABLE:       op_enable_g0 <= reg_wdata;
        ADDR_SRC_BASE_ADDR_LOW:  src_base_addr_low_g0 <= reg_wdata;
        ADDR_SRC_BASE_ADDR_HIGH: src_base_addr_high_g0 <= reg_wdata;
        ADDR_SRC_LINE_STRIDE:    src_line_stride_g0 <= reg_wdata;
        ADDR_SRC_SURFACE_STRIDE: src_surface_stride_g0 <= reg_wdata;
        ADDR_SRC_DMA_CFG:        src_dma_cfg_g0 <= reg_wdata;
        ADDR_DATA_FORMAT:        data_format_g0 <= reg_wdata;
        ADDR_OPERATION_MODE:     operation_mode_g0 <= reg_wdata;
        ADDR_PERF_ENABLE:        perf_enable_g0 <= reg_wdata;
        ADDR_PERF_READ_STALL:    perf_read_stall_g0 <= reg_wdata;
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
    src_base_addr_low_g1 <= 32'h0;
    src_base_addr_high_g1 <= 32'h0;
    src_line_stride_g1 <= 32'h0;
    src_surface_stride_g1 <= 32'h0;
    src_dma_cfg_g1 <= 32'h0;
    data_format_g1 <= 32'h0;
    operation_mode_g1 <= 32'h0;
    perf_enable_g1 <= 32'h0;
    perf_read_stall_g1 <= 32'h0;
    cya_g1 <= 32'h0;
  end else begin
    if (wr_en_group1) begin
      case (reg_addr)
        ADDR_OP_ENABLE:       op_enable_g1 <= reg_wdata;
        ADDR_SRC_BASE_ADDR_LOW:  src_base_addr_low_g1 <= reg_wdata;
        ADDR_SRC_BASE_ADDR_HIGH: src_base_addr_high_g1 <= reg_wdata;
        ADDR_SRC_LINE_STRIDE:    src_line_stride_g1 <= reg_wdata;
        ADDR_SRC_SURFACE_STRIDE: src_surface_stride_g1 <= reg_wdata;
        ADDR_SRC_DMA_CFG:        src_dma_cfg_g1 <= reg_wdata;
        ADDR_DATA_FORMAT:        data_format_g1 <= reg_wdata;
        ADDR_OPERATION_MODE:     operation_mode_g1 <= reg_wdata;
        ADDR_PERF_ENABLE:        perf_enable_g1 <= reg_wdata;
        ADDR_PERF_READ_STALL:    perf_read_stall_g1 <= reg_wdata;
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
        default:               csb_rdat_reg = 32'h0;
      endcase
    end else begin
      // Shadow registers - read from producer's group
      if (producer_ptr == 1'b0) begin
        case (reg_addr)
          ADDR_OP_ENABLE:       csb_rdat_reg = op_enable_g0;
          ADDR_SRC_BASE_ADDR_LOW:  csb_rdat_reg = src_base_addr_low_g0;
          ADDR_SRC_BASE_ADDR_HIGH: csb_rdat_reg = src_base_addr_high_g0;
          ADDR_SRC_LINE_STRIDE:    csb_rdat_reg = src_line_stride_g0;
          ADDR_SRC_SURFACE_STRIDE: csb_rdat_reg = src_surface_stride_g0;
          ADDR_SRC_DMA_CFG:        csb_rdat_reg = src_dma_cfg_g0;
          ADDR_DATA_FORMAT:        csb_rdat_reg = data_format_g0;
          ADDR_OPERATION_MODE:     csb_rdat_reg = operation_mode_g0;
          ADDR_PERF_ENABLE:        csb_rdat_reg = perf_enable_g0;
          ADDR_PERF_READ_STALL:    csb_rdat_reg = perf_read_stall_g0;
          ADDR_CYA:                csb_rdat_reg = cya_g0;
          default:                 csb_rdat_reg = 32'h0;
        endcase
      end else begin
        case (reg_addr)
          ADDR_OP_ENABLE:       csb_rdat_reg = op_enable_g1;
          ADDR_SRC_BASE_ADDR_LOW:  csb_rdat_reg = src_base_addr_low_g1;
          ADDR_SRC_BASE_ADDR_HIGH: csb_rdat_reg = src_base_addr_high_g1;
          ADDR_SRC_LINE_STRIDE:    csb_rdat_reg = src_line_stride_g1;
          ADDR_SRC_SURFACE_STRIDE: csb_rdat_reg = src_surface_stride_g1;
          ADDR_SRC_DMA_CFG:        csb_rdat_reg = src_dma_cfg_g1;
          ADDR_DATA_FORMAT:        csb_rdat_reg = data_format_g1;
          ADDR_OPERATION_MODE:     csb_rdat_reg = operation_mode_g1;
          ADDR_PERF_ENABLE:        csb_rdat_reg = perf_enable_g1;
          ADDR_PERF_READ_STALL:    csb_rdat_reg = perf_read_stall_g1;
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
assign nvdla_cdp_rdma_cfg_op_en = producer_ptr ? op_enable_g1 : op_enable_g0;
assign nvdla_cdp_rdma_status_0 = status_0_reg;
assign nvdla_cdp_rdma_status_1 = status_1_reg;
assign nvdla_cdp_rdma_pointer = pointer_reg;
assign nvdla_cdp_rdma_reg2dp_src_base_addr_low = producer_ptr ? src_base_addr_low_g1 : src_base_addr_low_g0;
assign nvdla_cdp_rdma_reg2dp_src_base_addr_high = producer_ptr ? src_base_addr_high_g1 : src_base_addr_high_g0;
assign nvdla_cdp_rdma_reg2dp_src_line_stride = producer_ptr ? src_line_stride_g1 : src_line_stride_g0;
assign nvdla_cdp_rdma_reg2dp_src_surface_stride = producer_ptr ? src_surface_stride_g1 : src_surface_stride_g0;
assign nvdla_cdp_rdma_reg2dp_src_dma_cfg = producer_ptr ? src_dma_cfg_g1 : src_dma_cfg_g0;
assign nvdla_cdp_rdma_reg2dp_data_format = producer_ptr ? data_format_g1 : data_format_g0;
assign nvdla_cdp_rdma_reg2dp_operation_mode = producer_ptr ? operation_mode_g1 : operation_mode_g0;
assign nvdla_cdp_rdma_reg2dp_perf_enable = producer_ptr ? perf_enable_g1 : perf_enable_g0;

endmodule // NV_NVDLA_CDP_reg_rdma_model_new