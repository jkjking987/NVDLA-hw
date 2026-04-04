// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : sdp_x1_ref.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Pure Verilog Reference Model for SDP X1 (Block Select path)
//   Operations: ALU -> MUL -> SHIFT -> RELU
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module sdp_x1_ref (
    input nvdla_core_clk,
    input nvdla_core_rstn,

    // Handshake
    input x1_in_valid,
    output x1_in_ready,
    input [255:0] x1_in_data,

    // ALU operand
    input [255:0] x1_alu_op,
    input x1_alu_op_valid,

    // MUL operand
    input [255:0] x1_mul_op,
    input x1_mul_op_valid,

    // Configuration
    input cfg_x1_bypass,
    input cfg_x1_alu_bypass,
    input [1:0] cfg_x1_alu_algo,
    input cfg_x1_alu_src,
    input [5:0] cfg_x1_alu_shift_value,
    input [15:0] cfg_x1_alu_operand,
    input cfg_x1_mul_bypass,
    input cfg_x1_mul_src,
    input [7:0] cfg_x1_mul_shift_value,
    input [15:0] cfg_x1_mul_operand,
    input cfg_x1_mul_prelu,
    input cfg_x1_relu_bypass,
    input cfg_x1_nan_to_zero,
    input [1:0] cfg_x1_proc_precision,

    // Output
    output [255:0] x1_out_data,
    output x1_out_valid,
    input x1_out_ready
);

    localparam PREC_INT16 = 2'd0;
    localparam PREC_FP16 = 2'd1;
    localparam PREC_INT8 = 2'd2;
    localparam ALU_ADD = 2'd0;
    localparam ALU_MAX = 2'd1;
    localparam ALU_MIN = 2'd2;

    // State: IDLE=0, RUNNING=1
    reg state_q;
    reg [255:0] data_in_reg;
    reg [255:0] alu_op_reg;
    reg [255:0] mul_op_reg;

    // State transition
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            state_q <= 1'b0;
        end else begin
            case (state_q)
                1'b0: begin  // IDLE
                    if (x1_in_valid) begin
                        data_in_reg <= x1_in_data;
                        state_q <= 1'b1;
                    end
                end
                1'b1: begin  // RUNNING
                    if (x1_out_ready) begin
                        state_q <= 1'b0;
                    end
                end
            endcase
        end
    end

    // ALU operand capture
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            alu_op_reg <= 256'b0;
        end else if (x1_alu_op_valid) begin
            alu_op_reg <= x1_alu_op;
        end
    end

    // MUL operand capture
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            mul_op_reg <= 256'b0;
        end else if (x1_mul_op_valid) begin
            mul_op_reg <= x1_mul_op;
        end
    end

    assign x1_in_ready = (state_q == 1'b0);

    // Compute ALU output for element 0
    wire [15:0] alu_op_elem;
    wire [15:0] alu_in_elem;
    wire [15:0] alu_result;

    assign alu_in_elem = data_in_reg[15:0];
    assign alu_op_elem = cfg_x1_alu_src ? alu_op_reg[15:0] : cfg_x1_alu_operand;

    wire [15:0] alu_add = alu_in_elem + alu_op_elem;
    wire [15:0] alu_max = (alu_in_elem > alu_op_elem) ? alu_in_elem : alu_op_elem;
    wire [15:0] alu_min = (alu_in_elem < alu_op_elem) ? alu_in_elem : alu_op_elem;

    assign alu_result = (cfg_x1_alu_algo == ALU_ADD) ? alu_add :
                        (cfg_x1_alu_algo == ALU_MAX) ? alu_max : alu_min;

    wire [15:0] alu_out_elem = cfg_x1_alu_bypass ? alu_in_elem : alu_result;

    // MUL
    wire [15:0] mul_op_elem;
    wire [31:0] mul_result;

    assign mul_op_elem = cfg_x1_mul_src ? mul_op_reg[15:0] : cfg_x1_mul_operand;

    wire sign_bit = alu_out_elem[15];
    wire [31:0] mul_intermediate = $signed(alu_out_elem) * $signed(mul_op_elem);
    wire [15:0] mul_prelu_out = (cfg_x1_mul_prelu && !sign_bit) ? alu_out_elem : mul_intermediate[15:0];

    assign mul_result = cfg_x1_mul_bypass ? {16'b0, alu_out_elem} : {16'b0, mul_prelu_out};

    // TRUNCATE
    wire [15:0] trt_result = mul_result >> cfg_x1_mul_shift_value;

    // RELU
    wire [15:0] relu_result = cfg_x1_relu_bypass ? trt_result :
                               (trt_result[15] == 1'b0) ? trt_result : 16'b0;

    // Output
    assign x1_out_data = cfg_x1_bypass ? data_in_reg : {240'b0, relu_result};
    assign x1_out_valid = (state_q == 1'b1);

endmodule