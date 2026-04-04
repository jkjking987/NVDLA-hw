// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_SDP_x2_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// X2 Processing Path (BN - Block Next)
// - ALU operation: MAX/MIN/ADD with configurable operand
// - MUL operation: multiplication with configurable operand
// - Shift and truncate
// - ReLU activation
// - Supports INT16 and FP16 precision
// +FHDR------------------------------------------------------------

`include "simulate_x_tick.vh"
module NV_NVDLA_SDP_x2_new (
   nvdla_core_clk                  //|< i
  ,nvdla_core_rstn                 //|< i
  // Input data interface
  ,x2_in_data                      //|< i
  ,x2_in_valid                     //|< i
  ,x2_in_ready                     //|> o
  // ALU operand from memory or register
  ,x2_alu_op                       //|< i
  ,x2_alu_op_valid                 //|< i
  // MUL operand from memory or register
  ,x2_mul_op                       //|< i
  ,x2_mul_op_valid                 //|< i
  // Configuration
  ,cfg_x2_bypass                   //|< i
  ,cfg_x2_alu_bypass               //|< i
  ,cfg_x2_alu_algo                 //|< i
  ,cfg_x2_alu_src                  //|< i
  ,cfg_x2_alu_shift_value           //|< i
  ,cfg_x2_alu_operand              //|< i
  ,cfg_x2_mul_bypass               //|< i
  ,cfg_x2_mul_src                  //|< i
  ,cfg_x2_mul_shift_value          //|< i
  ,cfg_x2_mul_operand              //|< i
  ,cfg_x2_mul_prelu                //|< i
  ,cfg_x2_relu_bypass              //|< i
  ,cfg_x2_nan_to_zero              //|< i
  ,cfg_x2_proc_precision           //|< i
  // Output
  ,x2_out_data                     //|> o
  ,x2_out_valid                    //|> o
  ,x2_out_ready                    //|< i
  );

//============================================================================
// parameters
//============================================================================
// Precision definitions
localparam [1:0] PRECISION_INT16 = 2'd0;
localparam [1:0] PRECISION_FP16   = 2'd1;
localparam [1:0] PRECISION_INT8   = 2'd2;

// ALU algorithm
localparam [1:0] ALU_MODE_ADD = 2'd0;
localparam [1:0] ALU_MODE_MAX = 2'd1;
localparam [1:0] ALU_MODE_MIN = 2'd2;

// Data path width
localparam DATA_WIDTH = 16;  // 16 elements per cycle

//============================================================================
// signal declarations
//============================================================================
// Clock and reset
wire nvdla_core_clk;
wire nvdla_core_rstn;

// Input data (16 x 16-bit elements)
wire  [255:0] x2_in_data;
wire x2_in_valid;
wire x2_in_ready;

// ALU operand
wire  [255:0] x2_alu_op;
wire x2_alu_op_valid;

// MUL operand
wire  [255:0] x2_mul_op;
wire x2_mul_op_valid;

// Configuration
wire cfg_x2_bypass;
wire cfg_x2_alu_bypass;
wire [1:0] cfg_x2_alu_algo;
wire cfg_x2_alu_src;
wire [5:0] cfg_x2_alu_shift_value;
wire [15:0] cfg_x2_alu_operand;
wire cfg_x2_mul_bypass;
wire cfg_x2_mul_src;
wire [7:0] cfg_x2_mul_shift_value;
wire [15:0] cfg_x2_mul_operand;
wire cfg_x2_mul_prelu;
wire cfg_x2_relu_bypass;
wire cfg_x2_nan_to_zero;
wire [1:0] cfg_x2_proc_precision;

// Output
wire [255:0] x2_out_data;
wire x2_out_valid;
wire x2_out_ready;

// Internal pipeline signals
reg [255:0] alu_in_data_r;
reg [255:0] alu_op_r;
reg alu_op_valid_r;
reg [255:0] alu_out_r;

reg [255:0] mul_in_data_r;
reg [255:0] mul_op_r;
reg mul_op_valid_r;
reg [255:0] mul_out_r;

reg [255:0] trt_out_r;
reg trt_valid_r;

reg [255:0] relu_out_r;
reg relu_valid_r;

//============================================================================
// Input data path
//============================================================================
// Input data register
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    alu_in_data_r <= 256'b0;
  end else if (x2_in_valid && x2_in_ready) begin
    alu_in_data_r <= x2_in_data;
  end
end

// ALU operand register (from memory or register file)
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    alu_op_r <= 256'b0;
    alu_op_valid_r <= 1'b0;
  end else begin
    if (cfg_x2_alu_src == 1'b0) begin
      // ALU operand from register
      alu_op_r <= {16{cfg_x2_alu_operand}};
      alu_op_valid_r <= 1'b1;
    end else if (x2_alu_op_valid) begin
      // ALU operand from memory
      alu_op_r <= x2_alu_op;
      alu_op_valid_r <= 1'b1;
    end else begin
      alu_op_valid_r <= 1'b0;
    end
  end
end

//============================================================================
// ALU operation
//============================================================================
genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : gen_alu
    wire [15:0] alu_in_elem;
    wire [15:0] alu_op_elem;
    wire [15:0] shifted_op;

    assign alu_in_elem = alu_in_data_r[i*16 +: 16];
    assign alu_op_elem = alu_op_r[i*16 +: 16];

    // Shift left for ALU operand alignment
    assign shifted_op = alu_op_elem << cfg_x2_alu_shift_value[5:1];

    // ALU operation
    always @* begin
      if (cfg_x2_proc_precision == PRECISION_FP16) begin
        // FP16 ALU
        case (cfg_x2_alu_algo)
          ALU_MODE_ADD: alu_out_r[i*16 +: 16] = $unsigned(alu_in_elem) + $unsigned(shifted_op);
          ALU_MODE_MAX: alu_out_r[i*16 +: 16] = ($unsigned(alu_in_elem) > $unsigned(shifted_op)) ? alu_in_elem : shifted_op;
          ALU_MODE_MIN: alu_out_r[i*16 +: 16] = ($unsigned(alu_in_elem) < $unsigned(shifted_op)) ? alu_in_elem : shifted_op;
          default: alu_out_r[i*16 +: 16] = $unsigned(alu_in_elem) + $unsigned(shifted_op);
        endcase
      end else begin
        // INT16/INT8 ALU
        case (cfg_x2_alu_algo)
          ALU_MODE_ADD: alu_out_r[i*16 +: 16] = $signed(alu_in_elem) + $signed(shifted_op);
          ALU_MODE_MAX: alu_out_r[i*16 +: 16] = ($signed(alu_in_elem) > $signed(shifted_op)) ? alu_in_elem : shifted_op;
          ALU_MODE_MIN: alu_out_r[i*16 +: 16] = ($signed(alu_in_elem) < $signed(shifted_op)) ? alu_in_elem : shifted_op;
          default: alu_out_r[i*16 +: 16] = $signed(alu_in_elem) + $signed(shifted_op);
        endcase
      end
    end
  end
endgenerate

// ALU bypass
wire [255:0] alu_result;
assign alu_result = cfg_x2_alu_bypass ? alu_in_data_r : alu_out_r;

//============================================================================
// MUL operation
//============================================================================
// MUL input register
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mul_in_data_r <= 256'b0;
    mul_op_r <= 256'b0;
    mul_op_valid_r <= 1'b0;
  end else begin
    mul_in_data_r <= alu_result;
    if (cfg_x2_mul_src == 1'b0) begin
      // MUL operand from register
      mul_op_r <= {16{cfg_x2_mul_operand}};
      mul_op_valid_r <= 1'b1;
    end else if (x2_mul_op_valid) begin
      // MUL operand from memory
      mul_op_r <= x2_mul_op;
      mul_op_valid_r <= 1'b1;
    end else begin
      mul_op_valid_r <= 1'b0;
    end
  end
end

// Multiplier operation
generate
  for (i = 0; i < 16; i = i + 1) begin : gen_mul
    wire [15:0] mul_in_elem;
    wire [15:0] mul_op_elem;
    wire [31:0] mul_result;
    wire sign_bit;

    assign mul_in_elem = mul_in_data_r[i*16 +: 16];
    assign mul_op_elem = mul_op_r[i*16 +: 16];
    assign sign_bit = mul_in_elem[15];

    // PReLU check: if input is negative and PReLU enabled, pass through
    wire mul_bypass_trt;
    assign mul_bypass_trt = cfg_x2_mul_prelu && sign_bit;

    // Multiplication
    assign mul_result = $signed(mul_in_elem) * $signed(mul_op_elem);

    // Select output based on PReLU bypass
    always @* begin
      if (cfg_x2_mul_bypass) begin
        mul_out_r[i*16 +: 16] = mul_in_elem;
      end else if (mul_bypass_trt) begin
        mul_out_r[i*16 +: 16] = mul_in_elem;  // PReLU bypass
      end else begin
        // Shift right after multiplication
        mul_out_r[i*16 +: 16] = mul_result[31:16];  // Simple truncation
      end
    end
  end
endgenerate

//============================================================================
// Shift and Truncate ( TRT)
//============================================================================
// TRT operation
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    trt_out_r <= 256'b0;
    trt_valid_r <= 1'b0;
  end else begin
    trt_valid_r <= mul_op_valid_r;
    // Shift right by configured amount
    if (cfg_x2_mul_shift_value[7]) begin
      // Right shift
      trt_out_r <= mul_out_r >> cfg_x2_mul_shift_value[6:0];
    end else begin
      trt_out_r <= mul_out_r;
    end
  end
end

//============================================================================
// ReLU activation
//============================================================================
generate
  for (i = 0; i < 16; i = i + 1) begin : gen_relu
    wire [15:0] relu_in_elem;

    assign relu_in_elem = trt_out_r[i*16 +: 16];

    always @* begin
      if (cfg_x2_relu_bypass) begin
        relu_out_r[i*16 +: 16] = relu_in_elem;
      end else begin
        // ReLU: max(0, input)
        if ($signed(relu_in_elem) > 16'sb0) begin
          relu_out_r[i*16 +: 16] = relu_in_elem;
        end else begin
          relu_out_r[i*16 +: 16] = 16'sb0;
        end
      end
    end
  end
endgenerate

// ReLU valid pipeline
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    relu_valid_r <= 1'b0;
  end else begin
    relu_valid_r <= trt_valid_r;
  end
end

//============================================================================
// Output assignment
//============================================================================
assign x2_out_data = relu_out_r;
assign x2_out_valid = relu_valid_r;

// Ready signal - always ready when not bypassed
assign x2_in_ready = 1'b1;  // Always accept new input when op_en is set

endmodule // NV_NVDLA_SDP_x2_new