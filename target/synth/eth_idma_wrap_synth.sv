// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Thiemo Zaugg <zauggth@ethz.ch>
// - Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "axi/port.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module eth_idma_wrap_synth #(
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
  /// Should the `R`-`AW` coupling hardware be present? (recommended)
  parameter bit          RAWCouplingAvail    = 1'b0,
  /// Mask invalid data on the manager interface
  parameter bit          MaskInvalidData     = 1'b1,
  parameter bit          CombinedShifter     = 1'b1,
  /// hardware legalization present
  parameter bit          HardwareLegalizer   = 1'b1,
  /// Reject zero-length transfers
  parameter bit          RejectZeroTransfers = 1'b1,
  /// Enable error handling
  parameter bit          ErrorHandling       = 1'b0,
  /// CDC FIFO
  parameter int unsigned TxFifoLogDepth      = 32'd8,
  parameter int unsigned RxFifoLogDepth      = 32'd8,
  /// Derived types
  parameter type id_t                        = logic    [AxiIdWidth-1 :0],
  parameter type addr_t                      = logic    [AddrWidth-1  :0],
  parameter type data_t                      = logic    [DataWidth-1  :0],
  parameter type strb_t                      = logic    [DataWidth/8-1:0],
  parameter type user_t                      = logic    [UserWidth-1  :0],
  parameter type reg_data_t                  = logic    [31           :0],
  parameter type reg_strb_t                  = logic    [3            :0]
)(
  input  logic                       clk_i,
  input  logic                       rst_ni,
  /// Ethernet: 1000BASE-T RGMII
  input  logic                       phy_rx_clk_i,
  input  logic    [3:0]              phy_rxd_i,
  input  logic                       phy_rx_ctl_i,
  output logic                       phy_tx_clk_o,
  output logic    [3:0]              phy_txd_o,
  output logic                       phy_tx_ctl_o,
  output logic                       phy_resetn_o,
  input  logic                       phy_intn_i,
  input  logic                       phy_pme_i,
  /// Ethernet MDIO
  input  logic                       phy_mdio_i,
  output logic                       phy_mdio_o,
  output logic                       phy_mdio_oe,
  output wire                        phy_mdc_o,
  /// iDMA testmode
  input  logic                       testmode_i,
  /// Error handler request
  input  idma_pkg::idma_eh_req_t     idma_eh_req_i,
  input  logic                       eh_req_valid_i,
  output logic                       eh_req_ready_o,
  /// AXI ports
  `AXI_M_PORT(eth, addr_t, data_t, strb_t, id_t, user_t, user_t, user_t, user_t, user_t)
  /// iDMA busy flags
  output idma_pkg::idma_busy_t       idma_busy_o,
  /// REGBUS Configuration Interface
  input  addr_t                     cfg_addr_i,
  input  reg_data_t                 cfg_wdata_i,
  input  reg_strb_t                 cfg_wstrb_i,
  input  logic                      cfg_write_i,
  input  logic                      cfg_valid_i,
  output reg_data_t                 cfg_rdata_o,
  output logic                      cfg_error_o,
  output logic                      cfg_ready_o
);

  `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t)

  axi_req_t  m_req;
  axi_resp_t m_rsp;

  `AXI_ASSIGN_MASTER_TO_FLAT(eth, m_req, m_rsp)

  `REG_BUS_TYPEDEF_ALL(cfg, addr_t, reg_data_t, reg_strb_t)

  cfg_req_t  cfg_req;
  cfg_rsp_t  cfg_rsp;

  assign cfg_req.addr  = cfg_addr_i;
  assign cfg_req.wdata = cfg_wdata_i;
  assign cfg_req.wstrb = cfg_wstrb_i;
  assign cfg_req.write = cfg_write_i;
  assign cfg_req.valid = cfg_valid_i;
  assign cfg_rdata_o   = cfg_rsp.rdata;
  assign cfg_error_o   = cfg_rsp.error;
  assign cfg_ready_o   = cfg_rsp.ready;

  /// DUT
  eth_idma_wrap#(
    .DataWidth           ( DataWidth           ),
    .AddrWidth           ( AddrWidth           ),
    .UserWidth           ( UserWidth           ),
    .AxiIdWidth          ( AxiIdWidth          ),
    .NumAxInFlight       ( NumAxInFlight       ),
    .BufferDepth         ( BufferDepth         ),
    .TFLenWidth          ( TFLenWidth          ),
    .MemSysDepth         ( MemSysDepth         ),
    .RAWCouplingAvail    ( RAWCouplingAvail    ),
    .HardwareLegalizer   ( HardwareLegalizer   ),
    .RejectZeroTransfers ( RejectZeroTransfers )
  ) i_eth_idma_wrap (
    .clk_i,
    .rst_ni,
     /// Etherent Internal clocks
    .phy_rx_clk_i,
    .phy_rxd_i,
    .phy_rx_ctl_i,
    .phy_tx_clk_o,
    .phy_txd_o,
    .phy_tx_ctl_o,
    .phy_resetn_o,
    .phy_intn_i,
    .phy_pme_i,
    .phy_mdio_i,
    .phy_mdio_o,
    .phy_mdio_oe,
    .phy_mdc_o,
    .reg_req_i      ( cfg_req ),
    .reg_rsp_o      ( cfg_rsp ),
    .testmode_i,
    .idma_eh_req_i,
    .eh_req_valid_i,
    .eh_req_ready_o,
    .axi_req_o      ( m_req ),
    .axi_rsp_i      ( m_rsp ),
    .idma_busy_o
  );

endmodule : eth_idma_wrap_synth
