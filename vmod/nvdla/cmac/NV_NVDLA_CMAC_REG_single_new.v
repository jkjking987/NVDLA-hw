// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CMAC_REG_single_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Single (shared) register group for CMAC
// - Status registers
// - Producer/Consumer pointer register
// +FHDR------------------------------------------------------------

module NV_NVDLA_CMAC_REG_single_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,reg_wr_en
  ,reg_offset
  ,reg_wr_data
  ,reg_rd_data
  ,producer
  ,consumer
  ,status_0
  ,status_1
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
output       producer;
input        consumer;
input  [1:0] status_0;
input  [1:0] status_1;

//==============================================================
// Parameters
//==============================================================
localparam ADDR_STATUS  = 12'h7000;
localparam ADDR_POINTER = 12'h7004;

//==============================================================
// Internal signals
//==============================================================
reg         producer_r;
reg  [31:0] reg_rd_data_r;
wire        pointer_wr_en;
wire        status_wr_en;

//==============================================================
// Pointer register (producer pointer)
//==============================================================
assign pointer_wr_en = reg_wr_en & (reg_offset[11:0] == ADDR_POINTER);

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    producer_r <= 1'b0;
  end else if (pointer_wr_en) begin
    producer_r <= reg_wr_data[0];
  end
end

assign producer = producer_r;

//==============================================================
// Status register read
//==============================================================
always @* begin
  case (reg_offset[11:0])
    ADDR_STATUS: begin
      reg_rd_data_r[31:16] = 16'b0;
      reg_rd_data_r[15:8]  = 8'b0;
      reg_rd_data_r[7:4]   = 4'b0;
      reg_rd_data_r[3:2]   = status_1[1:0];
      reg_rd_data_r[1:0]   = status_0[1:0];
    end
    ADDR_POINTER: begin
      reg_rd_data_r[31:2] = 30'b0;
      reg_rd_data_r[1]     = 1'b0;     // reserved
      reg_rd_data_r[0]     = producer_r;
    end
    default: begin
      reg_rd_data_r = 32'b0;
    end
  endcase
end

assign reg_rd_data = reg_rd_data_r;

endmodule // NV_NVDLA_CMAC_REG_single_new