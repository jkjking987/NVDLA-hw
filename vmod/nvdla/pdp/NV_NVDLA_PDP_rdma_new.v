// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_rdma_new.v

// Description:
// PDP Read DMA - reads input data from external memory (MCIF/CVIF)

module NV_NVDLA_PDP_rdma_new (
    nvdla_core_clk                  //|< i
  , nvdla_core_rstn                //|< i
  // Register interface
  , reg2dp_op_en                  //|< i
  , reg2dp_flying_mode            //|< i
  , reg2dp_cube_in_width          //|< i
  , reg2dp_cube_in_height         //|< i
  , reg2dp_cube_in_channel        //|< i
  , reg2dp_split_num              //|< i
  , reg2dp_kernel_width           //|< i
  , reg2dp_kernel_stride_width     //|< i
  , reg2dp_pad_width              //|< i
  , reg2dp_partial_width_in_first  //|< i
  , reg2dp_partial_width_in_mid    //|< i
  , reg2dp_partial_width_in_last   //|< i
  , reg2dp_src_base_addr_low       //|< i
  , reg2dp_src_base_addr_high     //|< i
  , reg2dp_src_line_stride         //|< i
  , reg2dp_src_surface_stride     //|< i
  , reg2dp_src_ram_type           //|< i
  , reg2dp_input_data             //|< i
  , reg2dp_cya                   //|< i
  , reg2dp_surf_stride            //|< i
  , reg2dp_dma_en                 //|< i
  // CSB interface
  , csb2pdp_rdma_req_pvld        //|< i
  , csb2pdp_rdma_req_prdy         //|> o
  , csb2pdp_rdma_req_pd           //|< i
  , pdp_rdma2csb_resp_pvld        //|> o
  , pdp_rdma2csb_resp_prdy        //|< i
  , pdp_rdma2csb_resp_pd         //|> o
  // MCIF interface
  , mcif2pdp_rd_rsp_valid         //|< i
  , mcif2pdp_rd_rsp_ready         //|> o
  , mcif2pdp_rd_rsp_pd            //|< i
  // CVIF interface
  , cvif2pdp_rd_rsp_valid         //|< i
  , cvif2pdp_rd_rsp_ready         //|> o
  , cvif2pdp_rd_rsp_pd            //|< i
  // Read request outputs
  , pdp2mcif_rd_req_valid         //|> o
  , pdp2mcif_rd_req_ready         //|< i
  , pdp2mcif_rd_req_pd           //|> o
  , pdp2cvif_rd_req_valid         //|> o
  , pdp2cvif_rd_req_ready         //|< i
  , pdp2cvif_rd_req_pd           //|> o
  , pdp2mcif_rd_cdt_lat_fifo_pop  //|> o
  , pdp2cvif_rd_cdt_lat_fifo_pop  //|> o
  // Output to pooling core
  , pdp_rdma2dp_valid             //|> o
  , pdp_rdma2dp_ready             //|< i
  , pdp_rdma2dp_pd               //|> o
  // Status
  , dp2reg_done                   //|> o
  , dp2reg_d0_perf_read_stall     //|> o
  , dp2reg_d1_perf_read_stall     //|> o
  , rdma2wdma_done                //|> o
  // Clock gating
  , dla_clk_ovr_on_sync          //|< i
  , global_clk_ovr_on_sync        //|< i
  , tmc2slcg_disable_clock_gating //|< i
  , pwrbus_ram_pd                 //|< i
);

//====================================================================
// Parameters
//====================================================================
localparam RDMA_STATE_IDLE = 2'd0;
localparam RDMA_STATE_RUNNING = 2'd1;
localparam RDMA_STATE_DONE = 2'd2;

// ATOM_CUBE_SIZE = 32 bytes
localparam ATOM_CUBE_SIZE = 6'd32;

// Data format constants
localparam DATA_FORMAT_INT8 = 2'd0;
localparam DATA_FORMAT_INT16 = 2'd1;
localparam DATA_FORMAT_FP16 = 2'd2;

// Flying mode
localparam FLYING_MODE_ON = 1'd0;
localparam FLYING_MODE_OFF = 1'd1;

