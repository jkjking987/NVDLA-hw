// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_reg_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSC Register File module
// - Single register group (S): Status and Pointer registers
// - Dual register groups (D0/D1): Configuration registers for ping-pong operation
// - Producer/consumer pointer mechanism for operation enable
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_reg_new (
   nvdla_core_clk             //|< i
  ,nvdla_core_rstn            //|< i
  ,reg_wr_en                  //|< i
  ,reg_rd_en                  //|< i
  ,reg_wr_data                //|< i  [31:0]
  ,reg_offset                 //|< i  [11:0]
  ,dp2reg_done                //|< i
  ,dp2reg_consumer            //|< i
  ,dp2reg_status_0            //|< i  [1:0]
  ,dp2reg_status_1            //|< i  [1:0]
  ,csc2csb_resp_valid         //|> o
  ,csc2csb_resp_pd            //|> o  [33:0]
  ,reg2dp_atomics             //|> o  [20:0]
  ,reg2dp_batches             //|> o  [4:0]
  ,reg2dp_conv_mode           //|> o
  ,reg2dp_conv_x_stride_ext   //|> o  [2:0]
  ,reg2dp_conv_y_stride_ext   //|> o  [2:0]
  ,reg2dp_cya                 //|> o  [31:0]
  ,reg2dp_data_bank           //|> o  [3:0]
  ,reg2dp_data_reuse          //|> o
  ,reg2dp_datain_channel_ext  //|> o  [12:0]
  ,reg2dp_datain_format       //|> o
  ,reg2dp_datain_height_ext   //|> o  [12:0]
  ,reg2dp_datain_width_ext    //|> o  [12:0]
  ,reg2dp_dataout_channel     //|> o  [12:0]
  ,reg2dp_dataout_height      //|> o  [12:0]
  ,reg2dp_dataout_width       //|> o  [12:0]
  ,reg2dp_entries             //|> o  [11:0]
  ,reg2dp_in_precision        //|> o  [1:0]
  ,reg2dp_op_en               //|> o
  ,reg2dp_pad_left            //|> o  [4:0]
  ,reg2dp_pad_top             //|> o  [4:0]
  ,reg2dp_pad_value           //|> o  [15:0]
  ,reg2dp_pra_truncate        //|> o  [1:0]
  ,reg2dp_proc_precision      //|> o  [1:0]
  ,reg2dp_rls_slices          //|> o  [11:0]
  ,reg2dp_skip_data_rls       //|> o
  ,reg2dp_skip_weight_rls     //|> o
  ,reg2dp_weight_bank         //|> o  [3:0]
  ,reg2dp_weight_bytes        //|> o  [24:0]
  ,reg2dp_weight_channel_ext  //|> o  [12:0]
  ,reg2dp_weight_format       //|> o
  ,reg2dp_weight_height_ext   //|> o  [4:0]
  ,reg2dp_weight_kernel       //|> o  [12:0]
  ,reg2dp_weight_reuse        //|> o
  ,reg2dp_weight_width_ext    //|> o  [4:0]
  ,reg2dp_wmb_bytes           //|> o  [20:0]
  ,reg2dp_x_dilation_ext      //|> o  [4:0]
  ,reg2dp_y_dilation_ext      //|> o  [4:0]
  ,reg2dp_y_extension         //|> o  [1:0]
  ,reg2dp_producer            //|> o
  );

//==========================================
// Parameters
//==========================================
parameter [31:0] ADDR_STATUS   = 12'h000;
parameter [31:0] ADDR_POINTER  = 12'h004;
parameter [31:0] ADDR_OP_ENABLE = 12'h008;
parameter [31:0] ADDR_MISC_CFG = 12'h00C;
parameter [31:0] ADDR_DUAL_BASE = 12'h008;  // Base for dual regs

//==========================================
// Ports
//==========================================
input         nvdla_core_clk;
input         nvdla_core_rstn;
input         reg_wr_en;
input         reg_rd_en;
input  [31:0] reg_wr_data;
input  [11:0] reg_offset;
input         dp2reg_done;
input         dp2reg_consumer;
input  [1:0]  dp2reg_status_0;
input  [1:0]  dp2reg_status_1;

