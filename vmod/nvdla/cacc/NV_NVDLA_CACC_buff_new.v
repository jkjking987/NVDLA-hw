// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : NV_NVDLA_CACC_buff_new.v
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
// CACC Buffer Module - Combined Assembly and Delivery SRAM buffers
// - Assembly buffer: 32 entries x 768 bits x 8 banks (for accumulation)
// - Delivery buffer: 32 entries x 512 bits x 8 banks (for output)
// - Assembly buffer supports read-modify-write for accumulation
// - Both buffers use ping-pong architecture for banking
// - FHDR------------------------------------------------------------

module NV_NVDLA_CACC_buff_new (
   nvdla_core_clk            //|< i
  ,nvdla_core_rstn          //|< i
  ,pwrbus_ram_pd            //|< i  [31:0]

  // Assembly buffer write interface (from calculator)
  ,abuf_wr_addr             //|< i  [4:0]
  ,abuf_wr_data_0           //|< i  [767:0]
  ,abuf_wr_data_1           //|< i  [767:0]
  ,abuf_wr_data_2           //|< i  [767:0]
  ,abuf_wr_data_3           //|< i  [767:0]
  ,abuf_wr_data_4           //|< i  [543:0]
  ,abuf_wr_data_5           //|< i  [543:0]
  ,abuf_wr_data_6           //|< i  [543:0]
  ,abuf_wr_data_7           //|< i  [543:0]
  ,abuf_wr_en               //|< i  [7:0]

  // Assembly buffer read interface (to calculator)
  ,abuf_rd_addr             //|< i  [4:0]
  ,abuf_rd_en               //|< i  [7:0]
  ,abuf_rd_data_0           //|> o  [767:0]
  ,abuf_rd_data_1           //|> o  [767:0]
  ,abuf_rd_data_2           //|> o  [767:0]
  ,abuf_rd_data_3           //|> o  [767:0]
  ,abuf_rd_data_4           //|> o  [543:0]
  ,abuf_rd_data_5           //|> o  [543:0]
  ,abuf_rd_data_6           //|> o  [543:0]
  ,abuf_rd_data_7           //|> o  [543:0]

  // Delivery buffer write interface (from calculator)
  ,dbuf_wr_addr_0           //|< i  [4:0]
  ,dbuf_wr_addr_1           //|< i  [4:0]
  ,dbuf_wr_addr_2           //|< i  [4:0]
  ,dbuf_wr_addr_3           //|< i  [4:0]
  ,dbuf_wr_addr_4           //|< i  [4:0]
  ,dbuf_wr_addr_5           //|< i  [4:0]
  ,dbuf_wr_addr_6           //|< i  [4:0]
  ,dbuf_wr_addr_7           //|< i  [4:0]
  ,dbuf_wr_data_0           //|< i  [511:0]
  ,dbuf_wr_data_1           //|< i  [511:0]
  ,dbuf_wr_data_2           //|< i  [511:0]
  ,dbuf_wr_data_3           //|< i  [511:0]
  ,dbuf_wr_data_4           //|< i  [511:0]
  ,dbuf_wr_data_5           //|< i  [511:0]
  ,dbuf_wr_data_6           //|< i  [511:0]
  ,dbuf_wr_data_7           //|< i  [511:0]
  ,dbuf_wr_en               //|< i  [7:0]

  // Delivery buffer read interface (to SDP)
  ,dbuf_rd_addr             //|< i  [4:0]
  ,dbuf_rd_en               //|< i  [7:0]
  ,dbuf_rd_data_0           //|> o  [511:0]
  ,dbuf_rd_data_1           //|> o  [511:0]
  ,dbuf_rd_data_2           //|> o  [511:0]
  ,dbuf_rd_data_3           //|> o  [511:0]
  ,dbuf_rd_data_4           //|> o  [511:0]
  ,dbuf_rd_data_5           //|> o  [511:0]
  ,dbuf_rd_data_6           //|> o  [511:0]
  ,dbuf_rd_data_7           //|> o  [511:0]
  ,dbuf_rd_layer_end        //|> o
  ,dbuf_rd_ready            //|> o
  );

