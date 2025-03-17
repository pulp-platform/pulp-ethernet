// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>

import eth_pkg::*;

module eth_synth (
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
  (* keep = "true" *) input  logic                    phy_intn_i,
  (* keep = "true" *) input  logic                    phy_pme_i,
  /// Ethernet MDIO
  (* keep = "true" *) input  logic                    phy_mdio_i,
  output logic                    phy_mdio_o,
  output logic                    phy_mdio_oe,
  output logic                    phy_mdc_o,
  /// iDMA testmode
  (* keep = "true" *) input  logic                    testmode_i,
  /// iDMA AXI Interface
  output axi_req_t                axi_req_o,
  input  axi_resp_t               axi_rsp_i,
  /// Register Configuration Interface
  input  reg_req_t                reg_req_i,
  output reg_rsp_t                reg_rsp_o,
  output logic                    eth_rx_irq_o
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
    .CombinedShifter     ( CombinedShifter     ),
    .HardwareLegalizer   ( HardwareLegalizer   ),
    .RejectZeroTransfers ( RejectZeroTransfers ),
    .TxFifoLogDepth      ( TxFifoLogDepth      ),
    .RxFifoLogDepth      ( RxFifoLogDepth      ),
    .axi_req_t           ( axi_req_t           ),
    .axi_rsp_t           ( axi_resp_t          ),
    .reg_req_t           ( reg_req_t           ),
    .reg_rsp_t           ( reg_rsp_t           )
  ) i_eth_idma_wrap (
    .clk_i               ( clk_i               ),
    .rst_ni              ( rst_ni              ),
     /// Etherent Internal clocks
    .eth_clk125_i        ( eth_clk125_i        ), // 125MHz in-phase
    .eth_clk125q_i       ( eth_clk125q_i       ), // 125 MHz with 90 phase shift
    .eth_clk200_i        ( eth_clk200_i        ),
    .phy_rx_clk_i        ( phy_rx_clk_i        ),
    .phy_rxd_i           ( phy_rxd_i           ),
    .phy_rx_ctl_i        ( phy_rx_ctl_i        ),
    .phy_tx_clk_o        ( phy_tx_clk_o        ),
    .phy_txd_o           ( phy_txd_o           ),
    .phy_tx_ctl_o        ( phy_tx_ctl_o        ),
    .phy_resetn_o        ( phy_resetn_o        ),
    .phy_intn_i          ( phy_intn_i          ),
    .phy_pme_i           ( phy_pme_i           ),
    .phy_mdio_i          ( phy_mdio_i          ),
    .phy_mdio_o          ( phy_mdio_o          ),
    .phy_mdio_oe         ( phy_mdio_oe         ),
    .phy_mdc_o           ( phy_mdc_o           ),
    .reg_req_i           ( reg_req_i           ),
    .reg_rsp_o           ( reg_rsp_o           ),
    .testmode_i          ( testmode_i          ),
    .axi_req_o           ( axi_req_o           ),
    .axi_rsp_i           ( axi_rsp_i           ),
    .eth_rx_irq_o        ( eth_rx_irq_o        )
  );

endmodule;
