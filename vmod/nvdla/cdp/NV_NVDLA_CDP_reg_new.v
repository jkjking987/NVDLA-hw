// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_reg_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP Register File Module
// - Handles dual register groups (group_0 and group_1) with producer/consumer pointer
// - Shadow register architecture for smooth context switching
// - Register address decoding for CDP registers
// - Status and control signal generation
//
// Register Map (offset based):
//   0x000-0x0FF: Common/Special registers (same for both groups)
//   0x100-0xFFF: Data path registers (shadowed, group-specific)
//
// Key Registers:
//   - S_STATUS (0x00): Status register with STATUS_0 and STATUS_1
//   - S_POINTER (0x04): Producer/Consumer pointer
//   - S_LUT_ACCESS_CFG (0x08): LUT access configuration
//   - S_LUT_ACCESS_DATA (0x0C): LUT access data
//   - S_LUT_CFG (0x10): LUT configuration
//   - S_LUT_INFO (0x14): LUT info
//   - D_OP_ENABLE (0xF00): Operation enable
//   - D_FUNC_BYPASS (0xF04): Function bypass
//   - D_DST_BASE_ADDR_LOW (0xF08): Destination base address low
//   - D_DST_BASE_ADDR_HIGH (0xF0C): Destination base address high
//   - D_DST_LINE_STRIDE (0xF10): Destination line stride
//   - D_DST_SURFACE_STRIDE (0xF14): Destination surface stride
//   - D_DST_DMA_CFG (0xF18): Destination DMA config
//   - D_DATA_FORMAT (0xF1C): Data format
//   - D_NAN_FLUSH_TO_ZERO (0xF20): NaN flush to zero
//   - D_LRN_CFG (0xF24): LRN configuration
//   - D_DATIN_OFFSET (0xF28): Input data offset
//   - D_DATIN_SCALE (0xF2C): Input data scale
//   - D_DATIN_SHIFTER (0xF30): Input data shifter
//   - D_DATOUT_OFFSET (0xF34): Output data offset
//   - D_DATOUT_SCALE (0xF38): Output data scale
//   - D_DATOUT_SHIFTER (0xF3C): Output data shifter
//   - D_PERF_ENABLE (0xF40): Performance enable
//   - D_PERF_WRITE_STALL (0xF44): Write stall perf counter
//   - D_CYA (0xFFC): CYA register
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_reg_new (
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
  // Register model outputs (from internal reg model)
  ,nvdla_cdp_cfg_op_en              //|< i [31:0]
  ,nvdla_cdp_status_0               //|< i [31:0]
  ,nvdla_cdp_status_1               //|< i [31:0]
  ,nvdla_cdp_pointer                //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_access_cfg  //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_access_data //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_cfg         //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_info        //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_le_start_low  //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_le_start_high //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_le_end_low    //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_le_end_high   //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_start_low  //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_start_high //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_end_low    //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_end_high   //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_le_slope_scale //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_le_slope_shift  //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_slope_scale //|< i [31:0]
  ,nvdla_cdp_reg2dp_lut_lo_slope_shift  //|< i [31:0]
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
input  [31:0] nvdla_cdp_cfg_op_en;
input  [31:0] nvdla_cdp_status_0;
input  [31:0] nvdla_cdp_status_1;
input  [31:0] nvdla_cdp_pointer;
input  [31:0] nvdla_cdp_reg2dp_lut_access_cfg;
input  [31:0] nvdla_cdp_reg2dp_lut_access_data;
input  [31:0] nvdla_cdp_reg2dp_lut_cfg;
input  [31:0] nvdla_cdp_reg2dp_lut_info;
input  [31:0] nvdla_cdp_reg2dp_lut_le_start_low;
input  [31:0] nvdla_cdp_reg2dp_lut_le_start_high;
input  [31:0] nvdla_cdp_reg2dp_lut_le_end_low;
input  [31:0] nvdla_cdp_reg2dp_lut_le_end_high;
input  [31:0] nvdla_cdp_reg2dp_lut_lo_start_low;
input  [31:0] nvdla_cdp_reg2dp_lut_lo_start_high;
input  [31:0] nvdla_cdp_reg2dp_lut_lo_end_low;
input  [31:0] nvdla_cdp_reg2dp_lut_lo_end_high;
input  [31:0] nvdla_cdp_reg2dp_lut_le_slope_scale;
input  [31:0] nvdla_cdp_reg2dp_lut_le_slope_shift;
input  [31:0] nvdla_cdp_reg2dp_lut_lo_slope_scale;
input  [31:0] nvdla_cdp_reg2dp_lut_lo_slope_shift;

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
// REGISTER ADDRESS DECODE
//===============================================================
assign reg_addr = csb_addr;
assign reg_read_en = csb_rd_en;
assign reg_write_en = csb_wr_en;

// Producer pointer - selects which register group is active
// 0 = group_0 is producer (active), 1 = group_1 is producer (active)
assign producer_ptr = nvdla_cdp_pointer[0];

//===============================================================
// REGISTER READ DATA PATH
//===============================================================
// Read data multiplexer - selects data based on address
reg [31:0] reg_rdata_mux;

always @(*) begin
  case (reg_addr)
    // Common registers - read same regardless of producer pointer
    ADDR_STATUS:        reg_rdata_mux = producer_ptr ? nvdla_cdp_status_1 : nvdla_cdp_status_0;
    ADDR_POINTER:       reg_rdata_mux = nvdla_cdp_pointer;
    ADDR_LUT_ACCESS_CFG: reg_rdata_mux = nvdla_cdp_reg2dp_lut_access_cfg;
    ADDR_LUT_ACCESS_DATA: reg_rdata_mux = nvdla_cdp_reg2dp_lut_access_data;
    ADDR_LUT_CFG:       reg_rdata_mux = nvdla_cdp_reg2dp_lut_cfg;
    ADDR_LUT_INFO:      reg_rdata_mux = nvdla_cdp_reg2dp_lut_info;
    ADDR_LUT_LE_START_LOW:  reg_rdata_mux = nvdla_cdp_reg2dp_lut_le_start_low;
    ADDR_LUT_LE_START_HIGH: reg_rdata_mux = nvdla_cdp_reg2dp_lut_le_start_high;
    ADDR_LUT_LE_END_LOW:    reg_rdata_mux = nvdla_cdp_reg2dp_lut_le_end_low;
    ADDR_LUT_LE_END_HIGH:   reg_rdata_mux = nvdla_cdp_reg2dp_lut_le_end_high;
    ADDR_LUT_LO_START_LOW:  reg_rdata_mux = nvdla_cdp_reg2dp_lut_lo_start_low;
    ADDR_LUT_LO_START_HIGH: reg_rdata_mux = nvdla_cdp_reg2dp_lut_lo_start_high;
    ADDR_LUT_LO_END_LOW:    reg_rdata_mux = nvdla_cdp_reg2dp_lut_lo_end_low;
    ADDR_LUT_LO_END_HIGH:   reg_rdata_mux = nvdla_cdp_reg2dp_lut_lo_end_high;
    ADDR_LUT_LE_SLOPE_SCALE: reg_rdata_mux = nvdla_cdp_reg2dp_lut_le_slope_scale;
    ADDR_LUT_LE_SLOPE_SHIFT:  reg_rdata_mux = nvdla_cdp_reg2dp_lut_le_slope_shift;
    ADDR_LUT_LO_SLOPE_SCALE: reg_rdata_mux = nvdla_cdp_reg2dp_lut_lo_slope_scale;
    ADDR_LUT_LO_SLOPE_SHIFT:  reg_rdata_mux = nvdla_cdp_reg2dp_lut_lo_slope_shift;
    // Data path registers - read based on producer pointer (active group)
    ADDR_OP_ENABLE:       reg_rdata_mux = nvdla_cdp_cfg_op_en;
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
    op_en_prev <= nvdla_cdp_cfg_op_en[0];
  end
end

assign reg2dp_op_en_trigger = nvdla_cdp_cfg_op_en[0] & ~op_en_prev;
assign reg2dp_op_en = nvdla_cdp_cfg_op_en[0];

endmodule // NV_NVDLA_CDP_reg_new