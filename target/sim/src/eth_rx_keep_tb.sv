// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Denis Gregor <romeoradescu25@proton.me>

// The receive path must report which bytes of a word are valid.
//
// Same two-instance RGMII loopback as eth_tb: one eth_top_synth transmits, its
// PHY pins drive a second instance's, and the frame comes back out of the
// second instance's AXI Stream receive port. Driven procedurally rather than
// with the randomized class-based drivers, so it runs on a plain open-source
// simulator as well as Questa, and so the checks name exact values.
//
// A broadcast destination MAC is accepted by framing_top's address filter
// without any register configuration, so the register bus is tied off.

`timescale 1 ns/1 ps

module eth_rx_keep_tb ();

  logic clk_i    = 1'b0;
  logic clk90_i  = 1'b0;
  logic clk200_i = 1'b0;
  logic rst_ni   = 1'b0;

  always #4 clk_i    = ~clk_i;      // 125 MHz
  always #2 clk200_i = ~clk200_i;
  initial begin
    #2;
    forever #4 clk90_i = ~clk90_i;  // 125 MHz, quarter period late
  end

  wire [3:0] a2b_d, b2a_d;
  wire       a2b_ctl, b2a_ctl, a2b_ck, b2a_ck;

  logic [63:0] tx_data;
  logic [7:0]  tx_keep;
  logic        tx_last, tx_valid, tx_ready;

  logic [63:0] rx_data;
  logic [7:0]  rx_keep, rx_strb;
  logic        rx_last, rx_valid;

  // Transmitting instance.
  eth_top_synth i_eth_tx (
    .rst_ni(rst_ni), .clk_i(clk_i), .clk90_i(clk90_i), .clk_200MHz_i(clk200_i),
    .phy_rx_clk(b2a_ck), .phy_rxd(b2a_d), .phy_rx_ctl(b2a_ctl),
    .phy_tx_clk(a2b_ck), .phy_txd(a2b_d), .phy_tx_ctl(a2b_ctl),
    .phy_reset_n(), .phy_int_n(1'b1), .phy_pme_n(1'b1),
    .phy_mdio_i(1'b0), .phy_mdio_o(), .phy_mdio_oe(), .phy_mdc(),
    .tx_axis_tdata_i(tx_data), .tx_axis_tstrb_i(tx_keep), .tx_axis_tkeep_i(tx_keep),
    .tx_axis_tlast_i(tx_last), .tx_axis_tid_i('0), .tx_axis_tdest_i('0),
    .tx_axis_tuser_i('0), .tx_axis_tvalid_i(tx_valid), .tx_axis_tready_o(tx_ready),
    .rx_axis_tdata_o(), .rx_axis_tstrb_o(), .rx_axis_tkeep_o(), .rx_axis_tlast_o(),
    .rx_axis_tid_o(), .rx_axis_tdest_o(), .rx_axis_tuser_o(), .rx_axis_tvalid_o(),
    .rx_axis_tready_i(1'b1),
    .reg_bus_addr_i('0), .reg_bus_write_i(1'b0), .reg_bus_wdata_i('0),
    .reg_bus_wstrb_i('0), .reg_bus_valid_i(1'b0), .reg_bus_rdata_o(),
    .reg_bus_ready_o(), .reg_bus_error_o()
  );

  // Receiving instance: its PHY receive pins are the transmitter's outputs.
  eth_top_synth i_eth_rx (
    .rst_ni(rst_ni), .clk_i(clk_i), .clk90_i(clk90_i), .clk_200MHz_i(clk200_i),
    .phy_rx_clk(a2b_ck), .phy_rxd(a2b_d), .phy_rx_ctl(a2b_ctl),
    .phy_tx_clk(b2a_ck), .phy_txd(b2a_d), .phy_tx_ctl(b2a_ctl),
    .phy_reset_n(), .phy_int_n(1'b1), .phy_pme_n(1'b1),
    .phy_mdio_i(1'b0), .phy_mdio_o(), .phy_mdio_oe(), .phy_mdc(),
    .tx_axis_tdata_i('0), .tx_axis_tstrb_i('0), .tx_axis_tkeep_i('0),
    .tx_axis_tlast_i(1'b0), .tx_axis_tid_i('0), .tx_axis_tdest_i('0),
    .tx_axis_tuser_i('0), .tx_axis_tvalid_i(1'b0), .tx_axis_tready_o(),
    .rx_axis_tdata_o(rx_data), .rx_axis_tstrb_o(rx_strb), .rx_axis_tkeep_o(rx_keep),
    .rx_axis_tlast_o(rx_last), .rx_axis_tid_o(), .rx_axis_tdest_o(),
    .rx_axis_tuser_o(), .rx_axis_tvalid_o(rx_valid), .rx_axis_tready_i(1'b1),
    .reg_bus_addr_i('0), .reg_bus_write_i(1'b0), .reg_bus_wdata_i('0),
    .reg_bus_wstrb_i('0), .reg_bus_valid_i(1'b0), .reg_bus_rdata_o(),
    .reg_bus_ready_o(), .reg_bus_error_o()
  );

  logic [63:0] rx_words [$];
  logic [7:0]  rx_keeps [$];
  logic [7:0]  rx_strbs [$];

  always @(posedge clk_i) begin
    if (rst_ni && rx_valid) begin
      rx_words.push_back(rx_data);
      rx_keeps.push_back(rx_keep);
      rx_strbs.push_back(rx_strb);
    end
  end

  int unsigned failures = 0;

  task automatic check(input string name, input bit ok, input string detail);
    if (ok) begin
      $display("  PASS  %s", name);
    end else begin
      $display("  FAIL  %s -- %s", name, detail);
      failures++;
    end
  endtask

  task automatic send_word(input logic [63:0] data, input logic [7:0] keep,
                           input logic last);
    tx_data  = data;
    tx_keep  = keep;
    tx_last  = last;
    tx_valid = 1'b1;
    forever begin
      @(posedge clk_i);
      if (tx_ready) break;
    end
    tx_valid = 1'b0;
    tx_last  = 1'b0;
  endtask

  initial begin
    tx_data  = '0;
    tx_keep  = '0;
    tx_last  = 1'b0;
    tx_valid = 1'b0;

    repeat (20) @(posedge clk_i);
    rst_ni = 1'b1;
    repeat (200) @(posedge clk_i);

    // The downsizer shifts the least significant byte out first, so byte 0 on
    // the wire is the low byte of the word: the broadcast destination address
    // occupies bits [47:0] of the first word.
    send_word(64'hAABB_FFFF_FFFF_FFFF, 8'hFF, 1'b0);  // dest ff:ff:ff:ff:ff:ff, src[0:1]
    send_word(64'h0008_1122_3344_5566, 8'hFF, 1'b0);  // src[2:5], ethertype 0x0800
    send_word(64'h0000_0000_0000_BBAA, 8'h03, 1'b1);  // two payload bytes

    repeat (4000) @(posedge clk_i);

    $display("eth_rx_keep_tb: %0d word(s) received", rx_words.size());
    for (int unsigned i = 0; i < rx_words.size(); i++) begin
      $display("    word %0d: data=0x%016h keep=0x%02h strb=0x%02h",
               i, rx_words[i], rx_keeps[i], rx_strbs[i]);
    end

    check("a frame is received", rx_words.size() > 0, "no words arrived");

    if (rx_words.size() > 0) begin
      // The header words the transmitter sent must come back unchanged.
      check("word 0 matches the transmitted header",
            rx_words[0] == 64'hAABB_FFFF_FFFF_FFFF, "header word 0 differs");
      check("word 1 matches the transmitted header",
            rx_words[1] == 64'h0008_1122_3344_5566, "header word 1 differs");

      // The regression: without TKEEP driven, every word reports no valid
      // bytes and the length of the frame is unrecoverable.
      begin
        automatic bit all_zero = 1'b1;
        for (int unsigned i = 0; i < rx_keeps.size(); i++) begin
          if (rx_keeps[i] != 8'h00) all_zero = 1'b0;
        end
        check("TKEEP reports valid bytes", !all_zero,
              "every received word has TKEEP=0x00");
      end

      // The MAC pads to the 60-byte minimum, so every word is fully valid.
      check("the final word is fully valid",
            rx_keeps[rx_keeps.size()-1] == 8'hFF, "final word TKEEP is not 0xFF");

      // TSTRB accompanies TKEEP on this interface.
      check("TSTRB tracks TKEEP",
            rx_strbs[rx_strbs.size()-1] == rx_keeps[rx_keeps.size()-1],
            "TSTRB and TKEEP disagree");
    end

    if (failures == 0) begin
      $display("eth_rx_keep_tb: all checks passed");
    end else begin
      $error("eth_rx_keep_tb: %0d check(s) failed", failures);
    end
    $finish;
  end

endmodule
