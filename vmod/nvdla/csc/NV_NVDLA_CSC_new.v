// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSC (Convolution Sequence Controller) Top-Level Integration
// - CSB interface for configuration
// - Input channel engine for feature map processing
// - Output channel engine for result writing
// - Weight processor for kernel handling
// - Memory interface (MCIF/CVIF) for data transport
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  // CSB interface
  ,csb2csc_req_pvld              //|< i
  ,csb2csc_req_prdy              //|> o
  ,csb2csc_req_pd                //|< i  [62:0]
  ,csc2csb_resp_valid            //|> o
  ,csc2csb_resp_pd               //|> o  [33:0]
  // CACC interface
  ,cacc2sc_dat_ready             //|< i
  ,cacc2sc_dat_pd                 //|< i  [511:0]
  ,cacc2sc_dat_valid              //|< i
  ,sc2cacc_dat_rdys               //|> o
  // CMAC interface
  ,sc2mac_dat_a_pvld             //|> o
  ,sc2mac_dat_a_mask              //|> o  [127:0]
  ,sc2mac_dat_a_pd                //|> o
  ,sc2mac_dat_b_pvld             //|> o
  ,sc2mac_dat_b_mask              //|> o  [127:0]
  ,sc2mac_dat_b_pd                //|> o
  ,sc2mac_wt_a_pvld              //|> o
  ,sc2mac_wt_a_data               //|> o  [511:0]
  ,sc2mac_wt_b_pvld              //|> o
  ,sc2mac_wt_b_data               //|> o  [511:0]
  // CDMA interface - Data
  ,cdma2sc_dat_updt              //|< i
  ,cdma2sc_dat_entries           //|< i  [11:0]
  ,cdma2sc_dat_slices            //|< i  [12:0]
  ,sc2cdma_dat_updt              //|> o
  ,sc2cdma_dat_entries           //|> o  [11:0]
  ,sc2cdma_dat_slices            //|> o  [12:0]
  ,sc2cdma_dat_pending_req       //|> o
  // CDMA interface - Weight
  ,cdma2sc_wt_updt               //|< i
  ,cdma2sc_wt_entries            //|< i  [11:0]
  ,cdma2sc_wt_kernels            //|< i  [12:0]
  ,cdma2sc_wmb_entries           //|< i  [11:0]
  ,sc2cdma_wt_updt               //|> o
  ,sc2cdma_wt_entries            //|> o  [11:0]
  ,sc2cdma_wt_kernels            //|> o  [12:0]
  ,sc2cdma_wmb_updt              //|> o
  ,sc2cdma_wmb_entries           //|> o  [11:0]
  // CVIF/MCIF interface
  ,cvif2sc_dat_rd_ready          //|< i
  ,sc2cvif_dat_rd_req            //|> o
  ,sc2cvif_dat_rd_adq            //|> o  [5:0]
  ,cvif2sc_dat_rd_data           //|< i  [511:0]
  ,cvif2sc_dat_rd_valid          //|< i
  ,cvif2sc_wt_rd_ready           //|< i
  ,sc2cvif_wt_rd_req             //|> o
  ,sc2cvif_wt_rd_adq             //|> o  [5:0]
  ,cvif2sc_wt_rd_data            //|< i  [511:0]
  ,cvif2sc_wt_rd_valid           //|< i
  ,cvif2sc_wmb_rd_ready          //|< i
  ,sc2cvif_wmb_rd_req            //|> o
  ,sc2cvif_wmb_rd_adq            //|> o  [5:0]
  ,cvif2sc_wmb_rd_data           //|< i  [511:0]
  ,cvif2sc_wmb_rd_valid          //|< i
  ,sc2cvif_rd_cdt                //|< i  [7:0]
  );

//==========================================
// Parameters
//==========================================

//==========================================
// Ports
//==========================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB interface
input         csb2csc_req_pvld;
output        csb2csc_req_prdy;
input  [62:0] csb2csc_req_pd;
output        csc2csb_resp_valid;
output [33:0] csc2csb_resp_pd;

// CACC interface
input         cacc2sc_dat_ready;
input  [511:0] cacc2sc_dat_pd;
input         cacc2sc_dat_valid;
output        sc2cacc_dat_rdys;

