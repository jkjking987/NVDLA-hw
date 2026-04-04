// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_BDMA_load_new.v
// Author        : Wolley Hardware Team
// Author Email  : hwteam@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// BDMA Load Engine - reads data from external memory (MCIF/CVIF)
// based on configuration received via internal FIFO from register file.
// - Source address (cfg_src_addr_low/high)
// - Line size (cfg_line_size)
// - Line repeat count (cfg_line_repeat_number)
// - Source line stride (cfg_src_line_stride)
// - Surface repeat count (cfg_surf_repeat_number)
// - Source surface stride (cfg_src_surf_stride)
// - Source RAM type (cfg_cmd_src_ram_type)
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_load_new (
    nvdla_core_clk             //|< i
  , nvdla_core_rstn            //|< i
  // MCIF interface
  , bdma2mcif_rd_req_ready     //|< i
  , bdma2mcif_rd_req_valid     //|> o
  , bdma2mcif_rd_req_pd        //|> o
  // CVIF interface
  , bdma2cvif_rd_req_ready     //|< i
  , bdma2cvif_rd_req_valid     //|> o
  , bdma2cvif_rd_req_pd        //|> o
  // Store engine interface
  , ld2st_wr_idle              //|< i
  , ld2st_wr_prdy              //|< i
  , ld2st_wr_pvld              //|> o
  , ld2st_wr_pd                //|> o
  // Register file config FIFO interface
  , cfg2ld_vld                 //|< i
  , cfg2ld_rdy                 //|> o
  , cfg2ld_pd                  //|< i
  // Idle/status outputs
  , ld2csb_idle                //|> o
  , ld2gate_slcg_en           //|> o
  , ld2csb_grp0_dma_stall_inc  //|> o
  , ld2csb_grp1_dma_stall_inc //|> o
);

// +FHDR------------------------------------------------------------
// Parameter definitions
// +FHDR------------------------------------------------------------
parameter [2:0] ST_IDLE    = 3'd0;
parameter [2:0] ST_RUNNING  = 3'd1;
parameter [2:0] ST_DONE     = 3'd2;

// +FHDR------------------------------------------------------------
// Port declarations
// +FHDR------------------------------------------------------------
input  nvdla_core_clk;
input  nvdla_core_rstn;

// MCIF interface
input         bdma2mcif_rd_req_ready;
output        bdma2mcif_rd_req_valid;
output [78:0] bdma2mcif_rd_req_pd;

// CVIF interface
input         bdma2cvif_rd_req_ready;
output        bdma2cvif_rd_req_valid;
output [78:0] bdma2cvif_rd_req_pd;

// Store engine interface
input         ld2st_wr_idle;
input         ld2st_wr_prdy;
output        ld2st_wr_pvld;
output [160:0] ld2st_wr_pd;

// Register file config FIFO interface
input         cfg2ld_vld;
output        cfg2ld_rdy;
input  [151:0] cfg2ld_pd;

// Idle/status outputs
output        ld2csb_idle;
output        ld2gate_slcg_en;
output        ld2csb_grp0_dma_stall_inc;
output        ld2csb_grp1_dma_stall_inc;

// +FHDR------------------------------------------------------------
// Wire declarations (grouped by function)
// +FHDR------------------------------------------------------------

// Config fields from FIFO
wire [31:0]  cfg_src_addr_high_v8;
wire [26:0]  cfg_src_addr_low_v32;
wire [31:0]  cfg_dst_addr_high_v8;
wire [26:0]  cfg_dst_addr_low_v32;
wire [12:0]  cfg_line_size;
wire         cfg_cmd_src_ram_type;
wire         cfg_cmd_dst_ram_type;
wire [23:0]  cfg_line_repeat_number;
wire [26:0]  cfg_src_line_stride;
wire [26:0]  cfg_dst_line_stride;
wire [23:0]  cfg_surf_repeat_number;
wire [26:0]  cfg_src_surf_stride;
wire [26:0]  cfg_dst_surf_stride;
wire         cfg_cmd_interrupt;
wire         cfg_cmd_interrupt_ptr;

// Extended addresses
wire [63:0]  cfg_src_addr;
wire [63:0]  cfg_dst_addr;
wire [31:0]  cfg_src_line_stride_ext;
wire [31:0]  cfg_src_surf_stride_ext;

// Internal control signals
wire         cfg_valid;
wire         cfg_ready;
wire         cfg_accept;
wire         load_en;
wire         load_idle;