//====================================================================
// Ports
//====================================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// Register interface
input        reg2dp_op_en;
input        reg2dp_flying_mode;
input  [12:0] reg2dp_cube_in_width;
input  [12:0] reg2dp_cube_in_height;
input  [12:0] reg2dp_cube_in_channel;
input  [7:0] reg2dp_split_num;
input  [3:0] reg2dp_kernel_width;
input  [3:0] reg2dp_kernel_stride_width;
input  [3:0] reg2dp_pad_width;
input  [9:0] reg2dp_partial_width_in_first;
input  [9:0] reg2dp_partial_width_in_mid;
input  [9:0] reg2dp_partial_width_in_last;
input  [26:0] reg2dp_src_base_addr_low;
input  [31:0] reg2dp_src_base_addr_high;
input  [26:0] reg2dp_src_line_stride;
input  [26:0] reg2dp_src_surface_stride;
input        reg2dp_src_ram_type;
input  [1:0] reg2dp_input_data;
input  [31:0] reg2dp_cya;
input  [31:0] reg2dp_surf_stride;
input        reg2dp_dma_en;

// CSB interface
input        csb2pdp_rdma_req_pvld;
output       csb2pdp_rdma_req_prdy;
input  [62:0] csb2pdp_rdma_req_pd;
output       pdp_rdma2csb_resp_pvld;
input        pdp_rdma2csb_resp_prdy;
output [33:0] pdp_rdma2csb_resp_pd;

// MCIF interface
input        mcif2pdp_rd_rsp_valid;
output       mcif2pdp_rd_rsp_ready;
input  [513:0] mcif2pdp_rd_rsp_pd;

// CVIF interface
input        cvif2pdp_rd_rsp_valid;
output       cvif2pdp_rd_rsp_ready;
input  [513:0] cvif2pdp_rd_rsp_pd;

// Read request outputs
output       pdp2mcif_rd_req_valid;
input        pdp2mcif_rd_req_ready;
output [78:0] pdp2mcif_rd_req_pd;
output       pdp2cvif_rd_req_valid;
input        pdp2cvif_rd_req_ready;
output [78:0] pdp2cvif_rd_req_pd;
output       pdp2mcif_rd_cdt_lat_fifo_pop;
output       pdp2cvif_rd_cdt_lat_fifo_pop;

// Output to pooling core
output       pdp_rdma2dp_valid;
input        pdp_rdma2dp_ready;
output [75:0] pdp_rdma2dp_pd;

// Status
output       dp2reg_done;
output [31:0] dp2reg_d0_perf_read_stall;
output [31:0] dp2reg_d1_perf_read_stall;
output       rdma2wdma_done;

// Clock gating
input        dla_clk_ovr_on_sync;
input        global_clk_ovr_on_sync;
input        tmc2slcg_disable_clock_gating;
input  [31:0] pwrbus_ram_pd;

//====================================================================
// Internal signals
//====================================================================
wire  [11:0] reg_addr;
wire  [31:0] reg_wr_data;
wire         reg_wr_en;
wire         reg_rd_en;

wire         nvdla_op_gated_clk;

reg   [1:0] rdma_state;
reg   [1:0] rdma_state_next;

reg   [12:0] cube_in_width;
reg   [12:0] cube_in_height;
reg   [12:0] cube_in_channel;
reg   [26:0] src_base_addr_low;
reg   [31:0] src_base_addr_high;
reg   [26:0] src_line_stride;
reg   [26:0] src_surface_stride;
reg   [7:0] split_num;
reg   [3:0] kernel_width;
reg   [3:0] kernel_stride_width;
reg   [3:0] pad_width;
reg   [9:0] partial_width_in_first;
reg   [9:0] partial_width_in_mid;
reg   [9:0] partial_width_in_last;

reg   [7:0] split_count;
reg   [12:0] current_width;
reg   [12:0] current_height;
reg   [12:0] current_channel;
reg   [12:0] atom_count;
reg   [12:0] atom_sent;
reg   [26:0] current_base_addr;

wire  [12:0] cube_in_width_plus1;
wire  [12:0] cube_in_height_plus1;
wire  [12:0] cube_in_channel_plus1;
wire  [7:0] split_num_plus1;
wire  [3:0] kernel_width_plus1;
wire  [3:0] kernel_stride_width_plus1;