//===============================================================
// Port declarations
//===============================================================
input         nvdla_core_clk;
input         nvdla_core_rstn;
input  [31:0] pwrbus_ram_pd;

// Assembly buffer write
input  [4:0]  abuf_wr_addr;
input  [767:0] abuf_wr_data_0;
input  [767:0] abuf_wr_data_1;
input  [767:0] abuf_wr_data_2;
input  [767:0] abuf_wr_data_3;
input  [543:0] abuf_wr_data_4;
input  [543:0] abuf_wr_data_5;
input  [543:0] abuf_wr_data_6;
input  [543:0] abuf_wr_data_7;
input  [7:0]   abuf_wr_en;

// Assembly buffer read
input  [4:0]  abuf_rd_addr;
input  [7:0]   abuf_rd_en;
output [767:0] abuf_rd_data_0;
output [767:0] abuf_rd_data_1;
output [767:0] abuf_rd_data_2;
output [767:0] abuf_rd_data_3;
output [543:0] abuf_rd_data_4;
output [543:0] abuf_rd_data_5;
output [543:0] abuf_rd_data_6;
output [543:0] abuf_rd_data_7;

// Delivery buffer write
input  [4:0]  dbuf_wr_addr_0;
input  [4:0]  dbuf_wr_addr_1;
input  [4:0]  dbuf_wr_addr_2;
input  [4:0]  dbuf_wr_addr_3;
input  [4:0]  dbuf_wr_addr_4;
input  [4:0]  dbuf_wr_addr_5;
input  [4:0]  dbuf_wr_addr_6;
input  [4:0]  dbuf_wr_addr_7;
input  [511:0] dbuf_wr_data_0;
input  [511:0] dbuf_wr_data_1;
input  [511:0] dbuf_wr_data_2;
input  [511:0] dbuf_wr_data_3;
input  [511:0] dbuf_wr_data_4;
input  [511:0] dbuf_wr_data_5;
input  [511:0] dbuf_wr_data_6;
input  [511:0] dbuf_wr_data_7;
input  [7:0]   dbuf_wr_en;

// Delivery buffer read
input  [4:0]  dbuf_rd_addr;
input  [7:0]   dbuf_rd_en;
output [511:0] dbuf_rd_data_0;
output [511:0] dbuf_rd_data_1;
output [511:0] dbuf_rd_data_2;
output [511:0] dbuf_rd_data_3;
output [511:0] dbuf_rd_data_4;
output [511:0] dbuf_rd_data_5;
output [511:0] dbuf_rd_data_6;
output [511:0] dbuf_rd_data_7;
output         dbuf_rd_layer_end;
output         dbuf_rd_ready;

//===============================================================
// Assembly buffer instantiation
//===============================================================
// 8 banks of 32-entry x 768-bit RAM for assembly buffer
// Banks 0-3: 768-bit wide
// Banks 4-7: 544-bit wide (actually 768 bits with unused portions)

