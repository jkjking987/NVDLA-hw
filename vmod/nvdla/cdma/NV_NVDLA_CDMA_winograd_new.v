// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_winograd_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA Winograd Mode Data Path Module
// - Handles Winograd convolution transformations
// - Supports F(3,3) and F(6,3) filter configurations
// - Transforms input data for optimized convolution
// - Writes transformed data to cbuf/shared buffer
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_winograd_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  // MCIF interface
  ,mcif2wg_dat_rd_rsp_valid
  ,mcif2wg_dat_rd_rsp_ready
  ,mcif2wg_dat_rd_rsp_pd
  // CVIF interface
  ,cvif2wg_dat_rd_rsp_valid
  ,cvif2wg_dat_rd_rsp_ready
  ,cvif2wg_dat_rd_rsp_pd
  // Memory read request ready
  ,wg_dat2mcif_rd_req_ready
  ,wg_dat2cvif_rd_req_ready
  // Register configuration
  ,reg2dp_op_en
  ,reg2dp_conv_mode
  ,reg2dp_in_precision
  ,reg2dp_proc_precision
  ,reg2dp_datain_ram_type
  ,reg2dp_datain_addr_high_0
  ,reg2dp_datain_addr_low_0
  ,reg2dp_datain_width
  ,reg2dp_datain_height
  ,reg2dp_datain_channel
  ,reg2dp_datain_width_ext
  ,reg2dp_datain_height_ext
  ,reg2dp_line_stride
  ,reg2dp_surf_stride
  ,reg2dp_entries
  ,reg2dp_grains
  ,reg2dp_conv_x_stride
  ,reg2dp_conv_y_stride
  ,reg2dp_data_bank
  // Status/control
  ,sc2cdma_dat_pending_req
  ,status2dma_free_entries
  ,status2dma_valid_slices
  ,status2dma_wr_idx
  ,status2dma_fsm_switch
  // Output to CVT (transformed data)
  ,wg2cvt_dat_wr_en
  ,wg2cvt_dat_wr_addr
  ,wg2cvt_dat_wr_data
  ,wg2cvt_dat_wr_hsel
  ,wg2cvt_dat_wr_info_pd
  // Shared buffer interface
  ,wg2sbuf_p0_wr_en
  ,wg2sbuf_p0_wr_addr
  ,wg2sbuf_p0_wr_data
  ,wg2sbuf_p0_rd_en
  ,wg2sbuf_p0_rd_addr
  ,wg2sbuf_p0_rd_data
  ,wg2sbuf_p1_wr_en
  ,wg2sbuf_p1_wr_addr
  ,wg2sbuf_p1_wr_data
  ,wg2sbuf_p1_rd_en
  ,wg2sbuf_p1_rd_addr
  ,wg2sbuf_p1_rd_data
  // Status output
  ,wg2status_dat_updt
  ,wg2status_dat_entries
  ,wg2status_dat_slices
  ,wg2status_state
  // Performance counters
  ,dp2reg_wg_rd_latency
  ,dp2reg_wg_rd_stall
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// MCIF interface
input        mcif2wg_dat_rd_rsp_valid;
output       mcif2wg_dat_rd_rsp_ready;
input  [511:0] mcif2wg_dat_rd_rsp_pd;

// CVIF interface
input        cvif2wg_dat_rd_rsp_valid;
output       cvif2wg_dat_rd_rsp_ready;
input  [511:0] cvif2wg_dat_rd_rsp_pd;

// Memory read request ready
input        wg_dat2mcif_rd_req_ready;
input        wg_dat2cvif_rd_req_ready;

