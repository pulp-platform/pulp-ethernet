// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>
 
`include "axi/typedef.svh"

module eth_idma_wrap_syth #(
  parameter int unsigned AddrWidth  = SynthAxiAddrWidth,
  parameter int unsigned DataWidth  = SynthAxiDataWidth,
  parameter int unsigned UserWidth  = SynthAxiUserWidth,
  parameter int unsigned AxiIdWidth = SynthAxiOutIdWidth,
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
  parameter int unsigned TxFifoLogDepth      = 32'd4,
  parameter int unsigned RxFifoLogDepth      = 32'd4,
  
  parameter int unsigned AsyncAxiOutAwWidth = SynthAsyncAxiOutAwWidth,
  parameter int unsigned AsyncAxiOutWWidth  = SynthAsyncAxiOutWWidth,
  parameter int unsigned AsyncAxiOutBWidth  = SynthAsyncAxiOutBWidth,
  parameter int unsigned AsyncAxiOutArWidth = SynthAsyncAxiOutArWidth,
  parameter int unsigned AsyncAxiOutRWidth  = SynthAsyncAxiOutRWidth

  parameter type         axi_out_aw_chan_t  = synth_axi_out_aw_chan_t,
  parameter type         axi_out_w_chan_t   = synth_axi_out_w_chan_t,
  parameter type         axi_out_b_chan_t   = synth_axi_out_b_chan_t,
  parameter type         axi_out_ar_chan_t  = synth_axi_out_ar_chan_t,
  parameter type         axi_out_r_chan_t   = synth_axi_out_r_chan_t,
  parameter type         axi_out_req_t      = synth_axi_out_req_t,
  parameter type         axi_out_resp_t     = synth_axi_out_resp_t,
  parameter int unsigned LogDepth           = SynthLogDepth,
  parameter int unsigned CdcSyncStages      = SynthCdcSyncStages,
  parameter int unsigned SyncStages         = 3,
  
  /// Register Request and Response type
  parameter type reg_req_t                   = logic,
  parameter type reg_rsp_t                   = logic
)(
  input  logic                    clk_i,
  input  logic                    rst_ni, 
  input  logic                    pwr_on_rst_ni,
  /// Ethernet RGMII
  input  logic                    phy_rx_clk_i,
  input  logic    [3:0]           phy_rxd_i,
  input  logic                    phy_rx_ctl_i,
  output logic                    phy_tx_clk_o,
  output logic    [3:0]           phy_txd_o,
  output logic                    phy_tx_ctl_o,
  output logic                    phy_resetn_o,
  input  logic                    phy_intn_i,
  input  logic                    phy_pme_i,
  input  logic                    phy_mdio_i,
  output logic                    phy_mdio_o,
  output logic                    phy_mdio_oe,
  output logic                    phy_mdc_o,
  // idma 
  input  logic                    testmode_i,
  // axi isolate
  input  logic                    axi_isolate_i,
  output logic                    axi_isolated_o,
  // axi cdc
  output logic [AsyncAxiOutAwWidth-1:0] async_axi_out_aw_data_o,
  output logic             [LogDepth:0] async_axi_out_aw_wptr_o,
  input  logic             [LogDepth:0] async_axi_out_aw_rptr_i,
  output logic [ AsyncAxiOutWWidth-1:0] async_axi_out_w_data_o,
  output logic             [LogDepth:0] async_axi_out_w_wptr_o,
  input  logic             [LogDepth:0] async_axi_out_w_rptr_i,
  input  logic [ AsyncAxiOutBWidth-1:0] async_axi_out_b_data_i,
  input  logic             [LogDepth:0] async_axi_out_b_wptr_i,
  output logic             [LogDepth:0] async_axi_out_b_rptr_o,
  output logic [AsyncAxiOutArWidth-1:0] async_axi_out_ar_data_o,
  output logic             [LogDepth:0] async_axi_out_ar_wptr_o,
  input  logic             [LogDepth:0] async_axi_out_ar_rptr_i,
  input  logic [ AsyncAxiOutRWidth-1:0] async_axi_out_r_data_i,
  input  logic             [LogDepth:0] async_axi_out_r_wptr_i,
  output logic             [LogDepth:0] async_axi_out_r_rptr_o
  /// reg cdc
  input  logic                    reg_async_mst_req_i,
  output logic                    reg_async_mst_ack_o,
  input  l2_ecc_reg_req_t         reg_async_mst_data_i,
  output logic                    reg_async_mst_req_o,
  input  logic                    reg_async_mst_ack_i,
  output l2_ecc_reg_rsp_t         reg_async_mst_data_o,
  // irq cdc
  outpput logic                   eth_irq_o,
);

  axi_out_req_t axi_out_req, axi_out_isolate_req;
  axi_out_resp_t axi_out_resp, axi_out_isolate_resp;

  logic axi_isolate_sync;
  logic eth_irq;

  reg_req_t reg_bus_req;
  reg_rsp_t reg_bus_rsp;

  sync #(
    .STAGES     ( SyncStages ),
    .ResetValue ( 1'b1       )
  ) i_isolate_sync (
    .clk_i,
    .rst_ni   ( pwr_on_rst_ni    ),
    .serial_i ( axi_isolate_i    ),
    .serial_o ( axi_isolate_sync )
  );

  sync #(
    .STAGES     ( SyncStages ),
    .ResetValue ( 1'b0       )
  ) i_irq_sync (
    .clk_i,
    .rst_ni   ( pwr_on_rst_ni ),
    .serial_i ( eth_irq       ),
    .serial_o ( eth_irq_o     )
  );
  
  axi_cdc_src #(
    .LogDepth   ( LogDepth          ),
    .SyncStages ( CdcSyncStages     ),
    .aw_chan_t  ( axi_out_aw_chan_t ),
    .w_chan_t   ( axi_out_w_chan_t  ),
    .b_chan_t   ( axi_out_b_chan_t  ),
    .ar_chan_t  ( axi_out_ar_chan_t ),
    .r_chan_t   ( axi_out_r_chan_t  ),
    .axi_req_t  ( axi_out_req_t     ),
    .axi_resp_t ( axi_out_resp_t    )
  ) i_cdc_out (
    .src_clk_i                  ( clk_i                   ),
    .src_rst_ni                 ( pwr_on_rst_ni           ),
    .src_req_i                  ( axi_out_req             ),
    .src_resp_o                 ( axi_out_rsp             ),
    .async_data_master_aw_data_o( async_axi_out_aw_data_o ),
    .async_data_master_aw_wptr_o( async_axi_out_aw_wptr_o ),
    .async_data_master_aw_rptr_i( async_axi_out_aw_rptr_i ),
    .async_data_master_w_data_o ( async_axi_out_w_data_o  ),
    .async_data_master_w_wptr_o ( async_axi_out_w_wptr_o  ),
    .async_data_master_w_rptr_i ( async_axi_out_w_rptr_i  ),
    .async_data_master_b_data_i ( async_axi_out_b_data_i  ),
    .async_data_master_b_wptr_i ( async_axi_out_b_wptr_i  ),
    .async_data_master_b_rptr_o ( async_axi_out_b_rptr_o  ),
    .async_data_master_ar_data_o( async_axi_out_ar_data_o ),
    .async_data_master_ar_wptr_o( async_axi_out_ar_wptr_o ),
    .async_data_master_ar_rptr_i( async_axi_out_ar_rptr_i ),
    .async_data_master_r_data_i ( async_axi_out_r_data_i  ),
    .async_data_master_r_wptr_i ( async_axi_out_r_wptr_i  ),
    .async_data_master_r_rptr_o ( async_axi_out_r_rptr_o  )
  );

  axi_isolate            #(
    .NumPending           ( NumAxInFlight  ),
    .TerminateTransaction ( 1              ),
    .AtopSupport          ( 1              ),
    .AxiAddrWidth         ( AddrWidth      ),
    .AxiDataWidth         ( DataWidth      ),
    .AxiIdWidth           ( AxiIdWidth     ),
    .AxiUserWidth         ( UserWidth      ),
    .axi_req_t            ( axi_out_req_t  ),
    .axi_resp_t           ( axi_out_resp_t )
  ) i_axi_out_isolate     (
    .clk_i,
    .rst_ni,
    .slv_req_i            ( axi_out_isolate_req  ),
    .slv_resp_o           ( axi_out_isolate_resp ),
    .mst_req_o            ( axi_out_req          ),
    .mst_resp_i           ( axi_out_resp         ),
    .isolate_i            ( axi_isolate_sync     ),
    .isolated_o           ( axi_isolated_o       )
  );

  eth_idma_wrap#(
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
  ) i_eth_idma_wrap (
    .clk_i,
    .rst_ni,
     /// Etherent Internal clocks
    .eth_clk125_i        ( clk_125MHz_0        ), // 125MHz in-phase
    .eth_clk125q_i       ( clk_125MHz_90       ), // 125 MHz with 90 phase shift
    .phy_rx_clk_i        ( eth_rxck            ),
    .phy_rxd_i           ( eth_rxd             ),
    .phy_rx_ctl_i        ( eth_rxctl           ),
    .phy_tx_clk_o        ( eth_txck            ),
    .phy_txd_o           ( eth_txd             ),
    .phy_tx_ctl_o        ( eth_txctl           ),
    .phy_resetn_o        ( eth_tx_rstn         ),  
    .phy_intn_i          ( phy_intn_i          ),
    .phy_pme_i           ( phy_pme_i           ),
    .phy_mdio_i          ( phy_mdio_i          ),
    .phy_mdio_o          ( phy_mdio_o          ),
    .phy_mdio_oe         ( phy_mdio_oe         ),
    .phy_mdc_o           ( phy_mdc_o           ),
    .reg_req_i           ( reg_bus_req         ),
    .reg_rsp_o           ( reg_bus_rsp         ),
    .testmode_i          ( testmode_i          ),
    .axi_req_o           ( axi_out_isolate_req ),
    .axi_rsp_i           ( axi_out_isolate_rsp ),
    .idma_busy_o         ( tx_busy             ),
    .eth_irq_o           ( eth_irq             )
  );

  reg_cdc_dst #(
    .CDC_KIND ( "cdc_4phase" ),
    .req_t      ( reg_req_t ),
    .rsp_t      ( reg_rsp_t )
  ) i_reg_cdc_dst (
    .dst_clk_i   ( clk_i                ),
    .dst_rst_ni  ( pwr_on_rst_ni        ),
    .dst_req_o   ( reg_bus_req          ),
    .dst_rsp_i   ( reg_bus_rsp          ),

    .async_req_i ( reg_async_mst_req_i  ),
    .async_ack_o ( reg_async_mst_ack_o  ),
    .async_data_i( reg_async_mst_data_i ),

    .async_req_o ( reg_async_mst_req_o  ),
    .async_ack_i ( reg_async_mst_ack_i  ),
    .async_data_o( reg_async_mst_data_o )
 );
endmodule : eth_idma_wrap_syth