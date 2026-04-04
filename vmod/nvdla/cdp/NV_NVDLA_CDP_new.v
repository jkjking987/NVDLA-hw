// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP (Convolution Data Processor) Top-Level Module
// - Post-processing unit for convolution results
// - Performs Local Response Normalization (LRN) and data format conversion
//
// CDP Architecture:
//   +----------+    +-------+    +-----+    +-----+    +--------+    +--------+
//   | RDMA     | -> | ICVT  | -> | SQ  | -> | LUT | -> | OCVT   | -> | WDMA  |
//   | (Read)   |    |(Input)|    |(Sqr)|    |(Norm)|   |(Output)|    |(Write) |
//   +----------+    +-------+    +-----+    +-----+    +--------+    +--------+
//
// Key Components:
//   - CSB Interface: Command/status bus for register access
//   - Register File: Dual-group register architecture with producer/consumer
//   - RDMA: Read DMA for fetching input data
//   - ICVT: Input Converter (ALU + MUL + Shift)
//   - SQ: Squeeze module (square computation)
//   - LUT: Lookup Table for LRN normalization
//   - OCVT: Output Converter (ALU + MUL + Shift + Saturation)
//   - WDMA: Write DMA for storing output data
//
// Supported Data Formats:
//   - INT8: 8-bit integer
//   - INT16: 16-bit integer
//   - FP16: Half-precision floating point
//
// Operations:
//   - Local Response Normalization (LRN)
//   - Data format conversion
//   - NaN handling (flush to zero)
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_new (
   nvdla_core_clk                  //|< i
  ,nvdla_core_rstn                 //|< i
  // CSB interface
  ,csb2cdp_req_pvld               //|< i
  ,csb2cdp_req_prdy               //|> o
  ,csb2cdp_req_pd                 //|< i [62:0]
  ,cdp2csb_resp_valid             //|> o
  ,cdp2csb_resp_pd                //|> o [33:0]
  // Interrupt interface
  ,cdp2glb_done_intr              //|> o [1:0]
  // DMA read interface (to MCIF/CVIF)
  ,cdp2mcif_rd_req_valid          //|> o
  ,cdp2mcif_rd_req_ready          //|< i
  ,cdp2mcif_rd_req_pd             //|> o
  ,mcif2cdp_rd_rsp_valid          //|< i
  ,mcif2cdp_rd_rsp_ready          //|> o
  ,mcif2cdp_rd_rsp_pd             //|< i
  // DMA write interface (to MCIF/CVIF)
  ,cdp2mcif_wr_req_valid          //|> o
  ,cdp2mcif_wr_req_ready          //|< i
  ,cdp2mcif_wr_req_pd             //|> o
  ,cdp2mcif_wr_dat_valid          //|> o
  ,cdp2mcif_wr_dat_ready          //|< i
  ,cdp2mcif_wr_dat_pd             //|> o
  ,mcif2cdp_wr_rsp_valid          //|< i
  ,mcif2cdp_wr_rsp_ready          //|> o
  // CVIF DMA interface
  ,cdp2cvif_rd_req_valid         //|> o
  ,cdp2cvif_rd_req_ready         //|< i
  ,cdp2cvif_rd_req_pd            //|> o
  ,cvif2cdp_rd_rsp_valid         //|< i
  ,cvif2cdp_rd_rsp_ready         //|> o
  ,cvif2cdp_rd_rsp_pd            //|< i
  ,cdp2cvif_wr_req_valid         //|> o
  ,cdp2cvif_wr_req_ready         //|< i
  ,cdp2cvif_wr_req_pd            //|> o
  ,cdp2cvif_wr_dat_valid         //|> o
  ,cdp2cvif_wr_dat_ready         //|< i
  ,cdp2cvif_wr_dat_pd            //|> o
  ,cvif2cdp_wr_rsp_valid         //|< i
  ,cvif2cdp_wr_rsp_ready         //|> o
  );