wire  [12:0] element_per_atom;
wire  [26:0] atom_addr;
wire  [7:0] atom_size;

wire        request_sent;
wire        is_mcif;
wire        is_cvif;

reg   [31:0] perf_read_stall_count;
reg         rdma_start;
reg         rdma_done;
reg         eg2ig_done;

// CQ signals
wire  [17:0] ig2cq_pd;
wire         ig2cq_pvld;
wire         ig2cq_prdy;
wire  [17:0] cq2eg_pd;
wire         cq2eg_pvld;
wire         cq2eg_prdy;

// EG signals
reg   [75:0] pdp_rdma2dp_pd_int;
reg         pdp_rdma2dp_valid_int;
reg         mcif_rd_rsp_ready_int;
reg         cvif_rd_rsp_ready_int;

reg   [31:0] nan_input_count;
reg   [31:0] inf_input_count;

wire        is_nan;
wire        is_inf;

wire        op_en_d0;
wire        op_en_d1;

//====================================================================
// Clock gating
//====================================================================
assign nvdla_op_gated_clk = nvdla_core_clk;

//====================================================================
// CSB interface for RDMA registers
//====================================================================
// RDMA register access is handled separately via reg_rdma module

//====================================================================
// Latch configuration at operation start
//====================================================================
assign cube_in_width_plus1 = reg2dp_cube_in_width + 13'd1;
assign cube_in_height_plus1 = reg2dp_cube_in_height + 13'd1;
assign cube_in_channel_plus1 = reg2dp_cube_in_channel + 13'd1;
assign split_num_plus1 = reg2dp_split_num + 8'd1;
assign kernel_width_plus1 = reg2dp_kernel_width + 4'd1;
assign kernel_stride_width_plus1 = reg2dp_kernel_stride_width + 4'd1;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        rdma_start <= 1'b0;
    end else begin
        if (reg2dp_op_en & (rdma_state == RDMA_STATE_IDLE)) begin
            rdma_start <= 1'b1;
        end else begin
            rdma_start <= 1'b0;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        cube_in_width <= 13'd0;
        cube_in_height <= 13'd0;
        cube_in_channel <= 13'd0;
        src_base_addr_low <= 27'd0;
        src_base_addr_high <= 32'd0;
        src_line_stride <= 27'd0;
        src_surface_stride <= 27'd0;
        split_num <= 8'd0;
        kernel_width <= 4'd0;
        kernel_stride_width <= 4'd0;
        pad_width <= 4'd0;
        partial_width_in_first <= 10'd0;
        partial_width_in_mid <= 10'd0;
        partial_width_in_last <= 10'd0;
    end else if (rdma_start) begin
        cube_in_width <= cube_in_width_plus1;
        cube_in_height <= cube_in_height_plus1;
        cube_in_channel <= cube_in_channel_plus1;
        src_base_addr_low <= reg2dp_src_base_addr_low;
        src_base_addr_high <= reg2dp_src_base_addr_high;
        src_line_stride <= reg2dp_src_line_stride;
        src_surface_stride <= reg2dp_src_surface_stride;
        split_num <= split_num_plus1;
        kernel_width <= kernel_width_plus1;
        kernel_stride_width <= kernel_stride_width_plus1;
        pad_width <= reg2dp_pad_width;
        partial_width_in_first <= reg2dp_partial_width_in_first;
        partial_width_in_mid <= reg2dp_partial_width_in_mid;
        partial_width_in_last <= reg2dp_partial_width_in_last;
    end
end

//====================================================================
// RDMA state machine
//====================================================================
always @(*) begin
    rdma_state_next = rdma_state;
    case (rdma_state)
        RDMA_STATE_IDLE: begin
            if (rdma_start)
                rdma_state_next = RDMA_STATE_RUNNING;
        end
        RDMA_STATE_RUNNING: begin
            if (rdma_done)
                rdma_state_next = RDMA_STATE_DONE;
        end
        RDMA_STATE_DONE: begin
            rdma_state_next = RDMA_STATE_IDLE;
        end
        default: rdma_state_next = RDMA_STATE_IDLE;
    endcase
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        rdma_state <= RDMA_STATE_IDLE;
    end else begin
        rdma_state <= rdma_state_next;
    end
