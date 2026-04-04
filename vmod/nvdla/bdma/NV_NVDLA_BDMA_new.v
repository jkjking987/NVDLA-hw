// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_BDMA_new.v
// Author        : Wolley Hardware Team
// Author Email  : hwteam@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// BDMA (Block DMA) Top-Level Integration Module
//
// This module integrates all BDMA sub-modules:
// - CSB interface with embedded register file (NV_NVDLA_BDMA_csb_new)
// - Load engine for memory read operations (NV_NVDLA_BDMA_load_new)
// - Store engine for memory write operations (NV_NVDLA_BDMA_store_new)
// - MCIF/CVIF router for external memory interfaces (NV_NVDLA_BDMA_mcif_cvif_new)
// - Command Queue FIFO for load-store data transfer (NV_NVDLA_BDMA_cq)
// - Clock gating unit (NV_NVDLA_BDMA_gate)
//
// Data Flow:
//   CSB/Reg -> Config Packer -> Load Engine -> CQ FIFO -> Store Engine -> MCIF/CVIF
//                                                         |
//                                                         v
//                                                     External Memory
// +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_new (
    nvdla_core_clk
  , nvdla_core_rstn

  // CSB Interface
  , csb2bdma_req_pvld
  , csb2bdma_req_prdy
  , csb2bdma_req_pd
  , bdma2csb_resp_valid
  , bdma2csb_resp_pd

  // MCIF Read Interface
  , mcif2bdma_rd_rsp_valid
  , mcif2bdma_rd_rsp_ready
  , mcif2bdma_rd_rsp_pd
  , bdma2mcif_rd_req_valid
  , bdma2mcif_rd_req_ready
  , bdma2mcif_rd_req_pd

  // MCIF Write Interface
  , mcif2bdma_wr_rsp_complete
  , bdma2mcif_wr_req_valid
  , bdma2mcif_wr_req_ready
  , bdma2mcif_wr_req_pd

  // CVIF Read Interface
  , cvif2bdma_rd_rsp_valid
  , cvif2bdma_rd_rsp_ready
  , cvif2bdma_rd_rsp_pd
  , bdma2cvif_rd_req_valid
  , bdma2cvif_rd_req_ready
  , bdma2cvif_rd_req_pd

  // CVIF Write Interface
  , cvif2bdma_wr_rsp_complete
  , bdma2cvif_wr_req_valid
  , bdma2cvif_wr_req_ready
  , bdma2cvif_wr_req_pd

  // Interrupt to Global
  , bdma2glb_done_intr

  // Clock gating control
  , dla_clk_ovr_on_sync
  , global_clk_ovr_on_sync
  , tmc2slcg_disable_clock_gating

  // Powerbus
  , pwrbus_ram_pd
);

// +FHDR------------------------------------------------------------
// Parameter definitions
// +FHDR------------------------------------------------------------

// +FHDR------------------------------------------------------------
// Port declarations
// +FHDR------------------------------------------------------------
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB Interface
input         csb2bdma_req_pvld;
output        csb2bdma_req_prdy;
input  [62:0] csb2bdma_req_pd;
output        bdma2csb_resp_valid;
output [33:0] bdma2csb_resp_pd;

// MCIF Read Interface (to/from mcif_cvif router)
input         mcif2bdma_rd_rsp_valid;
output        mcif2bdma_rd_rsp_ready;
input  [513:0] mcif2bdma_rd_rsp_pd;
output        bdma2mcif_rd_req_valid;
input         bdma2mcif_rd_req_ready;
output [78:0] bdma2mcif_rd_req_pd;

// MCIF Write Interface (to/from mcif_cvif router)
input         mcif2bdma_wr_rsp_complete;
output        bdma2mcif_wr_req_valid;
input         bdma2mcif_wr_req_ready;
output [514:0] bdma2mcif_wr_req_pd;

