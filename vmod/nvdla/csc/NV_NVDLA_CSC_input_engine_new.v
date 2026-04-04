// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_input_engine_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSC Input Engine module
// - Reads input feature maps from CBUF (Connection Buffer)
// - Handles direct convolution and Winograd modes
// - Sends data to CMAC A and CMAC B ports
// - Manages stripe-based data flow with batch support
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_input_engine_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  ,reg2dp_op_en                   //|< i
  ,reg2dp_conv_mode               //|< i
  ,reg2dp_proc_precision          //|< i  [1:0]
  ,reg2dp_datain_format           //|< i
  ,reg2dp_datain_width_ext        //|< i  [12:0]
  ,reg2dp_datain_height_ext       //|< i  [12:0]
  ,reg2dp_datain_channel_ext      //|< i  [12:0]
  ,reg2dp_dataout_width           //|< i  [12:0]
  ,reg2dp_dataout_height          //|< i  [12:0]
  ,reg2dp_dataout_channel         //|< i  [12:0]
  ,reg2dp_weight_width_ext        //|< i  [4:0]
  ,reg2dp_weight_height_ext       //|< i  [4:0]
  ,reg2dp_conv_x_stride_ext       //|< i  [2:0]
  ,reg2dp_conv_y_stride_ext       //|< i  [2:0]
  ,reg2dp_x_dilation_ext          //|< i  [4:0]
  ,reg2dp_y_dilation_ext          //|< i  [4:0]
  ,reg2dp_pad_left                //|< i  [4:0]
  ,reg2dp_pad_top                 //|< i  [4:0]
  ,reg2dp_pad_value               //|< i  [15:0]
  ,reg2dp_batches                 //|< i  [4:0]
  ,reg2dp_entries                 //|< i  [11:0]
  ,reg2dp_data_bank               //|< i  [3:0]
  ,reg2dp_y_extension             //|< i  [1:0]
  ,sc2buf_dat_rd_en               //|> o
  ,sc2buf_dat_rd_addr             //|> o  [11:0]
  ,sc2buf_dat_rd_valid            //|< i
  ,sc2buf_dat_rd_data             //|< i  [511:0]
  ,sc2mac_dat_a_pvld              //|> o
  ,sc2mac_dat_a_mask              //|> o  [127:0]
  ,sc2mac_dat_a_pd                //|> o
  ,sc2mac_dat_b_pvld              //|> o
  ,sc2mac_dat_b_mask              //|> o  [127:0]
  ,sc2mac_dat_b_pd                //|> o
  ,cdma2sc_dat_updt               //|< i
  ,cdma2sc_dat_entries            //|< i  [11:0]
  ,cdma2sc_dat_slices             //|< i  [12:0]
  ,sc2cdma_dat_updt               //|> o
  ,sc2cdma_dat_entries            //|> o  [11:0]
  ,sc2cdma_dat_slices             //|> o  [12:0]
  ,sc2cdma_dat_pending_req        //|> o
  ,csc2mac_dat_a_stripe_st        //|> o
  ,csc2mac_dat_a_stripe_end       //|> o
  ,csc2mac_dat_a_channel_end      //|> o
  ,csc2mac_dat_a_layer_end        //|> o
  ,csc2mac_dat_b_stripe_st        //|> o
  ,csc2mac_dat_b_stripe_end       //|> o
  ,csc2mac_dat_b_channel_end      //|> o
  ,csc2mac_dat_b_layer_end        //|> o
  );

//==========================================
// Parameters
//==========================================
parameter DATA_FORMAT_INT8  = 2'b00;
parameter DATA_FORMAT_INT16 = 2'b01;
parameter DATA_FORMAT_FP16  = 2'b10;

parameter CONV_MODE_DIRECT   = 1'b0;
parameter CONV_MODE_WINOGRAD  = 1'b1;

parameter DATA_FORMAT_FEATURE = 1'b0;
parameter DATA_FORMAT_PIXEL    = 1'b1;

parameter ATOMIC_CUBES         = 21'd1;
parameter PARALLEL_CHANNEL_NUM = 64;
parameter CBUF_ENTRY_SIZE      = 64;
parameter ATOM_CUBE_SIZE       = 64;

