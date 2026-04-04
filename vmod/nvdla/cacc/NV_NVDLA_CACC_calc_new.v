// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CACC_calc_new.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CACC Calculator - Accumulation and formatting engine
// - Receives MAC results from MAC_A and MAC_B
// - Concatenates data from both MAC units
// - Writes to assembly buffer for accumulation
// - Reads from assembly buffer for reshape/format
// - Writes formatted data to delivery buffer
// - Handles INT8, INT16, and FP16 precision
// - FHDR------------------------------------------------------------

module NV_NVDLA_CACC_calc_new (
   nvdla_core_clk           //|< i
  ,nvdla_core_rstn         //|< i

  // Register configuration inputs
  ,reg2dp_op_en            //|< i
  ,reg2dp_conv_mode        //|< i
  ,reg2dp_proc_precision   //|< i  [1:0]
  ,reg2dp_clip_truncate    //|< i  [4:0]

  // MAC A data input
  ,mac_a2accu_pvld         //|< i
  ,mac_a2accu_mask         //|< i  [7:0]
  ,mac_a2accu_mode         //|< i  [7:0]
  ,mac_a2accu_pd           //|< i  [8:0]
  ,mac_a2accu_data0        //|< i  [175:0]
  ,mac_a2accu_data1        //|< i  [175:0]
  ,mac_a2accu_data2        //|< i  [175:0]
  ,mac_a2accu_data3        //|< i  [175:0]
  ,mac_a2accu_data4        //|< i  [175:0]
  ,mac_a2accu_data5        //|< i  [175:0]
  ,mac_a2accu_data6        //|< i  [175:0]
  ,mac_a2accu_data7        //|< i  [175:0]

  // MAC B data input
  ,mac_b2accu_pvld         //|< i
  ,mac_b2accu_mask         //|< i  [7:0]
  ,mac_b2accu_mode         //|< i  [7:0]
  ,mac_b2accu_pd           //|< i  [8:0]
  ,mac_b2accu_data0        //|< i  [175:0]
  ,mac_b2accu_data1        //|< i  [175:0]
  ,mac_b2accu_data2        //|< i  [175:0]
  ,mac_b2accu_data3        //|< i  [175:0]
  ,mac_b2accu_data4        //|< i  [175:0]
  ,mac_b2accu_data5        //|< i  [175:0]
  ,mac_b2accu_data6        //|< i  [175:0]
  ,mac_b2accu_data7        //|< i  [175:0]

  // Assembly buffer interface
  ,abuf_rd_addr            //|> o  [4:0]
  ,abuf_rd_en              //|> o  [7:0]
  ,abuf_wr_addr            //|> o  [4:0]
  ,abuf_wr_data_0          //|> o  [767:0]
  ,abuf_wr_data_1          //|> o  [767:0]
  ,abuf_wr_data_2          //|> o  [767:0]
  ,abuf_wr_data_3          //|> o  [767:0]
  ,abuf_wr_data_4          //|> o  [543:0]
  ,abuf_wr_data_5          //|> o  [543:0]
  ,abuf_wr_data_6          //|> o  [543:0]
  ,abuf_wr_data_7          //|> o  [543:0]
  ,abuf_wr_en              //|> o  [7:0]

  // Assembly buffer read data (from buffer)
  ,abuf_rd_data_0          //|< i  [767:0]
  ,abuf_rd_data_1          //|< i  [767:0]
  ,abuf_rd_data_2          //|< i  [767:0]
  ,abuf_rd_data_3          //|< i  [767:0]
  ,abuf_rd_data_4          //|< i  [543:0]
  ,abuf_rd_data_5          //|< i  [543:0]
  ,abuf_rd_data_6          //|< i  [543:0]
  ,abuf_rd_data_7          //|< i  [543:0]

  // Delivery buffer interface
  ,dbuf_wr_addr_0         //|> o  [4:0]
  ,dbuf_wr_addr_1         //|> o  [4:0]
  ,dbuf_wr_addr_2         //|> o  [4:0]
  ,dbuf_wr_addr_3         //|> o  [4:0]
  ,dbuf_wr_addr_4         //|> o  [4:0]
  ,dbuf_wr_addr_5         //|> o  [4:0]
  ,dbuf_wr_addr_6         //|> o  [4:0]
  ,dbuf_wr_addr_7         //|> o  [4:0]
  ,dbuf_wr_data_0         //|> o  [511:0]
  ,dbuf_wr_data_1         //|> o  [511:0]
  ,dbuf_wr_data_2         //|> o  [511:0]
  ,dbuf_wr_data_3         //|> o  [511:0]
  ,dbuf_wr_data_4         //|> o  [511:0]
  ,dbuf_wr_data_5         //|> o  [511:0]
  ,dbuf_wr_data_6         //|> o  [511:0]
  ,dbuf_wr_data_7         //|> o  [511:0]
  ,dbuf_wr_en             //|> o  [7:0]

  // Status outputs
  ,dp2reg_done            //|> o
  ,dp2reg_sat_count       //|> o  [31:0]
  );

