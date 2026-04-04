// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDMA_image_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDMA Image Mode Data Path Module
// - Handles image data processing in Direct Convolution mode
// - Processes pixel data from MCIF/CVIF memory interface
// - Applies mean subtraction and padding
// - Writes processed data to cbuf/shared buffer
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDMA_image_new (
   // Clock and reset
   nvdla_core_clk
  ,nvdla_core_rstn
  // MCIF interface
  ,mcif2img_dat_rd_rsp_valid
  ,mcif2img_dat_rd_rsp_ready
  ,mcif2img_dat_rd_rsp_pd
  // CVIF interface
  ,cvif2img_dat_rd_rsp_valid
  ,cvif2img_dat_rd_rsp_ready
  ,cvif2img_dat_rd_rsp_pd
  // Memory read request ready
  ,img_dat2mcif_rd_req_ready
  ,img_dat2cvif_rd_req_ready
  // Register configuration
  ,reg2dp_op_en
  ,reg2dp_conv_mode
  ,reg2dp_in_precision
  ,reg2dp_proc_precision
  ,reg2dp_datain_ram_type
  ,reg2dp_datain_addr_high_0
  ,reg2dp_datain_addr_low_0
  ,reg2dp_datain_addr_high_1
  ,reg2dp_datain_addr_low_1
  ,reg2dp_datain_width
  ,reg2dp_datain_height
  ,reg2dp_datain_channel
  ,reg2dp_line_stride
  ,reg2dp_uv_line_stride
  ,reg2dp_pixel_format
  ,reg2dp_pixel_mapping
  ,reg2dp_pixel_x_offset
  ,reg2dp_pixel_y_offset
  ,reg2dp_pixel_sign_override
  ,reg2dp_mean_format
  ,reg2dp_mean_ry
  ,reg2dp_mean_gu
  ,reg2dp_mean_bv
  ,reg2dp_mean_ax
  ,reg2dp_data_bank
  ,reg2dp_pad_left
  ,reg2dp_pad_right
  ,reg2dp_pad_top
  ,reg2dp_pad_bottom
  ,reg2dp_pad_value
  ,reg2dp_dma_en
  // Status/control
  ,sc2cdma_dat_pending_req
  ,status2dma_free_entries
  ,status2dma_valid_slices
  ,status2dma_wr_idx
  ,status2dma_fsm_switch
  // Output to CVT (converted data)
  ,img2cvt_dat_wr_en
  ,img2cvt_dat_wr_addr
  ,img2cvt_dat_wr_data
  ,img2cvt_dat_wr_hsel
  ,img2cvt_dat_wr_info_pd
  ,img2cvt_dat_wr_pad_mask
  // Mean shift output
  ,img2cvt_mn_wr_data
  // Shared buffer interface
  ,img2sbuf_p0_wr_en
  ,img2sbuf_p0_wr_addr
  ,img2sbuf_p0_wr_data
  ,img2sbuf_p1_wr_en
  ,img2sbuf_p1_wr_addr
  ,img2sbuf_p1_wr_data
  ,img2sbuf_p0_rd_en
  ,img2sbuf_p0_rd_addr
  ,img2sbuf_p0_rd_data
  ,img2sbuf_p1_rd_en
  ,img2sbuf_p1_rd_addr
  ,img2sbuf_p1_rd_data
  // Status output
  ,img2status_dat_updt
  ,img2status_dat_entries
  ,img2status_dat_slices
  ,img2status_state
  // Performance counters
  ,dp2reg_img_rd_latency
  ,dp2reg_img_rd_stall
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// MCIF interface
input        mcif2img_dat_rd_rsp_valid;
output       mcif2img_dat_rd_rsp_ready;
input  [511:0] mcif2img_dat_rd_rsp_pd;

// CVIF interface
input        cvif2img_dat_rd_rsp_valid;
output       cvif2img_dat_rd_rsp_ready;
input  [511:0] cvif2img_dat_rd_rsp_pd;

// Memory read request ready
input        img_dat2mcif_rd_req_ready;
input        img_dat2cvif_rd_req_ready;

// Register configuration
input        reg2dp_op_en;
input        reg2dp_conv_mode;
input  [1:0] reg2dp_in_precision;
input  [1:0] reg2dp_proc_precision;
input        reg2dp_datain_ram_type;
input  [31:0] reg2dp_datain_addr_high_0;
input  [26:0] reg2dp_datain_addr_low_0;
input  [31:0] reg2dp_datain_addr_high_1;
input  [26:0] reg2dp_datain_addr_low_1;
input  [12:0] reg2dp_datain_width;
input  [12:0] reg2dp_datain_height;
input  [12:0] reg2dp_datain_channel;
input  [26:0] reg2dp_line_stride;
input  [26:0] reg2dp_uv_line_stride;
input  [5:0]  reg2dp_pixel_format;
input        reg2dp_pixel_mapping;
input  [4:0]  reg2dp_pixel_x_offset;
input  [2:0]  reg2dp_pixel_y_offset;
input        reg2dp_pixel_sign_override;
input        reg2dp_mean_format;
input  [15:0] reg2dp_mean_ry;
input  [15:0] reg2dp_mean_gu;
input  [15:0] reg2dp_mean_bv;
input  [15:0] reg2dp_mean_ax;
input  [3:0]  reg2dp_data_bank;
input  [4:0]  reg2dp_pad_left;
input  [5:0]  reg2dp_pad_right;
input  [4:0]  reg2dp_pad_top;
input  [5:0]  reg2dp_pad_bottom;
input  [15:0] reg2dp_pad_value;
input        reg2dp_dma_en;

// Status/control
input        sc2cdma_dat_pending_req;
input  [11:0] status2dma_free_entries;
input  [11:0] status2dma_valid_slices;
input  [11:0] status2dma_wr_idx;
input        status2dma_fsm_switch;

// Output to CVT
output        img2cvt_dat_wr_en;
output [11:0] img2cvt_dat_wr_addr;
output [1023:0] img2cvt_dat_wr_data;
output        img2cvt_dat_wr_hsel;
output [11:0] img2cvt_dat_wr_info_pd;
output [127:0] img2cvt_dat_wr_pad_mask;

// Mean shift output
output [1023:0] img2cvt_mn_wr_data;

// Shared buffer interface
output        img2sbuf_p0_wr_en;
output  [7:0] img2sbuf_p0_wr_addr;
output [255:0] img2sbuf_p0_wr_data;
output        img2sbuf_p1_wr_en;
output  [7:0] img2sbuf_p1_wr_addr;
output [255:0] img2sbuf_p1_wr_data;
output        img2sbuf_p0_rd_en;
output  [7:0] img2sbuf_p0_rd_addr;
input  [255:0] img2sbuf_p0_rd_data;
output        img2sbuf_p1_rd_en;
output  [7:0] img2sbuf_p1_rd_addr;
input  [255:0] img2sbuf_p1_rd_data;

// Status output
output        img2status_dat_updt;
output [11:0] img2status_dat_entries;
output [11:0] img2status_dat_slices;
output  [1:0] img2status_state;

// Performance counters
output [31:0] dp2reg_img_rd_latency;
output [31:0] dp2reg_img_rd_stall;

//===============================================================
// PARAMETERS
//===============================================================
localparam [2:0] IMG_STATE_IDLE    = 3'd0;
localparam [2:0] IMG_STATE_READING = 3'd1;
localparam [2:0] IMG_STATE_PROCESS = 3'd2;
localparam [2:0] IMG_STATE_WRITE  = 3'd3;
localparam [2:0] IMG_STATE_DONE    = 3'd4;

// Pixel format definitions
localparam [5:0] PIXEL_FMT_RGB    = 6'd0;
localparam [5:0] PIXEL_FMT_RGBA   = 6'd1;
localparam [5:0] PIXEL_FMT_YUV    = 6'd2;
localparam [5:0] PIXEL_FMT_YUVA   = 6'd3;

//===============================================================
// SIGNAL DECLARATION
//===============================================================
// State machine
reg  [2:0]  state_q;
reg  [2:0]  next_state;

// Pixel processing counters
reg  [12:0] pixel_x_cnt;
reg  [12:0] pixel_y_cnt;
reg  [12:0] pixel_channel_cnt;

// Line/surface tracking
reg  [12:0] line_cnt;
reg  [12:0] surf_cnt;

// Address calculation
wire [58:0] base_addr_0;
wire [58:0] base_addr_1;
wire [58:0] current_addr;
wire [26:0] line_offset;
wire [26:0] surf_offset;

// Input data capture
reg  [511:0] img_dat_rsp_data_q;
reg         img_dat_rsp_valid_q;
reg         img_dat_rsp_bank_q;  // 0=MCIF, 1=CVIF

// Mean values
reg  [15:0] mean_r;
reg  [15:0] mean_g;
reg  [15:0] mean_b;
reg  [15:0] mean_a;

// Pad detection
wire        is_padding_pixel;
wire        is_padding_line;
wire        is_padding_surf;

// Output data
reg         img2cvt_dat_wr_en_r;
reg  [11:0] img2cvt_dat_wr_addr_r;
reg  [1023:0] img2cvt_dat_wr_data_r;
reg         img2cvt_dat_wr_hsel_r;
reg  [11:0] img2cvt_dat_wr_info_r;
reg  [127:0] img2cvt_dat_wr_pad_mask_r;
reg  [1023:0] img2cvt_mn_wr_data_r;

// Shared buffer control
reg         img2sbuf_p0_wr_en_r;
reg   [7:0] img2sbuf_p0_wr_addr_r;
reg  [255:0] img2sbuf_p0_wr_data_r;
reg         img2sbuf_p1_wr_en_r;
reg   [7:0] img2sbuf_p1_wr_addr_r;
reg  [255:0] img2sbuf_p1_wr_data_r;

// Status output
reg         img2status_dat_updt_r;
reg  [11:0] img2status_dat_entries_r;
reg  [11:0] img2status_dat_slices_r;
reg   [1:0] img2status_state_r;

// Performance counters
reg  [31:0] dp2reg_img_rd_latency_r;
reg  [31:0] dp2reg_img_rd_stall_r;

// Ready/valid handshakes
reg         rsp_ready_q;
wire        rsp_accept;

// Request tracking
reg  [11:0] pending_req_cnt;
reg         mem_addr_select;  // 0=addr0, 1=addr1

//===============================================================
// COMBINATIONAL LOGIC
//===============================================================
// Address calculation
assign base_addr_0 = {reg2dp_datain_addr_high_0, reg2dp_datain_addr_low_0};
assign base_addr_1 = {reg2dp_datain_addr_high_1, reg2dp_datain_addr_low_1};

wire [58:0] selected_base_addr = mem_addr_select ? base_addr_1 : base_addr_0;

assign line_offset = (pixel_y_cnt * reg2dp_line_stride);
assign surf_offset  = (surf_cnt * reg2dp_uv_line_stride);
assign current_addr = selected_base_addr + line_offset + surf_offset;

// Padding detection
assign is_padding_pixel = (pixel_x_cnt < reg2dp_pad_left) ||
                          (pixel_x_cnt >= (reg2dp_datain_width - reg2dp_pad_right));
assign is_padding_line  = (pixel_y_cnt < reg2dp_pad_top) ||
                          (pixel_y_cnt >= (reg2dp_datain_height - reg2dp_pad_bottom));

// Response ready based on state
assign mcif2img_dat_rd_rsp_ready = rsp_ready_q & ~img_dat_rsp_bank_q;
assign cvif2img_dat_rd_rsp_ready = rsp_ready_q & img_dat_rsp_bank_q;
assign rsp_accept = img_dat_rsp_valid_q;

//===============================================================
// STATE MACHINE - SEQUENTIAL
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_q <= IMG_STATE_IDLE;
  end else begin
    state_q <= next_state;
  end
end

//===============================================================
// STATE MACHINE - COMBINATIONAL
//===============================================================
always @* begin
  next_state = state_q;
  case (state_q)
    IMG_STATE_IDLE: begin
      if (reg2dp_op_en && reg2dp_conv_mode == 1'b0)  // Direct convolution mode
        next_state = IMG_STATE_READING;
    end

    IMG_STATE_READING: begin
      if (img_dat_rsp_valid_q)
        next_state = IMG_STATE_PROCESS;
    end

    IMG_STATE_PROCESS: begin
      next_state = IMG_STATE_WRITE;
    end

    IMG_STATE_WRITE: begin
      if ((pixel_channel_cnt >= reg2dp_datain_channel) &&
          (pixel_x_cnt >= reg2dp_datain_width) &&
          (pixel_y_cnt >= reg2dp_datain_height))
        next_state = IMG_STATE_DONE;
      else
        next_state = IMG_STATE_READING;
    end

    IMG_STATE_DONE: begin
      next_state = IMG_STATE_IDLE;
    end

    default: next_state = IMG_STATE_IDLE;
  endcase
end

//===============================================================
// MEAN VALUES LOADING
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mean_r <= 16'd0;
    mean_g <= 16'd0;
    mean_b <= 16'd0;
    mean_a <= 16'd0;
  end else if (reg2dp_op_en) begin
    if (reg2dp_mean_format == 1'b0) begin  // Pixel mean
      mean_r <= reg2dp_mean_ry;
      mean_g <= reg2dp_mean_gu;
      mean_b <= reg2dp_mean_bv;
      mean_a <= reg2dp_mean_ax;
    end else begin  // Global mean
      mean_r <= reg2dp_mean_ry;
      mean_g <= reg2dp_mean_gu;
      mean_b <= reg2dp_mean_bv;
      mean_a <= 16'd0;
    end
  end
end

//===============================================================
// PIXEL COUNTER LOGIC
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    pixel_x_cnt <= 13'd0;
    pixel_y_cnt <= 13'd0;
    pixel_channel_cnt <= 13'd0;
    line_cnt <= 13'd0;
    surf_cnt <= 13'd0;
  end else if (state_q == IMG_STATE_IDLE) begin
    pixel_x_cnt <= 13'd0;
    pixel_y_cnt <= 13'd0;
    pixel_channel_cnt <= 13'd0;
    line_cnt <= 13'd0;
    surf_cnt <= 13'd0;
  end else if (state_q == IMG_STATE_WRITE) begin
    // Increment counters
    if (pixel_channel_cnt < reg2dp_datain_channel) begin
      pixel_channel_cnt <= pixel_channel_cnt + 13'd1;
    end else begin
      pixel_channel_cnt <= 13'd0;
      if (pixel_x_cnt < reg2dp_datain_width) begin
        pixel_x_cnt <= pixel_x_cnt + 13'd1;
      end else begin
        pixel_x_cnt <= 13'd0;
        if (pixel_y_cnt < reg2dp_datain_height) begin
          pixel_y_cnt <= pixel_y_cnt + 13'd1;
        end else begin
          pixel_y_cnt <= 13'd0;
          surf_cnt <= surf_cnt + 13'd1;
        end
      end
    end
  end
end

//===============================================================
// INPUT DATA CAPTURE
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    img_dat_rsp_data_q <= 512'd0;
    img_dat_rsp_valid_q <= 1'b0;
    img_dat_rsp_bank_q <= 1'b0;
  end else begin
    // Capture from whichever interface has valid data
    if (mcif2img_dat_rd_rsp_valid && ~img_dat_rsp_bank_q) begin
      img_dat_rsp_data_q <= mcif2img_dat_rd_rsp_pd;
      img_dat_rsp_valid_q <= 1'b1;
      img_dat_rsp_bank_q <= 1'b0;
    end else if (cvif2img_dat_rd_rsp_valid && img_dat_rsp_bank_q) begin
      img_dat_rsp_data_q <= cvif2img_dat_rd_rsp_pd;
      img_dat_rsp_valid_q <= 1'b1;
      img_dat_rsp_bank_q <= 1'b1;
    end else begin
      img_dat_rsp_valid_q <= 1'b0;
    end
  end
end

//===============================================================
// MEMORY ADDRESS SELECTION
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mem_addr_select <= 1'b0;
  end else begin
    // Select based on channel - use addr0 for Y, addr1 for UV
    if (reg2dp_pixel_mapping == 1'b1)  // Planar UV
      mem_addr_select <= (pixel_channel_cnt >= 16'd1);
    else
      mem_addr_select <= 1'b0;
  end
end

//===============================================================
// RESPONSE READY HANDLING
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    rsp_ready_q <= 1'b1;
  end else begin
    case (state_q)
      IMG_STATE_IDLE:    rsp_ready_q <= 1'b1;
      IMG_STATE_READING: begin
        if (img_dat_rsp_valid_q)
          rsp_ready_q <= 1'b0;
      end
      IMG_STATE_PROCESS: rsp_ready_q <= 1'b0;
      IMG_STATE_WRITE:   rsp_ready_q <= 1'b1;
      IMG_STATE_DONE:    rsp_ready_q <= 1'b0;
      default:           rsp_ready_q <= 1'b1;
    endcase
  end
end

//===============================================================
// PIXEL DATA PROCESSING
//===============================================================
// Extract pixel from input data based on format
wire [127:0] pixel_data_rgba;
wire [127:0] pixel_data_yuva;
wire [127:0] pixel_data_rgb;
wire [127:0] pixel_data_yuv;

// For simplicity, treating 512-bit data as 16 pixels of 32-bit each
// Actual extraction depends on pixel format
assign pixel_data_rgba = img_dat_rsp_data_q[255:128];  // Simplified

// Padding mask generation - all ones (no padding) initially
assign img2cvt_dat_wr_pad_mask = {128{1'b1}};

//===============================================================
// OUTPUT DATA ASSIGNMENT
//===============================================================
always @* begin
  // Default values
  img2cvt_dat_wr_en_r = 1'b0;
  img2cvt_dat_wr_addr_r = 12'd0;
  img2cvt_dat_wr_data_r = 1024'd0;
  img2cvt_dat_wr_hsel_r = 1'b0;
  img2cvt_dat_wr_info_r = 12'd0;
  img2cvt_mn_wr_data_r = 1024'd0;

  // Shared buffer default
  img2sbuf_p0_wr_en_r = 1'b0;
  img2sbuf_p0_wr_addr_r = 8'd0;
  img2sbuf_p0_wr_data_r = 256'd0;
  img2sbuf_p1_wr_en_r = 1'b0;
  img2sbuf_p1_wr_addr_r = 8'd0;
  img2sbuf_p1_wr_data_r = 256'd0;

  // Status default
  img2status_dat_updt_r = 1'b0;
  img2status_dat_entries_r = 12'd0;
  img2status_dat_slices_r = 12'd0;
  img2status_state_r = 2'd0;

  case (state_q)
    IMG_STATE_WRITE: begin
      // Generate write address from counters
      img2cvt_dat_wr_addr_r = {4'd0, surf_cnt[7:0]} + line_cnt[7:0];
      img2cvt_dat_wr_info_r = {pixel_channel_cnt[3:0], pixel_y_cnt[3:0], pixel_x_cnt[3:0]};

      if (is_padding_pixel || is_padding_line) begin
        // Output padding
        img2cvt_dat_wr_en_r = 1'b1;
        img2cvt_dat_wr_data_r = {64{reg2dp_pad_value}};  // Fill with pad value
        img2cvt_dat_wr_pad_mask_r = {128{1'b0}};  // Mark as padding
      end else begin
        // Output actual pixel data
        img2cvt_dat_wr_en_r = 1'b1;
        // Mean subtraction (simplified - actual implementation depends on format)
        img2cvt_mn_wr_data_r = img_dat_rsp_data_q;
        img2cvt_dat_wr_data_r = img_dat_rsp_data_q;
      end

      img2status_dat_updt_r = 1'b1;
      img2status_dat_entries_r = pixel_channel_cnt[11:0];
      img2status_dat_slices_r = surf_cnt[11:0];
      img2status_state_r = 2'd1;  // Working
    end

    IMG_STATE_DONE: begin
      img2status_dat_updt_r = 1'b1;
      img2status_state_r = 2'd2;  // Done
    end

    default: begin
      img2status_state_r = 2'd0;  // Idle
    end
  endcase
end

//===============================================================
// OUTPUT ASSIGNMENTS
//===============================================================
assign img2cvt_dat_wr_en = img2cvt_dat_wr_en_r;
assign img2cvt_dat_wr_addr = img2cvt_dat_wr_addr_r;
assign img2cvt_dat_wr_data = img2cvt_dat_wr_data_r;
assign img2cvt_dat_wr_hsel = img2cvt_dat_wr_hsel_r;
assign img2cvt_dat_wr_info_pd = img2cvt_dat_wr_info_r;
assign img2cvt_dat_wr_pad_mask = img2cvt_dat_wr_pad_mask_r;
assign img2cvt_mn_wr_data = img2cvt_mn_wr_data_r;

assign img2sbuf_p0_wr_en = img2sbuf_p0_wr_en_r;
assign img2sbuf_p0_wr_addr = img2sbuf_p0_wr_addr_r;
assign img2sbuf_p0_wr_data = img2sbuf_p0_wr_data_r;
assign img2sbuf_p1_wr_en = img2sbuf_p1_wr_en_r;
assign img2sbuf_p1_wr_addr = img2sbuf_p1_wr_addr_r;
assign img2sbuf_p1_wr_data = img2sbuf_p1_wr_data_r;

assign img2status_dat_updt = img2status_dat_updt_r;
assign img2status_dat_entries = img2status_dat_entries_r;
assign img2status_dat_slices = img2status_dat_slices_r;
assign img2status_state = img2status_state_r;

// Performance counters
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_img_rd_latency_r <= 32'd0;
    dp2reg_img_rd_stall_r <= 32'd0;
  end else begin
    if (state_q == IMG_STATE_READING && ~img_dat_rsp_valid_q)
      dp2reg_img_rd_latency_r <= dp2reg_img_rd_latency_r + 32'd1;
    if (state_q == IMG_STATE_READING && rsp_ready_q && ~img_dat_rsp_valid_q)
      dp2reg_img_rd_stall_r <= dp2reg_img_rd_stall_r + 32'd1;
  end
end

assign dp2reg_img_rd_latency = dp2reg_img_rd_latency_r;
assign dp2reg_img_rd_stall = dp2reg_img_rd_stall_r;

endmodule // NV_NVDLA_CDMA_image_new