// State machine
parameter [2:0] ST_IDLE        = 3'd0;
parameter [2:0] ST_WAIT_CBUF   = 3'd1;
parameter [2:0] ST_SEND_DATA   = 3'd2;
parameter [2:0] ST_WAIT_ACCU   = 3'd3;
parameter [2:0] ST_DONE        = 3'd4;

//==========================================
// Ports
//==========================================
input         nvdla_core_clk;
input         nvdla_core_rstn;
input         reg2dp_op_en;
input         reg2dp_conv_mode;
input  [1:0]  reg2dp_proc_precision;
input         reg2dp_datain_format;
input  [12:0] reg2dp_datain_width_ext;
input  [12:0] reg2dp_datain_height_ext;
input  [12:0] reg2dp_datain_channel_ext;
input  [12:0] reg2dp_dataout_width;
input  [12:0] reg2dp_dataout_height;
input  [12:0] reg2dp_dataout_channel;
input  [4:0]  reg2dp_weight_width_ext;
input  [4:0]  reg2dp_weight_height_ext;
input  [2:0]  reg2dp_conv_x_stride_ext;
input  [2:0]  reg2dp_conv_y_stride_ext;
input  [4:0]  reg2dp_x_dilation_ext;
input  [4:0]  reg2dp_y_dilation_ext;
input  [4:0]  reg2dp_pad_left;
input  [4:0]  reg2dp_pad_top;
input  [15:0] reg2dp_pad_value;
input  [4:0]  reg2dp_batches;
input  [11:0] reg2dp_entries;
input  [3:0]  reg2dp_data_bank;
input  [1:0]  reg2dp_y_extension;

output        sc2buf_dat_rd_en;
output [11:0] sc2buf_dat_rd_addr;
input         sc2buf_dat_rd_valid;
input  [511:0] sc2buf_dat_rd_data;

output        sc2mac_dat_a_pvld;
output [127:0] sc2mac_dat_a_mask;
output        sc2mac_dat_a_pd;
output        sc2mac_dat_b_pvld;
output [127:0] sc2mac_dat_b_mask;
output        sc2mac_dat_b_pd;

input         cdma2sc_dat_updt;
input  [11:0] cdma2sc_dat_entries;
input  [12:0] cdma2sc_dat_slices;
output        sc2cdma_dat_updt;
output [11:0] sc2cdma_dat_entries;
output [12:0] sc2cdma_dat_slices;
output        sc2cdma_dat_pending_req;

output        csc2mac_dat_a_stripe_st;
output        csc2mac_dat_a_stripe_end;
output        csc2mac_dat_a_channel_end;
output        csc2mac_dat_a_layer_end;
output        csc2mac_dat_b_stripe_st;
output        csc2mac_dat_b_stripe_end;
output        csc2mac_dat_b_channel_end;
output        csc2mac_dat_b_layer_end;

//==========================================
// Internal signals
//==========================================
// State machine
reg  [2:0] state_q;
reg  [2:0] next_state;

// Counters
reg  [12:0] slice_idx_free;
reg  [12:0] slice_idx_available;
reg  [11:0] data_entry_idx_free;
reg  [11:0] data_entry_idx_available;
reg  [31:0] stripe_count;
reg  [31:0] super_channel_count;
reg  [31:0] kernel_atom_count;
reg  [31:0] output_atom_count;
reg  [4:0]  batch_count;

// Computed values
wire [12:0] cube_in_width;
wire [12:0] cube_in_height;
wire [12:0] cube_in_channel;
wire [12:0] cube_out_width;
wire [12:0] cube_out_height;
wire [12:0] cube_out_channel;
wire [4:0]  kernel_width;
wire [4:0]  kernel_height;
wire [4:0]  batch_num;
wire [11:0] cbuf_entry_per_slice;
wire [31:0] cbuf_entry_for_data;
wire [31:0] element_per_atom;
wire [31:0] out_surface_num;
wire [31:0] stripe_num;
wire [31:0] super_channel_num;
wire [31:0] kernel_atom_num;
wire [31:0] ideal_stripe_length;
wire [31:0] last_stripe_length;
wire [31:0] current_stripe_length;

