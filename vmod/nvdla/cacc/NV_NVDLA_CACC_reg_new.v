// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CACC_reg_new.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CACC Register File with ping-pong architecture
// - Single register group: S_POINTER, S_STATUS
// - Dual register groups: D_OP_ENABLE, D_MISC_CFG, D_DATAOUT_*,
//   D_BATCH_NUMBER, D_LINE_STRIDE, D_SURF_STRIDE, D_DATAOUT_MAP,
//   D_CLIP_CFG, D_OUT_SATURATION, D_CYA
// - Producer pointer selects active dual register group
// - Consumer pointer tracks which group is being processed
// - FHDR------------------------------------------------------------

module NV_NVDLA_CACC_reg_new (
   nvdla_core_clk           //|< i
  ,nvdla_core_rstn         //|< i
  ,reg_rd_data             //|> o  [31:0]
  ,reg_rd_en               //|< i
  ,reg_wr_data             //|< i  [31:0]
  ,reg_wr_en               //|< i
  ,reg_offset              //|< i  [11:0]
  ,reg2dp_batches          //|> o  [4:0]
  ,reg2dp_clip_truncate    //|> o  [4:0]
  ,reg2dp_conv_mode        //|> o
  ,reg2dp_cya              //|> o  [31:0]
  ,reg2dp_dataout_addr     //|> o  [26:0]
  ,reg2dp_dataout_channel  //|> o  [12:0]
  ,reg2dp_dataout_height   //|> o  [12:0]
  ,reg2dp_dataout_width    //|> o  [12:0]
  ,reg2dp_line_packed      //|> o
  ,reg2dp_line_stride      //|> o  [18:0]
  ,reg2dp_op_en            //|> o
  ,reg2dp_proc_precision   //|> o  [1:0]
  ,reg2dp_surf_packed      //|> o
  ,reg2dp_surf_stride      //|> o  [18:0]
  ,dp2reg_done             //|< i
  ,dp2reg_sat_count        //|< i  [31:0]
  ,dp2reg_consumer         //|> o
  ,slcg_op_en              //|> o  [6:0]
  );

//===============================================================
// Port declarations
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB interface
input  [11:0] reg_offset;
input  [31:0] reg_wr_data;
input         reg_wr_en;
input         reg_rd_en;
output [31:0] reg_rd_data;

// Data path outputs
output [4:0]  reg2dp_batches;
output [4:0]  reg2dp_clip_truncate;
output        reg2dp_conv_mode;
output [31:0] reg2dp_cya;
output [26:0] reg2dp_dataout_addr;
output [12:0] reg2dp_dataout_channel;
output [12:0] reg2dp_dataout_height;
output [12:0] reg2dp_dataout_width;
output        reg2dp_line_packed;
output [18:0] reg2dp_line_stride;
output        reg2dp_op_en;
output [1:0]  reg2dp_proc_precision;
output        reg2dp_surf_packed;
output [18:0] reg2dp_surf_stride;

// Data path inputs
input         dp2reg_done;
input  [31:0] dp2reg_sat_count;
output        dp2reg_consumer;

// SLCG control
output [6:0]  slcg_op_en;

//===============================================================
// Internal signals
//===============================================================
wire [31:0] s_reg_rd_data;
wire [31:0] d0_reg_rd_data;
wire [31:0] d1_reg_rd_data;
wire        s_reg_wr_en;
wire        d0_reg_wr_en;
wire        d1_reg_wr_en;
wire        producer;
wire        consumer;
wire [1:0]  status_0;
wire [1:0]  status_1;
wire [6:0]  slcg_op_en_d0;

