// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_wdma_new.v

// Description:
// PDP Write DMA - writes output data to external memory (MCIF/CVIF)

module NV_NVDLA_PDP_wdma_new (
    nvdla_core_clk                  //|< i
  , nvdla_core_rstn                //|< i
  // Register interface
  , reg2dp_op_en                  //|< i
  , reg2dp_cube_out_width         //|< i
  , reg2dp_cube_out_height        //|< i
  , reg2dp_cube_out_channel       //|< i
  , reg2dp_dst_base_addr_low     //|< i
  , reg2dp_dst_base_addr_high    //|< i
  , reg2dp_dst_line_stride        //|< i
  , reg2dp_dst_surface_stride     //|< i
  , reg2dp_dst_ram_type           //|< i
  , reg2dp_input_data             //|< i
  , reg2dp_split_num              //|< i
  , reg2dp_partial_width_out_first //|< i
  , reg2dp_partial_width_out_mid   //|< i
  , reg2dp_partial_width_out_last  //|< i
  , reg2dp_dma_en                 //|< i
  // Input from pooling core
  , dp2pdp_valid                 //|< i
  , dp2pdp_ready                 //|> o
  , dp2pdp_pd                    //|< i
  // MCIF write interface
  , pdp2mcif_wr_req_valid        //|> o
  , pdp2mcif_wr_req_ready        //|< i
  , pdp2mcif_wr_req_pd           //|> o
  , pdp2mcif_wr_data_valid       //|> o
  , pdp2mcif_wr_data_ready       //|< i
  , pdp2mcif_wr_data_pd          //|> o
  // CVIF write interface
  , pdp2cvif_wr_req_valid        //|> o
  , pdp2cvif_wr_req_ready        //|< i
  , pdp2cvif_wr_req_pd           //|> o
  , pdp2cvif_wr_data_valid       //|> o
  , pdp2cvif_wr_data_ready       //|< i
  , pdp2cvif_wr_data_pd          //|> o
  // Write response
  , mcif2pdp_wr_rsp              //|< i
  , cvif2pdp_wr_rsp              //|< i
  // Status
  , dp2reg_done                   //|> o
  , dp2reg_d0_perf_write_stall   //|> o
  , dp2reg_d1_perf_write_stall   //|> o
  , wdma2pdp_done                //|> o
  , pwrbus_ram_pd                 //|< i
);

//====================================================================
// Parameters
//====================================================================
localparam WDMA_STATE_IDLE = 2'd0;
localparam WDMA_STATE_RUNNING = 2'd1;
localparam WDMA_STATE_DONE = 2'd2;

// ATOM_CUBE_SIZE = 32 bytes
localparam ATOM_CUBE_SIZE = 6'd32;

// Data format constants
localparam DATA_FORMAT_INT8 = 2'd0;
localparam DATA_FORMAT_INT16 = 2'd1;
localparam DATA_FORMAT_FP16 = 2'd2;

//====================================================================
// Ports
//====================================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// Register interface
input        reg2dp_op_en;
input  [12:0] reg2dp_cube_out_width;
input  [12:0] reg2dp_cube_out_height;
input  [12:0] reg2dp_cube_out_channel;
input  [26:0] reg2dp_dst_base_addr_low;
input  [31:0] reg2dp_dst_base_addr_high;
input  [26:0] reg2dp_dst_line_stride;
input  [26:0] reg2dp_dst_surface_stride;
input        reg2dp_dst_ram_type;
input  [1:0] reg2dp_input_data;
input  [7:0] reg2dp_split_num;
input  [9:0] reg2dp_partial_width_out_first;
input  [9:0] reg2dp_partial_width_out_mid;
input  [9:0] reg2dp_partial_width_out_last;
input        reg2dp_dma_en;

// Input from pooling core
input        dp2pdp_valid;
output       dp2pdp_ready;
input  [63:0] dp2pdp_pd;

// MCIF write interface
output       pdp2mcif_wr_req_valid;
input        pdp2mcif_wr_req_ready;
output [78:0] pdp2mcif_wr_req_pd;
output       pdp2mcif_wr_data_valid;
input        pdp2mcif_wr_data_ready;
output [511:0] pdp2mcif_wr_data_pd;

// CVIF write interface
output       pdp2cvif_wr_req_valid;
input        pdp2cvif_wr_req_ready;
output [78:0] pdp2cvif_wr_req_pd;
output       pdp2cvif_wr_data_valid;
input        pdp2cvif_wr_data_ready;
output [511:0] pdp2cvif_wr_data_pd;

// Write response
input        mcif2pdp_wr_rsp;
input        cvif2pdp_wr_rsp;

