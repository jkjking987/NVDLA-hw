// ================================================================
// NVDLA Open Source Project
//
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_csb_new.v

// Description:
// CSB interface for PDP - converts APB protocol to CSB protocol
// PDP register address space is 4KB (12-bit offset)

module NV_NVDLA_PDP_csb_new (
    nvdla_core_clk               //|< i
  , nvdla_core_rstn             //|< i
  , psel                        //|< i
  , penable                     //|< i
  , paddr                       //|< i
  , pwdata                      //|< i
  , pwrite                      //|< i
  , prdata                      //|> o
  , pready                      //|> o
  , csb2pdp_req_pvld            //|> o
  , csb2pdp_req_prdy            //|< i
  , csb2pdp_req_pd              //|> o
  , pdp2csb_resp_valid          //|< i
  , pdp2csb_resp_prdy          //|> o
  , pdp2csb_resp_pd            //|< i
);

// APB signals
input        psel;
input        penable;
input [31:0] paddr;
input [31:0] pwdata;
input        pwrite;
output [31:0] prdata;
output        pready;

// CSB request signals
output        csb2pdp_req_pvld;
input         csb2pdp_req_prdy;
output [62:0] csb2pdp_req_pd;

// CSB response signals
input         pdp2csb_resp_valid;
output        pdp2csb_resp_prdy;
input  [33:0] pdp2csb_resp_pd;

// Internal signals
reg          rd_trans_pending;
reg  [31:0] rd_data;

// Write transaction valid
wire         wr_trans_vld;
wire         rd_trans_vld;

// CSB request packet format
// [21:0]  - address (word aligned)
// [53:22] - write data
// [54]    - write enable
// [55]    - non-posted write
// [56]    - privilege bit
// [60:57] - write strobe
// [62:61] - level (for interrupt)

assign wr_trans_vld = psel & penable & pwrite;
assign rd_trans_vld = psel & penable & (~pwrite);

assign csb2pdp_req_pvld = wr_trans_vld | (rd_trans_vld & ~rd_trans_pending);

assign csb2pdp_req_pd = {
    2'd0,                  // level[1:0]
    4'h0,                  // wr_be[3:0]
    1'b0,                  // srcpriv
    1'b1,                  // nposted (always posted for simplicity)
    pwrite,               // write
    pwdata[31:0],         // wdat[31:0]
    paddr[23:2]           // addr[21:0]
};

assign pready = ~(wr_trans_vld & ~csb2pdp_req_prdy | rd_trans_vld & ~pdp2csb_resp_valid);

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        rd_trans_pending <= 1'b0;
    end else begin
        if (pdp2csb_resp_valid & rd_trans_pending) begin
            rd_trans_pending <= 1'b0;
        end else if (csb2pdp_req_pvld & csb2pdp_req_prdy & ~pwrite) begin
            rd_trans_pending <= 1'b1;
        end
    end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
    if (!nvdla_core_rstn) begin
        rd_data <= {32{1'b0}};
    end else begin
        if (pdp2csb_resp_valid) begin
            rd_data <= pdp2csb_resp_pd[31:0];
        end
    end
end

assign prdata = rd_data;
assign pdp2csb_resp_prdy = 1'b1;

endmodule // NV_NVDLA_PDP_csb_new