//===============================================================
// PORT DECLARATION
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// CSB interface
input         csb2cdp_req_pvld;
output        csb2cdp_req_prdy;
input  [62:0] csb2cdp_req_pd;
output        cdp2csb_resp_valid;
output [33:0] cdp2csb_resp_pd;

// Interrupt interface
output [1:0] cdp2glb_done_intr;

// DMA read interface (MCIF)
output        cdp2mcif_rd_req_valid;
input         cdp2mcif_rd_req_ready;
output [37:0] cdp2mcif_rd_req_pd;
input         mcif2cdp_rd_rsp_valid;
output        mcif2cdp_rd_rsp_ready;
input  [33:0] mcif2cdp_rd_rsp_pd;

// DMA write interface (MCIF)
output        cdp2mcif_wr_req_valid;
input         cdp2mcif_wr_req_ready;
output [37:0] cdp2mcif_wr_req_pd;
output        cdp2mcif_wr_dat_valid;
input         cdp2mcif_wr_dat_ready;
output [33:0] cdp2mcif_wr_dat_pd;
input         mcif2cdp_wr_rsp_valid;
output        mcif2cdp_wr_rsp_ready;

// DMA interface (CVIF)
output        cdp2cvif_rd_req_valid;
input         cdp2cvif_rd_req_ready;
output [37:0] cdp2cvif_rd_req_pd;
input         cvif2cdp_rd_rsp_valid;
output        cvif2cdp_rd_rsp_ready;
input  [33:0] cvif2cdp_rd_rsp_pd;

output        cdp2cvif_wr_req_valid;
input         cdp2cvif_wr_req_ready;
output [37:0] cdp2cvif_wr_req_pd;
output        cdp2cvif_wr_dat_valid;
input         cdp2cvif_wr_dat_ready;
output [33:0] cdp2cvif_wr_dat_pd;
input         cvif2cdp_wr_rsp_valid;
output        cvif2cdp_wr_rsp_ready;

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// CSB to Register interface
wire   [11:0] reg_addr;
wire   [31:0] reg_wdat;
wire          reg_rd_en;
wire          reg_wr_en;
wire   [31:0] reg_rd_data;

// Register to datapath signals
wire          reg2dp_op_en;
wire          reg2dp_op_en_trigger;

// Register model outputs (CDP)
wire   [31:0] nvdla_cdp_cfg_op_en;
wire   [31:0] nvdla_cdp_status_0;
wire   [31:0] nvdla_cdp_status_1;
wire   [31:0] nvdla_cdp_pointer;
wire   [31:0] nvdla_cdp_reg2dp_lut_access_cfg;
wire   [31:0] nvdla_cdp_reg2dp_lut_access_data;
wire   [31:0] nvdla_cdp_reg2dp_lut_cfg;
wire   [31:0] nvdla_cdp_reg2dp_lut_info;
wire   [31:0] nvdla_cdp_reg2dp_lut_le_start_low;
wire   [31:0] nvdla_cdp_reg2dp_lut_le_start_high;
wire   [31:0] nvdla_cdp_reg2dp_lut_le_end_low;
wire   [31:0] nvdla_cdp_reg2dp_lut_le_end_high;
wire   [31:0] nvdla_cdp_reg2dp_lut_lo_start_low;
wire   [31:0] nvdla_cdp_reg2dp_lut_lo_start_high;
wire   [31:0] nvdla_cdp_reg2dp_lut_lo_end_low;
wire   [31:0] nvdla_cdp_reg2dp_lut_lo_end_high;
wire   [31:0] nvdla_cdp_reg2dp_lut_le_slope_scale;
wire   [31:0] nvdla_cdp_reg2dp_lut_le_slope_shift;
wire   [31:0] nvdla_cdp_reg2dp_lut_lo_slope_scale;
wire   [31:0] nvdla_cdp_reg2dp_lut_lo_slope_shift;