// Status
output       dp2reg_done;
output [31:0] dp2reg_d0_perf_write_stall;
output [31:0] dp2reg_d1_perf_write_stall;
output       wdma2pdp_done;
input  [31:0] pwrbus_ram_pd;

//====================================================================
// Internal signals
//====================================================================
reg   [1:0] wdma_state;
reg   [1:0] wdma_state_next;

reg   [12:0] cube_out_width;
reg   [12:0] cube_out_height;
reg   [12:0] cube_out_channel;
reg   [26:0] dst_base_addr_low;
reg   [31:0] dst_base_addr_high;
reg   [26:0] dst_line_stride;
reg   [26:0] dst_surface_stride;
reg   [7:0] split_num;
reg   [9:0] partial_width_out_first;
reg   [9:0] partial_width_out_mid;
reg   [9:0] partial_width_out_last;

reg   [7:0] split_count;
reg   [12:0] atom_sent;
reg   [12:0] atom_count;
reg   [26:0] current_base_addr;

wire  [12:0] cube_out_width_plus1;
wire  [12:0] cube_out_height_plus1;
wire  [12:0] cube_out_channel_plus1;
wire  [7:0] split_num_plus1;

wire  [12:0] element_per_atom;
wire  [26:0] atom_addr;
wire  [7:0] atom_size;

wire        is_mcif;
wire        is_cvif;

reg         wdma_start;
reg         wdma_done;
reg         ack_received;

reg   [31:0] perf_write_stall_count;

reg   [63:0] dp2pdp_data_buf;
reg         dp2pdp_valid_int;
reg         dp2pdp_ready_int;

reg   [511:0] wr_data_buf;
reg         wr_data_valid_int;
reg   [7:0] wr_data_count;

reg   [511:0] pdp2mcif_wr_data_pd_int;
reg         pdp2mcif_wr_data_valid_int;
reg   [511:0] pdp2cvif_wr_data_pd_int;
reg         pdp2cvif_wr_data_valid_int;

wire  [511:0] wdma2mcif_data;
wire  [511:0] wdma2cvif_data;

//====================================================================
// Input handshake with pooling core
//====================================================================
assign dp2pdp_ready = dp2pdp_ready_int;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        dp2pdp_valid_int <= 1'b0;
        dp2pdp_data_buf <= 64'd0;
    end else begin
        if (dp2pdp_valid & dp2pdp_ready) begin
            dp2pdp_valid_int <= 1'b0;
        end else if (dp2pdp_valid & dp2pdp_ready_int) begin
            dp2pdp_valid_int <= 1'b1;
            dp2pdp_data_buf <= dp2pdp_pd;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        dp2pdp_ready_int <= 1'b0;
    end else begin
        if (wdma_state == WDMA_STATE_IDLE) begin
            dp2pdp_ready_int <= 1'b0;
        end else if (wdma_state == WDMA_STATE_RUNNING) begin
            if (is_mcif) begin
                dp2pdp_ready_int <= pdp2mcif_wr_data_ready | ~wr_data_valid_int;
            end else begin
                dp2pdp_ready_int <= pdp2cvif_wr_data_ready | ~wr_data_valid_int;
            end
        end else begin
            dp2pdp_ready_int <= 1'b0;
        end
    end
end

//====================================================================
// Latch configuration at operation start
//====================================================================
assign cube_out_width_plus1 = reg2dp_cube_out_width + 13'd1;
assign cube_out_height_plus1 = reg2dp_cube_out_height + 13'd1;
assign cube_out_channel_plus1 = reg2dp_cube_out_channel + 13'd1;
assign split_num_plus1 = reg2dp_split_num + 8'd1;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        wdma_start <= 1'b0;
    end else begin
        if (reg2dp_op_en & (wdma_state == WDMA_STATE_IDLE)) begin
            wdma_start <= 1'b1;
        end else begin
            wdma_start <= 1'b0;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        cube_out_width <= 13'd0;
        cube_out_height <= 13'd0;
        cube_out_channel <= 13'd0;
        dst_base_addr_low <= 27'd0;
        dst_base_addr_high <= 32'd0;
        dst_line_stride <= 27'd0;
        dst_surface_stride <= 27'd0;
        split_num <= 8'd0;
        partial_width_out_first <= 10'd0;
        partial_width_out_mid <= 10'd0;
        partial_width_out_last <= 10'd0;
    end else if (wdma_start) begin
        cube_out_width <= cube_out_width_plus1;
        cube_out_height <= cube_out_height_plus1;
        cube_out_channel <= cube_out_channel_plus1;
        dst_base_addr_low <= reg2dp_dst_base_addr_low;
        dst_base_addr_high <= reg2dp_dst_base_addr_high;
        dst_line_stride <= reg2dp_dst_line_stride;
        dst_surface_stride <= reg2dp_dst_surface_stride;
        split_num <= split_num_plus1;
        partial_width_out_first <= reg2dp_partial_width_out_first;
        partial_width_out_mid <= reg2dp_partial_width_out_mid;
        partial_width_out_last <= reg2dp_partial_width_out_last;
    end