nv_ram_rws_32x768 u_abuf_bank_0 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[0])
  ,.dout        (abuf_rd_data_0[767:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[0])
  ,.di          (abuf_wr_data_0[767:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x768 u_abuf_bank_1 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[1])
  ,.dout        (abuf_rd_data_1[767:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[1])
  ,.di          (abuf_wr_data_1[767:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x768 u_abuf_bank_2 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[2])
  ,.dout        (abuf_rd_data_2[767:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[2])
  ,.di          (abuf_wr_data_2[767:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x768 u_abuf_bank_3 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[3])
  ,.dout        (abuf_rd_data_3[767:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[3])
  ,.di          (abuf_wr_data_3[767:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x544 u_abuf_bank_4 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[4])
  ,.dout        (abuf_rd_data_4[543:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[4])
  ,.di          (abuf_wr_data_4[543:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x544 u_abuf_bank_5 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[5])
  ,.dout        (abuf_rd_data_5[543:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[5])
  ,.di          (abuf_wr_data_5[543:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x544 u_abuf_bank_6 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[6])
  ,.dout        (abuf_rd_data_6[543:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[6])
  ,.di          (abuf_wr_data_6[543:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x544 u_abuf_bank_7 (
   .clk         (nvdla_core_clk)
  ,.ra          (abuf_rd_addr[4:0])
  ,.re          (abuf_rd_en[7])
  ,.dout        (abuf_rd_data_7[543:0])
  ,.wa          (abuf_wr_addr[4:0])
  ,.we          (abuf_wr_en[7])
  ,.di          (abuf_wr_data_7[543:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

//===============================================================
// Delivery buffer instantiation
//===============================================================
// 8 banks of 32-entry x 512-bit RAM for delivery buffer
// All banks are 512-bit wide

nv_ram_rws_32x512 u_dbuf_bank_0 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[0])
  ,.dout        (dbuf_rd_data_0[511:0])
  ,.wa          (dbuf_wr_addr_0[4:0])
  ,.we          (dbuf_wr_en[0])
  ,.di          (dbuf_wr_data_0[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_1 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[1])
  ,.dout        (dbuf_rd_data_1[511:0])
  ,.wa          (dbuf_wr_addr_1[4:0])
  ,.we          (dbuf_wr_en[1])
  ,.di          (dbuf_wr_data_1[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_2 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[2])
  ,.dout        (dbuf_rd_data_2[511:0])
  ,.wa          (dbuf_wr_addr_2[4:0])
  ,.we          (dbuf_wr_en[2])
  ,.di          (dbuf_wr_data_2[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_3 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[3])
  ,.dout        (dbuf_rd_data_3[511:0])
  ,.wa          (dbuf_wr_addr_3[4:0])
  ,.we          (dbuf_wr_en[3])
  ,.di          (dbuf_wr_data_3[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_4 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[4])
  ,.dout        (dbuf_rd_data_4[511:0])
  ,.wa          (dbuf_wr_addr_4[4:0])
  ,.we          (dbuf_wr_en[4])
  ,.di          (dbuf_wr_data_4[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_5 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[5])
  ,.dout        (dbuf_rd_data_5[511:0])
  ,.wa          (dbuf_wr_addr_5[4:0])
  ,.we          (dbuf_wr_en[5])
  ,.di          (dbuf_wr_data_5[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_6 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[6])
  ,.dout        (dbuf_rd_data_6[511:0])
  ,.wa          (dbuf_wr_addr_6[4:0])
  ,.we          (dbuf_wr_en[6])
  ,.di          (dbuf_wr_data_6[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

nv_ram_rws_32x512 u_dbuf_bank_7 (
   .clk         (nvdla_core_clk)
  ,.ra          (dbuf_rd_addr[4:0])
  ,.re          (dbuf_rd_en[7])
  ,.dout        (dbuf_rd_data_7[511:0])
  ,.wa          (dbuf_wr_addr_7[4:0])
  ,.we          (dbuf_wr_en[7])
  ,.di          (dbuf_wr_data_7[511:0])
  ,.pwrbus_ram_pd (pwrbus_ram_pd[31:0])
  );

//===============================================================
// Delivery buffer status signals
//===============================================================
// These signals indicate when delivery data is ready
// They are connected to the delivery controller

reg dbuf_rd_ready_q;
assign dbuf_rd_ready = dbuf_rd_ready_q;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    dbuf_rd_ready_q <= 1'b0;
  end else begin
    // Ready when there's valid data to read
    // This is a simplified version - real implementation
    // would track write pointers and available entries
    dbuf_rd_ready_q <= |dbuf_wr_en;
  end
end

assign dbuf_rd_layer_end = 1'b0;  // TODO: Implement layer end tracking

endmodule // NV_NVDLA_CACC_buff_new