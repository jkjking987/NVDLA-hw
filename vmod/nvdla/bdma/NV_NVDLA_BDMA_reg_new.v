// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_BDMA_reg_new.v
// Author: Claude
// Description:
// BDMA Register File Module with CSB interface (new offset layout)
// Handles register read/write at address offsets via CSB protocol

// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_BDMA_reg_new.v
// Author        : Claude
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// BDMA Register File Module (New Offset Layout)
// - CSB (Command and Status Bus) register access interface
// - Supports read/write operations to all BDMA configuration
//   and status registers
// - Register offsets: OP_ENABLE(0x00), TRIG(0x04), CFG_OP(0x08),
//   CFG_CMD(0x0C), CFG_SRC/DST_ADDR_LOW/HIGH(0x10-0x1C),
//   CFG_LINE_SIZE(0x20), CFG_LINE_REPEAT_NUMBER(0x24),
//   CFG_SRC/DST_LINE_STRIDE(0x28-0x2C), CFG_SURF_REPEAT_NUMBER(0x30),
//   CFG_SRC/DST_SURF_STRIDE(0x34-0x38), STATUS(0x40)
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_reg_new (
   // CSB interface
   csb_clk
  ,csb_rstn
  ,csb_addr
  ,csb_wdat
  ,csb_rd_en
  ,csb_wr_en
  ,csb_rdat
  ,npu_rdy
  // Datapath outputs (to load/store blocks)
  ,reg2dp_src_addr_low_v32
  ,reg2dp_src_addr_high_v8
  ,reg2dp_dst_addr_low_v32
  ,reg2dp_dst_addr_high_v8
  ,reg2dp_line_size
  ,reg2dp_cmd_src_ram_type
  ,reg2dp_cmd_dst_ram_type
  ,reg2dp_line_repeat_number
  ,reg2dp_src_line_stride
  ,reg2dp_dst_line_stride
  ,reg2dp_surf_repeat_number
  ,reg2dp_src_surf_stride
  ,reg2dp_dst_surf_stride
  ,reg2dp_op_en
  ,reg2dp_trig
  ,reg2dp_status_stall_count_en
  ,reg2dp_op_en_trigger
  ,reg2dp_trig_trigger
  // External status inputs (from load/store blocks)
  ,ext_status_idle
  ,ext_status_grp0_busy
  ,ext_status_grp1_busy
  ,ext_free_slot
  );

//===============================================================
// PORT DECLARATION
//===============================================================
// CSB interface
input         csb_clk;
input         csb_rstn;
input  [11:0] csb_addr;
input  [31:0] csb_wdat;
input         csb_rd_en;
input         csb_wr_en;
output [31:0] csb_rdat;
output        npu_rdy;

// Datapath outputs
output [26:0] reg2dp_src_addr_low_v32;
output [31:0] reg2dp_src_addr_high_v8;
output [26:0] reg2dp_dst_addr_low_v32;
output [31:0] reg2dp_dst_addr_high_v8;
output [12:0] reg2dp_line_size;
output        reg2dp_cmd_src_ram_type;
output        reg2dp_cmd_dst_ram_type;
output [23:0] reg2dp_line_repeat_number;
output [26:0] reg2dp_src_line_stride;
output [26:0] reg2dp_dst_line_stride;
output [23:0] reg2dp_surf_repeat_number;
output [26:0] reg2dp_src_surf_stride;
output [26:0] reg2dp_dst_surf_stride;
output        reg2dp_op_en;
output        reg2dp_trig;
output        reg2dp_status_stall_count_en;
output        reg2dp_op_en_trigger;
output        reg2dp_trig_trigger;

// External status inputs
input         ext_status_idle;
input         ext_status_grp0_busy;
input         ext_status_grp1_busy;
input  [7:0]  ext_free_slot;

