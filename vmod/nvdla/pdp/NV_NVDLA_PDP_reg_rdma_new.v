// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_reg_rdma_new.v

// Description:
// PDP RDMA register file with dual register groups for ping-pong operation
// Register address range: 0x000 - 0xFFF (4KB space)

module NV_NVDLA_PDP_reg_rdma_new (
    nvdla_core_clk                    //|< i
  , nvdla_core_rstn                  //|< i
  , csb2pdp_rdma_req_pvld            //|< i
  , csb2pdp_rdma_req_prdy            //|> o
  , csb2pdp_rdma_req_pd              //|< i
  , dp2reg_done                       //|< i
  , dp2reg_d0_perf_read_stall         //|< i
  , dp2reg_d1_perf_read_stall         //|< i
  , pdp_rdma2csb_resp_pvld            //|> o
  , pdp_rdma2csb_resp_prdy            //|< i
  , pdp_rdma2csb_resp_pd             //|> o
  , reg2dp_op_en                      //|> o
  , reg2dp_flying_mode               //|> o
  , reg2dp_cube_in_width             //|> o
  , reg2dp_cube_in_height            //|> o
  , reg2dp_cube_in_channel           //|> o
  , reg2dp_split_num                 //|> o
  , reg2dp_kernel_width              //|> o
  , reg2dp_kernel_stride_width       //|> o
  , reg2dp_pad_width                 //|> o
  , reg2dp_partial_width_in_first     //|> o
  , reg2dp_partial_width_in_mid      //|> o
  , reg2dp_partial_width_in_last     //|> o
  , reg2dp_src_base_addr_low         //|> o
  , reg2dp_src_base_addr_high        //|> o
  , reg2dp_src_line_stride           //|> o
  , reg2dp_src_surface_stride        //|> o
  , reg2dp_src_ram_type              //|> o
  , reg2dp_input_data                //|> o
  , reg2dp_cya                       //|> o
  , reg2dp_surf_stride               //|> o
  , reg2dp_dma_en                    //|> o
  , slcg_op_en                      //|> o
);

//====================================================================
// Parameters
//====================================================================
// Register offsets for RDMA
localparam [11:0] REG_D_OP_ENABLE        = 12'hD008;
localparam [11:0] REG_D_DATA_CUBE_IN_WIDTH   = 12'hD00C;
localparam [11:0] REG_D_DATA_CUBE_IN_HEIGHT  = 12'hD010;
localparam [11:0] REG_D_DATA_CUBE_IN_CHANNEL  = 12'hD014;
localparam [11:0] REG_D_FLYING_MODE          = 12'hD018;
localparam [11:0] REG_D_SRC_BASE_ADDR_LOW   = 12'hD01C;
localparam [11:0] REG_D_SRC_BASE_ADDR_HIGH  = 12'hD020;
localparam [11:0] REG_D_SRC_LINE_STRIDE     = 12'hD024;
localparam [11:0] REG_D_SRC_SURFACE_STRIDE  = 12'hD028;
localparam [11:0] REG_D_SRC_RAM_CFG          = 12'hD02C;
localparam [11:0] REG_D_DATA_FORMAT          = 12'hD030;
localparam [11:0] REG_D_OPERATION_MODE_CFG   = 12'hD034;
localparam [11:0] REG_D_POOLING_KERNEL_CFG   = 12'hD038;
localparam [11:0] REG_D_POOLING_PADDING_CFG  = 12'hD03C;
localparam [11:0] REG_D_PARTIAL_WIDTH_IN     = 12'hD040;
localparam [11:0] REG_D_PERF_ENABLE          = 12'hD044;
localparam [11:0] REG_D_PERF_READ_STALL      = 12'hD048;
localparam [11:0] REG_D_CYA                  = 12'hD04C;
localparam [11:0] REG_S_POINTER              = 12'hD100;
localparam [11:0] REG_S_STATUS               = 12'hD104;

//====================================================================
// Ports
//====================================================================
input        nvdla_core_clk;
input        nvdla_core_rstn;
input        csb2pdp_rdma_req_pvld;
output       csb2pdp_rdma_req_prdy;
input  [62:0] csb2pdp_rdma_req_pd;
input        dp2reg_done;
input  [31:0] dp2reg_d0_perf_read_stall;
input  [31:0] dp2reg_d1_perf_read_stall;
output       pdp_rdma2csb_resp_pvld;
input        pdp_rdma2csb_resp_prdy;
output [33:0] pdp_rdma2csb_resp_pd;

