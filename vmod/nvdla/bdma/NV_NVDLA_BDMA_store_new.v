// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_BDMA_store_new.v
// Author        : Wolley Hardware Team
// Author Email  : hwteam@wolley.com
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// BDMA Store Engine - writes data to external memory (MCIF/CVIF)
// based on configuration received from load engine via ld2st interface.
// - Destination address (cfg_dst_addr_low/high)
// - Line size (cfg_line_size)
// - Line repeat count (cfg_line_repeat_number)
// - Destination line stride (cfg_dst_line_stride)
// - Surface repeat count (cfg_surf_repeat_number)
// - Destination surface stride (cfg_dst_surf_stride)
// - Destination RAM type (cfg_cmd_dst_ram_type)
//
// Data Flow:
// 1. Receives config+data info from load engine via ld2st_rd interface
// 2. Stores incoming DMA read responses in latency FIFO
// 3. Generates DMA write requests to MCIF/CVIF
// 4. Handles write response and generates interrupts
// -----------------------------------------------------------------
// +FHDR------------------------------------------------------------

module NV_NVDLA_BDMA_store_new (
    nvdla_core_clk                 //|< i
  , nvdla_core_rstn               //|< i
  // MCIF write interface
  , bdma2mcif_wr_req_ready        //|< i
  , bdma2mcif_wr_req_valid        //|> o
  , bdma2mcif_wr_req_pd           //|> o
  // CVIF write interface
  , bdma2cvif_wr_req_ready        //|< i
  , bdma2cvif_wr_req_valid        //|> o
  , bdma2cvif_wr_req_pd           //|> o
  // MCIF read response (data from memory)
  , mcif2bdma_rd_rsp_valid        //|< i
  , mcif2bdma_rd_rsp_ready        //|> o
  , mcif2bdma_rd_rsp_pd           //|< i
  // CVIF read response (data from memory)
  , cvif2bdma_rd_rsp_valid        //|< i
  , cvif2bdma_rd_rsp_ready        //|> o
  , cvif2bdma_rd_rsp_pd           //|< i
  // Write responses
  , mcif2bdma_wr_rsp_complete     //|< i
  , cvif2bdma_wr_rsp_complete     //|< i
  // Load engine interface (receives config+data info)
  , ld2st_rd_pvld                 //|< i
  , ld2st_rd_prdy                 //|> o
  , ld2st_rd_pd                   //|< i
  // Credit latency fifo pop
  , bdma2mcif_rd_cdt_lat_fifo_pop //|> o
  , bdma2cvif_rd_cdt_lat_fifo_pop //|> o
  // Status outputs
  , st2csb_idle                   //|> o
  , st2csb_grp0_done              //|> o
  , st2csb_grp1_done              //|> o
  , st2gate_slcg_en              //|> o
  , st2ld_load_idle              //|> o
  , dma_write_stall_count         //|> o
  , dma_write_stall_count_cen     //|< i
  , pwrbus_ram_pd                 //|< i
);

// +FHDR------------------------------------------------------------
// Parameter definitions
// +FHDR------------------------------------------------------------
parameter [2:0] ST_IDLE    = 3'd0;
parameter [2:0] ST_RUNNING = 3'd1;
parameter [2:0] ST_DONE    = 3'd2;

// +FHDR------------------------------------------------------------
// Port declarations
// +FHDR------------------------------------------------------------
input  nvdla_core_clk;
input  nvdla_core_rstn;

// MCIF write interface
input         bdma2mcif_wr_req_ready;
output        bdma2mcif_wr_req_valid;
output [514:0] bdma2mcif_wr_req_pd;

// CVIF write interface
input         bdma2cvif_wr_req_ready;
output        bdma2cvif_wr_req_valid;
output [514:0] bdma2cvif_wr_req_pd;

// MCIF read response
input         mcif2bdma_rd_rsp_valid;
output        mcif2bdma_rd_rsp_ready;
input  [513:0] mcif2bdma_rd_rsp_pd;

// CVIF read response
input         cvif2bdma_rd_rsp_valid;
output        cvif2bdma_rd_rsp_ready;
input  [513:0] cvif2bdma_rd_rsp_pd;

// Write responses
input         mcif2bdma_wr_rsp_complete;
input         cvif2bdma_wr_rsp_complete;

// Load engine interface
input         ld2st_rd_pvld;
output        ld2st_rd_prdy;
input  [160:0] ld2st_rd_pd;