// Register group outputs
wire [4:0]  reg2dp_d0_batches;
wire [4:0]  reg2dp_d1_batches;
wire [4:0]  reg2dp_d0_clip_truncate;
wire [4:0]  reg2dp_d1_clip_truncate;
wire        reg2dp_d0_conv_mode;
wire        reg2dp_d1_conv_mode;
wire [31:0] reg2dp_d0_cya;
wire [31:0] reg2dp_d1_cya;
wire [26:0] reg2dp_d0_dataout_addr;
wire [26:0] reg2dp_d1_dataout_addr;
wire [12:0] reg2dp_d0_dataout_channel;
wire [12:0] reg2dp_d1_dataout_channel;
wire [12:0] reg2dp_d0_dataout_height;
wire [12:0] reg2dp_d1_dataout_height;
wire [12:0] reg2dp_d0_dataout_width;
wire [12:0] reg2dp_d1_dataout_width;
wire        reg2dp_d0_line_packed;
wire        reg2dp_d1_line_packed;
wire [18:0] reg2dp_d0_line_stride;
wire [18:0] reg2dp_d1_line_stride;
wire        reg2dp_d0_op_en;
wire        reg2dp_d1_op_en;
wire        reg2dp_d0_op_en_trigger;
wire        reg2dp_d1_op_en_trigger;
wire [1:0]  reg2dp_d0_proc_precision;
wire [1:0]  reg2dp_d1_proc_precision;
wire        reg2dp_d0_surf_packed;
wire        reg2dp_d1_surf_packed;
wire [18:0] reg2dp_d0_surf_stride;
wire [18:0] reg2dp_d1_surf_stride;

// Op enable state machine
reg          reg2dp_d0_op_en_q;
reg          reg2dp_d1_op_en_q;
reg  [2:0]  reg2dp_op_en_reg;
wire        reg2dp_op_en_ori;
wire        reg2dp_op_en_sync;
wire        dp2reg_done_sync;

// Internal registers
reg          dp2reg_consumer_q;
reg  [31:0] dp2reg_d0_sat_count;
reg  [31:0] dp2reg_d1_sat_count;
reg          dp2reg_d0_set;
reg          dp2reg_d0_clr;
reg          dp2reg_d1_set;
reg          dp2reg_d1_clr;

//===============================================================
// Address decode
//===============================================================
// Register address ranges
// S registers: 0x9000 - 0x9007 (single group)
// D registers: 0x9008 - 0x9FFF (dual groups)

