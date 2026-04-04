// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : bdma_ref_tb.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Testbench for BDMA Reference Model
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module bdma_ref_tb;

    reg nvdla_core_clk;
    reg nvdla_core_rstn;
    reg [31:0] cfg_src_addr;
    reg [31:0] cfg_dst_addr;
    reg [12:0] cfg_line_size;
    reg [23:0] cfg_line_repeat;
    reg [26:0] cfg_src_stride;
    reg [26:0] cfg_dst_stride;
    reg [23:0] cfg_surf_repeat;
    reg [26:0] cfg_src_surf_stride;
    reg [26:0] cfg_dst_surf_stride;
    reg cfg_op_en;
    reg cfg_trigger;
    wire [31:0] status;
    wire idle;

    // DUT
    bdma_ref dut (
        .nvdla_core_clk(nvdla_core_clk),
        .nvdla_core_rstn(nvdla_core_rstn),
        .cfg_src_addr(cfg_src_addr),
        .cfg_dst_addr(cfg_dst_addr),
        .cfg_line_size(cfg_line_size),
        .cfg_line_repeat(cfg_line_repeat),
        .cfg_src_stride(cfg_src_stride),
        .cfg_dst_stride(cfg_dst_stride),
        .cfg_surf_repeat(cfg_surf_repeat),
        .cfg_src_surf_stride(cfg_src_surf_stride),
        .cfg_dst_surf_stride(cfg_dst_surf_stride),
        .cfg_op_en(cfg_op_en),
        .cfg_trigger(cfg_trigger),
        .status(status),
        .idle(idle)
    );

    // Clock
    initial begin
        nvdla_core_clk = 0;
        forever #5 nvdla_core_clk = ~nvdla_core_clk;
    end

    // Test
    integer test_count;
    integer pass_count;
    initial begin
        test_count = 0;
        pass_count = 0;

        nvdla_core_rstn = 0;
        cfg_src_addr = 0;
        cfg_dst_addr = 0;
        cfg_line_size = 0;
        cfg_line_repeat = 0;
        cfg_src_stride = 0;
        cfg_dst_stride = 0;
        cfg_surf_repeat = 0;
        cfg_src_surf_stride = 0;
        cfg_dst_surf_stride = 0;
        cfg_op_en = 0;
        cfg_trigger = 0;

        #100;
        nvdla_core_rstn = 1;
        #50;

        // Test 1: IDLE state
        test_count = test_count + 1;
        if (idle == 1) begin
            $display("PASS: Test 1 - IDLE state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - Expected IDLE=1, got %b", idle);
        end

        // Test 2: Start transfer
        test_count = test_count + 1;
        cfg_src_addr = 32'h1000;
        cfg_dst_addr = 32'h2000;
        cfg_line_size = 13'd100;
        cfg_line_repeat = 24'd10;
        cfg_src_stride = 27'd100;
        cfg_dst_stride = 27'd100;
        cfg_surf_repeat = 24'd1;
        cfg_src_surf_stride = 27'd1000;
        cfg_dst_surf_stride = 27'd1000;
        cfg_op_en = 1;
        cfg_trigger = 1;
        #10;
        cfg_trigger = 0;

        #100;
        if (idle == 0) begin
            $display("PASS: Test 2 - BUSY state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - Expected BUSY, got %b", idle);
        end

        // Wait for completion
        #10000;

        // Summary
        $display("========================================");
        $display("BDMA Reference Model Test Summary:");
        $display("  Total: %0d", test_count);
        $display("  Pass:  %0d", pass_count);
        $display("  Fail:  %0d", test_count - pass_count);
        $display("========================================");

        if (pass_count == test_count)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule