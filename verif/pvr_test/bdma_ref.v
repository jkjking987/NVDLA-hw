// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : bdma_ref.v
// Author        : Claude
// Created On    : 2026/04/05
// -----------------------------------------------------------------
// Description:
//   Pure Verilog Reference Model for BDMA
//   Mimics the behavior of cmod/bdma/NV_NVDLA_bdma.cpp
// +FHDR------------------------------------------------------------

`timescale 1ns / 1ps

module bdma_ref (
    input nvdla_core_clk,
    input nvdla_core_rstn,

    // Configuration inputs
    input [31:0] cfg_src_addr,
    input [31:0] cfg_dst_addr,
    input [12:0] cfg_line_size,
    input [23:0] cfg_line_repeat,
    input [26:0] cfg_src_stride,
    input [26:0] cfg_dst_stride,
    input [23:0] cfg_surf_repeat,
    input [26:0] cfg_src_surf_stride,
    input [26:0] cfg_dst_surf_stride,
    input cfg_op_en,
    input cfg_trigger,

    // Status outputs
    output reg [31:0] status,
    output reg idle
);

    // State machine
    localparam ST_IDLE = 2'b00;
    localparam ST_RUNNING = 2'b01;
    localparam ST_DONE = 2'b10;

    reg [1:0] state_q;
    reg [1:0] next_state;

    reg [31:0] cur_src_addr;
    reg [31:0] cur_dst_addr;
    reg [23:0] line_cnt;
    reg [23:0] surf_cnt;

    // State register
    always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
        if (!nvdla_core_rstn) begin
            state_q <= ST_IDLE;
        end else begin
            state_q <= next_state;
        end
    end

    // Next state logic
    always @* begin
        next_state = state_q;
        case (state_q)
            ST_IDLE: begin
                if (cfg_op_en && cfg_trigger)
                    next_state = ST_RUNNING;
            end
            ST_RUNNING: begin
                if (line_cnt == cfg_line_repeat && surf_cnt == cfg_surf_repeat)
                    next_state = ST_DONE;
            end
            ST_DONE: begin
                next_state = ST_IDLE;
            end
            default: next_state = ST_IDLE;
        endcase
    end

    // Status
    always @* begin
        idle = (state_q == ST_IDLE);
        status = {28'b0, state_q};
    end

    // Simple reference behavior
    always @(posedge nvdla_core_clk) begin
        if (state_q == ST_IDLE && cfg_op_en && cfg_trigger) begin
            cur_src_addr <= cfg_src_addr;
            cur_dst_addr <= cfg_dst_addr;
            line_cnt <= 24'b0;
            surf_cnt <= 24'b0;
        end else if (state_q == ST_RUNNING) begin
            // Increment addresses
            if (line_cnt < cfg_line_repeat) begin
                cur_src_addr <= cur_src_addr + cfg_src_stride;
                cur_dst_addr <= cur_dst_addr + cfg_dst_stride;
                line_cnt <= line_cnt + 1;
            end else begin
                line_cnt <= 24'b0;
                surf_cnt <= surf_cnt + 1;
            end
        end
    end

endmodule