// Credit latency fifo pop
output        bdma2mcif_rd_cdt_lat_fifo_pop;
output        bdma2cvif_rd_cdt_lat_fifo_pop;

// Status outputs
output        st2csb_idle;
output        st2csb_grp0_done;
output        st2csb_grp1_done;
output        st2gate_slcg_en;
output        st2ld_load_idle;
output [31:0] dma_write_stall_count;
input         dma_write_stall_count_cen;
input  [31:0] pwrbus_ram_pd;

// +FHDR------------------------------------------------------------
// Wire declarations (grouped by function)
// +FHDR------------------------------------------------------------

// Config fields from ld2st_rd_pd
wire [63:0]   cfg_dst_addr;
wire [12:0]   cfg_line_size;
wire          cfg_cmd_src_ram_type;
wire          cfg_cmd_dst_ram_type;
wire          cfg_cmd_interrupt;
wire          cfg_cmd_interrupt_ptr;
wire [26:0]   cfg_dst_line_stride;
wire [12:0]   cfg_line_repeat_number;
wire [26:0]   cfg_dst_surf_stride;
wire [12:0]   cfg_surf_repeat_number;

// Extended addresses/strides
wire [31:0]   cfg_dst_line_stride_ext;
wire [31:0]   cfg_dst_surf_stride_ext;

// Internal control signals
wire          cfg_valid;
wire          cfg_ready;
wire          cfg_accept;
wire          store_en;
wire          store_idle;
wire          tran_cmd_valid;
wire          is_last_beat;
wire          is_surf_last;
wire          is_cube_last;

// Data path signals
wire          dma_rd_rsp_vld;
wire          dma_rd_rsp_rdy;
wire [513:0]  dma_rd_rsp_pd;
wire          dma_rd_rsp_ram_type;
wire          dma_wr_dat_pvld;
wire          dma_wr_dat_rdy;
wire [513:0]  dma_wr_dat_data;
wire [1:0]    dma_wr_dat_mask;

// Transaction generation
wire          tran_cmd_accept;
wire          tran_dat_accept;
wire          cmd_en;
wire          dat_en;
wire [63:0]   line_addr;
wire [63:0]   surf_addr;
wire [12:0]   beat_count;
wire [12:0]   beat_size;
wire [11:0]   line_count;
wire [11:0]   surf_count;
wire          mon_line_addr_c;
wire          mon_surf_addr_c;

// RAM type routing
wire          is_mcif_wr;
wire          is_cvif_wr;
wire          mcif_wr_req_vld;
wire          cvif_wr_req_vld;
wire          mcif_wr_req_rdy;
wire          cvif_wr_req_rdy;
wire          wr_req_rdyi;
wire          mc_wr_req_rdyi;
wire          cv_wr_req_rdyi;

// DMA write request
wire          dma_wr_req_vld;
wire          dma_wr_req_rdy;
wire [514:0]  dma_wr_req_pd;
wire          dma_wr_req_ram_type;

// Write response handling
wire          ack_raw_vld;
wire          ack_raw_id;
wire          ack_raw_rdy;
wire          ack_bot_rdy;
wire          ack_top_rdy;
wire          releasing;
wire          mc_releasing;
wire          cv_releasing;
wire          mc_pending;
wire          cv_pending;
wire          mc_dma_wr_rsp_complete;
wire          cv_dma_wr_rsp_complete;
wire          dma_wr_rsp_complete;
wire          require_ack;

// Interrupt handling
wire          fifo_intr_wr_idle;
wire          fifo_intr_wr_pvld;
wire          fifo_intr_wr_pd;
wire          fifo_intr_rd_prdy;
wire          fifo_intr_rd_pvld;
wire          fifo_intr_rd_pd;
wire          grp0_done;
wire          grp1_done;

// Stall count
wire          dma_write_stall_count_inc;
wire          dma_write_stall_count_dec;
wire          stl_adv;
wire [33:0]   stl_cnt_cur;
wire [33:0]   stl_cnt_ext;
wire [33:0]   stl_cnt_inc;
wire [33:0]   stl_cnt_dec;
wire [33:0]   stl_cnt_mod;
wire [33:0]   stl_cnt_new;
wire [33:0]   stl_cnt_nxt;

