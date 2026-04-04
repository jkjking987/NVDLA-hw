// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_SDP_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// SDP (Second Data Processor) Top-Level Integration
// - CSB interface for register configuration
// - X1/X2/Y processing paths
// - Combination logic
// - Output to WDMA or PDP
// +FHDR------------------------------------------------------------

`include "simulate_x_tick.vh"
module NV_NVDLA_SDP_new (
   // Clock and reset
   nvdla_core_clk                  //|< i
  ,nvdla_core_rstn                 //|< i
  // CSB interface
  ,csb2sdp_req_pd                  //|< i
  ,csb2sdp_req_pvld                //|< i
  ,csb2sdp_req_prdy                //|> o
  ,sdp2csb_resp_pd                 //|> o
  ,sdp2csb_resp_valid              //|> o
  // CACC interface (flying mode)
  ,cacc2sdp_pd                     //|< i
  ,cacc2sdp_valid                  //|< i
  ,cacc2sdp_ready                  //|> o
  // Interrupt
  ,sdp2glb_done_intr_pd            //|> o
  // DMA write interface
  ,sdp2mcif_wr_req_valid          //|> o
  ,sdp2mcif_wr_req_ready          //|< i
  ,sdp2mcif_wr_req_pd             //|> o
  ,mcif2sdp_wr_rsp_complete       //|< i
  ,sdp2cvif_wr_req_valid          //|> o
  ,sdp2cvif_wr_req_ready          //|< i
  ,sdp2cvif_wr_req_pd             //|> o
  ,cvif2sdp_wr_rsp_complete       //|< i
  // Performance counters
  ,dp2reg_done                     //|< i
  ,dp2reg_lut_hybrid              //|< i
  ,dp2reg_lut_int_data            //|< i
  ,dp2reg_lut_le_hit              //|< i
  ,dp2reg_lut_lo_hit              //|< i
  ,dp2reg_lut_oflow               //|< i
  ,dp2reg_lut_uflow               //|< i
  ,dp2reg_out_saturation          //|< i
  ,dp2reg_status_inf_input_num    //|< i
  ,dp2reg_status_nan_input_num    //|< i
  ,dp2reg_status_nan_output_num   //|< i
  ,dp2reg_status_unequal          //|< i
  ,dp2reg_wdma_stall              //|< i
  // PDP interface
  ,sdp2pdp_pd                     //|> o
  ,sdp2pdp_valid                  //|> o
  ,sdp2pdp_ready                  //|< i
  );

//============================================================================
// parameters
//============================================================================
localparam [1:0] PRECISION_INT16 = 2'd0;
localparam [1:0] PRECISION_FP16   = 2'd1;
localparam [1:0] PRECISION_INT8   = 2'd2;

// Flying mode
localparam FLYING_MODE_OFF = 1'b0;
localparam FLYING_MODE_ON  = 1'b1;

// Output destination
localparam OUTPUT_DST_MEM = 1'b0;
localparam OUTPUT_DST_PDP = 1'b1;

//============================================================================
// signal declarations
//============================================================================
// Clock and reset
wire nvdla_core_clk;
wire nvdla_core_rstn;

// CSB interface
wire [62:0] csb2sdp_req_pd;
wire csb2sdp_req_pvld;
wire csb2sdp_req_prdy;
wire [33:0] sdp2csb_resp_pd;
wire sdp2csb_resp_valid;

// CACC interface
wire [511:0] cacc2sdp_pd;
wire cacc2sdp_valid;
wire cacc2sdp_ready;

// Interrupt
wire [1:0] sdp2glb_done_intr_pd;

// DMA write
wire sdp2mcif_wr_req_valid;
wire sdp2mcif_wr_req_ready;
wire [514:0] sdp2mcif_wr_req_pd;
wire mcif2sdp_wr_rsp_complete;
wire sdp2cvif_wr_req_valid;
wire sdp2cvif_wr_req_ready;
wire [514:0] sdp2cvif_wr_req_pd;
wire cvif2sdp_wr_rsp_complete;

// Performance counters
wire dp2reg_done;
wire [31:0] dp2reg_lut_hybrid;
wire [15:0] dp2reg_lut_int_data;
wire [31:0] dp2reg_lut_le_hit;
wire [31:0] dp2reg_lut_lo_hit;
wire [31:0] dp2reg_lut_oflow;
wire [31:0] dp2reg_lut_uflow;
wire [31:0] dp2reg_out_saturation;
wire [31:0] dp2reg_status_inf_input_num;
wire [31:0] dp2reg_status_nan_input_num;
wire [31:0] dp2reg_status_nan_output_num;
wire dp2reg_status_unequal;
wire [31:0] dp2reg_wdma_stall;

// PDP interface
wire [255:0] sdp2pdp_pd;
wire sdp2pdp_valid;
wire sdp2pdp_ready;

// Register outputs
wire [4:0] reg2dp_batch_number;
wire reg2dp_bcore_slcg_op_en;
wire [1:0] reg2dp_bn_alu_algo;
wire reg2dp_bn_alu_bypass;
wire [15:0] reg2dp_bn_alu_operand;
wire [5:0] reg2dp_bn_alu_shift_value;
wire reg2dp_bn_alu_src;
wire reg2dp_bn_bypass;
wire reg2dp_bn_mul_bypass;
wire [15:0] reg2dp_bn_mul_operand;
wire reg2dp_bn_mul_prelu;
wire [7:0] reg2dp_bn_mul_shift_value;
wire reg2dp_bn_mul_src;
wire reg2dp_bn_relu_bypass;
wire [1:0] reg2dp_bs_alu_algo;
wire reg2dp_bs_alu_bypass;
wire [15:0] reg2dp_bs_alu_operand;
wire [5:0] reg2dp_bs_alu_shift_value;
wire reg2dp_bs_alu_src;
wire reg2dp_bs_bypass;
wire reg2dp_bs_mul_bypass;
wire [15:0] reg2dp_bs_mul_operand;
wire reg2dp_bs_mul_prelu;
wire [7:0] reg2dp_bs_mul_shift_value;
wire reg2dp_bs_mul_src;
wire reg2dp_bs_relu_bypass;
wire [12:0] reg2dp_channel;
wire [31:0] reg2dp_cvt_offset;
wire [15:0] reg2dp_cvt_scale;
wire [5:0] reg2dp_cvt_shift;
wire [31:0] reg2dp_dst_base_addr_high;
wire [26:0] reg2dp_dst_base_addr_low;
wire [26:0] reg2dp_dst_batch_stride;
wire [26:0] reg2dp_dst_line_stride;
wire reg2dp_dst_ram_type;
wire [26:0] reg2dp_dst_surface_stride;
wire reg2dp_ecore_slcg_op_en;
wire [1:0] reg2dp_ew_alu_algo;
wire reg2dp_ew_alu_bypass;
wire reg2dp_ew_alu_cvt_bypass;
wire [31:0] reg2dp_ew_alu_cvt_offset;
wire [15:0] reg2dp_ew_alu_cvt_scale;
wire [5:0] reg2dp_ew_alu_cvt_truncate;
wire [31:0] reg2dp_ew_alu_operand;
wire reg2dp_ew_alu_src;
wire reg2dp_ew_bypass;
wire reg2dp_ew_lut_bypass;
wire reg2dp_ew_mul_bypass;
wire reg2dp_ew_mul_cvt_bypass;
wire [31:0] reg2dp_ew_mul_cvt_offset;
wire [15:0] reg2dp_ew_mul_cvt_scale;
wire [5:0] reg2dp_ew_mul_cvt_truncate;
wire [31:0] reg2dp_ew_mul_operand;
wire reg2dp_ew_mul_prelu;
wire reg2dp_ew_mul_src;
wire [9:0] reg2dp_ew_truncate;
wire reg2dp_flying_mode;
wire [12:0] reg2dp_height;
wire reg2dp_interrupt_ptr;
wire reg2dp_lut_hybrid_priority;
wire reg2dp_lut_int_access_type;
wire [9:0] reg2dp_lut_int_addr;
wire [15:0] reg2dp_lut_int_data;
wire reg2dp_lut_int_data_wr;
wire reg2dp_lut_int_table_id;
wire [31:0] reg2dp_lut_le_end;
wire reg2dp_lut_le_function;
wire [7:0] reg2dp_lut_le_index_offset;
wire [7:0] reg2dp_lut_le_index_select;
wire [15:0] reg2dp_lut_le_slope_oflow_scale;
wire [4:0] reg2dp_lut_le_slope_oflow_shift;
wire [15:0] reg2dp_lut_le_slope_uflow_scale;
wire [4:0] reg2dp_lut_le_slope_uflow_shift;
wire [31:0] reg2dp_lut_le_start;
wire [31:0] reg2dp_lut_lo_end;
wire [7:0] reg2dp_lut_lo_index_select;
wire [15:0] reg2dp_lut_lo_slope_oflow_scale;
wire [4:0] reg2dp_lut_lo_slope_oflow_shift;
wire [15:0] reg2dp_lut_lo_slope_uflow_scale;
wire [4:0] reg2dp_lut_lo_slope_uflow_shift;
wire [31:0] reg2dp_lut_lo_start;
wire reg2dp_lut_oflow_priority;
wire reg2dp_lut_slcg_en;
wire reg2dp_lut_uflow_priority;
wire reg2dp_nan_to_zero;
wire reg2dp_ncore_slcg_op_en;
wire reg2dp_op_en;
wire [1:0] reg2dp_out_precision;
wire reg2dp_output_dst;
wire reg2dp_perf_dma_en;
wire reg2dp_perf_lut_en;
wire reg2dp_perf_nan_inf_count_en;
wire reg2dp_perf_sat_en;
wire [1:0] reg2dp_proc_precision;
wire reg2dp_wdma_slcg_op_en;
wire [12:0] reg2dp_width;
wire reg2dp_winograd;

// Internal processing data
wire [255:0] x1_in_data;
wire x1_in_valid;
wire x1_in_ready;
wire [255:0] x1_out_data;
wire x1_out_valid;
wire x1_out_ready;

wire [255:0] x2_in_data;
wire x2_in_valid;
wire x2_in_ready;
wire [255:0] x2_out_data;
wire x2_out_valid;
wire x2_out_ready;

wire [255:0] y_in_data;
wire y_in_valid;
wire y_in_ready;
wire [255:0] y_lut_out;
wire y_lut_out_valid;
wire y_lut_in_ready;
wire [255:0] y_out_data;
wire y_out_valid;
wire y_out_ready;

// Combined output
reg [255:0] combined_out_r;
reg combined_valid_r;

// State machine
localparam [1:0] STATE_IDLE    = 2'd0;
localparam [1:0] STATE_PROCESS = 2'd1;
localparam [1:0] STATE_DONE   = 2'd2;

reg [1:0] state_q;
reg [1:0] state_next;

// Done pulse generation
reg done_pulse_r;
reg [1:0] reg2dp_interrupt_ptr_r;

//============================================================================
// Register file instantiation
//============================================================================
NV_NVDLA_SDP_reg_new u_reg (
   .nvdla_core_clk                  (nvdla_core_clk)
  ,.nvdla_core_rstn                 (nvdla_core_rstn)
  // CSB interface
  ,.csb2sdp_req_pd                  (csb2sdp_req_pd)
  ,.csb2sdp_req_pvld                (csb2sdp_req_pvld)
  ,.csb2sdp_req_prdy                (csb2sdp_req_prdy)
  ,.sdp2csb_resp_pd                 (sdp2csb_resp_pd)
  ,.sdp2csb_resp_valid              (sdp2csb_resp_valid)
  // Status from datapath
  ,.dp2reg_done                     (dp2reg_done)
  ,.dp2reg_lut_hybrid               (dp2reg_lut_hybrid)
  ,.dp2reg_lut_int_data             (dp2reg_lut_int_data)
  ,.dp2reg_lut_le_hit               (dp2reg_lut_le_hit)
  ,.dp2reg_lut_lo_hit               (dp2reg_lut_lo_hit)
  ,.dp2reg_lut_oflow                (dp2reg_lut_oflow)
  ,.dp2reg_lut_uflow               (dp2reg_lut_uflow)
  ,.dp2reg_out_saturation           (dp2reg_out_saturation)
  ,.dp2reg_status_inf_input_num     (dp2reg_status_inf_input_num)
  ,.dp2reg_status_nan_input_num     (dp2reg_status_nan_input_num)
  ,.dp2reg_status_nan_output_num    (dp2reg_status_nan_output_num)
  ,.dp2reg_status_unequal           (dp2reg_status_unequal)
  ,.dp2reg_wdma_stall              (dp2reg_wdma_stall)
  // Configuration outputs
  ,.reg2dp_batch_number             (reg2dp_batch_number)
  ,.reg2dp_bcore_slcg_op_en         (reg2dp_bcore_slcg_op_en)
  ,.reg2dp_bn_alu_algo              (reg2dp_bn_alu_algo)
  ,.reg2dp_bn_alu_bypass            (reg2dp_bn_alu_bypass)
  ,.reg2dp_bn_alu_operand           (reg2dp_bn_alu_operand)
  ,.reg2dp_bn_alu_shift_value       (reg2dp_bn_alu_shift_value)
  ,.reg2dp_bn_alu_src               (reg2dp_bn_alu_src)
  ,.reg2dp_bn_bypass                (reg2dp_bn_bypass)
  ,.reg2dp_bn_mul_bypass            (reg2dp_bn_mul_bypass)
  ,.reg2dp_bn_mul_operand           (reg2dp_bn_mul_operand)
  ,.reg2dp_bn_mul_prelu             (reg2dp_bn_mul_prelu)
  ,.reg2dp_bn_mul_shift_value       (reg2dp_bn_mul_shift_value)
  ,.reg2dp_bn_mul_src               (reg2dp_bn_mul_src)
  ,.reg2dp_bn_relu_bypass           (reg2dp_bn_relu_bypass)
  ,.reg2dp_bs_alu_algo              (reg2dp_bs_alu_algo)
  ,.reg2dp_bs_alu_bypass            (reg2dp_bs_alu_bypass)
  ,.reg2dp_bs_alu_operand           (reg2dp_bs_alu_operand)
  ,.reg2dp_bs_alu_shift_value       (reg2dp_bs_alu_shift_value)
  ,.reg2dp_bs_alu_src               (reg2dp_bs_alu_src)
  ,.reg2dp_bs_bypass                (reg2dp_bs_bypass)
  ,.reg2dp_bs_mul_bypass            (reg2dp_bs_mul_bypass)
  ,.reg2dp_bs_mul_operand           (reg2dp_bs_mul_operand)
  ,.reg2dp_bs_mul_prelu             (reg2dp_bs_mul_prelu)
  ,.reg2dp_bs_mul_shift_value       (reg2dp_bs_mul_shift_value)
  ,.reg2dp_bs_mul_src               (reg2dp_bs_mul_src)
  ,.reg2dp_bs_relu_bypass           (reg2dp_bs_relu_bypass)
  ,.reg2dp_channel                  (reg2dp_channel)
  ,.reg2dp_cvt_offset               (reg2dp_cvt_offset)
  ,.reg2dp_cvt_scale                (reg2dp_cvt_scale)
  ,.reg2dp_cvt_shift                (reg2dp_cvt_shift)
  ,.reg2dp_dst_base_addr_high       (reg2dp_dst_base_addr_high)
  ,.reg2dp_dst_base_addr_low        (reg2dp_dst_base_addr_low)
  ,.reg2dp_dst_batch_stride         (reg2dp_dst_batch_stride)
  ,.reg2dp_dst_line_stride          (reg2dp_dst_line_stride)
  ,.reg2dp_dst_ram_type             (reg2dp_dst_ram_type)
  ,.reg2dp_dst_surface_stride       (reg2dp_dst_surface_stride)
  ,.reg2dp_ecore_slcg_op_en         (reg2dp_ecore_slcg_op_en)
  ,.reg2dp_ew_alu_algo              (reg2dp_ew_alu_algo)
  ,.reg2dp_ew_alu_bypass            (reg2dp_ew_alu_bypass)
  ,.reg2dp_ew_alu_cvt_bypass        (reg2dp_ew_alu_cvt_bypass)
  ,.reg2dp_ew_alu_cvt_offset        (reg2dp_ew_alu_cvt_offset)
  ,.reg2dp_ew_alu_cvt_scale         (reg2dp_ew_alu_cvt_scale)
  ,.reg2dp_ew_alu_cvt_truncate      (reg2dp_ew_alu_cvt_truncate)
  ,.reg2dp_ew_alu_operand           (reg2dp_ew_alu_operand)
  ,.reg2dp_ew_alu_src               (reg2dp_ew_alu_src)
  ,.reg2dp_ew_bypass                (reg2dp_ew_bypass)
  ,.reg2dp_ew_lut_bypass            (reg2dp_ew_lut_bypass)
  ,.reg2dp_ew_mul_bypass            (reg2dp_ew_mul_bypass)
  ,.reg2dp_ew_mul_cvt_bypass        (reg2dp_ew_mul_cvt_bypass)
  ,.reg2dp_ew_mul_cvt_offset        (reg2dp_ew_mul_cvt_offset)
  ,.reg2dp_ew_mul_cvt_scale         (reg2dp_ew_mul_cvt_scale)
  ,.reg2dp_ew_mul_cvt_truncate      (reg2dp_ew_mul_cvt_truncate)
  ,.reg2dp_ew_mul_operand           (reg2dp_ew_mul_operand)
  ,.reg2dp_ew_mul_prelu             (reg2dp_ew_mul_prelu)
  ,.reg2dp_ew_mul_src               (reg2dp_ew_mul_src)
  ,.reg2dp_ew_truncate              (reg2dp_ew_truncate)
  ,.reg2dp_flying_mode              (reg2dp_flying_mode)
  ,.reg2dp_height                   (reg2dp_height)
  ,.reg2dp_interrupt_ptr            (reg2dp_interrupt_ptr)
  ,.reg2dp_lut_hybrid_priority      (reg2dp_lut_hybrid_priority)
  ,.reg2dp_lut_int_access_type      (reg2dp_lut_int_access_type)
  ,.reg2dp_lut_int_addr             (reg2dp_lut_int_addr)
  ,.reg2dp_lut_int_data             (reg2dp_lut_int_data)
  ,.reg2dp_lut_int_data_wr          (reg2dp_lut_int_data_wr)
  ,.reg2dp_lut_int_table_id         (reg2dp_lut_int_table_id)
  ,.reg2dp_lut_le_end               (reg2dp_lut_le_end)
  ,.reg2dp_lut_le_function          (reg2dp_lut_le_function)
  ,.reg2dp_lut_le_index_offset      (reg2dp_lut_le_index_offset)
  ,.reg2dp_lut_le_index_select      (reg2dp_lut_le_index_select)
  ,.reg2dp_lut_le_slope_oflow_scale (reg2dp_lut_le_slope_oflow_scale)
  ,.reg2dp_lut_le_slope_oflow_shift (reg2dp_lut_le_slope_oflow_shift)
  ,.reg2dp_lut_le_slope_uflow_scale (reg2dp_lut_le_slope_uflow_scale)
  ,.reg2dp_lut_le_slope_uflow_shift (reg2dp_lut_le_slope_uflow_shift)
  ,.reg2dp_lut_le_start             (reg2dp_lut_le_start)
  ,.reg2dp_lut_lo_end               (reg2dp_lut_lo_end)
  ,.reg2dp_lut_lo_index_select      (reg2dp_lut_lo_index_select)
  ,.reg2dp_lut_lo_slope_oflow_scale (reg2dp_lut_lo_slope_oflow_scale)
  ,.reg2dp_lut_lo_slope_oflow_shift (reg2dp_lut_lo_slope_oflow_shift)
  ,.reg2dp_lut_lo_slope_uflow_scale (reg2dp_lut_lo_slope_uflow_scale)
  ,.reg2dp_lut_lo_slope_uflow_shift (reg2dp_lut_lo_slope_uflow_shift)
  ,.reg2dp_lut_lo_start             (reg2dp_lut_lo_start)
  ,.reg2dp_lut_oflow_priority       (reg2dp_lut_oflow_priority)
  ,.reg2dp_lut_slcg_en              (reg2dp_lut_slcg_en)
  ,.reg2dp_lut_uflow_priority       (reg2dp_lut_uflow_priority)
  ,.reg2dp_nan_to_zero              (reg2dp_nan_to_zero)
  ,.reg2dp_ncore_slcg_op_en         (reg2dp_ncore_slcg_op_en)
  ,.reg2dp_op_en                    (reg2dp_op_en)
  ,.reg2dp_out_precision            (reg2dp_out_precision)
  ,.reg2dp_output_dst               (reg2dp_output_dst)
  ,.reg2dp_perf_dma_en              (reg2dp_perf_dma_en)
  ,.reg2dp_perf_lut_en              (reg2dp_perf_lut_en)
  ,.reg2dp_perf_nan_inf_count_en    (reg2dp_perf_nan_inf_count_en)
  ,.reg2dp_perf_sat_en              (reg2dp_perf_sat_en)
  ,.reg2dp_proc_precision           (reg2dp_proc_precision)
  ,.reg2dp_wdma_slcg_op_en          (reg2dp_wdma_slcg_op_en)
  ,.reg2dp_width                    (reg2dp_width)
  ,.reg2dp_winograd                 (reg2dp_winograd)
  );

//============================================================================
// X1 processing path instantiation
//============================================================================
NV_NVDLA_SDP_x1_new u_x1 (
   .nvdla_core_clk              (nvdla_core_clk)
  ,.nvdla_core_rstn             (nvdla_core_rstn)
  // Input
  ,.x1_in_data                  (cacc2sdp_pd[255:0])  // From CACC or internal
  ,.x1_in_valid                 (cacc2sdp_valid)
  ,.x1_in_ready                 (x1_in_ready)
  // ALU operand (from memory - not connected in this placeholder)
  ,.x1_alu_op                   (256'b0)
  ,.x1_alu_op_valid             (1'b0)
  // MUL operand (from memory - not connected in this placeholder)
  ,.x1_mul_op                   (256'b0)
  ,.x1_mul_op_valid             (1'b0)
  // Configuration
  ,.cfg_x1_bypass               (reg2dp_bs_bypass)
  ,.cfg_x1_alu_bypass           (reg2dp_bs_alu_bypass)
  ,.cfg_x1_alu_algo             (reg2dp_bs_alu_algo)
  ,.cfg_x1_alu_src              (reg2dp_bs_alu_src)
  ,.cfg_x1_alu_shift_value      (reg2dp_bs_alu_shift_value)
  ,.cfg_x1_alu_operand          (reg2dp_bs_alu_operand)
  ,.cfg_x1_mul_bypass           (reg2dp_bs_mul_bypass)
  ,.cfg_x1_mul_src              (reg2dp_bs_mul_src)
  ,.cfg_x1_mul_shift_value      (reg2dp_bs_mul_shift_value)
  ,.cfg_x1_mul_operand          (reg2dp_bs_mul_operand)
  ,.cfg_x1_mul_prelu            (reg2dp_bs_mul_prelu)
  ,.cfg_x1_relu_bypass          (reg2dp_bs_relu_bypass)
  ,.cfg_x1_nan_to_zero          (reg2dp_nan_to_zero)
  ,.cfg_x1_proc_precision       (reg2dp_proc_precision)
  // Output
  ,.x1_out_data                 (x1_out_data)
  ,.x1_out_valid                (x1_out_valid)
  ,.x1_out_ready                (x1_out_ready)
  );

//============================================================================
// X2 processing path instantiation
//============================================================================
NV_NVDLA_SDP_x2_new u_x2 (
   .nvdla_core_clk              (nvdla_core_clk)
  ,.nvdla_core_rstn             (nvdla_core_rstn)
  // Input
  ,.x2_in_data                  (cacc2sdp_pd[255:0])  // Same input as X1
  ,.x2_in_valid                 (cacc2sdp_valid)
  ,.x2_in_ready                 (x2_in_ready)
  // ALU operand (from memory - not connected in this placeholder)
  ,.x2_alu_op                   (256'b0)
  ,.x2_alu_op_valid             (1'b0)
  // MUL operand (from memory - not connected in this placeholder)
  ,.x2_mul_op                   (256'b0)
  ,.x2_mul_op_valid             (1'b0)
  // Configuration
  ,.cfg_x2_bypass               (reg2dp_bn_bypass)
  ,.cfg_x2_alu_bypass           (reg2dp_bn_alu_bypass)
  ,.cfg_x2_alu_algo             (reg2dp_bn_alu_algo)
  ,.cfg_x2_alu_src              (reg2dp_bn_alu_src)
  ,.cfg_x2_alu_shift_value      (reg2dp_bn_alu_shift_value)
  ,.cfg_x2_alu_operand          (reg2dp_bn_alu_operand)
  ,.cfg_x2_mul_bypass           (reg2dp_bn_mul_bypass)
  ,.cfg_x2_mul_src              (reg2dp_bn_mul_src)
  ,.cfg_x2_mul_shift_value      (reg2dp_bn_mul_shift_value)
  ,.cfg_x2_mul_operand          (reg2dp_bn_mul_operand)
  ,.cfg_x2_mul_prelu            (reg2dp_bn_mul_prelu)
  ,.cfg_x2_relu_bypass          (reg2dp_bn_relu_bypass)
  ,.cfg_x2_nan_to_zero          (reg2dp_nan_to_zero)
  ,.cfg_x2_proc_precision       (reg2dp_proc_precision)
  // Output
  ,.x2_out_data                 (x2_out_data)
  ,.x2_out_valid                (x2_out_valid)
  ,.x2_out_ready                (x2_out_ready)
  );

//============================================================================
// Y processing path instantiation
//============================================================================
NV_NVDLA_SDP_y_new u_y (
   .nvdla_core_clk              (nvdla_core_clk)
  ,.nvdla_core_rstn             (nvdla_core_rstn)
  // Input
  ,.y_in_data                   (cacc2sdp_pd[255:0])  // Same input
  ,.y_in_valid                  (cacc2sdp_valid)
  ,.y_in_ready                  (y_in_ready)
  // ALU operand (from memory - not connected in this placeholder)
  ,.y_alu_op                    (256'b0)
  ,.y_alu_op_valid              (1'b0)
  // MUL operand (from memory - not connected in this placeholder)
  ,.y_mul_op                    (256'b0)
  ,.y_mul_op_valid              (1'b0)
  // LUT output passthrough
  ,.y_lut_out                   (y_lut_out)
  ,.y_lut_out_valid             (y_lut_out_valid)
  ,.y_lut_in_ready              (1'b1)  // Always ready
  // Configuration
  ,.cfg_y_bypass                (reg2dp_ew_bypass)
  ,.cfg_y_alu_bypass            (reg2dp_ew_alu_bypass)
  ,.cfg_y_alu_algo              (reg2dp_ew_alu_algo)
  ,.cfg_y_alu_src               (reg2dp_ew_alu_src)
  ,.cfg_y_alu_cvt_bypass        (reg2dp_ew_alu_cvt_bypass)
  ,.cfg_y_alu_cvt_offset        (reg2dp_ew_alu_cvt_offset)
  ,.cfg_y_alu_cvt_scale         (reg2dp_ew_alu_cvt_scale)
  ,.cfg_y_alu_cvt_truncate      (reg2dp_ew_alu_cvt_truncate)
  ,.cfg_y_alu_operand           (reg2dp_ew_alu_operand)
  ,.cfg_y_mul_bypass            (reg2dp_ew_mul_bypass)
  ,.cfg_y_mul_src               (reg2dp_ew_mul_src)
  ,.cfg_y_mul_cvt_bypass        (reg2dp_ew_mul_cvt_bypass)
  ,.cfg_y_mul_cvt_offset        (reg2dp_ew_mul_cvt_offset)
  ,.cfg_y_mul_cvt_scale         (reg2dp_ew_mul_cvt_scale)
  ,.cfg_y_mul_cvt_truncate      (reg2dp_ew_mul_cvt_truncate)
  ,.cfg_y_mul_operand           (reg2dp_ew_mul_operand)
  ,.cfg_y_mul_prelu            (reg2dp_ew_mul_prelu)
  ,.cfg_y_truncate              (reg2dp_ew_truncate)
  ,.cfg_y_lut_bypass            (reg2dp_ew_lut_bypass)
  ,.cfg_y_lut_le_function       (reg2dp_lut_le_function)
  ,.cfg_y_lut_le_start          (reg2dp_lut_le_start[15:0])
  ,.cfg_y_lut_le_end            (reg2dp_lut_le_end[15:0])
  ,.cfg_y_lut_le_index_offset   (reg2dp_lut_le_index_offset)
  ,.cfg_y_lut_le_index_select   (reg2dp_lut_le_index_select)
  ,.cfg_y_lut_lo_start          (reg2dp_lut_lo_start[15:0])
  ,.cfg_y_lut_lo_end            (reg2dp_lut_lo_end[15:0])
  ,.cfg_y_lut_lo_index_select   (reg2dp_lut_lo_index_select)
  ,.cfg_y_lut_uflow_priority    (reg2dp_lut_uflow_priority)
  ,.cfg_y_lut_oflow_priority    (reg2dp_lut_oflow_priority)
  ,.cfg_y_lut_hybrid_priority   (reg2dp_lut_hybrid_priority)
  ,.cfg_y_lut_le_uflow_scale    (reg2dp_lut_le_slope_uflow_scale)
  ,.cfg_y_lut_le_uflow_shift    (reg2dp_lut_le_slope_uflow_shift)
  ,.cfg_y_lut_le_oflow_scale    (reg2dp_lut_le_slope_oflow_scale)
  ,.cfg_y_lut_le_oflow_shift    (reg2dp_lut_le_slope_oflow_shift)
  ,.cfg_y_lut_lo_uflow_scale    (reg2dp_lut_lo_slope_uflow_scale)
  ,.cfg_y_lut_lo_uflow_shift    (reg2dp_lut_lo_slope_uflow_shift)
  ,.cfg_y_lut_lo_oflow_scale    (reg2dp_lut_lo_slope_oflow_scale)
  ,.cfg_y_lut_lo_oflow_shift    (reg2dp_lut_lo_slope_oflow_shift)
  ,.cfg_y_nan_to_zero           (reg2dp_nan_to_zero)
  ,.cfg_y_proc_precision        (reg2dp_proc_precision)
  // Output
  ,.y_out_data                  (y_out_data)
  ,.y_out_valid                 (y_out_valid)
  ,.y_out_ready                 (y_out_ready)
  );

//============================================================================
// Output combination logic
//============================================================================
// Combination of X1, X2, Y outputs
// The actual combination depends on the mode:
// - All three paths can be enabled/disabled independently
// - Results are typically added together or selected based on configuration
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    combined_out_r <= 256'b0;
    combined_valid_r <= 1'b0;
  end else begin
    // Simple addition - actual implementation may be more complex
    combined_valid_r <= x1_out_valid || x2_out_valid || y_out_valid;

    if (x1_out_valid && reg2dp_bs_bypass) begin
      combined_out_r <= x1_out_data;
    end else if (x2_out_valid && reg2dp_bn_bypass) begin
      combined_out_r <= x2_out_data;
    end else if (y_out_valid && reg2dp_ew_bypass) begin
      combined_out_r <= y_out_data;
    end else begin
      // Add all outputs
      combined_out_r <= x1_out_data + x2_out_data + y_out_data;
    end
  end
end

//============================================================================
// Output routing
//============================================================================
// Route to PDP or memory based on configuration
assign sdp2pdp_pd = combined_out_r;
assign sdp2pdp_valid = combined_valid_r && (reg2dp_output_dst == OUTPUT_DST_PDP);

// DMA write requests not implemented in this placeholder
assign sdp2mcif_wr_req_valid = 1'b0;
assign sdp2mcif_wr_req_pd = 514'b0;
assign sdp2cvif_wr_req_valid = 1'b0;
assign sdp2cvif_wr_req_pd = 514'b0;

// CACC ready signal
assign cacc2sdp_ready = 1'b1;  // Always ready in this placeholder

//============================================================================
// Done interrupt generation
//============================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg2dp_interrupt_ptr_r <= 2'b0;
  end else begin
    reg2dp_interrupt_ptr_r <= {reg2dp_interrupt_ptr, 1'b0};
  end
end

assign sdp2glb_done_intr_pd = reg2dp_interrupt_ptr_r;

endmodule // NV_NVDLA_SDP_new