//===============================================================
// Parameters
//===============================================================
parameter MAC_CELL_NUM              = 16;
parameter HALF_MAC_CELL_NUM         = 8;
parameter RESULT_NUM_PER_MACCELL    = 8;
parameter ELEMENT_PER_MAC_CELL_INT8 = 8;

parameter ATOM_ELEMENT_NUM_INT8      = 32;
parameter ATOM_ELEMENT_NUM_INT16     = 16;
parameter ATOM_ELEMENT_NUM_FP16      = 16;

parameter ACCU_ASSEMBLY_BIT_WIDTH_INT16 = 48;
parameter ACCU_DELIVERY_BIT_WIDTH_INT16 = 32;

parameter MAC_OUTPUT_BIT_WIDTH_INT8  = 22;
parameter MAC_OUTPUT_BIT_WIDTH_INT16 = 46;
parameter MAC_OUTPUT_BIT_WIDTH_FP16  = 32;

parameter CONV_MODE_DIRECT  = 1'b0;
parameter CONV_MODE_WINOGAD = 1'b1;

parameter DATA_FORMAT_INT8 = 2'b00;
parameter DATA_FORMAT_INT16 = 2'b01;
parameter DATA_FORMAT_FP16 = 2'b10;

parameter CACC_TO_SDP_THROUGHPUT = 16;

parameter INT32_MAX = 32'h7fffffff;
parameter INT32_MIN = 32'h80000000;
parameter MAX_INT_48BITS = 47'h7fffffffffff;
parameter MIN_INT_48BITS = 47'h800000000000;

//===============================================================
// Port declarations
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// Register configuration
input         reg2dp_op_en;
input         reg2dp_conv_mode;
input  [1:0]  reg2dp_proc_precision;
input  [4:0]  reg2dp_clip_truncate;

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

// Assembly buffer write interface
output [4:0]  abuf_wr_addr;
output [767:0] abuf_wr_data_0;
output [767:0] abuf_wr_data_1;
output [767:0] abuf_wr_data_2;
output [767:0] abuf_wr_data_3;
output [543:0] abuf_wr_data_4;
output [543:0] abuf_wr_data_5;
output [543:0] abuf_wr_data_6;
output [543:0] abuf_wr_data_7;
output [7:0]  abuf_wr_en;

// Assembly buffer read interface
output [4:0]  abuf_rd_addr;
output [7:0]  abuf_rd_en;
input  [767:0] abuf_rd_data_0;
input  [767:0] abuf_rd_data_1;
input  [767:0] abuf_rd_data_2;
input  [767:0] abuf_rd_data_3;
input  [543:0] abuf_rd_data_4;
input  [543:0] abuf_rd_data_5;
input  [543:0] abuf_rd_data_6;
input  [543:0] abuf_rd_data_7;