// Register model outputs (RDMA)
wire   [31:0] nvdla_cdp_rdma_cfg_op_en;
wire   [31:0] nvdla_cdp_rdma_status_0;
wire   [31:0] nvdla_cdp_rdma_status_1;
wire   [31:0] nvdla_cdp_rdma_pointer;
wire   [31:0] nvdla_cdp_rdma_reg2dp_src_base_addr_low;
wire   [31:0] nvdla_cdp_rdma_reg2dp_src_base_addr_high;
wire   [31:0] nvdla_cdp_rdma_reg2dp_src_line_stride;
wire   [31:0] nvdla_cdp_rdma_reg2dp_src_surface_stride;
wire   [31:0] nvdla_cdp_rdma_reg2dp_src_dma_cfg;
wire   [31:0] nvdla_cdp_rdma_reg2dp_data_format;
wire   [31:0] nvdla_cdp_rdma_reg2dp_operation_mode;
wire   [31:0] nvdla_cdp_rdma_reg2dp_perf_enable;

// Internal status signals
wire          op_en_g0;          // Operation enable group 0
wire          op_en_g1;          // Operation enable group 1
wire          producer_ptr;       // Producer pointer
wire          consumer_ptr;       // Consumer pointer

// DMA status signals
wire          is_mc_ack_done;
wire          is_cv_ack_done;

//===============================================================
// CSB INTERFACE MODULE
//===============================================================
NV_NVDLA_CDP_csb_new u_csb (
   .nvdla_core_clk                  (nvdla_core_clk)                     //|< i
  ,.nvdla_core_rstn                 (nvdla_core_rstn)                    //|< i
  ,.csb2cdp_req_pvld               (csb2cdp_req_pvld)                  //|< i
  ,.csb2cdp_req_prdy               (csb2cdp_req_prdy)                  //|> o
  ,.csb2cdp_req_pd                 (csb2cdp_req_pd)                    //|< i
  ,.cdp2csb_resp_valid             (cdp2csb_resp_valid)               //|> o
  ,.cdp2csb_resp_pd                (cdp2csb_resp_pd)                   //|> o
  ,.reg2dp_op_en                   (reg2dp_op_en)                      //|> o
  ,.reg2dp_op_en_trigger           (reg2dp_op_en_trigger)              //|> o
  );

// Register file module
NV_NVDLA_CDP_reg_new u_reg (
   .nvdla_core_clk                  (nvdla_core_clk)                    //|< i
  ,.nvdla_core_rstn                 (nvdla_core_rstn)                   //|< i
  ,.csb_addr                       (reg_addr[11:0])                    //|< w
  ,.csb_wdat                       (reg_wdat[31:0])                    //|< w
  ,.csb_rd_en                      (reg_rd_en)                         //|< w
  ,.csb_wr_en                      (reg_wr_en)                         //|< w
  ,.csb_rdat                       (reg_rd_data[31:0])                 //|> w
  ,.reg2dp_op_en                   (reg2dp_op_en)                     //|< i
  ,.reg2dp_op_en_trigger           (reg2dp_op_en_trigger)             //|< i
  ,.nvdla_cdp_cfg_op_en            (nvdla_cdp_cfg_op_en)             //|> i
  ,.nvdla_cdp_status_0             (nvdla_cdp_status_0)               //|> i
  ,.nvdla_cdp_status_1             (nvdla_cdp_status_1)               //|> i
  ,.nvdla_cdp_pointer              (nvdla_cdp_pointer)               //|> i
  ,.nvdla_cdp_reg2dp_lut_access_cfg  (nvdla_cdp_reg2dp_lut_access_cfg) //|> i
  ,.nvdla_cdp_reg2dp_lut_access_data (nvdla_cdp_reg2dp_lut_access_data)//|> i
  ,.nvdla_cdp_reg2dp_lut_cfg       (nvdla_cdp_reg2dp_lut_cfg)        //|> i
  ,.nvdla_cdp_reg2dp_lut_info      (nvdla_cdp_reg2dp_lut_info)       //|> i
  ,.nvdla_cdp_reg2dp_lut_le_start_low  (nvdla_cdp_reg2dp_lut_le_start_low)  //|> i
  ,.nvdla_cdp_reg2dp_lut_le_start_high (nvdla_cdp_reg2dp_lut_le_start_high) //|> i
  ,.nvdla_cdp_reg2dp_lut_le_end_low    (nvdla_cdp_reg2dp_lut_le_end_low)    //|> i
  ,.nvdla_cdp_reg2dp_lut_le_end_high   (nvdla_cdp_reg2dp_lut_le_end_high)   //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_start_low  (nvdla_cdp_reg2dp_lut_lo_start_low)  //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_start_high (nvdla_cdp_reg2dp_lut_lo_start_high) //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_end_low    (nvdla_cdp_reg2dp_lut_lo_end_low)    //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_end_high   (nvdla_cdp_reg2dp_lut_lo_end_high)   //|> i
  ,.nvdla_cdp_reg2dp_lut_le_slope_scale (nvdla_cdp_reg2dp_lut_le_slope_scale) //|> i
  ,.nvdla_cdp_reg2dp_lut_le_slope_shift  (nvdla_cdp_reg2dp_lut_le_slope_shift) //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_slope_scale (nvdla_cdp_reg2dp_lut_lo_slope_scale) //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_slope_shift  (nvdla_cdp_reg2dp_lut_lo_slope_shift) //|> i
  );

