// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CDP_ocvt_new.v
// Author        : Claude
// Author Email  : noreply@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CDP Output Converter Module (OCVT)
// - Converts output data format based on precision mode
// - Performs ALU (subtract offset), MUL (multiply scale), and TRUNCATE (right shift with saturation)
// - Supports INT8, INT16, and FP16 precision modes
// - Generates saturation flags for overflow detection
//
// Data Flow:
//   Input Data -> ALU (sub offset) -> MUL (multiply scale) -> TRUNCATE/SAT (right shift) -> Output
//
// Precision modes:
//   2'b00: INT8  - 8-bit integer output
//   2'b01: INT16 - 16-bit integer output
//   2'b10: FP16  - Half-precision floating point output
//
// Saturation flags:
//   [0]: LSB saturation (overflow/underflow)
//   [1]: MSB saturation (overflow/underflow)
// +FHDR------------------------------------------------------------

module NV_NVDLA_CDP_ocvt_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  // Input data interface (valid/ready handshake)
  ,in_data_pvld                   //|< i  // input data valid
  ,in_data_prdy                   //|> o  // input data ready
  ,in_data_pd                     //|< i  // input data payload [48:0]
  // Configuration inputs
  ,cfg_alu_in                     //|< i  // ALU input (offset) [31:0]
  ,cfg_mul_in                     //|< i  // MUL input (scale) [15:0]
  ,cfg_truncate                   //|< i  // Truncate shift amount [5:0]
  ,cfg_precision                  //|< i  // Precision mode [1:0]
  // Output data interface
  ,out_data_pvld                  //|> o  // output data valid
  ,out_data_prdy                  //|< i  // output data ready
  ,out_data_pd                    //|> o  // output data payload [15:0]
  ,out_saturation                 //|> o  // saturation flags [1:0]
  );

//===============================================================
// PORT DECLARATION
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;

// Input data interface
input         in_data_pvld;
output        in_data_prdy;
input  [48:0] in_data_pd;         // 49-bit input (2 x 24.5 bits effectively)

// Configuration inputs
input  [31:0] cfg_alu_in;        // ALU offset input
input  [15:0] cfg_mul_in;        // MUL scale input
input  [5:0]  cfg_truncate;     // Right shift amount
input  [1:0]  cfg_precision;     // Precision mode

// Output data interface
output        out_data_pvld;
input         out_data_prdy;
output [15:0] out_data_pd;       // 16-bit output
output [1:0]  out_saturation;    // Saturation flags

//===============================================================
// WIRE DECLARATIONS
//===============================================================
// Internal data
reg    [48:0] data_in_reg;
reg    [31:0] alu_in_reg;
reg    [15:0] mul_in_reg;
reg    [5:0]  truncate_shift_reg;
reg    [1:0]  precision_reg;
reg          in_data_pvld_reg;

// Handshake status
wire         stage1_busy;
wire         stage2_busy;
wire         stage3_busy;

// Pipeline valid signals
reg          stage1_valid;
reg          stage2_valid;
reg          stage3_valid;

// Saturation flags
reg    [1:0] saturation_flags;

// Split data for INT8 mode
wire   [24:0] data_lsb;         // LSB data path
wire   [24:0] data_msb;         // MSB data path

// ALU output
wire   [24:0] alu_out_lsb;
wire   [24:0] alu_out_msb;

// MUL output (extended)
wire   [49:0] mul_out_lsb;
wire   [49:0] mul_out_msb;

// Truncate output
reg    [15:0] trunc_out_lsb;
reg    [15:0] trunc_out_msb;

// Saturation detection
reg          sat_lsb;
reg          sat_msb;

// Output data
reg    [15:0] out_data;

//===============================================================
// INPUT DATA REGISTRATION
//===============================================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    data_in_reg <= 49'h0;
    alu_in_reg <= 32'h0;
    mul_in_reg <= 16'h0;
    truncate_shift_reg <= 6'h0;
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

//===============================================================
// READY/VALID LOGIC
//===============================================================
assign in_data_prdy = ~stage1_busy;

// Stage busy flags
assign stage1_busy = stage1_valid & ~stage2_valid;
assign stage2_busy = stage2_valid & ~stage3_valid;
assign stage3_busy = stage3_valid & ~out_data_prdy;

