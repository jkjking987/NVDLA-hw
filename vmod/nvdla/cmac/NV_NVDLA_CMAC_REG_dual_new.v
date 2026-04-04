// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_REG_dual_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Dual register group for CMAC (banked for double buffering)
// - D_OP_ENABLE: Operation enable
// - D_MISC_CFG: Conv mode and processing precision
// +FHDR------------------------------------------------------------

module NV_NVDLA_CMAC_REG_dual_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,reg_wr_en
  ,reg_offset
  ,reg_wr_data
  ,reg_rd_data
  ,conv_mode
  ,proc_precision
  ,op_en
  ,op_en_trigger
  );

//==============================================================
// Port declarations
//==============================================================
input        nvdla_core_clk;
input        nvdla_core_rstn;
input        reg_wr_en;
input  [11:0] reg_offset;
input  [31:0] reg_wr_data;
output [31:0] reg_rd_data;
output       conv_mode;
output [1:0] proc_precision;
output       op_en;
output       op_en_trigger;

//==============================================================
// Parameters
//==============================================================
localparam ADDR_OP_ENABLE = 12'h7008;
localparam ADDR_MISC_CFG  = 12'h700c;

//==============================================================
// Internal signals
//==============================================================
reg         conv_mode_r;
reg  [1:0]  proc_precision_r;
reg         op_en_r;

wire        op_enable_wr_en;
wire        misc_cfg_wr_en;

//==============================================================
// Write enables
//==============================================================
assign op_enable_wr_en = reg_wr_en & (reg_offset[11:0] == ADDR_OP_ENABLE);
assign misc_cfg_wr_en  = reg_wr_en & (reg_offset[11:0] == ADDR_MISC_CFG);

//==============================================================
// Register flip-flops
//==============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    conv_mode_r       <= 1'b0;
    proc_precision_r  <= 2'b01;  // Default to INT8
  end else begin
    if (misc_cfg_wr_en) begin
      conv_mode_r      <= reg_wr_data[0];
      proc_precision_r <= reg_wr_data[13:12];
    end
  end
end

// op_en is controlled externally (not stored here)
assign op_en_trigger = op_enable_wr_en;

//==============================================================
// Read data output
//==============================================================
reg [31:0] reg_rd_data_r;

always @* begin
  case (reg_offset[11:0])
    ADDR_OP_ENABLE: begin
      reg_rd_data_r = {31'b0, op_en_r};
    end
    ADDR_MISC_CFG: begin
      reg_rd_data_r = {18'b0, proc_precision_r, 11'b0, conv_mode_r};
    end
    default: begin
      reg_rd_data_r = 32'b0;
    end
  endcase
end

assign reg_rd_data = reg_rd_data_r;

// Outputs to datapath
assign conv_mode      = conv_mode_r;
assign proc_precision = proc_precision_r;
assign op_en          = op_en_r;

// op_en is written via a separate path to allow external control
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_r <= 1'b0;
  end else if (op_enable_wr_en) begin
    op_en_r <= reg_wr_data[0];
  end
end

endmodule // NV_NVDLA_CMAC_REG_dual_new