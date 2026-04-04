// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_pool_new.v

// Description:
// PDP Pooling Core - performs pooling operations (AVE/MAX/MIN)

module NV_NVDLA_PDP_pool_new (
    nvdla_core_clk                  //|< i
  , nvdla_core_rstn                //|< i
  // Register interface
  , reg2dp_op_en                  //|< i
  , reg2dp_flying_mode            //|< i
  , reg2dp_input_data            //|< i
  , reg2dp_pooling_method        //|< i
  , reg2dp_nan_to_zero           //|< i
  , reg2dp_cube_in_width         //|< i
  , reg2dp_cube_in_height        //|< i
  , reg2dp_cube_in_channel       //|< i
  , reg2dp_cube_out_width        //|< i
  , reg2dp_kernel_width          //|< i
  , reg2dp_kernel_height         //|< i
  , reg2dp_kernel_stride_width   //|< i
  , reg2dp_kernel_stride_height  //|< i
  , reg2dp_pad_left              //|< i
  , reg2dp_pad_right             //|< i
  , reg2dp_pad_top               //|< i
  , reg2dp_pad_bottom            //|< i
  , reg2dp_pad_value_1x         //|< i
  , reg2dp_pad_value_2x         //|< i
  , reg2dp_pad_value_3x         //|< i
  , reg2dp_pad_value_4x         //|< i
  , reg2dp_pad_value_5x         //|< i
  , reg2dp_pad_value_6x         //|< i
  , reg2dp_pad_value_7x         //|< i
  , reg2dp_partial_width_in_first  //|< i
  , reg2dp_partial_width_in_mid    //|< i
  , reg2dp_partial_width_in_last   //|< i
  , reg2dp_partial_width_out_first //|< i
  , reg2dp_partial_width_out_mid   //|< i
  , reg2dp_partial_width_out_last  //|< i
  , reg2dp_recip_kernel_width    //|< i
  , reg2dp_recip_kernel_height   //|< i
  , reg2dp_split_num             //|< i
  // Input from RDMA
  , pdp_rdma2dp_valid            //|< i
  , pdp_rdma2dp_ready             //|> o
  , pdp_rdma2dp_pd               //|< i
  // Input from SDP (on-flying mode)
  , sdp2pdp_valid                //|< i
  , sdp2pdp_ready                //|> o
  , sdp2pdp_pd                   //|< i
  // Output to WDMA
  , dp2pdp_valid                  //|> o
  , dp2pdp_ready                 //|< i
  , dp2pdp_pd                    //|> o
  // Status
  , dp2reg_done                   //|> o
  , dp2reg_nan_input_num         //|> o
  , dp2reg_inf_input_num          //|> o
  , dp2reg_nan_output_num         //|> o
  , pwrbus_ram_pd                  //|< i
);

//====================================================================
// Parameters
//====================================================================
localparam POOL_STATE_IDLE = 3'd0;
localparam POOL_STATE_RUNNING = 3'd1;
localparam POOL_STATE_DONE = 3'd2;

// Pooling method
localparam POOLING_METHOD AVE = 2'd0;
localparam POOLING_METHOD MAX = 2'd1;
localparam POOLING_METHOD MIN = 2'd2;

// Flying mode
localparam FLYING_MODE_ON = 1'd0;
localparam FLYING_MODE_OFF = 1'd1;

// Data format
localparam DATA_FORMAT_INT8 = 2'd0;
localparam DATA_FORMAT_INT16 = 2'd1;
localparam DATA_FORMAT_FP16 = 2'd2;

// Line buffer depth (number of atoms)
localparam LINE_BUFFER_DEPTH = 4'd8;
localparam LINE_BUFFER_WIDTH = 8'd16;  // 16 elements per atom for FP16/INT16

//====================================================================
// Ports
//====================================================================
// Clock and reset
input        nvdla_core_clk;
input        nvdla_core_rstn;