// CMAC interface
output        sc2mac_dat_a_pvld;
output [127:0] sc2mac_dat_a_mask;
output        sc2mac_dat_a_pd;
output        sc2mac_dat_b_pvld;
output [127:0] sc2mac_dat_b_mask;
output        sc2mac_dat_b_pd;
output        sc2mac_wt_a_pvld;
output [511:0] sc2mac_wt_a_data;
output        sc2mac_wt_b_pvld;
output [511:0] sc2mac_wt_b_data;

// CDMA - Data
input         cdma2sc_dat_updt;
input  [11:0] cdma2sc_dat_entries;
input  [12:0] cdma2sc_dat_slices;
output        sc2cdma_dat_updt;
output [11:0] sc2cdma_dat_entries;
output [12:0] sc2cdma_dat_slices;
output        sc2cdma_dat_pending_req;

// CDMA - Weight
input         cdma2sc_wt_updt;
input  [11:0] cdma2sc_wt_entries;
input  [12:0] cdma2sc_wt_kernels;
input  [11:0] cdma2sc_wmb_entries;
output        sc2cdma_wt_updt;
output [11:0] sc2cdma_wt_entries;
output [12:0] sc2cdma_wt_kernels;
output        sc2cdma_wmb_updt;
output [11:0] sc2cdma_wmb_entries;

// CVIF/MCIF interface
input         cvif2sc_dat_rd_ready;
output        sc2cvif_dat_rd_req;
output [5:0]  sc2cvif_dat_rd_adq;
input  [511:0] cvif2sc_dat_rd_data;
input         cvif2sc_dat_rd_valid;
input         cvif2sc_wt_rd_ready;
output        sc2cvif_wt_rd_req;
output [5:0]  sc2cvif_wt_rd_adq;
input  [511:0] cvif2sc_wt_rd_data;
input         cvif2sc_wt_rd_valid;
input         cvif2sc_wmb_rd_ready;
output        sc2cvif_wmb_rd_req;
output [5:0]  sc2cvif_wmb_rd_adq;
input  [511:0] cvif2sc_wmb_rd_data;
input         cvif2sc_wmb_rd_valid;
input  [7:0]  sc2cvif_rd_cdt;

//==========================================
// Wire/Reg declarations
//==========================================

// CSB to Register
wire        reg_wr_en;
wire        reg_rd_en;
wire [31:0] reg_wr_data;
wire [11:0] reg_offset;

// Register outputs
wire        reg2dp_op_en;
wire        reg2dp_conv_mode;
wire [1:0]  reg2dp_proc_precision;
wire        reg2dp_datain_format;
wire [12:0] reg2dp_datain_width_ext;
wire [12:0] reg2dp_datain_height_ext;
wire [12:0] reg2dp_datain_channel_ext;
wire [12:0] reg2dp_dataout_width;
wire [12:0] reg2dp_dataout_height;
wire [12:0] reg2dp_dataout_channel;
wire [4:0]  reg2dp_weight_width_ext;
wire [4:0]  reg2dp_weight_height_ext;
wire [12:0] reg2dp_weight_channel_ext;
wire [12:0] reg2dp_weight_kernel;
wire [24:0] reg2dp_weight_bytes;
wire [20:0] reg2dp_wmb_bytes;
wire [3:0]  reg2dp_weight_bank;
wire        reg2dp_weight_format;
wire        reg2dp_weight_reuse;
wire        reg2dp_skip_weight_rls;
wire [11:0] reg2dp_entries;
wire [3:0]  reg2dp_data_bank;
wire [12:0] reg2dp_datain_channel;
wire [20:0] reg2dp_atomics;
wire [2:0]  reg2dp_conv_x_stride_ext;
wire [2:0]  reg2dp_conv_y_stride_ext;
wire [4:0]  reg2dp_x_dilation_ext;
wire [4:0]  reg2dp_y_dilation_ext;
wire [4:0]  reg2dp_pad_left;
wire [4:0]  reg2dp_pad_top;
wire [15:0] reg2dp_pad_value;
wire [4:0]  reg2dp_batches;
wire [1:0]  reg2dp_y_extension;
wire        reg2dp_skip_data_rls;
wire [11:0] reg2dp_rls_slices;
wire [1:0]  reg2dp_pra_truncate;
wire [31:0] reg2dp_cya;
wire        reg2dp_producer;

