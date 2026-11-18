// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// TX keep filter for framing_top (8-bit AXI-Stream, clk_i domain).
//
// The 64-to-8 bit downsizer always emits all 8 bytes of the last beat and only
// marks the unused ones with keep = 0. The MAC ignores keep, so without this
// filter every frame is padded to a multiple of 8 bytes (a 1514 B frame becomes
// 1520 B + FCS = 1524 B, above the 1518 B Ethernet maximum).
//
// This filter drops bytes with keep = 0 and moves tlast to the last byte with
// keep = 1. It holds one byte, so it adds one cycle of latency. The output is
// as continuous as the input (the MAC needs back-to-back bytes inside a frame).
//
// Assumption: keep = 0 bytes only appear after the last valid byte of a frame
// (trailing), or before the first one (leading, dropped as well).

module eth_tx_keep_filter (
  input  logic       clk_i,
  input  logic       rst_ni,
  // from the downsizer
  input  logic [7:0] in_data_i,
  input  logic       in_keep_i,
  input  logic       in_last_i,
  input  logic       in_user_i,
  input  logic       in_valid_i,
  output logic       in_ready_o,
  // to the MAC
  output logic [7:0] out_data_o,
  output logic       out_last_o,
  output logic       out_user_o,
  output logic       out_valid_o,
  input  logic       out_ready_i
);

  logic       h_valid_q, h_last_q, h_user_q;
  logic [7:0] h_data_q;

  logic pad_in;   // incoming byte is padding (keep = 0)
  logic fire_out; // held byte goes to the MAC this cycle
  logic take_in;  // incoming byte is consumed this cycle

  assign pad_in = in_valid_i & ~in_keep_i;

  // The held byte can leave once we know whether it is the last one:
  // it is last if it came with tlast, or if the next byte is padding.
  assign out_valid_o = h_valid_q & (h_last_q | in_valid_i);
  assign out_last_o  = h_last_q | pad_in;
  assign out_data_o  = h_data_q;
  assign out_user_o  = h_user_q;
  assign fire_out    = out_valid_o & out_ready_i;

  always_comb begin
    if (!h_valid_q)    in_ready_o = 1'b1;          // empty: take (or drop) the byte
    else if (h_last_q) in_ready_o = 1'b0;          // wait until the last byte left
    else               in_ready_o = out_ready_i;   // move in step with the MAC
  end
  assign take_in = in_valid_i & in_ready_o;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      h_valid_q <= 1'b0;
      h_last_q  <= 1'b0;
      h_user_q  <= 1'b0;
      h_data_q  <= '0;
    end else begin
      if (fire_out) h_valid_q <= 1'b0;
      // A valid byte is loaded into the holder; a padding byte is dropped.
      // A padding byte that arrives while a non-last byte is held makes that
      // byte the last one (it leaves this cycle with out_last_o = 1).
      if (take_in && in_keep_i) begin
        h_valid_q <= 1'b1;
        h_data_q  <= in_data_i;
        h_last_q  <= in_last_i;
        h_user_q  <= in_user_i;
      end
    end
  end

endmodule : eth_tx_keep_filter
