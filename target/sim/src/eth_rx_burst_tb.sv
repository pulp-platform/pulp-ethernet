// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// RX burst test for the RX frame queue and the sticky RSP_VALID.
// Same loopback as eth_idma_tb: TX eth_idma_wrap -> RGMII -> RX eth_idma_wrap.
//
// Test 1: TX sends 3 frames back to back. The RX side does not start any RX
//         DMA until all 3 have arrived. With RxMaxFrames = 2 (RxFifoLogDepth 9,
//         64-bit) frames 0 and 1 must be received intact, frame 2 dropped.
// Test 2: one more frame after the queue drained must be received intact.
// Test 3: RSP_VALID must still be 1 more than 63 cycles after a DMA, and 0
//         after writing RSP_VALID_CLR 1 then 0.

`timescale 1 ns/1 ns
`include "axi/typedef.svh"
`include "idma/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module eth_rx_burst_tb
 #(
  parameter int unsigned DataWidth           = 32'd64,
  parameter int unsigned AddrWidth           = 32'd64,
  parameter int unsigned UserWidth           = 32'd1,
  parameter int unsigned AxiIdWidth          = 32'd5,
  parameter int unsigned NumAxInFlight       = 32'd3,
  parameter int unsigned BufferDepth         = 32'd3,
  parameter int unsigned TFLenWidth          = 32'd32,
  parameter int unsigned MemSysDepth         = 32'd0,
  parameter bit          RejectZeroTransfers = 1'b1,
  // RX CDC FIFO depth as in cheshire_soc.sv (9 -> 4 KB -> RxMaxFrames = 2)
  parameter int unsigned RxLogDepth          = 32'd9,
  // Frames that should survive the burst in test 1
  parameter int unsigned ExpKept             = 32'd2
);

  import idma_pkg::*;
  import reg_test::*;

  localparam time SYS_TCK = 5ns;
  localparam time ETH_TCK = 8ns;
  localparam time SYS_TA  = 2ns;
  localparam time SYS_TT  = 3ns;

  localparam int AW_REGBUS           = 32;
  localparam int DW_REGBUS           = 32;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;
  localparam int unsigned StrbWidth  = DataWidth / 8;

  // Register offsets (gen/eth_idma_reg_pkg.sv)
  localparam logic [31:0] LOW_ADDR = 'h00, MACHI = 'h04, RSR = 'h18,
                          SRC_ADDR = 'h1c, DST_ADDR = 'h20, LENGTH = 'h24,
                          SRC_PROT = 'h28, DST_PROT = 'h2c, REQ_VALID = 'h44,
                          REQ_READY = 'h48, RSP_VALID = 'h50, RSP_CLR = 'h58;

  // Frames: lengths in bytes (100 is not a multiple of 8 on purpose)
  localparam int unsigned NFrames = 4;
  localparam int unsigned FLen [NFrames] = '{64, 100, 128, 72};
  localparam logic [63:0] Slot = 64'h800;  // memory spacing between frames

  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [AxiIdWidth-1:0]  id_t;
  typedef logic [UserWidth-1:0]   user_t;
  typedef logic [StrbWidth-1:0]   strb_t;
  typedef logic [DataWidth-1:0]   data_t;

  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, data_t, id_t, user_t)
  `AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_chan_t, axi_w_chan_t, axi_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(axi_rsp_t, axi_b_chan_t, axi_r_chan_t)

  typedef logic [AW_REGBUS-1:0]   reg_bus_addr_t;
  typedef logic [DW_REGBUS-1:0]   reg_bus_data_t;
  typedef logic [STRB_WIDTH-1:0]  reg_bus_strb_t;
  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)

  logic s_clk, s_rst_n, s_clk_125MHz_0, s_clk_125MHz_90;
  logic done = 0;
  int   errors = 0;

  logic       eth_rxck, eth_rxctl, eth_txck, eth_txctl, eth_tx_rstn, eth_rx_rstn;
  logic [3:0] eth_rxd, eth_txd;
  logic       rx_irq, reg_error;
  logic [31:0] rdata;

  axi_req_t axi_tx_req_mem, axi_rx_req_mem;
  axi_rsp_t axi_tx_rsp_mem, axi_rx_rsp_mem;
  idma_busy_t tx_busy, rx_busy;

  typedef reg_test::reg_driver #(
    .AW(AW_REGBUS), .DW(DW_REGBUS), .TT(SYS_TT), .TA(SYS_TA)
  ) reg_bus_drv_t;

  REG_BUS #(.DATA_WIDTH(DW_REGBUS), .ADDR_WIDTH(AW_REGBUS)) reg_bus_tx (.clk_i(s_clk));
  REG_BUS #(.DATA_WIDTH(DW_REGBUS), .ADDR_WIDTH(AW_REGBUS)) reg_bus_rx (.clk_i(s_clk));

  reg_bus_drv_t reg_drv_tx = new(reg_bus_tx);
  reg_bus_drv_t reg_drv_rx = new(reg_bus_rx);

  reg_bus_req_t reg_bus_tx_req, reg_bus_rx_req;
  reg_bus_rsp_t reg_bus_tx_rsp, reg_bus_rx_rsp;

  `REG_BUS_ASSIGN_TO_REQ (reg_bus_tx_req, reg_bus_tx)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_tx, reg_bus_tx_rsp)
  `REG_BUS_ASSIGN_TO_REQ (reg_bus_rx_req, reg_bus_rx)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_rx, reg_bus_rx_rsp)

  clk_rst_gen #(
    .ClkPeriod    ( SYS_TCK ),
    .RstClkCycles ( 1       )
  ) i_clk_rst_gen (
    .clk_o  ( s_clk   ),
    .rst_no ( s_rst_n )
  );

  axi_sim_mem #(
    .AddrWidth ( AddrWidth ), .DataWidth ( DataWidth ), .IdWidth ( AxiIdWidth ),
    .UserWidth ( UserWidth ), .axi_req_t ( axi_req_t ), .axi_rsp_t ( axi_rsp_t ),
    .WarnUninitialized ( 1'b0 ), .ClearErrOnAccess ( 1'b1 ),
    .ApplDelay ( SYS_TA ), .AcqDelay ( SYS_TT ), .UninitializedData ( "zeros" )
  ) i_tx_axi_sim_mem (
    .clk_i ( s_clk ), .rst_ni ( s_rst_n ),
    .axi_req_i ( axi_tx_req_mem ), .axi_rsp_o ( axi_tx_rsp_mem )
  );

  axi_sim_mem #(
    .AddrWidth ( AddrWidth ), .DataWidth ( DataWidth ), .IdWidth ( AxiIdWidth ),
    .UserWidth ( UserWidth ), .axi_req_t ( axi_req_t ), .axi_rsp_t ( axi_rsp_t ),
    .WarnUninitialized ( 1'b0 ), .ClearErrOnAccess ( 1'b1 ),
    .ApplDelay ( SYS_TA ), .AcqDelay ( SYS_TT ), .UninitializedData ( "zeros" )
  ) i_rx_axi_sim_mem (
    .clk_i ( s_clk ), .rst_ni ( s_rst_n ),
    .axi_req_i ( axi_rx_req_mem ), .axi_rsp_o ( axi_rx_rsp_mem )
  );

  eth_idma_wrap #(
    .DataWidth           ( DataWidth           ),
    .AddrWidth           ( AddrWidth           ),
    .UserWidth           ( UserWidth           ),
    .AxiIdWidth          ( AxiIdWidth          ),
    .NumAxInFlight       ( NumAxInFlight       ),
    .BufferDepth         ( BufferDepth         ),
    .TFLenWidth          ( TFLenWidth          ),
    .MemSysDepth         ( MemSysDepth         ),
    .RejectZeroTransfers ( RejectZeroTransfers ),
    .axi_req_t           ( axi_req_t           ),
    .axi_rsp_t           ( axi_rsp_t           ),
    .reg_req_t           ( reg_bus_req_t       ),
    .reg_rsp_t           ( reg_bus_rsp_t       )
  ) i_tx_eth_idma_wrap (
    .clk_i         ( s_clk           ),
    .rst_ni        ( s_rst_n         ),
    .eth_clk125_i  ( s_clk_125MHz_0  ),
    .eth_clk125q_i ( s_clk_125MHz_90 ),
    .phy_rx_clk_i  ( eth_rxck        ),
    .phy_rxd_i     ( eth_rxd         ),
    .phy_rx_ctl_i  ( eth_rxctl       ),
    .phy_tx_clk_o  ( eth_txck        ),
    .phy_txd_o     ( eth_txd         ),
    .phy_tx_ctl_o  ( eth_txctl       ),
    .phy_resetn_o  ( eth_tx_rstn     ),
    .phy_intn_i    ( 1'b1            ),
    .phy_pme_i     ( 1'b1            ),
    .phy_mdio_i    ( 1'b0            ),
    .phy_mdio_o    (                 ),
    .phy_mdio_oe   (                 ),
    .phy_mdc_o     (                 ),
    .reg_req_i     ( reg_bus_tx_req  ),
    .reg_rsp_o     ( reg_bus_tx_rsp  ),
    .testmode_i    ( 1'b0            ),
    .axi_req_o     ( axi_tx_req_mem  ),
    .axi_rsp_i     ( axi_tx_rsp_mem  ),
    .idma_busy_o   ( tx_busy         ),
    .eth_rx_irq_o  (                 )
  );

  eth_idma_wrap #(
    .DataWidth           ( DataWidth           ),
    .AddrWidth           ( AddrWidth           ),
    .UserWidth           ( UserWidth           ),
    .AxiIdWidth          ( AxiIdWidth          ),
    .NumAxInFlight       ( NumAxInFlight       ),
    .BufferDepth         ( BufferDepth         ),
    .TFLenWidth          ( TFLenWidth          ),
    .MemSysDepth         ( MemSysDepth         ),
    .RxFifoLogDepth      ( RxLogDepth          ),
    .RejectZeroTransfers ( RejectZeroTransfers ),
    .axi_req_t           ( axi_req_t           ),
    .axi_rsp_t           ( axi_rsp_t           ),
    .reg_req_t           ( reg_bus_req_t       ),
    .reg_rsp_t           ( reg_bus_rsp_t       )
  ) i_rx_eth_idma_wrap (
    .clk_i         ( s_clk           ),
    .rst_ni        ( s_rst_n         ),
    .eth_clk125_i  ( s_clk_125MHz_0  ),
    .eth_clk125q_i ( s_clk_125MHz_90 ),
    .phy_rx_clk_i  ( eth_txck        ),
    .phy_rxd_i     ( eth_txd         ),
    .phy_rx_ctl_i  ( eth_txctl       ),
    .phy_tx_clk_o  ( eth_rxck        ),
    .phy_txd_o     ( eth_rxd         ),
    .phy_tx_ctl_o  ( eth_rxctl       ),
    .phy_resetn_o  ( eth_rx_rstn     ),
    .phy_intn_i    ( 1'b1            ),
    .phy_pme_i     ( 1'b1            ),
    .phy_mdio_i    ( 1'b0            ),
    .phy_mdio_o    (                 ),
    .phy_mdio_oe   (                 ),
    .phy_mdc_o     (                 ),
    .reg_req_i     ( reg_bus_rx_req  ),
    .reg_rsp_o     ( reg_bus_rx_rsp  ),
    .testmode_i    ( 1'b0            ),
    .axi_req_o     ( axi_rx_req_mem  ),
    .axi_rsp_i     ( axi_rx_rsp_mem  ),
    .idma_busy_o   ( rx_busy         ),
    .eth_rx_irq_o  ( rx_irq          )
  );

  // 125 MHz clocks
  initial begin
    while (!done) begin
      s_clk_125MHz_0 <= 1; #(ETH_TCK/2);
      s_clk_125MHz_0 <= 0; #(ETH_TCK/2);
    end
  end
  initial begin
    while (!done) begin
      s_clk_125MHz_90 <= 0; #(ETH_TCK/4);
      s_clk_125MHz_90 <= 1; #(ETH_TCK/2);
      s_clk_125MHz_90 <= 0; #(ETH_TCK/4);
    end
  end

  // ---------------------------------------------------------------- helpers

  function automatic logic [7:0] fbyte(int k, int i);
    // Broadcast destination, then source MAC, EtherType 0x0800, tagged payload
    if (i < 6)       return 8'hff;
    else if (i < 12) return 8'h10 + i;
    else if (i == 12) return 8'h08;
    else if (i == 13) return 8'h00;
    else             return 8'((k << 5) ^ i);
  endfunction

  task automatic wr(bit rx, logic [31:0] a, logic [31:0] d);
    if (rx) reg_drv_rx.send_write(a, d, 'hf, reg_error);
    else    reg_drv_tx.send_write(a, d, 'hf, reg_error);
    @(posedge s_clk);
  endtask

  task automatic rd(bit rx, logic [31:0] a, output logic [31:0] d);
    if (rx) reg_drv_rx.send_read(a, d, reg_error);
    else    reg_drv_tx.send_read(a, d, reg_error);
    @(posedge s_clk);
  endtask

  // Start one DMA and wait for RSP_VALID, then clear it (1 then 0)
  task automatic dma(bit rx, logic [31:0] src, logic [31:0] dst, logic [31:0] len);
    logic [31:0] v;
    wr(rx, SRC_ADDR, src);
    wr(rx, DST_ADDR, dst);
    if (!rx) wr(rx, LENGTH, len);
    wr(rx, SRC_PROT, rx ? 32'h5 : 32'h0);  // RX: AXIS -> AXI, TX: AXI -> AXIS
    wr(rx, DST_PROT, rx ? 32'h0 : 32'h5);
    do rd(rx, REQ_READY, v); while (!v[0]);
    wr(rx, REQ_VALID, 32'h1);
    do rd(rx, RSP_VALID, v); while (!v[0]);
    wr(rx, RSP_CLR, 32'h1);
    wr(rx, RSP_CLR, 32'h0);
  endtask

  task automatic send(int k);
    for (int i = 0; i < FLen[k]; i++)
      i_tx_axi_sim_mem.mem[k*Slot + i] = fbyte(k, i);
    dma(0, k*Slot, 0, FLen[k]);
  endtask

  // Wait up to tmo ns for the RX IRQ. got = 1 if it came.
  task automatic wait_irq(int tmo, output bit got);
    got = 0;
    fork
      begin wait (rx_irq === 1'b1); got = 1; end
      begin #(tmo * 1ns); end
    join_any
    disable fork;
  endtask

  // Take one frame with the RX DMA into slot s and compare it with frame k
  task automatic receive(int s, int k);
    logic [31:0] len;
    int bad = 0;
    repeat (4) @(posedge s_clk);  // LENGTH register updates 1 cycle after the IRQ
    rd(1, LENGTH, len);
    dma(1, 0, s*Slot, 0);
    wr(1, RSR, 32'h2);  // as in eth_idma_tb
    if (len[11:0] != FLen[k] + 4) begin
      $display("[%0t] FAIL slot %0d: length %0d, expected %0d (frame %0d)",
               $time, s, len[11:0], FLen[k] + 4, k);
      errors++;
    end
    for (int i = 0; i < FLen[k]; i++)
      if (i_rx_axi_sim_mem.mem[s*Slot + i] !== fbyte(k, i)) bad++;
    if (bad != 0) begin
      $display("[%0t] FAIL slot %0d: %0d of %0d bytes differ from frame %0d",
               $time, s, bad, FLen[k], k);
      for (int i = 0; i < 16; i++) $display("  byte %0d: got %02x exp %02x", i, i_rx_axi_sim_mem.mem[s*Slot + i], fbyte(k, i));
      errors++;
    end else begin
      $display("[%0t] ok   slot %0d: frame %0d, %0d bytes", $time, s, k, FLen[k]);
    end
    // wait for the IRQ of this frame to drop (HoldOff gap)
    wait (rx_irq === 1'b0);
  endtask

  // ------------------------------------------------------------------- test

  initial begin
    bit got;
    int kept;

    reg_drv_tx.reset_master();
    reg_drv_rx.reset_master();
    @(posedge s_rst_n);
    repeat (10) @(posedge s_clk);

    wr(0, LOW_ADDR, 32'h00890702);
    wr(0, MACHI,    32'h00002301);
    wr(1, LOW_ADDR, 32'h89000123);
    wr(1, MACHI,    32'h00800207);  // promiscuous

    // Test 1: 3 frames back to back, RX DMA idle meanwhile
    send(0);
    send(1);
    send(2);
    #(30us);  // all 3 frames are on the wire by now

    kept = 0;
    for (int s = 0; s < 3; s++) begin
      wait_irq(5000, got);
      if (!got) break;
      receive(s, s);
      kept++;
    end
    if (kept != ExpKept) begin
      $display("FAIL test 1: %0d frames received from a burst of 3, expected %0d",
               kept, ExpKept);
      errors++;
    end else begin
      $display("ok   test 1: %0d of 3 burst frames received (expected %0d)", kept, ExpKept);
    end

    // Test 2: queue recovers
    send(3);
    wait_irq(30000, got);
    if (!got) begin
      $display("FAIL test 2: no RX IRQ for frame 3");
      errors++;
    end else begin
      receive(3, 3);
    end

    // Test 3: sticky RSP_VALID
    dma(0, 3*Slot, 0, FLen[3]);   // dma() already cleared; start another one
    wr(0, SRC_ADDR, 3*Slot);
    wr(0, LENGTH, FLen[3]);
    wr(0, REQ_VALID, 32'h1);
    repeat (200) @(posedge s_clk);
    rd(0, RSP_VALID, rdata);
    if (!rdata[0]) begin
      $display("FAIL test 3: RSP_VALID cleared itself"); errors++;
    end
    wr(0, RSP_CLR, 32'h1);
    wr(0, RSP_CLR, 32'h0);
    rd(0, RSP_VALID, rdata);
    if (rdata[0]) begin
      $display("FAIL test 3: RSP_VALID not cleared by RSP_VALID_CLR"); errors++;
    end
    if (errors == 0) $display("ok   test 3: RSP_VALID sticky and cleared by SW");

    // drain the two extra TX frames on the RX side
    for (int n = 0; n < 2; n++) begin
      wait_irq(30000, got);
      if (got) receive(4 + n, 3);
    end

    if (errors == 0) $display("Test PASS");
    else             $display("Test FAIL (%0d errors)", errors);
    done = 1;
    $finish;
  end

  initial begin
    #(2ms);
    $display("Test FAIL: global timeout");
    $finish;
  end

endmodule