// Register internal
wire        dp2reg_done;
wire        dp2reg_consumer;
wire [1:0]  dp2reg_status_0;
wire [1:0]  dp2reg_status_1;

// Input engine to CBUF (via mcif)
wire        sc2buf_dat_rd_en_ie;
wire [11:0] sc2buf_dat_rd_addr_ie;
wire        sc2buf_dat_rd_valid_ie;
wire [511:0] sc2buf_dat_rd_data_ie;

// Weight processor to CBUF (via mcif)
wire        sc2buf_wt_rd_en_wp;
wire [11:0] sc2buf_wt_rd_addr_wp;
wire        sc2buf_wt_rd_valid_wp;
wire [511:0] sc2buf_wt_rd_data_wp;

wire        sc2buf_wmb_rd_en_wp;
wire [11:0] sc2buf_wmb_rd_addr_wp;
wire        sc2buf_wmb_rd_valid_wp;
wire [511:0] sc2buf_wmb_rd_data_wp;

// CBUF to Input engine (via mcif)
wire        sc2buf_dat_rd_en_csc;
wire [11:0] sc2buf_dat_rd_addr_csc;
wire        sc2buf_dat_rd_valid_csc;
wire [511:0] sc2buf_dat_rd_data_csc;

// CBUF to Weight processor (via mcif)
wire        sc2buf_wt_rd_en_csc;
wire [11:0] sc2buf_wt_rd_addr_csc;
wire        sc2buf_wt_rd_valid_csc;
wire [511:0] sc2buf_wt_rd_data_csc;

wire        sc2buf_wmb_rd_en_csc;
wire [11:0] sc2buf_wmb_rd_addr_csc;
wire        sc2buf_wmb_rd_valid_csc;
wire [511:0] sc2buf_wmb_rd_data_csc;

// Input engine signals
wire [127:0] sc2mac_dat_a_mask_ie;
wire         sc2mac_dat_a_pvld_ie;
wire         sc2mac_dat_a_pd_ie;
wire [127:0] sc2mac_dat_b_mask_ie;
wire         sc2mac_dat_b_pvld_ie;
wire         sc2mac_dat_b_pd_ie;
wire         csc2mac_dat_a_stripe_st_ie;
wire         csc2mac_dat_a_stripe_end_ie;
wire         csc2mac_dat_a_channel_end_ie;
wire         csc2mac_dat_a_layer_end_ie;
wire         csc2mac_dat_b_stripe_st_ie;
wire         csc2mac_dat_b_stripe_end_ie;
wire         csc2mac_dat_b_channel_end_ie;
wire         csc2mac_dat_b_layer_end_ie;

// Weight processor signals
wire         sc2mac_wt_a_pvld_wp;
wire [511:0] sc2mac_wt_a_data_wp;
wire         sc2mac_wt_b_pvld_wp;
wire [511:0] sc2mac_wt_b_data_wp;
wire         csc2mac_wt_a_stripe_st_wp;
wire         csc2mac_wt_a_stripe_end_wp;
wire         csc2mac_wt_a_channel_end_wp;
wire         csc2mac_wt_a_layer_end_wp;
wire         csc2mac_wt_b_stripe_st_wp;
wire         csc2mac_wt_b_stripe_end_wp;
wire         csc2mac_wt_b_channel_end_wp;
wire         csc2mac_wt_b_layer_end_wp;

// Output engine signals
wire         sc2cacc_dat_rdys_oe;
wire         dp2reg_done_oe;