// Stripe info
reg         stripe_st;
reg         stripe_end;
reg         channel_end;
reg         layer_end;

// Input coordinate calculation
reg  [12:0] output_atom_coor_width;
reg  [12:0] output_atom_coor_height;
reg  [12:0] input_atom_coor_width;
reg  [12:0] input_atom_coor_height;
reg  [4:0]  kernel_atom_coor_width;
reg  [4:0]  kernel_atom_coor_height;
wire        is_padding;
wire [11:0] cbuf_rd_addr;

// Data output
reg  [127:0] sc2mac_dat_a_mask;
reg  [127:0] sc2mac_dat_b_mask;
reg         sc2mac_dat_a_pvld;
reg         sc2mac_dat_b_pvld;
reg         sc2mac_dat_a_pd;
reg         sc2mac_dat_b_pd;

// CDMA interface
reg         sc2cdma_dat_updt;
reg  [11:0] sc2cdma_dat_entries;
reg  [12:0] sc2cdma_dat_slices;
reg         sc2cdma_dat_pending_req;

// CBUF interface
reg         sc2buf_dat_rd_en;
reg  [11:0] sc2buf_dat_rd_addr;

// Accu credit
reg  [7:0]  accu_credit;
parameter ACCU_CREDIT_INIT = 8'd32;

//==========================================
// Compute cube dimensions from register values
//==========================================
assign cube_in_width[12:0]   = reg2dp_datain_width_ext[12:0] + 13'd1;
assign cube_in_height[12:0]  = reg2dp_datain_height_ext[12:0] + 13'd1;
assign cube_in_channel[12:0] = reg2dp_datain_channel_ext[12:0] + 13'd1;
assign cube_out_width[12:0]  = reg2dp_dataout_width[12:0] + 13'd1;
assign cube_out_height[12:0] = reg2dp_dataout_height[12:0] + 13'd1;
assign cube_out_channel[12:0] = reg2dp_dataout_channel[12:0] + 13'd1;
assign kernel_width[4:0]     = reg2dp_weight_width_ext[4:0] + 5'd1;
assign kernel_height[4:0]    = reg2dp_weight_height_ext[4:0] + 5'd1;
assign batch_num[4:0]        = reg2dp_batches[4:0] + 5'd1;

// Element per atom based on precision
assign element_per_atom[31:0] =
    (reg2dp_proc_precision == DATA_FORMAT_INT8)  ? 32'd64 :
    (reg2dp_proc_precision == DATA_FORMAT_INT16) ? 32'd32 :
    (reg2dp_proc_precision == DATA_FORMAT_FP16)   ? 32'd32 : 32'd32;

// Compute entries per slice
wire [11:0] atom_per_channel;
assign atom_per_channel[11:0] = (cube_in_channel[12:0] * element_per_atom[31:0] + ATOM_CUBE_SIZE - 1) / ATOM_CUBE_SIZE;

