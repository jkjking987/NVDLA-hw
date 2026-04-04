// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_new.v

// Description:
// PDP top-level integration module

module NV_NVDLA_PDP_new (
    nvdla_core_clk                  //|< i
  , nvdla_core_rstn                //|< i
  // APB interface
  , psel                           //|< i
  , penable                        //|< i
  , paddr                          //|< i
  , pwdata                         //|< i
  , pwrite                         //|< i
  , prdata                         //|> o
  , pready                         //|> o
  // Interrupt
  , pdp2glb_done_intr             //|> o
  // MCIF read interface
  , mcif2pdp_rd_rsp_valid          //|< i
  , mcif2pdp_rd_rsp_ready          //|> o
  , mcif2pdp_rd_rsp_pd            //|< i
  // MCIF write interface
  , pdp2mcif_wr_req_valid         //|> o
  , pdp2mcif_wr_req_ready         //|< i
  , pdp2mcif_wr_req_pd            //|> o
  , pdp2mcif_wr_data_valid        //|> o
  , pdp2mcif_wr_data_ready        //|< i
  , pdp2mcif_wr_data_pd           //|> o
  , mcif2pdp_wr_rsp               //|< i
  // CVIF read interface
  , cvif2pdp_rd_rsp_valid          //|< i
  , cvif2pdp_rd_rsp_ready         //|> o
  , cvif2pdp_rd_rsp_pd            //|< i
  // CVIF write interface
  , pdp2cvif_wr_req_valid         //|> o
  , pdp2cvif_wr_req_ready         //|< i
  , pdp2cvif_wr_req_pd            //|> o
  , pdp2cvif_wr_data_valid        //|> o
  , pdp2cvif_wr_data_ready        //|< i
  , pdp2cvif_wr_data_pd           //|> o
  , cvif2pdp_wr_rsp               //|< i
  // SDP to PDP interface (on-flying mode)
  , sdp2pdp_valid                 //|< i
  , sdp2pdp_ready                 //|> o
  , sdp2pdp_pd                    //|< i
  // Clock gating
  , dla_clk_ovr_on_sync           //|< i
  , global_clk_ovr_on_sync        //|< i
  , tmc2slcg_disable_clock_gating  //|< i
  , pwrbus_ram_pd                  //|< i
);

//====================================================================
// Parameters
//====================================================================

//====================================================================
// Ports
//====================================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// APB interface
input        psel;
input        penable;
input [31:0] paddr;
input [31:0] pwdata;
input        pwrite;
output [31:0] prdata;
output       pready;

// Interrupt
output [1:0] pdp2glb_done_intr;

// MCIF read interface
input        mcif2pdp_rd_rsp_valid;
output       mcif2pdp_rd_rsp_ready;
input  [513:0] mcif2pdp_rd_rsp_pd;

// MCIF write interface
output       pdp2mcif_wr_req_valid;
input        pdp2mcif_wr_req_ready;
output [78:0] pdp2mcif_wr_req_pd;
output       pdp2mcif_wr_data_valid;
input        pdp2mcif_wr_data_ready;
output [511:0] pdp2mcif_wr_data_pd;
input        mcif2pdp_wr_rsp;

// CVIF read interface
input        cvif2pdp_rd_rsp_valid;
output       cvif2pdp_rd_rsp_ready;
input  [513:0] cvif2pdp_rd_rsp_pd;

// CVIF write interface
output       pdp2cvif_wr_req_valid;
input        pdp2cvif_wr_req_ready;
output [78:0] pdp2cvif_wr_req_pd;
output       pdp2cvif_wr_data_valid;
input        pdp2cvif_wr_data_ready;
output [511:0] pdp2cvif_wr_data_pd;
input        cvif2pdp_wr_rsp;

// SDP to PDP interface
input        sdp2pdp_valid;
output       sdp2pdp_ready;
input  [255:0] sdp2pdp_pd;