//==========================================
// CSB Interface Module
//==========================================
NV_NVDLA_CSC_csb_new u_csb (
   .nvdla_core_clk            (nvdla_core_clk)
  ,.nvdla_core_rstn           (nvdla_core_rstn)
  ,.csb2csc_req_pvld         (csb2csc_req_pvld)
  ,.csb2csc_req_prdy         (csb2csc_req_prdy)
  ,.csb2csc_req_pd            (csb2csc_req_pd[62:0])
  ,.csc2csb_resp_valid       (csc2csb_resp_valid)
  ,.csc2csb_resp_pd          (csc2csb_resp_pd[33:0])
  ,.reg_wr_en                 (reg_wr_en)
  ,.reg_rd_en                 (reg_rd_en)
  ,.reg_wr_data               (reg_wr_data[31:0])
  ,.reg_offset                (reg_offset[11:0])
  ,.reg2dp_producer           (reg2dp_producer)
  ,.reg2dp_d0_op_en           (1'b0)  // Simplified - connected in reg file
  ,.reg2dp_d1_op_en           (1'b0)
  );

//==========================================
// Register File Module
//==========================================
NV_NVDLA_CSC_reg_new u_reg (
   .nvdla_core_clk            (nvdla_core_clk)
  ,.nvdla_core_rstn           (nvdla_core_rstn)
  ,.reg_wr_en                 (reg_wr_en)
  ,.reg_rd_en                 (reg_rd_en)
  ,.reg_wr_data               (reg_wr_data[31:0])
  ,.reg_offset                (reg_offset[11:0])
  ,.dp2reg_done               (dp2reg_done)
  ,.dp2reg_consumer           (dp2reg_consumer)
  ,.dp2reg_status_0           (dp2reg_status_0[1:0])
  ,.dp2reg_status_1           (dp2reg_status_1[1:0])
  ,.csc2csb_resp_valid       (csc2csb_resp_valid)
  ,.csc2csb_resp_pd          (csc2csb_resp_pd[33:0])
  ,.reg2dp_atomics            (reg2dp_atomics[20:0])
  ,.reg2dp_batches            (reg2dp_batches[4:0])
  ,.reg2dp_conv_mode          (reg2dp_conv_mode)
  ,.reg2dp_conv_x_stride_ext  (reg2dp_conv_x_stride_ext[2:0])
  ,.reg2dp_conv_y_stride_ext  (reg2dp_conv_y_stride_ext[2:0])
  ,.reg2dp_cya                (reg2dp_cya[31:0])
  ,.reg2dp_data_bank          (reg2dp_data_bank[3:0])
  ,.reg2dp_data_reuse         ()
  ,.reg2dp_datain_channel_ext (reg2dp_datain_channel_ext[12:0])
  ,.reg2dp_datain_format      (reg2dp_datain_format)
  ,.reg2dp_datain_height_ext  (reg2dp_datain_height_ext[12:0])
  ,.reg2dp_datain_width_ext   (reg2dp_datain_width_ext[12:0])
  ,.reg2dp_dataout_channel    (reg2dp_dataout_channel[12:0])
  ,.reg2dp_dataout_height     (reg2dp_dataout_height[12:0])
  ,.reg2dp_dataout_width      (reg2dp_dataout_width[12:0])
  ,.reg2dp_entries            (reg2dp_entries[11:0])
  ,.reg2dp_in_precision       ()
  ,.reg2dp_op_en              (reg2dp_op_en)
  ,.reg2dp_pad_left           (reg2dp_pad_left[4:0])
  ,.reg2dp_pad_top            (reg2dp_pad_top[4:0])
  ,.reg2dp_pad_value          (reg2dp_pad_value[15:0])
  ,.reg2dp_pra_truncate       (reg2dp_pra_truncate[1:0])
  ,.reg2dp_proc_precision     (reg2dp_proc_precision[1:0])
  ,.reg2dp_rls_slices         (reg2dp_rls_slices[11:0])
  ,.reg2dp_skip_data_rls      (reg2dp_skip_data_rls)
  ,.reg2dp_skip_weight_rls    (reg2dp_skip_weight_rls)
  ,.reg2dp_weight_bank        (reg2dp_weight_bank[3:0])
  ,.reg2dp_weight_bytes       (reg2dp_weight_bytes[24:0])
  ,.reg2dp_weight_channel_ext (reg2dp_weight_channel_ext[12:0])
  ,.reg2dp_weight_format      (reg2dp_weight_format)
  ,.reg2dp_weight_height_ext  (reg2dp_weight_height_ext[4:0])
  ,.reg2dp_weight_kernel      (reg2dp_weight_kernel[12:0])
  ,.reg2dp_weight_reuse       (reg2dp_weight_reuse)
  ,.reg2dp_weight_width_ext   (reg2dp_weight_width_ext[4:0])
  ,.reg2dp_wmb_bytes          (reg2dp_wmb_bytes[20:0])
  ,.reg2dp_x_dilation_ext     (reg2dp_x_dilation_ext[4:0])
  ,.reg2dp_y_dilation_ext     (reg2dp_y_dilation_ext[4:0])
  ,.reg2dp_y_extension        (reg2dp_y_extension[1:0])
  ,.reg2dp_producer           (reg2dp_producer)
  );

//==========================================
// Input Engine Module
//==========================================
NV_NVDLA_CSC_input_engine_new u_input_engine (
   .nvdla_core_clk                 (nvdla_core_clk)
  ,.nvdla_core_rstn                (nvdla_core_rstn)
  ,.reg2dp_op_en                   (reg2dp_op_en)
  ,.reg2dp_conv_mode               (reg2dp_conv_mode)
  ,.reg2dp_proc_precision          (reg2dp_proc_precision[1:0])
  ,.reg2dp_datain_format           (reg2dp_datain_format)
  ,.reg2dp_datain_width_ext        (reg2dp_datain_width_ext[12:0])
  ,.reg2dp_datain_height_ext       (reg2dp_datain_height_ext[12:0])
  ,.reg2dp_datain_channel_ext      (reg2dp_datain_channel_ext[12:0])
  ,.reg2dp_dataout_width           (reg2dp_dataout_width[12:0])
  ,.reg2dp_dataout_height          (reg2dp_dataout_height[12:0])
  ,.reg2dp_dataout_channel        (reg2dp_dataout_channel[12:0])
  ,.reg2dp_weight_width_ext        (reg2dp_weight_width_ext[4:0])
  ,.reg2dp_weight_height_ext       (reg2dp_weight_height_ext[4:0])
  ,.reg2dp_conv_x_stride_ext       (reg2dp_conv_x_stride_ext[2:0])
  ,.reg2dp_conv_y_stride_ext       (reg2dp_conv_y_stride_ext[2:0])
  ,.reg2dp_x_dilation_ext          (reg2dp_x_dilation_ext[4:0])
  ,.reg2dp_y_dilation_ext          (reg2dp_y_dilation_ext[4:0])
  ,.reg2dp_pad_left                (reg2dp_pad_left[4:0])
  ,.reg2dp_pad_top                 (reg2dp_pad_top[4:0])
  ,.reg2dp_pad_value               (reg2dp_pad_value[15:0])
  ,.reg2dp_batches                 (reg2dp_batches[4:0])
  ,.reg2dp_entries                 (reg2dp_entries[11:0])
  ,.reg2dp_data_bank               (reg2dp_data_bank[3:0])
  ,.reg2dp_y_extension             (reg2dp_y_extension[1:0])
  ,.sc2buf_dat_rd_en               (sc2buf_dat_rd_en_ie)
  ,.sc2buf_dat_rd_addr             (sc2buf_dat_rd_addr_ie[11:0])
  ,.sc2buf_dat_rd_valid            (sc2buf_dat_rd_valid_csc)
  ,.sc2buf_dat_rd_data             (sc2buf_dat_rd_data_csc[511:0])
  ,.sc2mac_dat_a_pvld              (sc2mac_dat_a_pvld_ie)
  ,.sc2mac_dat_a_mask              (sc2mac_dat_a_mask_ie[127:0])
  ,.sc2mac_dat_a_pd                (sc2mac_dat_a_pd_ie)
  ,.sc2mac_dat_b_pvld              (sc2mac_dat_b_pvld_ie)
  ,.sc2mac_dat_b_mask              (sc2mac_dat_b_mask_ie[127:0])
  ,.sc2mac_dat_b_pd                (sc2mac_dat_b_pd_ie)
  ,.cdma2sc_dat_updt               (cdma2sc_dat_updt)
  ,.cdma2sc_dat_entries            (cdma2sc_dat_entries[11:0])
  ,.cdma2sc_dat_slices             (cdma2sc_dat_slices[12:0])
  ,.sc2cdma_dat_updt               (sc2cdma_dat_updt)
  ,.sc2cdma_dat_entries            (sc2cdma_dat_entries[11:0])
  ,.sc2cdma_dat_slices             (sc2cdma_dat_slices[12:0])
  ,.sc2cdma_dat_pending_req       (sc2cdma_dat_pending_req)
  ,.csc2mac_dat_a_stripe_st       (csc2mac_dat_a_stripe_st_ie)
  ,.csc2mac_dat_a_stripe_end      (csc2mac_dat_a_stripe_end_ie)
  ,.csc2mac_dat_a_channel_end      (csc2mac_dat_a_channel_end_ie)
  ,.csc2mac_dat_a_layer_end       (csc2mac_dat_a_layer_end_ie)
  ,.csc2mac_dat_b_stripe_st       (csc2mac_dat_b_stripe_st_ie)
  ,.csc2mac_dat_b_stripe_end      (csc2mac_dat_b_stripe_end_ie)
  ,.csc2mac_dat_b_channel_end      (csc2mac_dat_b_channel_end_ie)
  ,.csc2mac_dat_b_layer_end       (csc2mac_dat_b_layer_end_ie)
  );

//==========================================
// Output Engine Module
//==========================================
NV_NVDLA_CSC_output_engine_new u_output_engine (
   .nvdla_core_clk                 (nvdla_core_clk)
  ,.nvdla_core_rstn                (nvdla_core_rstn)
  ,.reg2dp_op_en                   (reg2dp_op_en)
  ,.reg2dp_conv_mode               (reg2dp_conv_mode)
  ,.reg2dp_proc_precision          (reg2dp_proc_precision[1:0])
  ,.reg2dp_dataout_width           (reg2dp_dataout_width[12:0])
  ,.reg2dp_dataout_height          (reg2dp_dataout_height[12:0])
  ,.reg2dp_dataout_channel        (reg2dp_dataout_channel[12:0])
  ,.reg2dp_atomics                 (reg2dp_atomics[20:0])
  ,.reg2dp_rls_slices             (reg2dp_rls_slices[11:0])
  ,.cacc2sc_dat_ready             (cacc2sc_dat_ready)
  ,.cacc2sc_dat_pd                 (cacc2sc_dat_pd[511:0])
  ,.cacc2sc_dat_valid              (cacc2sc_dat_valid)
  ,.sc2cacc_dat_rdys               (sc2cacc_dat_rdys_oe)
  ,.sc2cdp_dat_pvld               ()
  ,.sc2cdp_dat_addr               ()
  ,.sc2cdp_dat_pd                 ()
  ,.sc2cdp_dat_ready              (1'b1)
  ,.dp2reg_done                    (dp2reg_done_oe)
  );

assign dp2reg_done = dp2reg_done_oe;
assign sc2cacc_dat_rdys = sc2cacc_dat_rdys_oe;

//==========================================
// Weight Processor Module
//==========================================
NV_NVDLA_CSC_weight_proc_new u_weight_proc (
   .nvdla_core_clk                 (nvdla_core_clk)
  ,.nvdla_core_rstn                (nvdla_core_rstn)
  ,.reg2dp_op_en                   (reg2dp_op_en)
  ,.reg2dp_conv_mode               (reg2dp_conv_mode)
  ,.reg2dp_proc_precision          (reg2dp_proc_precision[1:0])
  ,.reg2dp_weight_format           (reg2dp_weight_format)
  ,.reg2dp_weight_width_ext        (reg2dp_weight_width_ext[4:0])
  ,.reg2dp_weight_height_ext       (reg2dp_weight_height_ext[4:0])
  ,.reg2dp_weight_channel_ext      (reg2dp_weight_channel_ext[12:0])
  ,.reg2dp_weight_kernel          (reg2dp_weight_kernel[12:0])
  ,.reg2dp_weight_bytes            (reg2dp_weight_bytes[24:0])
  ,.reg2dp_wmb_bytes              (reg2dp_wmb_bytes[20:0])
  ,.reg2dp_weight_bank            (reg2dp_weight_bank[3:0])
  ,.reg2dp_weight_reuse           (reg2dp_weight_reuse)
  ,.reg2dp_skip_weight_rls        (reg2dp_skip_weight_rls)
  ,.reg2dp_entries                 (reg2dp_entries[11:0])
  ,.reg2dp_data_bank               (reg2dp_data_bank[3:0])
  ,.reg2dp_datain_channel_ext      (reg2dp_datain_channel_ext[12:0])
  ,.reg2dp_atomics                 (reg2dp_atomics[20:0])
  ,.sc2buf_wt_rd_en               (sc2buf_wt_rd_en_wp)
  ,.sc2buf_wt_rd_addr             (sc2buf_wt_rd_addr_wp[11:0])
  ,.sc2buf_wt_rd_valid            (sc2buf_wt_rd_valid_csc)
  ,.sc2buf_wt_rd_data             (sc2buf_wt_rd_data_csc[511:0])
  ,.sc2buf_wmb_rd_en              (sc2buf_wmb_rd_en_wp)
  ,.sc2buf_wmb_rd_addr            (sc2buf_wmb_rd_addr_wp[11:0])
  ,.sc2buf_wmb_rd_valid           (sc2buf_wmb_rd_valid_csc)
  ,.sc2buf_wmb_rd_data            (sc2buf_wmb_rd_data_csc[511:0])
  ,.sc2mac_wt_a_pvld              (sc2mac_wt_a_pvld_wp)
  ,.sc2mac_wt_a_data               (sc2mac_wt_a_data_wp[511:0])
  ,.sc2mac_wt_b_pvld              (sc2mac_wt_b_pvld_wp)
  ,.sc2mac_wt_b_data               (sc2mac_wt_b_data_wp[511:0])
  ,.csc2mac_wt_a_stripe_st        (csc2mac_wt_a_stripe_st_wp)
  ,.csc2mac_wt_a_stripe_end       (csc2mac_wt_a_stripe_end_wp)
  ,.csc2mac_wt_a_channel_end       (csc2mac_wt_a_channel_end_wp)
  ,.csc2mac_wt_a_layer_end        (csc2mac_wt_a_layer_end_wp)
  ,.csc2mac_wt_b_stripe_st        (csc2mac_wt_b_stripe_st_wp)
  ,.csc2mac_wt_b_stripe_end       (csc2mac_wt_b_stripe_end_wp)
  ,.csc2mac_wt_b_channel_end       (csc2mac_wt_b_channel_end_wp)
  ,.csc2mac_wt_b_layer_end        (csc2mac_wt_b_layer_end_wp)
  ,.cdma2sc_wt_updt               (cdma2sc_wt_updt)
  ,.cdma2sc_wt_entries            (cdma2sc_wt_entries[11:0])
  ,.cdma2sc_wt_kernels            (cdma2sc_wt_kernels[12:0])
  ,.cdma2sc_wmb_entries           (cdma2sc_wmb_entries[11:0])
  ,.sc2cdma_wt_updt               (sc2cdma_wt_updt)
  ,.sc2cdma_wt_entries            (sc2cdma_wt_entries[11:0])
  ,.sc2cdma_wt_kernels            (sc2cdma_wt_kernels[12:0])
  ,.sc2cdma_wmb_updt              (sc2cdma_wmb_updt)
  ,.sc2cdma_wmb_entries           (sc2cdma_wmb_entries[11:0])
  );

//==========================================
// Memory Interface Module
//==========================================
NV_NVDLA_CSC_mcif_cvif_new u_mcif_cvif (
   .nvdla_core_clk                 (nvdla_core_clk)
  ,.nvdla_core_rstn                (nvdla_core_rstn)
  // Data path input (from CSC internal)
  ,.sc2buf_dat_rd_en_i            (sc2buf_dat_rd_en_ie)
  ,.sc2buf_dat_rd_addr_i          (sc2buf_dat_rd_addr_ie[11:0])
  ,.sc2buf_dat_rd_en_o            (sc2buf_dat_rd_en_csc)
  ,.sc2buf_dat_rd_addr_o          (sc2buf_dat_rd_addr_csc[11:0])
  ,.sc2buf_dat_rd_valid_i         (1'b0)  // No direct passthrough for now
  ,.sc2buf_dat_rd_data_i          ({512{1'b0}})
  ,.sc2buf_dat_rd_valid_o         (sc2buf_dat_rd_valid_csc)
  ,.sc2buf_dat_rd_data_o          (sc2buf_dat_rd_data_csc[511:0])
  // Weight path input
  ,.sc2buf_wt_rd_en_i             (sc2buf_wt_rd_en_wp)
  ,.sc2buf_wt_rd_addr_i           (sc2buf_wt_rd_addr_wp[11:0])
  ,.sc2buf_wt_rd_en_o             (sc2buf_wt_rd_en_csc)
  ,.sc2buf_wt_rd_addr_o           (sc2buf_wt_rd_addr_csc[11:0])
  ,.sc2buf_wt_rd_valid_i          (1'b0)
  ,.sc2buf_wt_rd_data_i           ({512{1'b0}})
  ,.sc2buf_wt_rd_valid_o          (sc2buf_wt_rd_valid_csc)
  ,.sc2buf_wt_rd_data_o           (sc2buf_wt_rd_data_csc[511:0])
  // WMB path input
  ,.sc2buf_wmb_rd_en_i            (sc2buf_wmb_rd_en_wp)
  ,.sc2buf_wmb_rd_addr_i          (sc2buf_wmb_rd_addr_wp[11:0])
  ,.sc2buf_wmb_rd_en_o            (sc2buf_wmb_rd_en_csc)
  ,.sc2buf_wmb_rd_addr_o          (sc2buf_wmb_rd_addr_csc[11:0])
  ,.sc2buf_wmb_rd_valid_i         (1'b0)
  ,.sc2buf_wmb_rd_data_i          ({512{1'b0}})
  ,.sc2buf_wmb_rd_valid_o         (sc2buf_wmb_rd_valid_csc)
  ,.sc2buf_wmb_rd_data_o          (sc2buf_wmb_rd_data_csc[511:0])
  // CVIF external interface - Data
  ,.cvif2sc_dat_rd_ready          (cvif2sc_dat_rd_ready)
  ,.sc2cvif_dat_rd_req            (sc2cvif_dat_rd_req)
  ,.sc2cvif_dat_rd_adq            (sc2cvif_dat_rd_adq[5:0])
  ,.cvif2sc_dat_rd_data           (cvif2sc_dat_rd_data[511:0])
  ,.cvif2sc_dat_rd_valid          (cvif2sc_dat_rd_valid)
  // CVIF external interface - Weight
  ,.cvif2sc_wt_rd_ready           (cvif2sc_wt_rd_ready)
  ,.sc2cvif_wt_rd_req             (sc2cvif_wt_rd_req)
  ,.sc2cvif_wt_rd_adq             (sc2cvif_wt_rd_adq[5:0])
  ,.cvif2sc_wt_rd_data            (cvif2sc_wt_rd_data[511:0])
  ,.cvif2sc_wt_rd_valid           (cvif2sc_wt_rd_valid)
  // CVIF external interface - WMB
  ,.cvif2sc_wmb_rd_ready          (cvif2sc_wmb_rd_ready)
  ,.sc2cvif_wmb_rd_req            (sc2cvif_wmb_rd_req)
  ,.sc2cvif_wmb_rd_adq            (sc2cvif_wmb_rd_adq[5:0])
  ,.cvif2sc_wmb_rd_data           (cvif2sc_wmb_rd_data[511:0])
  ,.cvif2sc_wmb_rd_valid          (cvif2sc_wmb_rd_valid)
  // Credits
  ,.sc2cvif_rd_cdt                (sc2cvif_rd_cdt[7:0])
  );

//==========================================
// Output assignments
//==========================================
// CMAC data output (combine input engine signals)
assign sc2mac_dat_a_pvld = sc2mac_dat_a_pvld_ie;
assign sc2mac_dat_a_mask[127:0] = sc2mac_dat_a_mask_ie[127:0];
assign sc2mac_dat_a_pd = sc2mac_dat_a_pd_ie;
assign sc2mac_dat_b_pvld = sc2mac_dat_b_pvld_ie;
assign sc2mac_dat_b_mask[127:0] = sc2mac_dat_b_mask_ie[127:0];
assign sc2mac_dat_b_pd = sc2mac_dat_b_pd_ie;

// CMAC weight output (weight processor signals)
assign sc2mac_wt_a_pvld = sc2mac_wt_a_pvld_wp;
assign sc2mac_wt_a_data[511:0] = sc2mac_wt_a_data_wp[511:0];
assign sc2mac_wt_b_pvld = sc2mac_wt_b_pvld_wp;
assign sc2mac_wt_b_data[511:0] = sc2mac_wt_b_data_wp[511:0];

endmodule // NV_NVDLA_CSC_new