// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Thiemo Zaugg <zauggth@ethz.ch>

`include "axi/assign.svh"

module eth_rgmii_synth (
  input       logic                 clk_i       , // Clock
  input       logic                 clk_200MHz_i,
  input       logic                 rst_ni      , // Asynchronous reset active low
  input       logic                 eth_clk_i   ,

  // AXI slave connection
  input       eth_rgmii_pkg::id_t   aw_id       ,
  input       eth_rgmii_pkg::addr_t aw_addr     ,
  input       axi_pkg::len_t        aw_len      ,
  input       axi_pkg::size_t       aw_size     ,
  input       axi_pkg::burst_t      aw_burst    ,
  input       logic                 aw_lock     ,
  input       axi_pkg::cache_t      aw_cache    ,
  input       axi_pkg::prot_t       aw_prot     ,
  input       axi_pkg::qos_t        aw_qos      ,
  input       axi_pkg::region_t     aw_region   ,
  input       axi_pkg::atop_t       aw_atop     ,
  input       eth_rgmii_pkg::user_t aw_user     ,
  input       logic                 aw_valid    ,
  output      logic                 aw_ready    ,
  input       eth_rgmii_pkg::data_t w_data      ,
  input       eth_rgmii_pkg::strb_t w_strb      ,
  input       logic                 w_last      ,
  input       eth_rgmii_pkg::user_t w_user      ,
  input       logic                 w_valid     ,
  output      logic                 w_ready     ,
  output      eth_rgmii_pkg::id_t   b_id        ,
  output      axi_pkg::resp_t       b_resp      ,
  output      eth_rgmii_pkg::user_t b_user      ,
  output      logic                 b_valid     ,
  input       logic                 b_ready     ,
  input       eth_rgmii_pkg::id_t   ar_id       ,
  input       eth_rgmii_pkg::addr_t ar_addr     ,
  input       axi_pkg::len_t        ar_len      ,
  input       axi_pkg::size_t       ar_size     ,
  input       axi_pkg::burst_t      ar_burst    ,
  input       logic                 ar_lock     ,
  input       axi_pkg::cache_t      ar_cache    ,
  input       axi_pkg::prot_t       ar_prot     ,
  input       axi_pkg::qos_t        ar_qos      ,
  input       axi_pkg::region_t     ar_region   ,
  input       eth_rgmii_pkg::user_t ar_user     ,
  input       logic                 ar_valid    ,
  output      logic                 ar_ready    ,
  output      eth_rgmii_pkg::id_t   r_id        ,
  output      eth_rgmii_pkg::data_t r_data      ,
  output      axi_pkg::resp_t       r_resp      ,
  output      logic                 r_last      ,
  output      eth_rgmii_pkg::user_t r_user      ,
  output      logic                 r_valid     ,
  input       logic                 r_ready     ,

  // Ethernet
  input  wire                       eth_rxck    ,
  input  wire                       eth_rxctl   ,
  input  wire       [3:0]           eth_rxd     ,
  output wire                       eth_txck    ,
  output wire                       eth_txctl   ,
  output wire       [3:0]           eth_txd     ,
  output wire                       eth_rst_n   ,
  input       logic                 phy_tx_clk_i,
  output      reg                   eth_irq
);

  AXI_BUS #(
    .AXI_ADDR_WIDTH(eth_rgmii_pkg::AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(eth_rgmii_pkg::AXI_DATA_WIDTH),
    .AXI_ID_WIDTH  (eth_rgmii_pkg::AXI_ID_WIDTH  ),
    .AXI_USER_WIDTH(eth_rgmii_pkg::AXI_USER_WIDTH)
  ) axi_master_tx ();


  eth_rgmii #(
    .AXI_ADDR_WIDTH(eth_rgmii_pkg::AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(eth_rgmii_pkg::AXI_DATA_WIDTH),
    .AXI_ID_WIDTH  (eth_rgmii_pkg::AXI_ID_WIDTH  ),
    .AXI_USER_WIDTH(eth_rgmii_pkg::AXI_USER_WIDTH)
  ) i_eth_rgmii (
    .clk_i       (clk_i          ),
    .clk_200MHz_i(clk_200MHz_i   ),
    .rst_ni      (rst_ni         ),
    .eth_clk_i   (eth_clk_i      ), //90

    .ethernet    (axi_master_tx  ),

    .eth_rxck    (eth_rxck       ),
    .eth_rxctl   (eth_rxctl      ),
    .eth_rxd     (eth_rxd        ),

    .eth_txck    (eth_txck       ),
    .eth_txctl   (eth_txctl      ),
    .eth_txd     (eth_txd        ),

    .eth_rst_n   (eth_rst_n   ),
    .phy_tx_clk_i(phy_tx_clk_i ),  //0
    .eth_irq     (eth_irq)
  );

  assign axi_master_tx.aw_id     = aw_id    ;
  assign axi_master_tx.aw_addr   = aw_addr  ;
  assign axi_master_tx.aw_len    = aw_len   ;
  assign axi_master_tx.aw_size   = aw_size  ;
  assign axi_master_tx.aw_burst  = aw_burst ;
  assign axi_master_tx.aw_lock   = aw_lock  ;
  assign axi_master_tx.aw_cache  = aw_cache ;
  assign axi_master_tx.aw_prot   = aw_prot  ;
  assign axi_master_tx.aw_qos    = aw_qos   ;
  assign axi_master_tx.aw_region = aw_region;
  assign axi_master_tx.aw_atop   = aw_atop  ;
  assign axi_master_tx.aw_user   = aw_user  ;
  assign axi_master_tx.aw_valid  = aw_valid ;
  assign aw_ready = axi_master_tx.aw_ready;

  assign axi_master_tx.w_data  = w_data ;
  assign axi_master_tx.w_strb  = w_strb ;
  assign axi_master_tx.w_last  = w_last ;
  assign axi_master_tx.w_user  = w_user ;
  assign axi_master_tx.w_valid = w_valid;
  assign w_ready = axi_master_tx.w_ready;

  assign b_id    = axi_master_tx.b_id   ;
  assign b_resp  = axi_master_tx.b_resp ;
  assign b_user  = axi_master_tx.b_user ;
  assign b_valid = axi_master_tx.b_valid;
  assign axi_master_tx.b_ready = b_ready;

  assign axi_master_tx.ar_id     = ar_id    ;
  assign axi_master_tx.ar_addr   = ar_addr  ;
  assign axi_master_tx.ar_len    = ar_len   ;
  assign axi_master_tx.ar_size   = ar_size  ;
  assign axi_master_tx.ar_burst  = ar_burst ;
  assign axi_master_tx.ar_lock   = ar_lock  ;
  assign axi_master_tx.ar_cache  = ar_cache ;
  assign axi_master_tx.ar_prot   = ar_prot  ;
  assign axi_master_tx.ar_qos    = ar_qos   ;
  assign axi_master_tx.ar_region = ar_region;
  assign axi_master_tx.ar_user   = ar_user  ;
  assign axi_master_tx.ar_valid  = ar_valid ;
  assign ar_ready = axi_master_tx.ar_ready;

  assign r_id    = axi_master_tx.r_id   ;
  assign r_data  = axi_master_tx.r_data ;
  assign r_resp  = axi_master_tx.r_resp ;
  assign r_last  = axi_master_tx.r_last ;
  assign r_user  = axi_master_tx.r_user ;
  assign r_valid = axi_master_tx.r_valid;
  assign axi_master_tx.r_ready = r_ready;

endmodule : eth_rgmii_synth
