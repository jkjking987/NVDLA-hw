// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_reg_rdma_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP RDMA Register File Module
// - Handles dual register groups (group_0 and group_1) for RDMA
// - Producer/Consumer pointer mechanism
// - Shadow register architecture
//
// Key Registers:
//   - S_STATUS (0x00): Status register
//   - S_POINTER (0x04): Producer/Consumer pointer
//   - D_OP_ENABLE (0xF00): Operation enable
//   - D_SRC_BASE_ADDR_LOW (0xF04): Source base address low
//   - D_SRC_BASE_ADDR_HIGH (0xF08): Source base address high
//   - D_SRC_LINE_STRIDE (0xF0C): Source line stride
//   - D_SRC_SURFACE_STRIDE (0xF10): Source surface stride
//   - D_SRC_DMA_CFG (0xF14): Source DMA config
//   - D_SRC_COMPRESSION_EN (0xF18): Source compression enable
//   - D_DATA_FORMAT (0xF1C): Data format
//   - D_OPERATION_MODE (0xF20): Operation mode
//   - D_PERF_ENABLE (0xF24): Performance enable
//   - D_PERF_READ_STALL (0xF28): Read stall perf counter
//   - D_CYA (0xFFC): CYA register
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_reg_rdma_new (
   nvdla_core_clk                    //|< i
  ,nvdla_core_rstn                   //|< i
  // CSB interface
  ,csb_addr                         //|< i [11:0]
  ,csb_wdat                         //|< i [31:0]
  ,csb_rd_en                        //|< i
  ,csb_wr_en                        //|< i
  ,csb_rdat                         //|> o [31:0]
  // Datapath outputs
  ,reg2dp_op_en                     //|> o
  ,reg2dp_op_en_trigger             //|> o
  // Register model outputs
  ,nvdla_cdp_rdma_cfg_op_en              //|< i [31:0]
  ,nvdla_cdp_rdma_status_0               //|< i [31:0]
  ,nvdla_cdp_rdma_status_1               //|< i [31:0]
  ,nvdla_cdp_rdma_pointer                //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_base_addr_low  //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_base_addr_high //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_line_stride    //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_surface_stride //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_src_dma_cfg        //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_data_format        //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_operation_mode     //|< i [31:0]
  ,nvdla_cdp_rdma_reg2dp_perf_enable         //|< i [31:0]
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

// Datapath outputs
output        reg2dp_op_en;
output        reg2dp_op_en_trigger;

// Register model inputs
input  [31:0] nvdla_cdp_rdma_cfg_op_en;
input  [31:0] nvdla_cdp_rdma_status_0;
input  [31:0] nvdla_cdp_rdma_status_1;
input  [31:0] nvdla_cdp_rdma_pointer;
input  [31:0] nvdla_cdp_rdma_reg2dp_src_base_addr_low;
input  [31:0] nvdla_cdp_rdma_reg2dp_src_base_addr_high;
input  [31:0] nvdla_cdp_rdma_reg2dp_src_line_stride;
input  [31:0] nvdla_cdp_rdma_reg2dp_src_surface_stride;
input  [31:0] nvdla_cdp_rdma_reg2dp_src_dma_cfg;
input  [31:0] nvdla_cdp_rdma_reg2dp_data_format;
input  [31:0] nvdla_cdp_rdma_reg2dp_operation_mode;
input  [31:0] nvdla_cdp_rdma_reg2dp_perf_enable;

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// Register address decode
wire   [11:0] reg_addr;
wire   [31:0] reg_rdata;
wire          reg_read_en;
wire          reg_write_en;

// Producer pointer for selecting active register group
wire          producer_ptr;

// Common register addresses
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
// REGISTER ADDRESS DECODE
//===============================================================
assign reg_addr = csb_addr;
assign reg_read_en = csb_rd_en;
assign reg_write_en = csb_wr_en;

// Producer pointer - selects which register group is active
assign producer_ptr = nvdla_cdp_rdma_pointer[0];

//===============================================================
// REGISTER READ DATA PATH
//===============================================================
// Read data multiplexer - selects data based on address
reg [31:0] reg_rdata_mux;

always @(*) begin
  case (reg_addr)
    // Common registers - read same regardless of producer pointer
    ADDR_STATUS:        reg_rdata_mux = producer_ptr ? nvdla_cdp_rdma_status_1 : nvdla_cdp_rdma_status_0;
    ADDR_POINTER:       reg_rdata_mux = nvdla_cdp_rdma_pointer;
    // Data path registers - read based on producer pointer (active group)
    ADDR_OP_ENABLE:       reg_rdata_mux = nvdla_cdp_rdma_cfg_op_en;
    ADDR_SRC_BASE_ADDR_LOW:  reg_rdata_mux = nvdla_cdp_rdma_reg2dp_src_base_addr_low;
    ADDR_SRC_BASE_ADDR_HIGH: reg_rdata_mux = nvdla_cdp_rdma_reg2dp_src_base_addr_high;
    ADDR_SRC_LINE_STRIDE:    reg_rdata_mux = nvdla_cdp_rdma_reg2dp_src_line_stride;
    ADDR_SRC_SURFACE_STRIDE: reg_rdata_mux = nvdla_cdp_rdma_reg2dp_src_surface_stride;
    ADDR_SRC_DMA_CFG:        reg_rdata_mux = nvdla_cdp_rdma_reg2dp_src_dma_cfg;
    ADDR_DATA_FORMAT:        reg_rdata_mux = nvdla_cdp_rdma_reg2dp_data_format;
    ADDR_OPERATION_MODE:     reg_rdata_mux = nvdla_cdp_rdma_reg2dp_operation_mode;
    ADDR_PERF_ENABLE:        reg_rdata_mux = nvdla_cdp_rdma_reg2dp_perf_enable;
    default:              reg_rdata_mux = 32'h0;
  endcase
end

assign csb_rdat = reg_rdata_mux;

//===============================================================
// OP_ENABLE REGISTER - Generate trigger and op_en
//===============================================================
// reg2dp_op_en_trigger: pulse when OP_EN transitions from 0 to 1
reg op_en_prev;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_prev <= 1'b0;
  end else begin
    op_en_prev <= nvdla_cdp_rdma_cfg_op_en[0];
  end
end

assign reg2dp_op_en_trigger = nvdla_cdp_rdma_cfg_op_en[0] & ~op_en_prev;
assign reg2dp_op_en = nvdla_cdp_rdma_cfg_op_en[0];

endmodule // NV_NVDLA_CDP_reg_rdma_new