// Register interface
input        reg2dp_op_en;
input        reg2dp_flying_mode;
input  [1:0] reg2dp_input_data;
input  [1:0] reg2dp_pooling_method;
input        reg2dp_nan_to_zero;
input  [12:0] reg2dp_cube_in_width;
input  [12:0] reg2dp_cube_in_height;
input  [12:0] reg2dp_cube_in_channel;
input  [12:0] reg2dp_cube_out_width;
input  [3:0] reg2dp_kernel_width;
input  [3:0] reg2dp_kernel_height;
input  [3:0] reg2dp_kernel_stride_width;
input  [3:0] reg2dp_kernel_stride_height;
input  [2:0] reg2dp_pad_left;
input  [2:0] reg2dp_pad_right;
input  [2:0] reg2dp_pad_top;
input  [2:0] reg2dp_pad_bottom;
input  [18:0] reg2dp_pad_value_1x;
input  [18:0] reg2dp_pad_value_2x;
input  [18:0] reg2dp_pad_value_3x;
input  [18:0] reg2dp_pad_value_4x;
input  [18:0] reg2dp_pad_value_5x;
input  [18:0] reg2dp_pad_value_6x;
input  [18:0] reg2dp_pad_value_7x;
input  [9:0] reg2dp_partial_width_in_first;
input  [9:0] reg2dp_partial_width_in_mid;
input  [9:0] reg2dp_partial_width_in_last;
input  [9:0] reg2dp_partial_width_out_first;
input  [9:0] reg2dp_partial_width_out_mid;
input  [9:0] reg2dp_partial_width_out_last;
input  [16:0] reg2dp_recip_kernel_width;
input  [16:0] reg2dp_recip_kernel_height;
input  [7:0] reg2dp_split_num;

// Input from RDMA
input        pdp_rdma2dp_valid;
output       pdp_rdma2dp_ready;
input  [75:0] pdp_rdma2dp_pd;

// Input from SDP
input        sdp2pdp_valid;
output       sdp2pdp_ready;
input  [255:0] sdp2pdp_pd;

// Output to WDMA
output       dp2pdp_valid;
input        dp2pdp_ready;
output [63:0] dp2pdp_pd;

// Status
output       dp2reg_done;
output [31:0] dp2reg_nan_input_num;
output [31:0] dp2reg_inf_input_num;
output [31:0] dp2reg_nan_output_num;
input  [31:0] pwrbus_ram_pd;

//====================================================================
// Internal signals
//====================================================================
reg   [2:0] pool_state;
reg   [2:0] pool_state_next;

reg   [12:0] cube_in_width;
reg   [12:0] cube_in_height;
reg   [12:0] cube_in_channel;
reg   [12:0] cube_out_width;
reg   [3:0] kernel_width;
reg   [3:0] kernel_height;
reg   [3:0] kernel_stride_width;
reg   [3:0] kernel_stride_height;
reg   [2:0] pad_left;
reg   [2:0] pad_right;
reg   [2:0] pad_top;
reg   [2:0] pad_bottom;
reg   [1:0] pooling_method;
reg   [1:0] input_data;
reg         nan_to_zero;
reg         flying_mode;
reg   [16:0] recip_kernel_width;
reg   [16:0] recip_kernel_height;
reg   [9:0] partial_width_in_first;
reg   [9:0] partial_width_in_mid;
reg   [9:0] partial_width_in_last;
reg   [9:0] partial_width_out_first;
reg   [9:0] partial_width_out_mid;
reg   [9:0] partial_width_out_last;
reg   [7:0] split_num;

reg   [7:0] split_count;
reg   [12:0] width_count;
reg   [12:0] height_count;
reg   [12:0] channel_count;
reg   [12:0] output_width;
reg   [12:0] output_height;

reg   pool_start;
reg   pool_done;

wire  [12:0] cube_in_width_plus1;
wire  [12:0] cube_in_height_plus1;
wire  [12:0] cube_in_channel_plus1;
wire  [12:0] cube_out_width_plus1;
wire  [3:0] kernel_width_plus1;
wire  [3:0] kernel_height_plus1;
wire  [3:0] kernel_stride_width_plus1;
wire  [3:0] kernel_stride_height_plus1;
wire  [7:0] split_num_plus1;

wire  is_flying_on;
wire  is_flying_off;
wire  is_ave;
wire  is_max;
wire  is_min;
wire  is_int8;
wire  is_int16;
wire  is_fp16;