end

//====================================================================
// Calculate element per atom based on data format
//====================================================================
assign element_per_atom = (reg2dp_input_data == DATA_FORMAT_INT8) ? 13'd32 :
                          (reg2dp_input_data == DATA_FORMAT_INT16) ? 13'd16 :
                          (reg2dp_input_data == DATA_FORMAT_FP16) ? 13'd16 : 13'd16;

//====================================================================
// Address generation and request generation
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        split_count <= 8'd0;
        atom_sent <= 13'd0;
    end else if (rdma_start) begin
        split_count <= 8'd0;
        atom_sent <= 13'd0;
    end else if (request_sent) begin
        if (atom_sent >= atom_count - 13'd1) begin
            atom_sent <= 13'd0;
            split_count <= split_count + 8'd1;
        end else begin
            atom_sent <= atom_sent + 13'd1;
        end
    end
end

// Calculate number of atoms to read for current split
wire [12:0] split_atom_count;
assign split_atom_count = (split_count == 8'd0) ? partial_width_in_first[12:0] :
                          (split_count == (split_num - 8'd1)) ? partial_width_in_last[12:0] :
                          partial_width_in_mid[12:0];

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        atom_count <= 13'd0;
    end else if (rdma_start) begin
        atom_count <= partial_width_in_first[12:0];
    end else if (request_sent && (atom_sent >= atom_count - 13'd1) && (split_count < split_num - 8'd1)) begin
        atom_count <= partial_width_in_mid[12:0];
    end else if (request_sent && (atom_sent >= atom_count - 13'd1) && (split_count == split_num - 8'd1)) begin
        atom_count <= partial_width_in_last[12:0];
    end
end

// Calculate current base address for split
wire [26:0] split_offset;
wire [26:0] current_split_base;
assign split_offset = (split_count == 8'd0) ? 27'd0 :
                      (partial_width_in_first + (split_count - 8'd1) * partial_width_in_mid -
                       (kernel_width - kernel_stride_width)) * {26'd0, ATOM_CUBE_SIZE};

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        current_base_addr <= 27'd0;
    end else if (rdma_start) begin
        current_base_addr <= {src_base_addr_high[26:0], src_base_addr_low} >> 5;
    end else if (request_sent && (atom_sent >= atom_count - 13'd1)) begin
        current_base_addr <= current_base_addr + split_offset;
    end
end

assign atom_addr = current_base_addr + atom_sent * {20'd0, ATOM_CUBE_SIZE};

//====================================================================
// Generate read requests
//====================================================================
reg   [78:0] pdp2mcif_rd_req_pd_int;
reg         pdp2mcif_rd_req_valid_int;
reg   [78:0] pdp2cvif_rd_req_pd_int;
reg         pdp2cvif_rd_req_valid_int;

assign pdp2mcif_rd_req_valid = pdp2mcif_rd_req_valid_int;
assign pdp2cvif_rd_req_valid = pdp2cvif_rd_req_valid_int;
assign pdp2mcif_rd_req_pd = pdp2mcif_rd_req_pd_int;
assign pdp2cvif_rd_req_pd = pdp2cvif_rd_req_pd_int;

assign is_mcif = (reg2dp_src_ram_type == 1'd0);
assign is_cvif = (reg2dp_src_ram_type == 1'd1);

assign request_sent = is_mcif ? (pdp2mcif_rd_req_valid & pdp2mcif_rd_req_ready) :
                     (pdp2cvif_rd_req_valid & pdp2cvif_rd_req_ready);

always @(*) begin
    if (is_mcif) begin
        pdp2mcif_rd_req_pd_int = {1'd0, atom_addr, 6'd0, atom_count - 13'd1};
        pdp2cvif_rd_req_pd_int = 78'd0;
    end else begin
        pdp2mcif_rd_req_pd_int = 78'd0;
        pdp2cvif_rd_req_pd_int = {1'd0, atom_addr, 6'd0, atom_count - 13'd1};
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pdp2mcif_rd_req_valid_int <= 1'b0;
        pdp2cvif_rd_req_valid_int <= 1'b0;
    end else begin
        if (rdma_state == RDMA_STATE_RUNNING) begin
            if (is_mcif & (atom_sent < atom_count)) begin
                pdp2mcif_rd_req_valid_int <= 1'b1;
            end else begin
                pdp2mcif_rd_req_valid_int <= 1'b0;
            end
            if (is_cvif & (atom_sent < atom_count)) begin
                pdp2cvif_rd_req_valid_int <= 1'b1;
            end else begin
                pdp2cvif_rd_req_valid_int <= 1'b0;
            end
        end else begin
            pdp2mcif_rd_req_valid_int <= 1'b0;
            pdp2cvif_rd_req_valid_int <= 1'b0;
        end
    end
end

//====================================================================
// Done detection
//====================================================================
always @(*) begin
    rdma_done = (rdma_state == RDMA_STATE_RUNNING) &
                (split_count >= split_num) &
                (atom_sent >= atom_count - 13'd1);
end

assign rdma2wdma_done = (rdma_state == RDMA_STATE_DONE);
assign dp2reg_done = rdma_done;

//====================================================================
// Read response processing
//====================================================================
assign mcif2pdp_rd_rsp_ready = mcif_rd_rsp_ready_int;
assign cvif2pdp_rd_rsp_ready = cvif_rd_rsp_ready_int;

always @(*) begin
    if (is_mcif) begin
        mcif_rd_rsp_ready_int = pdp_rdma2dp_ready;
        cvif_rd_rsp_ready_int = 1'b0;
    end else begin
        mcif_rd_rsp_ready_int = 1'b0;
        cvif_rd_rsp_ready_int = pdp_rdma2dp_ready;
    end
end

// Process incoming read data
wire [511:0] rsp_data;
wire [1:0] rsp_mask;

assign rsp_data = is_mcif ? mcif2pdp_rd_rsp_pd[511:0] : cvif2pdp_rd_rsp_pd[511:0];
assign rsp_mask = is_mcif ? mcif2pdp_rd_rsp_pd[513:512] : cvif2pdp_rd_rsp_pd[513:512];

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pdp_rdma2dp_valid_int <= 1'b0;
        pdp_rdma2dp_pd_int <= 76'd0;
    end else begin
        if ((is_mcif & mcif2pdp_rd_rsp_valid) | (is_cvif & cvif2pdp_rd_rsp_valid)) begin
            if (pdp_rdma2dp_ready) begin
                pdp_rdma2dp_valid_int <= 1'b1;
                pdp_rdma2dp_pd_int <= {rsp_mask, 2'd0, atom_addr, rsp_data[511:440]};
            end
        end else begin
            pdp_rdma2dp_valid_int <= 1'b0;
        end
    end
end

assign pdp_rdma2dp_valid = pdp_rdma2dp_valid_int;
assign pdp_rdma2dp_pd = pdp_rdma2dp_pd_int;

// NaN/Inf detection for FP16
generate
    genvar i;
    for (i = 0; i < 16; i = i + 1) begin : nan_inf_check
        assign is_nan = rsp_data[i*32 + 30: i*32 + 25] == 6'b111111;
        assign is_inf = (rsp_data[i*32 + 30: i*32 + 25] == 6'b111110) &
                        (rsp_data[i*32 + 23: i*32 + 0] == 24'd0);
    end
endgenerate

//====================================================================
// Performance counters
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        perf_read_stall_count <= 32'd0;
    end else begin
        if ((is_mcif & ~pdp2mcif_rd_req_ready & pdp2mcif_rd_req_valid) |
            (is_cvif & ~pdp2cvif_rd_req_ready & pdp2cvif_rd_req_valid)) begin
            perf_read_stall_count <= perf_read_stall_count + 32'd1;
        end
    end
end

assign dp2reg_d0_perf_read_stall = perf_read_stall_count;
assign dp2reg_d1_perf_read_stall = perf_read_stall_count;

//====================================================================
// CDT latency fifo pop
//====================================================================
assign pdp2mcif_rd_cdt_lat_fifo_pop = pdp2mcif_rd_req_valid & pdp2mcif_rd_req_ready;
assign pdp2cvif_rd_cdt_lat_fifo_pop = pdp2cvif_rd_req_valid & pdp2cvif_rd_req_ready;

endmodule // NV_NVDLA_PDP_rdma_new