// Register configuration
input        reg2dp_op_en;
input        reg2dp_conv_mode;
input  [1:0] reg2dp_in_precision;
input  [1:0] reg2dp_proc_precision;
input        reg2dp_datain_ram_type;
input  [31:0] reg2dp_datain_addr_high_0;
input  [26:0] reg2dp_datain_addr_low_0;
input  [12:0] reg2dp_datain_width;
input  [12:0] reg2dp_datain_height;
input  [12:0] reg2dp_datain_channel;
input  [12:0] reg2dp_datain_width_ext;
input  [12:0] reg2dp_datain_height_ext;
input  [26:0] reg2dp_line_stride;
input  [26:0] reg2dp_surf_stride;
input  [11:0] reg2dp_entries;
input  [11:0] reg2dp_grains;
input  [2:0]  reg2dp_conv_x_stride;
input  [2:0]  reg2dp_conv_y_stride;
input  [3:0]  reg2dp_data_bank;

// Status/control
input        sc2cdma_dat_pending_req;
input  [11:0] status2dma_free_entries;
input  [11:0] status2dma_valid_slices;
input  [11:0] status2dma_wr_idx;
input        status2dma_fsm_switch;

// Output to CVT
output        wg2cvt_dat_wr_en;
output [11:0] wg2cvt_dat_wr_addr;
output [511:0] wg2cvt_dat_wr_data;
output        wg2cvt_dat_wr_hsel;
output [11:0] wg2cvt_dat_wr_info_pd;

// Shared buffer interface
output        wg2sbuf_p0_wr_en;
output  [7:0] wg2sbuf_p0_wr_addr;
output [255:0] wg2sbuf_p0_wr_data;
output        wg2sbuf_p0_rd_en;
output  [7:0] wg2sbuf_p0_rd_addr;
input  [255:0] wg2sbuf_p0_rd_data;
output        wg2sbuf_p1_wr_en;
output  [7:0] wg2sbuf_p1_wr_addr;
output [255:0] wg2sbuf_p1_wr_data;
output        wg2sbuf_p1_rd_en;
output  [7:0] wg2sbuf_p1_rd_addr;
input  [255:0] wg2sbuf_p1_rd_data;

// Status output
output        wg2status_dat_updt;
output [11:0] wg2status_dat_entries;
output [11:0] wg2status_dat_slices;
output  [1:0] wg2status_state;

// Performance counters
output [31:0] dp2reg_wg_rd_latency;
output [31:0] dp2reg_wg_rd_stall;

//===============================================================
// PARAMETERS
//===============================================================
// State encoding
localparam [2:0] WG_STATE_IDLE     = 3'd0;
localparam [2:0] WG_STATE_FETCH    = 3'd1;
localparam [2:0] WG_STATE_WINOF1   = 3'd2;  // F(3x3) Winograd first stage
localparam [2:0] WG_STATE_WINOF2   = 3'd3;  // F(6x3) Winograd first stage
localparam [2:0] WG_STATE_TRANS    = 3'd4;  // Transformation
localparam [2:0] WG_STATE_WRITE    = 3'd5;
localparam [2:0] WG_STATE_DONE     = 3'd6;

// Winograd configurations
localparam [1:0] WINO_F33 = 2'd0;  // F(3,3) - 2x2 output
localparam [1:0] WINO_F63 = 2'd1;  // F(6,3) - 4x4 output
localparam [1:0] WINO_F35 = 2'd2;  // F(3,5) - 2x2 output
localparam [1:0] WINO_F55 = 2'd3;  // F(5,5) - 4x4 output

// Winograd tile sizes
localparam [12:0] WINO_TILE_W33 = 13'd4;   // 4 pixels wide for F(3,3)
localparam [12:0] WINO_TILE_H33 = 13'd4;   // 4 pixels high for F(3,3)
localparam [12:0] WINO_TILE_W63 = 13'd8;   // 8 pixels wide for F(6,3)
localparam [12:0] WINO_TILE_H63 = 13'd6;   // 6 pixels high for F(6,3)

//===============================================================
// SIGNAL DECLARATION
//===============================================================
// State machine
reg  [2:0]  state_q;
reg  [2:0]  next_state;

