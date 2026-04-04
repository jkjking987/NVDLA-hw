// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_weight_proc_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSC Weight Processor module
// - Reads weight data from CBUF (Connection Buffer)
// - Handles weight decompression if compressed format
// - Sends weight data to CMAC A and CMAC B ports
// - Manages Winograd and direct convolution weight formats
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_weight_proc_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  ,reg2dp_op_en                   //|< i
  ,reg2dp_conv_mode               //|< i
  ,reg2dp_proc_precision          //|< i  [1:0]
  ,reg2dp_weight_format           //|< i
  ,reg2dp_weight_width_ext        //|< i  [4:0]
  ,reg2dp_weight_height_ext       //|< i  [4:0]
  ,reg2dp_weight_channel_ext      //|< i  [12:0]
  ,reg2dp_weight_kernel          //|< i  [12:0]
  ,reg2dp_weight_bytes            //|< i  [24:0]
  ,reg2dp_wmb_bytes              //|< i  [20:0]
  ,reg2dp_weight_bank            //|< i  [3:0]
  ,reg2dp_weight_reuse           //|< i
  ,reg2dp_skip_weight_rls        //|< i
  ,reg2dp_entries                 //|< i  [11:0]
  ,reg2dp_data_bank               //|< i  [3:0]
  ,reg2dp_datain_channel_ext      //|< i  [12:0]
  ,reg2dp_atomics                 //|< i  [20:0]
  ,sc2buf_wt_rd_en               //|> o
  ,sc2buf_wt_rd_addr             //|> o  [11:0]
  ,sc2buf_wt_rd_valid            //|< i
  ,sc2buf_wt_rd_data             //|< i  [511:0]
  ,sc2buf_wmb_rd_en              //|> o
  ,sc2buf_wmb_rd_addr            //|> o  [11:0]
  ,sc2buf_wmb_rd_valid          //|< i
  ,sc2buf_wmb_rd_data            //|< i  [511:0]
  ,sc2mac_wt_a_pvld             //|> o
  ,sc2mac_wt_a_data              //|> o  [511:0]
  ,sc2mac_wt_b_pvld             //|> o
  ,sc2mac_wt_b_data              //|> o  [511:0]
  ,csc2mac_wt_a_stripe_st        //|> o
  ,csc2mac_wt_a_stripe_end       //|> o
  ,csc2mac_wt_a_channel_end      //|> o
  ,csc2mac_wt_a_layer_end        //|> o
  ,csc2mac_wt_b_stripe_st        //|> o
  ,csc2mac_wt_b_stripe_end       //|> o
  ,csc2mac_wt_b_channel_end      //|> o
  ,csc2mac_wt_b_layer_end        //|> o
  ,cdma2sc_wt_updt               //|< i
  ,cdma2sc_wt_entries            //|< i  [11:0]
  ,cdma2sc_wt_kernels            //|< i  [12:0]
  ,cdma2sc_wmb_entries           //|< i  [11:0]
  ,sc2cdma_wt_updt               //|> o
  ,sc2cdma_wt_entries            //|> o  [11:0]
  ,sc2cdma_wt_kernels            //|> o  [12:0]
  ,sc2cdma_wmb_updt              //|> o
  ,sc2cdma_wmb_entries            //|> o  [11:0]
  );

//==========================================
// Parameters
//==========================================
parameter WEIGHT_FORMAT_UNCOMPRESSED = 1'b0;
parameter WEIGHT_FORMAT_COMPRESSED   = 1'b1;

parameter CONV_MODE_DIRECT   = 1'b0;
parameter CONV_MODE_WINOGRAD  = 1'b1;

parameter CBUF_ENTRY_SIZE = 64;
parameter PARALLEL_CHANNEL_NUM = 64;

// State machine
parameter [2:0] ST_IDLE        = 3'd0;
parameter [2:0] ST_WAIT_WT     = 3'd1;
parameter [2:0] ST_LOAD_WT     = 3'd2;
parameter [2:0] ST_SEND_WT     = 3'd3;
parameter [2:0] ST_DONE        = 3'd4;

//==========================================
// Ports
//==========================================
input         nvdla_core_clk;
input         nvdla_core_rstn;
input         reg2dp_op_en;
input         reg2dp_conv_mode;
input  [1:0]  reg2dp_proc_precision;
input         reg2dp_weight_format;
input  [4:0]  reg2dp_weight_width_ext;
input  [4:0]  reg2dp_weight_height_ext;
input  [12:0] reg2dp_weight_channel_ext;
input  [12:0] reg2dp_weight_kernel;
input  [24:0] reg2dp_weight_bytes;
input  [20:0] reg2dp_wmb_bytes;
input  [3:0]  reg2dp_weight_bank;
input         reg2dp_weight_reuse;
input         reg2dp_skip_weight_rls;
input  [11:0] reg2dp_entries;
input  [3:0]  reg2dp_data_bank;
input  [12:0] reg2dp_datain_channel_ext;
input  [20:0] reg2dp_atomics;

output        sc2buf_wt_rd_en;
output [11:0] sc2buf_wt_rd_addr;
input         sc2buf_wt_rd_valid;
input  [511:0] sc2buf_wt_rd_data;

output        sc2buf_wmb_rd_en;
output [11:0] sc2buf_wmb_rd_addr;
input         sc2buf_wmb_rd_valid;
input  [511:0] sc2buf_wmb_rd_data;

output        sc2mac_wt_a_pvld;
output [511:0] sc2mac_wt_a_data;
output        sc2mac_wt_b_pvld;
output [511:0] sc2mac_wt_b_data;

output        csc2mac_wt_a_stripe_st;
output        csc2mac_wt_a_stripe_end;
output        csc2mac_wt_a_channel_end;
output        csc2mac_wt_a_layer_end;
output        csc2mac_wt_b_stripe_st;
output        csc2mac_wt_b_stripe_end;
output        csc2mac_wt_b_channel_end;
output        csc2mac_wt_b_layer_end;

input         cdma2sc_wt_updt;
input  [11:0] cdma2sc_wt_entries;
input  [12:0] cdma2sc_wt_kernels;
input  [11:0] cdma2sc_wmb_entries;

output        sc2cdma_wt_updt;
output [11:0] sc2cdma_wt_entries;
output [12:0] sc2cdma_wt_kernels;
output        sc2cdma_wmb_updt;
output [11:0] sc2cdma_wmb_entries;

//==========================================
// Internal signals
//==========================================
// State machine
reg  [2:0] state_q;
reg  [2:0] next_state;

// Weight dimensions
wire [4:0]  kernel_width;
wire [4:0]  kernel_height;
wire [12:0] weight_channel;
wire [12:0] kernel_num;
wire [24:0] weight_byte_count;
wire [20:0] wmb_byte_count;
wire [11:0] weight_entries;
wire [11:0] wmb_entries;

// CBUF configuration
wire [11:0] cbuf_entry_per_weight;
wire [31:0] cbuf_entry_for_weight;
wire [31:0] weight_layer_start_byte_idx;

// Counters
reg  [12:0] kernel_count;
reg  [12:0] kernel_group_count;
reg  [31:0] weight_atom_count;
reg  [31:0] channel_group_count;
reg  [11:0] weight_entry_idx_free;
reg  [11:0] weight_entry_idx_available;
reg  [11:0] wmb_entry_idx_free;
reg  [11:0] wmb_entry_idx_available;
reg  [12:0] kernel_num_available;
reg  [12:0] kernel_num_used;

// Control signals
reg         wt_fetch_done;
reg         layer_complete;
reg         stripe_start;
reg         stripe_end_signal;
reg         channel_end_signal;
reg         layer_end_signal;