//===============================================================
// PARAMETERS
//===============================================================
// Register addresses (12-bit address, lower 12 bits of 32-bit address)
// New offset layout as specified in Task 1.2
parameter [11:0] REG_OP_ENABLE              = 12'h000;
parameter [11:0] REG_TRIG                   = 12'h004;
parameter [11:0] REG_CFG_OP                 = 12'h008;
parameter [11:0] REG_CFG_CMD                = 12'h00C;
parameter [11:0] REG_CFG_SRC_ADDR_LOW       = 12'h010;
parameter [11:0] REG_CFG_SRC_ADDR_HIGH      = 12'h014;
parameter [11:0] REG_CFG_DST_ADDR_LOW        = 12'h018;
parameter [11:0] REG_CFG_DST_ADDR_HIGH       = 12'h01C;
parameter [11:0] REG_CFG_LINE_SIZE           = 12'h020;
parameter [11:0] REG_CFG_LINE_REPEAT_NUMBER  = 12'h024;
parameter [11:0] REG_CFG_SRC_LINE_STRIDE     = 12'h028;
parameter [11:0] REG_CFG_DST_LINE_STRIDE     = 12'h02C;
parameter [11:0] REG_CFG_SURF_REPEAT_NUMBER  = 12'h030;
parameter [11:0] REG_CFG_SRC_SURF_STRIDE     = 12'h034;
parameter [11:0] REG_CFG_DST_SURF_STRIDE     = 12'h038;
parameter [11:0] REG_STATUS                  = 12'h040;

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// Write enable decode
wire        op_enable_wren;
wire        trig_wren;
wire        cfg_op_wren;
wire        cfg_cmd_wren;
wire        cfg_src_addr_low_wren;
wire        cfg_src_addr_high_wren;
wire        cfg_dst_addr_low_wren;
wire        cfg_dst_addr_high_wren;
wire        cfg_line_size_wren;
wire        cfg_line_repeat_number_wren;
wire        cfg_src_line_stride_wren;
wire        cfg_dst_line_stride_wren;
wire        cfg_surf_repeat_number_wren;
wire        cfg_src_surf_stride_wren;
wire        cfg_dst_surf_stride_wren;
wire        status_wren;

// Read data muxes
wire [31:0] op_enable_rdat;
wire [31:0] trig_rdat;
wire [31:0] cfg_op_rdat;
wire [31:0] cfg_cmd_rdat;
wire [31:0] cfg_src_addr_low_rdat;
wire [31:0] cfg_src_addr_high_rdat;
wire [31:0] cfg_dst_addr_low_rdat;
wire [31:0] cfg_dst_addr_high_rdat;
wire [31:0] cfg_line_size_rdat;
wire [31:0] cfg_line_repeat_number_rdat;
wire [31:0] cfg_src_line_stride_rdat;
wire [31:0] cfg_dst_line_stride_rdat;
wire [31:0] cfg_surf_repeat_number_rdat;
wire [31:0] cfg_src_surf_stride_rdat;
wire [31:0] cfg_dst_surf_stride_rdat;
wire [31:0] status_rdat;

//===============================================================
// REG DECLARATIONS
//===============================================================
// OP_ENABLE register
reg          op_enable_r;

// TRIG register
reg          trig_r;

// CFG registers (writable)
reg          cfg_op_en_r;
reg          cfg_cmd_src_ram_type_r;
reg          cfg_cmd_dst_ram_type_r;
reg  [26:0]  cfg_src_addr_low_r;
reg  [31:0]  cfg_src_addr_high_r;
reg  [26:0]  cfg_dst_addr_low_r;
reg  [31:0]  cfg_dst_addr_high_r;
reg  [12:0]  cfg_line_size_r;
reg  [23:0]  cfg_line_repeat_number_r;
reg  [26:0]  cfg_src_line_stride_r;
reg  [26:0]  cfg_dst_line_stride_r;
reg  [23:0]  cfg_surf_repeat_number_r;
reg  [26:0]  cfg_src_surf_stride_r;
reg  [26:0]  cfg_dst_surf_stride_r;
reg          cfg_status_stall_count_en_r;