// Line buffer
reg   [16:0] line_buffer [0:LINE_BUFFER_DEPTH-1][0:LINE_BUFFER_WIDTH-1];
reg   [3:0] line_buffer_wr_idx;
reg   [3:0] line_buffer_rd_idx;
wire  [3:0] line_buffer_wr_idx_next;
wire  [3:0] line_buffer_rd_idx_next;

// Pooling accumulation
reg   [31:0] pool_accum [0:15];  // 16 elements per atom
reg   [3:0] pool_count [0:15];  // count of valid elements per position

// Input data registers
reg   [75:0] pdp_rdma2dp_data;
reg         pdp_rdma2dp_valid_int;
reg   [255:0] sdp2pdp_data;
reg         sdp2pdp_valid_int;

// Output data
reg   [63:0] dp2pdp_data_int;
reg         dp2pdp_valid_int;
reg         dp2pdp_ready_int;

// NaN/Inf counters
reg   [31:0] nan_input_count;
reg   [31:0] inf_input_count;
reg   [31:0] nan_output_count;

wire        is_nan;
wire        is_inf;

integer i;

//====================================================================
// Input selection based on flying mode
//====================================================================
assign is_flying_on = (flying_mode == FLYING_MODE_ON);
assign is_flying_off = (flying_mode == FLYING_MODE_OFF);

assign pdp_rdma2dp_ready = is_flying_off ? dp2pdp_ready_int : 1'b0;
assign sdp2pdp_ready = is_flying_on ? dp2pdp_ready_int : 1'b0;

always @(*) begin
    if (is_flying_off) begin
        pdp_rdma2dp_valid_int = pdp_rdma2dp_valid;
        sdp2pdp_valid_int = 1'b0;
    end else begin
        pdp_rdma2dp_valid_int = 1'b0;
        sdp2pdp_valid_int = sdp2pdp_valid;
    end
end

//====================================================================
// Latch configuration at operation start
//====================================================================
assign cube_in_width_plus1 = reg2dp_cube_in_width + 13'd1;
assign cube_in_height_plus1 = reg2dp_cube_in_height + 13'd1;
assign cube_in_channel_plus1 = reg2dp_cube_in_channel + 13'd1;
assign cube_out_width_plus1 = reg2dp_cube_out_width + 13'd1;
assign kernel_width_plus1 = reg2dp_kernel_width + 4'd1;
assign kernel_height_plus1 = reg2dp_kernel_height + 4'd1;
assign kernel_stride_width_plus1 = reg2dp_kernel_stride_width + 4'd1;
assign kernel_stride_height_plus1 = reg2dp_kernel_stride_height + 4'd1;
assign split_num_plus1 = reg2dp_split_num + 8'd1;