// Internal pipeline signals
wire          int_wr_req_valid;
wire          int_wr_req_ready;
wire [514:0]  int_wr_req_pd;
wire          mc_int_wr_req_valid;
wire          mc_int_wr_req_ready;
wire [514:0]  mc_int_wr_req_pd;
wire          cv_int_wr_req_valid;
wire          cv_int_wr_req_ready;
wire [514:0]  cv_int_wr_req_pd;

// +FHDR------------------------------------------------------------
// Reg declarations
// +FHDR------------------------------------------------------------

// State machine
reg  [2:0]   state_q;
reg  [2:0]   next_state;

// Config registers
reg  [12:0]  reg_line_size;
reg          reg_cmd_dst_ram_type;
reg  [12:0]  reg_line_repeat_number;
reg  [12:0]  reg_surf_repeat_number;
reg  [31:0]  reg_line_stride;
reg  [31:0]  reg_surf_stride;
reg          reg_cmd_interrupt;
reg          reg_cmd_interrupt_ptr;

// Address registers
reg  [63:0]  line_addr_q;
reg  [63:0]  surf_addr_q;
reg  [11:0]  line_count_q;
reg  [11:0]  surf_count_q;
reg          mon_line_addr_c_q;
reg          mon_surf_addr_c_q;

// Beat tracking
reg  [12:0]  beat_count_q;

// Control flags
reg          cmd_en_q;
reg          dat_en_q;
reg          tran_cmd_valid_q;

// ACK tracking
reg          ack_bot_id;
reg          ack_bot_vld;
reg          ack_top_id;
reg          ack_top_vld;

// Write response tracking
reg          mc_dma_wr_rsp_complete_q;
reg          cv_dma_wr_rsp_complete_q;
reg          dma_wr_rsp_complete_q;
reg          mc_pending_q;
reg          cv_pending_q;

// SLCG control
reg          st2gate_slcg_en_q;

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
    ST_IDLE:    if (cfg_accept)           next_state = ST_RUNNING;
    ST_RUNNING: if (is_cube_last & tran_dat_accept & is_last_beat) next_state = ST_DONE;
    ST_DONE:                           next_state = ST_IDLE;
    default:                           next_state = ST_IDLE;
  endcase
end

// +FHDR------------------------------------------------------------
// Load engine interface - receive config
// +FHDR------------------------------------------------------------
assign store_idle = (state_q == ST_IDLE);
assign st2csb_idle = store_idle & !tran_cmd_valid_q;
assign st2ld_load_idle = cmd_en_q & !tran_cmd_valid_q;

// Ready when idle or when we're accepting last beat of cube
assign ld2st_rd_prdy = (tran_dat_accept & is_last_beat & is_cube_last) | (!tran_cmd_valid_q);

// Command valid tracking
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    tran_cmd_valid_q <= 1'b0;
  end else begin
    if (ld2st_rd_prdy) begin
      tran_cmd_valid_q <= ld2st_rd_pvld;
    end
  end
end

assign cfg_valid = ld2st_rd_pvld & tran_cmd_valid_q;
assign cfg_accept = cfg_valid & cfg_ready & store_idle;
assign ld2st_rd_prdy = cfg_ready & store_idle;

// Unpack config from ld2st_rd_pd
assign cfg_dst_addr[63:0]         = ld2st_rd_pd[63:0];
assign cfg_line_size[12:0]        = ld2st_rd_pd[76:64];
assign cfg_cmd_src_ram_type        = ld2st_rd_pd[77];   // unused in store
assign cfg_cmd_dst_ram_type        = ld2st_rd_pd[78];
assign cfg_cmd_interrupt          = ld2st_rd_pd[79];
assign cfg_cmd_interrupt_ptr      = ld2st_rd_pd[80];
assign cfg_dst_line_stride[26:0]   = ld2st_rd_pd[107:81];
assign cfg_line_repeat_number[12:0] = ld2st_rd_pd[120:108];
assign cfg_dst_surf_stride[26:0]   = ld2st_rd_pd[147:121];
assign cfg_surf_repeat_number[12:0] = ld2st_rd_pd[160:148];