// Delivery buffer write interface
output [4:0]  dbuf_wr_addr_0;
output [4:0]  dbuf_wr_addr_1;
output [4:0]  dbuf_wr_addr_2;
output [4:0]  dbuf_wr_addr_3;
output [4:0]  dbuf_wr_addr_4;
output [4:0]  dbuf_wr_addr_5;
output [4:0]  dbuf_wr_addr_6;
output [4:0]  dbuf_wr_addr_7;
output [511:0] dbuf_wr_data_0;
output [511:0] dbuf_wr_data_1;
output [511:0] dbuf_wr_data_2;
output [511:0] dbuf_wr_data_3;
output [511:0] dbuf_wr_data_4;
output [511:0] dbuf_wr_data_5;
output [511:0] dbuf_wr_data_6;
output [511:0] dbuf_wr_data_7;
output [7:0]  dbuf_wr_en;

// Status outputs
output        dp2reg_done;
output reg [31:0] dp2reg_sat_count;

//===============================================================
// Internal signals
//===============================================================
// MAC data concatenation
wire [MAC_OUTPUT_BIT_WIDTH_INT8*HALF_MAC_CELL_NUM*RESULT_NUM_PER_MACCELL-1:0] mac_a_concat_data;
wire [7:0] mac_a_concat_mask;
wire [8:0] mac_a_concat_pd;

wire [MAC_OUTPUT_BIT_WIDTH_INT8*HALF_MAC_CELL_NUM*RESULT_NUM_PER_MACCELL-1:0] mac_b_concat_data;
wire [7:0] mac_b_concat_mask;
wire [8:0] mac_b_concat_pd;

// Combined MAC data
wire [2*MAC_OUTPUT_BIT_WIDTH_INT8*HALF_MAC_CELL_NUM*RESULT_NUM_PER_MACCELL-1:0] mac_combined_data;
wire [15:0] mac_combined_mask;
wire [8:0]  mac_combined_pd;

// Assembly index tracking
reg  [12:0] assembly_sram_group_idx_working;
reg  [12:0] assembly_sram_group_idx_available;
reg  [12:0] assembly_sram_group_idx_fetched;
reg         is_assembly_working;
reg         has_ongoing_channel_operation;
reg  [12:0] saved_assembly_sram_group_idx_working;

// Reshape state machine
reg         reshape_first_layer;
reg  [12:0] delivery_sram_group_idx_available;
reg  [12:0] delivery_sram_group_idx_fetched;
reg         delivery_first_layer;
reg  [31:0] saturation_num_perlayer;

// Signals from stripe info
wire        stripe_end;
wire        channel_end;
wire        layer_end;

// Precision and mode
wire [1:0]  precision;
wire        conv_mode;
wire [4:0]  clip_truncate;

// atom_per_mac_cell calculation
wire [4:0]  atom_per_mac_cell;
assign atom_per_mac_cell = (conv_mode == CONV_MODE_WINOGAD) ? 5'd4 : 5'd1;

// round_stride_accu
wire [7:0]  round_stride_accu;
assign round_stride_accu = MAC_CELL_NUM;  // Same for all precisions

//===============================================================
// MAC data concatenation (from two half-MAC units)
//===============================================================
// This concatenates data from MAC_A and MAC_B to form complete
// MAC results. Each MAC cell provides partial results.

// MAC A data array
wire [175:0] mac_a_data [0:7];
assign mac_a_data[0] = mac_a2accu_data0;
assign mac_a_data[1] = mac_a2accu_data1;
assign mac_a_data[2] = mac_a2accu_data2;
assign mac_a_data[3] = mac_a2accu_data3;
assign mac_a_data[4] = mac_a2accu_data4;
assign mac_a_data[5] = mac_a2accu_data5;
assign mac_a_data[6] = mac_a2accu_data6;
assign mac_a_data[7] = mac_a2accu_data7;