end

//====================================================================
// WDMA state machine
//====================================================================
always @(*) begin
    wdma_state_next = wdma_state;
    case (wdma_state)
        WDMA_STATE_IDLE: begin
            if (wdma_start)
                wdma_state_next = WDMA_STATE_RUNNING;
        end
        WDMA_STATE_RUNNING: begin
            if (wdma_done)
                wdma_state_next = WDMA_STATE_DONE;
        end
        WDMA_STATE_DONE: begin
            if (ack_received)
                wdma_state_next = WDMA_STATE_IDLE;
        end
        default: wdma_state_next = WDMA_STATE_IDLE;
    endcase
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        wdma_state <= WDMA_STATE_IDLE;
    end else begin
        wdma_state <= wdma_state_next;
    end
end

//====================================================================
// Calculate element per atom based on data format
//====================================================================
assign element_per_atom = (reg2dp_input_data == DATA_FORMAT_INT8) ? 13'd32 :
                          (reg2dp_input_data == DATA_FORMAT_INT16) ? 13'd16 :
                          (reg2dp_input_data == DATA_FORMAT_FP16) ? 13'd16 : 13'd16;

//====================================================================
// Atom count and address generation
//====================================================================
wire [12:0] split_atom_count;
assign split_atom_count = (split_count == 8'd0) ? partial_width_out_first[12:0] :
                          (split_count == (split_num - 8'd1)) ? partial_width_out_last[12:0] :
                          partial_width_out_mid[12:0];

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        split_count <= 8'd0;
        atom_sent <= 13'd0;
        atom_count <= 13'd0;
    end else if (wdma_start) begin
        split_count <= 8'd0;
        atom_sent <= 13'd0;
        atom_count <= partial_width_out_first[12:0];
    end else if (wr_data_valid_int && (is_mcif ? pdp2mcif_wr_data_ready : pdp2cvif_wr_data_ready)) begin
        if (atom_sent >= atom_count - 13'd1) begin
            atom_sent <= 13'd0;
            if (split_count < split_num - 8'd1) begin
                split_count <= split_count + 8'd1;
                atom_count <= partial_width_out_mid[12:0];
            end else begin
                split_count <= split_count + 8'd1;
                atom_count <= partial_width_out_last[12:0];
            end
        end else begin
            atom_sent <= atom_sent + 13'd1;
        end
    end
end

// Calculate current base address for split
wire [26:0] split_offset;
assign split_offset = (split_count == 8'd0) ? 27'd0 :
                      (partial_width_out_first + (split_count - 8'd1) * partial_width_out_mid) *
                       {20'd0, ATOM_CUBE_SIZE};

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        current_base_addr <= 27'd0;
    end else if (wdma_start) begin
        current_base_addr <= {dst_base_addr_high[26:0], dst_base_addr_low} >> 5;
    end else if (wr_data_valid_int && (is_mcif ? pdp2mcif_wr_data_ready : pdp2cvif_wr_data_ready)) begin
        if (atom_sent >= atom_count - 13'd1) begin
            current_base_addr <= current_base_addr + split_offset;
        end
    end
end

assign atom_addr = current_base_addr + atom_sent * {20'd0, ATOM_CUBE_SIZE};

//====================================================================
// RAM type selection
//====================================================================
assign is_mcif = (reg2dp_dst_ram_type == 1'd0);
assign is_cvif = (reg2dp_dst_ram_type == 1'd1);

//====================================================================
// Write request generation
//====================================================================
reg   [78:0] pdp2mcif_wr_req_pd_int;
reg         pdp2mcif_wr_req_valid_int;
reg   [78:0] pdp2cvif_wr_req_pd_int;
reg         pdp2cvif_wr_req_valid_int;

assign pdp2mcif_wr_req_valid = pdp2mcif_wr_req_valid_int;
assign pdp2cvif_wr_req_valid = pdp2cvif_wr_req_valid_int;
assign pdp2mcif_wr_req_pd = pdp2mcif_wr_req_pd_int;
assign pdp2cvif_wr_req_pd = pdp2cvif_wr_req_pd_int;

always @(*) begin
    if (is_mcif) begin
        pdp2mcif_wr_req_pd_int = {1'd0, atom_addr, 6'd0, atom_count - 13'd1};
        pdp2cvif_wr_req_pd_int = 78'd0;
    end else begin
        pdp2mcif_wr_req_pd_int = 78'd0;
        pdp2cvif_wr_req_pd_int = {1'd0, atom_addr, 6'd0, atom_count - 13'd1};
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pdp2mcif_wr_req_valid_int <= 1'b0;
        pdp2cvif_wr_req_valid_int <= 1'b0;
    end else begin
        if (wdma_state == WDMA_STATE_RUNNING) begin
            if (is_mcif & (atom_sent < atom_count)) begin
                pdp2mcif_wr_req_valid_int <= 1'b1;
            end else begin
                pdp2mcif_wr_req_valid_int <= 1'b0;
            end
            if (is_cvif & (atom_sent < atom_count)) begin
                pdp2cvif_wr_req_valid_int <= 1'b1;
            end else begin
                pdp2cvif_wr_req_valid_int <= 1'b0;
            end
        end else begin
            pdp2mcif_wr_req_valid_int <= 1'b0;
            pdp2cvif_wr_req_valid_int <= 1'b0;
        end
    end
end

//====================================================================
// Write data aggregation
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        wr_data_valid_int <= 1'b0;
        wr_data_count <= 8'd0;
        wr_data_buf <= 512'd0;
    end else begin
        if (wdma_state == WDMA_STATE_IDLE) begin
            wr_data_valid_int <= 1'b0;
            wr_data_count <= 8'd0;
        end else if (dp2pdp_valid & dp2pdp_ready) begin
            if (wr_data_count == 8'd0) begin
                wr_data_buf[63:0] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd1) begin
                wr_data_buf[127:64] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd2) begin
                wr_data_buf[191:128] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd3) begin
                wr_data_buf[255:192] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd4) begin
                wr_data_buf[319:256] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd5) begin
                wr_data_buf[383:320] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd6) begin
                wr_data_buf[447:384] <= dp2pdp_pd;
                wr_data_count <= wr_data_count + 8'd1;
            end else if (wr_data_count == 8'd7) begin
                wr_data_buf[511:448] <= dp2pdp_pd;
                wr_data_count <= 8'd0;
                wr_data_valid_int <= 1'b1;
            end
        end else if (wr_data_valid_int) begin
            if (is_mcif & pdp2mcif_wr_data_ready) begin
                wr_data_valid_int <= 1'b0;
            end else if (is_cvif & pdp2cvif_wr_data_ready) begin
                wr_data_valid_int <= 1'b0;
            end
        end
    end
end

assign pdp2mcif_wr_data_pd = wr_data_buf;
assign pdp2cvif_wr_data_pd = wr_data_buf;
assign pdp2mcif_wr_data_valid = wr_data_valid_int & is_mcif;
assign pdp2cvif_wr_data_valid = wr_data_valid_int & is_cvif;

//====================================================================
// Done detection and acknowledgment
//====================================================================
always @(*) begin
    wdma_done = (wdma_state == WDMA_STATE_RUNNING) &
                (split_count >= split_num) &
                (atom_sent >= atom_count - 13'd1) &
                (wr_data_count == 8'd0);
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        ack_received <= 1'b0;
    end else begin
        if (wdma_state == WDMA_STATE_DONE) begin
            if ((is_mcif & mcif2pdp_wr_rsp) | (is_cvif & cvif2pdp_wr_rsp)) begin
                ack_received <= 1'b1;
            end
        end else begin
            ack_received <= 1'b0;
        end
    end
end

assign wdma2pdp_done = (wdma_state == WDMA_STATE_DONE) & ack_received;
assign dp2reg_done = wdma2pdp_done;

//====================================================================
// Performance counters
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        perf_write_stall_count <= 32'd0;
    end else begin
        if ((is_mcif & ~pdp2mcif_wr_req_ready & pdp2mcif_wr_req_valid) |
            (is_cvif & ~pdp2cvif_wr_req_ready & pdp2cvif_wr_req_valid) |
            (is_mcif & ~pdp2mcif_wr_data_ready & wr_data_valid_int) |
            (is_cvif & ~pdp2cvif_wr_data_ready & wr_data_valid_int)) begin
            perf_write_stall_count <= perf_write_stall_count + 32'd1;
        end
    end
end

assign dp2reg_d0_perf_write_stall = perf_write_stall_count;
assign dp2reg_d1_perf_write_stall = perf_write_stall_count;

endmodule // NV_NVDLA_PDP_wdma_new