output        csc2csb_resp_valid;
output [33:0] csc2csb_resp_pd;
output [20:0] reg2dp_atomics;
output [4:0]  reg2dp_batches;
output        reg2dp_conv_mode;
output [2:0]  reg2dp_conv_x_stride_ext;
output [2:0]  reg2dp_conv_y_stride_ext;
output [31:0] reg2dp_cya;
output [3:0]  reg2dp_data_bank;
output        reg2dp_data_reuse;
output [12:0] reg2dp_datain_channel_ext;
output        reg2dp_datain_format;
output [12:0] reg2dp_datain_height_ext;
output [12:0] reg2dp_datain_width_ext;
output [12:0] reg2dp_dataout_channel;
output [12:0] reg2dp_dataout_height;
output [12:0] reg2dp_dataout_width;
output [11:0] reg2dp_entries;
output [1:0]  reg2dp_in_precision;
output        reg2dp_op_en;
output [4:0]  reg2dp_pad_left;
output [4:0]  reg2dp_pad_top;
output [15:0] reg2dp_pad_value;
output [1:0]  reg2dp_pra_truncate;
output [1:0]  reg2dp_proc_precision;
output [11:0] reg2dp_rls_slices;
output        reg2dp_skip_data_rls;
output        reg2dp_skip_weight_rls;
output [3:0]  reg2dp_weight_bank;
output [24:0] reg2dp_weight_bytes;
output [12:0] reg2dp_weight_channel_ext;
output        reg2dp_weight_format;
output [4:0]  reg2dp_weight_height_ext;
output [12:0] reg2dp_weight_kernel;
output        reg2dp_weight_reuse;
output [4:0]  reg2dp_weight_width_ext;
output [20:0] reg2dp_wmb_bytes;
output [4:0]  reg2dp_x_dilation_ext;
output [4:0]  reg2dp_y_dilation_ext;
output [1:0]  reg2dp_y_extension;
output        reg2dp_producer;

//==========================================
// Internal signals
//==========================================
// Single register group signals
wire        s_reg_wr_en;
wire        s_op_en_trigger;
reg         s_producer;
reg         s_consumer;
wire [31:0] s_reg_rd_data;
wire [31:0] s_status_out;
wire [31:0] s_pointer_out;

// Dual register group signals
wire        d0_reg_wr_en;
wire        d1_reg_wr_en;
wire        d0_op_en_trigger;
wire        d1_op_en_trigger;
reg         d0_op_en;
reg         d1_op_en;
reg  [20:0] d0_atomics;
reg  [4:0]  d0_batches;
reg         d0_conv_mode;
reg  [2:0]  d0_conv_x_stride_ext;
reg  [2:0]  d0_conv_y_stride_ext;
reg  [31:0] d0_cya;
reg  [3:0]  d0_data_bank;
reg         d0_data_reuse;
reg  [12:0] d0_datain_channel_ext;
reg         d0_datain_format;
reg  [12:0] d0_datain_height_ext;
reg  [12:0] d0_datain_width_ext;
reg  [12:0] d0_dataout_channel;
reg  [12:0] d0_dataout_height;
reg  [12:0] d0_dataout_width;
reg  [11:0] d0_entries;
reg  [1:0]  d0_in_precision;
reg  [4:0]  d0_pad_left;
reg  [4:0]  d0_pad_top;
reg  [15:0] d0_pad_value;
reg  [1:0]  d0_pra_truncate;
reg  [1:0]  d0_proc_precision;
reg  [11:0] d0_rls_slices;
reg         d0_skip_data_rls;
reg         d0_skip_weight_rls;
reg  [3:0]  d0_weight_bank;
reg  [24:0] d0_weight_bytes;
reg  [12:0] d0_weight_channel_ext;
reg         d0_weight_format;
reg  [4:0]  d0_weight_height_ext;
reg  [12:0] d0_weight_kernel;
reg         d0_weight_reuse;
reg  [4:0]  d0_weight_width_ext;
reg  [20:0] d0_wmb_bytes;
reg  [4:0]  d0_x_dilation_ext;
reg  [4:0]  d0_y_dilation_ext;
reg  [1:0]  d0_y_extension;
reg  [31:0] d0_reg_rd_data;

reg  [20:0] d1_atomics;
reg  [4:0]  d1_batches;
reg         d1_conv_mode;
reg  [2:0]  d1_conv_x_stride_ext;
reg  [2:0]  d1_conv_y_stride_ext;
reg  [31:0] d1_cya;
reg  [3:0]  d1_data_bank;
reg         d1_data_reuse;
reg  [12:0] d1_datain_channel_ext;
reg         d1_datain_format;
reg  [12:0] d1_datain_height_ext;
reg  [12:0] d1_datain_width_ext;
reg  [12:0] d1_dataout_channel;
reg  [12:0] d1_dataout_height;
reg  [12:0] d1_dataout_width;
reg  [11:0] d1_entries;
reg  [1:0]  d1_in_precision;
reg  [4:0]  d1_pad_left;
reg  [4:0]  d1_pad_top;
reg  [15:0] d1_pad_value;
reg  [1:0]  d1_pra_truncate;
reg  [1:0]  d1_proc_precision;
reg  [11:0] d1_rls_slices;
reg         d1_skip_data_rls;
reg         d1_skip_weight_rls;
reg  [3:0]  d1_weight_bank;
reg  [24:0] d1_weight_bytes;
reg  [12:0] d1_weight_channel_ext;
reg         d1_weight_format;
reg  [4:0]  d1_weight_height_ext;
reg  [12:0] d1_weight_kernel;
reg         d1_weight_reuse;
reg  [4:0]  d1_weight_width_ext;
reg  [20:0] d1_wmb_bytes;
reg  [4:0]  d1_x_dilation_ext;
reg  [4:0]  d1_y_dilation_ext;
reg  [1:0]  d1_y_extension;
reg  [31:0] d1_reg_rd_data;

