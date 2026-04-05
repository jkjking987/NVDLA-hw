// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_icvt_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP Input Converter Module (ICVT)
// - Converts input data format based on precision mode
// - Performs ALU (subtract offset), MUL (multiply scale), and TRUNCATE (right shift)
// - Supports INT8, INT16, and FP16 precision modes
//
// Data Flow:
//   Input Data -> ALU (sub offset) -> MUL (multiply scale) -> TRUNCATE (right shift) -> Output
//
// Precision modes:
//   2'b00: INT8  - 8-bit integer (2 pixels packed in 16 bits)
//   2'b01: INT16 - 16-bit integer
//   2'b10: FP16  - Half-precision floating point
//
// ALU:   out = in - cfg_alu_in (sign-extended subtraction)
// MUL:   out = alu_out * cfg_mul_in
// TRUNCATE: out = mul_out >> cfg_truncate (arithmetic right shift)
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_icvt_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  // Input data interface (valid/ready handshake)
  ,in_data_pvld                   //|< i  // input data valid
  ,in_data_prdy                   //|> o  // input data ready
  ,in_data_pd                     //|< i  // input data payload [15:0]
  // Configuration inputs
  ,cfg_alu_in                     //|< i  // ALU input (offset) [15:0]
  ,cfg_mul_in                     //|< i  // MUL input (scale) [15:0]
  ,cfg_truncate                   //|< i  // Truncate shift amount [4:0]
  ,cfg_precision                  //|< i  // Precision mode [1:0]
  // Output data interface
  ,out_data_pvld                  //|> o  // output data valid
  ,out_data_prdy                  //|< i  // output data ready
  ,out_data_pd                    //|> o  // output data payload [17:0]
  );

//===============================================================
// PORT DECLARATION
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// Input data interface
input         in_data_pvld;
output        in_data_prdy;
input  [15:0] in_data_pd;

// Configuration inputs
input  [15:0] cfg_alu_in;      // ALU offset input
input  [15:0] cfg_mul_in;      // MUL scale input
input  [4:0]  cfg_truncate;    // Right shift amount
input  [1:0]  cfg_precision;   // Precision mode

// Output data interface
output        out_data_pvld;
input         out_data_prdy;
output [17:0] out_data_pd;

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// Internal data
wire   [15:0] data_in;          // Registered input data
wire   [15:0] alu_in;          // ALU offset (registered)
wire   [15:0] mul_in;          // MUL scale (registered)
wire   [4:0]  truncate_shift;   // Truncate shift (registered)
wire   [1:0]  precision;       // Precision mode (registered)

// ALU output (intermediate)
wire   [16:0] alu_out_lsb;     // ALU output for LSB (sign-extended)
wire   [16:0] alu_out_msb;     // ALU output for MSB (sign-extended)

// MUL output (intermediate)
wire   [33:0] mul_out_lsb;     // MUL output for LSB (extended)
wire   [33:0] mul_out_msb;     // MUL output for MSB (extended)

// Truncate output
wire   [16:0] trunc_out_lsb;   // Truncate output for LSB
wire   [16:0] trunc_out_msb;   // Truncate output for MSB

// Handshake status
wire         in_ready;
wire         out_ready;
wire         stage1_busy;
wire         stage2_busy;
wire         stage3_busy;

// Pipeline valid signals
reg          stage1_valid;
reg          stage2_valid;
reg          stage3_valid;

// Split data for INT8 mode
wire   [7:0] data_lsb;         // LSB 8 bits (pixel 0)
wire   [7:0] data_msb;         // MSB 8 bits (pixel 1)

// Output data
reg    [17:0] out_data;

//===============================================================
// INPUT DATA REGISTRATION
//===============================================================
reg    [15:0] data_in_reg;
reg    [15:0] alu_in_reg;
reg    [15:0] mul_in_reg;
reg    [4:0]  truncate_shift_reg;
reg    [1:0]  precision_reg;
reg          in_data_pvld_reg;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    data_in_reg <= 16'h0;
    alu_in_reg <= 16'h0;
    mul_in_reg <= 16'h0;
    truncate_shift_reg <= 5'h0;
    precision_reg <= 2'h0;
    in_data_pvld_reg <= 1'b0;
  end else begin
    if (in_data_pvld & in_data_prdy) begin
      data_in_reg <= in_data_pd;
      alu_in_reg <= cfg_alu_in;
      mul_in_reg <= cfg_mul_in;
      truncate_shift_reg <= cfg_truncate;
      precision_reg <= cfg_precision;
      in_data_pvld_reg <= 1'b1;
    end else if (stage1_busy) begin
      in_data_pvld_reg <= 1'b0;
    end
  end
end

assign data_in = data_in_reg;
assign alu_in = alu_in_reg;
assign mul_in = mul_in_reg;
assign truncate_shift = truncate_shift_reg;
assign precision = precision_reg;

//===============================================================
// READY/VALID LOGIC
//===============================================================
// Input is ready when not busy in pipeline
assign in_data_prdy = ~stage1_busy;