// MAC B data array
wire [175:0] mac_b_data [0:7];
assign mac_b_data[0] = mac_b2accu_data0;
assign mac_b_data[1] = mac_b2accu_data1;
assign mac_b_data[2] = mac_b2accu_data2;
assign mac_b_data[3] = mac_b2accu_data3;
assign mac_b_data[4] = mac_b2accu_data4;
assign mac_b_data[5] = mac_b2accu_data5;
assign mac_b_data[6] = mac_b2accu_data6;
assign mac_b_data[7] = mac_b2accu_data7;

// Register inputs
reg [1:0] precision_q;
reg conv_mode_q;
reg [4:0] clip_truncate_q;
reg reg2dp_op_en_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    precision_q <= DATA_FORMAT_INT16;
    conv_mode_q <= CONV_MODE_DIRECT;
    clip_truncate_q <= 5'b0;
    reg2dp_op_en_q <= 1'b0;
  end else begin
    precision_q <= reg2dp_proc_precision;
    conv_mode_q <= reg2dp_conv_mode;
    clip_truncate_q <= reg2dp_clip_truncate;
    reg2dp_op_en_q <= reg2dp_op_en;
  end
end

assign precision = precision_q;
assign conv_mode = conv_mode_q;
assign clip_truncate = clip_truncate_q;

//===============================================================
// Assembly buffer write logic
//===============================================================
// When MAC data arrives, we write to assembly buffer
// and optionally accumulate if there's existing data

reg [4:0] abuf_wr_addr_q;
reg [7:0] abuf_wr_en_q;
reg [767:0] abuf_wr_data_0_q;
reg [767:0] abuf_wr_data_1_q;
reg [767:0] abuf_wr_data_2_q;
reg [767:0] abuf_wr_data_3_q;
reg [543:0] abuf_wr_data_4_q;
reg [543:0] abuf_wr_data_5_q;
reg [543:0] abuf_wr_data_6_q;
reg [543:0] abuf_wr_data_7_q;

assign abuf_wr_addr = abuf_wr_addr_q;
assign abuf_wr_en = abuf_wr_en_q;
assign abuf_wr_data_0 = abuf_wr_data_0_q;
assign abuf_wr_data_1 = abuf_wr_data_1_q;
assign abuf_wr_data_2 = abuf_wr_data_2_q;
assign abuf_wr_data_3 = abuf_wr_data_3_q;
assign abuf_wr_data_4 = abuf_wr_data_4_q;
assign abuf_wr_data_5 = abuf_wr_data_5_q;
assign abuf_wr_data_6 = abuf_wr_data_6_q;
assign abuf_wr_data_7 = abuf_wr_data_7_q;

// MAC valid signals registered
reg mac_a_pvld_q;
reg mac_b_pvld_q;
reg [8:0] mac_a_pd_q;
reg [8:0] mac_b_pd_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mac_a_pvld_q <= 1'b0;
    mac_b_pvld_q <= 1'b0;
    mac_a_pd_q <= 9'b0;
    mac_b_pd_q <= 9'b0;
  end else begin
    mac_a_pvld_q <= mac_a2accu_pvld;
    mac_b_pvld_q <= mac_b2accu_pvld;
    mac_a_pd_q <= mac_a2accu_pd;
    mac_b_pd_q <= mac_b2accu_pd;
  end
end

assign stripe_end = mac_a_pd_q[0];  // stripe_end from pd
assign channel_end = mac_a_pd_q[1];  // channel_end from pd
assign layer_end = mac_a_pd_q[2];   // layer_end from pd

//===============================================================
// Assembly write address calculation
//===============================================================
// Each MAC cell contributes multiple elements per atom
// For INT8: 2 elements per MAC cell per atom
// For INT16/FP16: 1 element per MAC cell per atom

wire [7:0] atom_iter;
wire [7:0] mac_cell_iter;
wire [7:0] kernel_iter;