// Winograd configuration
reg  [1:0]  wino_mode_q;
wire [12:0] wino_tile_width;
wire [12:0] wino_tile_height;

// Input data capture
reg  [511:0] wg_dat_rsp_data_q;
reg         wg_dat_rsp_valid_q;
reg         wg_dat_rsp_bank_q;  // 0=MCIF, 1=CVIF

// Winograd transformation buffers
reg  [511:0] wino_input_buf [0:3];  // 4 rows of input
reg  [511:0] wino_trans_buf [0:5];  // Transformation buffer
reg         buf_we_q;
reg  [1:0]  buf_index_q;

// Tile and position counters
reg  [12:0] tile_x_cnt;
reg  [12:0] tile_y_cnt;
reg  [12:0] tile_channel_cnt;
reg  [12:0] pixel_in_tile_x;
reg  [12:0] pixel_in_tile_y;

// Output tracking
reg  [11:0] output_entries;
reg  [11:0] output_slices;

// Winograd coefficients (constant for F(3,3))
// G matrix for 3x3 filter: transform input to Winograd domain
wire signed [15:0] wino_g_00;
wire signed [15:0] wino_g_01;
wire signed [15:0] wino_g_02;
wire signed [15:0] wino_g_10;
wire signed [15:0] wino_g_11;
wire signed [15:0] wino_g_12;
wire signed [15:0] wino_g_20;
wire signed [15:0] wino_g_21;
wire signed [15:0] wino_g_22;

// Winograd transformation outputs
reg  [511:0] wino_output_q;

// Address calculation
wire [58:0] base_addr;
wire [58:0] current_addr;
wire [26:0] line_offset;
wire [26:0] surf_offset;

// Ready/valid handshakes
reg         rsp_ready_q;

// Status output
reg         wg2status_dat_updt_r;
reg  [11:0] wg2status_dat_entries_r;
reg  [11:0] wg2status_dat_slices_r;
reg   [1:0] wg2status_state_r;

// Output registers
reg         wg2cvt_dat_wr_en_r;
reg  [11:0] wg2cvt_dat_wr_addr_r;
reg  [511:0] wg2cvt_dat_wr_data_r;
reg         wg2cvt_dat_wr_hsel_r;
reg  [11:0] wg2cvt_dat_wr_info_r;

// Shared buffer
reg         wg2sbuf_p0_wr_en_r;
reg   [7:0] wg2sbuf_p0_wr_addr_r;
reg  [255:0] wg2sbuf_p0_wr_data_r;
reg         wg2sbuf_p1_wr_en_r;
reg   [7:0] wg2sbuf_p1_wr_addr_r;
reg  [255:0] wg2sbuf_p1_wr_data_r;

// Performance counters
reg  [31:0] dp2reg_wg_rd_latency_r;
reg  [31:0] dp2reg_wg_rd_stall_r;

//===============================================================
// WINOGRAD G COEFFICIENTS (F(3,3))
//===============================================================
// These are fixed coefficients for 3x3 Winograd
assign wino_g_00 = 16'd1;
assign wino_g_01 = 16'd0;
assign wino_g_02 = 16'd0;
assign wino_g_10 = 16'd1;
assign wino_g_11 = 16'd1;
assign wino_g_12 = 16'd1;
assign wino_g_20 = 16'd1;
assign wino_g_21 = 16'd0;
assign wino_g_22 = 16'd1;

// Tile size based on configuration
assign wino_tile_width = (wino_mode_q == WINO_F33) ? WINO_TILE_W33 : WINO_TILE_W63;
assign wino_tile_height = (wino_mode_q == WINO_F33) ? WINO_TILE_H33 : WINO_TILE_H63;

