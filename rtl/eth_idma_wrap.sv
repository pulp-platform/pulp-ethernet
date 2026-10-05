// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>


`include "axi/typedef.svh"
`include "axi_stream/typedef.svh"
`include "idma/typedef.svh"

module eth_idma_wrap #(
  /// Data width
  parameter int unsigned DataWidth           = 32'd32,
  /// Address width
  parameter int unsigned AddrWidth           = 32'd32,
  /// AXI User width
  parameter int unsigned UserWidth           = 32'd1,
  /// AXI ID width
  parameter int unsigned AxiIdWidth          = 32'd1,
  /// Number of transaction that can be in-flight concurrently
  parameter int unsigned NumAxInFlight       = 32'd3,
  /// The depth of the internal reorder buffer
  parameter int unsigned BufferDepth         = 32'd3,
  /// With of a transfer: max transfer size is `2**TFLenWidth` bytes
  parameter int unsigned TFLenWidth          = 32'd32,
  /// The depth of the memory system the backend is attached to
  parameter int unsigned MemSysDepth         = 32'd0,
  parameter bit CombinedShifter              = 1'b1,
  /// hardware legalization present
  parameter bit HardwareLegalizer            = 1'b1,
  /// Reject zero-length transfers
  parameter bit RejectZeroTransfers          = 1'b1,
  /// CDC FIFO
  parameter int unsigned TxFifoLogDepth      = 32'd5,
  parameter int unsigned RxFifoLogDepth      = 32'd3,
  /// AXI4+ATOP Request and Response channel type
  parameter type axi_req_t                   = logic,
  parameter type axi_rsp_t                   = logic,
  /// Register Request and Response type
  parameter type reg_req_t                   = logic,
  parameter type reg_rsp_t                   = logic
)(
  input  logic                    clk_i,
  input  logic                    rst_ni,
  /// Etherent clocks
  input  logic                    eth_clk125_i,
  input  logic                    eth_clk125q_i,
  /// Only for Genesys2 delay control
  input  logic                    eth_clk200_i,
  /// Ethernet: 1000BASE-T RGMII
  input  logic                    phy_rx_clk_i,
  input  logic    [3:0]           phy_rxd_i,
  input  logic                    phy_rx_ctl_i,
  output logic                    phy_tx_clk_o,
  output logic    [3:0]           phy_txd_o,
  output logic                    phy_tx_ctl_o,
  output logic                    phy_resetn_o,
  input  logic                    phy_intn_i,
  input  logic                    phy_pme_i,
  /// Ethernet MDIO
  input  logic                    phy_mdio_i,
  output logic                    phy_mdio_o,
  output logic                    phy_mdio_oe,
  output logic                    phy_mdc_o,
  /// iDMA testmode
  input  logic                    testmode_i,
  /// iDMA AXI Interface
  output axi_req_t                axi_req_o,
  input  axi_rsp_t                axi_rsp_i,
  /// iDMA Busy Signal
  output idma_pkg::idma_busy_t    idma_busy_o,
  /// Register Configuration Interface
  input  reg_req_t      reg_req_i,
  output reg_rsp_t      reg_rsp_o,
  output logic          eth_rx_irq_o
);
  import eth_idma_reg_pkg::*;
  import idma_pkg::*;

  localparam int unsigned RegAddrWidth = 8;
  localparam int unsigned StrbWidth    = DataWidth / 8;

  eth_idma_reg2hw_t reg2hw, reg2hw_eth; // Write
  eth_idma_hw2reg_t hw2reg, hw2reg_eth; // Read

  logic phy_rx_clk;

  (* mark_debug = "true" *) logic req_valid_sync, req_valid;

  assign phy_rx_clk   = phy_rx_clk_i;

  eth_idma_reg_top #(
    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t),
    .AW(RegAddrWidth)
  ) i_regs (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .reg_req_i(reg_req_i),
    .reg_rsp_o(reg_rsp_o),
    .reg2hw(reg2hw), // Write
    .hw2reg(hw2reg), // Read
    .devmode_i(1'b1)
  );

  /// Address type
  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [StrbWidth-1:0]   strb_t;
  typedef logic [UserWidth-1:0]   user_t;
  typedef logic [AxiIdWidth-1:0]  id_t;
  typedef logic [TFLenWidth-1:0]  tf_len_t;

  /// AXI typedefs
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)

  /// AXI Stream typedefs
  `AXI_STREAM_TYPEDEF_S_CHAN_T(axis_t_chan_t, data_t, strb_t, strb_t, id_t, id_t, user_t)
  `AXI_STREAM_TYPEDEF_REQ_T(axi_stream_req_t, axis_t_chan_t)
  `AXI_STREAM_TYPEDEF_RSP_T(axi_stream_rsp_t)

  /// Meta Channel Widths
  localparam int unsigned axi_aw_chan_width = axi_pkg::aw_width(AddrWidth, AxiIdWidth, UserWidth);
  localparam int unsigned axi_ar_chan_width = axi_pkg::ar_width(AddrWidth, AxiIdWidth, UserWidth);
  localparam int unsigned axis_t_chan_width = $bits(axis_t_chan_t);

  /// iDMA req and rsp typedefs
  `IDMA_TYPEDEF_OPTIONS_T(options_t, id_t)
  `IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, addr_t, options_t)
  `IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, addr_t)
  `IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)
  function int unsigned max_width(input int unsigned a, b);
      return (a > b) ? a : b;
  endfunction

  typedef struct packed {
    axi_ar_chan_t ar_chan;
    logic[max_width(axi_ar_chan_width, axis_t_chan_width)-axi_ar_chan_width:0] padding;
  } axi_read_ar_chan_padded_t;

  typedef struct packed {
    axis_t_chan_t t_chan;
    logic[max_width(axi_ar_chan_width, axis_t_chan_width)-axis_t_chan_width:0] padding;
  } axis_read_t_chan_padded_t;

  typedef union packed {
    axi_read_ar_chan_padded_t axi;
    axis_read_t_chan_padded_t axis;
  } read_meta_channel_t;

  typedef struct packed {
    axi_aw_chan_t aw_chan;
    logic[max_width(axi_aw_chan_width, axis_t_chan_width)-axi_aw_chan_width:0] padding;
  } axi_write_aw_chan_padded_t;

  typedef struct packed {
    axis_t_chan_t t_chan;
    logic[max_width(axi_aw_chan_width, axis_t_chan_width)-axis_t_chan_width:0] padding;
  } axis_write_t_chan_padded_t;

  typedef union packed {
    axi_write_aw_chan_padded_t axi;
    axis_write_t_chan_padded_t axis;
  } write_meta_channel_t;

  (* mark_debug = "true" *)logic idma_req_ready, idma_rsp_valid, rsp_valid;
  logic idma_rsp_ready;
  logic [11:0] eth_len, eth_len_q;
  logic rx_complete, rx_complete_sync, rx_complete_sync_q, rx_avail_q;
  logic eth_rx_irq_phy, eth_rx_irq_sync;
  logic tx_busy;
  logic sync;
  logic rx_en;

  /// Request handshake, directional qualification & toggle CDC signals
  logic is_rx_dma, rx_dma_done;
  logic rsp_dir_is_rx, dir_fifo_full, dir_fifo_empty;
  logic req_valid_q, req_pending_q, req_hs;
  logic rsp_valid_clr_q, rsp_valid_clr_pulse;
  logic rx_done_tog_q;
  logic [5:0] sw_rsp_cnt_q;
  tf_len_t sw_len_q;

  /// AXI request and response
  axi_req_t axi_read_req;
  axi_req_t axi_write_req;
  axi_rsp_t axi_read_rsp;
  axi_rsp_t axi_write_rsp;

  /// AXI Stream request and response
  (* mark_debug = "true" *) axi_stream_rsp_t idma_axis_read_rsp;
  (* mark_debug = "true" *) axi_stream_req_t idma_axis_read_req;
  axi_stream_req_t eth_axis_tx_req;
  axi_stream_req_t idma_axis_write_req;
  axi_stream_rsp_t idma_axis_write_rsp, eth_axis_tx_rsp;
  (* mark_debug = "true" *)  axi_stream_req_t eth_axis_rx_req;
  (* mark_debug = "true" *) axi_stream_rsp_t eth_axis_rx_rsp;
  /// iDMA request and response
  (* mark_debug = "true" *) idma_req_t idma_reg_req;
  (* mark_debug = "true" *) idma_rsp_t idma_reg_rsp;

  logic rsp_valid_clr;
  logic idma_axis_read_rsp_tready_sync;

  assign idma_reg_req.src_addr                   = reg2hw.src_addr.q;
  assign idma_reg_req.dst_addr                   = reg2hw.dst_addr.q;

  assign idma_reg_req.opt.src_protocol           = idma_pkg::protocol_e'(reg2hw.src_protocol.q);
  assign idma_reg_req.opt.dst_protocol           = idma_pkg::protocol_e'(reg2hw.dst_protocol.q);

  assign is_rx_dma                               = (idma_reg_req.opt.src_protocol == idma_pkg::AXI_STREAM);

  assign idma_reg_req.opt.axi_id                 = reg2hw.axi_id.q;

  assign idma_reg_req.opt.src.burst              = reg2hw.opt_src.burst.q;
  assign idma_reg_req.opt.src.cache              = reg2hw.opt_src.cache.q;
  assign idma_reg_req.opt.src.lock               = reg2hw.opt_src.lock.q;
  assign idma_reg_req.opt.src.prot               = reg2hw.opt_src.prot.q;
  assign idma_reg_req.opt.src.qos                = reg2hw.opt_src.qos.q;
  assign idma_reg_req.opt.src.region             = reg2hw.opt_src.region.q;

  assign idma_reg_req.opt.dst.burst              = reg2hw.opt_dst.burst.q;
  assign idma_reg_req.opt.dst.cache              = reg2hw.opt_dst.cache.q;
  assign idma_reg_req.opt.dst.lock               = reg2hw.opt_dst.lock.q;
  assign idma_reg_req.opt.dst.prot               = reg2hw.opt_dst.prot.q;
  assign idma_reg_req.opt.dst.qos                = reg2hw.opt_dst.qos.q;
  assign idma_reg_req.opt.dst.region             = reg2hw.opt_dst.region.q;

  assign idma_reg_req.opt.beo.decouple_aw        = reg2hw.beo.decouple_aw.q;
  assign idma_reg_req.opt.beo.decouple_rw        = reg2hw.beo.decouple_rw.q;
  assign idma_reg_req.opt.beo.src_max_llen       = reg2hw.beo.src_max_llen.q;
  assign idma_reg_req.opt.beo.dst_max_llen       = reg2hw.beo.dst_max_llen.q;
  assign idma_reg_req.opt.beo.src_reduce_len     = reg2hw.beo.src_reduce_len.q;
  assign idma_reg_req.opt.beo.dst_reduce_len     = reg2hw.beo.dst_reduce_len.q;

  assign idma_reg_req.opt.last                   = reg2hw.last.q;

  assign req_valid                               = reg2hw.req_valid.q;
  assign idma_rsp_ready                          = 1'b1;

  // Synchronize rx_complete and eth_rx_irq_phy from phy_rx_clk into clk_i so
  // software status reads, PLIC interrupt output, and eth_len sampling are CDC-clean.
  sync #(
    .STAGES     ( 32'd3      ),
    .ResetValue ( 1'b0       )
  ) i_rx_complete_sync (
    .clk_i    ( clk_i            ),
    .rst_ni   ( rst_ni           ),
    .serial_i ( rx_complete      ),
    .serial_o ( rx_complete_sync )
  );

  sync #(
    .STAGES     ( 32'd3      ),
    .ResetValue ( 1'b0       )
  ) i_rx_irq_reg_sync (
    .clk_i    ( clk_i            ),
    .rst_ni   ( rst_ni           ),
    .serial_i ( eth_rx_irq_phy   ),
    .serial_o ( eth_rx_irq_sync  )
  );

  // Hold req_pending_q high from software REQ_VALID rising edge until backend
  // accepts the request (req_hs = req_pending_q & idma_req_ready).
  assign req_hs         = req_pending_q & idma_req_ready;
  assign req_valid_sync = req_pending_q;
  assign rx_dma_done    = idma_rsp_valid & idma_rsp_ready & ~dir_fifo_empty & rsp_dir_is_rx;

  // Local clk_i RX availability flag (rx_avail_q): set on rising edge of
  // rx_complete_sync and cleared immediately in clk_i when the RX DMA
  // completes, preventing stale RSR.rx_complete reads or spurious PLIC
  // re-pendings during the CDC clear round-trip.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_valid_q        <= 1'b0;
      req_pending_q      <= 1'b0;
      rsp_valid_clr_q    <= 1'b0;
      rx_complete_sync_q <= 1'b0;
      rx_avail_q         <= 1'b0;
    end else begin
      req_valid_q        <= req_valid;
      rsp_valid_clr_q    <= rsp_valid_clr;
      rx_complete_sync_q <= rx_complete_sync;

      if (req_valid & ~req_valid_q) begin
        req_pending_q <= 1'b1;
      end else if (req_hs) begin
        req_pending_q <= 1'b0;
      end

      if (rx_complete_sync & ~rx_complete_sync_q) begin
        rx_avail_q <= 1'b1;
      end else if (rx_dma_done) begin
        rx_avail_q <= 1'b0;
      end
    end
  end
  assign rsp_valid_clr_pulse = rsp_valid_clr & ~rsp_valid_clr_q;

  always_comb begin
    hw2reg.req_valid.d  = 1'b0;
    hw2reg.req_valid.de = req_hs;
  end

  // Track request direction (1 = RX, 0 = TX) at request handshake time
  // and pop at response completion time.
  fifo_v3 #(
    .DATA_WIDTH ( 32'd1         ),
    .DEPTH      ( NumAxInFlight )
  ) i_dir_fifo (
    .clk_i      ( clk_i                           ),
    .rst_ni     ( rst_ni                          ),
    .flush_i    ( 1'b0                            ),
    .testmode_i ( testmode_i                      ),
    .full_o     ( dir_fifo_full                   ),
    .empty_o    ( dir_fifo_empty                  ),
    .usage_o    (                                 ),
    .data_i     ( is_rx_dma                       ),
    .push_i     ( req_hs                          ),
    .data_o     ( rsp_dir_is_rx                   ),
    .pop_i      ( idma_rsp_valid & idma_rsp_ready )
  );

  idma_backend_rw_axi_rw_axis #(
    .DataWidth            ( DataWidth            ),
    .AddrWidth            ( AddrWidth            ),
    .AxiIdWidth           ( AxiIdWidth           ),
    .UserWidth            ( UserWidth            ),
    .TFLenWidth           ( TFLenWidth           ),
    .BufferDepth          ( BufferDepth          ),
    .NumAxInFlight        ( NumAxInFlight        ),
    .MemSysDepth          ( MemSysDepth          ),
    .HardwareLegalizer    ( HardwareLegalizer    ),
    .RejectZeroTransfers  ( RejectZeroTransfers  ),
    .idma_req_t           ( idma_req_t           ),
    .idma_rsp_t           ( idma_rsp_t           ),
    .idma_busy_t          ( idma_busy_t          ),
    .axi_req_t            ( axi_req_t            ),
    .axi_rsp_t            ( axi_rsp_t            ),
    .axis_req_t           ( axi_stream_req_t     ),
    .axis_rsp_t           ( axi_stream_rsp_t     ),
    .write_meta_channel_t ( write_meta_channel_t ),
    .read_meta_channel_t  ( read_meta_channel_t  )
  ) i_idma_backend (
    .clk_i                ( clk_i                ),
    .rst_ni               ( rst_ni               ),
    .testmode_i           ( testmode_i           ),
    .idma_eh_req_i        ( '0                   ),
    .eh_req_valid_i       ( '0                   ),
    .idma_req_i           ( idma_reg_req         ),
    .req_valid_i          ( req_pending_q        ),
    .req_ready_o          ( idma_req_ready       ),
    .idma_rsp_o           ( idma_reg_rsp         ),
    .rsp_valid_o          ( idma_rsp_valid       ),
    .rsp_ready_i          ( idma_rsp_ready       ),
    .axi_write_req_o      ( axi_write_req        ),
    .axi_write_rsp_i      ( axi_write_rsp        ),
    .axi_read_req_o       ( axi_read_req         ),
    .axi_read_rsp_i       ( axi_read_rsp         ),
    .axis_read_req_i      ( idma_axis_read_req   ),
    .axis_read_rsp_o      ( idma_axis_read_rsp   ),
    .axis_write_req_o     ( idma_axis_write_req  ),
    .axis_write_rsp_i     ( idma_axis_write_rsp  ),
    .busy_o               ( idma_busy_o          )
  );

  eth_top #(
    .DataWidth          (  DataWidth         ),
    .RegAddrWidth       (  RegAddrWidth      ),
    .IdWidth            (  AxiIdWidth        ),
    .DestWidth          (  AxiIdWidth        ),
    .axi_stream_req_t   (  axi_stream_req_t  ),
    .axi_stream_rsp_t   (  axi_stream_rsp_t  ),
    .reg2hw_itf_t       (  eth_idma_reg2hw_t ),
    .hw2reg_itf_t       (  eth_idma_hw2reg_t )
  ) i_eth_top (
    .rst_ni             (  rst_ni            ),
    .clk_i              (  eth_clk125_i      ),
    .clk90_int          (  eth_clk125q_i     ),
    .clk200_int         (  eth_clk200_i      ),
    .phy_rx_clk         (  phy_rx_clk        ),
    .phy_rxd            (  phy_rxd_i         ),
    .phy_rx_ctl         (  phy_rx_ctl_i      ),
    .phy_tx_clk         (  phy_tx_clk_o      ),
    .phy_txd            (  phy_txd_o         ),
    .phy_tx_ctl         (  phy_tx_ctl_o      ),
    .phy_reset_n        (  phy_resetn_o      ),
    .phy_int_n          (  phy_intn_i        ),
    .phy_pme_n          (  phy_pme_i         ),
    .phy_mdio_i         (  phy_mdio_i        ),
    .phy_mdio_o         (  phy_mdio_o        ),
    .phy_mdio_oe        (  phy_mdio_oe       ),
    .phy_mdc            (  phy_mdc_o         ),
    .tx_axis_req_i      (  eth_axis_tx_req   ),
    .tx_axis_rsp_o      (  eth_axis_tx_rsp   ),
    .rx_axis_req_o      (  eth_axis_rx_req   ),
    .rx_axis_rsp_i      (  eth_axis_rx_rsp   ),
    .reg2hw_i           (  reg2hw_eth        ),
    .hw2reg_o           (  hw2reg_eth        ),
    .eth_rx_irq_o       (  eth_rx_irq_phy    ),
    .rsp_valid_i        (  rx_done_tog_q     ),
    .eth_len_o          (  eth_len           ),
    .rx_complete_o      (  rx_complete       ),
    .tx_busy_o          (  tx_busy           ),
    .sync_o             (  sync              )
  );

  // Module interrupt output: clears in the exact same clk_i cycle as rx_avail_q
  assign eth_rx_irq_o = eth_rx_irq_sync & rx_avail_q;

  assign hw2reg.rsp_valid.de = 1'b1;
  assign hw2reg.rsp_valid.d  = rsp_valid;
  assign hw2reg.req_ready.de = 1'b1;
  assign hw2reg.req_ready.d  = idma_req_ready;
  assign hw2reg.rsp_ready.de = 1'b1;
  assign hw2reg.rsp_ready.d  = idma_rsp_ready;

  assign hw2reg.low_addr             = '0;
  assign hw2reg.machi                = '0;
  assign hw2reg.mdio.mdio_clk        = '0;
  assign hw2reg.mdio.mdio_o          = '0;
  assign hw2reg.mdio.mdio_oe         = '0;
  assign hw2reg.mdio.mdio_i          = hw2reg_eth.mdio.mdio_i;
  assign hw2reg.axi_id               = '0;
  assign hw2reg.last                 = '0;
  assign hw2reg.rsr.rx_irq.de        = 1'b1;
  assign hw2reg.rsr.rx_irq.d         = eth_rx_irq_sync & rx_avail_q;
  assign hw2reg.rsr.rx_complete.de   = 1'b1;
  assign hw2reg.rsr.rx_complete.d    = rx_avail_q;
  assign hw2reg.tx_busy              = hw2reg_eth.tx_busy;
  assign hw2reg.tx_fcs               = hw2reg_eth.tx_fcs;
  assign hw2reg.rx_fcs               = hw2reg_eth.rx_fcs;

  assign reg2hw_eth.machi    = reg2hw.machi;
  assign reg2hw_eth.low_addr = reg2hw.low_addr;
  assign reg2hw_eth.mdio     = reg2hw.mdio;
  assign rsp_valid_clr       = reg2hw.rsp_valid_clr.q;

  // Workaround to preserve register-map compatibility without a dedicated
  // RX-length register: latch software TX length writes on a valid register
  // bus handshake using ETH_IDMA_LENGTH_OFFSET (&wstrb[1:0] for 12-bit length),
  // and sample eth_len in clk_i when rx_complete_sync is asserted.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sw_len_q  <= '0;
      eth_len_q <= '0;
    end else begin
      if (reg_req_i.valid && reg_rsp_o.ready && reg_req_i.write &&
          (&reg_req_i.wstrb[1:0]) &&
          (reg_req_i.addr[RegAddrWidth-1:0] == ETH_IDMA_LENGTH_OFFSET)) begin
        sw_len_q <= tf_len_t'(reg_req_i.wdata);
      end
      if (rx_complete_sync) begin
        eth_len_q <= eth_len;
      end
    end
  end

  always_comb begin
    idma_reg_req.length = is_rx_dma ? tf_len_t'(eth_len_q) : sw_len_q;
    hw2reg.length.de    = 1'b0;
    hw2reg.length.d     = 12'b0;
    if (rx_avail_q) begin
      hw2reg.length.de  = 1'b1;
      hw2reg.length.d   = eth_len_q;
    end
  end

  // 1. Toggle-based RX completion CDC (rx_done_tog_q -> framing_top i_rsp_sync
  // + XOR edge detector): ratio-independent and never merges completions.
  // 2. Software-visible completion status (rsp_valid) re-triggers on any
  // completion and supports explicit software clear via rsp_valid_clr.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_done_tog_q <= 1'b0;
      rsp_valid     <= 1'b0;
      sw_rsp_cnt_q  <= 6'b0;
    end else begin
      if (rx_dma_done) begin
        rx_done_tog_q <= ~rx_done_tog_q;
      end

      if (rsp_valid_clr_pulse) begin
        rsp_valid    <= 1'b0;
        sw_rsp_cnt_q <= 6'd0;
      end else if (idma_rsp_valid) begin
        rsp_valid    <= 1'b1;
        sw_rsp_cnt_q <= 6'd1;
      end else if (rsp_valid) begin
        if (sw_rsp_cnt_q == 6'b111111) begin
          rsp_valid    <= 1'b0;
          sw_rsp_cnt_q <= 6'd0;
        end else begin
          sw_rsp_cnt_q <= sw_rsp_cnt_q + 6'd1;
        end
      end
    end
  end


  // TX CDC FIFO
  cdc_fifo_gray #(
    .T           ( axis_t_chan_t   ),
    .LOG_DEPTH   ( TxFifoLogDepth  ),
    .SYNC_STAGES ( 3 )
  ) i_cdc_fifo_tx (
    .src_rst_ni     ( rst_ni                     ),
    .src_clk_i      ( clk_i                      ),
    .src_data_i     ( idma_axis_write_req.t      ),
    .src_valid_i    ( idma_axis_write_req.tvalid ),
    .src_ready_o    ( idma_axis_write_rsp.tready ),
    .dst_rst_ni     ( rst_ni                     ),
    .dst_clk_i      ( eth_clk125_i               ),
    .dst_data_o     ( eth_axis_tx_req.t          ),
    .dst_valid_o    ( eth_axis_tx_req.tvalid     ),
    .dst_ready_i    ( eth_axis_tx_rsp.tready     )
  );

  // RX CDC FIFO
  cdc_fifo_gray #(
    .T           ( axis_t_chan_t  ),
    .LOG_DEPTH   ( RxFifoLogDepth ),
    .SYNC_STAGES ( 3 )
  ) i_cdc_fifo_rx (
    .src_rst_ni     ( rst_ni                    ),
    .src_clk_i      ( phy_rx_clk                ),
    .src_data_i     ( eth_axis_rx_req.t         ),
    .src_valid_i    ( eth_axis_rx_req.tvalid    ),
    .src_ready_o    ( eth_axis_rx_rsp.tready    ),
    .dst_rst_ni     ( rst_ni                    ),
    .dst_clk_i      ( clk_i                     ),
    .dst_data_o     ( idma_axis_read_req.t      ),
    .dst_valid_o    ( idma_axis_read_req.tvalid ),
    .dst_ready_i    ( idma_axis_read_rsp.tready )
  );

  axi_rw_join #(
    .axi_req_t   ( axi_req_t ),
    .axi_resp_t  ( axi_rsp_t )
  ) i_axi_tx_rw_join (
    .clk_i            ( clk_i         ),
    .rst_ni           ( rst_ni        ),
    .slv_read_req_i   ( axi_read_req  ),
    .slv_read_resp_o  ( axi_read_rsp  ),
    .slv_write_req_i  ( axi_write_req ),
    .slv_write_resp_o ( axi_write_rsp ),
    .mst_req_o        ( axi_req_o     ),
    .mst_resp_i       ( axi_rsp_i     )
  );

  `ifndef SYNTHESIS
  // Assertions to verify request handshake and direction FIFO integrity
  assert property (@(posedge clk_i) disable iff (!rst_ni)
    !(req_valid & ~req_valid_q & req_pending_q))
    else $error("[eth_idma_wrap] New SW request issued while previous request still pending!");

  assert property (@(posedge clk_i) disable iff (!rst_ni)
    req_hs |-> !dir_fifo_full)
    else $error("[eth_idma_wrap] i_dir_fifo overflow!");

  assert property (@(posedge clk_i) disable iff (!rst_ni)
    (idma_rsp_valid & idma_rsp_ready) |-> !dir_fifo_empty)
    else $error("[eth_idma_wrap] i_dir_fifo underflow on completion!");
  `endif

endmodule : eth_idma_wrap