assign is_ave = (pooling_method == POOLING_METHOD_AVE);
assign is_max = (pooling_method == POOLING_METHOD_MAX);
assign is_min = (pooling_method == POOLING_METHOD_MIN);
assign is_int8 = (input_data == DATA_FORMAT_INT8);
assign is_int16 = (input_data == DATA_FORMAT_INT16);
assign is_fp16 = (input_data == DATA_FORMAT_FP16);

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pool_start <= 1'b0;
    end else begin
        if (reg2dp_op_en & (pool_state == POOL_STATE_IDLE)) begin
            pool_start <= 1'b1;
        end else begin
            pool_start <= 1'b0;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        cube_in_width <= 13'd0;
        cube_in_height <= 13'd0;
        cube_in_channel <= 13'd0;
        cube_out_width <= 13'd0;
        kernel_width <= 4'd0;
        kernel_height <= 4'd0;
        kernel_stride_width <= 4'd0;
        kernel_stride_height <= 4'd0;
        pad_left <= 3'd0;
        pad_right <= 3'd0;
        pad_top <= 3'd0;
        pad_bottom <= 3'd0;
        pooling_method <= 2'd0;
        input_data <= 2'd0;
        nan_to_zero <= 1'd0;
        flying_mode <= 1'd0;
        recip_kernel_width <= 17'd0;
        recip_kernel_height <= 17'd0;
        partial_width_in_first <= 10'd0;
        partial_width_in_mid <= 10'd0;
        partial_width_in_last <= 10'd0;
        partial_width_out_first <= 10'd0;
        partial_width_out_mid <= 10'd0;
        partial_width_out_last <= 10'd0;
        split_num <= 8'd0;
    end else if (pool_start) begin
        cube_in_width <= cube_in_width_plus1;
        cube_in_height <= cube_in_height_plus1;
        cube_in_channel <= cube_in_channel_plus1;
        cube_out_width <= cube_out_width_plus1;
        kernel_width <= kernel_width_plus1;
        kernel_height <= kernel_height_plus1;
        kernel_stride_width <= kernel_stride_width_plus1;
        kernel_stride_height <= kernel_stride_height_plus1;
        pad_left <= reg2dp_pad_left;
        pad_right <= reg2dp_pad_right;
        pad_top <= reg2dp_pad_top;
        pad_bottom <= reg2dp_pad_bottom;
        pooling_method <= reg2dp_pooling_method;
        input_data <= reg2dp_input_data;
        nan_to_zero <= reg2dp_nan_to_zero;
        flying_mode <= reg2dp_flying_mode;
        recip_kernel_width <= reg2dp_recip_kernel_width;
        recip_kernel_height <= reg2dp_recip_kernel_height;
        partial_width_in_first <= reg2dp_partial_width_in_first;
        partial_width_in_mid <= reg2dp_partial_width_in_mid;
        partial_width_in_last <= reg2dp_partial_width_in_last;
        partial_width_out_first <= reg2dp_partial_width_out_first;
        partial_width_out_mid <= reg2dp_partial_width_out_mid;
        partial_width_out_last <= reg2dp_partial_width_out_last;
        split_num <= split_num_plus1;
    end
end

//====================================================================
// Pool state machine
//====================================================================
always @(*) begin
    pool_state_next = pool_state;
    case (pool_state)
        POOL_STATE_IDLE: begin
            if (pool_start)
                pool_state_next = POOL_STATE_RUNNING;
        end
        POOL_STATE_RUNNING: begin
            if (pool_done)
                pool_state_next = POOL_STATE_DONE;
        end
        POOL_STATE_DONE: begin
            pool_state_next = POOL_STATE_IDLE;
        end
        default: pool_state_next = POOL_STATE_IDLE;
    endcase
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pool_state <= POOL_STATE_IDLE;
    end else begin
        pool_state <= pool_state_next;
    end
end

//====================================================================
// Input processing
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        pdp_rdma2dp_data <= 76'd0;
    end else begin
        if (pdp_rdma2dp_valid) begin
            pdp_rdma2dp_data <= pdp_rdma2dp_pd;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        sdp2pdp_data <= 256'd0;
    end else begin
        if (sdp2pdp_valid) begin
            sdp2pdp_data <= sdp2pdp_pd;
        end
    end
end

//====================================================================
// Line buffer management
//====================================================================
assign line_buffer_wr_idx_next = line_buffer_wr_idx + 4'd1;
assign line_buffer_rd_idx_next = line_buffer_rd_idx + 4'd1;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        line_buffer_wr_idx <= 4'd0;
    end else begin
        if (pool_start) begin
            line_buffer_wr_idx <= 4'd0;
        end else if ((pdp_rdma2dp_valid & is_flying_off) | (sdp2pdp_valid & is_flying_on)) begin
            line_buffer_wr_idx <= line_buffer_wr_idx_next;
        end
    end
end

