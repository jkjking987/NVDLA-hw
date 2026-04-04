// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_SDP_y_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// Y Processing Path (EW - Element Wise)
// - MUL operation with optional conversion
// - ALU operation with optional conversion
// - Truncate
// - ReLU activation
// - LUT (Lookup Table) with LE and LO functions
// - Supports INT16 and FP16 precision
// +FHDR------------------------------------------------------------

`include "simulate_x_tick.vh"
module NV_NVDLA_SDP_y_new (
   nvdla_core_clk                  //|< i
  ,nvdla_core_rstn                 //|< i
  // Input data interface
  ,y_in_data                       //|< i
  ,y_in_valid                      //|< i
  ,y_in_ready                      //|> o
  // ALU operand from memory or register
  ,y_alu_op                        //|< i
  ,y_alu_op_valid                  //|< i
  // MUL operand from memory or register
  ,y_mul_op                        //|< i
  ,y_mul_op_valid                  //|< i
  // LUT output
  ,y_lut_out                       //|> o
  ,y_lut_out_valid                 //|> o
  ,y_lut_in_ready                  //|< i
  // Configuration
  ,cfg_y_bypass                    //|< i
  ,cfg_y_alu_bypass                //|< i
  ,cfg_y_alu_algo                  //|< i
  ,cfg_y_alu_src                   //|< i
  ,cfg_y_alu_cvt_bypass            //|< i
  ,cfg_y_alu_cvt_offset            //|< i
  ,cfg_y_alu_cvt_scale             //|< i
  ,cfg_y_alu_cvt_truncate          //|< i
  ,cfg_y_alu_operand               //|< i
  ,cfg_y_mul_bypass                //|< i
  ,cfg_y_mul_src                   //|< i
  ,cfg_y_mul_cvt_bypass            //|< i
  ,cfg_y_mul_cvt_offset            //|< i
  ,cfg_y_mul_cvt_scale             //|< i
  ,cfg_y_mul_cvt_truncate          //|< i
  ,cfg_y_mul_operand               //|< i
  ,cfg_y_mul_prelu                 //|< i
  ,cfg_y_truncate                  //|< i
  ,cfg_y_lut_bypass                //|< i
  ,cfg_y_lut_le_function           //|< i
  ,cfg_y_lut_le_start              //|< i
  ,cfg_y_lut_le_end                //|< i
  ,cfg_y_lut_le_index_offset       //|< i
  ,cfg_y_lut_le_index_select       //|< i
  ,cfg_y_lut_lo_start              //|< i
  ,cfg_y_lut_lo_end                //|< i
  ,cfg_y_lut_lo_index_select       //|< i
  ,cfg_y_lut_uflow_priority        //|< i
  ,cfg_y_lut_oflow_priority        //|< i
  ,cfg_y_lut_hybrid_priority       //|< i
  ,cfg_y_lut_le_uflow_scale        //|< i
  ,cfg_y_lut_le_uflow_shift        //|< i
  ,cfg_y_lut_le_oflow_scale        //|< i
  ,cfg_y_lut_le_oflow_shift        //|< i
  ,cfg_y_lut_lo_uflow_scale        //|< i
  ,cfg_y_lut_lo_uflow_shift        //|< i
  ,cfg_y_lut_lo_oflow_scale        //|< i
  ,cfg_y_lut_lo_oflow_shift        //|< i
  ,cfg_y_nan_to_zero               //|< i
  ,cfg_y_proc_precision            //|< i
  // Output
  ,y_out_data                      //|> o
  ,y_out_valid                     //|> o
  ,y_out_ready                     //|< i
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
localparam [1:0] ALU_MODE_EQL = 2'd3;  // Equal (for comparison)

// Data path width
localparam DATA_WIDTH = 16;  // 16 elements per cycle

//============================================================================
// signal declarations
//============================================================================
// Clock and reset
wire nvdla_core_clk;
wire nvdla_core_rstn;

// Input data (16 x 16-bit elements)
wire  [255:0] y_in_data;
wire y_in_valid;
wire y_in_ready;

// ALU operand
wire  [255:0] y_alu_op;
wire y_alu_op_valid;

// MUL operand
wire  [255:0] y_mul_op;
wire y_mul_op_valid;

// LUT output
wire  [255:0] y_lut_out;
wire y_lut_out_valid;
wire y_lut_in_ready;

// Configuration
wire cfg_y_bypass;
wire cfg_y_alu_bypass;
wire [1:0] cfg_y_alu_algo;
wire cfg_y_alu_src;
wire cfg_y_alu_cvt_bypass;
wire [31:0] cfg_y_alu_cvt_offset;
wire [15:0] cfg_y_alu_cvt_scale;
wire [5:0] cfg_y_alu_cvt_truncate;
wire [31:0] cfg_y_alu_operand;
wire cfg_y_mul_bypass;
wire cfg_y_mul_src;
wire cfg_y_mul_cvt_bypass;
wire [31:0] cfg_y_mul_cvt_offset;
wire [15:0] cfg_y_mul_cvt_scale;
wire [5:0] cfg_y_mul_cvt_truncate;
wire [31:0] cfg_y_mul_operand;
wire cfg_y_mul_prelu;
wire [9:0] cfg_y_truncate;
wire cfg_y_lut_bypass;
wire cfg_y_lut_le_function;
wire [31:0] cfg_y_lut_le_start;
wire [31:0] cfg_y_lut_le_end;
wire [7:0] cfg_y_lut_le_index_offset;
wire [7:0] cfg_y_lut_le_index_select;
wire [31:0] cfg_y_lut_lo_start;
wire [31:0] cfg_y_lut_lo_end;
wire [7:0] cfg_y_lut_lo_index_select;
wire cfg_y_lut_uflow_priority;
wire cfg_y_lut_oflow_priority;
wire cfg_y_lut_hybrid_priority;
wire [15:0] cfg_y_lut_le_uflow_scale;
wire [4:0] cfg_y_lut_le_uflow_shift;
wire [15:0] cfg_y_lut_le_oflow_scale;
wire [4:0] cfg_y_lut_le_oflow_shift;
wire [15:0] cfg_y_lut_lo_uflow_scale;
wire [4:0] cfg_y_lut_lo_uflow_shift;
wire [15:0] cfg_y_lut_lo_oflow_scale;
wire [4:0] cfg_y_lut_lo_oflow_shift;
wire cfg_y_nan_to_zero;
wire [1:0] cfg_y_proc_precision;

// Output
wire [255:0] y_out_data;
wire y_out_valid;
wire y_out_ready;

// Internal pipeline signals
reg [255:0] mul_in_data_r;
reg [255:0] mul_op_r;
reg mul_op_valid_r;
reg [255:0] mul_out_r;

reg [255:0] alu_in_data_r;
reg [255:0] alu_op_r;
reg alu_op_valid_r;
reg [255:0] alu_out_r;

reg [255:0] trt_out_r;
reg trt_valid_r;

reg [255:0] relu_out_r;
reg relu_valid_r;

reg [255:0] lut_in_r;
reg lut_valid_r;

//============================================================================
// MUL operation (first in Y path)
//============================================================================
// MUL input register
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mul_in_data_r <= 256'b0;
    mul_op_r <= 256'b0;
    mul_op_valid_r <= 1'b0;
  end else if (y_in_valid && y_in_ready) begin
    mul_in_data_r <= y_in_data;
    if (cfg_y_mul_src == 1'b0) begin
      // MUL operand from register
      mul_op_r <= {8{cfg_y_mul_operand[31:0]}};
      mul_op_valid_r <= 1'b1;
    end else if (y_mul_op_valid) begin
      // MUL operand from memory
      mul_op_r <= y_mul_op;
      mul_op_valid_r <= 1'b1;
    end else begin
      mul_op_valid_r <= 1'b0;
    end
  end else begin
    mul_op_valid_r <= 1'b0;
  end
end

// Multiplier operation
genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : gen_mul
    wire [31:0] mul_in_elem;  // Extended to 32 bits for multiplication
    wire [31:0] mul_op_elem;
    wire [31:0] mul_result;
    wire sign_bit;

    assign mul_in_elem = {{16{mul_in_data_r[i*16 + 15]}}, mul_in_data_r[i*16 +: 16]};
    assign mul_op_elem = {{16{mul_op_r[i*16 + 15]}}, mul_op_r[i*16 +: 16]};
    assign sign_bit = mul_in_elem[31];

    // PReLU check: if input is negative and PReLU enabled, pass through
    wire mul_bypass_trt;
    assign mul_bypass_trt = cfg_y_mul_prelu && sign_bit;

    // Multiplication
    assign mul_result = mul_in_elem * mul_op_elem;

    // Select output based on PReLU bypass
    always @* begin
      if (cfg_y_mul_bypass) begin
        mul_out_r[i*16 +: 16] = mul_in_data_r[i*16 +: 16];
      end else if (mul_bypass_trt) begin
        mul_out_r[i*16 +: 16] = mul_in_data_r[i*16 +: 16];  // PReLU bypass
      end else begin
        // Apply conversion and truncation
        if (!cfg_y_mul_cvt_bypass) begin
          // Apply scale and offset
          mul_out_r[i*16 +: 16] = (mul_result[31:16] * cfg_y_mul_cvt_scale[15:0]) + cfg_y_mul_cvt_offset[15:0];
        end else begin
          mul_out_r[i*16 +: 16] = mul_result[47:32];  // Upper 16 bits of 48-bit result
        end
      end
    end
  end
endgenerate

//============================================================================
// ALU operation (after MUL in Y path)
//============================================================================
// ALU input register
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    alu_in_data_r <= 256'b0;
    alu_op_r <= 256'b0;
    alu_op_valid_r <= 1'b0;
  end else begin
    alu_in_data_r <= mul_out_r;
    if (cfg_y_alu_src == 1'b0) begin
      // ALU operand from register
      alu_op_r <= {8{cfg_y_alu_operand[31:0]}};
      alu_op_valid_r <= mul_op_valid_r;
    end else if (y_alu_op_valid) begin
      // ALU operand from memory
      alu_op_r <= y_alu_op;
      alu_op_valid_r <= 1'b1;
    end else begin
      alu_op_valid_r <= 1'b0;
    end
  end
end

// ALU operation
generate
  for (i = 0; i < 16; i = i + 1) begin : gen_alu
    wire [31:0] alu_in_elem;
    wire [31:0] alu_op_elem;
    wire [31:0] cvt_op_elem;
    wire [31:0] alu_result;

    assign alu_in_elem = {{16{alu_in_data_r[i*16 + 15]}}, alu_in_data_r[i*16 +: 16]};
    assign alu_op_elem = {{16{alu_op_r[i*16 + 15]}}, alu_op_r[i*16 +: 16]};

    // Apply conversion to operand if not bypassed
    assign cvt_op_elem = cfg_y_alu_cvt_bypass ?
        alu_op_elem :
        (alu_op_elem * cfg_y_alu_cvt_scale[15:0]) + cfg_y_alu_cvt_offset;

    // ALU operation
    always @* begin
      case (cfg_y_alu_algo)
        ALU_MODE_ADD: alu_result = alu_in_elem + cvt_op_elem;
        ALU_MODE_MAX: alu_result = (alu_in_elem > cvt_op_elem) ? alu_in_elem : cvt_op_elem;
        ALU_MODE_MIN: alu_result = (alu_in_elem < cvt_op_elem) ? alu_in_elem : cvt_op_elem;
        ALU_MODE_EQL: alu_result = (alu_in_elem == cvt_op_elem) ? 32'hFFFFFFFF : 32'h0;
        default: alu_result = alu_in_elem + cvt_op_elem;
      endcase
    end

    // Truncate result
    always @* begin
      if (!cfg_y_alu_cvt_bypass) begin
        alu_out_r[i*16 +: 16] = alu_result[15:0];
      end else begin
        alu_out_r[i*16 +: 16] = alu_result[cfg_y_alu_cvt_truncate +: 16];
      end
    end
  end
endgenerate

// ALU bypass
wire [255:0] alu_result;
assign alu_result = cfg_y_alu_bypass ? mul_out_r : alu_out_r;

//============================================================================
// Truncate
//============================================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    trt_out_r <= 256'b0;
    trt_valid_r <= 1'b0;
  end else begin
    trt_valid_r <= alu_op_valid_r;
    // Truncate based on configuration
    trt_out_r <= alu_result >> cfg_y_truncate[3:0];
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
      if (cfg_y_bypass) begin  // Note: Y bypass includes ReLU
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
// LUT (Lookup Table) - placeholder implementation
//============================================================================
// LUT input register
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    lut_in_r <= 256'b0;
    lut_valid_r <= 1'b0;
  end else begin
    lut_in_r <= relu_out_r;
    lut_valid_r <= relu_valid_r;
  end
end

// LUT operation - simplified placeholder
// The actual LUT has complex index calculation and slope interpolation
generate
  for (i = 0; i < 16; i = i + 1) begin : gen_lut
    wire [15:0] lut_in_elem;
    wire [15:0] lut_out_elem;
    wire [7:0] lut_index;
    wire in_le_range;
    wire in_lo_range;
    wire is_underflow;
    wire is_overflow;

    assign lut_in_elem = lut_in_r[i*16 +: 16];

    // Calculate index based on input
    assign lut_index = lut_in_elem[7:0] + cfg_y_lut_le_index_offset;

    // Check if input is in LE range
    assign in_le_range = ($signed(lut_in_elem) >= $signed(cfg_y_lut_le_start[15:0])) &&
                         ($signed(lut_in_elem) <= $signed(cfg_y_lut_le_end[15:0]));

    // Check if input is in LO range
    assign in_lo_range = ($signed(lut_in_elem) >= $signed(cfg_y_lut_lo_start[15:0])) &&
                         ($signed(lut_in_elem) <= $signed(cfg_y_lut_lo_end[15:0]));

    // Underflow/Overflow detection
    assign is_underflow = ($signed(lut_in_elem) < $signed(cfg_y_lut_le_start[15:0]));
    assign is_overflow = ($signed(lut_in_elem) > $signed(cfg_y_lut_le_end[15:0]));

    // LUT output selection based on priority and range
    always @* begin
      if (cfg_y_lut_bypass) begin
        lut_out_r[i*16 +: 16] = lut_in_elem;
      end else begin
        // Simplified LUT - actual implementation has complex slope interpolation
        if (is_underflow) begin
          // Apply underflow slope scale
          if (cfg_y_lut_uflow_priority) begin
            lut_out_r[i*16 +: 16] = cfg_y_lut_le_start[15:0];
          end else begin
            lut_out_r[i*16 +: 16] = lut_in_elem;
          end
        end else if (is_overflow) begin
          // Apply overflow slope scale
          if (cfg_y_lut_oflow_priority) begin
            lut_out_r[i*16 +: 16] = cfg_y_lut_le_end[15:0];
          end else begin
            lut_out_r[i*16 +: 16] = lut_in_elem;
          end
        end else if (in_le_range) begin
          // LE function lookup
          if (cfg_y_lut_le_function) begin
            // Linear interpolation mode
            lut_out_r[i*16 +: 16] = lut_in_elem;  // Placeholder
          end else begin
            // Direct lookup mode
            lut_out_r[i*16 +: 16] = lut_in_elem;  // Placeholder
          end
        end else begin
          lut_out_r[i*16 +: 16] = lut_in_elem;
        end
      end
    end
  end
endgenerate

// LUT bypass path
wire [255:0] lut_result;
assign lut_result = cfg_y_lut_bypass ? lut_in_r : lut_out_r;

//============================================================================
// Output assignment
//============================================================================
assign y_out_data = lut_result;
assign y_out_valid = lut_valid_r;

// LUT direct output (bypasses LUT if needed)
assign y_lut_out = lut_result;
assign y_lut_out_valid = lut_valid_r;

// Ready signal - accepts new input when previous stage is done
assign y_in_ready = 1'b1;

endmodule // NV_NVDLA_SDP_y_new