assign cbuf_entry_per_slice[11:0] = (atom_per_channel[11:0] / 4) * cube_in_width[12:0];
assign cbuf_entry_for_data[31:0]   = (reg2dp_data_bank[3:0] + 4'd1) * 12'd256;

// Output surface and stripe calculations
assign out_surface_num[31:0]   = (cube_out_channel[12:0] + element_per_atom[31:0] - 1) / element_per_atom[31:0];
assign super_channel_num[31:0] = (cube_in_channel[12:0] + PARALLEL_CHANNEL_NUM - 1) / PARALLEL_CHANNEL_NUM;
assign kernel_atom_num[31:0]  = kernel_height[4:0] * kernel_width[4:0];

// Ideal stripe length lookup
wire [5:0] stripe_length_per_batch;
assign stripe_length_per_batch =
    (batch_num[4:0] <= 5'd1)  ? 6'd16 :
    (batch_num[4:0] <= 5'd2)  ? 6'd8  :
    (batch_num[4:0] <= 5'd4)  ? 6'd4  :
    (batch_num[4:0] <= 5'd8)  ? 6'd2  : 6'd1;

assign ideal_stripe_length[31:0] = {26'd0, stripe_length_per_batch[5:0]};

wire [31:0] output_atom_num;
assign output_atom_num[31:0] = cube_out_height[12:0] * cube_out_width[12:0];

wire [31:0] first_stripe_length;
wire [31:0] second_stripe_length;
assign first_stripe_length[31:0] = (output_atom_num[31:0] >= 2 * ideal_stripe_length[31:0]) ? ideal_stripe_length[31:0] : output_atom_num[31:0];
assign second_stripe_length[31:0] = (output_atom_num[31:0] >= 2 * ideal_stripe_length[31:0]) ?
                                    ((output_atom_num[31:0] % ideal_stripe_length[31:0]) == 0 ? ideal_stripe_length[31:0] : (output_atom_num[31:0] % ideal_stripe_length[31:0])) :
                                    output_atom_num[31:0];

assign last_stripe_length[31:0] = (first_stripe_length[31:0] >= second_stripe_length[31:0]) ?
                                   first_stripe_length[31:0] : second_stripe_length[31:0];

assign stripe_num[31:0] = (output_atom_num[31:0] - last_stripe_length[31:0]) / ideal_stripe_length[31:0] + 32'd1;

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
        next_state[2:0] = ST_WAIT_CBUF;
    end
    ST_WAIT_CBUF: begin
      if (slice_idx_available[12:0] >= 13'd1)
        next_state[2:0] = ST_SEND_DATA;
    end
    ST_SEND_DATA: begin
      if (layer_end)
        next_state[2:0] = ST_DONE;
      else if (accu_credit[7:0] == 8'd0)
        next_state[2:0] = ST_WAIT_ACCU;
    end
    ST_WAIT_ACCU: begin
      if (accu_credit[7:0] > 8'd0)
        next_state[2:0] = ST_SEND_DATA;
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
    slice_idx_free[12:0] <= 13'd0;
    slice_idx_available[12:0] <= 13'd0;
    data_entry_idx_free[11:0] <= 12'd0;
    data_entry_idx_available[11:0] <= 12'd0;
    stripe_count[31:0] <= 32'd0;
    super_channel_count[31:0] <= 32'd0;
    kernel_atom_count[31:0] <= 32'd0;
    output_atom_count[31:0] <= 32'd0;
    batch_count[4:0] <= 5'd0;
    accu_credit[7:0] <= ACCU_CREDIT_INIT;
  end else begin
    case (state_q[2:0])
      ST_IDLE: begin
        slice_idx_free[12:0] <= 13'd0;
        slice_idx_available[12:0] <= 13'd0;
        data_entry_idx_free[11:0] <= 12'd0;
        data_entry_idx_available[11:0] <= 12'd0;
        stripe_count[31:0] <= 32'd0;
        super_channel_count[31:0] <= 32'd0;
        kernel_atom_count[31:0] <= 32'd0;
        output_atom_count[31:0] <= 32'd0;
        batch_count[4:0] <= 5'd0;
        accu_credit[7:0] <= ACCU_CREDIT_INIT;
      end
      ST_WAIT_CBUF: begin
        if (cdma2sc_dat_updt) begin
          slice_idx_available[12:0] <= slice_idx_available[12:0] + cdma2sc_dat_slices[12:0];
          data_entry_idx_available[11:0] <= data_entry_idx_available[11:0] + cdma2sc_dat_entries[11:0];
        end
      end
      ST_SEND_DATA: begin
        // Update counters on valid send
        if (sc2mac_dat_a_pvld) begin
          // Compute current stripe length
          if (stripe_count[31:0] < (stripe_num[31:0] - 32'd1))
            current_stripe_length[31:0] = ideal_stripe_length[31:0];
          else
            current_stripe_length[31:0] = last_stripe_length[31:0];

          // Increment output atom count
          output_atom_count[31:0] <= output_atom_count[31:0] + 32'd1;

          // Check if stripe is complete
          if (output_atom_count[31:0] == (current_stripe_length[31:0] - 32'd1)) begin
            output_atom_count[31:0] <= 32'd0;
            stripe_count[31:0] <= stripe_count[31:0] + 32'd1;
          end

          // Increment batch counter
          if (batch_count[4:0] == (batch_num[4:0] - 5'd1)) begin
            batch_count[4:0] <= 5'd0;
          end else begin
            batch_count[4:0] <= batch_count[4:0] + 5'd1;
          end

          // Channel and kernel atom tracking
          if (kernel_atom_count[31:0] == (kernel_atom_num[31:0] - 32'd1)) begin
            kernel_atom_count[31:0] <= 32'd0;
            if (super_channel_count[31:0] == (super_channel_num[31:0] - 32'd1)) begin
              super_channel_count[31:0] <= 32'd0;
            end else begin
              super_channel_count[31:0] <= super_channel_count[31:0] + 32'd1;
            end
          end else begin
            kernel_atom_count[31:0] <= kernel_atom_count[31:0] + 32'd1;
          end

          // Credit management
          if (stripe_end && channel_end) begin
            accu_credit[7:0] <= accu_credit[7:0] - 8'd1;
          end
        end

        // Release slices at end of processing
        if (layer_end) begin
          sc2cdma_dat_updt <= 1'b1;
          sc2cdma_dat_slices[12:0] <= slice_idx_free[12:0];
          sc2cdma_dat_entries[11:0] <= data_entry_idx_free[11:0];
          slice_idx_available[12:0] <= 13'd0;
          data_entry_idx_available[11:0] <= 12'd0;
        end
      end
      ST_DONE: begin
        sc2cdma_dat_updt <= 1'b0;
      end
    endcase
  end
end

//==========================================
// Coordinate calculations
//==========================================
wire [31:0] current_stripe_length_w;
assign current_stripe_length_w[31:0] = (stripe_count[31:0] < (stripe_num[31:0] - 32'd1)) ?
                                        ideal_stripe_length[31:0] : last_stripe_length[31:0];

always @(*) begin
  output_atom_coor_width[12:0] = output_atom_count[31:0] % cube_out_width[12:0];
  output_atom_coor_height[12:0] = output_atom_count[31:0] / cube_out_width[12:0];
end

always @(*) begin
  kernel_atom_coor_width[4:0] = kernel_atom_count[31:0] % kernel_width[4:0];
  kernel_atom_coor_height[4:0] = kernel_atom_count[31:0] / kernel_width[4:0];
end

always @(*) begin
  input_atom_coor_width[12:0] = output_atom_coor_width[12:0] * {9'd0, reg2dp_conv_x_stride_ext[2:0]} +
                                  kernel_atom_coor_width[4:0] * {10'd0, reg2dp_x_dilation_ext[4:0]} -
                                  {9'd0, reg2dp_pad_left[4:0]};
  input_atom_coor_height[12:0] = output_atom_coor_height[12:0] * {9'd0, reg2dp_conv_y_stride_ext[2:0]} +
                                  kernel_atom_coor_height[4:0] * {10'd0, reg2dp_y_dilation_ext[4:0]} -
                                  {9'd0, reg2dp_pad_top[4:0]};
end

assign is_padding = (input_atom_coor_width[12:0] < 13'd0) ||
                     (input_atom_coor_height[12:0] < 13'd0) ||
                     (input_atom_coor_width[12:0] >= cube_in_width[12:0]) ||
                     (input_atom_coor_height[12:0] >= cube_in_height[12:0]);

//==========================================
// CBUF address calculation
//==========================================
assign cbuf_rd_addr[11:0] = (data_entry_idx_free[11:0] +
                             (input_atom_coor_height[12:0] * batch_num[4:0] + batch_count[4:0]) * cbuf_entry_per_slice[11:0] +
                             cube_in_width[12:0] * super_channel_count[31:0] +
                             input_atom_coor_width[12:0]) % cbuf_entry_for_data[11:0];

//==========================================
// CBUF read control
//==========================================
always @(*) begin
  sc2buf_dat_rd_en <= 1'b0;
  sc2buf_dat_rd_addr[11:0] <= 12'd0;

  if (state_q[2:0] == ST_SEND_DATA && !is_padding) begin
    sc2buf_dat_rd_en <= 1'b1;
    sc2buf_dat_rd_addr[11:0] <= cbuf_rd_addr[11:0];
  end
end

//==========================================
// Data output to CMAC
//==========================================
assign csc2mac_dat_a_stripe_st = stripe_st;
assign csc2mac_dat_a_stripe_end = stripe_end;
assign csc2mac_dat_a_channel_end = channel_end;
assign csc2mac_dat_a_layer_end = layer_end;
assign csc2mac_dat_b_stripe_st = stripe_st;
assign csc2mac_dat_b_stripe_end = stripe_end;
assign csc2mac_dat_b_channel_end = channel_end;
assign csc2mac_dat_b_layer_end = layer_end;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    sc2mac_dat_a_pvld <= 1'b0;
    sc2mac_dat_b_pvld <= 1'b0;
    sc2mac_dat_a_pd <= 1'b0;
    sc2mac_dat_b_pd <= 1'b0;
    sc2mac_dat_a_mask[127:0] <= {128{1'b0}};
    sc2mac_dat_b_mask[127:0] <= {128{1'b0}};
    stripe_st <= 1'b0;
    stripe_end <= 1'b0;
    channel_end <= 1'b0;
    layer_end <= 1'b0;
  end else begin
    sc2mac_dat_a_pvld <= 1'b0;
    sc2mac_dat_b_pvld <= 1'b0;

    if (state_q[2:0] == ST_SEND_DATA) begin
      // First atom of stripe
      stripe_st <= (output_atom_count[31:0] == 32'd0) && (batch_count[4:0] == 5'd0) &&
                   (super_channel_count[31:0] == 32'd0) && (kernel_atom_count[31:0] == 32'd0);

      // Last atom of stripe
      stripe_end <= (output_atom_count[31:0] == (current_stripe_length_w[31:0] - 32'd1)) &&
                    (batch_count[4:0] == (batch_num[4:0] - 5'd1));

      // Last super channel
      channel_end <= (kernel_atom_count[31:0] == (kernel_atom_num[31:0] - 32'd1)) &&
                     (super_channel_count[31:0] == (super_channel_num[31:0] - 32'd1));

      // Last output surface
      layer_end <= (stripe_count[31:0] == (stripe_num[31:0] - 32'd1)) &&
                   (output_atom_count[31:0] == (last_stripe_length[31:0] - 32'd1)) &&
                   (batch_count[4:0] == (batch_num[4:0] - 5'd1)) &&
                   (kernel_atom_count[31:0] == (kernel_atom_num[31:0] - 32'd1)) &&
                   (super_channel_count[31:0] == (super_channel_num[31:0] - 32'd1));

      // Send data valid
      sc2mac_dat_a_pvld <= 1'b1;
      sc2mac_dat_b_pvld <= 1'b1;
      sc2mac_dat_a_pd <= 1'b1;
      sc2mac_dat_b_pd <= 1'b1;

      // Generate mask based on precision
      if (reg2dp_proc_precision == DATA_FORMAT_INT8) begin
        sc2mac_dat_a_mask[127:0] <= {128{1'b1}};
        sc2mac_dat_b_mask[127:0] <= {128{1'b1}};
      end else begin
        sc2mac_dat_a_mask[127:0] <= {128{1'b1}};
        sc2mac_dat_b_mask[127:0] <= {128{1'b1}};
      end
    end else begin
      stripe_st <= 1'b0;
      stripe_end <= 1'b0;
      channel_end <= 1'b0;
    end
  end
end

//==========================================
// CDMA interface
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    sc2cdma_dat_updt <= 1'b0;
    sc2cdma_dat_pending_req <= 1'b0;
  end else begin
    sc2cdma_dat_pending_req <= (slice_idx_available[12:0] < (batch_num[4:0] * cube_in_height[12:0]));
  end
end

endmodule // NV_NVDLA_CSC_input_engine_new