// CSB response flops
reg  [31:0]  csb_rdat_q;

// Trigger detection flops
reg          cfg_op_en_wren_d1;
reg          trig_wren_d1;

//===============================================================
// ADDRESS DECODE - WRITE ENABLE
//===============================================================
assign op_enable_wren              = (csb_addr == REG_OP_ENABLE)              & csb_wr_en;
assign trig_wren                   = (csb_addr == REG_TRIG)                   & csb_wr_en;
assign cfg_op_wren                 = (csb_addr == REG_CFG_OP)                & csb_wr_en;
assign cfg_cmd_wren                = (csb_addr == REG_CFG_CMD)                & csb_wr_en;
assign cfg_src_addr_low_wren       = (csb_addr == REG_CFG_SRC_ADDR_LOW)       & csb_wr_en;
assign cfg_src_addr_high_wren      = (csb_addr == REG_CFG_SRC_ADDR_HIGH)      & csb_wr_en;
assign cfg_dst_addr_low_wren       = (csb_addr == REG_CFG_DST_ADDR_LOW)       & csb_wr_en;
assign cfg_dst_addr_high_wren      = (csb_addr == REG_CFG_DST_ADDR_HIGH)      & csb_wr_en;
assign cfg_line_size_wren          = (csb_addr == REG_CFG_LINE_SIZE)          & csb_wr_en;
assign cfg_line_repeat_number_wren = (csb_addr == REG_CFG_LINE_REPEAT_NUMBER) & csb_wr_en;
assign cfg_src_line_stride_wren    = (csb_addr == REG_CFG_SRC_LINE_STRIDE)   & csb_wr_en;
assign cfg_dst_line_stride_wren    = (csb_addr == REG_CFG_DST_LINE_STRIDE)   & csb_wr_en;
assign cfg_surf_repeat_number_wren = (csb_addr == REG_CFG_SURF_REPEAT_NUMBER) & csb_wr_en;
assign cfg_src_surf_stride_wren    = (csb_addr == REG_CFG_SRC_SURF_STRIDE)   & csb_wr_en;
assign cfg_dst_surf_stride_wren    = (csb_addr == REG_CFG_DST_SURF_STRIDE)   & csb_wr_en;
assign status_wren                 = (csb_addr == REG_STATUS)                 & csb_wr_en;

//===============================================================
// REGISTER FILE - WRITE LOGIC
//===============================================================
// OP_ENABLE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    op_enable_r <= 1'd0;
  end else begin
    if (op_enable_wren) begin
      op_enable_r <= csb_wdat[0];
    end
  end
end

// TRIG
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    trig_r <= 1'd0;
  end else begin
    if (trig_wren) begin
      trig_r <= csb_wdat[0];
    end
  end
end

// CFG_OP
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_op_en_r <= 1'd0;
  end else begin
    if (cfg_op_wren) begin
      cfg_op_en_r <= csb_wdat[0];
    end
  end
end

// CFG_CMD
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_cmd_src_ram_type_r <= 1'd0;
    cfg_cmd_dst_ram_type_r <= 1'd0;
  end else begin
    if (cfg_cmd_wren) begin
      cfg_cmd_src_ram_type_r <= csb_wdat[0];
      cfg_cmd_dst_ram_type_r <= csb_wdat[1];
    end
  end
end

// CFG_SRC_ADDR_LOW
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_src_addr_low_r[26:0] <= 27'd0;
  end else begin
    if (cfg_src_addr_low_wren) begin
      cfg_src_addr_low_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// CFG_SRC_ADDR_HIGH
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_src_addr_high_r[31:0] <= 32'd0;
  end else begin
    if (cfg_src_addr_high_wren) begin
      cfg_src_addr_high_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// CFG_DST_ADDR_LOW
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_dst_addr_low_r[26:0] <= 27'd0;
  end else begin
    if (cfg_dst_addr_low_wren) begin
      cfg_dst_addr_low_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// CFG_DST_ADDR_HIGH
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_dst_addr_high_r[31:0] <= 32'd0;
  end else begin
    if (cfg_dst_addr_high_wren) begin
      cfg_dst_addr_high_r[31:0] <= csb_wdat[31:0];
    end
  end