output       reg2dp_op_en;
output       reg2dp_flying_mode;
output [12:0] reg2dp_cube_in_width;
output [12:0] reg2dp_cube_in_height;
output [12:0] reg2dp_cube_in_channel;
output [7:0] reg2dp_split_num;
output [3:0] reg2dp_kernel_width;
output [3:0] reg2dp_kernel_stride_width;
output [3:0] reg2dp_pad_width;
output [9:0] reg2dp_partial_width_in_first;
output [9:0] reg2dp_partial_width_in_mid;
output [9:0] reg2dp_partial_width_in_last;
output [26:0] reg2dp_src_base_addr_low;
output [31:0] reg2dp_src_base_addr_high;
output [26:0] reg2dp_src_line_stride;
output [26:0] reg2dp_src_surface_stride;
output       reg2dp_src_ram_type;
output [1:0] reg2dp_input_data;
output [31:0] reg2dp_cya;
output [31:0] reg2dp_surf_stride;
output       reg2dp_dma_en;
output       slcg_op_en;

//====================================================================
// Internal signals
//====================================================================
wire  [11:0] reg_addr;
wire  [31:0] reg_wr_data;
wire         reg_wr_en;
wire         reg_rd_en;
wire  [31:0] reg_rd_data;

reg   [31:0] reg_rdata_d0;
reg   [31:0] reg_rdata_d1;
reg   [31:0] reg_rdata_s;

reg         producer;
reg         consumer;
reg   [1:0] status_0;
reg   [1:0] status_1;

reg         op_en_d0;
reg         op_en_d1;
reg         op_en_d0_w;
reg         op_en_d1_w;

reg         slcg_op_en_d0;
reg         slcg_op_en_d1;
reg         slcg_op_en_d2;

wire        select_s;
wire        select_d0;
wire        select_d1;

// D0 registers
reg  [12:0] d0_reg_cube_in_width;
reg  [12:0] d0_reg_cube_in_height;
reg  [12:0] d0_reg_cube_in_channel;
reg         d0_reg_flying_mode;
reg   [7:0] d0_reg_split_num;
reg   [3:0] d0_reg_kernel_width;
reg   [3:0] d0_reg_kernel_stride_width;
reg   [3:0] d0_reg_pad_width;
reg   [9:0] d0_reg_partial_width_in_first;
reg   [9:0] d0_reg_partial_width_in_mid;
reg   [9:0] d0_reg_partial_width_in_last;
reg  [26:0] d0_reg_src_base_addr_low;
reg  [31:0] d0_reg_src_base_addr_high;
reg  [26:0] d0_reg_src_line_stride;
reg  [26:0] d0_reg_src_surface_stride;
reg         d0_reg_src_ram_type;
reg   [1:0] d0_reg_input_data;
reg         d0_reg_dma_en;
reg  [31:0] d0_reg_cya;
reg  [31:0] d0_reg_surf_stride;

// D1 registers
reg  [12:0] d1_reg_cube_in_width;
reg  [12:0] d1_reg_cube_in_height;
reg  [12:0] d1_reg_cube_in_channel;
reg         d1_reg_flying_mode;
reg   [7:0] d1_reg_split_num;
reg   [3:0] d1_reg_kernel_width;
reg   [3:0] d1_reg_kernel_stride_width;
reg   [3:0] d1_reg_pad_width;
reg   [9:0] d1_reg_partial_width_in_first;
reg   [9:0] d1_reg_partial_width_in_mid;
reg   [9:0] d1_reg_partial_width_in_last;
reg  [26:0] d1_reg_src_base_addr_low;
reg  [31:0] d1_reg_src_base_addr_high;
reg  [26:0] d1_reg_src_line_stride;
reg  [26:0] d1_reg_src_surface_stride;
reg         d1_reg_src_ram_type;
reg   [1:0] d1_reg_input_data;
reg         d1_reg_dma_en;
reg  [31:0] d1_reg_cya;
reg  [31:0] d1_reg_surf_stride;

//====================================================================
// CSB request decode
//====================================================================
assign reg_addr     = csb2pdp_rdma_req_pd[33:22];
assign reg_wr_data  = csb2pdp_rdma_req_pd[53:22];
assign reg_wr_en    = csb2pdp_rdma_req_pvld & csb2pdp_rdma_req_pd[54];
assign reg_rd_en    = csb2pdp_rdma_req_pvld & ~csb2pdp_rdma_req_pd[54];