// CVIF Read Interface (to/from mcif_cvif router)
input         cvif2bdma_rd_rsp_valid;
output        cvif2bdma_rd_rsp_ready;
input  [513:0] cvif2bdma_rd_rsp_pd;
output        bdma2cvif_rd_req_valid;
input         bdma2cvif_rd_req_ready;
output [78:0] bdma2cvif_rd_req_pd;

// CVIF Write Interface (to/from mcif_cvif router)
input         cvif2bdma_wr_rsp_complete;
output        bdma2cvif_wr_req_valid;
input         bdma2cvif_wr_req_ready;
output [514:0] bdma2cvif_wr_req_pd;

// Interrupt to Global
output [1:0]  bdma2glb_done_intr;

// Clock gating control
input         dla_clk_ovr_on_sync;
input         global_clk_ovr_on_sync;
input         tmc2slcg_disable_clock_gating;

// Powerbus
input  [31:0] pwrbus_ram_pd;

// +FHDR------------------------------------------------------------
// Wire declarations
// +FHDR------------------------------------------------------------

// CSB to Register signals
wire  [26:0]  reg2dp_src_addr_low_v32;
wire  [31:0]  reg2dp_src_addr_high_v8;
wire  [26:0]  reg2dp_dst_addr_low_v32;
wire  [31:0]  reg2dp_dst_addr_high_v8;
wire  [12:0]  reg2dp_line_size;
wire          reg2dp_cmd_src_ram_type;
wire          reg2dp_cmd_dst_ram_type;
wire  [23:0]  reg2dp_line_repeat_number;
wire  [26:0]  reg2dp_src_line_stride;
wire  [26:0]  reg2dp_dst_line_stride;
wire  [23:0]  reg2dp_surf_repeat_number;
wire  [26:0]  reg2dp_src_surf_stride;
wire  [26:0]  reg2dp_dst_surf_stride;
wire          reg2dp_op_en;
wire          reg2dp_launch0_grp0_launch;
wire          reg2dp_launch1_grp1_launch;
wire          reg2dp_status_stall_count_en;
wire          reg2dp_op_en_trigger;
wire          reg2dp_launch0_trigger;
wire          reg2dp_launch1_trigger;

// External status from engines
wire          ext_status_idle;
wire          ext_status_grp0_busy;
wire          ext_status_grp1_busy;
wire  [7:0]   ext_free_slot;

// Config packer to Load engine
wire          cfg2ld_vld;
wire          cfg2ld_rdy;
wire [151:0]  cfg2ld_pd;

// Load to Store interface (via CQ FIFO)
wire          ld2st_wr_pvld;
wire          ld2st_wr_prdy;
wire [160:0]  ld2st_wr_pd;
wire          ld2st_wr_idle;
wire          ld2st_rd_pvld;
wire          ld2st_rd_prdy;
wire [160:0]  ld2st_rd_pd;

// Load engine status
wire          ld2csb_idle;
wire          ld2gate_slcg_en;
wire          ld2csb_grp0_dma_stall_inc;
wire          ld2csb_grp1_dma_stall_inc;
wire          ld2st_wr_idle_from_load;

// Store engine status
wire          st2csb_idle;
wire          st2csb_grp0_done;
wire          st2csb_grp1_done;
wire          st2gate_slcg_en;
wire          st2ld_load_idle;
wire  [31:0]  dma_write_stall_count;
wire          dma_write_stall_count_cen;

// MCIF/CVIF internal routing (after mcif_cvif_new)
wire          mcif_rd_rsp_valid_int;
wire          mcif_rd_rsp_ready_int;
wire [513:0]  mcif_rd_rsp_pd_int;
wire          mcif_wr_rsp_complete_int;
wire          cvif_rd_rsp_valid_int;
wire          cvif_rd_rsp_ready_int;
wire [513:0]  cvif_rd_rsp_pd_int;
wire          cvif_wr_rsp_complete_int;