// Transaction generation
wire         tran_valid;
wire         tran_ready;
wire         tran_accept;
wire [63:0]  tran_addr;
wire [14:0]  tran_size;
wire         is_last_req_in_line;
wire         is_surf_end;
wire         is_cube_end;

// RAM type routing
wire         is_mcif_req;
wire         is_cvif_req;
wire         mcif_req_vld;
wire         cvif_req_vld;
wire         mcif_req_rdy;
wire         cvif_req_rdy;

// DMA stall tracking
wire         dma_stall_inc;

// +FHDR------------------------------------------------------------
// Reg declarations
// +FHDR------------------------------------------------------------

// State machine
reg  [2:0]   state_q;
reg  [2:0]   next_state;

// Config registers (latched on load_en)
reg  [12:0]  reg_line_size;
reg          reg_cmd_src_ram_type;
reg  [31:0]  reg_line_stride;
reg  [31:0]  reg_surf_stride;
reg  [23:0]  reg_line_repeat_number;
reg  [23:0]  reg_surf_repeat_number;
reg  [63:0]  reg_dst_addr;
reg  [63:0]  reg_src_addr;

// Transaction tracking
reg  [63:0]  line_addr;
reg  [63:0]  surf_addr;
reg  [23:0]  line_count;
reg  [23:0]  surf_count;
reg          mon_line_addr_c;
reg          mon_surf_addr_c;

// Internal valid-ready pipeline
reg          int_rd_req_valid;
reg  [78:0]  int_rd_req_pd;
wire         int_rd_req_ready;

// Output pipeline
reg          mc_rd_req_valid;
reg  [78:0]  mc_rd_req_pd;
reg          cv_rd_req_valid;
reg  [78:0]  cv_rd_req_pd;

// SLCG control
reg          ld2gate_slcg_en_q;

// +FHDR------------------------------------------------------------
// State machine - sequential register
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    state_q <= ST_IDLE;
  end else begin
    state_q <= next_state;
  end
end

// +FHDR------------------------------------------------------------
// State machine - combinational next state
// +FHDR------------------------------------------------------------
always @* begin
  next_state = state_q;
  case (state_q)
    ST_IDLE:    if (cfg_accept)        next_state = ST_RUNNING;
    ST_RUNNING: if (is_cube_end & tran_accept) next_state = ST_DONE;
    ST_DONE:                          next_state = ST_IDLE;
    default:                          next_state = ST_IDLE;
  endcase
end

// +FHDR------------------------------------------------------------
// Config FIFO interface
// +FHDR------------------------------------------------------------
assign cfg_valid = cfg2ld_vld;
assign cfg2ld_rdy = cfg_ready;
assign cfg_accept = cfg_valid & cfg_ready & load_idle;

// Unpack config from FIFO
assign cfg_src_addr_high_v8  = cfg2ld_pd[31:0];
assign cfg_src_addr_low_v32  = cfg2ld_pd[58:32];
assign cfg_dst_addr_high_v8  = cfg2ld_pd[90:59];
assign cfg_dst_addr_low_v32  = cfg2ld_pd[117:91];
assign cfg_line_size         = cfg2ld_pd[130:118];
assign cfg_cmd_src_ram_type  = cfg2ld_pd[131];
assign cfg_cmd_dst_ram_type  = cfg2ld_pd[132];
assign cfg_line_repeat_number = cfg2ld_pd[156:133];
assign cfg_src_line_stride   = cfg2ld_pd[183:157];
assign cfg_dst_line_stride   = cfg2ld_pd[210:184];
assign cfg_surf_repeat_number = cfg2ld_pd[234:211];
assign cfg_src_surf_stride   = cfg2ld_pd[261:235];
assign cfg_dst_surf_stride   = cfg2ld_pd[288:262];
assign cfg_cmd_interrupt     = cfg2ld_pd[289];
assign cfg_cmd_interrupt_ptr = cfg2ld_pd[290];