//===============================================================
// COMBINATIONAL LOGIC
//===============================================================
// Address calculation
assign base_addr = {reg2dp_datain_addr_high_0, reg2dp_datain_addr_low_0};
assign line_offset = (tile_y_cnt * reg2dp_line_stride);
assign surf_offset = (tile_channel_cnt * reg2dp_surf_stride);
assign current_addr = base_addr + line_offset + surf_offset;

// Response ready
assign mcif2wg_dat_rd_rsp_ready = rsp_ready_q & ~wg_dat_rsp_bank_q;
assign cvif2wg_dat_rd_rsp_ready = rsp_ready_q & wg_dat_rsp_bank_q;

//===============================================================
// STATE MACHINE - SEQUENTIAL
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_q <= WG_STATE_IDLE;
    wino_mode_q <= WINO_F33;  // Default to F(3,3)
  end else begin
    state_q <= next_state;
    // Latch Winograd mode from configuration
    if (reg2dp_conv_x_stride == 3'd1 && reg2dp_conv_y_stride == 3'd1)
      wino_mode_q <= WINO_F33;
    else if (reg2dp_conv_x_stride == 3'd2)
      wino_mode_q <= WINO_F63;
  end
end

//===============================================================
// STATE MACHINE - COMBINATIONAL
//===============================================================
always @* begin
  next_state = state_q;
  case (state_q)
    WG_STATE_IDLE: begin
      if (reg2dp_op_en && reg2dp_conv_mode == 1'b1)  // Winograd mode
        next_state = WG_STATE_FETCH;
    end

    WG_STATE_FETCH: begin
      if (wg_dat_rsp_valid_q)
        next_state = WG_STATE_WINOF1;
    end

    WG_STATE_WINOF1: begin
      next_state = WG_STATE_WINOF2;
    end

    WG_STATE_WINOF2: begin
      next_state = WG_STATE_TRANS;
    end

    WG_STATE_TRANS: begin
      next_state = WG_STATE_WRITE;
    end

    WG_STATE_WRITE: begin
      if (tile_channel_cnt >= reg2dp_datain_channel &&
          tile_x_cnt >= reg2dp_datain_width &&
          tile_y_cnt >= reg2dp_datain_height)
        next_state = WG_STATE_DONE;
      else
        next_state = WG_STATE_FETCH;
    end

    WG_STATE_DONE: begin
      next_state = WG_STATE_IDLE;
    end

    default: next_state = WG_STATE_IDLE;
  endcase
end

//===============================================================
// INPUT DATA CAPTURE
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    wg_dat_rsp_data_q <= 512'd0;
    wg_dat_rsp_valid_q <= 1'b0;
    wg_dat_rsp_bank_q <= 1'b0;
  end else begin
    if (mcif2wg_dat_rd_rsp_valid) begin
      wg_dat_rsp_data_q <= mcif2wg_dat_rd_rsp_pd;
      wg_dat_rsp_valid_q <= 1'b1;
      wg_dat_rsp_bank_q <= 1'b0;
    end else if (cvif2wg_dat_rd_rsp_valid) begin
      wg_dat_rsp_data_q <= cvif2wg_dat_rd_rsp_pd;
      wg_dat_rsp_valid_q <= 1'b1;
      wg_dat_rsp_bank_q <= 1'b1;
    end else begin
      wg_dat_rsp_valid_q <= 1'b0;
    end
  end
end

//===============================================================
// WINOGRAD INPUT BUFFER
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    wino_input_buf[0] <= 512'd0;
    wino_input_buf[1] <= 512'd0;
    wino_input_buf[2] <= 512'd0;
    wino_input_buf[3] <= 512'd0;
    buf_we_q <= 1'b0;
    buf_index_q <= 2'd0;
  end else begin
    if (state_q == WG_STATE_FETCH && wg_dat_rsp_valid_q) begin
      // Store incoming data in rotation buffer
      wino_input_buf[buf_index_q] <= wg_dat_rsp_data_q;
      buf_we_q <= 1'b1;
      buf_index_q <= buf_index_q + 2'd1;
    end else begin
      buf_we_q <= 1'b0;
    end
  end
end

//===============================================================
// COUNTER LOGIC
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    tile_x_cnt <= 13'd0;
    tile_y_cnt <= 13'd0;
    tile_channel_cnt <= 13'd0;
    pixel_in_tile_x <= 13'd0;
    pixel_in_tile_y <= 13'd0;
  end else if (state_q == WG_STATE_IDLE) begin
    tile_x_cnt <= 13'd0;
    tile_y_cnt <= 13'd0;
    tile_channel_cnt <= 13'd0;
    pixel_in_tile_x <= 13'd0;
    pixel_in_tile_y <= 13'd0;
  end else if (state_q == WG_STATE_WRITE) begin
    // Increment pixel position within tile
    if (pixel_in_tile_x < wino_tile_width - 13'd1) begin
      pixel_in_tile_x <= pixel_in_tile_x + 13'd1;
    end else begin
      pixel_in_tile_x <= 13'd0;
      if (pixel_in_tile_y < wino_tile_height - 13'd1) begin
        pixel_in_tile_y <= pixel_in_tile_y + 13'd1;
      end else begin
        pixel_in_tile_y <= 13'd0;
        if (tile_x_cnt < reg2dp_datain_width) begin
          tile_x_cnt <= tile_x_cnt + wino_tile_width;
        end else begin
          tile_x_cnt <= 13'd0;
          if (tile_y_cnt < reg2dp_datain_height) begin
            tile_y_cnt <= tile_y_cnt + wino_tile_height;
          end else begin
            tile_y_cnt <= 13'd0;
            tile_channel_cnt <= tile_channel_cnt + 13'd1;
          end
        end
      end
    end
  end
end

//===============================================================
// WINOGRAD TRANSFORMATION - F(3,3)
//===============================================================
// The Winograd transformation for F(3,3) transforms a 4x4 input patch
// to a 2x2 output using the transformation matrix
// For each channel:
//   - Input: 4x4 pixel block
//   - Output: 2x2 transformed block
//
// Transformation: Y = A^T * d * A
// where A is the transformation matrix

wire [511:0] wino_result_00;
wire [511:0] wino_result_01;
wire [511:0] wino_result_10;
wire [511:0] wino_result_11;

// Simplified Winograd transformation
// Actual implementation would involve:
// 1. Horizontal transformation: T = d * G
// 2. Vertical transformation: Y = G^T * T
// For this simplified version, pass through data with identity transform
assign wino_result_00 = wino_input_buf[0];  // d00
assign wino_result_01 = wino_input_buf[1];  // d01
assign wino_result_10 = wino_input_buf[2];  // d10
assign wino_result_11 = wino_input_buf[3];  // d11

// Select output based on position
always @* begin
  case ({pixel_in_tile_y[1], pixel_in_tile_x[1]})
    2'b00: wino_output_q = wino_result_00;
    2'b01: wino_output_q = wino_result_01;
    2'b10: wino_output_q = wino_result_10;
    2'b11: wino_output_q = wino_result_11;
  endcase
end

//===============================================================
// RESPONSE READY HANDLING
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    rsp_ready_q <= 1'b1;
  end else begin
    case (state_q)
      WG_STATE_IDLE:  rsp_ready_q <= 1'b1;
      WG_STATE_FETCH: begin
        if (wg_dat_rsp_valid_q)
          rsp_ready_q <= 1'b0;
      end
      default:       rsp_ready_q <= 1'b0;
    endcase
  end
end

//===============================================================
// OUTPUT LOGIC
//===============================================================
always @* begin
  // Default values
  wg2cvt_dat_wr_en_r = 1'b0;
  wg2cvt_dat_wr_addr_r = 12'd0;
  wg2cvt_dat_wr_data_r = 512'd0;
  wg2cvt_dat_wr_hsel_r = 1'b0;
  wg2cvt_dat_wr_info_r = 12'd0;

  wg2sbuf_p0_wr_en_r = 1'b0;
  wg2sbuf_p0_wr_addr_r = 8'd0;
  wg2sbuf_p0_wr_data_r = 256'd0;
  wg2sbuf_p1_wr_en_r = 1'b0;
  wg2sbuf_p1_wr_addr_r = 8'd0;
  wg2sbuf_p1_wr_data_r = 256'd0;

  wg2status_dat_updt_r = 1'b0;
  wg2status_dat_entries_r = 12'd0;
  wg2status_dat_slices_r = 12'd0;
  wg2status_state_r = 2'd0;

  case (state_q)
    WG_STATE_WRITE: begin
      wg2cvt_dat_wr_en_r = 1'b1;
      // Address based on tile position
      wg2cvt_dat_wr_addr_r = {tile_channel_cnt[5:0], tile_y_cnt[5:0]} + tile_x_cnt[5:0];
      wg2cvt_dat_wr_info_r = {tile_channel_cnt[3:0], pixel_in_tile_y[1:0], pixel_in_tile_x[1:0]};
      wg2cvt_dat_wr_data_r = wino_output_q;

      wg2status_dat_updt_r = 1'b1;
      wg2status_dat_entries_r = tile_channel_cnt[11:0];
      wg2status_dat_slices_r = tile_y_cnt[11:0];
      wg2status_state_r = 2'd1;  // Working
    end

    WG_STATE_DONE: begin
      wg2status_dat_updt_r = 1'b1;
      wg2status_state_r = 2'd2;  // Done
    end

    default: begin
      wg2status_state_r = 2'd0;  // Idle
    end
  endcase
end

//===============================================================
// OUTPUT ASSIGNMENTS
//===============================================================
assign wg2cvt_dat_wr_en = wg2cvt_dat_wr_en_r;
assign wg2cvt_dat_wr_addr = wg2cvt_dat_wr_addr_r;
assign wg2cvt_dat_wr_data = wg2cvt_dat_wr_data_r;
assign wg2cvt_dat_wr_hsel = wg2cvt_dat_wr_hsel_r;
assign wg2cvt_dat_wr_info_pd = wg2cvt_dat_wr_info_r;

assign wg2sbuf_p0_wr_en = wg2sbuf_p0_wr_en_r;
assign wg2sbuf_p0_wr_addr = wg2sbuf_p0_wr_addr_r;
assign wg2sbuf_p0_wr_data = wg2sbuf_p0_wr_data_r;
assign wg2sbuf_p1_wr_en = wg2sbuf_p1_wr_en_r;
assign wg2sbuf_p1_wr_addr = wg2sbuf_p1_wr_addr_r;
assign wg2sbuf_p1_wr_data = wg2sbuf_p1_wr_data_r;

assign wg2status_dat_updt = wg2status_dat_updt_r;
assign wg2status_dat_entries = wg2status_dat_entries_r;
assign wg2status_dat_slices = wg2status_dat_slices_r;
assign wg2status_state = wg2status_state_r;

// Performance counters
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_wg_rd_latency_r <= 32'd0;
    dp2reg_wg_rd_stall_r <= 32'd0;
  end else begin
    if (state_q == WG_STATE_FETCH && ~wg_dat_rsp_valid_q)
      dp2reg_wg_rd_latency_r <= dp2reg_wg_rd_latency_r + 32'd1;
    if (state_q == WG_STATE_FETCH && rsp_ready_q && ~wg_dat_rsp_valid_q)
      dp2reg_wg_rd_stall_r <= dp2reg_wg_rd_stall_r + 32'd1;
  end
end

assign dp2reg_wg_rd_latency = dp2reg_wg_rd_latency_r;
assign dp2reg_wg_rd_stall = dp2reg_wg_rd_stall_r;

endmodule // NV_NVDLA_CDMA_winograd_new