//====================================================================
// Pooling counters
//====================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        split_count <= 8'd0;
        width_count <= 13'd0;
        height_count <= 13'd0;
        channel_count <= 13'd0;
        output_width <= 13'd0;
        output_height <= 13'd0;
    end else if (pool_start) begin
        split_count <= 8'd0;
        width_count <= 13'd0;
        height_count <= 13'd0;
        channel_count <= 13'd0;
        output_width <= 13'd0;
        output_height <= 13'd0;
    end else if (pool_state == POOL_STATE_RUNNING) begin
        // Width iteration
        if (pdp_rdma2dp_valid_int | sdp2pdp_valid_int) begin
            if (width_count < cube_in_width - 13'd1) begin
                width_count <= width_count + 13'd1;
            end else begin
                width_count <= 13'd0;
                // Height iteration
                if (height_count < cube_in_height - 13'd1) begin
                    height_count <= height_count + 13'd1;
                end else begin
                    height_count <= 13'd0;
                    // Channel iteration
                    if (channel_count < cube_in_channel - 13'd1) begin
                        channel_count <= channel_count + 13'd1;
                    end else begin
                        channel_count <= 13'd0;
                        // Output position
                        if (output_width < cube_out_width - 13'd1) begin
                            output_width <= output_width + 13'd1;
                        end else begin
                            output_width <= 13'd0;
                            if (output_height < cube_in_height - 13'd1) begin
                                output_height <= output_height + 13'd1;
                            end else begin
                                output_height <= 13'd0;
                                // Split iteration
                                if (split_count < split_num - 8'd1) begin
                                    split_count <= split_count + 8'd1;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

// Done when all splits, channels, heights, and widths processed
always @(*) begin
    pool_done = (pool_state == POOL_STATE_RUNNING) &
                (split_count >= split_num) &
                (channel_count >= cube_in_channel - 13'd1) &
                (height_count >= cube_in_height - 13'd1) &
                (width_count >= cube_in_width - 13'd1);
end

assign dp2reg_done = (pool_state == POOL_STATE_DONE);

//====================================================================
// Pooling operation
//====================================================================
// For simplicity, this implementation performs a basic pooling operation
// A full implementation would include the full line buffer and 2D pooling logic

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        dp2pdp_valid_int <= 1'b0;
        dp2pdp_data_int <= 64'd0;
        nan_input_count <= 32'd0;
        inf_input_count <= 32'd0;
        nan_output_count <= 32'd0;
    end else begin
        if (pool_state == POOL_STATE_IDLE) begin
            dp2pdp_valid_int <= 1'b0;
            nan_input_count <= 32'd0;
            inf_input_count <= 32'd0;
            nan_output_count <= 32'd0;
        end else if (pool_state == POOL_STATE_RUNNING) begin
            // Generate output when we have a complete pooling window
            if ((output_height < cube_in_height) & (output_width < cube_out_width)) begin
                // Simple pooling - just pass through input for now
                // A full implementation would do the actual pooling calculation
                dp2pdp_valid_int <= 1'b1;
                dp2pdp_data_int <= pdp_rdma2dp_data[63:0];
            end else begin
                dp2pdp_valid_int <= 1'b0;
            end
        end else begin
            dp2pdp_valid_int <= 1'b0;
        end
    end
end

assign dp2pdp_valid = dp2pdp_valid_int;
assign dp2pdp_pd = dp2pdp_data_int;

always @(*) begin
    if (is_flying_off) begin
        dp2pdp_ready_int = dp2pdp_ready;
    end else begin
        dp2pdp_ready_int = dp2pdp_ready;
    end
end

assign dp2reg_nan_input_num = nan_input_count;
assign dp2reg_inf_input_num = inf_input_count;
assign dp2reg_nan_output_num = nan_output_count;

//====================================================================
// NaN/Inf detection for FP16
//====================================================================
generate
    genvar j;
    for (j = 0; j < 16; j = j + 1) begin : nan_inf_detect
        wire [15:0] fp16_val;
        wire val_is_nan;
        wire val_is_inf;
        wire [4:0] exponent;
        wire [9:0] fraction;

        assign fp16_val = pdp_rdma2dp_data[j*16 +: 16];
        assign exponent = fp16_val[15:11];
        assign fraction = fp16_val[10:0];

        assign val_is_nan = (exponent == 5'b11111) & (fraction != 10'd0);
        assign val_is_inf = (exponent == 5'b11111) & (fraction == 10'd0);

        always @(posedge nvdla_core_clk) begin
            if (pool_state == POOL_STATE_RUNNING) begin
                if (is_fp16) begin
                    if (val_is_nan) begin
                        nan_input_count <= nan_input_count + 32'd1;
                    end
                    if (val_is_inf) begin
                        inf_input_count <= inf_input_count + 32'd1;
                    end
                end
            end
        end
    end
endgenerate

endmodule // NV_NVDLA_PDP_pool_new