// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Dual-clock FIFO whose bulk storage is a tc_sram (BRAM on FPGA through
// tech_cells_generic, an SRAM macro on ASIC). Drop-in replacement for
// common_cells cdc_fifo_gray (same ports).
//
//   src_clk_i: small cdc_fifo_gray (2**CdcLogDepth entries, flip-flops)
//   dst_clk_i: single-clock FIFO with 2**LOG_DEPTH entries in a 1R1W tc_sram
//
// Total capacity is 2**LOG_DEPTH + 2**CdcLogDepth words. The dst clock must
// be fast enough to drain the CDC FIFO at the src word rate.

module eth_cdc_fifo_sram #(
  parameter type         T           = logic,
  parameter int unsigned LOG_DEPTH   = 9,
  parameter int unsigned SYNC_STAGES = 3,
  parameter int unsigned CdcLogDepth = 2
) (
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  T     src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,

  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  output T     dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  T     cdc_data;
  logic cdc_valid, cdc_ready;

  cdc_fifo_gray #(
    .T           ( T           ),
    .LOG_DEPTH   ( CdcLogDepth ),
    .SYNC_STAGES ( SYNC_STAGES )
  ) i_cdc_fifo (
    .src_rst_ni  ( src_rst_ni  ),
    .src_clk_i   ( src_clk_i   ),
    .src_data_i  ( src_data_i  ),
    .src_valid_i ( src_valid_i ),
    .src_ready_o ( src_ready_o ),
    .dst_rst_ni  ( dst_rst_ni  ),
    .dst_clk_i   ( dst_clk_i   ),
    .dst_data_o  ( cdc_data    ),
    .dst_valid_o ( cdc_valid   ),
    .dst_ready_i ( cdc_ready   )
  );

  eth_sram_fifo #(
    .T         ( T         ),
    .LOG_DEPTH ( LOG_DEPTH )
  ) i_sram_fifo (
    .clk_i   ( dst_clk_i   ),
    .rst_ni  ( dst_rst_ni  ),
    .data_i  ( cdc_data    ),
    .valid_i ( cdc_valid   ),
    .ready_o ( cdc_ready   ),
    .data_o  ( dst_data_o  ),
    .valid_o ( dst_valid_o ),
    .ready_i ( dst_ready_i )
  );

endmodule : eth_cdc_fifo_sram


// Single-clock first-word-fall-through FIFO on a 2-port (1W + 1R) tc_sram with
// read latency 1. A word frees its SRAM slot only when it leaves the output,
// so the word on data_o is never overwritten. One word per cycle in and out.
module eth_sram_fifo #(
  parameter type         T         = logic,
  parameter int unsigned LOG_DEPTH = 9
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  T     data_i,
  input  logic valid_i,
  output logic ready_o,
  output T     data_o,
  output logic valid_o,
  input  logic ready_i
);

  localparam int unsigned A     = LOG_DEPTH;
  localparam int unsigned W     = $bits(T);
  localparam int unsigned Depth = 2**A;

  logic [A-1:0] wptr_q, rptr_q;
  logic [A:0]   occ_q;     // words in the SRAM incl. the one on data_o
  logic [A:0]   unread_q;  // words written but not yet read from the SRAM
  logic         rvalid_q;
  logic         push, rd, pop;

  logic [1:0]           sram_req, sram_we;
  logic [1:0][A-1:0]    sram_addr;
  logic [1:0][W-1:0]    sram_wdata, sram_rdata;
  logic [1:0][(W+7)/8-1:0] sram_be;

  assign ready_o = (occ_q != (A+1)'(Depth));
  assign push    = valid_i & ready_o;
  assign pop     = rvalid_q & ready_i;
  assign rd      = (unread_q != '0) & (~rvalid_q | ready_i);

  // port 0: write, port 1: read
  assign sram_req   = {rd, push};
  assign sram_we    = 2'b01;
  assign sram_addr  = {rptr_q, wptr_q};
  assign sram_wdata = {{W{1'b0}}, W'(data_i)};
  assign sram_be    = {{((W+7)/8){1'b0}}, {((W+7)/8){1'b1}}};

  tc_sram #(
    .NumWords  ( Depth ),
    .DataWidth ( W     ),
    .ByteWidth ( 8     ),
    .NumPorts  ( 2     ),
    .Latency   ( 1     )
  ) i_sram (
    .clk_i   ( clk_i      ),
    .rst_ni  ( rst_ni     ),
    .req_i   ( sram_req   ),
    .we_i    ( sram_we    ),
    .addr_i  ( sram_addr  ),
    .wdata_i ( sram_wdata ),
    .be_i    ( sram_be    ),
    .rdata_o ( sram_rdata )
  );

  assign data_o  = T'(sram_rdata[1]);
  assign valid_o = rvalid_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wptr_q   <= '0;
      rptr_q   <= '0;
      occ_q    <= '0;
      unread_q <= '0;
      rvalid_q <= 1'b0;
    end else begin
      if (push) wptr_q <= wptr_q + 1'b1;
      if (rd)   rptr_q <= rptr_q + 1'b1;
      occ_q    <= occ_q    + (A+1)'(push) - (A+1)'(pop);
      unread_q <= unread_q + (A+1)'(push) - (A+1)'(rd);
      if (rd)        rvalid_q <= 1'b1;
      else if (pop)  rvalid_q <= 1'b0;
    end
  end

endmodule : eth_sram_fifo