// Extended address calculation
assign cfg_src_addr[63:0] = {cfg_src_addr_high_v8[31:0], cfg_src_addr_low_v32[26:0], 5'd0};
assign cfg_dst_addr[63:0] = {cfg_dst_addr_high_v8[31:0], cfg_dst_addr_low_v32[26:0], 5'd0};
assign cfg_src_line_stride_ext[31:0] = {cfg_src_line_stride[26:0], 5'd0};
assign cfg_src_surf_stride_ext[31:0] = {cfg_src_surf_stride[26:0], 5'd0};

// +FHDR------------------------------------------------------------
// Load idle and enable logic
// +FHDR------------------------------------------------------------
assign load_idle = (state_q == ST_IDLE) & ld2st_wr_idle & !tran_valid;
assign ld2csb_idle = load_idle;

// SLCG generation
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    ld2gate_slcg_en_q <= 1'b0;
  end else begin
    ld2gate_slcg_en_q <= !load_idle;
  end
end
assign ld2gate_slcg_en = ld2gate_slcg_en_q;

// Config ready signal - allow new config when idle
assign cfg_ready = load_idle;

// Load enable - when we accept a new config
assign load_en = cfg_accept;

// +FHDR------------------------------------------------------------
// Config registers - latch config values when load starts
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg_line_size            <= 13'd0;
    reg_cmd_src_ram_type     <= 1'b0;
    reg_line_stride          <= 32'd0;
    reg_surf_stride          <= 32'd0;
    reg_line_repeat_number   <= 24'd0;
    reg_surf_repeat_number   <= 24'd0;
    reg_dst_addr             <= 64'd0;
    reg_src_addr             <= 64'd0;
  end else begin
    if (load_en) begin
      reg_line_size            <= {{13{1'b0}}, cfg_line_size[12:0]};
      reg_cmd_src_ram_type     <= cfg_cmd_src_ram_type;
      reg_line_stride          <= {{5{1'b0}}, cfg_src_line_stride_ext[31:5]};
      reg_surf_stride          <= {{5{1'b0}}, cfg_src_surf_stride_ext[31:5]};
      reg_line_repeat_number   <= cfg_line_repeat_number[23:0];
      reg_surf_repeat_number   <= cfg_surf_repeat_number[23:0];
      reg_dst_addr             <= cfg_dst_addr;
      reg_src_addr             <= cfg_src_addr;
    end
  end
end

// +FHDR------------------------------------------------------------
// Transaction tracking - line and surface counters
// +FHDR------------------------------------------------------------
assign is_last_req_in_line = 1'b1;  // Single transaction per line for now
assign is_surf_end = is_last_req_in_line & (line_count == reg_line_repeat_number);
assign is_cube_end = is_surf_end & (surf_count == reg_surf_repeat_number);

// Line address - updated on each transaction accept
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    line_addr <= 64'd0;
  end else begin
    if (load_en) begin
      line_addr <= cfg_src_addr;
    end else if (tran_accept) begin
      if (is_surf_end) begin
        {mon_line_addr_c, line_addr} <= surf_addr + reg_surf_stride;
      end else begin
        {mon_line_addr_c, line_addr} <= line_addr + reg_line_stride;
      end
    end
  end
end

// Surface address - base address for each surface
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    surf_addr <= 64'd0;
    {mon_surf_addr_c, surf_addr} <= 65'd0;
  end else begin
    if (load_en) begin
      surf_addr <= cfg_src_addr;
    end else if (tran_accept) begin
      if (is_surf_end) begin
        {mon_surf_addr_c, surf_addr} <= surf_addr + reg_surf_stride;
      end
    end
  end
end

// Line counter
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    line_count <= 24'd0;
  end else begin
    if (load_en) begin
      line_count <= 24'd0;
    end else if (tran_accept) begin
      if (is_surf_end) begin
        line_count <= 24'd0;
      end else begin
        line_count <= line_count + 24'd1;
      end
    end
  end
end

// Surface counter
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    surf_count <= 24'd0;
  end else begin
    if (load_en) begin
      surf_count <= 24'd0;
    end else if (tran_accept) begin
      if (is_cube_end) begin
        surf_count <= 24'd0;
      end else if (is_surf_end) begin
        surf_count <= surf_count + 24'd1;
      end
    end
  end
end

// +FHDR------------------------------------------------------------
// Transaction generation
// +FHDR------------------------------------------------------------
assign tran_valid = (state_q == ST_RUNNING);
assign tran_addr  = line_addr;
assign tran_size  = {{2{1'b0}}, reg_line_size[12:0]};

// +FHDR------------------------------------------------------------
// RAM type routing
// +FHDR------------------------------------------------------------
assign is_mcif_req = (reg_cmd_src_ram_type == 1'b1);
assign is_cvif_req = (reg_cmd_src_ram_type == 1'b0);

assign mcif_req_vld = tran_valid & is_mcif_req;
assign cvif_req_vld = tran_valid & is_cvif_req;

assign mcif_req_rdy = bdma2mcif_rd_req_ready;
assign cvif_req_rdy = bdma2cvif_rd_req_ready;

// +FHDR------------------------------------------------------------
// DMA request pipeline
// +FHDR------------------------------------------------------------

// First stage: internal valid/ready handshake
assign tran_ready = int_rd_req_ready;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    int_rd_req_valid <= 1'b0;
    int_rd_req_pd    <= 79'd0;
  end else begin
    int_rd_req_valid <= tran_valid & tran_ready;
    int_rd_req_pd    <= {15'd0, tran_addr[63:0]};  // Pack: addr[63:0], size[14:0]
  end
end

// Second stage: split by RAM type to MCIF/CVIF
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mc_rd_req_valid <= 1'b0;
    mc_rd_req_pd    <= 79'd0;
    cv_rd_req_valid <= 1'b0;
    cv_rd_req_pd    <= 79'd0;
  end else begin
    if (is_mcif_req & int_rd_req_valid & int_rd_req_ready) begin
      mc_rd_req_valid <= 1'b1;
      mc_rd_req_pd    <= int_rd_req_pd;
    end else if (mcif_req_rdy) begin
      mc_rd_req_valid <= 1'b0;
    end

    if (is_cvif_req & int_rd_req_valid & int_rd_req_ready) begin
      cv_rd_req_valid <= 1'b1;
      cv_rd_req_pd    <= int_rd_req_pd;
    end else if (cvif_req_rdy) begin
      cv_rd_req_valid <= 1'b0;
    end
  end
end

// Third stage: output assignment
assign bdma2mcif_rd_req_valid = mc_rd_req_valid;
assign bdma2mcif_rd_req_pd    = mc_rd_req_pd;
assign bdma2cvif_rd_req_valid = cv_rd_req_valid;
assign bdma2cvif_rd_req_pd    = cv_rd_req_pd;

assign int_rd_req_ready = (is_mcif_req & mcif_req_rdy) | (is_cvif_req & cvif_req_rdy);

// +FHDR------------------------------------------------------------
// Store engine data path
// +FHDR------------------------------------------------------------
assign ld2st_wr_pvld = load_en;

// Pack ld2st_wr_pd: dst_addr[63:0], line_size[12:0], cmd fields, strides, repeat counts
assign ld2st_wr_pd[63:0]     = reg_dst_addr[63:0];
assign ld2st_wr_pd[76:64]    = reg_line_size[12:0];
assign ld2st_wr_pd[77]       = reg_cmd_src_ram_type;
assign ld2st_wr_pd[78]       = cfg_cmd_dst_ram_type;  // from current config
assign ld2st_wr_pd[79]       = cfg_cmd_interrupt;
assign ld2st_wr_pd[80]       = cfg_cmd_interrupt_ptr;
assign ld2st_wr_pd[107:81]   = cfg_dst_line_stride[26:0];
assign ld2st_wr_pd[120:108]  = reg_line_repeat_number[12:0];
assign ld2st_wr_pd[147:121]  = cfg_dst_surf_stride[26:0];
assign ld2st_wr_pd[160:148]  = reg_surf_repeat_number[12:0];

// +FHDR------------------------------------------------------------
// Stall tracking
// +FHDR------------------------------------------------------------
assign dma_stall_inc = tran_valid & !tran_ready;
assign ld2csb_grp0_dma_stall_inc = dma_stall_inc & (cfg_cmd_interrupt_ptr == 1'b0);
assign ld2csb_grp1_dma_stall_inc = dma_stall_inc & (cfg_cmd_interrupt_ptr == 1'b1);

// +FHDR------------------------------------------------------------
// Assertions
// +FHDR------------------------------------------------------------
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON

// No X's allowed on control signals
`ifndef SYNTHESIS
  // VCS coverage off
  nv_assert_no_x #(0, 1, 0, "No X's allowed on control signals")
    zzz_assert_no_x_ctrl (nvdla_core_clk, `ASSERT_RESET, 1'd1, (^cfg_ready));
  // VCS coverage on
`endif

// Line address overlap check
`ifndef SYNTHESIS
  // VCS coverage off
  nv_assert_never #(0, 0, "Line Address is overlapped within one single command")
    zzz_assert_never_line_overlap (nvdla_core_clk, `ASSERT_RESET, (reg_line_size << 5) > reg_line_stride);
  // VCS coverage on
`endif

`undef ASSERT_RESET
`endif // ASSERT_ON

endmodule // NV_NVDLA_BDMA_load_new