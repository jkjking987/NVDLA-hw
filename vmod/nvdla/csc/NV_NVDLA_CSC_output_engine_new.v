// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CSC_output_engine_new.v
// Author        : Wolley RTL Team
// Author Email  : rtl@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CSC Output Engine module
// - Receives processed data from CACC (Convolution Accumulator)
// - Writes output feature maps to memory via SC2CBDP interface
// - Manages output surface dimensions and data formatting
// +FHDR------------------------------------------------------------

module NV_NVDLA_CSC_output_engine_new (
   nvdla_core_clk                 //|< i
  ,nvdla_core_rstn                //|< i
  ,reg2dp_op_en                   //|< i
  ,reg2dp_conv_mode               //|< i
  ,reg2dp_proc_precision          //|< i  [1:0]
  ,reg2dp_dataout_width           //|< i  [12:0]
  ,reg2dp_dataout_height          //|< i  [12:0]
  ,reg2dp_dataout_channel         //|< i  [12:0]
  ,reg2dp_atomics                 //|< i  [20:0]
  ,reg2dp_rls_slices              //|< i  [11:0]
  ,cacc2sc_dat_ready              //|< i
  ,cacc2sc_dat_pd                 //|< i
  ,cacc2sc_dat_valid              //|< i
  ,sc2cacc_dat_rdys               //|> o
  ,sc2cdp_dat_pvld                //|> o
  ,sc2cdp_dat_addr                //|> o  [31:0]
  ,sc2cdp_dat_pd                  //|> o
  ,sc2cdp_dat_ready               //|< i
  ,dp2reg_done                    //|> o
  );

//==========================================
// Parameters
//==========================================
parameter DATA_FORMAT_INT8  = 2'b00;
parameter DATA_FORMAT_INT16 = 2'b01;
parameter DATA_FORMAT_FP16  = 2'b10;

parameter CONV_MODE_DIRECT   = 1'b0;
parameter CONV_MODE_WINOGRAD  = 1'b1;

// State machine
parameter [2:0] ST_IDLE        = 3'd0;
parameter [2:0] ST_RECV_DATA   = 3'd1;
parameter [2:0] ST_SEND_DATA   = 3'd2;
parameter [2:0] ST_DONE        = 3'd3;

//==========================================
// Ports
//==========================================
input         nvdla_core_clk;
input         nvdla_core_rstn;
input         reg2dp_op_en;
input         reg2dp_conv_mode;
input  [1:0]  reg2dp_proc_precision;
input  [12:0] reg2dp_dataout_width;
input  [12:0] reg2dp_dataout_height;
input  [12:0] reg2dp_dataout_channel;
input  [20:0] reg2dp_atomics;
input  [11:0] reg2dp_rls_slices;

input         cacc2sc_dat_ready;
input  [511:0] cacc2sc_dat_pd;
input         cacc2sc_dat_valid;

output        sc2cacc_dat_rdys;
output        sc2cdp_dat_pvld;
output [31:0] sc2cdp_dat_addr;
output [511:0] sc2cdp_dat_pd;
input         sc2cdp_dat_ready;

output        dp2reg_done;

//==========================================
// Internal signals
//==========================================
// State machine
reg  [2:0] state_q;
reg  [2:0] next_state;

// Output dimensions
wire [12:0] cube_out_width;
wire [12:0] cube_out_height;
wire [12:0] cube_out_channel;
wire [31:0] output_surface_num;
wire [31:0] output_atom_num;
wire [31:0] atom_per_surface;

// Counters
reg  [12:0] surface_count;
reg  [31:0] atom_count_per_surface;
reg  [31:0] slice_release_count;
reg         operation_complete;

// Data path
reg         sc2cacc_dat_rdys;
reg         sc2cdp_dat_pvld;
reg  [511:0] sc2cdp_dat_pd;
reg  [31:0] sc2cdp_dat_addr;

// Done signal
reg         dp2reg_done_q;
reg         dp2reg_done;

// Credit tracking
reg  [7:0]  credit_count;
parameter CREDIT_INIT = 8'd16;

//==========================================
// Output cube calculations
//==========================================
assign cube_out_width[12:0]   = reg2dp_dataout_width[12:0] + 13'd1;
assign cube_out_height[12:0]  = reg2dp_dataout_height[12:0] + 13'd1;
assign cube_out_channel[12:0] = reg2dp_dataout_channel[12:0] + 13'd1;

// Output atom calculations
wire [31:0] element_per_atom;
assign element_per_atom[31:0] =
    (reg2dp_proc_precision == DATA_FORMAT_INT8)  ? 32'd64 :
    (reg2dp_proc_precision == DATA_FORMAT_INT16) ? 32'd32 :
    (reg2dp_proc_precision == DATA_FORMAT_FP16)   ? 32'd32 : 32'd32;