// Forward valid signals
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    stage1_valid <= 1'b0;
    stage2_valid <= 1'b0;
    stage3_valid <= 1'b0;
  end else begin
    stage1_valid <= in_data_pvld & in_data_prdy;
    stage2_valid <= stage1_valid & ~stage1_busy;
    stage3_valid <= stage2_valid & ~stage2_busy;
  end
end

assign out_data_pvld = stage3_valid;

//===============================================================
// DATA SPLIT FOR PROCESSING
//===============================================================
assign data_lsb = data_in_reg[24:0];
assign data_msb = data_in_reg[48:25];

//===============================================================
// ALU STAGE - Subtraction of offset
//===============================================================
// ALU: out = in - cfg_alu_in (sign-extended subtraction)
assign alu_out_lsb = $signed(data_lsb) - $signed(alu_in_reg[24:0]);
assign alu_out_msb = $signed(data_msb) - $signed(alu_in_reg[24:0]);

//===============================================================
// MUL STAGE - Multiplication by scale
//===============================================================
assign mul_out_lsb = $signed({{25{alu_out_lsb[24]}}, alu_out_lsb}) *
                     $signed({{9{cfg_mul_in[15]}}, cfg_mul_in});
assign mul_out_msb = $signed({{25{alu_out_msb[24]}}, alu_out_msb}) *
                     $signed({{9{cfg_mul_in[15]}}, cfg_mul_in});

//===============================================================
// TRUNCATE STAGE - Right shift with saturation check
//===============================================================
function [15:0] shift_right_sat_50to16;
  input [49:0] data;
  input [5:0]  shift;
  input        sign;
  output       sat;
  reg   [49:0] result;
  reg   [15:0] truncated;
  reg          sat_detect;
  begin
    sat_detect = 1'b0;
    if (shift >= 16) begin
      // If shift >= 16, check for saturation
      if (sign) begin
        // Negative saturation: all bits should be 1
        sat_detect = ~(&data[49:shift]);  // Not all 1s means saturation
      end else begin
        // Positive saturation: all bits should be 0 except lower bits
        sat_detect = |data[49:shift];  // Any 1 in upper bits means saturation
      end
      truncated = {16{sign & data[49]}};
    end else begin
      // Arithmetic right shift
      result = {{shift{sign & data[49]}}, data[49:shift]};
      truncated = result[15:0];

      // Saturation detection: check if bits were lost
      if (sign) begin
        sat_detect = ~(&{data[shift-1:0], {shift{1'b1}}});  // Lost precision in negative
      end else begin
        sat_detect = |data[shift-1:0];  // Lost precision in positive
      end
    end
    shift_right_sat_50to16 = truncated;
    sat = sat_detect & |shift;  // Sat if overflow occurred and shift > 0
  end
endfunction

always @(*) begin
  {trunc_out_lsb, sat_lsb} = shift_right_sat_50to16(mul_out_lsb, truncate_shift_reg, mul_out_lsb[49]);
  {trunc_out_msb, sat_msb} = shift_right_sat_50to16(mul_out_msb, truncate_shift_reg, mul_out_msb[49]);
end

//===============================================================
// OUTPUT GENERATION
//===============================================================
always @(*) begin
  case (precision_reg)
    2'b00: begin // INT8 mode
      // Output: {trunc_msb[7:0], trunc_lsb[7:0]} = 16 bits
      out_data = {trunc_out_msb[7:0], trunc_out_lsb[7:0]};
      saturation_flags = {sat_msb, sat_lsb};
    end
    2'b01: begin // INT16 mode
      // Output: trunc_out_lsb[15:0]
      out_data = trunc_out_lsb[15:0];
      saturation_flags = {sat_msb, sat_lsb};
    end
    2'b10: begin // FP16 mode
      // For FP16: pass through lower 16 bits (fp17 -> fp16 conversion)
      out_data = data_in_reg[15:0];
      saturation_flags = 2'b00;  // No saturation for FP16
    end
    default: begin
      out_data = 16'h0;
      saturation_flags = 2'b00;
    end
  endcase
end

assign out_data_pd = out_data;
assign out_saturation = saturation_flags;

endmodule // NV_NVDLA_CDP_ocvt_new