end

// CFG_LINE_SIZE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_line_size_r[12:0] <= 13'd0;
  end else begin
    if (cfg_line_size_wren) begin
      cfg_line_size_r[12:0] <= csb_wdat[12:0];
    end
  end
end

// CFG_LINE_REPEAT_NUMBER
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_line_repeat_number_r[23:0] <= 24'd0;
  end else begin
    if (cfg_line_repeat_number_wren) begin
      cfg_line_repeat_number_r[23:0] <= csb_wdat[23:0];
    end
  end
end

// CFG_SRC_LINE_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_src_line_stride_r[26:0] <= 27'd0;
  end else begin
    if (cfg_src_line_stride_wren) begin
      cfg_src_line_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// CFG_DST_LINE_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_dst_line_stride_r[26:0] <= 27'd0;
  end else begin
    if (cfg_dst_line_stride_wren) begin
      cfg_dst_line_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// CFG_SURF_REPEAT_NUMBER
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_surf_repeat_number_r[23:0] <= 24'd0;
  end else begin
    if (cfg_surf_repeat_number_wren) begin
      cfg_surf_repeat_number_r[23:0] <= csb_wdat[23:0];
    end
  end
end

// CFG_SRC_SURF_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_src_surf_stride_r[26:0] <= 27'd0;
  end else begin
    if (cfg_src_surf_stride_wren) begin
      cfg_src_surf_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

// CFG_DST_SURF_STRIDE
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_dst_surf_stride_r[26:0] <= 27'd0;
  end else begin
    if (cfg_dst_surf_stride_wren) begin
      cfg_dst_surf_stride_r[26:0] <= csb_wdat[31:5];
    end
  end
end

//===============================================================
// TRIGGER DETECTION LOGIC
//===============================================================
// Detect rising edge of write enable for trigger generation
always @(posedge csb_clk or negedge csb_rstn) begin
  if (!csb_rstn) begin
    cfg_op_en_wren_d1 <= 1'd0;
    trig_wren_d1 <= 1'd0;
  end else begin
    cfg_op_en_wren_d1 <= cfg_op_wren;
    trig_wren_d1 <= trig_wren;
  end
end

// Trigger outputs (one cycle pulse on rising edge of write enable)
assign reg2dp_op_en_trigger = cfg_op_wren & ~cfg_op_en_wren_d1;
assign reg2dp_trig_trigger = trig_wren & ~trig_wren_d1;