// Extended stride calculation
assign cfg_dst_line_stride_ext[31:0] = {cfg_dst_line_stride[26:0], 5'd0};
assign cfg_dst_surf_stride_ext[31:0] = {cfg_dst_surf_stride[26:0], 5'd0};

// Config ready signal
assign cfg_ready = store_idle & !tran_cmd_valid_q;

// Store enable - when we accept a new config
assign store_en = cfg_accept;

// +FHDR------------------------------------------------------------
// Config registers - latch config values when store starts
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    reg_line_size            <= 13'd0;
    reg_cmd_dst_ram_type    <= 1'b0;
    reg_line_repeat_number   <= 13'd0;
    reg_surf_repeat_number   <= 13'd0;
    reg_line_stride          <= 32'd0;
    reg_surf_stride          <= 32'd0;
    reg_cmd_interrupt        <= 1'b0;
    reg_cmd_interrupt_ptr    <= 1'b0;
  end else begin
    if (store_en) begin
      reg_line_size            <= {{13{1'b0}}, cfg_line_size[12:0]};
      reg_cmd_dst_ram_type    <= cfg_cmd_dst_ram_type;
      reg_line_repeat_number   <= {{13{1'b0}}, cfg_line_repeat_number[12:0]};
      reg_surf_repeat_number   <= {{13{1'b0}}, cfg_surf_repeat_number[12:0]};
      reg_line_stride          <= {{5{1'b0}}, cfg_dst_line_stride_ext[31:5]};
      reg_surf_stride          <= {{5{1'b0}}, cfg_dst_surf_stride_ext[31:5]};
      reg_cmd_interrupt        <= cfg_cmd_interrupt;
      reg_cmd_interrupt_ptr    <= cfg_cmd_interrupt_ptr;
    end
  end
end

// +FHDR------------------------------------------------------------
// Address and counter tracking
// +FHDR------------------------------------------------------------

// Beat size calculation (line size in beats, each beat is 32 bytes)
assign beat_size = reg_line_size[12:1];

// Beat count
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    beat_count_q <= 13'd0;
  end else begin
    if (store_en) begin
      beat_count_q <= 13'd0;
    end else if (tran_dat_accept) begin
      if (is_last_beat) begin
        beat_count_q <= 13'd0;
      end else begin
        beat_count_q <= beat_count_q + 13'd1;
      end
    end
  end
end
assign is_last_beat = (beat_count_q == beat_size);

// Line address tracking
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    line_addr_q <= 64'd0;
    mon_line_addr_c_q <= 1'b0;
  end else begin
    if (store_en) begin
      line_addr_q <= cfg_dst_addr;
    end else if (tran_dat_accept & is_last_beat) begin
      if (is_surf_last) begin
        {mon_line_addr_c_q, line_addr_q} <= surf_addr_q + reg_surf_stride;
      end else begin
        {mon_line_addr_c_q, line_addr_q} <= line_addr_q + reg_line_stride;
      end
    end
  end
end

// Surface address tracking
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    surf_addr_q <= 64'd0;
    mon_surf_addr_c_q <= 1'b0;
  end else begin
    if (store_en) begin
      surf_addr_q <= cfg_dst_addr;
    end else if (tran_dat_accept & is_last_beat) begin
      if (is_surf_last) begin
        {mon_surf_addr_c_q, surf_addr_q} <= surf_addr_q + reg_surf_stride;
      end
    end
  end
end

// Line count
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    line_count_q <= 12'd0;
  end else begin
    if (store_en) begin
      line_count_q <= 12'd0;
    end else if (tran_dat_accept & is_last_beat) begin
      if (is_surf_last) begin
        line_count_q <= 12'd0;
      end else begin
        line_count_q <= line_count_q + 12'd1;
      end
    end
  end
end

// Surface count
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    surf_count_q <= 12'd0;
  end else begin
    if (store_en) begin
      surf_count_q <= 12'd0;
    end else if (tran_dat_accept & is_last_beat) begin
      if (is_cube_last) begin
        surf_count_q <= 12'd0;
      end else if (is_surf_last) begin
        surf_count_q <= surf_count_q + 12'd1;
      end
    end
  end
end

// End-of-transfer flags
assign is_surf_last = (line_count_q == reg_line_repeat_number);
assign is_cube_last = (surf_count_q == reg_surf_repeat_number) & is_surf_last;

// +FHDR------------------------------------------------------------
// Command/Data enable logic
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cmd_en_q <= 1'b1;
    dat_en_q <= 1'b0;
  end else begin
    if (tran_cmd_accept) begin
      cmd_en_q <= 1'b0;
      dat_en_q <= 1'b1;
    end else if (tran_dat_accept & is_last_beat) begin
      cmd_en_q <= 1'b1;
      dat_en_q <= 1'b0;
    end
  end
end
assign cmd_en = cmd_en_q;
assign dat_en = dat_en_q;

// +FHDR------------------------------------------------------------
// DMA read response handling
// +FHDR------------------------------------------------------------
assign dma_rd_rsp_ram_type = cfg_cmd_src_ram_type;  // ram type from load engine

// Credit latency fifo pop based on RAM type
assign bdma2mcif_rd_cdt_lat_fifo_pop = dma_wr_dat_pvld & dma_wr_dat_rdy & (dma_rd_rsp_ram_type == 1'b1);
assign bdma2cvif_rd_cdt_lat_fifo_pop = dma_wr_dat_pvld & dma_wr_dat_rdy & (dma_rd_rsp_ram_type == 1'b0);

// +FHDR------------------------------------------------------------
// Latency FIFO for read responses
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_STORE_lat_fifo lat_fifo (
   .nvdla_core_clk        (nvdla_core_clk)           //|< i
  ,.nvdla_core_rstn       (nvdla_core_rstn)          //|< i
  ,.lat_fifo_wr_prdy      (dma_rd_rsp_rdy)           //|> w
  ,.lat_fifo_wr_pvld      (dma_rd_rsp_vld)           //|< w
  ,.lat_fifo_wr_pd        (dma_rd_rsp_pd[513:0])     //|< w
  ,.lat_fifo_rd_prdy      (dma_wr_dat_rdy)           //|< w
  ,.lat_fifo_rd_pvld      (dma_wr_dat_pvld)          //|> w
  ,.lat_fifo_rd_pd        (dma_wr_dat_data[513:0])   //|> w
  ,.pwrbus_ram_pd         (pwrbus_ram_pd[31:0])      //|< i
  );

// +FHDR------------------------------------------------------------
// DMA write request generation
// +FHDR------------------------------------------------------------

// Command handshake
assign dma_wr_req_rdy = wr_req_rdyi;
assign tran_cmd_accept = cmd_en & tran_cmd_valid_q & dma_wr_req_rdy;
assign tran_dat_accept = dat_en & dma_wr_dat_pvld & dma_wr_req_rdy;

// Command request
wire          dma_wr_cmd_vld;
wire [63:0]   dma_wr_cmd_addr;
wire [12:0]   dma_wr_cmd_size;
wire          dma_wr_cmd_require_ack;
wire [77:0]   dma_wr_cmd_pd;

assign dma_wr_cmd_vld        = cmd_en & tran_cmd_valid_q;
assign dma_wr_cmd_addr       = line_addr_q;
assign dma_wr_cmd_size       = reg_line_size;
assign dma_wr_cmd_require_ack = reg_cmd_interrupt & is_cube_last;

// Pack command
assign dma_wr_cmd_pd[63:0]   = dma_wr_cmd_addr[63:0];
assign dma_wr_cmd_pd[76:64]  = dma_wr_cmd_size[12:0];
assign dma_wr_cmd_pd[77]     = dma_wr_cmd_require_ack;

// Data request
wire          dma_wr_dat_vld;
wire [513:0]  dma_wr_dat_pd;

assign dma_wr_dat_vld        = dat_en & dma_wr_dat_pvld;
assign dma_wr_dat_mask       = (reg_line_size[0] == 0 && is_last_beat) ? 2'b01 : 2'b11;

// Pack data
assign dma_wr_dat_pd[511:0] = dma_wr_dat_data[511:0];
assign dma_wr_dat_pd[513:512] = dma_wr_dat_mask[1:0];

// Combined request
assign dma_wr_req_vld = dma_wr_cmd_vld | dma_wr_dat_vld;

always @* begin
  dma_wr_req_pd = 515'd0;
  if (cmd_en) begin
    dma_wr_req_pd[77:0]   = dma_wr_cmd_pd;
    dma_wr_req_pd[514]    = 1'b0;  // PKT_nvdla_dma_wr_req_dma_write_cmd_ID
  end else begin
    dma_wr_req_pd[513:0]  = dma_wr_dat_pd;
    dma_wr_req_pd[514]    = 1'b1;  // PKT_nvdla_dma_wr_req_dma_write_data_ID
  end
end

assign dma_wr_req_ram_type = reg_cmd_dst_ram_type;

// +FHDR------------------------------------------------------------
// RAM type routing to MCIF/CVIF
// +FHDR------------------------------------------------------------
assign mcif_wr_req_vld = dma_wr_req_vld & (dma_wr_req_ram_type == 1'b1);
assign cvif_wr_req_vld = dma_wr_req_vld & (dma_wr_req_ram_type == 1'b0);
assign mc_wr_req_rdyi = bdma2mcif_wr_req_ready & (dma_wr_req_ram_type == 1'b1);
assign cv_wr_req_rdyi = bdma2cvif_wr_req_ready & (dma_wr_req_ram_type == 1'b0);
assign wr_req_rdyi = mc_wr_req_rdyi | cv_wr_req_rdyi;

// +FHDR------------------------------------------------------------
// Internal write request pipeline
// +FHDR------------------------------------------------------------
assign int_wr_req_valid = dma_wr_req_vld;
assign int_wr_req_pd = dma_wr_req_pd;

// Internal ready signal
assign int_wr_req_ready = (is_mcif_wr & mcif_wr_req_rdy) | (is_cvif_wr & cvif_wr_req_rdy);

// MCIF path
assign is_mcif_wr = (reg_cmd_dst_ram_type == 1'b1);
assign is_cvif_wr = (reg_cmd_dst_ram_type == 1'b0);

// First stage: route to appropriate interface
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mc_int_wr_req_valid <= 1'b0;
    mc_int_wr_req_pd    <= 515'd0;
    cv_int_wr_req_valid <= 1'b0;
    cv_int_wr_req_pd    <= 515'd0;
  end else begin
    if (is_mcif_wr & int_wr_req_valid & int_wr_req_ready) begin
      mc_int_wr_req_valid <= 1'b1;
      mc_int_wr_req_pd    <= int_wr_req_pd;
    end else if (mcif_wr_req_rdy) begin
      mc_int_wr_req_valid <= 1'b0;
    end

    if (is_cvif_wr & int_wr_req_valid & int_wr_req_ready) begin
      cv_int_wr_req_valid <= 1'b1;
      cv_int_wr_req_pd    <= int_wr_req_pd;
    end else if (cvif_wr_req_rdy) begin
      cv_int_wr_req_valid <= 1'b0;
    end
  end
end

assign mcif_wr_req_rdy = bdma2mcif_wr_req_ready;
assign cvif_wr_req_rdy = bdma2cvif_wr_req_ready;

// Output assignments
assign bdma2mcif_wr_req_valid = mc_int_wr_req_valid;
assign bdma2mcif_wr_req_pd    = mc_int_wr_req_pd[514:0];
assign bdma2cvif_wr_req_valid = cv_int_wr_req_valid;
assign bdma2cvif_wr_req_pd    = cv_int_wr_req_pd[514:0];

// +FHDR------------------------------------------------------------
// Write response handling
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mc_dma_wr_rsp_complete_q <= 1'b0;
  end else begin
    mc_dma_wr_rsp_complete_q <= mcif2bdma_wr_rsp_complete;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cv_dma_wr_rsp_complete_q <= 1'b0;
  end else begin
    cv_dma_wr_rsp_complete_q <= cvif2bdma_wr_rsp_complete;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dma_wr_rsp_complete_q <= 1'b0;
  end else begin
    dma_wr_rsp_complete_q <= releasing;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mc_pending_q <= 1'b0;
  end else begin
    if (ack_top_id == 1'b0) begin
      if (mc_dma_wr_rsp_complete_q) begin
        mc_pending_q <= 1'b1;
      end
    end else if (ack_top_id == 1'b1) begin
      if (mc_pending_q) begin
        mc_pending_q <= 1'b0;
      end
    end
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cv_pending_q <= 1'b0;
  end else begin
    if (ack_top_id == 1'b1) begin
      if (cv_dma_wr_rsp_complete_q) begin
        cv_pending_q <= 1'b1;
      end
    end else if (ack_top_id == 1'b0) begin
      if (cv_pending_q) begin
        cv_pending_q <= 1'b0;
      end
    end
  end
end

assign mc_releasing = (ack_top_id == 1'b1) & (mc_dma_wr_rsp_complete_q | mc_pending_q);
assign cv_releasing = (ack_top_id == 1'b0) & (cv_dma_wr_rsp_complete_q | cv_pending_q);
assign releasing = mc_releasing | cv_releasing;

// ACK tracking
assign require_ack = (dma_wr_req_pd[514] == 1'b0) & (dma_wr_req_pd[77] == 1'b1);
assign ack_raw_vld = dma_wr_req_vld & wr_req_rdyi & require_ack;
assign ack_raw_id  = dma_wr_req_ram_type;

// Stage 1: bot
assign ack_raw_rdy = ack_bot_rdy | !ack_bot_vld;
always @(posedge nvdla_core_clk) begin
  if (ack_raw_vld & ack_raw_rdy) begin
    ack_bot_id <= ack_raw_id;
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    ack_bot_vld <= 1'b0;
  end else begin
    if (ack_raw_rdy) begin
      ack_bot_vld <= ack_raw_vld;
    end
  end
end

// Stage 2: top
assign ack_bot_rdy = ack_top_rdy | !ack_top_vld;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    ack_top_id <= 1'b0;
  end else begin
    if (ack_bot_vld & ack_bot_rdy) begin
      ack_top_id <= ack_bot_id;
    end
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    ack_top_vld <= 1'b0;
  end else begin
    if (ack_bot_rdy) begin
      ack_top_vld <= ack_bot_vld;
    end
  end
end

assign ack_top_rdy = releasing;

// +FHDR------------------------------------------------------------
// Interrupt handling
// +FHDR------------------------------------------------------------
NV_NVDLA_BDMA_STORE_fifo_intr u_fifo_intr (
   .nvdla_core_clk        (nvdla_core_clk)           //|< i
  ,.nvdla_core_rstn       (nvdla_core_rstn)          //|< i
  ,.fifo_intr_wr_idle     (fifo_intr_wr_idle)        //|> w
  ,.fifo_intr_wr_pvld     (fifo_intr_wr_pvld)        //|< w
  ,.fifo_intr_wr_pd       (fifo_intr_wr_pd)          //|< w
  ,.fifo_intr_rd_prdy     (fifo_intr_rd_prdy)        //|< w
  ,.fifo_intr_rd_pvld     (fifo_intr_rd_pvld)        //|> w
  ,.fifo_intr_rd_pd       (fifo_intr_rd_pd)          //|> w
  ,.pwrbus_ram_pd         (pwrbus_ram_pd[31:0])      //|< i
  );

assign fifo_intr_wr_pd    = reg_cmd_interrupt_ptr;
assign fifo_intr_wr_pvld  = dma_wr_cmd_vld & dma_wr_req_rdy & dma_wr_cmd_require_ack;
assign fifo_intr_rd_prdy  = dma_wr_rsp_complete_q;

assign grp0_done = fifo_intr_rd_pvld & fifo_intr_rd_prdy & (fifo_intr_rd_pd == 1'b0);
assign grp1_done = fifo_intr_rd_pvld & fifo_intr_rd_prdy & (fifo_intr_rd_pd == 1'b1);

assign st2csb_grp0_done = grp0_done;
assign st2csb_grp1_done = grp1_done;

// +FHDR------------------------------------------------------------
// Read response handling - merge MCIF and CVIF
// +FHDR------------------------------------------------------------
wire [513:0] mc_dma_rd_rsp_pd;
wire         mc_dma_rd_rsp_vld;
wire         mc_int_rd_rsp_valid;
wire         mc_int_rd_rsp_ready;
wire [513:0] mc_int_rd_rsp_pd;

wire [513:0] cv_dma_rd_rsp_pd;
wire         cv_dma_rd_rsp_vld;
wire         cv_int_rd_rsp_valid;
wire         cv_int_rd_rsp_ready;
wire [513:0] cv_int_rd_rsp_pd;

// MCIF read response path
assign mcif2bdma_rd_rsp_ready = mc_int_rd_rsp_ready;
assign mc_int_rd_rsp_valid = mcif2bdma_rd_rsp_valid;
assign mc_int_rd_rsp_pd = mcif2bdma_rd_rsp_pd;

// CVIF read response path
assign cvif2bdma_rd_rsp_ready = cv_int_rd_rsp_ready;
assign cv_int_rd_rsp_valid = cvif2bdma_rd_rsp_valid;
assign cv_int_rd_rsp_pd = cvif2bdma_rd_rsp_pd;

// Merge responses
assign dma_rd_rsp_vld = mc_dma_rd_rsp_vld | cv_dma_rd_rsp_vld;
assign dma_rd_rsp_pd = ({514{mc_dma_rd_rsp_vld}} & mc_dma_rd_rsp_pd) |
                       ({514{cv_dma_rd_rsp_vld}} & cv_dma_rd_rsp_pd);

// Add simple pipeline registers for read responses
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    mc_dma_rd_rsp_vld <= 1'b0;
    cv_dma_rd_rsp_vld <= 1'b0;
  end else begin
    mc_dma_rd_rsp_vld <= mc_int_rd_rsp_valid & dma_rd_rsp_rdy;
    cv_dma_rd_rsp_vld <= cv_int_rd_rsp_valid & dma_rd_rsp_rdy;
  end
end

always @(posedge nvdla_core_clk) begin
  if (mc_int_rd_rsp_valid & dma_rd_rsp_rdy) begin
    mc_dma_rd_rsp_pd <= mc_int_rd_rsp_pd;
  end
  if (cv_int_rd_rsp_valid & dma_rd_rsp_rdy) begin
    cv_dma_rd_rsp_pd <= cv_int_rd_rsp_pd;
  end
end

assign mc_int_rd_rsp_ready = dma_rd_rsp_rdy;
assign cv_int_rd_rsp_ready = dma_rd_rsp_rdy;

// Direct passthrough for ready signals
assign mcif2bdma_rd_rsp_ready = dma_rd_rsp_rdy;
assign cvif2bdma_rd_rsp_ready = dma_rd_rsp_rdy;

// Assign to internal wires for FIFO
wire [513:0] mcif2bdma_rd_rsp_pd_d0;
wire [513:0] cvif2bdma_rd_rsp_pd_d0;

assign mcif2bdma_rd_rsp_pd_d0 = mcif2bdma_rd_rsp_pd;
assign cvif2bdma_rd_rsp_pd_d0 = cvif2bdma_rd_rsp_pd;

// Use direct assignment for the merged signals
assign dma_rd_rsp_rdy = 1'b1;  // Always ready - FIFO handles backpressure

// +FHDR------------------------------------------------------------
// Stall count tracking
// +FHDR------------------------------------------------------------
assign dma_write_stall_count_inc = dma_wr_req_vld & !dma_wr_req_rdy;
assign dma_write_stall_count_dec = 1'b0;

always @* begin
  stl_adv = dma_write_stall_count_inc ^ dma_write_stall_count_dec;
end

always @* begin
  stl_cnt_ext[33:0] = {1'b0, 1'b0, stl_cnt_cur[31:0]};
  stl_cnt_inc[33:0] = stl_cnt_cur + 34'd1;
  stl_cnt_dec[33:0] = stl_cnt_cur - 34'd1;
  stl_cnt_mod[33:0] = (dma_write_stall_count_inc & ~dma_write_stall_count_dec) ? stl_cnt_inc :
                      (~dma_write_stall_count_inc & dma_write_stall_count_dec) ? stl_cnt_dec :
                      stl_cnt_ext;
  stl_cnt_new[33:0] = stl_adv ? stl_cnt_mod[33:0] : stl_cnt_ext[33:0];
  stl_cnt_nxt[33:0] = dma_wr_rsp_complete_q ? 34'd0 : stl_cnt_new[33:0];
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    stl_cnt_cur[31:0] <= 32'd0;
  end else begin
    if (dma_write_stall_count_cen) begin
      stl_cnt_cur[31:0] <= stl_cnt_nxt[31:0];
    end
  end
end

assign dma_write_stall_count[31:0] = stl_cnt_cur[31:0];

// +FHDR------------------------------------------------------------
// SLCG generation
// +FHDR------------------------------------------------------------
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    st2gate_slcg_en_q <= 1'b0;
  end else begin
    st2gate_slcg_en_q <= !store_idle;
  end
end
assign st2gate_slcg_en = st2gate_slcg_en_q;

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

// Write complete should not happen when intr ptr not in fifo
`ifndef SYNTHESIS
  // VCS coverage off
  nv_assert_never #(0, 0, "when write complete, intr_ptr should be already in the head of fifo_intr read side")
    zzz_assert_never_intr_ptr (nvdla_core_clk, `ASSERT_RESET, !fifo_intr_rd_pvld & dma_wr_rsp_complete_q);
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

endmodule // NV_NVDLA_BDMA_store_new