// Clock gating
input        dla_clk_ovr_on_sync;
input        global_clk_ovr_on_sync;
input        tmc2slcg_disable_clock_gating;
input  [31:0] pwrbus_ram_pd;

//====================================================================
// CSB interface
//====================================================================
wire        csb2pdp_req_pvld;
wire        csb2pdp_req_prdy;
wire [62:0] csb2pdp_req_pd;
wire        pdp2csb_resp_pvld;
wire        pdp2csb_resp_prdy;
wire [33:0] pdp2csb_resp_pd;

NV_NVDLA_PDP_csb_new u_csb (
    .nvdla_core_clk           (nvdla_core_clk)
  , .nvdla_core_rstn         (nvdla_core_rstn)
  , .psel                    (psel)
  , .penable                 (penable)
  , .paddr                   (paddr)
  , .pwdata                  (pwdata)
  , .pwrite                  (pwrite)
  , .prdata                  (prdata)
  , .pready                  (pready)
  , .csb2pdp_req_pvld       (csb2pdp_req_pvld)
  , .csb2pdp_req_prdy       (csb2pdp_req_prdy)
  , .csb2pdp_req_pd         (csb2pdp_req_pd)
  , .pdp2csb_resp_pvld      (pdp2csb_resp_pvld)
  , .pdp2csb_resp_prdy      (pdp2csb_resp_prdy)
  , .pdp2csb_resp_pd        (pdp2csb_resp_pd)
);

//====================================================================
// PDP Register file
//====================================================================
wire        reg2dp_op_en;
wire        reg2dp_flying_mode;
wire  [1:0] reg2dp_pooling_method;
wire  [7:0] reg2dp_split_num;
wire  [12:0] reg2dp_cube_in_width;
wire  [12:0] reg2dp_cube_in_height;
wire  [12:0] reg2dp_cube_in_channel;
wire  [12:0] reg2dp_cube_out_width;
wire  [12:0] reg2dp_cube_out_height;
wire  [12:0] reg2dp_cube_out_channel;
wire  [3:0] reg2dp_kernel_width;
wire  [3:0] reg2dp_kernel_height;
wire  [3:0] reg2dp_kernel_stride_width;
wire  [3:0] reg2dp_kernel_stride_height;
wire  [2:0] reg2dp_pad_left;
wire  [2:0] reg2dp_pad_right;
wire  [2:0] reg2dp_pad_top;
wire  [2:0] reg2dp_pad_bottom;
wire  [18:0] reg2dp_pad_value_1x;
wire  [18:0] reg2dp_pad_value_2x;
wire  [18:0] reg2dp_pad_value_3x;
wire  [18:0] reg2dp_pad_value_4x;
wire  [18:0] reg2dp_pad_value_5x;
wire  [18:0] reg2dp_pad_value_6x;
wire  [18:0] reg2dp_pad_value_7x;
wire  [9:0] reg2dp_partial_width_in_first;
wire  [9:0] reg2dp_partial_width_in_mid;
wire  [9:0] reg2dp_partial_width_in_last;
wire  [9:0] reg2dp_partial_width_out_first;
wire  [9:0] reg2dp_partial_width_out_mid;
wire  [9:0] reg2dp_partial_width_out_last;
wire  [26:0] reg2dp_src_base_addr_low;
wire  [31:0] reg2dp_src_base_addr_high;
wire  [26:0] reg2dp_src_line_stride;
wire  [26:0] reg2dp_src_surface_stride;
wire  [26:0] reg2dp_dst_base_addr_low;
wire  [31:0] reg2dp_dst_base_addr_high;
wire  [26:0] reg2dp_dst_line_stride;
wire  [26:0] reg2dp_dst_surface_stride;
wire        reg2dp_dst_ram_type;
wire  [1:0] reg2dp_input_data;
wire        reg2dp_nan_to_zero;
wire  [16:0] reg2dp_recip_kernel_width;
wire  [16:0] reg2dp_recip_kernel_height;
wire  [31:0] reg2dp_cya;
wire        reg2dp_dma_en;
wire  [2:0] slcg_op_en;