// Stage busy flags (pipeline is 3 stages deep)
assign stage1_busy = stage1_valid & ~stage2_valid;
assign stage2_busy = stage2_valid & ~stage3_valid;
assign stage3_busy = stage3_valid & ~(out_data_prdy);

// Forward valid signals
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    stage1_valid <= 1'b0;
    stage2_valid <= 1'b0;
    stage3_valid <= 1'b0;
  end else begin
    stage1_valid <= in_data_pvld & in_data_prdy;
    stage2_valid <= stage1_valid & ~stage2_busy;
    stage3_valid <= stage2_valid & ~stage3_busy;
  end
end

assign out_data_pvld = stage3_valid;
assign out_ready = out_data_prdy | ~stage3_valid;

//===============================================================
// DATA SPLIT FOR INT8 MODE
//===============================================================
assign data_lsb = data_in[7:0];   // Lower pixel
assign data_msb = data_in[15:8]; // Upper pixel

//===============================================================
// ALU STAGE - Subtraction of offset
//===============================================================
// For INT8: subtract offset from each 8-bit pixel (sign-extended to 9 bits)
assign alu_out_lsb = $signed({1'b0, data_lsb}) - $signed({1'b0, alu_in[7:0]});
assign alu_out_msb = $signed({1'b0, data_msb}) - $signed({1'b0, alu_in[15:8]});

// For INT16: subtract offset from 16-bit data (sign-extended to 17 bits)
// For FP16: pass through (no conversion in ALU stage based on C model)
wire [16:0] alu_out_int16;
assign alu_out_int16 = $signed({1'b0, data_in}) - $signed({1'b0, alu_in});

//===============================================================
// MUL STAGE - Multiplication by scale
//===============================================================
wire   [33:0] mul_result_lsb;
wire   [33:0] mul_result_msb;
wire   [33:0] mul_result_int16;

// INT8 mode: multiply 9-bit ALU output by 16-bit scale
assign mul_result_lsb = $signed({{9{alu_out_lsb[16]}}, alu_out_lsb}) * $signed({{17{alu_in[15]}}, mul_in});
assign mul_result_msb = $signed({{9{alu_out_msb[16]}}, alu_out_msb}) * $signed({{17{alu_in[15]}}, mul_in});

// INT16 mode: multiply 17-bit ALU output by 16-bit scale
assign mul_result_int16 = $signed({{17{alu_out_int16[16]}}, alu_out_int16}) * $signed({{17{alu_in[15]}}, mul_in});

//===============================================================
// TRUNCATE STAGE - Right shift with saturation
//===============================================================
// Perform arithmetic right shift on multiply result
// The C code uses: IntShiftRight<vMulOutHSize, vTruncateHSize, vDataOutHSize>

// For INT8 output: 34-bit -> 17-bit right shift
// Fixed for Verilator: replaced variable replication with for-loop approach
function [16:0] arith_right_shift_34to17;
  input [33:0] data;
  input [4:0]  shift;
  input        sign;
  reg   [33:0] result;
  integer i;
  begin
    // Initialize result
    result = 34'b0;

    if (shift >= 17) begin
      // If shift >= 17, result is sign extension or zero
      if (sign && data[33]) begin
        // All 1s for negative
        for (i = 0; i < 17; i = i + 1) begin
          result[i] = 1'b1;
        end
      end
      // Lower 17 bits stay 0
    end else begin
      // Arithmetic right shift: fill top 'shift' bits with sign bit
      for (i = 0; i < shift; i = i + 1) begin
        result[33 - i] = sign && data[33];
      end
      // Copy data[33:shift] to result[33-shift:0]
      for (i = 0; i < (34 - shift); i = i + 1) begin
        result[33 - shift - i] = data[33 - i];
      end
    end
    arith_right_shift_34to17 = result[16:0];
  end
endfunction

assign trunc_out_lsb = arith_right_shift_34to17(mul_result_lsb, truncate_shift, mul_result_lsb[33]);
assign trunc_out_msb = arith_right_shift_34to17(mul_result_msb, truncate_shift, mul_result_msb[33]);

// Truncate output for INT16 mode
wire [16:0] trunc_out_int16;
assign trunc_out_int16 = arith_right_shift_34to17(mul_result_int16, truncate_shift, mul_result_int16[33]);

//===============================================================
// OUTPUT GENERATION
//===============================================================
// Output format based on precision mode
always @(*) begin
  case (precision)
    2'b00: begin // INT8 mode
      // Output: {trunc_msb[8:0], trunc_lsb[8:0]} = 18 bits
      out_data = {trunc_out_msb[8:0], trunc_out_lsb[8:0]};
    end
    2'b01: begin // INT16 mode
      // Output: trunc_out_int16[16:0] = 17 bits
      out_data = trunc_out_int16[16:0];
    end
    2'b10: begin // FP16 mode
      // For FP16: Pass through input as fp17 (expand from 16 to 17 bits)
      // The C model shows fp16 to fp17 conversion
      out_data = {1'b0, data_in};  // fp16 -> fp17 by adding 1 bit
    end
    default: begin
      out_data = 18'h0;
    end
  endcase
end

assign out_data_pd = out_data;

endmodule // NV_NVDLA_CDP_icvt_new