always @(*) begin
  abuf_wr_en_q = 8'b0;
  abuf_wr_addr_q = 5'b0;
  abuf_wr_data_0_q = {768{1'b0}};
  abuf_wr_data_1_q = {768{1'b0}};
  abuf_wr_data_2_q = {768{1'b0}};
  abuf_wr_data_3_q = {768{1'b0}};
  abuf_wr_data_4_q = {544{1'b0}};
  abuf_wr_data_5_q = {544{1'b0}};
  abuf_wr_data_6_q = {544{1'b0}};
  abuf_wr_data_7_q = {544{1'b0}};

  if (mac_a_pvld_q && mac_b_pvld_q && is_assembly_working) begin
    // Calculate write address based on precision
    if (precision_q == DATA_FORMAT_INT8) begin
      // INT8: 2 elements per atom
      abuf_wr_addr_q = assembly_sram_group_idx_working[4:0];
    end else begin
      // INT16/FP16: 1 element per atom
      abuf_wr_addr_q = assembly_sram_group_idx_working[4:0];
    end
  end
end

//===============================================================
// Assembly buffer read logic (for reshape)
//===============================================================
reg [4:0] abuf_rd_addr_q;
reg [7:0] abuf_rd_en_q;

assign abuf_rd_addr = abuf_rd_addr_q;
assign abuf_rd_en = abuf_rd_en_q;

//===============================================================
// Reshape logic - truncation and saturation
//===============================================================
// This reads from assembly buffer and writes to delivery buffer
// with appropriate truncation/saturation

reg [4:0] dbuf_wr_addr_q;
reg [7:0] dbuf_wr_en_q;
reg [511:0] dbuf_wr_data_0_q;
reg [511:0] dbuf_wr_data_1_q;
reg [511:0] dbuf_wr_data_2_q;
reg [511:0] dbuf_wr_data_3_q;
reg [511:0] dbuf_wr_data_4_q;
reg [511:0] dbuf_wr_data_5_q;
reg [511:0] dbuf_wr_data_6_q;
reg [511:0] dbuf_wr_data_7_q;

assign dbuf_wr_addr_0 = dbuf_wr_addr_q;
assign dbuf_wr_addr_1 = dbuf_wr_addr_q;
assign dbuf_wr_addr_2 = dbuf_wr_addr_q;
assign dbuf_wr_addr_3 = dbuf_wr_addr_q;
assign dbuf_wr_addr_4 = dbuf_wr_addr_q;
assign dbuf_wr_addr_5 = dbuf_wr_addr_q;
assign dbuf_wr_addr_6 = dbuf_wr_addr_q;
assign dbuf_wr_addr_7 = dbuf_wr_addr_q;
assign dbuf_wr_en = dbuf_wr_en_q;
assign dbuf_wr_data_0 = dbuf_wr_data_0_q;
assign dbuf_wr_data_1 = dbuf_wr_data_1_q;
assign dbuf_wr_data_2 = dbuf_wr_data_2_q;
assign dbuf_wr_data_3 = dbuf_wr_data_3_q;
assign dbuf_wr_data_4 = dbuf_wr_data_4_q;
assign dbuf_wr_data_5 = dbuf_wr_data_5_q;
assign dbuf_wr_data_6 = dbuf_wr_data_6_q;
assign dbuf_wr_data_7 = dbuf_wr_data_7_q;

//===============================================================
// Assembly index management
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    assembly_sram_group_idx_working <= 13'b0;
    assembly_sram_group_idx_available <= 13'b0;
    assembly_sram_group_idx_fetched <= 13'b0;
    is_assembly_working <= 1'b0;
    has_ongoing_channel_operation <= 1'b0;
    saved_assembly_sram_group_idx_working <= 13'b0;
    reshape_first_layer <= 1'b1;
    delivery_first_layer <= 1'b1;
    delivery_sram_group_idx_available <= 13'b0;
    delivery_sram_group_idx_fetched <= 13'b0;
    saturation_num_perlayer <= 32'b0;
  end else begin
    // Op enable detection - rising edge
    if (reg2dp_op_en && ~reg2dp_op_en_q) begin
      // Layer starting - initialize indices
      is_assembly_working <= 1'b1;
      reshape_first_layer <= 1'b1;
      delivery_first_layer <= 1'b1;
      saturation_num_perlayer <= 32'b0;

      if (precision_q == DATA_FORMAT_INT8) begin
        assembly_sram_group_idx_available <= -13'd2 * atom_per_mac_cell;
        assembly_sram_group_idx_fetched <= -13'd2 * atom_per_mac_cell;
        delivery_sram_group_idx_available <= -13'd2 * atom_per_mac_cell;
        delivery_sram_group_idx_fetched <= -13'd2 * atom_per_mac_cell;
      end else begin
        assembly_sram_group_idx_available <= -13'd1 * atom_per_mac_cell;
        assembly_sram_group_idx_fetched <= -13'd1 * atom_per_mac_cell;
        delivery_sram_group_idx_available <= -13'd1 * atom_per_mac_cell;
        delivery_sram_group_idx_fetched <= -13'd1 * atom_per_mac_cell;
      end
    end

    // Channel end - update available index
    if (channel_end && mac_a_pvld_q) begin
      assembly_sram_group_idx_available <= assembly_sram_group_idx_working;

      if (precision_q == DATA_FORMAT_INT8) begin
        assembly_sram_group_idx_working <= assembly_sram_group_idx_working + 13'd2 * atom_per_mac_cell;
      end else begin
        assembly_sram_group_idx_working <= assembly_sram_group_idx_working + atom_per_mac_cell;
      end

      if (stripe_end) begin
        has_ongoing_channel_operation <= 1'b0;
      end else begin
        has_ongoing_channel_operation <= 1'b1;
      end
    end

    // Stripe end but not channel end
    if (stripe_end && ~channel_end && mac_a_pvld_q) begin
      if (precision_q == DATA_FORMAT_INT8) begin
        assembly_sram_group_idx_working <= assembly_sram_group_idx_available + 13'd2 * atom_per_mac_cell;
      end else begin
        assembly_sram_group_idx_working <= assembly_sram_group_idx_available + atom_per_mac_cell;
      end
      has_ongoing_channel_operation <= 1'b1;
    end

    // Layer end
    if (layer_end && stripe_end && mac_a_pvld_q) begin
      is_assembly_working <= 1'b0;
      saved_assembly_sram_group_idx_working <= assembly_sram_group_idx_working;
    end
  end
end

//===============================================================
// Reshape state machine
//===============================================================
reg reshape_running;
reg [12:0] reshape_atom_count;
reg [12:0] reshape_mac_cell_iter;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reshape_running <= 1'b0;
    reshape_atom_count <= 13'b0;
    reshape_mac_cell_iter <= 13'b0;
  end else begin
    // Reshape starts when assembly has data available
    if (is_assembly_working && (assembly_sram_group_idx_available > assembly_sram_group_idx_fetched)) begin
      reshape_running <= 1'b1;
    end else if (reshape_atom_count >= MAC_CELL_NUM) begin
      reshape_running <= 1'b0;
      reshape_atom_count <= 13'b0;
    end
  end
end

//===============================================================
// Delivery done and saturation count
//===============================================================
reg dp2reg_done_q;

assign dp2reg_done = dp2reg_done_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_done_q <= 1'b0;
    dp2reg_sat_count <= 32'b0;
  end else begin
    // Done is asserted when layer ends and reshape is complete
    if (layer_end && stripe_end && mac_a_pvld_q && ~is_assembly_working) begin
      dp2reg_done_q <= 1'b1;
      dp2reg_sat_count <= saturation_num_perlayer;
    end else begin
      dp2reg_done_q <= 1'b0;
    end
  end
end

endmodule // NV_NVDLA_CACC_calc_new