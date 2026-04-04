// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : sdp_x1_ref_tb.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Testbench for SDP X1 Reference Model
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module sdp_x1_ref_tb;

    reg nvdla_core_clk;
    reg nvdla_core_rstn;

    reg x1_in_valid;
    wire x1_in_ready;
    reg [255:0] x1_in_data;

    reg [255:0] x1_alu_op;
    reg x1_alu_op_valid;

    reg [255:0] x1_mul_op;
    reg x1_mul_op_valid;

    wire [255:0] x1_out_data;
    wire x1_out_valid;
    reg x1_out_ready;

    // DUT
    sdp_x1_ref dut (
        .nvdla_core_clk(nvdla_core_clk),
        .nvdla_core_rstn(nvdla_core_rstn),
        .x1_in_valid(x1_in_valid),
        .x1_in_ready(x1_in_ready),
        .x1_in_data(x1_in_data),
        .x1_alu_op(x1_alu_op),
        .x1_alu_op_valid(x1_alu_op_valid),
        .x1_mul_op(x1_mul_op),
        .x1_mul_op_valid(x1_mul_op_valid),
        .cfg_x1_bypass(1'b0),
        .cfg_x1_alu_bypass(1'b0),
        .cfg_x1_alu_algo(2'd0),
        .cfg_x1_alu_src(1'b1),
        .cfg_x1_alu_shift_value(6'd0),
        .cfg_x1_alu_operand(16'd0),
        .cfg_x1_mul_bypass(1'b0),
        .cfg_x1_mul_src(1'b1),
        .cfg_x1_mul_shift_value(8'd0),
        .cfg_x1_mul_operand(16'd0),
        .cfg_x1_mul_prelu(1'b0),
        .cfg_x1_relu_bypass(1'b0),
        .cfg_x1_nan_to_zero(1'b0),
        .cfg_x1_proc_precision(2'd0),
        .x1_out_data(x1_out_data),
        .x1_out_valid(x1_out_valid),
        .x1_out_ready(x1_out_ready)
    );

    initial begin
        nvdla_core_clk = 0;
        forever #5 nvdla_core_clk = ~nvdla_core_clk;
    end

    integer test_count;
    integer pass_count;

    initial begin
        test_count = 0;
        pass_count = 0;
        x1_in_valid = 0;
        x1_alu_op_valid = 0;
        x1_mul_op_valid = 0;
        x1_out_ready = 1;
        x1_in_data = 256'b0;
        x1_alu_op = 256'b0;
        x1_mul_op = 256'b0;

        nvdla_core_rstn = 0;
        #100;
        nvdla_core_rstn = 1;
        #50;

        // Test 1: ADD operation - element 0: 100 + 50 = 150
        test_count = test_count + 1;
        x1_in_data = 256'b0;
        x1_in_data[15:0] = 16'd100;
        x1_alu_op = 256'b0;
        x1_alu_op[15:0] = 16'd50;
        x1_mul_op = 256'b0;
        x1_mul_op[15:0] = 16'd1;

        // Present operands first
        x1_alu_op_valid = 1;
        x1_mul_op_valid = 1;
        @(posedge nvdla_core_clk);
        #1;

        // Then present input data
        x1_in_valid = 1;
        @(posedge nvdla_core_clk);
        #1;

        // Wait for output
        while (!x1_out_valid) @(posedge nvdla_core_clk);
        #1;

        if (x1_out_data[15:0] == 16'd150) begin
            $display("PASS: Test 1 - ADD result=%h (expected 150)", x1_out_data[15:0]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - ADD result=%h (expected 150)", x1_out_data[15:0]);
        end

        // Clear handshake
        x1_in_valid = 0;
        x1_alu_op_valid = 0;
        x1_mul_op_valid = 0;
        @(posedge nvdla_core_clk);
        #1;

        // Test 2: MAX operation - element 0: max(80, 30) = 80
        test_count = test_count + 1;
        x1_in_data = 256'b0;
        x1_in_data[15:0] = 16'd80;
        x1_alu_op = 256'b0;
        x1_alu_op[15:0] = 16'd30;
        x1_mul_op = 256'b0;
        x1_mul_op[15:0] = 16'd1;

        x1_alu_op_valid = 1;
        x1_mul_op_valid = 1;
        @(posedge nvdla_core_clk);
        #1;
        x1_in_valid = 1;
        @(posedge nvdla_core_clk);
        #1;
        while (!x1_out_valid) @(posedge nvdla_core_clk);
        #1;

        if (x1_out_data[15:0] == 16'd80) begin
            $display("PASS: Test 2 - MAX result=%h (expected 80)", x1_out_data[15:0]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - MAX result=%h (expected 80)", x1_out_data[15:0]);
        end

        x1_in_valid = 0;
        x1_alu_op_valid = 0;
        x1_mul_op_valid = 0;
        @(posedge nvdla_core_clk);
        #1;

        // Test 3: MUL operation - element 0: 10 * 5 = 50
        test_count = test_count + 1;
        x1_in_data = 256'b0;
        x1_in_data[15:0] = 16'd10;
        x1_alu_op = 256'b0;
        x1_alu_op[15:0] = 16'd0;  // ALU bypass (add 0)
        x1_mul_op = 256'b0;
        x1_mul_op[15:0] = 16'd5;

        x1_alu_op_valid = 1;
        x1_mul_op_valid = 1;
        @(posedge nvdla_core_clk);
        #1;
        x1_in_valid = 1;
        @(posedge nvdla_core_clk);
        #1;
        while (!x1_out_valid) @(posedge nvdla_core_clk);
        #1;

        if (x1_out_data[15:0] == 16'd50) begin
            $display("PASS: Test 3 - MUL result=%h (expected 50)", x1_out_data[15:0]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 3 - MUL result=%h (expected 50)", x1_out_data[15:0]);
        end

        $display("========================================");
        $display("SDP X1 Reference Model Test Summary:");
        $display("  Total: %0d", test_count);
        $display("  Pass:  %0d", pass_count);
        $display("  Fail:  %0d", test_count - pass_count);
        $display("========================================");

        $finish;
    end

endmodule