wire        dp2reg_done;
wire  [31:0] dp2reg_nan_input_num;
wire  [31:0] dp2reg_inf_input_num;
wire  [31:0] dp2reg_nan_output_num;
wire  [31:0] dp2reg_d0_perf_write_stall;
wire  [31:0] dp2reg_d1_perf_write_stall;

NV_NVDLA_PDP_reg_new u_reg (
    .nvdla_core_clk                (nvdla_core_clk)
  , .nvdla_core_rstn              (nvdla_core_rstn)
  , .csb2pdp_req_pvld            (csb2pdp_req_pvld)
  , .csb2pdp_req_prdy            (csb2pdp_req_prdy)
  , .csb2pdp_req_pd              (csb2pdp_req_pd)
  , .dp2reg_done                  (dp2reg_done)
  , .dp2reg_nan_input_num         (dp2reg_nan_input_num)
  , .dp2reg_inf_input_num         (dp2reg_inf_input_num)
  , .dp2reg_nan_output_num        (dp2reg_nan_output_num)
  , .dp2reg_d0_perf_write_stall  (dp2reg_d0_perf_write_stall)
  , .dp2reg_d1_perf_write_stall  (dp2reg_d1_perf_write_stall)
  , .pdp2csb_resp_pvld           (pdp2csb_resp_pvld)
  , .pdp2csb_resp_prdy           (pdp2csb_resp_prdy)
  , .pdp2csb_resp_pd             (pdp2csb_resp_pd)
  , .reg2dp_op_en                 (reg2dp_op_en)
  , .reg2dp_flying_mode          (reg2dp_flying_mode)
  , .reg2dp_pooling_method        (reg2dp_pooling_method)
  , .reg2dp_split_num            (reg2dp_split_num)
  , .reg2dp_cube_in_width         (reg2dp_cube_in_width)
  , .reg2dp_cube_in_height        (reg2dp_cube_in_height)
  , .reg2dp_cube_in_channel       (reg2dp_cube_in_channel)
  , .reg2dp_cube_out_width        (reg2dp_cube_out_width)
  , .reg2dp_cube_out_height       (reg2dp_cube_out_height)
  , .reg2dp_cube_out_channel      (reg2dp_cube_out_channel)
  , .reg2dp_kernel_width          (reg2dp_kernel_width)
  , .reg2dp_kernel_height         (reg2dp_kernel_height)
  , .reg2dp_kernel_stride_width    (reg2dp_kernel_stride_width)
  , .reg2dp_kernel_stride_height   (reg2dp_kernel_stride_height)
  , .reg2dp_pad_left             (reg2dp_pad_left)
  , .reg2dp_pad_right            (reg2dp_pad_right)
  , .reg2dp_pad_top              (reg2dp_pad_top)
  , .reg2dp_pad_bottom           (reg2dp_pad_bottom)
  , .reg2dp_pad_value_1x         (reg2dp_pad_value_1x)
  , .reg2dp_pad_value_2x         (reg2dp_pad_value_2x)
  , .reg2dp_pad_value_3x         (reg2dp_pad_value_3x)
  , .reg2dp_pad_value_4x         (reg2dp_pad_value_4x)
  , .reg2dp_pad_value_5x         (reg2dp_pad_value_5x)
  , .reg2dp_pad_value_6x         (reg2dp_pad_value_6x)
  , .reg2dp_pad_value_7x         (reg2dp_pad_value_7x)
  , .reg2dp_partial_width_in_first (reg2dp_partial_width_in_first)
  , .reg2dp_partial_width_in_mid   (reg2dp_partial_width_in_mid)
  , .reg2dp_partial_width_in_last  (reg2dp_partial_width_in_last)
  , .reg2dp_partial_width_out_first (reg2dp_partial_width_out_first)
  , .reg2dp_partial_width_out_mid  (reg2dp_partial_width_out_mid)
  , .reg2dp_partial_width_out_last (reg2dp_partial_width_out_last)
  , .reg2dp_src_base_addr_low    (reg2dp_src_base_addr_low)
  , .reg2dp_src_base_addr_high   (reg2dp_src_base_addr_high)
  , .reg2dp_src_line_stride       (reg2dp_src_line_stride)
  , .reg2dp_src_surface_stride    (reg2dp_src_surface_stride)
  , .reg2dp_dst_base_addr_low    (reg2dp_dst_base_addr_low)
  , .reg2dp_dst_base_addr_high   (reg2dp_dst_base_addr_high)
  , .reg2dp_dst_line_stride       (reg2dp_dst_line_stride)
  , .reg2dp_dst_surface_stride    (reg2dp_dst_surface_stride)
  , .reg2dp_dst_ram_type         (reg2dp_dst_ram_type)
  , .reg2dp_input_data           (reg2dp_input_data)
  , .reg2dp_nan_to_zero          (reg2dp_nan_to_zero)
  , .reg2dp_recip_kernel_width    (reg2dp_recip_kernel_width)
  , .reg2dp_recip_kernel_height   (reg2dp_recip_kernel_height)
  , .reg2dp_cya                  (reg2dp_cya)
  , .reg2dp_dma_en               (reg2dp_dma_en)
  , .slcg_op_en                  (slcg_op_en)
);