// Selection signals
wire        select_s;
wire        select_d0;
wire        select_d1;

// Consumer/Producer pointer
reg         consumer_q;
wire        consumer_w;
wire        producer_q;
wire        op_en_ori;
reg  [2:0]  op_en_reg;

// Response signals
reg  [33:0] csc2csb_resp_pd;
reg         csc2csb_resp_valid;
wire [31:0] reg_rd_data;
wire        csb_rresp_error;
wire        csb_wresp_error;
wire [33:0] csb_rresp_pd_w;
wire [33:0] csb_wresp_pd_w;

//==========================================
// Register group selection
//==========================================
assign select_s  = (reg_offset[11:0] < 12'h008);
assign select_d0 = (reg_offset[11:0] >= 12'h008) & (producer_q == 1'b0);
assign select_d1 = (reg_offset[11:0] >= 12'h008) & (producer_q == 1'b1);

assign s_reg_wr_en  = reg_wr_en & select_s;
assign d0_reg_wr_en = reg_wr_en & select_d0 & ~d0_op_en;
assign d1_reg_wr_en = reg_wr_en & select_d1 & ~d1_op_en;

//==========================================
// Single register group (Status/Pointer)
//==========================================
// Consumer pointer management
assign consumer_w = ~consumer_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    consumer_q <= 1'b0;
  end else if (dp2reg_done) begin
    consumer_q <= consumer_w;
  end
end

// Producer register (write-only via CSB)
wire s_pointer_wren;
assign s_pointer_wren = s_reg_wr_en & (reg_offset[11:0] == ADDR_POINTER);

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    s_producer <= 1'b0;
  end else if (s_pointer_wren) begin
    s_producer <= reg_wr_data[0];
  end
end

assign producer_q = s_producer;

// Status output
assign s_status_out[31:0] = {14'b0, dp2reg_status_1[1:0], 14'b0, dp2reg_status_0[1:0]};
assign s_pointer_out[31:0] = {15'b0, consumer_q, 15'b0, s_producer};

// Single register read mux
always @(*) begin
  case (reg_offset[11:0])
    ADDR_STATUS:   s_reg_rd_data = s_status_out;
    ADDR_POINTER:  s_reg_rd_data = s_pointer_out;
    default:       s_reg_rd_data = 32'h0;
  endcase
end

//==========================================
// Dual register group D0
//==========================================
assign d0_op_en_trigger = d0_reg_wr_en & (reg_offset[11:0] == ADDR_OP_ENABLE);

// D0_OP_EN register (write trigger only, read from flop)
wire d0_op_en_w;
assign d0_op_en_w = (~d0_op_en & d0_op_en_trigger) ? reg_wr_data[0] :
                    (dp2reg_done & consumer_q == 1'b0) ? 1'b0 : d0_op_en;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d0_op_en <= 1'b0;
  end else begin
    d0_op_en <= d0_op_en_w;
  end
end

// D0 Configuration registers
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d0_atomics[20:0]          <= 21'd1;
    d0_batches[4:0]           <= 5'd0;
    d0_conv_mode              <= 1'b0;
    d0_conv_x_stride_ext[2:0] <= 3'd0;
    d0_conv_y_stride_ext[2:0] <= 3'd0;
    d0_cya[31:0]              <= 32'd0;
    d0_data_bank[3:0]         <= 4'd0;
    d0_data_reuse             <= 1'b0;
    d0_datain_channel_ext[12:0] <= 13'd0;
    d0_datain_format          <= 1'b0;
    d0_datain_height_ext[12:0] <= 13'd0;
    d0_datain_width_ext[12:0] <= 13'd0;
    d0_dataout_channel[12:0]  <= 13'd0;
    d0_dataout_height[12:0]   <= 13'd0;
    d0_dataout_width[12:0]    <= 13'd0;
    d0_entries[11:0]          <= 12'd0;
    d0_in_precision[1:0]      <= 2'd1;
    d0_pad_left[4:0]           <= 5'd0;
    d0_pad_top[4:0]            <= 5'd0;
    d0_pad_value[15:0]        <= 16'd0;
    d0_pra_truncate[1:0]      <= 2'd0;
    d0_proc_precision[1:0]     <= 2'd1;
    d0_rls_slices[11:0]       <= 12'd1;
    d0_skip_data_rls          <= 1'b0;
    d0_skip_weight_rls        <= 1'b0;
    d0_weight_bank[3:0]       <= 4'd0;
    d0_weight_bytes[24:0]     <= 25'd0;
    d0_weight_channel_ext[12:0] <= 13'd0;
    d0_weight_format          <= 1'b0;
    d0_weight_height_ext[4:0] <= 5'd0;
    d0_weight_kernel[12:0]    <= 13'd0;
    d0_weight_reuse           <= 1'b0;
    d0_weight_width_ext[4:0]  <= 5'd0;
    d0_wmb_bytes[20:0]        <= 21'd0;
    d0_x_dilation_ext[4:0]    <= 5'd0;
    d0_y_dilation_ext[4:0]    <= 5'd0;
    d0_y_extension[1:0]       <= 2'd0;
  end else begin
    if (d0_reg_wr_en) begin
      case (reg_offset[11:0])
        12'h010: d0_datain_format <= reg_wr_data[0];
        12'h014: begin
          d0_datain_width_ext[12:0]  <= reg_wr_data[12:0];
          d0_datain_height_ext[12:0] <= reg_wr_data[28:16];
        end
        12'h018: d0_datain_channel_ext[12:0] <= reg_wr_data[12:0];
        12'h01C: d0_batches[4:0] <= reg_wr_data[4:0];
        12'h020: d0_y_extension[1:0] <= reg_wr_data[1:0];
        12'h024: d0_entries[11:0] <= reg_wr_data[11:0];
        12'h028: d0_weight_format <= reg_wr_data[0];
        12'h02C: begin
          d0_weight_width_ext[4:0]  <= reg_wr_data[4:0];
          d0_weight_height_ext[4:0] <= reg_wr_data[20:16];
        end
        12'h030: begin
          d0_weight_channel_ext[12:0] <= reg_wr_data[12:0];
          d0_weight_kernel[12:0]      <= reg_wr_data[28:16];
        end
        12'h034: d0_weight_bytes[24:0] <= reg_wr_data[31:7];
        12'h038: d0_wmb_bytes[20:0] <= reg_wr_data[27:7];
        12'h03C: begin
          d0_dataout_width[12:0]  <= reg_wr_data[12:0];
          d0_dataout_height[12:0] <= reg_wr_data[28:16];
        end
        12'h040: d0_dataout_channel[12:0] <= reg_wr_data[12:0];
        12'h044: d0_atomics[20:0] <= reg_wr_data[20:0];
        12'h048: d0_rls_slices[11:0] <= reg_wr_data[11:0];
        12'h04C: begin
          d0_conv_x_stride_ext[2:0] <= reg_wr_data[2:0];
          d0_conv_y_stride_ext[2:0] <= reg_wr_data[18:16];
        end
        12'h050: begin
          d0_x_dilation_ext[4:0] <= reg_wr_data[4:0];
          d0_y_dilation_ext[4:0] <= reg_wr_data[20:16];
        end
        12'h054: begin
          d0_pad_left[4:0] <= reg_wr_data[4:0];
          d0_pad_top[4:0]   <= reg_wr_data[20:16];
        end
        12'h058: d0_pad_value[15:0] <= reg_wr_data[15:0];
        12'h05C: begin
          d0_data_bank[3:0]   <= reg_wr_data[3:0];
          d0_weight_bank[3:0] <= reg_wr_data[19:16];
        end
        12'h060: d0_pra_truncate[1:0] <= reg_wr_data[1:0];
        12'h064: d0_cya[31:0] <= reg_wr_data[31:0];
        12'h00C: begin
          d0_conv_mode          <= reg_wr_data[0];
          d0_in_precision[1:0]  <= reg_wr_data[9:8];
          d0_proc_precision[1:0] <= reg_wr_data[13:12];
          d0_data_reuse         <= reg_wr_data[16];
          d0_weight_reuse       <= reg_wr_data[20];
          d0_skip_data_rls      <= reg_wr_data[24];
          d0_skip_weight_rls    <= reg_wr_data[28];
        end
      endcase
    end
  end
end

// D0 register read mux
always @(*) begin
  case (reg_offset[11:0])
    12'h044: d0_reg_rd_data = {11'b0, d0_atomics[20:0]};
    12'h05C: d0_reg_rd_data = {12'b0, d0_weight_bank[3:0], 12'b0, d0_data_bank[3:0]};
    12'h01C: d0_reg_rd_data = {27'b0, d0_batches[4:0]};
    12'h04C: d0_reg_rd_data = {13'b0, d0_conv_y_stride_ext[2:0], 13'b0, d0_conv_x_stride_ext[2:0]};
    12'h064: d0_reg_rd_data = d0_cya[31:0];
    12'h010: d0_reg_rd_data = {31'b0, d0_datain_format};
    12'h014: d0_reg_rd_data = {3'b0, d0_datain_height_ext[12:0], 3'b0, d0_datain_width_ext[12:0]};
    12'h018: d0_reg_rd_data = {19'b0, d0_datain_channel_ext[12:0]};
    12'h03C: d0_reg_rd_data = {3'b0, d0_dataout_height[12:0], 3'b0, d0_dataout_width[12:0]};
    12'h040: d0_reg_rd_data = {19'b0, d0_dataout_channel[12:0]};
    12'h050: d0_reg_rd_data = {11'b0, d0_y_dilation_ext[4:0], 11'b0, d0_x_dilation_ext[4:0]};
    12'h024: d0_reg_rd_data = {20'b0, d0_entries[11:0]};
    12'h00C: d0_reg_rd_data = {3'b0, d0_skip_weight_rls, 3'b0, d0_skip_data_rls, 3'b0, d0_weight_reuse, 3'b0, d0_data_reuse, 2'b0, d0_proc_precision[1:0], 2'b0, d0_in_precision[1:0], 7'b0, d0_conv_mode};
    12'h008: d0_reg_rd_data = {31'b0, d0_op_en};
    12'h020: d0_reg_rd_data = {30'b0, d0_y_extension[1:0]};
    12'h060: d0_reg_rd_data = {30'b0, d0_pra_truncate[1:0]};
    12'h048: d0_reg_rd_data = {20'b0, d0_rls_slices[11:0]};
    12'h034: d0_reg_rd_data = {d0_weight_bytes[24:0], 7'b0};
    12'h028: d0_reg_rd_data = {31'b0, d0_weight_format};
    12'h02C: d0_reg_rd_data = {11'b0, d0_weight_height_ext[4:0], 11'b0, d0_weight_width_ext[4:0]};
    12'h030: d0_reg_rd_data = {3'b0, d0_weight_kernel[12:0], 3'b0, d0_weight_channel_ext[12:0]};
    12'h038: d0_reg_rd_data = {4'b0, d0_wmb_bytes[20:0], 7'b0};
    12'h054: d0_reg_rd_data = {11'b0, d0_pad_top[4:0], 11'b0, d0_pad_left[4:0]};
    12'h058: d0_reg_rd_data = {16'b0, d0_pad_value[15:0]};
    default: d0_reg_rd_data = 32'h0;
  endcase