wire select_s  = (reg_offset[11:0] < 12'h008);
wire select_d0 = (reg_offset[11:0] >= 12'h008) & ~producer;
wire select_d1 = (reg_offset[11:0] >= 12'h008) &  producer;

assign s_reg_wr_en  = reg_wr_en & select_s;
assign d0_reg_wr_en = reg_wr_en & select_d0 & ~reg2dp_d0_op_en_q;
assign d1_reg_wr_en = reg_wr_en & select_d1 & ~reg2dp_d1_op_en_q;

//===============================================================
// Mux read data from appropriate register group
//===============================================================
assign reg_rd_data = ({32{select_s}}  & s_reg_rd_data) |
                     ({32{select_d0}} & d0_reg_rd_data) |
                     ({32{select_d1}} & d1_reg_rd_data);

//===============================================================
// Single register group (S_POINTER, S_STATUS)
//===============================================================
NV_NVDLA_CACC_reg_s_new u_s_reg (
   .nvdla_core_clk    (nvdla_core_clk)
  ,.nvdla_core_rstn   (nvdla_core_rstn)
  ,.reg_offset        (reg_offset[11:0])
  ,.reg_wr_data       (reg_wr_data[31:0])
  ,.reg_wr_en         (s_reg_wr_en)
  ,.reg_rd_data       (s_reg_rd_data[31:0])
  ,.producer          (producer)
  ,.consumer          (dp2reg_consumer_q)
  ,.status_0         (status_0[1:0])
  ,.status_1         (status_1[1:0])
  );

//===============================================================
// Dual register group 0 (D registers)
//===============================================================
NV_NVDLA_CACC_reg_d_new u_d0_reg (
   .nvdla_core_clk     (nvdla_core_clk)
  ,.nvdla_core_rstn    (nvdla_core_rstn)
  ,.reg_offset         (reg_offset[11:0])
  ,.reg_wr_data        (reg_wr_data[31:0])
  ,.reg_wr_en          (d0_reg_wr_en)
  ,.reg_rd_data        (d0_reg_rd_data[31:0])
  ,.batches            (reg2dp_d0_batches[4:0])
  ,.clip_truncate      (reg2dp_d0_clip_truncate[4:0])
  ,.conv_mode          (reg2dp_d0_conv_mode)
  ,.cya                (reg2dp_d0_cya[31:0])
  ,.dataout_addr       (reg2dp_d0_dataout_addr[26:0])
  ,.dataout_channel    (reg2dp_d0_dataout_channel[12:0])
  ,.dataout_height     (reg2dp_d0_dataout_height[12:0])
  ,.dataout_width      (reg2dp_d0_dataout_width[12:0])
  ,.line_packed        (reg2dp_d0_line_packed)
  ,.line_stride        (reg2dp_d0_line_stride[18:0])
  ,.proc_precision     (reg2dp_d0_proc_precision[1:0])
  ,.surf_packed        (reg2dp_d0_surf_packed)
  ,.surf_stride        (reg2dp_d0_surf_stride[18:0])
  ,.op_en              (reg2dp_d0_op_en)
  ,.op_en_trigger      (reg2dp_d0_op_en_trigger)
  ,.sat_count          (dp2reg_d0_sat_count[31:0])
  );

//===============================================================
// Dual register group 1 (D registers)
//===============================================================
NV_NVDLA_CACC_reg_d_new u_d1_reg (
   .nvdla_core_clk     (nvdla_core_clk)
  ,.nvdla_core_rstn    (nvdla_core_rstn)
  ,.reg_offset         (reg_offset[11:0])
  ,.reg_wr_data        (reg_wr_data[31:0])
  ,.reg_wr_en          (d1_reg_wr_en)
  ,.reg_rd_data        (d1_reg_rd_data[31:0])
  ,.batches            (reg2dp_d1_batches[4:0])
  ,.clip_truncate      (reg2dp_d1_clip_truncate[4:0])
  ,.conv_mode          (reg2dp_d1_conv_mode)
  ,.cya                (reg2dp_d1_cya[31:0])
  ,.dataout_addr       (reg2dp_d1_dataout_addr[26:0])
  ,.dataout_channel    (reg2dp_d1_dataout_channel[12:0])
  ,.dataout_height     (reg2dp_d1_dataout_height[12:0])
  ,.dataout_width      (reg2dp_d1_dataout_width[12:0])
  ,.line_packed        (reg2dp_d1_line_packed)
  ,.line_stride        (reg2dp_d1_line_stride[18:0])
  ,.proc_precision     (reg2dp_d1_proc_precision[1:0])
  ,.surf_packed        (reg2dp_d1_surf_packed)
  ,.surf_stride        (reg2dp_d1_surf_stride[18:0])
  ,.op_en              (reg2dp_d1_op_en)
  ,.op_en_trigger      (reg2dp_d1_op_en_trigger)
  ,.sat_count          (dp2reg_d1_sat_count[31:0])
  );

//===============================================================
// Producer pointer management
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_consumer_q <= 1'b0;
  end else begin
    if (dp2reg_done_sync) begin
      dp2reg_consumer_q <= ~dp2reg_consumer_q;
    end
  end
end

assign dp2reg_consumer = dp2reg_consumer_q;
assign producer = ~dp2reg_consumer_q;  // Producer is inverse of consumer

// Consumer pointer from SC
assign consumer = dp2reg_consumer_q;

// Done signal synchronization (2FF synchronizer since dp2reg_done comes from data path)
reg dp2reg_done_d1;
reg dp2reg_done_d2;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_done_d1 <= 1'b0;
    dp2reg_done_d2 <= 1'b0;
  end else begin
    dp2reg_done_d1 <= dp2reg_done;
    dp2reg_done_d2 <= dp2reg_done_d1;
  end
end
assign dp2reg_done_sync = dp2reg_done_d2;

//===============================================================
// Status generation based on op_en and consumer
//===============================================================
assign status_0 = (reg2dp_d0_op_en == 1'b0) ? 2'b00 :
                  (consumer == 1'b1)         ? 2'b10 :
                  2'b01;

assign status_1 = (reg2dp_d1_op_en == 1'b0) ? 2'b00 :
                  (consumer == 1'b0)         ? 2'b10 :
                  2'b01;

//===============================================================
// Op enable state machine with 3-cycle delay
//===============================================================
// reg2dp_op_en follows the op_en of the currently active group
// with a 3-cycle delay for clock gating control
assign reg2dp_op_en_ori = consumer ? reg2dp_d1_op_en : reg2dp_d0_op_en;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg2dp_op_en_reg <= 3'b000;
  end else begin
    if (dp2reg_done_sync) begin
      reg2dp_op_en_reg <= 3'b000;
    end else begin
      reg2dp_op_en_reg <= {reg2dp_op_en_reg[1:0], reg2dp_op_en_ori};
    end
  end
end

assign reg2dp_op_en_sync = reg2dp_op_en_reg[2];

// Additional pipeline for SLCG
reg [6:0] slcg_op_en_d1;
reg [6:0] slcg_op_en_d2;
reg [6:0] slcg_op_en_d3;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    slcg_op_en_d1 <= 7'b0;
    slcg_op_en_d2 <= 7'b0;
    slcg_op_en_d3 <= 7'b0;
  end else begin
    slcg_op_en_d1 <= {7{reg2dp_op_en_sync}};
    slcg_op_en_d2 <= slcg_op_en_d1;
    slcg_op_en_d3 <= slcg_op_en_d2;
  end
end

assign slcg_op_en = slcg_op_en_d3;

//===============================================================
// Op enable tracking for write protection
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg2dp_d0_op_en_q <= 1'b0;
    reg2dp_d1_op_en_q <= 1'b0;
  end else begin
    reg2dp_d0_op_en_q <= reg2dp_d0_op_en;
    reg2dp_d1_op_en_q <= reg2dp_d1_op_en;
  end
end

//===============================================================
// Saturation count management
//===============================================================
// Detect op_en transitions
always @(*) begin
  dp2reg_d0_set = reg2dp_d0_op_en & ~reg2dp_d0_op_en_q;
  dp2reg_d0_clr = ~reg2dp_d0_op_en & reg2dp_d0_op_en_q;
  dp2reg_d1_set = reg2dp_d1_op_en & ~reg2dp_d1_op_en_q;
  dp2reg_d1_clr = ~reg2dp_d1_op_en & reg2dp_d1_op_en_q;
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_d0_sat_count <= 32'b0;
    dp2reg_d1_sat_count <= 32'b0;
  end else begin
    if (dp2reg_d0_set) begin
      dp2reg_d0_sat_count <= dp2reg_sat_count;
    end else if (dp2reg_d0_clr) begin
      dp2reg_d0_sat_count <= 32'b0;
    end

    if (dp2reg_d1_set) begin
      dp2reg_d1_sat_count <= dp2reg_sat_count;
    end else if (dp2reg_d1_clr) begin
      dp2reg_d1_sat_count <= 32'b0;
    end
  end
end

//===============================================================
// Output multiplexer for data path
//===============================================================
assign reg2dp_batches         = consumer ? reg2dp_d1_batches         : reg2dp_d0_batches;
assign reg2dp_clip_truncate   = consumer ? reg2dp_d1_clip_truncate   : reg2dp_d0_clip_truncate;
assign reg2dp_conv_mode       = consumer ? reg2dp_d1_conv_mode       : reg2dp_d0_conv_mode;
assign reg2dp_cya             = consumer ? reg2dp_d1_cya             : reg2dp_d0_cya;
assign reg2dp_dataout_addr    = consumer ? reg2dp_d1_dataout_addr    : reg2dp_d0_dataout_addr;
assign reg2dp_dataout_channel = consumer ? reg2dp_d1_dataout_channel : reg2dp_d0_dataout_channel;
assign reg2dp_dataout_height  = consumer ? reg2dp_d1_dataout_height  : reg2dp_d0_dataout_height;
assign reg2dp_dataout_width   = consumer ? reg2dp_d1_dataout_width   : reg2dp_d0_dataout_width;
assign reg2dp_line_packed     = consumer ? reg2dp_d1_line_packed     : reg2dp_d0_line_packed;
assign reg2dp_line_stride     = consumer ? reg2dp_d1_line_stride     : reg2dp_d0_line_stride;
assign reg2dp_proc_precision  = consumer ? reg2dp_d1_proc_precision  : reg2dp_d0_proc_precision;
assign reg2dp_surf_packed     = consumer ? reg2dp_d1_surf_packed     : reg2dp_d0_surf_packed;
assign reg2dp_surf_stride     = consumer ? reg2dp_d1_surf_stride     : reg2dp_d0_surf_stride;
assign reg2dp_op_en           = reg2dp_op_en_sync;

endmodule // NV_NVDLA_CACC_reg_new


//===============================================================
// Sub-module: Single register group (S_POINTER, S_STATUS)
//===============================================================
module NV_NVDLA_CACC_reg_s_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,reg_offset
  ,reg_wr_data
  ,reg_wr_en
  ,reg_rd_data
  ,producer
  ,consumer
  ,status_0
  ,status_1
  );

input         nvdla_core_clk;
input         nvdla_core_rstn;
input  [11:0] reg_offset;
input  [31:0] reg_wr_data;
input         reg_wr_en;
output [31:0] reg_rd_data;
output        producer;
input         consumer;
input  [1:0]  status_0;
input  [1:0]  status_1;

// Internal wires
wire         nvdla_cacc_s_pointer_wren;
wire         nvdla_cacc_s_status_wren;
wire [31:0]  s_pointer_out;
wire [31:0]  s_status_out;

// Register write enables
assign nvdla_cacc_s_pointer_wren = (reg_offset == 12'h004) & reg_wr_en;
assign nvdla_cacc_s_status_wren   = (reg_offset == 12'h000) & reg_wr_en;

// Register bits: producer (bit 0)
reg producer_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    producer_q <= 1'b0;
  end else if (nvdla_cacc_s_pointer_wren) begin
    producer_q <= reg_wr_data[0];
  end
end

assign producer = producer_q;

// Readback format: S_POINTER = {15'b0, consumer, 15'b0, producer}
assign s_pointer_out[31:0] = {15'b0, consumer, 15'b0, producer};

// Readback format: S_STATUS = {14'b0, status_1, 14'b0, status_0}
assign s_status_out[31:0] = {14'b0, status_1[1:0], 14'b0, status_0[1:0]};

// Read data mux
reg [31:0] reg_rd_data_q;

always @(*) begin
  case (reg_offset)
    12'h004: reg_rd_data_q = s_pointer_out;
    12'h000: reg_rd_data_q = s_status_out;
    default: reg_rd_data_q = 32'b0;
  endcase
end

assign reg_rd_data = reg_rd_data_q;

endmodule // NV_NVDLA_CACC_reg_s_new


//===============================================================
// Sub-module: Dual register group (D registers)
//===============================================================
module NV_NVDLA_CACC_reg_d_new (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,reg_offset
  ,reg_wr_data
  ,reg_wr_en
  ,reg_rd_data
  ,batches
  ,clip_truncate
  ,conv_mode
  ,cya
  ,dataout_addr
  ,dataout_channel
  ,dataout_height
  ,dataout_width
  ,line_packed
  ,line_stride
  ,proc_precision
  ,surf_packed
  ,surf_stride
  ,op_en
  ,op_en_trigger
  ,sat_count
  );

input         nvdla_core_clk;
input         nvdla_core_rstn;
input  [11:0] reg_offset;
input  [31:0] reg_wr_data;
input         reg_wr_en;
output [31:0] reg_rd_data;
output [4:0]  batches;
output [4:0]  clip_truncate;
output        conv_mode;
output [31:0] cya;
output [26:0] dataout_addr;
output [12:0] dataout_channel;
output [12:0] dataout_height;
output [12:0] dataout_width;
output        line_packed;
output [18:0] line_stride;
output [1:0]  proc_precision;
output        surf_packed;
output [18:0] surf_stride;
output        op_en;
output        op_en_trigger;
input  [31:0] sat_count;

// Write enables
wire         wren_batch;
wire         wren_clip;
wire         wren_cya;
wire         wren_addr;
wire         wren_map;
wire         wren_size0;
wire         wren_size1;
wire         wren_stride;
wire         wren_misc;
wire         wren_op_en;
wire         wren_sat;
wire         wren_surf;

assign wren_batch   = (reg_offset == 12'h01C) & reg_wr_en;
assign wren_clip    = (reg_offset == 12'h02C) & reg_wr_en;
assign wren_cya     = (reg_offset == 12'h034) & reg_wr_en;
assign wren_addr    = (reg_offset == 12'h018) & reg_wr_en;
assign wren_map     = (reg_offset == 12'h028) & reg_wr_en;
assign wren_size0   = (reg_offset == 12'h010) & reg_wr_en;
assign wren_size1   = (reg_offset == 12'h014) & reg_wr_en;
assign wren_stride  = (reg_offset == 12'h020) & reg_wr_en;
assign wren_misc    = (reg_offset == 12'h00C) & reg_wr_en;
assign wren_op_en   = (reg_offset == 12'h008) & reg_wr_en;
assign wren_sat     = (reg_offset == 12'h030) & reg_wr_en;
assign wren_surf    = (reg_offset == 12'h024) & reg_wr_en;

// Register fields
reg [4:0]  batches_q;
reg [4:0]  clip_truncate_q;
reg        conv_mode_q;
reg [31:0] cya_q;
reg [26:0] dataout_addr_q;
reg [12:0] dataout_channel_q;
reg [12:0] dataout_height_q;
reg [12:0] dataout_width_q;
reg        line_packed_q;
reg [18:0] line_stride_q;
reg [1:0]  proc_precision_q;
reg        surf_packed_q;
reg [18:0] surf_stride_q;

// Op enable is driven by external state machine, not directly written
// Just track the trigger for response
reg op_en_trigger_q;
assign op_en_trigger = wren_op_en;

// Assign outputs
assign batches         = batches_q;
assign clip_truncate   = clip_truncate_q;
assign conv_mode       = conv_mode_q;
assign cya             = cya_q;
assign dataout_addr    = dataout_addr_q;
assign dataout_channel = dataout_channel_q;
assign dataout_height  = dataout_height_q;
assign dataout_width   = dataout_width_q;
assign line_packed     = line_packed_q;
assign line_stride     = line_stride_q;
assign proc_precision  = proc_precision_q;
assign surf_packed     = surf_packed_q;
assign surf_stride     = surf_stride_q;

// Register file write process
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    batches_q         <= 5'b0;
    clip_truncate_q   <= 5'b0;
    conv_mode_q       <= 1'b0;
    cya_q             <= 32'b0;
    dataout_addr_q    <= 27'b0;
    dataout_channel_q <= 13'b0;
    dataout_height_q <= 13'b0;
    dataout_width_q   <= 13'b0;
    line_packed_q     <= 1'b0;
    line_stride_q      <= 19'b0;
    proc_precision_q  <= 2'b01;  // Default to INT16
    surf_packed_q     <= 1'b0;
    surf_stride_q     <= 19'b0;
  end else begin
    if (wren_batch)   batches_q         <= reg_wr_data[4:0];
    if (wren_clip)    clip_truncate_q   <= reg_wr_data[4:0];
    if (wren_cya)     cya_q             <= reg_wr_data[31:0];
    if (wren_addr)    dataout_addr_q    <= reg_wr_data[31:5];
    if (wren_map) begin
      line_packed_q   <= reg_wr_data[0];
      surf_packed_q   <= reg_wr_data[16];
    end
    if (wren_size0) begin
      dataout_height_q <= reg_wr_data[28:16];
      dataout_width_q  <= reg_wr_data[12:0];
    end
    if (wren_size1)   dataout_channel_q <= reg_wr_data[12:0];
    if (wren_stride)  line_stride_q     <= reg_wr_data[23:5];
    if (wren_misc) begin
      conv_mode_q      <= reg_wr_data[0];
      proc_precision_q <= reg_wr_data[13:12];
    end
    if (wren_surf)    surf_stride_q     <= reg_wr_data[23:5];
  end
end

// Op enable is set when trigger is high and op_en register bit is 1
// It gets cleared by the external state machine via dp2reg_done
reg op_en_q;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_q <= 1'b0;
  end else if (wren_op_en) begin
    op_en_q <= reg_wr_data[0];
  end
end
assign op_en = op_en_q;

// Readback data
reg [31:0] reg_rd_data_q;

always @(*) begin
  case (reg_offset)
    12'h01C: reg_rd_data_q = {27'b0, batches_q};
    12'h02C: reg_rd_data_q = {27'b0, clip_truncate_q};
    12'h034: reg_rd_data_q = cya_q;
    12'h018: reg_rd_data_q = {dataout_addr_q, 5'b0};
    12'h028: reg_rd_data_q = {15'b0, surf_packed_q, 15'b0, line_packed_q};
    12'h010: reg_rd_data_q = {3'b0, dataout_height_q, 3'b0, dataout_width_q};
    12'h014: reg_rd_data_q = {19'b0, dataout_channel_q};
    12'h020: reg_rd_data_q = {8'b0, line_stride_q, 5'b0};
    12'h00C: reg_rd_data_q = {18'b0, proc_precision_q, 11'b0, conv_mode_q};
    12'h008: reg_rd_data_q = {31'b0, op_en_q};
    12'h030: reg_rd_data_q = sat_count;  // Read-only
    12'h024: reg_rd_data_q = {8'b0, surf_stride_q, 5'b0};
    default: reg_rd_data_q = 32'b0;
  endcase
end

assign reg_rd_data = reg_rd_data_q;

endmodule // NV_NVDLA_CACC_reg_d_new