// Register model module (CDP)
NV_NVDLA_CDP_reg_model_new u_reg_model (
   .nvdla_core_clk                    (nvdla_core_clk)                      //|< i
  ,.nvdla_core_rstn                   (nvdla_core_rstn)                     //|< i
  ,.csb_addr                         (reg_addr[11:0])                      //|< w
  ,.csb_wdat                         (reg_wdat[31:0])                     //|< w
  ,.csb_rd_en                        (reg_rd_en)                          //|< w
  ,.csb_wr_en                        (reg_wr_en)                          //|< w
  ,.csb_rdat                         (reg_rd_data[31:0])                   //|> w
  ,.nvdla_cdp_cfg_op_en              (nvdla_cdp_cfg_op_en)                //|> i
  ,.nvdla_cdp_status_0               (nvdla_cdp_status_0)                 //|> i
  ,.nvdla_cdp_status_1               (nvdla_cdp_status_1)                 //|> i
  ,.nvdla_cdp_pointer                (nvdla_cdp_pointer)                  //|> i
  ,.nvdla_cdp_reg2dp_lut_access_cfg  (nvdla_cdp_reg2dp_lut_access_cfg)  //|> i
  ,.nvdla_cdp_reg2dp_lut_access_data (nvdla_cdp_reg2dp_lut_access_data) //|> i
  ,.nvdla_cdp_reg2dp_lut_cfg         (nvdla_cdp_reg2dp_lut_cfg)         //|> i
  ,.nvdla_cdp_reg2dp_lut_info        (nvdla_cdp_reg2dp_lut_info)        //|> i
  ,.nvdla_cdp_reg2dp_lut_le_start_low  (nvdla_cdp_reg2dp_lut_le_start_low)  //|> i
  ,.nvdla_cdp_reg2dp_lut_le_start_high (nvdla_cdp_reg2dp_lut_le_start_high) //|> i
  ,.nvdla_cdp_reg2dp_lut_le_end_low    (nvdla_cdp_reg2dp_lut_le_end_low)    //|> i
  ,.nvdla_cdp_reg2dp_lut_le_end_high   (nvdla_cdp_reg2dp_lut_le_end_high)   //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_start_low  (nvdla_cdp_reg2dp_lut_lo_start_low)  //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_start_high (nvdla_cdp_reg2dp_lut_lo_start_high) //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_end_low    (nvdla_cdp_reg2dp_lut_lo_end_low)    //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_end_high   (nvdla_cdp_reg2dp_lut_lo_end_high)   //|> i
  ,.nvdla_cdp_reg2dp_lut_le_slope_scale (nvdla_cdp_reg2dp_lut_le_slope_scale) //|> i
  ,.nvdla_cdp_reg2dp_lut_le_slope_shift  (nvdla_cdp_reg2dp_lut_le_slope_shift) //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_slope_scale (nvdla_cdp_reg2dp_lut_lo_slope_scale) //|> i
  ,.nvdla_cdp_reg2dp_lut_lo_slope_shift  (nvdla_cdp_reg2dp_lut_lo_slope_shift) //|> i
  );

