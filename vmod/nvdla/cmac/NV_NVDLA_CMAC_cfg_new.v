// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_cfg_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Configuration logic for CMAC
// - State machine for operation coordination
// - Clock gating control (SLCG)
// - Layer/stripe processing control
// +FHDR------------------------------------------------------------

module NV_NVDLA_CMAC_cfg_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,reg2dp_op_en
  ,reg2dp_conv_mode
  ,reg2dp_proc_precision
  ,mac2accu_pvld
  ,cfg2mac_op_en
  ,cfg2mac_conv_mode
  ,cfg2mac_proc_precision
  ,cfg2mac_dat_pvld
  ,cfg2mac_wt_pvld
  ,cfg2mac_done
  ,dp2reg_done
  ,slcg_op_en
  ,tmc2slcg_disable_clock_gating
  );

//==============================================================
// Port declarations
//==============================================================
input        nvdla_core_clk;
input        nvdla_core_rstn;

// From register file
input        reg2dp_op_en;
input        reg2dp_conv_mode;
input  [1:0] reg2dp_proc_precision;

// From MAC
input        mac2accu_pvld;

// To MAC
output       cfg2mac_op_en;
output       cfg2mac_conv_mode;
output [1:0] cfg2mac_proc_precision;
output       cfg2mac_dat_pvld;
output       cfg2mac_wt_pvld;

// To register file
output       dp2reg_done;

// Clock gating
output [10:0] slcg_op_en;
input         tmc2slcg_disable_clock_gating;

//==============================================================
// State machine
//==============================================================
localparam STATE_IDLE    = 2'b00;
localparam STATE_WORKING = 2'b01;
localparam STATE_DONE    = 2'b10;

reg [1:0] state_r;
reg [1:0] next_state;

// Operation enable tracking
reg op_en_r;
reg op_en_delay1_r;
reg op_en_delay2_r;
reg op_en_delay3_r;

//==============================================================
// State register
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_r <= STATE_IDLE;
  end else begin
    state_r <= next_state;
  end
end

//==============================================================
// Next state logic
//==============================================================
always @* begin
  next_state = state_r;
  case (state_r)
    STATE_IDLE: begin
      if (reg2dp_op_en) begin
        next_state = STATE_WORKING;
      end
    end

    STATE_WORKING: begin
      if (mac2accu_pvld) begin
        next_state = STATE_DONE;
      end
    end

    STATE_DONE: begin
      next_state = STATE_IDLE;
    end

    default: next_state = STATE_IDLE;
  endcase
end

//==============================================================
// Operation enable pipeline
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_r        <= 1'b0;
    op_en_delay1_r <= 1'b0;
    op_en_delay2_r <= 1'b0;
    op_en_delay3_r <= 1'b0;
  end else begin
    op_en_r        <= reg2dp_op_en;
    op_en_delay1_r <= op_en_r;
    op_en_delay2_r <= op_en_delay1_r;
    op_en_delay3_r <= op_en_delay2_r;
  end
end

//==============================================================
// Output assignments
//==============================================================
assign cfg2mac_op_en = op_en_delay3_r;
assign cfg2mac_conv_mode = reg2dp_conv_mode;
assign cfg2mac_proc_precision = reg2dp_proc_precision;

// Data/weight valid follows op_en
assign cfg2mac_dat_pvld = op_en_delay2_r;
assign cfg2mac_wt_pvld = op_en_delay1_r;

// Done pulse to register file
assign dp2reg_done = (state_r == STATE_DONE);

//==============================================================
// Clock gating control (SLCG - Smart Clock Gating)
//==============================================================
// SLCG op_en is delayed 3 cycles to align with data pipeline
assign slcg_op_en = {11{op_en_delay3_r}};

endmodule // NV_NVDLA_CMAC_cfg_new