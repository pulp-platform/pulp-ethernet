// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>
 
`include "axi/typedef.svh"
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
  parameter bit HardwareLegalizer   = 1'b1,
  /// Reject zero-length transfers
  parameter bit RejectZeroTransfers = 1'b1,
  /// CDC FIFO
  parameter int unsigned TxFifoLogDepth      = 32'd8,
  parameter int unsigned RxFifoLogDepth      = 32'd8,
  /// AXI4+ATOP Request and Response channel type
  parameter type axi_req_t                   = logic,
  parameter type axi_rsp_t                   = logic,
  /// Register Request and Response type
  parameter type reg_req_t                   = logic,
  parameter type reg_rsp_t                   = logic
)(
  input  logic                    clk_i,
  input  logic                    rst_ni, 
  /// Etherent Internal clocks
  input  logic                    eth_clk_i, 
  input  logic                    eth_clk90_i,
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
  input  reg_req_t                reg_req_i,
  output reg_rsp_t                reg_rsp_o
);
  import eth_idma_reg_pkg::*;
  import idma_pkg::*;
    
  localparam int unsigned RegAddrWidth = 8; 
  localparam int unsigned StrbWidth     = DataWidth / 8;

  eth_idma_reg2hw_t reg2hw; // Write
  eth_idma_hw2reg_t hw2reg; // Read

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
  `IDMA_AXI_STREAM_TYPEDEF_S_CHAN_T(axis_t_chan_t, data_t, strb_t, strb_t, id_t, id_t, user_t)
  `IDMA_AXI_STREAM_TYPEDEF_REQ_T(axi_stream_req_t, axis_t_chan_t)
  `IDMA_AXI_STREAM_TYPEDEF_RSP_T(axi_stream_rsp_t)

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
  
  logic  idma_req_valid, idma_req_ready, idma_rsp_ready, idma_rsp_valid;  

  /// AXI request and response
  axi_req_t     axi_read_req,axi_write_req;
  axi_rsp_t     axi_read_rsp,axi_write_rsp;

  /// AXI Stream request and response
  axi_stream_rsp_t idma_axis_read_rsp, eth_axis_tx_rsp;  
  axi_stream_req_t idma_axis_read_req, eth_axis_tx_req;
  axi_stream_req_t idma_axis_write_req, eth_axis_rx_rsp;
  axi_stream_rsp_t idma_axis_write_rsp, eth_axis_rx_req;

  /// iDMA request and response
  idma_req_t idma_reg_req;
  idma_rsp_t idma_reg_rsp;

  assign idma_reg_req.length                     = reg2hw.length.q;
  assign idma_reg_req.src_addr                   = reg2hw.src_addr.q;
  assign idma_reg_req.dst_addr                   = reg2hw.dst_addr.q;

  assign idma_reg_req.opt.src_protocol           = idma_pkg::protocol_e'(reg2hw.src_protocol.q);
  assign idma_reg_req.opt.dst_protocol           = idma_pkg::protocol_e'(reg2hw.dst_protocol.q);
  
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

  assign idma_req_valid                          = reg2hw.req_valid.q;
  assign idma_rsp_ready                          = reg2hw.rsp_ready.q;

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
    .clk_i                ( clk_i             ),
    .rst_ni               ( rst_ni            ),
    .testmode_i           ( testmode_i        ),
    .idma_req_i           ( idma_reg_req      ),
    .req_valid_i          ( idma_req_valid    ), 
    .req_ready_o          ( idma_req_ready    ),  
    .idma_rsp_o           ( idma_reg_rsp      ),
    .rsp_valid_o          ( idma_rsp_valid    ),  
    .rsp_ready_i          ( idma_rsp_ready    ),
    .axi_write_req_o      ( axi_write_req     ),
    .axi_write_rsp_i      ( axi_write_rsp     ),
    .axi_read_req_o       ( axi_read_req      ),
    .axi_read_rsp_i       ( axi_read_rsp      ),
    .axis_read_req_i      ( idma_axis_read_req   ),
    .axis_read_rsp_o      ( idma_axis_read_rsp   ), 
    .axis_write_req_o     ( idma_axis_write_req  ), 
    .axis_write_rsp_i     ( idma_axis_write_rsp  ),
    .busy_o               ( idma_busy_o          )
  );

  eth_top #(
    .DataWidth          (  DataWidth         ), 
    .RegAddrWidth       (  RegAddrWidth      ),
    .axi_stream_req_t   (  axi_stream_req_t  ),
    .axi_stream_rsp_t   (  axi_stream_rsp_t  ),
    .reg2hw_itf_t       (  eth_idma_reg2hw_t ),
    .hw2reg_itf_t       (  eth_idma_hw2reg_t )
  ) i_eth_top (
    .rst_ni             (  rst_ni            ),
    .clk_i              (  eth_clk_i         ),
    .clk90_int          (  eth_clk90_i       ),
    .phy_rx_clk         (  phy_rx_clk_i      ),
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
    .phy_mdc            (  phy_mdc           ), 
    .tx_axis_req_i      (  eth_axis_tx_req   ), 
    .tx_axis_rsp_o      (  eth_axis_tx_rsp   ),
    .rx_axis_req_o      (  eth_axis_rx_rsp   ),
    .rx_axis_rsp_i      (  eth_axis_rx_req   ),
    .idma_req_ready     (  idma_req_ready    ),
    .idma_rsp_valid     (  idma_rsp_valid    ),        
    .reg2hw_i           (  reg2hw            ),
    .hw2reg_o           (  hw2reg            )
  );
  
  // TX CDC FIFO
  cdc_fifo_gray #(
    .T           ( axis_t_chan_t   ),
    .LOG_DEPTH   ( TxFifoLogDepth  )
  ) i_cdc_fifo_tx (
    .src_rst_ni     ( rst_ni                     ),
    .src_clk_i      ( clk_i                      ),
    .src_data_i     ( idma_axis_write_req.t      ),
    .src_valid_i    ( idma_axis_write_req.tvalid ),
    .src_ready_o    ( idma_axis_write_rsp.tready ),
    .dst_rst_ni     ( rst_ni                     ),
    .dst_clk_i      ( eth_clk_i                  ),
    .dst_data_o     ( eth_axis_tx_req.t          ),
    .dst_valid_o    ( eth_axis_tx_req.tvalid     ),
    .dst_ready_i    ( eth_axis_tx_rsp.tready     )
  );

  // RX CDC FIFO
  cdc_fifo_gray #(
    .T           ( axis_t_chan_t  ),
    .LOG_DEPTH   ( RxFifoLogDepth )
  ) i_cdc_fifo_rx (
    .src_rst_ni     ( rst_ni                    ),
    .src_clk_i      ( eth_clk_i                 ),
    .src_data_i     ( eth_axis_rx_rsp.t         ),
    .src_valid_i    ( eth_axis_rx_rsp.tvalid    ),
    .src_ready_o    ( eth_axis_rx_req.tready    ),
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

endmodule : eth_idma_wrap