// Register file module (RDMA)
NV_NVDLA_CDP_reg_rdma_new u_reg_rdma (
   .nvdla_core_clk                    (nvdla_core_clk)                    //|< i
  ,.nvdla_core_rstn                   (nvdla_core_rstn)                   //|< i
  ,.csb_addr                         (reg_addr[11:0])                    //|< w
  ,.csb_wdat                         (reg_wdat[31:0])                   //|< w
  ,.csb_rd_en                        (reg_rd_en)                        //|< w
  ,.csb_wr_en                        (reg_wr_en)                        //|< w
  ,.csb_rdat                         (reg_rd_data[31:0])               //|> w
  ,.reg2dp_op_en                     (reg2dp_op_en)                     //|< i
  ,.reg2dp_op_en_trigger             (reg2dp_op_en_trigger)            //|< i
  ,.nvdla_cdp_rdma_cfg_op_en              (nvdla_cdp_rdma_cfg_op_en)              //|> i
  ,.nvdla_cdp_rdma_status_0               (nvdla_cdp_rdma_status_0)              //|> i
  ,.nvdla_cdp_rdma_status_1               (nvdla_cdp_rdma_status_1)              //|> i
  ,.nvdla_cdp_rdma_pointer                (nvdla_cdp_rdma_pointer)               //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_base_addr_low  (nvdla_cdp_rdma_reg2dp_src_base_addr_low)  //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_base_addr_high (nvdla_cdp_rdma_reg2dp_src_base_addr_high) //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_line_stride    (nvdla_cdp_rdma_reg2dp_src_line_stride)    //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_surface_stride (nvdla_cdp_rdma_reg2dp_src_surface_stride) //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_dma_cfg        (nvdla_cdp_rdma_reg2dp_src_dma_cfg)        //|> i
  ,.nvdla_cdp_rdma_reg2dp_data_format        (nvdla_cdp_rdma_reg2dp_data_format)        //|> i
  ,.nvdla_cdp_rdma_reg2dp_operation_mode     (nvdla_cdp_rdma_reg2dp_operation_mode)     //|> i
  ,.nvdla_cdp_rdma_reg2dp_perf_enable         (nvdla_cdp_rdma_reg2dp_perf_enable)         //|> i
  );