end

//==========================================
// Dual register group D1 (same structure as D0)
//==========================================
assign d1_op_en_trigger = d1_reg_wr_en & (reg_offset[11:0] == ADDR_OP_ENABLE);

wire d1_op_en_w;
assign d1_op_en_w = (~d1_op_en & d1_op_en_trigger) ? reg_wr_data[0] :
                    (dp2reg_done & consumer_q == 1'b1) ? 1'b0 : d1_op_en;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d1_op_en <= 1'b0;
  end else begin
    d1_op_en <= d1_op_en_w;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    d1_atomics[20:0]          <= 21'd1;
    d1_batches[4:0]           <= 5'd0;
    d1_conv_mode              <= 1'b0;
    d1_conv_x_stride_ext[2:0] <= 3'd0;
    d1_conv_y_stride_ext[2:0] <= 3'd0;
    d1_cya[31:0]              <= 32'd0;
    d1_data_bank[3:0]         <= 4'd0;
    d1_data_reuse             <= 1'b0;
    d1_datain_channel_ext[12:0] <= 13'd0;
    d1_datain_format          <= 1'b0;
    d1_datain_height_ext[12:0] <= 13'd0;
    d1_datain_width_ext[12:0] <= 13'd0;
    d1_dataout_channel[12:0]  <= 13'd0;
    d1_dataout_height[12:0]   <= 13'd0;
    d1_dataout_width[12:0]    <= 13'd0;
    d1_entries[11:0]          <= 12'd0;
    d1_in_precision[1:0]      <= 2'd1;
    d1_pad_left[4:0]           <= 5'd0;
    d1_pad_top[4:0]            <= 5'd0;
    d1_pad_value[15:0]        <= 16'd0;
    d1_pra_truncate[1:0]      <= 2'd0;
    d1_proc_precision[1:0]     <= 2'd1;
    d1_rls_slices[11:0]       <= 12'd1;
    d1_skip_data_rls          <= 1'b0;
    d1_skip_weight_rls        <= 1'b0;
    d1_weight_bank[3:0]       <= 4'd0;
    d1_weight_bytes[24:0]     <= 25'd0;
    d1_weight_channel_ext[12:0] <= 13'd0;
    d1_weight_format          <= 1'b0;
    d1_weight_height_ext[4:0] <= 5'd0;
    d1_weight_kernel[12:0]    <= 13'd0;
    d1_weight_reuse           <= 1'b0;
    d1_weight_width_ext[4:0]  <= 5'd0;
    d1_wmb_bytes[20:0]        <= 21'd0;
    d1_x_dilation_ext[4:0]    <= 5'd0;
    d1_y_dilation_ext[4:0]    <= 5'd0;
    d1_y_extension[1:0]       <= 2'd0;
  end else begin
    if (d1_reg_wr_en) begin
      case (reg_offset[11:0])
        12'h010: d1_datain_format <= reg_wr_data[0];
        12'h014: begin
          d1_datain_width_ext[12:0]  <= reg_wr_data[12:0];
          d1_datain_height_ext[12:0] <= reg_wr_data[28:16];
        end
        12'h018: d1_datain_channel_ext[12:0] <= reg_wr_data[12:0];
        12'h01C: d1_batches[4:0] <= reg_wr_data[4:0];
        12'h020: d1_y_extension[1:0] <= reg_wr_data[1:0];
        12'h024: d1_entries[11:0] <= reg_wr_data[11:0];
        12'h028: d1_weight_format <= reg_wr_data[0];
        12'h02C: begin
          d1_weight_width_ext[4:0]  <= reg_wr_data[4:0];
          d1_weight_height_ext[4:0] <= reg_wr_data[20:16];
        end
        12'h030: begin
          d1_weight_channel_ext[12:0] <= reg_wr_data[12:0];
          d1_weight_kernel[12:0]      <= reg_wr_data[28:16];
        end
        12'h034: d1_weight_bytes[24:0] <= reg_wr_data[31:7];
        12'h038: d1_wmb_bytes[20:0] <= reg_wr_data[27:7];
        12'h03C: begin
          d1_dataout_width[12:0]  <= reg_wr_data[12:0];
          d1_dataout_height[12:0] <= reg_wr_data[28:16];
        end
        12'h040: d1_dataout_channel[12:0] <= reg_wr_data[12:0];
        12'h044: d1_atomics[20:0] <= reg_wr_data[20:0];
        12'h048: d1_rls_slices[11:0] <= reg_wr_data[11:0];
        12'h04C: begin
          d1_conv_x_stride_ext[2:0] <= reg_wr_data[2:0];
          d1_conv_y_stride_ext[2:0] <= reg_wr_data[18:16];
        end
        12'h050: begin
          d1_x_dilation_ext[4:0] <= reg_wr_data[4:0];
          d1_y_dilation_ext[4:0] <= reg_wr_data[20:16];
        end
        12'h054: begin
          d1_pad_left[4:0] <= reg_wr_data[4:0];
          d1_pad_top[4:0]   <= reg_wr_data[20:16];
        end
        12'h058: d1_pad_value[15:0] <= reg_wr_data[15:0];
        12'h05C: begin
          d1_data_bank[3:0]   <= reg_wr_data[3:0];
          d1_weight_bank[3:0] <= reg_wr_data[19:16];
        end
        12'h060: d1_pra_truncate[1:0] <= reg_wr_data[1:0];
        12'h064: d1_cya[31:0] <= reg_wr_data[31:0];
        12'h00C: begin
          d1_conv_mode          <= reg_wr_data[0];
          d1_in_precision[1:0]  <= reg_wr_data[9:8];
          d1_proc_precision[1:0] <= reg_wr_data[13:12];
          d1_data_reuse         <= reg_wr_data[16];
          d1_weight_reuse       <= reg_wr_data[20];
          d1_skip_data_rls      <= reg_wr_data[24];
          d1_skip_weight_rls    <= reg_wr_data[28];
        end
      endcase
    end
  end
end

always @(*) begin
  case (reg_offset[11:0])
    12'h044: d1_reg_rd_data = {11'b0, d1_atomics[20:0]};
    12'h05C: d1_reg_rd_data = {12'b0, d1_weight_bank[3:0], 12'b0, d1_data_bank[3:0]};
    12'h01C: d1_reg_rd_data = {27'b0, d1_batches[4:0]};
    12'h04C: d1_reg_rd_data = {13'b0, d1_conv_y_stride_ext[2:0], 13'b0, d1_conv_x_stride_ext[2:0]};
    12'h064: d1_reg_rd_data = d1_cya[31:0];
    12'h010: d1_reg_rd_data = {31'b0, d1_datain_format};
    12'h014: d1_reg_rd_data = {3'b0, d1_datain_height_ext[12:0], 3'b0, d1_datain_width_ext[12:0]};
    12'h018: d1_reg_rd_data = {19'b0, d1_datain_channel_ext[12:0]};
    12'h03C: d1_reg_rd_data = {3'b0, d1_dataout_height[12:0], 3'b0, d1_dataout_width[12:0]};
    12'h040: d1_reg_rd_data = {19'b0, d1_dataout_channel[12:0]};
    12'h050: d1_reg_rd_data = {11'b0, d1_y_dilation_ext[4:0], 11'b0, d1_x_dilation_ext[4:0]};
    12'h024: d1_reg_rd_data = {20'b0, d1_entries[11:0]};
    12'h00C: d1_reg_rd_data = {3'b0, d1_skip_weight_rls, 3'b0, d1_skip_data_rls, 3'b0, d1_weight_reuse, 3'b0, d1_data_reuse, 2'b0, d1_proc_precision[1:0], 2'b0, d1_in_precision[1:0], 7'b0, d1_conv_mode};
    12'h008: d1_reg_rd_data = {31'b0, d1_op_en};
    12'h020: d1_reg_rd_data = {30'b0, d1_y_extension[1:0]};
    12'h060: d1_reg_rd_data = {30'b0, d1_pra_truncate[1:0]};
    12'h048: d1_reg_rd_data = {20'b0, d1_rls_slices[11:0]};
    12'h034: d1_reg_rd_data = {d1_weight_bytes[24:0], 7'b0};
    12'h028: d1_reg_rd_data = {31'b0, d1_weight_format};
    12'h02C: d1_reg_rd_data = {11'b0, d1_weight_height_ext[4:0], 11'b0, d1_weight_width_ext[4:0]};
    12'h030: d1_reg_rd_data = {3'b0, d1_weight_kernel[12:0], 3'b0, d1_weight_channel_ext[12:0]};
    12'h038: d1_reg_rd_data = {4'b0, d1_wmb_bytes[20:0], 7'b0};
    12'h054: d1_reg_rd_data = {11'b0, d1_pad_top[4:0], 11'b0, d1_pad_left[4:0]};
    12'h058: d1_reg_rd_data = {16'b0, d1_pad_value[15:0]};
    default: d1_reg_rd_data = 32'h0;
  endcase
