// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_SDP_reg_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// SDP Register File with dual-bank (ping-pong) architecture
// - Group 0 and Group 1 registers for concurrent operation
// - Producer/Consumer pointer for bank selection
// - All configuration registers for SDP processing paths
// - Status registers for hardware layer communication
// +FHDR------------------------------------------------------------

`include "simulate_x_tick.vh"
module NV_NVDLA_SDP_reg_new (
   nvdla_core_clk                  //|< i
  ,nvdla_core_rstn                 //|< i
  // CSB interface
  ,csb2sdp_req_pd                  //|< i
  ,csb2sdp_req_pvld                //|< i
  ,csb2sdp_req_prdy                //|> o
  ,sdp2csb_resp_pd                 //|> o
  ,sdp2csb_resp_valid              //|> o
  // Status inputs from datapath
  ,dp2reg_done                     //|< i
  ,dp2reg_lut_hybrid              //|< i
  ,dp2reg_lut_int_data            //|< i
  ,dp2reg_lut_le_hit              //|< i
  ,dp2reg_lut_lo_hit              //|< i
  ,dp2reg_lut_oflow              //|< i
  ,dp2reg_lut_uflow              //|< i
  ,dp2reg_out_saturation         //|< i
  ,dp2reg_status_inf_input_num   //|< i
  ,dp2reg_status_nan_input_num   //|< i
  ,dp2reg_status_nan_output_num  //|< i
  ,dp2reg_status_unequal         //|< i
  ,dp2reg_wdma_stall             //|< i
  // Configuration outputs to datapath
  ,reg2dp_batch_number           //|> o
  ,reg2dp_bcore_slcg_op_en       //|> o
  ,reg2dp_bn_alu_algo            //|> o
  ,reg2dp_bn_alu_bypass          //|> o
  ,reg2dp_bn_alu_operand         //|> o
  ,reg2dp_bn_alu_shift_value     //|> o
  ,reg2dp_bn_alu_src             //|> o
  ,reg2dp_bn_bypass              //|> o
  ,reg2dp_bn_mul_bypass          //|> o
  ,reg2dp_bn_mul_operand         //|> o
  ,reg2dp_bn_mul_prelu           //|> o
  ,reg2dp_bn_mul_shift_value     //|> o
  ,reg2dp_bn_mul_src             //|> o
  ,reg2dp_bn_relu_bypass         //|> o
  ,reg2dp_bs_alu_algo            //|> o
  ,reg2dp_bs_alu_bypass          //|> o
  ,reg2dp_bs_alu_operand         //|> o
  ,reg2dp_bs_alu_shift_value     //|> o
  ,reg2dp_bs_alu_src             //|> o
  ,reg2dp_bs_bypass              //|> o
  ,reg2dp_bs_mul_bypass          //|> o
  ,reg2dp_bs_mul_operand         //|> o
  ,reg2dp_bs_mul_prelu           //|> o
  ,reg2dp_bs_mul_shift_value     //|> o
  ,reg2dp_bs_mul_src             //|> o
  ,reg2dp_bs_relu_bypass         //|> o
  ,reg2dp_channel                //|> o
  ,reg2dp_cvt_offset             //|> o
  ,reg2dp_cvt_scale              //|> o
  ,reg2dp_cvt_shift              //|> o
  ,reg2dp_dst_base_addr_high     //|> o
  ,reg2dp_dst_base_addr_low      //|> o
  ,reg2dp_dst_batch_stride       //|> o
  ,reg2dp_dst_line_stride        //|> o
  ,reg2dp_dst_ram_type           //|> o
  ,reg2dp_dst_surface_stride     //|> o
  ,reg2dp_ecore_slcg_op_en       //|> o
  ,reg2dp_ew_alu_algo            //|> o
  ,reg2dp_ew_alu_bypass          //|> o
  ,reg2dp_ew_alu_cvt_bypass      //|> o
  ,reg2dp_ew_alu_cvt_offset      //|> o
  ,reg2dp_ew_alu_cvt_scale       //|> o
  ,reg2dp_ew_alu_cvt_truncate    //|> o
  ,reg2dp_ew_alu_operand         //|> o
  ,reg2dp_ew_alu_src             //|> o
  ,reg2dp_ew_bypass              //|> o
  ,reg2dp_ew_lut_bypass          //|> o
  ,reg2dp_ew_mul_bypass          //|> o
  ,reg2dp_ew_mul_cvt_bypass      //|> o
  ,reg2dp_ew_mul_cvt_offset      //|> o
  ,reg2dp_ew_mul_cvt_scale       //|> o
  ,reg2dp_ew_mul_cvt_truncate    //|> o
  ,reg2dp_ew_mul_operand         //|> o
  ,reg2dp_ew_mul_prelu           //|> o
  ,reg2dp_ew_mul_src             //|> o
  ,reg2dp_ew_truncate            //|> o
  ,reg2dp_flying_mode            //|> o
  ,reg2dp_height                 //|> o
  ,reg2dp_interrupt_ptr          //|> o
  ,reg2dp_lut_hybrid_priority    //|> o
  ,reg2dp_lut_int_access_type    //|> o
  ,reg2dp_lut_int_addr           //|> o
  ,reg2dp_lut_int_data           //|> o
  ,reg2dp_lut_int_data_wr        //|> o
  ,reg2dp_lut_int_table_id       //|> o
  ,reg2dp_lut_le_end             //|> o
  ,reg2dp_lut_le_function        //|> o
  ,reg2dp_lut_le_index_offset    //|> o
  ,reg2dp_lut_le_index_select    //|> o
  ,reg2dp_lut_le_slope_oflow_scale //|> o
  ,reg2dp_lut_le_slope_oflow_shift //|> o
  ,reg2dp_lut_le_slope_uflow_scale //|> o
  ,reg2dp_lut_le_slope_uflow_shift //|> o
  ,reg2dp_lut_le_start           //|> o
  ,reg2dp_lut_lo_end             //|> o
  ,reg2dp_lut_lo_index_select    //|> o
  ,reg2dp_lut_lo_slope_oflow_scale //|> o
  ,reg2dp_lut_lo_slope_oflow_shift //|> o
  ,reg2dp_lut_lo_slope_uflow_scale //|> o
  ,reg2dp_lut_lo_slope_uflow_shift //|> o
  ,reg2dp_lut_lo_start           //|> o
  ,reg2dp_lut_oflow_priority     //|> o
  ,reg2dp_lut_slcg_en           //|> o
  ,reg2dp_lut_uflow_priority     //|> o
  ,reg2dp_nan_to_zero           //|> o
  ,reg2dp_ncore_slcg_op_en      //|> o
  ,reg2dp_op_en                 //|> o
  ,reg2dp_out_precision         //|> o
  ,reg2dp_output_dst            //|> o
  ,reg2dp_perf_dma_en           //|> o
  ,reg2dp_perf_lut_en           //|> o
  ,reg2dp_perf_nan_inf_count_en //|> o
  ,reg2dp_perf_sat_en           //|> o
  ,reg2dp_proc_precision        //|> o
  ,reg2dp_wdma_slcg_op_en       //|> o
  ,reg2dp_width                 //|> o
  ,reg2dp_winograd              //|> o
  );

//============================================================================
// parameters
//============================================================================
// Register address offsets (byte addresses)
localparam [11:0] REG_S_STATUS         = 12'h000;
localparam [11:0] REG_S_POINTER        = 12'h004;
localparam [11:0] REG_S_LUT_ACCESS_CFG = 12'h008;
localparam [11:0] REG_S_LUT_ACCESS_DATA = 12'h00c;
localparam [11:0] REG_S_LUT_CFG        = 12'h010;
localparam [11:0] REG_S_LUT_INFO      = 12'h014;
localparam [11:0] REG_S_LUT_LE_START   = 12'h018;
localparam [11:0] REG_S_LUT_LE_END     = 12'h01c;
localparam [11:0] REG_S_LUT_LO_START   = 12'h020;
localparam [11:0] REG_S_LUT_LO_END     = 12'h024;
localparam [11:0] REG_S_LUT_LE_SLOPE_SCALE = 12'h028;
localparam [11:0] REG_S_LUT_LE_SLOPE_SHIFT = 12'h02c;
localparam [11:0] REG_S_LUT_LO_SLOPE_SCALE = 12'h030;
localparam [11:0] REG_S_LUT_LO_SLOPE_SHIFT = 12'h034;
localparam [11:0] REG_D_OP_ENABLE      = 12'h038;
localparam [11:0] REG_D_DATA_CUBE_WIDTH = 12'h03c;
localparam [11:0] REG_D_DATA_CUBE_HEIGHT = 12'h040;
localparam [11:0] REG_D_DATA_CUBE_CHANNEL = 12'h044;
localparam [11:0] REG_D_DST_BASE_ADDR_LOW = 12'h048;
localparam [11:0] REG_D_DST_BASE_ADDR_HIGH = 12'h04c;
localparam [11:0] REG_D_DST_LINE_STRIDE = 12'h050;
localparam [11:0] REG_D_DST_SURFACE_STRIDE = 12'h054;
localparam [11:0] REG_D_DST_DMA_CFG    = 12'h058;
localparam [11:0] REG_D_DST_BATCH_STRIDE = 12'h05c;
localparam [11:0] REG_D_FEATURE_MODE_CFG = 12'h0b0;
localparam [11:0] REG_D_DATA_FORMAT    = 12'h0b4;
localparam [11:0] REG_D_DP_BS_CFG      = 12'h0b8;
localparam [11:0] REG_D_DP_BS_ALU_CFG  = 12'h0bc;
localparam [11:0] REG_D_DP_BS_ALU_SRC_VALUE = 12'h0c0;
localparam [11:0] REG_D_DP_BS_MUL_CFG  = 12'h0c4;
localparam [11:0] REG_D_DP_BS_MUL_SRC_VALUE = 12'h0c8;
localparam [11:0] REG_D_DP_BN_CFG      = 12'h0cc;
localparam [11:0] REG_D_DP_BN_ALU_CFG  = 12'h0d0;
localparam [11:0] REG_D_DP_BN_ALU_SRC_VALUE = 12'h0d4;
localparam [11:0] REG_D_DP_BN_MUL_CFG  = 12'h0d8;
localparam [11:0] REG_D_DP_BN_MUL_SRC_VALUE = 12'h0dc;
localparam [11:0] REG_D_DP_EW_CFG      = 12'h0e0;
localparam [11:0] REG_D_DP_EW_ALU_CFG  = 12'h0e4;
localparam [11:0] REG_D_DP_EW_ALU_CVT_OFFSET_VALUE = 12'h0e8;
localparam [11:0] REG_D_DP_EW_ALU_CVT_SCALE_VALUE = 12'h0ec;
localparam [11:0] REG_D_DP_EW_ALU_CVT_TRUNCATE_VALUE = 12'h0f0;
localparam [11:0] REG_D_DP_EW_ALU_SRC_VALUE = 12'h0f4;
localparam [11:0] REG_D_DP_EW_MUL_CFG  = 12'h0f8;
localparam [11:0] REG_D_DP_EW_MUL_CVT_OFFSET_VALUE = 12'h0fc;
localparam [11:0] REG_D_DP_EW_MUL_CVT_SCALE_VALUE = 12'h100;
localparam [11:0] REG_D_DP_EW_MUL_CVT_TRUNCATE_VALUE = 12'h104;
localparam [11:0] REG_D_DP_EW_MUL_SRC_VALUE = 12'h108;
localparam [11:0] REG_D_DP_EW_TRUNCATE_VALUE = 12'h10c;
localparam [11:0] REG_D_CVT_OFFSET     = 12'h110;
localparam [11:0] REG_D_CVT_SCALE      = 12'h114;
localparam [11:0] REG_D_CVT_SHIFT      = 12'h118;
localparam [11:0] REG_D_STATUS         = 12'h11c;
localparam [11:0] REG_D_STATUS_NAN_INPUT_NUM = 12'h120;
localparam [11:0] REG_D_STATUS_INF_INPUT_NUM = 12'h124;
localparam [11:0] REG_D_STATUS_NAN_OUTPUT_NUM = 12'h128;
localparam [11:0] REG_D_PERF_ENABLE    = 12'h1e0;
localparam [11:0] REG_D_PERF_WDMA_WRITE_STALL = 12'h1e4;
localparam [11:0] REG_D_PERF_LUT_UFLOW = 12'h1e8;
localparam [11:0] REG_D_PERF_LUT_OFLOW = 12'h1ec;
localparam [11:0] REG_D_PERF_LUT_HYBRID = 12'h1f0;
localparam [11:0] REG_D_PERF_LUT_LE_HIT = 12'h1f4;
localparam [11:0] REG_D_PERF_LUT_LO_HIT = 12'h1f8;
localparam [11:0] REG_D_PERF_OUT_SATURATION = 12'h1fc;

// Register field masks and shifts
localparam OP_ENABLE_OFFSET = 12'h038;

//============================================================================
// signal declarations
//============================================================================
// Clock and reset
input  nvdla_core_clk;
input  nvdla_core_rstn;

// CSB interface
input  [62:0] csb2sdp_req_pd;
input  csb2sdp_req_pvld;
output csb2sdp_req_prdy;
output [33:0] sdp2csb_resp_pd;
output sdp2csb_resp_valid;

// Status inputs
input  dp2reg_done;
input  [31:0] dp2reg_lut_hybrid;
input  [15:0] dp2reg_lut_int_data;
input  [31:0] dp2reg_lut_le_hit;
input  [31:0] dp2reg_lut_lo_hit;
input  [31:0] dp2reg_lut_oflow;
input  [31:0] dp2reg_lut_uflow;
input  [31:0] dp2reg_out_saturation;
input  [31:0] dp2reg_status_inf_input_num;
input  [31:0] dp2reg_status_nan_input_num;
input  [31:0] dp2reg_status_nan_output_num;
input  dp2reg_status_unequal;
input  [31:0] dp2reg_wdma_stall;

// Configuration outputs - X1 (BS) path
output [4:0] reg2dp_batch_number;
output reg2dp_bcore_slcg_op_en;
output reg2dp_bn_alu_algo;
output reg2dp_bn_alu_bypass;
output [15:0] reg2dp_bn_alu_operand;
output [5:0] reg2dp_bn_alu_shift_value;
output reg2dp_bn_alu_src;
output reg2dp_bn_bypass;
output reg2dp_bn_mul_bypass;
output [15:0] reg2dp_bn_mul_operand;
output reg2dp_bn_mul_prelu;
output [7:0] reg2dp_bn_mul_shift_value;
output reg2dp_bn_mul_src;
output reg2dp_bn_relu_bypass;
output reg2dp_bs_alu_algo;
output reg2dp_bs_alu_bypass;
output [15:0] reg2dp_bs_alu_operand;
output [5:0] reg2dp_bs_alu_shift_value;
output reg2dp_bs_alu_src;
output reg2dp_bs_bypass;
output reg2dp_bs_mul_bypass;
output [15:0] reg2dp_bs_mul_operand;
output reg2dp_bs_mul_prelu;
output [7:0] reg2dp_bs_mul_shift_value;
output reg2dp_bs_mul_src;
output reg2dp_bs_relu_bypass;

// Datapath configuration
output [12:0] reg2dp_channel;
output [31:0] reg2dp_cvt_offset;
output [15:0] reg2dp_cvt_scale;
output [5:0] reg2dp_cvt_shift;
output [31:0] reg2dp_dst_base_addr_high;
output [26:0] reg2dp_dst_base_addr_low;
output [26:0] reg2dp_dst_batch_stride;
output [26:0] reg2dp_dst_line_stride;
output reg2dp_dst_ram_type;
output [26:0] reg2dp_dst_surface_stride;
output reg2dp_ecore_slcg_op_en;
output [1:0] reg2dp_ew_alu_algo;
output reg2dp_ew_alu_bypass;
output reg2dp_ew_alu_cvt_bypass;
output [31:0] reg2dp_ew_alu_cvt_offset;
output [15:0] reg2dp_ew_alu_cvt_scale;
output [5:0] reg2dp_ew_alu_cvt_truncate;
output [31:0] reg2dp_ew_alu_operand;
output reg2dp_ew_alu_src;
output reg2dp_ew_bypass;
output reg2dp_ew_lut_bypass;
output reg2dp_ew_mul_bypass;
output reg2dp_ew_mul_cvt_bypass;
output [31:0] reg2dp_ew_mul_cvt_offset;
output [15:0] reg2dp_ew_mul_cvt_scale;
output [5:0] reg2dp_ew_mul_cvt_truncate;
output [31:0] reg2dp_ew_mul_operand;
output reg2dp_ew_mul_prelu;
output reg2dp_ew_mul_src;
output [9:0] reg2dp_ew_truncate;
output reg2dp_flying_mode;
output [12:0] reg2dp_height;
output reg2dp_interrupt_ptr;
output reg2dp_lut_hybrid_priority;
output reg2dp_lut_int_access_type;
output [9:0] reg2dp_lut_int_addr;
output [15:0] reg2dp_lut_int_data;
output reg2dp_lut_int_data_wr;
output reg2dp_lut_int_table_id;
output [31:0] reg2dp_lut_le_end;
output reg2dp_lut_le_function;
output [7:0] reg2dp_lut_le_index_offset;
output [7:0] reg2dp_lut_le_index_select;
output [15:0] reg2dp_lut_le_slope_oflow_scale;
output [4:0] reg2dp_lut_le_slope_oflow_shift;
output [15:0] reg2dp_lut_le_slope_uflow_scale;
output [4:0] reg2dp_lut_le_slope_uflow_shift;
output [31:0] reg2dp_lut_le_start;
output [31:0] reg2dp_lut_lo_end;
output [7:0] reg2dp_lut_lo_index_select;
output [15:0] reg2dp_lut_lo_slope_oflow_scale;
output [4:0] reg2dp_lut_lo_slope_oflow_shift;
output [15:0] reg2dp_lut_lo_slope_uflow_scale;
output [4:0] reg2dp_lut_lo_slope_uflow_shift;
output [31:0] reg2dp_lut_lo_start;
output reg2dp_lut_oflow_priority;
output reg2dp_lut_slcg_en;
output reg2dp_lut_uflow_priority;
output reg2dp_nan_to_zero;
output reg2dp_ncore_slcg_op_en;
output reg2dp_op_en;
output [1:0] reg2dp_out_precision;
output reg2dp_output_dst;
output reg2dp_perf_dma_en;
output reg2dp_perf_lut_en;
output reg2dp_perf_nan_inf_count_en;
output reg2dp_perf_sat_en;
output [1:0] reg2dp_proc_precision;
output reg2dp_wdma_slcg_op_en;
output [12:0] reg2dp_width;
output reg2dp_winograd;

//============================================================================
// internal signals
//============================================================================
// CSB request decoded signals
wire req_write;
wire req_read;
wire [15:0] req_addr;
wire [31:0] req_wdat;
wire [3:0] req_wrbe;
wire req_nposted;

// Register address (word-aligned within 4KB block)
wire [11:0] reg_offset;

// Bank selection
reg bank_sel_r;  // 0 = group_0, 1 = group_1

// Producer pointer
reg producer_q;
reg consumer_q;

// Register bank 0
reg [31:0] reg_group_0 [0:255];
reg [31:0] reg_group_1 [0:255];

// Status registers (updated by datapath)
reg [31:0] reg_status_0;
reg [31:0] reg_status_1;
reg [31:0] reg_status_nan_input_num;
reg [31:0] reg_status_inf_input_num;
reg [31:0] reg_status_nan_output_num;
reg [31:0] reg_wdma_stall;
reg [31:0] reg_lut_uflow;
reg [31:0] reg_lut_oflow;
reg [31:0] reg_lut_hybrid;
reg [31:0] reg_lut_le_hit;
reg [31:0] reg_lut_lo_hit;
reg [31:0] reg_out_saturation;

// Read data output
reg [31:0] read_data_q;

// Operation enable
reg op_en_r;

//============================================================================
// CSB request decoding
//============================================================================
assign req_addr  = csb2sdp_req_pd[31:16];
assign req_wdat  = {16'b0, csb2sdp_req_pd[15:0]};
assign req_wrbe  = csb2sdp_req_pd[60:57];
assign req_nposted = csb2sdp_req_pd[55];
assign req_write = csb2sdp_req_pd[54];
assign req_read  = csb2sdp_req_pd[53];

// Address in CSB master is word aligned, convert to byte offset
assign reg_offset = {req_addr[13:2], 2'b0};

//============================================================================
// CSB response generation
//============================================================================
assign csb2sdp_req_prdy = 1'b1;

// Response packet: [33] = error, [32] = posted, [31:16] = reserved, [15:0] = data
assign sdp2csb_resp_pd = {1'b0, req_nposted, 17'b0, read_data_q[15:0]};
assign sdp2csb_resp_valid = 1'b0;  // Will be pulsed when response is sent

//============================================================================
// Bank selection logic
//============================================================================
// Producer pointer determines which bank is active for writes
// Consumer pointer determines which bank is being processed by HW
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    producer_q <= 1'b0;
    consumer_q <= 1'b0;
  end else begin
    // Producer increments when operation is enabled
    if (reg_group_0[REG_D_OP_ENABLE][0] && (producer_q == 1'b0)) begin
      producer_q <= 1'b1;
    end else if (reg_group_1[REG_D_OP_ENABLE][0] && (producer_q == 1'b1)) begin
      producer_q <= 1'b0;
    end
    // Consumer follows producer after operation completes
    if (dp2reg_done) begin
      consumer_q <= producer_q;
    end
  end
end

// Bank selection for read/write
wire bank_sel = producer_q;  // Write to the bank that's not currently being processed

//============================================================================
// Register file access
//============================================================================
// Write operation
wire reg_write_en = req_write && csb2sdp_req_pvld;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_r <= 1'b0;
  end else begin
    if (reg_write_en && (reg_offset == REG_D_OP_ENABLE)) begin
      op_en_r <= req_wdat[0];
    end
  end
end

// Read operation
always @* begin
  if (!nvdla_core_rstn) begin
    read_data_q = 32'b0;
  end else if (reg_offset >= 12'h400) begin
    // Shadow registers (status, etc) - read from both banks
    case (reg_offset)
      REG_S_STATUS: read_data_q = {30'b0, reg_status_1[1:0]};
      default: read_data_q = 32'b0;
    endcase
  end else begin
    // Normal registers - read from active bank
    if (bank_sel == 1'b0) begin
      read_data_q = reg_group_0[reg_offset[11:2]];
    end else begin
      read_data_q = reg_group_1[reg_offset[11:2]];
    end
  end
end

// Register write - only certain offsets are writable
wire is_writable_offset = (reg_offset < 12'h400) &&
                          (reg_offset != REG_S_STATUS) &&
                          (reg_offset != REG_S_POINTER);

wire [11:0] write_offset = reg_offset[11:2];

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    // Reset registers
    integer i;
    for (i = 0; i < 256; i = i + 1) begin
      reg_group_0[i] <= 32'b0;
      reg_group_1[i] <= 32'b0;
    end
  end else if (reg_write_en && is_writable_offset) begin
    // Write to selected bank
    if (bank_sel == 1'b0) begin
      reg_group_0[write_offset] <= req_wdat;
    end else begin
      reg_group_1[write_offset] <= req_wdat;
    end
  end
end

//============================================================================
// Status register updates from datapath
//============================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg_status_nan_input_num <= 32'b0;
    reg_status_inf_input_num <= 32'b0;
    reg_status_nan_output_num <= 32'b0;
    reg_wdma_stall <= 32'b0;
    reg_lut_uflow <= 32'b0;
    reg_lut_oflow <= 32'b0;
    reg_lut_hybrid <= 32'b0;
    reg_lut_le_hit <= 32'b0;
    reg_lut_lo_hit <= 32'b0;
    reg_out_saturation <= 32'b0;
  end else begin
    reg_status_nan_input_num <= dp2reg_status_nan_input_num;
    reg_status_inf_input_num <= dp2reg_status_inf_input_num;
    reg_status_nan_output_num <= dp2reg_status_nan_output_num;
    reg_wdma_stall <= dp2reg_wdma_stall;
    reg_lut_uflow <= dp2reg_lut_uflow;
    reg_lut_oflow <= dp2reg_lut_oflow;
    reg_lut_hybrid <= dp2reg_lut_hybrid;
    reg_lut_le_hit <= dp2reg_lut_le_hit;
    reg_lut_lo_hit <= dp2reg_lut_lo_hit;
    reg_out_saturation <= dp2reg_out_saturation;
  end
end

//============================================================================
// Register output generation
//============================================================================
// Select the active register bank based on consumer pointer
wire [31:0] active_status_0 = consumer_q ?
    reg_group_1[REG_S_STATUS] : reg_group_0[REG_S_STATUS];

// Generate outputs from the active register bank
assign reg2dp_op_en = consumer_q ?
    reg_group_1[REG_D_OP_ENABLE][0] : reg_group_0[REG_D_OP_ENABLE][0];

// SDP common configuration
assign reg2dp_proc_precision = consumer_q ?
    reg_group_1[REG_D_DATA_FORMAT][1:0] : reg_group_0[REG_D_DATA_FORMAT][1:0];
assign reg2dp_out_precision = consumer_q ?
    reg_group_1[REG_D_DATA_FORMAT][3:2] : reg_group_0[REG_D_DATA_FORMAT][3:2];

// Cube dimensions
assign reg2dp_width = consumer_q ?
    reg_group_1[REG_D_DATA_CUBE_WIDTH][12:0] : reg_group_0[REG_D_DATA_CUBE_WIDTH][12:0];
assign reg2dp_height = consumer_q ?
    reg_group_1[REG_D_DATA_CUBE_HEIGHT][12:0] : reg_group_0[REG_D_DATA_CUBE_HEIGHT][12:0];
assign reg2dp_channel = consumer_q ?
    reg_group_1[REG_D_DATA_CUBE_CHANNEL][12:0] : reg_group_0[REG_D_DATA_CUBE_CHANNEL][12:0];

// Destination address
assign reg2dp_dst_base_addr_low = consumer_q ?
    reg_group_1[REG_D_DST_BASE_ADDR_LOW][26:0] : reg_group_0[REG_D_DST_BASE_ADDR_LOW][26:0];
assign reg2dp_dst_base_addr_high = consumer_q ?
    reg_group_1[REG_D_DST_BASE_ADDR_HIGH] : reg_group_0[REG_D_DST_BASE_ADDR_HIGH];
assign reg2dp_dst_line_stride = consumer_q ?
    reg_group_1[REG_D_DST_LINE_STRIDE][26:0] : reg_group_0[REG_D_DST_LINE_STRIDE][26:0];
assign reg2dp_dst_surface_stride = consumer_q ?
    reg_group_1[REG_D_DST_SURFACE_STRIDE][26:0] : reg_group_0[REG_D_DST_SURFACE_STRIDE][26:0];
assign reg2dp_dst_batch_stride = consumer_q ?
    reg_group_1[REG_D_DST_BATCH_STRIDE][26:0] : reg_group_0[REG_D_DST_BATCH_STRIDE][26:0];
assign reg2dp_dst_ram_type = consumer_q ?
    reg_group_1[REG_D_DST_DMA_CFG][0] : reg_group_0[REG_D_DST_DMA_CFG][0];

// Feature mode
assign reg2dp_flying_mode = consumer_q ?
    reg_group_1[REG_D_FEATURE_MODE_CFG][0] : reg_group_0[REG_D_FEATURE_MODE_CFG][0];
assign reg2dp_winograd = consumer_q ?
    reg_group_1[REG_D_FEATURE_MODE_CFG][4] : reg_group_0[REG_D_FEATURE_MODE_CFG][4];
assign reg2dp_output_dst = consumer_q ?
    reg_group_1[REG_D_FEATURE_MODE_CFG][1] : reg_group_0[REG_D_FEATURE_MODE_CFG][1];
assign reg2dp_nan_to_zero = consumer_q ?
    reg_group_1[REG_D_FEATURE_MODE_CFG][2] : reg_group_0[REG_D_FEATURE_MODE_CFG][2];
assign reg2dp_batch_number = consumer_q ?
    reg_group_1[REG_D_FEATURE_MODE_CFG][9:5] : reg_group_0[REG_D_FEATURE_MODE_CFG][9:5];

// X1 (BS) path configuration
assign reg2dp_bs_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BS_CFG][0] : reg_group_0[REG_D_DP_BS_CFG][0];
assign reg2dp_bs_alu_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BS_CFG][1] : reg_group_0[REG_D_DP_BS_CFG][1];
assign reg2dp_bs_alu_algo = consumer_q ?
    reg_group_1[REG_D_DP_BS_CFG][3:2] : reg_group_0[REG_D_DP_BS_CFG][3:2];
assign reg2dp_bs_mul_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BS_CFG][4] : reg_group_0[REG_D_DP_BS_CFG][4];
assign reg2dp_bs_mul_prelu = consumer_q ?
    reg_group_1[REG_D_DP_BS_CFG][5] : reg_group_0[REG_D_DP_BS_CFG][5];
assign reg2dp_bs_relu_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BS_CFG][6] : reg_group_0[REG_D_DP_BS_CFG][6];

assign reg2dp_bs_alu_src = consumer_q ?
    reg_group_1[REG_D_DP_BS_ALU_CFG][0] : reg_group_0[REG_D_DP_BS_ALU_CFG][0];
assign reg2dp_bs_alu_shift_value = consumer_q ?
    reg_group_1[REG_D_DP_BS_ALU_CFG][6:1] : reg_group_0[REG_D_DP_BS_ALU_CFG][6:1];
assign reg2dp_bs_alu_operand = consumer_q ?
    reg_group_1[REG_D_DP_BS_ALU_SRC_VALUE][15:0] : reg_group_0[REG_D_DP_BS_ALU_SRC_VALUE][15:0];

assign reg2dp_bs_mul_src = consumer_q ?
    reg_group_1[REG_D_DP_BS_MUL_CFG][0] : reg_group_0[REG_D_DP_BS_MUL_CFG][0];
assign reg2dp_bs_mul_shift_value = consumer_q ?
    reg_group_1[REG_D_DP_BS_MUL_CFG][7:1] : reg_group_0[REG_D_DP_BS_MUL_CFG][7:1];
assign reg2dp_bs_mul_operand = consumer_q ?
    reg_group_1[REG_D_DP_BS_MUL_SRC_VALUE][15:0] : reg_group_0[REG_D_DP_BS_MUL_SRC_VALUE][15:0];

// X2 (BN) path configuration
assign reg2dp_bn_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BN_CFG][0] : reg_group_0[REG_D_DP_BN_CFG][0];
assign reg2dp_bn_alu_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BN_CFG][1] : reg_group_0[REG_D_DP_BN_CFG][1];
assign reg2dp_bn_alu_algo = consumer_q ?
    reg_group_1[REG_D_DP_BN_CFG][3:2] : reg_group_0[REG_D_DP_BN_CFG][3:2];
assign reg2dp_bn_mul_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BN_CFG][4] : reg_group_0[REG_D_DP_BN_CFG][4];
assign reg2dp_bn_mul_prelu = consumer_q ?
    reg_group_1[REG_D_DP_BN_CFG][5] : reg_group_0[REG_D_DP_BN_CFG][5];
assign reg2dp_bn_relu_bypass = consumer_q ?
    reg_group_1[REG_D_DP_BN_CFG][6] : reg_group_0[REG_D_DP_BN_CFG][6];

assign reg2dp_bn_alu_src = consumer_q ?
    reg_group_1[REG_D_DP_BN_ALU_CFG][0] : reg_group_0[REG_D_DP_BN_ALU_CFG][0];
assign reg2dp_bn_alu_shift_value = consumer_q ?
    reg_group_1[REG_D_DP_BN_ALU_CFG][6:1] : reg_group_0[REG_D_DP_BN_ALU_CFG][6:1];
assign reg2dp_bn_alu_operand = consumer_q ?
    reg_group_1[REG_D_DP_BN_ALU_SRC_VALUE][15:0] : reg_group_0[REG_D_DP_BN_ALU_SRC_VALUE][15:0];

assign reg2dp_bn_mul_src = consumer_q ?
    reg_group_1[REG_D_DP_BN_MUL_CFG][0] : reg_group_0[REG_D_DP_BN_MUL_CFG][0];
assign reg2dp_bn_mul_shift_value = consumer_q ?
    reg_group_1[REG_D_DP_BN_MUL_CFG][7:1] : reg_group_0[REG_D_DP_BN_MUL_CFG][7:1];
assign reg2dp_bn_mul_operand = consumer_q ?
    reg_group_1[REG_D_DP_BN_MUL_SRC_VALUE][15:0] : reg_group_0[REG_D_DP_BN_MUL_SRC_VALUE][15:0];

// Y (EW) path configuration
assign reg2dp_ew_bypass = consumer_q ?
    reg_group_1[REG_D_DP_EW_CFG][0] : reg_group_0[REG_D_DP_EW_CFG][0];
assign reg2dp_ew_alu_bypass = consumer_q ?
    reg_group_1[REG_D_DP_EW_CFG][1] : reg_group_0[REG_D_DP_EW_CFG][1];
assign reg2dp_ew_alu_algo = consumer_q ?
    reg_group_1[REG_D_DP_EW_CFG][3:2] : reg_group_0[REG_D_DP_EW_CFG][3:2];
assign reg2dp_ew_mul_bypass = consumer_q ?
    reg_group_1[REG_D_DP_EW_CFG][4] : reg_group_0[REG_D_DP_EW_CFG][4];
assign reg2dp_ew_mul_prelu = consumer_q ?
    reg_group_1[REG_D_DP_EW_CFG][5] : reg_group_0[REG_D_DP_EW_CFG][5];
assign reg2dp_ew_lut_bypass = consumer_q ?
    reg_group_1[REG_D_DP_EW_CFG][6] : reg_group_0[REG_D_DP_EW_CFG][6];

assign reg2dp_ew_alu_src = consumer_q ?
    reg_group_1[REG_D_DP_EW_ALU_CFG][0] : reg_group_0[REG_D_DP_EW_ALU_CFG][0];
assign reg2dp_ew_alu_cvt_bypass = consumer_q ?
    reg_group_1[REG_D_DP_EW_ALU_CFG][1] : reg_group_0[REG_D_DP_EW_ALU_CFG][1];
assign reg2dp_ew_alu_operand = consumer_q ?
    reg_group_1[REG_D_DP_EW_ALU_SRC_VALUE][31:0] : reg_group_0[REG_D_DP_EW_ALU_SRC_VALUE][31:0];
assign reg2dp_ew_alu_cvt_offset = consumer_q ?
    reg_group_1[REG_D_DP_EW_ALU_CVT_OFFSET_VALUE] : reg_group_0[REG_D_DP_EW_ALU_CVT_OFFSET_VALUE];
assign reg2dp_ew_alu_cvt_scale = consumer_q ?
    reg_group_1[REG_D_DP_EW_ALU_CVT_SCALE_VALUE][15:0] : reg_group_0[REG_D_DP_EW_ALU_CVT_SCALE_VALUE][15:0];
assign reg2dp_ew_alu_cvt_truncate = consumer_q ?
    reg_group_1[REG_D_DP_EW_ALU_CVT_TRUNCATE_VALUE][5:0] : reg_group_0[REG_D_DP_EW_ALU_CVT_TRUNCATE_VALUE][5:0];

assign reg2dp_ew_mul_src = consumer_q ?
    reg_group_1[REG_D_DP_EW_MUL_CFG][0] : reg_group_0[REG_D_DP_EW_MUL_CFG][0];
assign reg2dp_ew_mul_cvt_bypass = consumer_q ?
    reg_group_1[REG_D_DP_EW_MUL_CFG][1] : reg_group_0[REG_D_DP_EW_MUL_CFG][1];
assign reg2dp_ew_mul_operand = consumer_q ?
    reg_group_1[REG_D_DP_EW_MUL_SRC_VALUE][31:0] : reg_group_0[REG_D_DP_EW_MUL_SRC_VALUE][31:0];
assign reg2dp_ew_mul_cvt_offset = consumer_q ?
    reg_group_1[REG_D_DP_EW_MUL_CVT_OFFSET_VALUE] : reg_group_0[REG_D_DP_EW_MUL_CVT_OFFSET_VALUE];
assign reg2dp_ew_mul_cvt_scale = consumer_q ?
    reg_group_1[REG_D_DP_EW_MUL_CVT_SCALE_VALUE][15:0] : reg_group_0[REG_D_DP_EW_MUL_CVT_SCALE_VALUE][15:0];
assign reg2dp_ew_mul_cvt_truncate = consumer_q ?
    reg_group_1[REG_D_DP_EW_MUL_CVT_TRUNCATE_VALUE][5:0] : reg_group_0[REG_D_DP_EW_MUL_CVT_TRUNCATE_VALUE][5:0];

assign reg2dp_ew_truncate = consumer_q ?
    reg_group_1[REG_D_DP_EW_TRUNCATE_VALUE][9:0] : reg_group_0[REG_D_DP_EW_TRUNCATE_VALUE][9:0];

// CVT configuration
assign reg2dp_cvt_offset = consumer_q ?
    reg_group_1[REG_D_CVT_OFFSET] : reg_group_0[REG_D_CVT_OFFSET];
assign reg2dp_cvt_scale = consumer_q ?
    reg_group_1[REG_D_CVT_SCALE][15:0] : reg_group_0[REG_D_CVT_SCALE][15:0];
assign reg2dp_cvt_shift = consumer_q ?
    reg_group_1[REG_D_CVT_SHIFT][5:0] : reg_group_0[REG_D_CVT_SHIFT][5:0];

// Performance enable
assign reg2dp_perf_dma_en = consumer_q ?
    reg_group_1[REG_D_PERF_ENABLE][0] : reg_group_0[REG_D_PERF_ENABLE][0];
assign reg2dp_perf_lut_en = consumer_q ?
    reg_group_1[REG_D_PERF_ENABLE][1] : reg_group_0[REG_D_PERF_ENABLE][1];
assign reg2dp_perf_sat_en = consumer_q ?
    reg_group_1[REG_D_PERF_ENABLE][2] : reg_group_0[REG_D_PERF_ENABLE][2];
assign reg2dp_perf_nan_inf_count_en = consumer_q ?
    reg_group_1[REG_D_PERF_ENABLE][3] : reg_group_0[REG_D_PERF_ENABLE][3];

// Clock gating
assign reg2dp_wdma_slcg_op_en = 1'b1;  // Default enabled
assign reg2dp_bcore_slcg_op_en = 1'b1;
assign reg2dp_ecore_slcg_op_en = 1'b1;
assign reg2dp_ncore_slcg_op_en = 1'b1;
assign reg2dp_lut_slcg_en = 1'b1;

// Interrupt pointer
assign reg2dp_interrupt_ptr = 1'b0;  // Default to group 0

// LUT configuration - read from both banks and select
assign reg2dp_lut_le_function = consumer_q ?
    reg_group_1[REG_S_LUT_CFG][0] : reg_group_0[REG_S_LUT_CFG][0];
assign reg2dp_lut_uflow_priority = consumer_q ?
    reg_group_1[REG_S_LUT_CFG][1] : reg_group_0[REG_S_LUT_CFG][1];
assign reg2dp_lut_oflow_priority = consumer_q ?
    reg_group_1[REG_S_LUT_CFG][2] : reg_group_0[REG_S_LUT_CFG][2];
assign reg2dp_lut_hybrid_priority = consumer_q ?
    reg_group_1[REG_S_LUT_CFG][3] : reg_group_0[REG_S_LUT_CFG][3];
assign reg2dp_lut_le_start = consumer_q ?
    reg_group_1[REG_S_LUT_LE_START] : reg_group_0[REG_S_LUT_LE_START];
assign reg2dp_lut_le_end = consumer_q ?
    reg_group_1[REG_S_LUT_LE_END] : reg_group_0[REG_S_LUT_LE_END];
assign reg2dp_lut_lo_start = consumer_q ?
    reg_group_1[REG_S_LUT_LO_START] : reg_group_0[REG_S_LUT_LO_START];
assign reg2dp_lut_lo_end = consumer_q ?
    reg_group_1[REG_S_LUT_LO_END] : reg_group_0[REG_S_LUT_LO_END];
assign reg2dp_lut_le_index_offset = consumer_q ?
    reg_group_1[REG_S_LUT_INFO][7:0] : reg_group_0[REG_S_LUT_INFO][7:0];
assign reg2dp_lut_le_index_select = consumer_q ?
    reg_group_1[REG_S_LUT_INFO][15:8] : reg_group_0[REG_S_LUT_INFO][15:8];
assign reg2dp_lut_lo_index_select = consumer_q ?
    reg_group_1[REG_S_LUT_INFO][23:16] : reg_group_0[REG_S_LUT_INFO][23:16];
assign reg2dp_lut_le_slope_uflow_scale = consumer_q ?
    reg_group_1[REG_S_LUT_LE_SLOPE_SCALE][15:0] : reg_group_0[REG_S_LUT_LE_SLOPE_SCALE][15:0];
assign reg2dp_lut_le_slope_oflow_scale = consumer_q ?
    reg_group_1[REG_S_LUT_LE_SLOPE_SCALE][31:16] : reg_group_0[REG_S_LUT_LE_SLOPE_SCALE][31:16];
assign reg2dp_lut_le_slope_uflow_shift = consumer_q ?
    reg_group_1[REG_S_LUT_LE_SLOPE_SHIFT][4:0] : reg_group_0[REG_S_LUT_LE_SLOPE_SHIFT][4:0];
assign reg2dp_lut_le_slope_oflow_shift = consumer_q ?
    reg_group_1[REG_S_LUT_LE_SLOPE_SHIFT][9:5] : reg_group_0[REG_S_LUT_LE_SLOPE_SHIFT][9:5];
assign reg2dp_lut_lo_slope_uflow_scale = consumer_q ?
    reg_group_1[REG_S_LUT_LO_SLOPE_SCALE][15:0] : reg_group_0[REG_S_LUT_LO_SLOPE_SCALE][15:0];
assign reg2dp_lut_lo_slope_oflow_scale = consumer_q ?
    reg_group_1[REG_S_LUT_LO_SLOPE_SCALE][31:16] : reg_group_0[REG_S_LUT_LO_SLOPE_SCALE][31:16];
assign reg2dp_lut_lo_slope_uflow_shift = consumer_q ?
    reg_group_1[REG_S_LUT_LO_SLOPE_SHIFT][4:0] : reg_group_0[REG_S_LUT_LO_SLOPE_SHIFT][4:0];
assign reg2dp_lut_lo_slope_oflow_shift = consumer_q ?
    reg_group_1[REG_S_LUT_LO_SLOPE_SHIFT][9:5] : reg_group_0[REG_S_LUT_LO_SLOPE_SHIFT][9:5];

// LUT internal access
assign reg2dp_lut_int_access_type = 1'b0;  // Default read
assign reg2dp_lut_int_addr = 10'b0;
assign reg2dp_lut_int_data = 16'b0;
assign reg2dp_lut_int_data_wr = 1'b0;
assign reg2dp_lut_int_table_id = 1'b0;

endmodule // NV_NVDLA_SDP_reg_new