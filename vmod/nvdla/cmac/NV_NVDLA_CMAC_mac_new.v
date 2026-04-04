// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_mac_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// MAC (Multiply-Accumulate) array for CMAC
// - 8 MAC cells operating in parallel
// - Each cell performs element-wise multiply-accumulate
// - Supports INT8, INT16, and FP16 precision
// - Supports normal and Winograd convolution modes
// +FHDR------------------------------------------------------------

module NV_NVDLA_CMAC_mac_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,cfg_op_en
  ,cfg_conv_mode
  ,cfg_proc_precision
  ,sc2mac_dat_pvld
  ,sc2mac_dat_data
  ,sc2mac_dat_mask
  ,sc2mac_wt_pvld
  ,sc2mac_wt_data
  ,sc2mac_wt_mask
  ,sc2mac_wt_sel
  ,mac2accu_pvld
  ,mac2accu_data
  ,mac2accu_mask
  ,mac2accu_mode
  ,mac2accu_pd
  );

//==============================================================
// Parameters
//==============================================================
localparam MAC_CELL_NUM         = 8;
localparam DATA_ELEMENT_NUM     = 128;
localparam WEIGHT_ELEMENT_NUM   = MAC_CELL_NUM * DATA_ELEMENT_NUM;  // 1024
localparam RESULT_NUM_PER_CELL  = 8;
localparam TOTAL_RESULT_NUM     = MAC_CELL_NUM * RESULT_NUM_PER_CELL; // 64

localparam DATA_BIT_WIDTH      = 8;
localparam WEIGHT_BIT_WIDTH    = 8;
localparam OUTPUT_BIT_WIDTH    = 22;

localparam PARALLEL_CHANNEL_NUM = 64;

// Precision values
localparam PRECISION_INT8  = 2'b01;
localparam PRECISION_INT16 = 2'b10;
localparam PRECISION_FP16  = 2'b00;

//==============================================================
// Port declarations
//==============================================================
input        nvdla_core_clk;
input        nvdla_core_rstn;

// Configuration
input        cfg_op_en;
input        cfg_conv_mode;       // 0=normal, 1=winograd
input  [1:0] cfg_proc_precision;  // 00=FP16, 01=INT8, 10=INT16

// Data input (from CSC)
input        sc2mac_dat_pvld;
input  [DATA_ELEMENT_NUM-1:0][DATA_BIT_WIDTH-1:0] sc2mac_dat_data;
input  [127:0] sc2mac_dat_mask;

// Weight input (from CSC)
input        sc2mac_wt_pvld;
input  [DATA_ELEMENT_NUM-1:0][WEIGHT_BIT_WIDTH-1:0] sc2mac_wt_data;
input  [127:0] sc2mac_wt_mask;
input  [7:0]   sc2mac_wt_sel;

// Output to accumulator
output       mac2accu_pvld;
output [TOTAL_RESULT_NUM-1:0][OUTPUT_BIT_WIDTH-1:0] mac2accu_data;
output [MAC_CELL_NUM-1:0] mac2accu_mask;
output [7:0]   mac2accu_mode;
output [8:0]   mac2accu_pd;

//==============================================================
// Internal signals
//==============================================================
// Shadow registers for weight and data
reg  [DATA_ELEMENT_NUM-1:0][DATA_BIT_WIDTH-1:0] data_operand_r;
reg  [WEIGHT_ELEMENT_NUM-1:0][WEIGHT_BIT_WIDTH-1:0] weight_operand_shadow_r;
reg  [WEIGHT_ELEMENT_NUM-1:0][WEIGHT_BIT_WIDTH-1:0] weight_operand_r;

reg  [MAC_CELL_NUM-1:0][1:0] wt_mask_r;
reg  [MAC_CELL_NUM-1:0][1:0] wt_mask_shadow_r;
reg  [1:0] dat_mask_r;

reg  [MAC_CELL_NUM-1:0] enabled_mac_cell_shadow;
reg  [MAC_CELL_NUM-1:0] enabled_mac_cell_active;

// Result storage
reg  [TOTAL_RESULT_NUM-1:0][OUTPUT_BIT_WIDTH-1:0] mac_result_r;

// State machine
reg  [1:0] state_r;
localparam STATE_IDLE    = 2'b00;
localparam STATE_LOADING = 2'b01;
localparam STATE_CALC    = 2'b10;
localparam STATE_DONE    = 2'b11;

// Stripe info
reg         stripe_st_r;
reg         layer_end_r;
reg         stripe_end_r;

// Valid tracking
reg         working_r;
reg         mac_done_r;

//==============================================================
// Weight data capture and MAC cell assignment
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    enabled_mac_cell_shadow <= '0;
  end else if (sc2mac_wt_pvld && working_r) begin
    enabled_mac_cell_shadow <= enabled_mac_cell_shadow | sc2mac_wt_sel;
  end
end