end

//==========================================
// Read data selection
//==========================================
assign reg_rd_data = ({32{select_s}}  & s_reg_rd_data) |
                     ({32{select_d0}} & d0_reg_rd_data) |
                     ({32{select_d1}} & d1_reg_rd_data);

//==========================================
// Operation enable output
//==========================================
assign op_en_ori = consumer_q ? d1_op_en : d0_op_en;

// OP_EN pipeline register
wire [2:0] op_en_reg_w;
assign op_en_reg_w = dp2reg_done ? 3'b0 : {op_en_reg[1:0], op_en_ori};

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_reg[2:0] <= 3'b0;
  end else begin
    op_en_reg[2:0] <= op_en_reg_w[2:0];
  end
end

assign reg2dp_op_en = op_en_reg[2];

//==========================================
// Status generation
//==========================================
wire [1:0] status_0;
wire [1:0] status_1;

assign status_0 = (d0_op_en == 1'b0) ? 2'b00 :
                  (consumer_q == 1'b1) ? 2'b10 : 2'b01;

assign status_1 = (d1_op_en == 1'b0) ? 2'b00 :
                  (consumer_q == 1'b0) ? 2'b10 : 2'b01;

//==========================================
// CSB Response generation
//==========================================
assign csb_rresp_pd_w[31:0] = reg_rd_data[31:0];
assign csb_rresp_pd_w[32]   = csb_rresp_error;
assign csb_rresp_pd_w[33]    = 1'b0;  // Read response ID

assign csb_wresp_pd_w[31:0] = {32{1'b0}};
assign csb_wresp_pd_w[32]   = csb_wresp_error;
assign csb_wresp_pd_w[33]    = 1'b1;  // Write response ID

assign csb_rresp_error = 1'b0;
assign csb_wresp_error = 1'b0;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    csc2csb_resp_valid <= 1'b0;
  end else begin
    csc2csb_resp_valid <= (reg_wr_en & ~reg_wr_data[31]) | reg_rd_en;  // Simplified nposted check
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    csc2csb_resp_pd[33:0] <= {34{1'b0}};
  end else begin
    if (reg_rd_en) begin
      csc2csb_resp_pd[33:0] <= csb_rresp_pd_w[33:0];
    end else if (reg_wr_en) begin
      csc2csb_resp_pd[33:0] <= csb_wresp_pd_w[33:0];
    end
  end
end

//==========================================
// Output assignments from active register group
//==========================================
assign reg2dp_producer            = producer_q;
assign reg2dp_atomics             = consumer_q ? d1_atomics[20:0] : d0_atomics[20:0];
assign reg2dp_batches[4:0]       = consumer_q ? d1_batches[4:0] : d0_batches[4:0];
assign reg2dp_conv_mode           = consumer_q ? d1_conv_mode : d0_conv_mode;
assign reg2dp_conv_x_stride_ext[2:0] = consumer_q ? d1_conv_x_stride_ext[2:0] : d0_conv_x_stride_ext[2:0];
assign reg2dp_conv_y_stride_ext[2:0] = consumer_q ? d1_conv_y_stride_ext[2:0] : d0_conv_y_stride_ext[2:0];
assign reg2dp_cya[31:0]           = consumer_q ? d1_cya[31:0] : d0_cya[31:0];
assign reg2dp_data_bank[3:0]      = consumer_q ? d1_data_bank[3:0] : d0_data_bank[3:0];
assign reg2dp_data_reuse          = consumer_q ? d1_data_reuse : d0_data_reuse;
assign reg2dp_datain_channel_ext[12:0] = consumer_q ? d1_datain_channel_ext[12:0] : d0_datain_channel_ext[12:0];
assign reg2dp_datain_format       = consumer_q ? d1_datain_format : d0_datain_format;
assign reg2dp_datain_height_ext[12:0] = consumer_q ? d1_datain_height_ext[12:0] : d0_datain_height_ext[12:0];
assign reg2dp_datain_width_ext[12:0] = consumer_q ? d1_datain_width_ext[12:0] : d0_datain_width_ext[12:0];
assign reg2dp_dataout_channel[12:0] = consumer_q ? d1_dataout_channel[12:0] : d0_dataout_channel[12:0];
assign reg2dp_dataout_height[12:0] = consumer_q ? d1_dataout_height[12:0] : d0_dataout_height[12:0];
assign reg2dp_dataout_width[12:0] = consumer_q ? d1_dataout_width[12:0] : d0_dataout_width[12:0];
assign reg2dp_entries[11:0]       = consumer_q ? d1_entries[11:0] : d0_entries[11:0];
assign reg2dp_in_precision[1:0]   = consumer_q ? d1_in_precision[1:0] : d0_in_precision[1:0];
assign reg2dp_pad_left[4:0]       = consumer_q ? d1_pad_left[4:0] : d0_pad_left[4:0];
assign reg2dp_pad_top[4:0]        = consumer_q ? d1_pad_top[4:0] : d0_pad_top[4:0];
assign reg2dp_pad_value[15:0]     = consumer_q ? d1_pad_value[15:0] : d0_pad_value[15:0];
assign reg2dp_pra_truncate[1:0]   = consumer_q ? d1_pra_truncate[1:0] : d0_pra_truncate[1:0];
assign reg2dp_proc_precision[1:0] = consumer_q ? d1_proc_precision[1:0] : d0_proc_precision[1:0];
assign reg2dp_rls_slices[11:0]    = consumer_q ? d1_rls_slices[11:0] : d0_rls_slices[11:0];
assign reg2dp_skip_data_rls       = consumer_q ? d1_skip_data_rls : d0_skip_data_rls;
assign reg2dp_skip_weight_rls     = consumer_q ? d1_skip_weight_rls : d0_skip_weight_rls;
assign reg2dp_weight_bank[3:0]    = consumer_q ? d1_weight_bank[3:0] : d0_weight_bank[3:0];
assign reg2dp_weight_bytes[24:0]  = consumer_q ? d1_weight_bytes[24:0] : d0_weight_bytes[24:0];
assign reg2dp_weight_channel_ext[12:0] = consumer_q ? d1_weight_channel_ext[12:0] : d0_weight_channel_ext[12:0];
assign reg2dp_weight_format       = consumer_q ? d1_weight_format : d0_weight_format;
assign reg2dp_weight_height_ext[4:0] = consumer_q ? d1_weight_height_ext[4:0] : d0_weight_height_ext[4:0];
assign reg2dp_weight_kernel[12:0] = consumer_q ? d1_weight_kernel[12:0] : d0_weight_kernel[12:0];
assign reg2dp_weight_reuse        = consumer_q ? d1_weight_reuse : d0_weight_reuse;
assign reg2dp_weight_width_ext[4:0] = consumer_q ? d1_weight_width_ext[4:0] : d0_weight_width_ext[4:0];
assign reg2dp_wmb_bytes[20:0]     = consumer_q ? d1_wmb_bytes[20:0] : d0_wmb_bytes[20:0];
assign reg2dp_x_dilation_ext[4:0] = consumer_q ? d1_x_dilation_ext[4:0] : d0_x_dilation_ext[4:0];
assign reg2dp_y_dilation_ext[4:0] = consumer_q ? d1_y_dilation_ext[4:0] : d0_y_dilation_ext[4:0];
assign reg2dp_y_extension[1:0]    = consumer_q ? d1_y_extension[1:0] : d0_y_extension[1:0];

endmodule // NV_NVDLA_CSC_reg_new