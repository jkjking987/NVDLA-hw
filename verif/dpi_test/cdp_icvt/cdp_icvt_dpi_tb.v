// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : cdp_icvt_dpi_tb.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   DPI Testbench for CDP ICVT
//   Compares RTL output with C reference model
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

// Import DPI function
import "DPI-C" function void cdp_icvt_ref(
    input int data_in,
    input int alu_in,
    input int mul_in,
    input int truncate,
    output int data_out
);

module cdp_icvt_dpi_tb;

    reg nvdla_core_clk;
    reg nvdla_core_rstn;

    // Input interface (matching RTL)
    reg in_data_pvld;
    wire in_data_prdy;
    reg [15:0] in_data_pd;

    // Configuration
    reg [15:0] cfg_alu_in;
    reg [15:0] cfg_mul_in;
    reg [4:0] cfg_truncate;
    reg [1:0] cfg_precision;

    // Output interface (matching RTL)
    wire out_data_pvld;
    reg out_data_prdy;
    wire [17:0] out_data_pd;

    // DPI reference result
    int dpi_result;

    // DUT - use actual RTL module name
    NV_NVDLA_CDP_icvt_new dut (
        .nvdla_core_clk(nvdla_core_clk),
        .nvdla_core_rstn(nvdla_core_rstn),
        .in_data_pvld(in_data_pvld),
        .in_data_prdy(in_data_prdy),
        .in_data_pd(in_data_pd),
        .cfg_alu_in(cfg_alu_in),
        .cfg_mul_in(cfg_mul_in),
        .cfg_truncate(cfg_truncate),
        .cfg_precision(cfg_precision),
        .out_data_pvld(out_data_pvld),
        .out_data_prdy(out_data_prdy),
        .out_data_pd(out_data_pd)
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
        in_data_pvld = 0;
        out_data_prdy = 1;
        cfg_precision = 2'b01;  // INT16
        cfg_alu_in = 16'd10;
        cfg_mul_in = 16'd2;
        cfg_truncate = 5'd4;

        nvdla_core_rstn = 0;
        #100;
        nvdla_core_rstn = 1;
        #50;

        // Test 1: INT16 operation
        // ALU: 100-10=90, MUL: 90*2=180, TRUNCATE: 180>>4=11 (0xb)
        test_count = test_count + 1;
        in_data_pd = 16'd100;
        in_data_pvld = 1;
        @(posedge nvdla_core_clk);
        while (!in_data_prdy) @(posedge nvdla_core_clk);
        in_data_pvld = 0;

        // Call DPI reference
        cdp_icvt_ref(32'd100, 32'd10, 32'd2, 32'd4, dpi_result);

        while (!out_data_pvld) @(posedge nvdla_core_clk);
        #1;
        if (out_data_pd[15:0] == (dpi_result & 16'hFFFF)) begin
            $display("PASS: Test 1 - RTL=%h DPI=%h", out_data_pd[15:0], dpi_result);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - RTL=%h DPI=%h", out_data_pd[15:0], dpi_result);
        end

        // Test 2: Another value
        // ALU: 200-10=190, MUL: 190*2=380, TRUNCATE: 380>>4=23 (0x17)
        test_count = test_count + 1;
        in_data_pd = 16'd200;
        in_data_pvld = 1;
        @(posedge nvdla_core_clk);
        while (!in_data_prdy) @(posedge nvdla_core_clk);
        in_data_pvld = 0;

        // Call DPI reference
        cdp_icvt_ref(32'd200, 32'd10, 32'd2, 32'd4, dpi_result);

        while (!out_data_pvld) @(posedge nvdla_core_clk);
        #1;
        if (out_data_pd[15:0] == (dpi_result & 16'hFFFF)) begin
            $display("PASS: Test 2 - RTL=%h DPI=%h", out_data_pd[15:0], dpi_result);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - RTL=%h DPI=%h", out_data_pd[15:0], dpi_result);
        end

        $display("========================================");
        $display("CDP ICVT DPI Verification Summary:");
        $display("  Total: %0d", test_count);
        $display("  Pass:  %0d", pass_count);
        $display("  Fail:  %0d", test_count - pass_count);
        $display("========================================");

        $finish;
    end

endmodule
