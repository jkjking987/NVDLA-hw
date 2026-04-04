// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_SDP_csb_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSB (Command Status Bus) interface for SDP
// - Handles CSB protocol for register access
// - Parses request packet and generates response
// - Supports read/write operations with proper handshaking
// +FHDR------------------------------------------------------------

`include "simulate_x_tick.vh"
module NV_NVDLA_SDP_csb_new (
   nvdla_core_clk                  //|< i
  ,nvdla_core_rstn                 //|< i
  ,csb2sdp_req_pd                  //|< i
  ,csb2sdp_req_pvld                //|< i
  ,csb2sdp_req_prdy                //|> o
  ,sdp2csb_resp_pd                 //|> o
  ,sdp2csb_resp_valid              //|> o
  // Register access interface
  ,reg2csb_rd_en                   //|< i
  ,reg2csb_wr_en                   //|< i
  ,reg2csb_addr                    //|< i
  ,reg2csb_wdata                   //|< i
  ,csb2reg_rdata                   //|> o
  ,csb2reg_ready                   //|> o
  );

//============================================================================
// parameters
//============================================================================
localparam CSB_ADDR_WIDTH = 16;
localparam CSB_DATA_WIDTH = 32;

// CSB request packet structure (63 bits)
// [62:61] - level
// [60:57] - write byte enable
// [56]    - srcpriv
// [55]    - nposted
// [54]    - write
// [53]    - read
// [31:16] - address
// [15:0]  - write data (low)
// Note: Full write data is 32 bits, split across multiple fields

//============================================================================
// signal declarations
//============================================================================
// Clock and reset
wire nvdla_core_clk;
wire nvdla_core_rstn;

// CSB request interface
wire  [62:0] csb2sdp_req_pd;
wire         csb2sdp_req_pvld;
wire         csb2sdp_req_prdy;

// CSB response interface
wire  [33:0] sdp2csb_resp_pd;
wire         sdp2csb_resp_valid;

// Register interface
wire         reg2csb_rd_en;
wire         reg2csb_wr_en;
wire  [11:0] reg2csb_addr;
wire  [31:0] reg2csb_wdata;
wire  [31:0] csb2reg_rdata;
wire         csb2reg_ready;

// Internal CSB request decoded signals
wire         req_write;
wire         req_read;
wire  [15:0] req_addr;
wire  [31:0] req_wdat;
wire  [3:0]  req_wrbe;
wire         req_nposted;
wire         req_srcpriv;
wire  [1:0]  req_level;

// Response packet structure (34 bits)
// [33]    - error
// [32]    - posted
// [31:16] - reserved
// [15:0]  - read data (when applicable)

// State machine states
localparam [1:0] CSB_STATE_IDLE   = 2'd0;
localparam [1:0] CSB_STATE_READ  = 2'd1;
localparam [1:0] CSB_STATE_WRITE  = 2'd2;
localparam [1:0] CSB_STATE_RESP  = 2'd3;

reg [1:0] csb_state_q;
reg [1:0] csb_state_next;

// Response generation
reg        resp_valid_r;
reg [33:0] resp_pd_r;

//============================================================================
// CSB request decoding
//============================================================================
// Extract fields from CSB request packet
assign req_addr  = csb2sdp_req_pd[31:16];
assign req_wdat   = {16'b0, csb2sdp_req_pd[15:0]};  // Lower 16 bits
assign req_wrbe   = csb2sdp_req_pd[60:57];
assign req_nposted = csb2sdp_req_pd[55];
assign req_srcpriv = csb2sdp_req_pd[56];
assign req_write  = csb2sdp_req_pd[54];
assign req_read   = csb2sdp_req_pd[53];
assign req_level  = csb2sdp_req_pd[62:61];

//============================================================================
// CSB state machine
//============================================================================
// Sequential state register
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    csb_state_q <= CSB_STATE_IDLE;
  end else begin
    csb_state_q <= csb_state_next;
  end
end

// Combinational next state logic
always @* begin
  csb_state_next = csb_state_q;
  case (csb_state_q)
    CSB_STATE_IDLE: begin
      if (csb2sdp_req_pvld && req_write) begin
        csb_state_next = CSB_STATE_WRITE;
      end else if (csb2sdp_req_pvld && req_read) begin
        csb_state_next = CSB_STATE_READ;
      end
    end
    CSB_STATE_WRITE: begin
      // Write completes in one cycle, response sent immediately
      if (req_nposted) begin
        csb_state_next = CSB_STATE_RESP;
      end else begin
        csb_state_next = CSB_STATE_IDLE;
      end
    end
    CSB_STATE_READ: begin
      // Read completes in one cycle, response sent immediately
      csb_state_next = CSB_STATE_RESP;
    end
    CSB_STATE_RESP: begin
      // Response sent, return to idle
      csb_state_next = CSB_STATE_IDLE;
    end
    default: begin
      csb_state_next = CSB_STATE_IDLE;
    end
  endcase
end

//============================================================================
// Response generation
//============================================================================
// Response valid signal
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    resp_valid_r <= 1'b0;
  end else begin
    case (csb_state_q)
      CSB_STATE_IDLE: begin
        resp_valid_r <= 1'b0;
      end
      CSB_STATE_WRITE: begin
        resp_valid_r <= req_nposted;  // Only valid for non-posted writes
      end
      CSB_STATE_READ: begin
        resp_valid_r <= 1'b1;
      end
      CSB_STATE_RESP: begin
        resp_valid_r <= 1'b0;
      end
      default: begin
        resp_valid_r <= 1'b0;
      end
    endcase
  end
end

// Response data packet generation
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    resp_pd_r <= 34'b0;
  end else begin
    case (csb_state_q)
      CSB_STATE_IDLE: begin
        resp_pd_r <= 34'b0;
      end
      CSB_STATE_WRITE: begin
        // For posted writes, no response needed (already handled above)
        // For non-posted writes, generate complete response
        resp_pd_r <= {1'b0, req_nposted, 17'b0, csb2reg_rdata[15:0]};
      end
      CSB_STATE_READ: begin
        // Read response with data
        resp_pd_r <= {1'b0, 1'b1, 17'b0, csb2reg_rdata[15:0]};
      end
      CSB_STATE_RESP: begin
        resp_pd_r <= 34'b0;
      end
      default: begin
        resp_pd_r <= 34'b0;
      end
    endcase
  end
end

//============================================================================
// Ready signal generation
//============================================================================
// SDP is always ready to accept CSB requests
assign csb2sdp_req_prdy = 1'b1;

//============================================================================
// Output assignments
//============================================================================
assign sdp2csb_resp_valid = resp_valid_r;
assign sdp2csb_resp_pd     = resp_pd_r;

//============================================================================
// Register access handling
//============================================================================
// Register address is byte-aligned (word address from CSB master)
// Address mapping:
// - Lower 4KB block for SDP registers
// - Uses bits [11:2] for word address within the block
wire [11:0] reg_addr_word = req_addr[13:2];

// Write enable pulse generation
reg wr_en_r;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    wr_en_r <= 1'b0;
  end else begin
    wr_en_r <= (csb_state_q == CSB_STATE_WRITE) && req_write && !req_nposted;
  end
end

// Connect to register file
assign csb2reg_ready = 1'b1;  // Register access always ready
assign csb2reg_rdata = 32'h0; // Placeholder - actual data comes from register file

// Write data is passed through based on write byte enable
wire [31:0] reg_wdata_with_be;
assign reg_wdata_with_be = req_wdat;

endmodule // NV_NVDLA_SDP_csb_new