assign csb2pdp_rdma_req_prdy = 1'b1;

//====================================================================
// Register group selection
//====================================================================
assign select_s  = (reg_addr < REG_D_OP_ENABLE);
assign select_d0 = (reg_addr >= REG_D_OP_ENABLE) & (producer == 1'b0);
assign select_d1 = (reg_addr >= REG_D_OP_ENABLE) & (producer == 1'b1);

//====================================================================
// Consumer/Producer pointer logic
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        consumer <= 1'b0;
    end else begin
        if (dp2reg_done) begin
            consumer <= ~consumer;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        producer <= 1'b0;
    end else begin
        if (reg_wr_en & (reg_addr == REG_S_POINTER)) begin
            producer <= reg_wr_data[0];
        end
    end
end

//====================================================================
// Status generation
//====================================================================
always @(*) begin
    case (op_en_d0)
        1'b0:    status_0 = 2'b00;
        default: status_0 = consumer ? 2'b10 : 2'b01;
    endcase
end

always @(*) begin
    case (op_en_d1)
        1'b0:    status_1 = 2'b00;
        default: status_1 = consumer ? 2'b01 : 2'b10;
    endcase
end

//====================================================================
// Op enable logic
//====================================================================
always @(*) begin
    op_en_d0_w = (~op_en_d0 & reg_wr_data[0]) & select_d0 ?
                  1'b1 : (dp2reg_done & (consumer == 1'b0)) ? 1'b0 : op_en_d0;
end

always @(*) begin
    op_en_d1_w = (~op_en_d1 & reg_wr_data[0]) & select_d1 ?
                  1'b1 : (dp2reg_done & (consumer == 1'b1)) ? 1'b0 : op_en_d1;
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        op_en_d0 <= 1'b0;
    end else begin
        op_en_d0 <= op_en_d0_w;
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        op_en_d1 <= 1'b0;
    end else begin
        op_en_d1 <= op_en_d1_w;
    end
end

//====================================================================
// SLCG enable generation
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        slcg_op_en_d0 <= 1'b0;
    end else begin
        slcg_op_en_d0 <= op_en_d0 | op_en_d1;
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        slcg_op_en_d1 <= 1'b0;
    end else begin
        slcg_op_en_d1 <= slcg_op_en_d0;
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        slcg_op_en_d2 <= 1'b0;
    end else begin
        slcg_op_en_d2 <= slcg_op_en_d1;
    end
end

assign slcg_op_en = slcg_op_en_d2;

//====================================================================
// D0 register writes
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_cube_in_width <= 13'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_CUBE_IN_WIDTH)
            d0_reg_cube_in_width <= reg_wr_data[12:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_cube_in_height <= 13'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_CUBE_IN_HEIGHT)
            d0_reg_cube_in_height <= reg_wr_data[12:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_cube_in_channel <= 13'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_CUBE_IN_CHANNEL)
            d0_reg_cube_in_channel <= reg_wr_data[12:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_flying_mode <= 1'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_FLYING_MODE)
            d0_reg_flying_mode <= reg_wr_data[0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_split_num <= 8'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_OPERATION_MODE_CFG)
            d0_reg_split_num <= reg_wr_data[23:16];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_kernel_width <= 4'd0;
        d0_reg_kernel_stride_width <= 4'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_POOLING_KERNEL_CFG) begin
            d0_reg_kernel_width <= reg_wr_data[3:0];
            d0_reg_kernel_stride_width <= reg_wr_data[11:8];
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_pad_width <= 4'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_POOLING_PADDING_CFG)
            d0_reg_pad_width <= reg_wr_data[3:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_partial_width_in_first <= 10'd0;
        d0_reg_partial_width_in_mid <= 10'd0;
        d0_reg_partial_width_in_last <= 10'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_PARTIAL_WIDTH_IN) begin
            d0_reg_partial_width_in_first <= reg_wr_data[9:0];
            d0_reg_partial_width_in_mid <= reg_wr_data[19:10];
            d0_reg_partial_width_in_last <= reg_wr_data[29:20];
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_src_base_addr_low <= 27'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_BASE_ADDR_LOW)
            d0_reg_src_base_addr_low <= reg_wr_data[26:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_src_base_addr_high <= 32'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_BASE_ADDR_HIGH)
            d0_reg_src_base_addr_high <= reg_wr_data[31:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_src_line_stride <= 27'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_LINE_STRIDE)
            d0_reg_src_line_stride <= reg_wr_data[26:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_src_surface_stride <= 27'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_SURFACE_STRIDE)
            d0_reg_src_surface_stride <= reg_wr_data[26:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_src_ram_type <= 1'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_RAM_CFG)
            d0_reg_src_ram_type <= reg_wr_data[0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_input_data <= 2'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_FORMAT)
            d0_reg_input_data <= reg_wr_data[1:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_dma_en <= 1'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_PERF_ENABLE)
            d0_reg_dma_en <= reg_wr_data[0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_cya <= 32'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_CYA)
            d0_reg_cya <= reg_wr_data[31:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d0_reg_surf_stride <= 32'd0;
    end else if (select_d0 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_SURFACE_STRIDE)
            d0_reg_surf_stride <= reg_wr_data[31:0];
    end
end

//====================================================================
// D1 register writes (identical to D0)
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_cube_in_width <= 13'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_CUBE_IN_WIDTH)
            d1_reg_cube_in_width <= reg_wr_data[12:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_cube_in_height <= 13'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_CUBE_IN_HEIGHT)
            d1_reg_cube_in_height <= reg_wr_data[12:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_cube_in_channel <= 13'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_CUBE_IN_CHANNEL)
            d1_reg_cube_in_channel <= reg_wr_data[12:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_flying_mode <= 1'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_FLYING_MODE)
            d1_reg_flying_mode <= reg_wr_data[0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_split_num <= 8'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_OPERATION_MODE_CFG)
            d1_reg_split_num <= reg_wr_data[23:16];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_kernel_width <= 4'd0;
        d1_reg_kernel_stride_width <= 4'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_POOLING_KERNEL_CFG) begin
            d1_reg_kernel_width <= reg_wr_data[3:0];
            d1_reg_kernel_stride_width <= reg_wr_data[11:8];
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_pad_width <= 4'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_POOLING_PADDING_CFG)
            d1_reg_pad_width <= reg_wr_data[3:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_partial_width_in_first <= 10'd0;
        d1_reg_partial_width_in_mid <= 10'd0;
        d1_reg_partial_width_in_last <= 10'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_PARTIAL_WIDTH_IN) begin
            d1_reg_partial_width_in_first <= reg_wr_data[9:0];
            d1_reg_partial_width_in_mid <= reg_wr_data[19:10];
            d1_reg_partial_width_in_last <= reg_wr_data[29:20];
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_src_base_addr_low <= 27'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_BASE_ADDR_LOW)
            d1_reg_src_base_addr_low <= reg_wr_data[26:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_src_base_addr_high <= 32'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_BASE_ADDR_HIGH)
            d1_reg_src_base_addr_high <= reg_wr_data[31:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_src_line_stride <= 27'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_LINE_STRIDE)
            d1_reg_src_line_stride <= reg_wr_data[26:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_src_surface_stride <= 27'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_SURFACE_STRIDE)
            d1_reg_src_surface_stride <= reg_wr_data[26:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_src_ram_type <= 1'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_RAM_CFG)
            d1_reg_src_ram_type <= reg_wr_data[0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_input_data <= 2'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_DATA_FORMAT)
            d1_reg_input_data <= reg_wr_data[1:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_dma_en <= 1'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_PERF_ENABLE)
            d1_reg_dma_en <= reg_wr_data[0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_cya <= 32'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_CYA)
            d1_reg_cya <= reg_wr_data[31:0];
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        d1_reg_surf_stride <= 32'd0;
    end else if (select_d1 & reg_wr_en) begin
        if (reg_addr == REG_D_SRC_SURFACE_STRIDE)
            d1_reg_surf_stride <= reg_wr_data[31:0];
    end
end

//====================================================================
// Read data selection
//====================================================================
always @(*) begin
    reg_rdata_d0 = 32'd0;
    case (reg_addr)
        REG_D_OP_ENABLE:        reg_rdata_d0 = {{31{1'b0}}, op_en_d0};
        REG_D_DATA_CUBE_IN_WIDTH:   reg_rdata_d0 = {{19{1'b0}}, d0_reg_cube_in_width};
        REG_D_DATA_CUBE_IN_HEIGHT:  reg_rdata_d0 = {{19{1'b0}}, d0_reg_cube_in_height};
        REG_D_DATA_CUBE_IN_CHANNEL: reg_rdata_d0 = {{19{1'b0}}, d0_reg_cube_in_channel};
        REG_D_FLYING_MODE:      reg_rdata_d0 = {{31{1'b0}}, d0_reg_flying_mode};
        REG_D_SRC_BASE_ADDR_LOW:  reg_rdata_d0 = {{5{1'b0}}, d0_reg_src_base_addr_low};
        REG_D_SRC_BASE_ADDR_HIGH: reg_rdata_d0 = d0_reg_src_base_addr_high;
        REG_D_SRC_LINE_STRIDE:   reg_rdata_d0 = {{5{1'b0}}, d0_reg_src_line_stride};
        REG_D_SRC_SURFACE_STRIDE: reg_rdata_d0 = {{5{1'b0}}, d0_reg_src_surface_stride};
        REG_D_SRC_RAM_CFG:       reg_rdata_d0 = {{31{1'b0}}, d0_reg_src_ram_type};
        REG_D_DATA_FORMAT:       reg_rdata_d0 = {{30{1'b0}}, d0_reg_input_data};
        REG_D_OPERATION_MODE_CFG: reg_rdata_d0 = {{8{1'b0}}, d0_reg_split_num, 16'd0};
        REG_D_POOLING_KERNEL_CFG: reg_rdata_d0 = {8'd0, d0_reg_kernel_stride_width, 4'd0, d0_reg_kernel_width};
        REG_D_POOLING_PADDING_CFG: reg_rdata_d0 = {12'd0, d0_reg_pad_width};
        REG_D_PARTIAL_WIDTH_IN: reg_rdata_d0 = {d0_reg_partial_width_in_last, d0_reg_partial_width_in_mid, d0_reg_partial_width_in_first};
        REG_D_PERF_ENABLE:       reg_rdata_d0 = {{31{1'b0}}, d0_reg_dma_en};
        REG_D_PERF_READ_STALL:   reg_rdata_d0 = dp2reg_d0_perf_read_stall;
        REG_D_CYA:               reg_rdata_d0 = d0_reg_cya;
        default:                 reg_rdata_d0 = 32'd0;
    endcase
end

always @(*) begin
    reg_rdata_d1 = 32'd0;
    case (reg_addr)
        REG_D_OP_ENABLE:        reg_rdata_d1 = {{31{1'b0}}, op_en_d1};
        REG_D_DATA_CUBE_IN_WIDTH:   reg_rdata_d1 = {{19{1'b0}}, d1_reg_cube_in_width};
        REG_D_DATA_CUBE_IN_HEIGHT:  reg_rdata_d1 = {{19{1'b0}}, d1_reg_cube_in_height};
        REG_D_DATA_CUBE_IN_CHANNEL: reg_rdata_d1 = {{19{1'b0}}, d1_reg_cube_in_channel};
        REG_D_FLYING_MODE:      reg_rdata_d1 = {{31{1'b0}}, d1_reg_flying_mode};
        REG_D_SRC_BASE_ADDR_LOW:  reg_rdata_d1 = {{5{1'b0}}, d1_reg_src_base_addr_low};
        REG_D_SRC_BASE_ADDR_HIGH: reg_rdata_d1 = d1_reg_src_base_addr_high;
        REG_D_SRC_LINE_STRIDE:   reg_rdata_d1 = {{5{1'b0}}, d1_reg_src_line_stride};
        REG_D_SRC_SURFACE_STRIDE: reg_rdata_d1 = {{5{1'b0}}, d1_reg_src_surface_stride};
        REG_D_SRC_RAM_CFG:       reg_rdata_d1 = {{31{1'b0}}, d1_reg_src_ram_type};
        REG_D_DATA_FORMAT:       reg_rdata_d1 = {{30{1'b0}}, d1_reg_input_data};
        REG_D_OPERATION_MODE_CFG: reg_rdata_d1 = {{8{1'b0}}, d1_reg_split_num, 16'd0};
        REG_D_POOLING_KERNEL_CFG: reg_rdata_d1 = {8'd0, d1_reg_kernel_stride_width, 4'd0, d1_reg_kernel_width};
        REG_D_POOLING_PADDING_CFG: reg_rdata_d1 = {12'd0, d1_reg_pad_width};
        REG_D_PARTIAL_WIDTH_IN: reg_rdata_d1 = {d1_reg_partial_width_in_last, d1_reg_partial_width_in_mid, d1_reg_partial_width_in_first};
        REG_D_PERF_ENABLE:       reg_rdata_d1 = {{31{1'b0}}, d1_reg_dma_en};
        REG_D_PERF_READ_STALL:   reg_rdata_d1 = dp2reg_d1_perf_read_stall;
        REG_D_CYA:               reg_rdata_d1 = d1_reg_cya;
        default:                 reg_rdata_d1 = 32'd0;
    endcase
end

always @(*) begin
    reg_rdata_s = 32'd0;
    case (reg_addr)
        REG_S_POINTER: reg_rdata_s = {{30{1'b0}}, producer, consumer};
        REG_S_STATUS:  reg_rdata_s = {status_1, status_0};
        default:       reg_rdata_s = 32'd0;
    endcase
end

assign reg_rd_data = ({32{select_s}} & reg_rdata_s) |
                     ({32{select_d0}} & reg_rdata_d0) |
                     ({32{select_d1}} & reg_rdata_d1);

//====================================================================
// CSB response
//====================================================================
reg  [33:0] pdp_rdma2csb_resp_pd_int;
reg         pdp_rdma2csb_resp_pvld_int;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pdp_rdma2csb_resp_pvld_int <= 1'b0;
    end else begin
        pdp_rdma2csb_resp_pvld_int <= reg_rd_en | (reg_wr_en & csb2pdp_rdma_req_pd[55]);
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pdp_rdma2csb_resp_pd_int <= {34{1'b0}};
    end else begin
        if (reg_rd_en) begin
            pdp_rdma2csb_resp_pd_int <= {reg_rd_data, 1'b0, 1'b0};
        end else if (reg_wr_en) begin
            pdp_rdma2csb_resp_pd_int <= {reg_wr_data, 1'b0, 1'b1};
        end
    end
end

assign pdp_rdma2csb_resp_pvld = pdp_rdma2csb_resp_pvld_int;
assign pdp_rdma2csb_resp_pd = pdp_rdma2csb_resp_pd_int;

//====================================================================
// Output assignments - select active group based on consumer
//====================================================================
assign reg2dp_op_en = consumer ? op_en_d1 : op_en_d0;
assign reg2dp_flying_mode = consumer ? d1_reg_flying_mode : d0_reg_flying_mode;
assign reg2dp_cube_in_width = consumer ? d1_reg_cube_in_width : d0_reg_cube_in_width;
assign reg2dp_cube_in_height = consumer ? d1_reg_cube_in_height : d0_reg_cube_in_height;
assign reg2dp_cube_in_channel = consumer ? d1_reg_cube_in_channel : d0_reg_cube_in_channel;
assign reg2dp_split_num = consumer ? d1_reg_split_num : d0_reg_split_num;
assign reg2dp_kernel_width = consumer ? d1_reg_kernel_width : d0_reg_kernel_width;
assign reg2dp_kernel_stride_width = consumer ? d1_reg_kernel_stride_width : d0_reg_kernel_stride_width;
assign reg2dp_pad_width = consumer ? d1_reg_pad_width : d0_reg_pad_width;
assign reg2dp_partial_width_in_first = consumer ? d1_reg_partial_width_in_first : d0_reg_partial_width_in_first;
assign reg2dp_partial_width_in_mid = consumer ? d1_reg_partial_width_in_mid : d0_reg_partial_width_in_mid;
assign reg2dp_partial_width_in_last = consumer ? d1_reg_partial_width_in_last : d0_reg_partial_width_in_last;
assign reg2dp_src_base_addr_low = consumer ? d1_reg_src_base_addr_low : d0_reg_src_base_addr_low;
assign reg2dp_src_base_addr_high = consumer ? d1_reg_src_base_addr_high : d0_reg_src_base_addr_high;
assign reg2dp_src_line_stride = consumer ? d1_reg_src_line_stride : d0_reg_src_line_stride;
assign reg2dp_src_surface_stride = consumer ? d1_reg_src_surface_stride : d0_reg_src_surface_stride;
assign reg2dp_src_ram_type = consumer ? d1_reg_src_ram_type : d0_reg_src_ram_type;
assign reg2dp_input_data = consumer ? d1_reg_input_data : d0_reg_input_data;
assign reg2dp_cya = consumer ? d1_reg_cya : d0_reg_cya;
assign reg2dp_surf_stride = consumer ? d1_reg_surf_stride : d0_reg_surf_stride;
assign reg2dp_dma_en = consumer ? d1_reg_dma_en : d0_reg_dma_en;

endmodule // NV_NVDLA_PDP_reg_rdma_new