// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : cdp_ocvt_ref_tb.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Testbench for CDP OCVT Reference Model
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module cdp_ocvt_ref_tb;

    reg nvdla_core_clk;
    reg nvdla_core_rstn;

    reg chn_data_in_vld;
    wire chn_data_in_rdy;
    reg [49:0] chn_data_in;

    reg [1:0] cfg_precision;
    reg [31:0] cfg_alu_in;
    reg [15:0] cfg_mul_in;
    reg [5:0] cfg_truncate;

    wire chn_data_out_vld;
    reg chn_data_out_rdy;
    wire [15:0] chn_data_out;
    wire [1:0] chn_data_out_sat;

    // DUT
    cdp_ocvt_ref dut (
        .nvdla_core_clk(nvdla_core_clk),
        .nvdla_core_rstn(nvdla_core_rstn),
        .chn_data_in_vld(chn_data_in_vld),
        .chn_data_in_rdy(chn_data_in_rdy),
        .chn_data_in(chn_data_in),
        .cfg_precision(cfg_precision),
        .cfg_alu_in(cfg_alu_in),
        .cfg_mul_in(cfg_mul_in),
        .cfg_truncate(cfg_truncate),
        .chn_data_out_vld(chn_data_out_vld),
        .chn_data_out_rdy(chn_data_out_rdy),
        .chn_data_out(chn_data_out),
        .chn_data_out_sat(chn_data_out_sat)
    );

    // Clock
    initial begin
        nvdla_core_clk = 0;
        forever #5 nvdla_core_clk = ~nvdla_core_clk;
    end

    integer test_count;
    integer pass_count;

    initial begin
        test_count = 0;
        pass_count = 0;
        chn_data_in_vld = 0;
        chn_data_out_rdy = 1;
        cfg_precision = 2'b01;  // INT16
        cfg_alu_in = 32'd10;
        cfg_mul_in = 16'd2;
        cfg_truncate = 6'd4;

        nvdla_core_rstn = 0;
        #100;
        nvdla_core_rstn = 1;
        #50;

        // Test 1: Basic INT16 operation
        // Input: 100, ALU: -10, MUL: *2, TRUNCATE: >>4
        // ALU: 100-10=90, MUL: 90*2=180, TRUNCATE: 180>>4=11 (0xb)
        test_count = test_count + 1;
        chn_data_in = 50'd100;
        chn_data_in_vld = 1;
        @(posedge nvdla_core_clk);
        while (!chn_data_in_rdy) @(posedge nvdla_core_clk);
        chn_data_in_vld = 0;

        while (!chn_data_out_vld) @(posedge nvdla_core_clk);
        #1;
        if (chn_data_out == 16'hb) begin
            $display("PASS: Test 1 - OCVT result=%h (expected b)", chn_data_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - OCVT result=%h (expected b)", chn_data_out);
        end

        // Test 2: Another value
        // Input: 200, ALU: -10, MUL: *2, TRUNCATE: >>4
        // ALU: 200-10=190, MUL: 190*2=380, TRUNCATE: 380>>4=23 (0x17)
        test_count = test_count + 1;
        chn_data_in = 50'd200;
        chn_data_in_vld = 1;
        @(posedge nvdla_core_clk);
        while (!chn_data_in_rdy) @(posedge nvdla_core_clk);
        chn_data_in_vld = 0;

        while (!chn_data_out_vld) @(posedge nvdla_core_clk);
        #1;
        if (chn_data_out == 16'h17) begin
            $display("PASS: Test 2 - OCVT result=%h (expected 17)", chn_data_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - OCVT result=%h (expected 17)", chn_data_out);
        end

        $display("========================================");
        $display("CDP OCVT Reference Model Test Summary:");
        $display("  Total: %0d", test_count);
        $display("  Pass:  %0d", pass_count);
        $display("  Fail:  %0d", test_count - pass_count);
        $display("========================================");

        $finish;
    end

endmodule