//===============================================================
// READ DATA ASSEMBLY
//===============================================================
// Assemble read data for each register (combines register fields to 32-bit word)
assign op_enable_rdat[31:0]              = {31'd0, op_enable_r};
assign trig_rdat[31:0]                    = {31'd0, trig_r};
assign cfg_op_rdat[31:0]                  = {31'd0, cfg_op_en_r};
assign cfg_cmd_rdat[31:0]                 = {30'd0, cfg_cmd_dst_ram_type_r, cfg_cmd_src_ram_type_r};
assign cfg_src_addr_low_rdat[31:0]        = {5'd0, cfg_src_addr_low_r[26:0]};
assign cfg_src_addr_high_rdat[31:0]       = cfg_src_addr_high_r[31:0];
assign cfg_dst_addr_low_rdat[31:0]        = {5'd0, cfg_dst_addr_low_r[26:0]};
assign cfg_dst_addr_high_rdat[31:0]       = cfg_dst_addr_high_r[31:0];
assign cfg_line_size_rdat[31:0]           = {19'd0, cfg_line_size_r[12:0]};
assign cfg_line_repeat_number_rdat[31:0]  = {8'd0, cfg_line_repeat_number_r[23:0]};
assign cfg_src_line_stride_rdat[31:0]     = {5'd0, cfg_src_line_stride_r[26:0]};
assign cfg_dst_line_stride_rdat[31:0]     = {5'd0, cfg_dst_line_stride_r[26:0]};
assign cfg_surf_repeat_number_rdat[31:0]   = {8'd0, cfg_surf_repeat_number_r[23:0]};
assign cfg_src_surf_stride_rdat[31:0]     = {5'd0, cfg_src_surf_stride_r[26:0]};
assign cfg_dst_surf_stride_rdat[31:0]     = {5'd0, cfg_dst_surf_stride_r[26:0]};

// STATUS register read data - assembled from external status inputs
// Format: [31:11] reserved, [10] grp1_busy, [9] grp0_busy, [8] idle, [7:0] free_slot
assign status_rdat[31:0] = {21'd0, ext_status_grp1_busy, ext_status_grp0_busy, ext_status_idle, ext_free_slot[7:0]};

//===============================================================
// READ DATA MUX - CSB READ RESPONSE
//===============================================================
always @* begin
  case (csb_addr)
    REG_OP_ENABLE:             csb_rdat_q = op_enable_rdat;
    REG_TRIG:                  csb_rdat_q = trig_rdat;
    REG_CFG_OP:                csb_rdat_q = cfg_op_rdat;
    REG_CFG_CMD:               csb_rdat_q = cfg_cmd_rdat;
    REG_CFG_SRC_ADDR_LOW:       csb_rdat_q = cfg_src_addr_low_rdat;
    REG_CFG_SRC_ADDR_HIGH:      csb_rdat_q = cfg_src_addr_high_rdat;
    REG_CFG_DST_ADDR_LOW:       csb_rdat_q = cfg_dst_addr_low_rdat;
    REG_CFG_DST_ADDR_HIGH:      csb_rdat_q = cfg_dst_addr_high_rdat;
    REG_CFG_LINE_SIZE:          csb_rdat_q = cfg_line_size_rdat;
    REG_CFG_LINE_REPEAT_NUMBER: csb_rdat_q = cfg_line_repeat_number_rdat;
    REG_CFG_SRC_LINE_STRIDE:    csb_rdat_q = cfg_src_line_stride_rdat;
    REG_CFG_DST_LINE_STRIDE:    csb_rdat_q = cfg_dst_line_stride_rdat;
    REG_CFG_SURF_REPEAT_NUMBER: csb_rdat_q = cfg_surf_repeat_number_rdat;
    REG_CFG_SRC_SURF_STRIDE:    csb_rdat_q = cfg_src_surf_stride_rdat;
    REG_CFG_DST_SURF_STRIDE:    csb_rdat_q = cfg_dst_surf_stride_rdat;
    REG_STATUS:                 csb_rdat_q = status_rdat;
    default:                    csb_rdat_q = 32'd0;
  endcase
end

//===============================================================
// CSB RESPONSE OUTPUT
//===============================================================
// CSB read data output
assign csb_rdat[31:0] = csb_rdat_q;

// Ready signal - always ready for CSB transactions
assign npu_rdy = 1'b1;

//===============================================================
// DATAPATH OUTPUTS (registered values)
//===============================================================
assign reg2dp_src_addr_low_v32[26:0]      = cfg_src_addr_low_r[26:0];
assign reg2dp_src_addr_high_v8[31:0]      = cfg_src_addr_high_r[31:0];
assign reg2dp_dst_addr_low_v32[26:0]      = cfg_dst_addr_low_r[26:0];
assign reg2dp_dst_addr_high_v8[31:0]      = cfg_dst_addr_high_r[31:0];
assign reg2dp_line_size[12:0]             = cfg_line_size_r[12:0];
assign reg2dp_cmd_src_ram_type            = cfg_cmd_src_ram_type_r;
assign reg2dp_cmd_dst_ram_type            = cfg_cmd_dst_ram_type_r;
assign reg2dp_line_repeat_number[23:0]    = cfg_line_repeat_number_r[23:0];
assign reg2dp_src_line_stride[26:0]       = cfg_src_line_stride_r[26:0];
assign reg2dp_dst_line_stride[26:0]       = cfg_dst_line_stride_r[26:0];
assign reg2dp_surf_repeat_number[23:0]    = cfg_surf_repeat_number_r[23:0];
assign reg2dp_src_surf_stride[26:0]        = cfg_src_surf_stride_r[26:0];
assign reg2dp_dst_surf_stride[26:0]        = cfg_dst_surf_stride_r[26:0];
assign reg2dp_op_en                       = cfg_op_en_r;
assign reg2dp_trig                        = trig_r;
assign reg2dp_status_stall_count_en        = cfg_status_stall_count_en_r;

//===============================================================
// DEBUG AND ASSERTIONS
//===============================================================
// synopsys translate_off
`ifdef SYNTHESIS
`else
// Register write debug
always @(posedge csb_clk) begin
  if (csb_wr_en) begin
    case (csb_addr)
      REG_OP_ENABLE:             $display("%t:%m: WR REG_OP_ENABLE = 0x%h", $time, csb_wdat);
      REG_TRIG:                  $display("%t:%m: WR REG_TRIG = 0x%h", $time, csb_wdat);
      REG_CFG_OP:                $display("%t:%m: WR REG_CFG_OP = 0x%h", $time, csb_wdat);
      REG_CFG_CMD:               $display("%t:%m: WR REG_CFG_CMD = 0x%h", $time, csb_wdat);
      REG_CFG_SRC_ADDR_LOW:       $display("%t:%m: WR REG_CFG_SRC_ADDR_LOW = 0x%h", $time, csb_wdat);
      REG_CFG_SRC_ADDR_HIGH:      $display("%t:%m: WR REG_CFG_SRC_ADDR_HIGH = 0x%h", $time, csb_wdat);
      REG_CFG_DST_ADDR_LOW:       $display("%t:%m: WR REG_CFG_DST_ADDR_LOW = 0x%h", $time, csb_wdat);
      REG_CFG_DST_ADDR_HIGH:      $display("%t:%m: WR REG_CFG_DST_ADDR_HIGH = 0x%h", $time, csb_wdat);
      REG_CFG_LINE_SIZE:          $display("%t:%m: WR REG_CFG_LINE_SIZE = 0x%h", $time, csb_wdat);
      REG_CFG_LINE_REPEAT_NUMBER: $display("%t:%m: WR REG_CFG_LINE_REPEAT_NUMBER = 0x%h", $time, csb_wdat);
      REG_CFG_SRC_LINE_STRIDE:    $display("%t:%m: WR REG_CFG_SRC_LINE_STRIDE = 0x%h", $time, csb_wdat);
      REG_CFG_DST_LINE_STRIDE:    $display("%t:%m: WR REG_CFG_DST_LINE_STRIDE = 0x%h", $time, csb_wdat);
      REG_CFG_SURF_REPEAT_NUMBER: $display("%t:%m: WR REG_CFG_SURF_REPEAT_NUMBER = 0x%h", $time, csb_wdat);
      REG_CFG_SRC_SURF_STRIDE:    $display("%t:%m: WR REG_CFG_SRC_SURF_STRIDE = 0x%h", $time, csb_wdat);
      REG_CFG_DST_SURF_STRIDE:    $display("%t:%m: WR REG_CFG_DST_SURF_STRIDE = 0x%h", $time, csb_wdat);
      REG_STATUS:                 $display("%t:%m: WR REG_STATUS (read-only) = 0x%h", $time, csb_wdat);
      default:;
    endcase
  end
end
`endif
// synopsys translate_on

endmodule // NV_NVDLA_BDMA_reg_new