// Output signals
reg         sc2mac_wt_a_pvld;
reg         sc2mac_wt_b_pvld;
reg  [511:0] sc2mac_wt_a_data;
reg  [511:0] sc2mac_wt_b_data;
reg         csc2mac_wt_a_stripe_st;
reg         csc2mac_wt_a_stripe_end;
reg         csc2mac_wt_a_channel_end;
reg         csc2mac_wt_a_layer_end;
reg         csc2mac_wt_b_stripe_st;
reg         csc2mac_wt_b_stripe_end;
reg         csc2mac_wt_b_channel_end;
reg         csc2mac_wt_b_layer_end;

// CBUF read
reg         sc2buf_wt_rd_en;
reg  [11:0] sc2buf_wt_rd_addr;
reg         sc2buf_wmb_rd_en;
reg  [11:0] sc2buf_wmb_rd_addr;

// CDMA update
reg         sc2cdma_wt_updt;
reg  [11:0] sc2cdma_wt_entries;
reg  [12:0] sc2cdma_wt_kernels;
reg         sc2cdma_wmb_updt;
reg  [11:0] sc2cdma_wmb_entries;

//==========================================
// Weight dimension calculations
//==========================================
assign kernel_width[4:0]     = reg2dp_weight_width_ext[4:0] + 5'd1;
assign kernel_height[4:0]    = reg2dp_weight_height_ext[4:0] + 5'd1;
assign weight_channel[12:0] = reg2dp_weight_channel_ext[12:0] + 13'd1;
assign kernel_num[12:0]     = reg2dp_weight_kernel[12:0] + 13'd1;
assign weight_byte_count[24:0] = reg2dp_weight_bytes[24:0];
assign wmb_byte_count[20:0]    = reg2dp_wmb_bytes[20:0];

// Weight entries calculation
assign weight_entries[11:0] = (weight_byte_count[24:0] << 7) / CBUF_ENTRY_SIZE;
assign wmb_entries[11:0]     = (wmb_byte_count[20:0] << 7) / CBUF_ENTRY_SIZE;