// Credit/latency FIFO control
wire          bdma2mcif_rd_cdt_lat_fifo_pop;
wire          bdma2cvif_rd_cdt_lat_fifo_pop;

// Clock gating
wire          csb2gate_slcg_en;
wire          nvdla_gated_clk;

// Free slot counting
wire  [7:0]   free_slot_count;
wire           free_slot_dec;
wire           free_slot_inc;
wire           free_slot_cen;
wire           ld_cmd_accepted;
wire           st_cmd_accepted;

// +FHDR------------------------------------------------------------
// Reg declarations
// +FHDR------------------------------------------------------------

// Free slot counter
reg  [7:0]    free_slot_count_q;
reg           free_slot_inc_q;
reg           free_slot_dec_q;

// +FHDR------------------------------------------------------------
// Clock Gating Instance
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_gate u_gate (
   .csb2gate_slcg_en              (csb2gate_slcg_en)
  ,.dla_clk_ovr_on_sync           (dla_clk_ovr_on_sync)
  ,.global_clk_ovr_on_sync        (global_clk_ovr_on_sync)
  ,.ld2gate_slcg_en               (ld2gate_slcg_en)
  ,.nvdla_core_clk                (nvdla_core_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  ,.st2gate_slcg_en               (st2gate_slcg_en)
  ,.tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  ,.nvdla_gated_clk               (nvdla_gated_clk)
  );

// +FHDR------------------------------------------------------------
// CSB Interface with embedded Register File
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_csb_new u_csb (
   .nvdla_core_clk                (nvdla_core_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  ,.csb2bdma_req_pvld             (csb2bdma_req_pvld)
  ,.csb2bdma_req_prdy             (csb2bdma_req_prdy)
  ,.csb2bdma_req_pd               (csb2bdma_req_pd)
  ,.bdma2csb_resp_valid           (bdma2csb_resp_valid)
  ,.bdma2csb_resp_pd              (bdma2csb_resp_pd)
  // Datapath outputs to config packer
  ,.reg2dp_src_addr_low_v32       (reg2dp_src_addr_low_v32)
  ,.reg2dp_src_addr_high_v8      (reg2dp_src_addr_high_v8)
  ,.reg2dp_dst_addr_low_v32       (reg2dp_dst_addr_low_v32)
  ,.reg2dp_dst_addr_high_v8       (reg2dp_dst_addr_high_v8)
  ,.reg2dp_line_size              (reg2dp_line_size)
  ,.reg2dp_cmd_src_ram_type       (reg2dp_cmd_src_ram_type)
  ,.reg2dp_cmd_dst_ram_type       (reg2dp_cmd_dst_ram_type)
  ,.reg2dp_line_repeat_number     (reg2dp_line_repeat_number)
  ,.reg2dp_src_line_stride        (reg2dp_src_line_stride)
  ,.reg2dp_dst_line_stride        (reg2dp_dst_line_stride)
  ,.reg2dp_surf_repeat_number     (reg2dp_surf_repeat_number)
  ,.reg2dp_src_surf_stride        (reg2dp_src_surf_stride)
  ,.reg2dp_dst_surf_stride        (reg2dp_dst_surf_stride)
  ,.reg2dp_op_en                  (reg2dp_op_en)
  ,.reg2dp_launch0_grp0_launch    (reg2dp_launch0_grp0_launch)
  ,.reg2dp_launch1_grp1_launch    (reg2dp_launch1_grp1_launch)
  ,.reg2dp_status_stall_count_en  (reg2dp_status_stall_count_en)
  ,.reg2dp_op_en_trigger          (reg2dp_op_en_trigger)
  ,.reg2dp_launch0_trigger        (reg2dp_launch0_trigger)
  ,.reg2dp_launch1_trigger        (reg2dp_launch1_trigger)
  // External status inputs
  ,.ext_status_idle              (ext_status_idle)
  ,.ext_status_grp0_busy         (ext_status_grp0_busy)
  ,.ext_status_grp1_busy         (ext_status_grp1_busy)
  ,.ext_free_slot                 (ext_free_slot)
  );

// +FHDR------------------------------------------------------------
// Config Packer - Pack reg2dp signals into cfg2ld format for Load
// +FHDR------------------------------------------------------------
// This module bridges the CSB/Reg outputs to the Load engine's
// config FIFO interface. It packs the register values into the
// 151-bit cfg2ld_pd format expected by the load engine.

NV_NVDLA_BDMA_config_packer u_config_packer (
   .nvdla_core_clk                (nvdla_core_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  // Input: reg2dp signals from CSB/Reg
  ,.reg2dp_src_addr_low_v32       (reg2dp_src_addr_low_v32)
  ,.reg2dp_src_addr_high_v8      (reg2dp_src_addr_high_v8)
  ,.reg2dp_dst_addr_low_v32       (reg2dp_dst_addr_low_v32)
  ,.reg2dp_dst_addr_high_v8       (reg2dp_dst_addr_high_v8)
  ,.reg2dp_line_size              (reg2dp_line_size)
  ,.reg2dp_cmd_src_ram_type       (reg2dp_cmd_src_ram_type)
  ,.reg2dp_cmd_dst_ram_type       (reg2dp_cmd_dst_ram_type)
  ,.reg2dp_line_repeat_number     (reg2dp_line_repeat_number)
  ,.reg2dp_src_line_stride        (reg2dp_src_line_stride)
  ,.reg2dp_dst_line_stride        (reg2dp_dst_line_stride)
  ,.reg2dp_surf_repeat_number     (reg2dp_surf_repeat_number)
  ,.reg2dp_src_surf_stride        (reg2dp_src_surf_stride)
  ,.reg2dp_dst_surf_stride        (reg2dp_dst_surf_stride)
  ,.reg2dp_op_en                  (reg2dp_op_en)
  ,.reg2dp_op_en_trigger          (reg2dp_op_en_trigger)
  // Output: cfg2ld signals to Load engine
  ,.cfg2ld_vld                    (cfg2ld_vld)
  ,.cfg2ld_rdy                    (cfg2ld_rdy)
  ,.cfg2ld_pd                     (cfg2ld_pd)
  // Status
  ,.cfg_cmd_accepted              (ld_cmd_accepted)
  );

// +FHDR------------------------------------------------------------
// Load Engine
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_load_new u_load (
   .nvdla_core_clk                (nvdla_gated_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  // MCIF interface
  ,.bdma2mcif_rd_req_ready        (bdma2mcif_rd_req_ready)
  ,.bdma2mcif_rd_req_valid        (bdma2mcif_rd_req_valid)
  ,.bdma2mcif_rd_req_pd           (bdma2mcif_rd_req_pd)
  // CVIF interface
  ,.bdma2cvif_rd_req_ready        (bdma2cvif_rd_req_ready)
  ,.bdma2cvif_rd_req_valid        (bdma2cvif_rd_req_valid)
  ,.bdma2cvif_rd_req_pd           (bdma2cvif_rd_req_pd)
  // Store engine interface
  ,.ld2st_wr_idle                 (ld2st_wr_idle_from_load)
  ,.ld2st_wr_prdy                 (ld2st_wr_prdy)
  ,.ld2st_wr_pvld                 (ld2st_wr_pvld)
  ,.ld2st_wr_pd                   (ld2st_wr_pd)
  // Config FIFO interface
  ,.cfg2ld_vld                    (cfg2ld_vld)
  ,.cfg2ld_rdy                    (cfg2ld_rdy)
  ,.cfg2ld_pd                     (cfg2ld_pd)
  // Status outputs
  ,.ld2csb_idle                   (ld2csb_idle)
  ,.ld2gate_slcg_en              (ld2gate_slcg_en)
  ,.ld2csb_grp0_dma_stall_inc    (ld2csb_grp0_dma_stall_inc)
  ,.ld2csb_grp1_dma_stall_inc    (ld2csb_grp1_dma_stall_inc)
  );

// +FHDR------------------------------------------------------------
// Command Queue FIFO - Bridge between Load and Store
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_cq u_cq (
   .nvdla_core_clk                (nvdla_gated_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  ,.ld2st_wr_prdy                 (ld2st_wr_prdy)
  ,.ld2st_wr_idle                (ld2st_wr_idle)
  ,.ld2st_wr_pvld                 (ld2st_wr_pvld)
  ,.ld2st_wr_pd                   (ld2st_wr_pd)
  ,.ld2st_rd_prdy                 (ld2st_rd_prdy)
  ,.ld2st_rd_pvld                 (ld2st_rd_pvld)
  ,.ld2st_rd_pd                   (ld2st_rd_pd)
  ,.pwrbus_ram_pd                 (pwrbus_ram_pd)
  );

assign ld2st_wr_idle_from_load = ld2st_wr_idle;

// +FHDR------------------------------------------------------------
// Store Engine
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_store_new u_store (
   .nvdla_core_clk                (nvdla_gated_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  // MCIF write interface
  ,.bdma2mcif_wr_req_ready        (bdma2mcif_wr_req_ready)
  ,.bdma2mcif_wr_req_valid        (bdma2mcif_wr_req_valid)
  ,.bdma2mcif_wr_req_pd           (bdma2mcif_wr_req_pd)
  // CVIF write interface
  ,.bdma2cvif_wr_req_ready        (bdma2cvif_wr_req_ready)
  ,.bdma2cvif_wr_req_valid        (bdma2cvif_wr_req_valid)
  ,.bdma2cvif_wr_req_pd           (bdma2cvif_wr_req_pd)
  // MCIF read response (data from memory)
  ,.mcif2bdma_rd_rsp_valid        (mcif2bdma_rd_rsp_valid)
  ,.mcif2bdma_rd_rsp_ready        (mcif2bdma_rd_rsp_ready)
  ,.mcif2bdma_rd_rsp_pd           (mcif2bdma_rd_rsp_pd)
  // CVIF read response (data from memory)
  ,.cvif2bdma_rd_rsp_valid        (cvif2bdma_rd_rsp_valid)
  ,.cvif2bdma_rd_rsp_ready        (cvif2bdma_rd_rsp_ready)
  ,.cvif2bdma_rd_rsp_pd           (cvif2bdma_rd_rsp_pd)
  // Write responses
  ,.mcif2bdma_wr_rsp_complete     (mcif2bdma_wr_rsp_complete)
  ,.cvif2bdma_wr_rsp_complete    (cvif2bdma_wr_rsp_complete)
  // Load engine interface (receives config+data info)
  ,.ld2st_rd_pvld                 (ld2st_rd_pvld)
  ,.ld2st_rd_prdy                 (ld2st_rd_prdy)
  ,.ld2st_rd_pd                   (ld2st_rd_pd)
  // Credit latency fifo pop
  ,.bdma2mcif_rd_cdt_lat_fifo_pop (bdma2mcif_rd_cdt_lat_fifo_pop)
  ,.bdma2cvif_rd_cdt_lat_fifo_pop (bdma2cvif_rd_cdt_lat_fifo_pop)
  // Status outputs
  ,.st2csb_idle                   (st2csb_idle)
  ,.st2csb_grp0_done              (st2csb_grp0_done)
  ,.st2csb_grp1_done              (st2csb_grp1_done)
  ,.st2gate_slcg_en              (st2gate_slcg_en)
  ,.st2ld_load_idle              (st2ld_load_idle)
  ,.dma_write_stall_count         (dma_write_stall_count)
  ,.dma_write_stall_count_cen     (dma_write_stall_count_cen)
  ,.pwrbus_ram_pd                 (pwrbus_ram_pd)
  );

// +FHDR------------------------------------------------------------
// MCIF/CVIF Router (passthrough)
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_mcif_cvif_new u_mcif_cvif (
   .nvdla_core_clk                (nvdla_core_clk)
  ,.nvdla_core_rstn               (nvdla_core_rstn)
  // MCIF Read Interface
  ,.mcif2bdma_rd_rsp_valid        (mcif2bdma_rd_rsp_valid)
  ,.mcif2bdma_rd_rsp_ready        (mcif2bdma_rd_rsp_ready)
  ,.mcif2bdma_rd_rsp_pd           (mcif2bdma_rd_rsp_pd)
  ,.bdma2mcif_rd_req_valid        (bdma2mcif_rd_req_valid)
  ,.bdma2mcif_rd_req_ready        (bdma2mcif_rd_req_ready)
  ,.bdma2mcif_rd_req_pd           (bdma2mcif_rd_req_pd)
  // MCIF Write Interface
  ,.mcif2bdma_wr_rsp_complete    (mcif2bdma_wr_rsp_complete)
  ,.bdma2mcif_wr_req_valid        (bdma2mcif_wr_req_valid)
  ,.bdma2mcif_wr_req_ready        (bdma2mcif_wr_req_ready)
  ,.bdma2mcif_wr_req_pd           (bdma2mcif_wr_req_pd)
  // CVIF Read Interface
  ,.cvif2bdma_rd_rsp_valid        (cvif2bdma_rd_rsp_valid)
  ,.cvif2bdma_rd_rsp_ready        (cvif2bdma_rd_rsp_ready)
  ,.cvif2bdma_rd_rsp_pd           (cvif2bdma_rd_rsp_pd)
  ,.bdma2cvif_rd_req_valid        (bdma2cvif_rd_req_valid)
  ,.bdma2cvif_rd_req_ready        (bdma2cvif_rd_req_ready)
  ,.bdma2cvif_rd_req_pd           (bdma2cvif_rd_req_pd)
  // CVIF Write Interface
  ,.cvif2bdma_wr_rsp_complete    (cvif2bdma_wr_rsp_complete)
  ,.bdma2cvif_wr_req_valid        (bdma2cvif_wr_req_valid)
  ,.bdma2cvif_wr_req_ready        (bdma2cvif_wr_req_ready)
  ,.bdma2cvif_wr_req_pd           (bdma2cvif_wr_req_pd)
  // Credit/latency FIFO control
  ,.bdma2mcif_rd_cdt_lat_fifo_pop (bdma2mcif_rd_cdt_lat_fifo_pop)
  ,.bdma2cvif_rd_cdt_lat_fifo_pop (bdma2cvif_rd_cdt_lat_fifo_pop)
  );

// +FHDR------------------------------------------------------------
// Status Aggregation
// +FHDR------------------------------------------------------------
// Aggregate idle status from both engines
assign ext_status_idle = ld2csb_idle & st2csb_idle;

// Busy status from groups (based on operation mode)
assign ext_status_grp0_busy = ld2csb_idle ? 1'b0 : ~ld2csb_idle;
assign ext_status_grp1_busy = 1'b0;  // Group 1 not used in current implementation

// Free slot tracking
assign free_slot_inc = ld_cmd_accepted;
assign free_slot_dec = st_cmd_accepted;
assign free_slot_cen = 1'b1;

// Free slot counter
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    free_slot_count_q <= 8'd20;  // BDMA_CONFIG_FIFO_DEPTH
  end else begin
    if (free_slot_cen) begin
      if (free_slot_inc & ~free_slot_dec) begin
        free_slot_count_q <= free_slot_count_q + 8'd1;
      end else if (~free_slot_inc & free_slot_dec) begin
        free_slot_count_q <= free_slot_count_q - 8'd1;
      end
    end
  end
end

assign ext_free_slot = free_slot_count_q;
assign dma_write_stall_count_cen = reg2dp_status_stall_count_en;

// CSB clock gating enable
assign csb2gate_slcg_en = reg2dp_op_en | reg2dp_launch0_grp0_launch | reg2dp_launch1_grp1_launch;

// +FHDR------------------------------------------------------------
// Interrupt Generation
// +FHDR------------------------------------------------------------
// Combine done interrupts from store engine
assign bdma2glb_done_intr = {st2csb_grp1_done, st2csb_grp0_done};

// +FHDR------------------------------------------------------------
// Assertions
// +FHDR------------------------------------------------------------
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON

// No X's allowed on critical control signals
`ifndef SYNTHESIS
  // VCS coverage off
  nv_assert_no_x #(0, 1, 0, "No X's allowed on csb2bdma_req_prdy")
    u_assert_csb_prdy (nvdla_core_clk, `ASSERT_RESET, 1'd1, (^csb2bdma_req_prdy));
  nv_assert_no_x #(0, 1, 0, "No X's allowed on bdma2csb_resp_valid")
    u_assert_resp_vld (nvdla_core_clk, `ASSERT_RESET, 1'd1, (^bdma2csb_resp_valid));
  // VCS coverage on
`endif

// Free slot should not underflow
`ifndef SYNTHESIS
  nv_assert_never #(0, 0, "Free slot counter underflow")
    u_assert_free_slot_underflow (nvdla_core_clk, `ASSERT_RESET, (free_slot_count_q == 8'd0) & free_slot_dec);
`endif

`undef ASSERT_RESET
`endif // ASSERT_ON

endmodule // NV_NVDLA_BDMA_new

// +FHDR------------------------------------------------------------
// Config Packer Submodule
// +FHDR------------------------------------------------------------
// Packs reg2dp_* signals from CSB/Register into cfg2ld_* format
// for the Load engine's config FIFO interface.
//
// cfg2ld_pd format (151 bits):
// [151] = 1'b0 (reserved)
// [150:148] = 3'd0 (reserved)
// [290:289] = {cmd_interrupt_ptr, cmd_interrupt}
// [288:262] = dst_surf_stride
// [261:235] = src_surf_stride
// [234:211] = surf_repeat_number
// [210:184] = dst_line_stride
// [183:157] = src_line_stride
// [156:133] = line_repeat_number
// [132] = cmd_dst_ram_type
// [131] = cmd_src_ram_type
// [130:118] = line_size
// [117:91] = dst_addr_low_v32
// [90:59] = dst_addr_high_v8
// [58:32] = src_addr_low_v32
// [31:0] = src_addr_high_v8
// +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_config_packer (
    nvdla_core_clk
  , nvdla_core_rstn
  // Input: reg2dp signals from CSB/Reg
  , reg2dp_src_addr_low_v32
  , reg2dp_src_addr_high_v8
  , reg2dp_dst_addr_low_v32
  , reg2dp_dst_addr_high_v8
  , reg2dp_line_size
  , reg2dp_cmd_src_ram_type
  , reg2dp_cmd_dst_ram_type
  , reg2dp_line_repeat_number
  , reg2dp_src_line_stride
  , reg2dp_dst_line_stride
  , reg2dp_surf_repeat_number
  , reg2dp_src_surf_stride
  , reg2dp_dst_surf_stride
  , reg2dp_op_en
  , reg2dp_op_en_trigger
  // Output: cfg2ld signals to Load engine
  , cfg2ld_vld
  , cfg2ld_rdy
  , cfg2ld_pd
  // Status
  , cfg_cmd_accepted
);

// +FHDR------------------------------------------------------------
// Port declarations
// +FHDR------------------------------------------------------------
input         nvdla_core_clk;
input         nvdla_core_rstn;

// Input: reg2dp signals
input  [26:0] reg2dp_src_addr_low_v32;
input  [31:0] reg2dp_src_addr_high_v8;
input  [26:0] reg2dp_dst_addr_low_v32;
input  [31:0] reg2dp_dst_addr_high_v8;
input  [12:0] reg2dp_line_size;
input         reg2dp_cmd_src_ram_type;
input         reg2dp_cmd_dst_ram_type;
input  [23:0] reg2dp_line_repeat_number;
input  [26:0] reg2dp_src_line_stride;
input  [26:0] reg2dp_dst_line_stride;
input  [23:0] reg2dp_surf_repeat_number;
input  [26:0] reg2dp_src_surf_stride;
input  [26:0] reg2dp_dst_surf_stride;
input         reg2dp_op_en;
input         reg2dp_op_en_trigger;

// Output: cfg2ld signals
output        cfg2ld_vld;
input         cfg2ld_rdy;
output [151:0] cfg2ld_pd;

// Status
output        cfg_cmd_accepted;

// +FHDR------------------------------------------------------------
// Wire declarations
// +FHDR------------------------------------------------------------

// +FHDR------------------------------------------------------------
// Reg declarations
// +FHDR------------------------------------------------------------
reg           cfg2ld_vld_q;
reg  [151:0]  cfg2ld_pd_q;
reg           cfg_cmd_accepted_q;
reg           op_en_trigger_d1;

// +FHDR------------------------------------------------------------
// Config packing logic
// +FHDR------------------------------------------------------------
// Pack the config values into cfg2ld_pd format
// Format: [151] reserved, [150:148] reserved, [290:289] interrupt fields,
// [288:262] dst_surf_stride, [261:235] src_surf_stride, [234:211] surf_repeat,
// [210:184] dst_line_stride, [183:157] src_line_stride, [156:133] line_repeat,
// [132] dst_ram_type, [131] src_ram_type, [130:118] line_size,
// [117:91] dst_addr_low, [90:59] dst_addr_high, [58:32] src_addr_low, [31:0] src_addr_high

always @* begin
  cfg2ld_pd_q = 152'd0;
  cfg2ld_pd_q[31:0] = reg2dp_src_addr_high_v8[31:0];
  cfg2ld_pd_q[58:32] = reg2dp_src_addr_low_v32[26:0];
  cfg2ld_pd_q[90:59] = reg2dp_dst_addr_high_v8[31:0];
  cfg2ld_pd_q[117:91] = reg2dp_dst_addr_low_v32[26:0];
  cfg2ld_pd_q[130:118] = reg2dp_line_size[12:0];
  cfg2ld_pd_q[131] = reg2dp_cmd_src_ram_type;
  cfg2ld_pd_q[132] = reg2dp_cmd_dst_ram_type;
  cfg2ld_pd_q[156:133] = reg2dp_line_repeat_number[23:0];
  cfg2ld_pd_q[183:157] = reg2dp_src_line_stride[26:0];
  cfg2ld_pd_q[210:184] = reg2dp_dst_line_stride[26:0];
  cfg2ld_pd_q[234:211] = reg2dp_surf_repeat_number[23:0];
  cfg2ld_pd_q[261:235] = reg2dp_src_surf_stride[26:0];
  cfg2ld_pd_q[288:262] = reg2dp_dst_surf_stride[26:0];
  cfg2ld_pd_q[290:289] = 2'b00;  // interrupt ptr and flag from reg
end

// Trigger detection - generate pulse on op_en_trigger rising edge
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_trigger_d1 <= 1'b0;
    cfg2ld_vld_q <= 1'b0;
  end else begin
    op_en_trigger_d1 <= reg2dp_op_en_trigger;
    // Generate valid pulse when op_en_trigger rises
    cfg2ld_vld_q <= reg2dp_op_en_trigger & ~op_en_trigger_d1;
  end
end

assign cfg2ld_vld = cfg2ld_vld_q;
assign cfg2ld_pd = cfg2ld_pd_q;

// Command accepted when load engine accepts the config
assign cfg_cmd_accepted = cfg2ld_vld_q & cfg2ld_rdy;

endmodule // NV_NVDLA_BDMA_config_packer