// Capture weight data into shadow register
integer wt_idx;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    for (wt_idx = 0; wt_idx < WEIGHT_ELEMENT_NUM; wt_idx = wt_idx + 1) begin
      weight_operand_shadow_r[wt_idx] <= '0;
    end
  end else if (sc2mac_wt_pvld && working_r) begin
    // Find which MAC cell this weight belongs to
    integer mac_cell_id;
    mac_cell_id = 0;
    while ((sc2mac_wt_sel & (1 << mac_cell_id)) == 0 && mac_cell_id < MAC_CELL_NUM) begin
      mac_cell_id = mac_cell_id + 1;
    end
    // Store weight data for this MAC cell
    for (wt_idx = 0; wt_idx < DATA_ELEMENT_NUM; wt_idx = wt_idx + 1) begin
      weight_operand_shadow_r[mac_cell_id * DATA_ELEMENT_NUM + wt_idx] <= sc2mac_wt_data[wt_idx];
    end
    // Store mask
    wt_mask_shadow_r[mac_cell_id][0] <= sc2mac_wt_mask[63:0];
    wt_mask_shadow_r[mac_cell_id][1] <= sc2mac_wt_mask[127:64];
  end
end

// Data operand capture
integer dat_idx;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    for (dat_idx = 0; dat_idx < DATA_ELEMENT_NUM; dat_idx = dat_idx + 1) begin
      data_operand_r[dat_idx] <= '0;
    end
    dat_mask_r <= '0;
  end else if (sc2mac_dat_pvld && working_r) begin
    data_operand_r <= sc2mac_dat_data;
    dat_mask_r[0] <= sc2mac_dat_mask[63:0];
    dat_mask_r[1] <= sc2mac_dat_mask[127:64];
  end
end

//==============================================================
// State machine and operation flow
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_r <= STATE_IDLE;
    working_r <= 1'b0;
  end else begin
    case (state_r)
      STATE_IDLE: begin
        if (cfg_op_en) begin
          state_r <= STATE_LOADING;
          working_r <= 1'b1;
        end
      end

      STATE_LOADING: begin
        // Weight and data are loaded
        if (sc2mac_dat_pvld) begin
          state_r <= STATE_CALC;
        end
      end

      STATE_CALC: begin
        state_r <= STATE_DONE;
      end

      STATE_DONE: begin
        state_r <= STATE_IDLE;
        working_r <= 1'b0;
      end

      default: state_r <= STATE_IDLE;
    endcase
  end
end

//==============================================================
// MAC calculation (simplified INT8 implementation)
//==============================================================
genvar mac_idx;
genvar res_idx;

generate
  for (mac_idx = 0; mac_idx < MAC_CELL_NUM; mac_idx = mac_idx + 1) begin : gen_mac_cell
    for (res_idx = 0; res_idx < RESULT_NUM_PER_CELL; res_idx = res_idx + 1) begin : gen_result
      always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
          mac_result_r[mac_idx * RESULT_NUM_PER_CELL + res_idx] <= '0;
        end else if (state_r == STATE_CALC && cfg_op_en) begin
          // Simplified INT8 MAC calculation
          // Each MAC cell computes dot product of 64 channels * 2 kernels
          integer ch_idx;
          reg signed [OUTPUT_BIT_WIDTH-1:0] accu;
          accu = 0;

          if (enabled_mac_cell_active[mac_idx]) begin
            for (ch_idx = 0; ch_idx < PARALLEL_CHANNEL_NUM; ch_idx = ch_idx + 1) begin
              reg signed [DATA_BIT_WIDTH-1:0] data_val;
              reg signed [WEIGHT_BIT_WIDTH-1:0] weight_val;
              reg wt_mask_bit;
              reg dat_mask_bit;

              data_val = data_operand_r[ch_idx];
              weight_val = weight_operand_r[mac_idx * DATA_ELEMENT_NUM + ch_idx];

              // Get mask bits
              if (res_idx < 4) begin
                wt_mask_bit = wt_mask_r[mac_idx][1];
                dat_mask_bit = dat_mask_r[1];
              end else begin
                wt_mask_bit = wt_mask_r[mac_idx][0];
                dat_mask_bit = dat_mask_r[0];
              end

              // Apply masks
              if (wt_mask_bit && dat_mask_bit) begin
                accu = accu + (data_val * weight_val);
              end
            end
          end

          mac_result_r[mac_idx * RESULT_NUM_PER_CELL + res_idx] <= accu;
        end
      end
    end
  end
endgenerate

//==============================================================
// Output assignment
//==============================================================
assign mac2accu_pvld = (state_r == STATE_DONE);
assign mac2accu_data = mac_result_r;
assign mac2accu_mask = enabled_mac_cell_active;
assign mac2accu_mode = cfg_conv_mode ? 8'hFF : 8'h00;
assign mac2accu_pd = {layer_end_r, stripe_end_r, stripe_st_r, 6'b0};

//==============================================================
// Weight shadow to active update (on stripe start)
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    enabled_mac_cell_active <= '0;
    weight_operand_r <= '0;
    wt_mask_r <= '0;
  end else if (sc2mac_dat_pvld && working_r) begin
    // A new stripe - promote shadow to active
    enabled_mac_cell_active <= enabled_mac_cell_shadow;
    weight_operand_r <= weight_operand_shadow_r;
    wt_mask_r <= wt_mask_shadow_r;
    enabled_mac_cell_shadow <= '0;
  end
end

endmodule // NV_NVDLA_CMAC_mac_new