assign output_surface_num[31:0] = (cube_out_channel[12:0] + element_per_atom[31:0] - 1) / element_per_atom[31:0];
assign output_atom_num[31:0]    = cube_out_height[12:0] * cube_out_width[12:0];
assign atom_per_surface[31:0]   = output_atom_num[31:0];

//==========================================
// State machine - sequential
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_q[2:0] <= ST_IDLE;
  end else begin
    state_q[2:0] <= next_state[2:0];
  end
end

//==========================================
// State machine - combinational
//==========================================
always @(*) begin
  next_state[2:0] = state_q[2:0];
  case (state_q[2:0])
    ST_IDLE: begin
      if (reg2dp_op_en)
        next_state[2:0] = ST_RECV_DATA;
    end
    ST_RECV_DATA: begin
      if (operation_complete)
        next_state[2:0] = ST_DONE;
    end
    ST_DONE: begin
      next_state[2:0] = ST_IDLE;
    end
    default: next_state[2:0] = ST_IDLE;
  endcase
end

//==========================================
// Counter management
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    surface_count[12:0] <= 13'd0;
    atom_count_per_surface[31:0] <= 32'd0;
    slice_release_count[31:0] <= 32'd0;
    operation_complete <= 1'b0;
    credit_count[7:0] <= CREDIT_INIT;
  end else begin
    case (state_q[2:0])
      ST_IDLE: begin
        surface_count[12:0] <= 13'd0;
        atom_count_per_surface[31:0] <= 32'd0;
        slice_release_count[31:0] <= 32'd0;
        operation_complete <= 1'b0;
        credit_count[7:0] <= CREDIT_INIT;
      end
      ST_RECV_DATA: begin
        if (cacc2sc_dat_valid && sc2cacc_dat_rdys) begin
          atom_count_per_surface[31:0] <= atom_count_per_surface[31:0] + 32'd1;

          if (atom_count_per_surface[31:0] == (atom_per_surface[31:0] - 32'd1)) begin
            atom_count_per_surface[31:0] <= 32'd0;
            surface_count[12:0] <= surface_count[12:0] + 13'd1;
          end

          if (surface_count[12:0] == (output_surface_num[31:0] - 32'd1) &&
              atom_count_per_surface[31:0] == (atom_per_surface[31:0] - 32'd1)) begin
            operation_complete <= 1'b1;
          end

          credit_count[7:0] <= credit_count[7:0] - 8'd1;
        end

        if (credit_count[7:0] < CREDIT_INIT)
          credit_count[7:0] <= credit_count[7:0] + 8'd1;
      end
    endcase
  end
end

//==========================================
// Ready signal to CACC
//==========================================
always @(*) begin
  sc2cacc_dat_rdys = 1'b0;
  if (state_q[2:0] == ST_RECV_DATA && credit_count[7:0] > 8'd0) begin
    sc2cacc_dat_rdys = 1'b1;
  end
end

//==========================================
// Output address calculation
//==========================================
wire [31:0] surface_base_addr;
wire [31:0] atom_offset;
wire [31:0] surface_stride;
wire [12:0] surface_atom_coor;
wire [31:0] surface_atom_index;

assign surface_stride[31:0] = output_atom_num[31:0] * element_per_atom[31:0] / 32'd8;
assign surface_atom_coor[12:0] = atom_count_per_surface[31:0] % cube_out_width[12:0];
assign surface_atom_index[31:0] = atom_count_per_surface[31:0] / cube_out_width[12:0];

assign atom_offset[31:0] = (surface_atom_index[31:0] * cube_out_width[12:0] + surface_atom_coor[12:0]) * element_per_atom[31:0] / 32'd8;
assign sc2cdp_dat_addr[31:0] = surface_base_addr[31:0] + surface_count[12:0] * surface_stride[31:0] + atom_offset[31:0];

assign surface_base_addr[31:0] = 32'd0;  // Base address from register (future expansion)

//==========================================
// Data output to CDP
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    sc2cdp_dat_pvld <= 1'b0;
    sc2cdp_dat_pd[511:0] <= {512{1'b0}};
  end else begin
    sc2cdp_dat_pvld <= 1'b0;

    if (state_q[2:0] == ST_RECV_DATA && cacc2sc_dat_valid && sc2cacc_dat_rdys) begin
      sc2cdp_dat_pvld <= 1'b1;
      sc2cdp_dat_pd[511:0] <= cacc2sc_dat_pd[511:0];
    end
  end
end

//==========================================
// Done signal generation
//==========================================
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dp2reg_done_q <= 1'b0;
    dp2reg_done <= 1'b0;
  end else begin
    dp2reg_done_q <= operation_complete;
    dp2reg_done <= dp2reg_done_q;
  end
end

endmodule // NV_NVDLA_CSC_output_engine_new