// CBUF entry calculation
assign cbuf_entry_per_weight[11:0] = reg2dp_entries[11:0];
assign cbuf_entry_for_weight[31:0] = (reg2dp_weight_bank[3:0] + 4'd1) * 12'd256;

// Kernel group calculation
wire [12:0] kernel_per_group;
wire [12:0] kernel_group_num;
assign kernel_per_group[12:0] = 13'd8;  // Fixed for NVDLA
assign kernel_group_num[12:0] = (kernel_num[12:0] + kernel_per_group[12:0] - 1) / kernel_per_group[12:0];

// Channel group
wire [31:0] channel_group_num;
wire [12:0] channel_per_group;
assign channel_per_group[12:0] = PARALLEL_CHANNEL_NUM;
assign channel_group_num[31:0] = (weight_channel[12:0] + channel_per_group[12:0] - 1) / channel_per_group[12:0];

//==========================================
// State machine - sequential
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_q[2:0] <= ST_IDLE;
  end else begin
    state_q[2:0] <= next_state[2:0];
  end
end

//==========================================
// State machine - combinational
//==========================================
always @(*) begin
  next_state[2:0] = state_q[2:0];
  case (state_q[2:0])
    ST_IDLE: begin
      if (reg2dp_op_en)
        next_state[2:0] = ST_WAIT_WT;
    end
    ST_WAIT_WT: begin
      if (kernel_num_available[12:0] >= 13'd1)
        next_state[2:0] = ST_LOAD_WT;
    end
    ST_LOAD_WT: begin
      next_state[2:0] = ST_SEND_WT;
    end
    ST_SEND_WT: begin
      if (layer_complete)
        next_state[2:0] = ST_DONE;
      else if (wt_fetch_done)
        next_state[2:0] = ST_WAIT_WT;
    end
    ST_DONE: begin
      next_state[2:0] = ST_IDLE;
    end
    default: next_state[2:0] = ST_IDLE;
  endcase
end

//==========================================
// Counter management
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    kernel_count[12:0] <= 13'd0;
    kernel_group_count[12:0] <= 13'd0;
    weight_atom_count[31:0] <= 32'd0;
    channel_group_count[31:0] <= 32'd0;
    weight_entry_idx_free[11:0] <= 12'd0;
    weight_entry_idx_available[11:0] <= 12'd0;
    wmb_entry_idx_free[11:0] <= 12'd0;
    wmb_entry_idx_available[11:0] <= 12'd0;
    kernel_num_available[12:0] <= 13'd0;
    kernel_num_used[12:0] <= 13'd0;
    wt_fetch_done <= 1'b0;
    layer_complete <= 1'b0;
  end else begin
    case (state_q[2:0])
      ST_IDLE: begin
        kernel_count[12:0] <= 13'd0;
        kernel_group_count[12:0] <= 13'd0;
        weight_atom_count[31:0] <= 32'd0;
        channel_group_count[31:0] <= 32'd0;
        kernel_num_available[12:0] <= 13'd0;
        kernel_num_used[12:0] <= 13'd0;
        wt_fetch_done <= 1'b0;
        layer_complete <= 1'b0;
      end
      ST_WAIT_WT: begin
        if (cdma2sc_wt_updt) begin
          weight_entry_idx_available[11:0] <= weight_entry_idx_available[11:0] + cdma2sc_wt_entries[11:0];
          wmb_entry_idx_available[11:0] <= wmb_entry_idx_available[11:0] + cdma2sc_wmb_entries[11:0];
          kernel_num_available[12:0] <= kernel_num_available[12:0] + cdma2sc_wt_kernels[12:0];
        end
      end
      ST_LOAD_WT: begin
        if (kernel_num_available[12:0] >= kernel_per_group[12:0]) begin
          kernel_num_available[12:0] <= kernel_num_available[12:0] - kernel_per_group[12:0];
        end else begin
          kernel_num_available[12:0] <= 13'd0;
        end
        wt_fetch_done <= 1'b0;
      end
      ST_SEND_WT: begin
        if (sc2mac_wt_a_pvld) begin
          channel_group_count[31:0] <= channel_group_count[31:0] + 32'd1;

          if (channel_group_count[31:0] == (channel_group_num[31:0] - 32'd1)) begin
            channel_group_count[31:0] <= 32'd0;
            kernel_count[12:0] <= kernel_count[12:0] + 13'd1;

            if (kernel_count[12:0] == (kernel_num[12:0] - 13'd1)) begin
              layer_complete <= 1'b1;
            end
          end
        end
      end
      ST_DONE: begin
        if (reg2dp_skip_weight_rls) begin
          kernel_num_used[12:0] <= kernel_num_used[12:0] + kernel_num[12:0];
        end else begin
          sc2cdma_wt_updt <= 1'b1;
          sc2cdma_wt_entries[11:0] <= weight_entry_idx_free[11:0];
          sc2cdma_wt_kernels[12:0] <= kernel_num[12:0];
          sc2cdma_wmb_updt <= 1'b1;
          sc2cdma_wmb_entries[11:0] <= wmb_entry_idx_free[11:0];
        end
      end
    endcase
  end
end

//==========================================
// Weight atom count calculation
//==========================================
wire [31:0] weight_atom_num_per_kernel;
assign weight_atom_num_per_kernel[31:0] = (kernel_width[4:0] * kernel_height[4:0] *
                                             ((weight_channel[12:0] + PARALLEL_CHANNEL_NUM - 1) / PARALLEL_CHANNEL_NUM) *
                                             ((kernel_per_group[12:0] + 7) / 8));

//==========================================
// CBUF read address calculation
//==========================================
wire [11:0] weight_cbuf_addr;
assign weight_cbuf_addr[11:0] = (weight_entry_idx_free[11:0] +
                                  kernel_count[12:0] * cbuf_entry_per_weight[11:0] +
                                  channel_group_count[31:0]) % cbuf_entry_for_weight[11:0];

wire [11:0] wmb_cbuf_addr;
assign wmb_cbuf_addr[11:0] = (wmb_entry_idx_free[11:0] +
                               kernel_group_count[12:0]) % cbuf_entry_for_weight[11:0];

//==========================================
// CBUF read control
//==========================================
always @(*) begin
  sc2buf_wt_rd_en <= 1'b0;
  sc2buf_wt_rd_addr[11:0] <= 12'd0;
  sc2buf_wmb_rd_en <= 1'b0;
  sc2buf_wmb_rd_addr[11:0] <= 12'd0;

  if (state_q[2:0] == ST_LOAD_WT) begin
    sc2buf_wt_rd_en <= 1'b1;
    sc2buf_wt_rd_addr[11:0] <= weight_cbuf_addr[11:0];

    if (reg2dp_weight_format == WEIGHT_FORMAT_COMPRESSED) begin
      sc2buf_wmb_rd_en <= 1'b1;
      sc2buf_wmb_rd_addr[11:0] <= wmb_cbuf_addr[11:0];
    end
  end
end

//==========================================
// Weight data output to CMAC
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    sc2mac_wt_a_pvld <= 1'b0;
    sc2mac_wt_b_pvld <= 1'b0;
    sc2mac_wt_a_data[511:0] <= {512{1'b0}};
    sc2mac_wt_b_data[511:0] <= {512{1'b0}};
    csc2mac_wt_a_stripe_st <= 1'b0;
    csc2mac_wt_a_stripe_end <= 1'b0;
    csc2mac_wt_a_channel_end <= 1'b0;
    csc2mac_wt_a_layer_end <= 1'b0;
    csc2mac_wt_b_stripe_st <= 1'b0;
    csc2mac_wt_b_stripe_end <= 1'b0;
    csc2mac_wt_b_channel_end <= 1'b0;
    csc2mac_wt_b_layer_end <= 1'b0;
  end else begin
    sc2mac_wt_a_pvld <= 1'b0;
    sc2mac_wt_b_pvld <= 1'b0;

    if (state_q[2:0] == ST_LOAD_WT && sc2buf_wt_rd_valid) begin
      sc2mac_wt_a_pvld <= 1'b1;
      sc2mac_wt_b_pvld <= 1'b1;
      sc2mac_wt_a_data[511:0] <= sc2buf_wt_rd_data[511:0];
      sc2mac_wt_b_data[511:0] <= sc2buf_wt_rd_data[511:0];

      // Stripe signals
      stripe_start <= (kernel_count[12:0] == 13'd0) && (channel_group_count[31:0] == 32'd0);
      stripe_end_signal <= (channel_group_count[31:0] == (channel_group_num[31:0] - 32'd1));
      channel_end_signal <= (channel_group_count[31:0] == (channel_group_num[31:0] - 32'd1));
      layer_end_signal <= (kernel_count[12:0] == (kernel_num[12:0] - 13'd1)) &&
                          (channel_group_count[31:0] == (channel_group_num[31:0] - 32'd1));

      csc2mac_wt_a_stripe_st <= stripe_start;
      csc2mac_wt_a_stripe_end <= stripe_end_signal;
      csc2mac_wt_a_channel_end <= channel_end_signal;
      csc2mac_wt_a_layer_end <= layer_end_signal;
      csc2mac_wt_b_stripe_st <= stripe_start;
      csc2mac_wt_b_stripe_end <= stripe_end_signal;
      csc2mac_wt_b_channel_end <= channel_end_signal;
      csc2mac_wt_b_layer_end <= layer_end_signal;
    end else begin
      csc2mac_wt_a_stripe_st <= 1'b0;
      csc2mac_wt_a_stripe_end <= 1'b0;
      csc2mac_wt_a_channel_end <= 1'b0;
      csc2mac_wt_a_layer_end <= 1'b0;
      csc2mac_wt_b_stripe_st <= 1'b0;
      csc2mac_wt_b_stripe_end <= 1'b0;
      csc2mac_wt_b_channel_end <= 1'b0;
      csc2mac_wt_b_layer_end <= 1'b0;
    end
  end
end

endmodule // NV_NVDLA_CSC_weight_proc_new