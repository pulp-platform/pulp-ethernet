// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Thiemo Zaugg <zauggth@ethz.ch>

`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module eth_top_synth (
  input  wire                                           rst_ni       ,
  input  wire                                           clk_i        ,
  input  wire                                           clk90_i      ,
  input  wire                                           clk_200MHz_i ,
  // Ethernet: 1000BASE-T RGMII
  input  wire                                           phy_rx_clk   ,
  input  wire     [3:0]                                 phy_rxd      ,
  input  wire                                           phy_rx_ctl   ,
  output wire                                           phy_tx_clk   ,
  output wire     [3:0]                                 phy_txd      ,
  output wire                                           phy_tx_ctl   ,
  output wire                                           phy_reset_n  ,
  input  wire                                           phy_int_n    ,
  input  wire                                           phy_pme_n    ,
  // MDIO
  input  wire                                           phy_mdio_i   ,
  output      reg                                       phy_mdio_o   ,
  output      reg                                       phy_mdio_oe  ,
  output wire                                           phy_mdc      ,

  // AXIS TX
  input       eth_top_pkg::axis_tdata_t                 tx_axis_tdata_i,
  input       eth_top_pkg::axis_tstrb_t                 tx_axis_tstrb_i,
  input       eth_top_pkg::axis_tkeep_t                 tx_axis_tkeep_i,
  input  logic                                          tx_axis_tlast_i,
  input       eth_top_pkg::axis_tid_t                   tx_axis_tid_i,
  input       eth_top_pkg::axis_tdest_t                 tx_axis_tdest_i,
  input       eth_top_pkg::axis_tuser_t                 tx_axis_tuser_i,
  input  logic                                          tx_axis_tvalid_i,
  output logic                                          tx_axis_tready_o,
  // AXIS RX
  output       eth_top_pkg::axis_tdata_t                 rx_axis_tdata_o,
  output       eth_top_pkg::axis_tstrb_t                 rx_axis_tstrb_o,
  output       eth_top_pkg::axis_tkeep_t                 rx_axis_tkeep_o,
  output logic                                           rx_axis_tlast_o,
  output       eth_top_pkg::axis_tid_t                   rx_axis_tid_o,
  output       eth_top_pkg::axis_tdest_t                 rx_axis_tdest_o,
  output       eth_top_pkg::axis_tuser_t                 rx_axis_tuser_o,
  output logic                                           rx_axis_tvalid_o,
  input  logic                                           rx_axis_tready_i,

  // configuration (register interface)
  input       eth_top_pkg::reg_bus_addr_t               reg_bus_addr_i,
  input logic                                           reg_bus_write_i,
  input       eth_top_pkg::reg_bus_data_t               reg_bus_wdata_i,
  input       eth_top_pkg::reg_bus_strb_t               reg_bus_wstrb_i,
  input logic                                           reg_bus_valid_i,
  output      eth_top_pkg::reg_bus_data_t               reg_bus_rdata_o,
  output logic                                          reg_bus_error_o,
  output logic                                          reg_bus_ready_o
);

eth_top_pkg::s_req_t tx_axis_req_i, rx_axis_req_o;
eth_top_pkg::s_rsp_t tx_axis_rsp_o, rx_axis_rsp_i;

eth_top_pkg::reg_bus_req_t reg_req_i;
eth_top_pkg::reg_bus_rsp_t reg_rsp_o;


  eth_top i_eth_top (
    .rst_ni      (rst_ni         ),
    .clk_i       (clk_i          ),
    .clk90_int   (clk_90_i       ),
    .clk_200_int (clk_200MHz_i   ),

    // Ethernet: 1000BASE-T RGMII
    .phy_rx_clk  (phy_rx_clk     ),
    .phy_rxd     (phy_rxd        ),
    .phy_rx_ctl  (phy_rx_ctl     ),

    .phy_tx_clk  (phy_tx_clk     ),
    .phy_txd     (phy_txd        ),
    .phy_tx_ctl  (phy_tx_ctl     ),

    .phy_reset_n (phy_reset_n    ),
    .phy_int_n   (phy_int_n      ),
    .phy_pme_n   (phy_pme_n      ),

    // MDIO
    .phy_mdio_i  (phy_mdio_i     ),
    .phy_mdio_o  (phy_mdio_o     ),
    .phy_mdio_oe (phy_mdio_oe    ),
    .phy_mdc     (phy_mdc        ),

    .tx_axis_req_i(tx_axis_req_i), // set tuser to 1'b0 to indicate no error
    .tx_axis_rsp_o(tx_axis_rsp_o),
    .rx_axis_req_o(rx_axis_req_o),
    .rx_axis_rsp_i(rx_axis_rsp_i),

    // Configuration Interface
    .reg_req_i    (reg_req_i),
    .reg_rsp_o    (reg_rsp_o)
  );

  // AXIS TX
  assign tx_axis_req_i.t.data = tx_axis_tdata_i;
  assign tx_axis_req_i.t.strb = tx_axis_tstrb_i;
  assign tx_axis_req_i.t.keep = tx_axis_tkeep_i;
  assign tx_axis_req_i.t.last = tx_axis_tlast_i;
  assign tx_axis_req_i.t.id  = tx_axis_tid_i;
  assign tx_axis_req_i.t.dest = tx_axis_tdest_i;
  assign tx_axis_req_i.t.user = tx_axis_tuser_i;
  assign tx_axis_req_i.tvalid = tx_axis_tvalid_i;
  assign tx_axis_tready_o     = tx_axis_rsp_o.tready;
  //AXIS RX
  assign rx_axis_tdata_o      = rx_axis_req_o.t.data;
  assign rx_axis_tstrb_o      = rx_axis_req_o.t.strb;
  assign rx_axis_tkeep_o      = rx_axis_req_o.t.keep;
  assign rx_axis_tlast_o      = rx_axis_req_o.t.last;
  assign rx_axis_tid_o        = rx_axis_req_o.t.id;
  assign rx_axis_tdest_o      = rx_axis_req_o.t.dest;
  assign rx_axis_tuser_o      = rx_axis_req_o.t.user;
  assign rx_axis_tvalid_o     = rx_axis_req_o.tvalid;
  assign rx_axis_rsp_i.tready = rx_axis_tready_i;


  // Regbus
  assign reg_req_i.addr       = reg_bus_addr_i;
  assign reg_req_i.write      = reg_bus_write_i;
  assign reg_req_i.wdata      = reg_bus_wdata_i;
  assign reg_req_i.wstrb      = reg_bus_wstrb_i;
  assign reg_req_i.valid      = reg_bus_valid_i;
  assign reg_bus_rdata_o      = reg_rsp_o.rdata;
  assign reg_bus_ready_o      = reg_rsp_o.ready;
  assign reg_bus_error_o      = reg_rsp_o.error;

endmodule : eth_top_synth