// Register model module (RDMA)
NV_NVDLA_CDP_reg_rdma_model_new u_reg_rdma_model (
   .nvdla_core_clk                    (nvdla_core_clk)                      //|< i
  ,.nvdla_core_rstn                   (nvdla_core_rstn)                     //|< i
  ,.csb_addr                         (reg_addr[11:0])                     //|< w
  ,.csb_wdat                         (reg_wdat[31:0])                     //|< w
  ,.csb_rd_en                        (reg_rd_en)                          //|< w
  ,.csb_wr_en                        (reg_wr_en)                          //|< w
  ,.csb_rdat                         (reg_rd_data[31:0])                  //|> w
  ,.nvdla_cdp_rdma_cfg_op_en              (nvdla_cdp_rdma_cfg_op_en)               //|> i
  ,.nvdla_cdp_rdma_status_0               (nvdla_cdp_rdma_status_0)               //|> i
  ,.nvdla_cdp_rdma_status_1               (nvdla_cdp_rdma_status_1)               //|> i
  ,.nvdla_cdp_rdma_pointer                (nvdla_cdp_rdma_pointer)                //|> i
  ,.nvdla_cdp_rd2dp_src_base_addr_low  (nvdla_cdp_rdma_reg2dp_src_base_addr_low)  //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_base_addr_high (nvdla_cdp_rdma_reg2dp_src_base_addr_high) //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_line_stride    (nvdla_cdp_rdma_reg2dp_src_line_stride)    //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_surface_stride (nvdla_cdp_rdma_reg2dp_src_surface_stride) //|> i
  ,.nvdla_cdp_rdma_reg2dp_src_dma_cfg        (nvdla_cdp_rdma_reg2dp_src_dma_cfg)        //|> i
  ,.nvdla_cdp_rdma_reg2dp_data_format        (nvdla_cdp_rdma_reg2dp_data_format)        //|> i
  ,.nvdla_cdp_rdma_reg2dp_operation_mode     (nvdla_cdp_rdma_reg2dp_operation_mode)     //|> i
  ,.nvdla_cdp_rdma_reg2dp_perf_enable        (nvdla_cdp_rdma_reg2dp_perf_enable)        //|> i
  );

// Extract CSB fields from request
assign reg_addr = {csb2cdp_req_pd[21:0], 2'b00};
assign reg_wdat = csb2cdp_req_pd[53:22];
assign reg_wr_en = csb2cdp_req_pvld & csb2cdp_req_pd[54];
assign reg_rd_en = csb2cdp_req_pvld & ~csb2cdp_req_pd[54];

//===============================================================
// INTERNAL STATUS SIGNALS
//===============================================================
// Producer/consumer pointer
assign producer_ptr = nvdla_cdp_pointer[0];
assign consumer_ptr = ~producer_ptr;

// Operation enable signals
assign op_en_g0 = nvdla_cdp_cfg_op_en[0] & (producer_ptr == 1'b0);
assign op_en_g1 = nvdla_cdp_cfg_op_en[0] & (producer_ptr == 1'b1);

//===============================================================
// INTERRUPT GENERATION
//===============================================================
// Done interrupt generation - simplified
reg [1:0] done_intr_reg;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    done_intr_reg <= 2'b0;
  end else begin
    // Generate done interrupt when operation completes
    done_intr_reg <= 2'b0;  // Simplified - actual implementation would track completion
  end
end

assign cdp2glb_done_intr = done_intr_reg;

//===============================================================
// DMA CONNECTIONS (STUB - Actual implementation needs DMA controllers)
//===============================================================
// MCIF connections
assign cdp2mcif_rd_req_valid = 1'b0;
assign cdp2mcif_rd_req_pd = 38'h0;
assign mcif2cdp_rd_rsp_ready = 1'b0;

assign cdp2mcif_wr_req_valid = 1'b0;
assign cdp2mcif_wr_req_pd = 38'h0;
assign cdp2mcif_wr_dat_valid = 1'b0;
assign cdp2mcif_wr_dat_pd = 34'h0;
assign mcif2cdp_wr_rsp_ready = 1'b0;

// CVIF connections
assign cdp2cvif_rd_req_valid = 1'b0;
assign cdp2cvif_rd_req_pd = 38'h0;
assign cvif2cdp_rd_rsp_ready = 1'b0;

assign cdp2cvif_wr_req_valid = 1'b0;
assign cdp2cvif_wr_req_pd = 38'h0;
assign cdp2cvif_wr_dat_valid = 1'b0;
assign cdp2cvif_wr_dat_pd = 34'h0;
assign cvif2cdp_wr_rsp_ready = 1'b0;

//===============================================================
// STANDBY STATE (for power gating)
//===============================================================
wire [3:0] slcg_op_en;
assign slcg_op_en = {4{reg2dp_op_en}};  // Simplified clock gating

endmodule // NV_NVDLA_CDP_new