//====================================================================
// PDP RDMA (Read DMA)
//====================================================================
wire        csb2pdp_rdma_req_pvld;
wire        csb2pdp_rdma_req_prdy;
wire [62:0] csb2pdp_rdma_req_pd;
wire        pdp_rdma2csb_resp_pvld;
wire        pdp_rdma2csb_resp_prdy;
wire [33:0] pdp_rdma2csb_resp_pd;

wire        pdp2mcif_rd_req_valid;
wire        pdp2mcif_rd_req_ready;
wire [78:0] pdp2mcif_rd_req_pd;
wire        pdp2cvif_rd_req_valid;
wire        pdp2cvif_rd_req_ready;
wire [78:0] pdp2cvif_rd_req_pd;
wire        pdp2mcif_rd_cdt_lat_fifo_pop;
wire        pdp2cvif_rd_cdt_lat_fifo_pop;

wire        pdp_rdma2dp_valid;
wire        pdp_rdma2dp_ready;
wire [75:0] pdp_rdma2dp_pd;
wire        rdma2wdma_done;
wire  [31:0] dp2reg_d0_perf_read_stall;
wire  [31:0] dp2reg_d1_perf_read_stall;

NV_NVDLA_PDP_rdma_new u_rdma (
    .nvdla_core_clk                 (nvdla_core_clk)
  , .nvdla_core_rstn               (nvdla_core_rstn)
  , .reg2dp_op_en                  (reg2dp_op_en)
  , .reg2dp_flying_mode            (reg2dp_flying_mode)
  , .reg2dp_cube_in_width          (reg2dp_cube_in_width)
  , .reg2dp_cube_in_height         (reg2dp_cube_in_height)
  , .reg2dp_cube_in_channel        (reg2dp_cube_in_channel)
  , .reg2dp_split_num              (reg2dp_split_num)
  , .reg2dp_kernel_width           (reg2dp_kernel_width)
  , .reg2dp_kernel_stride_width    (reg2dp_kernel_stride_width)
  , .reg2dp_pad_width              ({1'b0, reg2dp_pad_left})
  , .reg2dp_partial_width_in_first (reg2dp_partial_width_in_first)
  , .reg2dp_partial_width_in_mid    (reg2dp_partial_width_in_mid)
  , .reg2dp_partial_width_in_last  (reg2dp_partial_width_in_last)
  , .reg2dp_src_base_addr_low       (reg2dp_src_base_addr_low)
  , .reg2dp_src_base_addr_high      (reg2dp_src_base_addr_high)
  , .reg2dp_src_line_stride        (reg2dp_src_line_stride)
  , .reg2dp_src_surface_stride     (reg2dp_src_surface_stride)
  , .reg2dp_src_ram_type           (reg2dp_src_ram_type)
  , .reg2dp_input_data             (reg2dp_input_data)
  , .reg2dp_cya                    (reg2dp_cya)
  , .reg2dp_surf_stride            (reg2dp_src_surface_stride[31:0])
  , .reg2dp_dma_en                (reg2dp_dma_en)
  , .csb2pdp_rdma_req_pvld        (csb2pdp_rdma_req_pvld)
  , .csb2pdp_rdma_req_prdy        (csb2pdp_rdma_req_prdy)
  , .csb2pdp_rdma_req_pd          (csb2pdp_rdma_req_pd)
  , .pdp_rdma2csb_resp_pvld       (pdp_rdma2csb_resp_pvld)
  , .pdp_rdma2csb_resp_prdy        (pdp_rdma2csb_resp_prdy)
  , .pdp_rdma2csb_resp_pd          (pdp_rdma2csb_resp_pd)
  , .mcif2pdp_rd_rsp_valid         (mcif2pdp_rd_rsp_valid)
  , .mcif2pdp_rd_rsp_ready         (mcif2pdp_rd_rsp_ready)
  , .mcif2pdp_rd_rsp_pd           (mcif2pdp_rd_rsp_pd)
  , .cvif2pdp_rd_rsp_valid         (cvif2pdp_rd_rsp_valid)
  , .cvif2pdp_rd_rsp_ready         (cvif2pdp_rd_rsp_ready)
  , .cvif2pdp_rd_rsp_pd           (cvif2pdp_rd_rsp_pd)
  , .pdp2mcif_rd_req_valid        (pdp2mcif_rd_req_valid)
  , .pdp2mcif_rd_req_ready        (pdp2mcif_rd_req_ready)
  , .pdp2mcif_rd_req_pd           (pdp2mcif_rd_req_pd)
  , .pdp2cvif_rd_req_valid        (pdp2cvif_rd_req_valid)
  , .pdp2cvif_rd_req_ready        (pdp2cvif_rd_req_ready)
  , .pdp2cvif_rd_req_pd           (pdp2cvif_rd_req_pd)
  , .pdp2mcif_rd_cdt_lat_fifo_pop (pdp2mcif_rd_cdt_lat_fifo_pop)
  , .pdp2cvif_rd_cdt_lat_fifo_pop (pdp2cvif_rd_cdt_lat_fifo_pop)
  , .pdp_rdma2dp_valid            (pdp_rdma2dp_valid)
  , .pdp_rdma2dp_ready            (pdp_rdma2dp_ready)
  , .pdp_rdma2dp_pd               (pdp_rdma2dp_pd)
  , .dp2reg_done                   (dp2reg_done)
  , .dp2reg_d0_perf_read_stall    (dp2reg_d0_perf_read_stall)
  , .dp2reg_d1_perf_read_stall    (dp2reg_d1_perf_read_stall)
  , .rdma2wdma_done               (rdma2wdma_done)
  , .dla_clk_ovr_on_sync          (dla_clk_ovr_on_sync)
  , .global_clk_ovr_on_sync       (global_clk_ovr_on_sync)
  , .tmc2slcg_disable_clock_gating (tmc2slcg_disable_clock_gating)
  , .pwrbus_ram_pd                 (pwrbus_ram_pd)
);

//====================================================================
// PDP Pooling Core
//====================================================================
wire        pool_dp2pdp_valid;
wire        pool_dp2pdp_ready;
wire [63:0] pool_dp2pdp_pd;
wire  [31:0] pool_dp2reg_nan_input_num;
wire  [31:0] pool_dp2reg_inf_input_num;
wire  [31:0] pool_dp2reg_nan_output_num;

NV_NVDLA_PDP_pool_new u_pool (
    .nvdla_core_clk                (nvdla_core_clk)
  , .nvdla_core_rstn              (nvdla_core_rstn)
  , .reg2dp_op_en                 (reg2dp_op_en)
  , .reg2dp_flying_mode          (reg2dp_flying_mode)
  , .reg2dp_input_data           (reg2dp_input_data)
  , .reg2dp_pooling_method        (reg2dp_pooling_method)
  , .reg2dp_nan_to_zero           (reg2dp_nan_to_zero)
  , .reg2dp_cube_in_width         (reg2dp_cube_in_width)
  , .reg2dp_cube_in_height        (reg2dp_cube_in_height)
  , .reg2dp_cube_in_channel       (reg2dp_cube_in_channel)
  , .reg2dp_cube_out_width        (reg2dp_cube_out_width)
  , .reg2dp_kernel_width          (reg2dp_kernel_width)
  , .reg2dp_kernel_height         (reg2dp_kernel_height)
  , .reg2dp_kernel_stride_width    (reg2dp_kernel_stride_width)
  , .reg2dp_kernel_stride_height   (reg2dp_kernel_stride_height)
  , .reg2dp_pad_left              (reg2dp_pad_left)
  , .reg2dp_pad_right             (reg2dp_pad_right)
  , .reg2dp_pad_top               (reg2dp_pad_top)
  , .reg2dp_pad_bottom            (reg2dp_pad_bottom)
  , .reg2dp_pad_value_1x         (reg2dp_pad_value_1x)
  , .reg2dp_pad_value_2x         (reg2dp_pad_value_2x)
  , .reg2dp_pad_value_3x         (reg2dp_pad_value_3x)
  , .reg2dp_pad_value_4x         (reg2dp_pad_value_4x)
  , .reg2dp_pad_value_5x         (reg2dp_pad_value_5x)
  , .reg2dp_pad_value_6x         (reg2dp_pad_value_6x)
  , .reg2dp_pad_value_7x         (reg2dp_pad_value_7x)
  , .reg2dp_partial_width_in_first (reg2dp_partial_width_in_first)
  , .reg2dp_partial_width_in_mid   (reg2dp_partial_width_in_mid)
  , .reg2dp_partial_width_in_last  (reg2dp_partial_width_in_last)
  , .reg2dp_partial_width_out_first (reg2dp_partial_width_out_first)
  , .reg2dp_partial_width_out_mid  (reg2dp_partial_width_out_mid)
  , .reg2dp_partial_width_out_last (reg2dp_partial_width_out_last)
  , .reg2dp_recip_kernel_width    (reg2dp_recip_kernel_width)
  , .reg2dp_recip_kernel_height   (reg2dp_recip_kernel_height)
  , .reg2dp_split_num             (reg2dp_split_num)
  , .pdp_rdma2dp_valid            (pdp_rdma2dp_valid)
  , .pdp_rdma2dp_ready            (pdp_rdma2dp_ready)
  , .pdp_rdma2dp_pd               (pdp_rdma2dp_pd)
  , .sdp2pdp_valid                (sdp2pdp_valid)
  , .sdp2pdp_ready                (sdp2pdp_ready)
  , .sdp2pdp_pd                   (sdp2pdp_pd)
  , .dp2pdp_valid                 (pool_dp2pdp_valid)
  , .dp2pdp_ready                 (pool_dp2pdp_ready)
  , .dp2pdp_pd                    (pool_dp2pdp_pd)
  , .dp2reg_done                  (pool_dp2reg_done)
  , .dp2reg_nan_input_num         (pool_dp2reg_nan_input_num)
  , .dp2reg_inf_input_num         (pool_dp2reg_inf_input_num)
  , .dp2reg_nan_output_num        (pool_dp2reg_nan_output_num)
  , .pwrbus_ram_pd                 (pwrbus_ram_pd)
);

// Assign pooling done to main done signal
wire pool_done_int;
assign pool_done_int = pool_dp2pdp_valid & pool_dp2pdp_ready;

//====================================================================
// PDP WDMA (Write DMA)
//====================================================================
NV_NVDLA_PDP_wdma_new u_wdma (
    .nvdla_core_clk                (nvdla_core_clk)
  , .nvdla_core_rstn              (nvdla_core_rstn)
  , .reg2dp_op_en                 (reg2dp_op_en)
  , .reg2dp_cube_out_width        (reg2dp_cube_out_width)
  , .reg2dp_cube_out_height       (reg2dp_cube_out_height)
  , .reg2dp_cube_out_channel      (reg2dp_cube_out_channel)
  , .reg2dp_dst_base_addr_low    (reg2dp_dst_base_addr_low)
  , .reg2dp_dst_base_addr_high   (reg2dp_dst_base_addr_high)
  , .reg2dp_dst_line_stride       (reg2dp_dst_line_stride)
  , .reg2dp_dst_surface_stride    (reg2dp_dst_surface_stride)
  , .reg2dp_dst_ram_type         (reg2dp_dst_ram_type)
  , .reg2dp_input_data           (reg2dp_input_data)
  , .reg2dp_split_num             (reg2dp_split_num)
  , .reg2dp_partial_width_out_first (reg2dp_partial_width_out_first)
  , .reg2dp_partial_width_out_mid  (reg2dp_partial_width_out_mid)
  , .reg2dp_partial_width_out_last (reg2dp_partial_width_out_last)
  , .reg2dp_dma_en               (reg2dp_dma_en)
  , .dp2pdp_valid                 (pool_dp2pdp_valid)
  , .dp2pdp_ready                 (pool_dp2pdp_ready)
  , .dp2pdp_pd                    (pool_dp2pdp_pd)
  , .pdp2mcif_wr_req_valid       (pdp2mcif_wr_req_valid)
  , .pdp2mcif_wr_req_ready       (pdp2mcif_wr_req_ready)
  , .pdp2mcif_wr_req_pd           (pdp2mcif_wr_req_pd)
  , .pdp2mcif_wr_data_valid      (pdp2mcif_wr_data_valid)
  , .pdp2mcif_wr_data_ready      (pdp2mcif_wr_data_ready)
  , .pdp2mcif_wr_data_pd          (pdp2mcif_wr_data_pd)
  , .pdp2cvif_wr_req_valid       (pdp2cvif_wr_req_valid)
  , .pdp2cvif_wr_req_ready       (pdp2cvif_wr_req_ready)
  , .pdp2cvif_wr_req_pd           (pdp2cvif_wr_req_pd)
  , .pdp2cvif_wr_data_valid      (pdp2cvif_wr_data_valid)
  , .pdp2cvif_wr_data_ready      (pdp2cvif_wr_data_ready)
  , .pdp2cvif_wr_data_pd          (pdp2cvif_wr_data_pd)
  , .mcif2pdp_wr_rsp              (mcif2pdp_wr_rsp)
  , .cvif2pdp_wr_rsp              (cvif2pdp_wr_rsp)
  , .dp2reg_done                  (dp2reg_done)
  , .dp2reg_d0_perf_write_stall  (dp2reg_d0_perf_write_stall)
  , .dp2reg_d1_perf_write_stall  (dp2reg_d1_perf_write_stall)
  , .wdma2pdp_done               (wdma2pdp_done)
  , .pwrbus_ram_pd                 (pwrbus_ram_pd)
);

//====================================================================
// Interrupt generation
//====================================================================
reg [1:0] done_intr_reg;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        done_intr_reg <= 2'b00;
    end else begin
        if (dp2reg_done) begin
            done_intr_reg <= done_intr_reg + 2'd1;
        end
    end
end

assign pdp2glb_done_intr = done_intr_reg;

endmodule // NV_NVDLA_PDP_new