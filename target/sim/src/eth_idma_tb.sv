// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>

`timescale 1 ns/1 ns
`include "axi/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"
//import eth_pkg::*;

module eth_idma_tb
 #(
  parameter int unsigned DataWidth           = 32'd64,
  parameter int unsigned AddrWidth           = 32'd48,
  parameter int unsigned UserWidth           = 32'd2,
  parameter int unsigned AxiIdWidth          = 32'd6,
  parameter int unsigned NumAxInFlight       = 32'd3,
  parameter int unsigned BufferDepth         = 32'd3,
  parameter int unsigned TFLenWidth          = 32'd32,
  parameter int unsigned MemSysDepth         = 32'd0,
  parameter bit          HardwareLegalizer   = 1'b1,
  parameter bit          RejectZeroTransfers = 1'b1
);

  import idma_pkg::*;
  import reg_test::*;

  /// timing parameters
  localparam time SYS_TCK       = 5ns;
  localparam time ETH_TCK       = 8ns;
  localparam time SYS_TA        = 2ns;
  localparam time SYS_TT        = 3ns;

  /// Register interface parameters
  localparam int unsigned AW_REGBUS           = 32;
  localparam int unsigned DW_REGBUS           = 32;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  /// TMU parameters

  localparam int unsigned MaxUniqIds    = 32;
  localparam int unsigned MaxTxnsPerId  = 8;

  /// Dependent parameters
  localparam int unsigned StrbWidth     = DataWidth / 8;
  parameter int unsigned AxiIntIdWidth = (MaxUniqIds > 1) ? $clog2(MaxUniqIds) : 1;

  /// AXI4+ATOP typedefs
  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [AxiIdWidth-1:0]  id_t;
  typedef logic [UserWidth-1:0]   user_t;
  typedef logic [StrbWidth-1:0]   strb_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [TFLenWidth-1:0]  tf_len_t;
  typedef logic [AxiIntIdWidth-1:0] intid_t;

  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, data_t, id_t, user_t)

  `AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_chan_t, axi_w_chan_t, axi_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(axi_rsp_t, axi_b_chan_t, axi_r_chan_t)

  /// Intermediate AXI types
  `AXI_TYPEDEF_AW_CHAN_T(int_aw_t, addr_t, intid_t, user_t);
  `AXI_TYPEDEF_W_CHAN_T(w_t, data_t, strb_t, user_t);
  `AXI_TYPEDEF_B_CHAN_T(int_b_t, intid_t, user_t);
  `AXI_TYPEDEF_AR_CHAN_T(int_ar_t, addr_t, intid_t, user_t);
  `AXI_TYPEDEF_R_CHAN_T(int_r_t, data_t, intid_t, user_t);
  `AXI_TYPEDEF_REQ_T(slv_req_t, int_aw_t, w_t, int_ar_t);
  `AXI_TYPEDEF_RESP_T(slv_resp_t, int_b_t, int_r_t );

  /// Regsiter bus typedefs
  typedef logic [AW_REGBUS-1:0]   reg_bus_addr_t;
  typedef logic [DW_REGBUS-1:0]   reg_bus_data_t;
  typedef logic [STRB_WIDTH-1:0]  reg_bus_strb_t;

  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)

  logic       s_clk;
  logic       s_clk125;
  logic       s_clk125q;
  logic       s_rst_n;
  logic       error_found = 0;

  /// ethernet pads
  logic       eth_rxck;
  logic       eth_rxctl;
  logic [3:0] eth_rxd;
  logic       eth_txck;
  logic       eth_txctl;
  logic [3:0] eth_txd;
  logic       eth_tx_rstn, eth_rx_rstn;

  /// AXI4+ATOP request and response
  axi_req_t tx_req, axi_rx_req_mem;
  axi_rsp_t tx_rsp, axi_rx_rsp_mem;

  slv_req_t tx_mem_req;
  slv_resp_t tx_mem_rsp;

  /// -------------------- REG Drivers -----------------------
  typedef reg_test::reg_driver #(
    .AW(AW_REGBUS),
    .DW(DW_REGBUS),
    .TT(SYS_TT),
    .TA(SYS_TA)
  ) reg_bus_drv_t;

  REG_BUS #(
    .DATA_WIDTH(DW_REGBUS),
    .ADDR_WIDTH(AW_REGBUS)
  )  reg_bus_tx (
    .clk_i(s_clk)
  );

  REG_BUS #(
    .DATA_WIDTH(DW_REGBUS),
    .ADDR_WIDTH(AW_REGBUS)
  )  reg_bus_rx(
    .clk_i(s_clk)
  );

  REG_BUS #(
    .DATA_WIDTH(DW_REGBUS),
    .ADDR_WIDTH(AW_REGBUS)
  )  reg_bus_tmu(
    .clk_i(s_clk)
  );

  logic reg_error;
  logic rx_irq, tmu_irq;
  logic dma_done = 0;
  logic req_ready = 0;
  logic rst_stat;

  reg_bus_drv_t reg_drv_tx  = new(reg_bus_tx);
  reg_bus_drv_t reg_drv_rx  = new(reg_bus_rx);
  reg_bus_drv_t reg_drv_tmu = new(reg_bus_tmu);

  reg_bus_req_t tmu_reg_req, reg_bus_tx_req, reg_bus_rx_req;
  reg_bus_rsp_t tmu_reg_rsp, reg_bus_tx_rsp, reg_bus_rx_rsp;

   `REG_BUS_ASSIGN_TO_REQ (reg_bus_tx_req, reg_bus_tx)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_tx, reg_bus_tx_rsp)

  `REG_BUS_ASSIGN_TO_REQ (reg_bus_rx_req, reg_bus_rx)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_rx, reg_bus_rx_rsp)

  `REG_BUS_ASSIGN_TO_REQ (tmu_reg_req, reg_bus_tmu)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_tmu, tmu_reg_rsp)

  // clocking block
  clk_rst_gen #(
    .ClkPeriod    ( SYS_TCK   ),
    .RstClkCycles ( 10        )
  ) i_clk_rst_gen (
    .clk_o        ( s_clk     ),
    .rst_no       ( s_rst_n   )  // active low reset
  );

   ////////////////
   //    TMU     //
   ////////////////

  slv_guard_top #(
      .AddrWidth    ( AddrWidth           ),
      .DataWidth    ( DataWidth           ),
      .StrbWidth    ( StrbWidth           ),
      .AxiIdWidth   ( AxiIdWidth          ),
      .AxiUserWidth ( UserWidth           ),
      .MaxUniqIds   ( MaxUniqIds          ),
      .MaxTxnsPerId ( MaxTxnsPerId        ),
      .req_t        ( axi_req_t           ),
      .rsp_t        ( axi_rsp_t           ),
      .slv_req_t    ( slv_req_t           ),
      .slv_rsp_t    ( slv_resp_t          ),
      .reg_req_t    ( reg_bus_req_t       ),
      .reg_rsp_t    ( reg_bus_rsp_t       )
  ) i_slv_guard_top (
      .clk_i       (   s_clk         ),
      .rst_ni      (   s_rst_n       ),
      .guard_ena_i (   1'b1          ),
      .req_i       (   tx_req        ),
      .rsp_o       (   tx_rsp        ),
      .req_o       (   tx_mem_req    ),
      .rsp_i       (   tx_mem_rsp    ),
      .reg_req_i   (   tmu_reg_req   ),
      .reg_rsp_o   (   tmu_reg_rsp   ),
      .irq_o       (   tmu_irq       ),
      .rst_req_o   (   rst_stat      ),
      .rst_stat_i  (   1'b0          )
  );

  // AXI4 TX sim memory
  axi_sim_mem #(
    .AddrWidth         ( AddrWidth    ),
    .DataWidth         ( DataWidth    ),
    .IdWidth           ( AxiIdWidth   ),
    .UserWidth         ( UserWidth    ),
    .axi_req_t         ( slv_req_t    ),
    .axi_rsp_t         ( slv_resp_t   ),
    .WarnUninitialized ( 1'b0         ),
    .ClearErrOnAccess  ( 1'b1         ),
    .ApplDelay         ( SYS_TA       ),
    .AcqDelay          ( SYS_TT       ),
    .UninitializedData ( "zeros"      )
  ) i_tx_axi_sim_mem (
    .clk_i              ( s_clk           ),
    .rst_ni             ( s_rst_n         ),
    .axi_req_i          ( tx_mem_req      ),
    .axi_rsp_o          ( tx_mem_rsp      )
  );

  // AXI4 RX sim memory
  axi_sim_mem #(
    .AddrWidth         ( AddrWidth    ),
    .DataWidth         ( DataWidth    ),
    .IdWidth           ( AxiIdWidth   ),
    .UserWidth         ( UserWidth    ),
    .axi_req_t         ( axi_req_t    ),
    .axi_rsp_t         ( axi_rsp_t    ),
    .WarnUninitialized ( 1'b0         ),
    .ClearErrOnAccess  ( 1'b1         ),
    .ApplDelay         ( SYS_TA       ),
    .AcqDelay          ( SYS_TT       ),
    .UninitializedData ( "zeros"      )
  ) i_rx_axi_sim_mem (
    .clk_i              ( s_clk             ),
    .rst_ni             ( s_rst_n           ),
    .axi_req_i          ( axi_rx_req_mem    ),
    .axi_rsp_o          ( axi_rx_rsp_mem    )
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
    .clk_i               ( s_clk               ),
    .rst_ni              ( s_rst_n             ),
     /// Etherent Internal clocks
    .eth_clk125_i        ( s_clk125      ), // 125MHz in-phase
    .eth_clk125q_i       ( s_clk125q     ), // 125 MHz with 90 phase shift
    .eth_clk200_i        ( 1'b0                ),
    .phy_rx_clk_i        ( eth_rxck            ),
    .phy_rxd_i           ( eth_rxd             ),
    .phy_rx_ctl_i        ( eth_rxctl           ),
    .phy_tx_clk_o        ( eth_txck            ),
    .phy_txd_o           ( eth_txd             ),
    .phy_tx_ctl_o        ( eth_txctl           ),
    .phy_resetn_o        ( eth_tx_rstn         ),
    .phy_intn_i          ( 1'b1                ),
    .phy_pme_i           ( 1'b1                ),
    .phy_mdio_i          ( 1'b0                ),
    .phy_mdio_o          (                     ),
    .phy_mdio_oe         (                     ),
    .phy_mdc_o           (                     ),
    .reg_req_i           ( reg_bus_tx_req      ),
    .reg_rsp_o           ( reg_bus_tx_rsp      ),
    .testmode_i          ( 1'b0                ),
    .axi_req_o           ( tx_req              ),
    .axi_rsp_i           ( tx_rsp              )
  );

  reg_bus_req_t rx_reg_idma_req, tx_reg_idma_req;
  reg_bus_rsp_t rx_reg_idma_rsp, tx_reg_idma_rsp;

  eth_idma_wrap #(
    .DataWidth           ( DataWidth           ),
    .AddrWidth           ( AddrWidth           ),
    .UserWidth           ( UserWidth           ),
    .AxiIdWidth          ( AxiIdWidth          ),
    .NumAxInFlight       ( NumAxInFlight       ),
    .BufferDepth         ( BufferDepth         ),
    .TFLenWidth          ( TFLenWidth          ),
    .MemSysDepth         ( MemSysDepth         ),
    .RxFifoLogDepth      (                    ),
    .RejectZeroTransfers ( RejectZeroTransfers ),
    .axi_req_t           ( axi_req_t           ),
    .axi_rsp_t           ( axi_rsp_t           ),
    .reg_req_t           ( reg_bus_req_t       ),
    .reg_rsp_t           ( reg_bus_rsp_t       )
  ) i_rx_eth_idma_wrap (
    .clk_i            ( s_clk           ),
    .rst_ni           ( s_rst_n         ),
    .eth_clk125_i     ( s_clk125  ), // 125MHz in-phase
    .eth_clk125q_i    ( s_clk125q ), // 125 MHz with 90 phase shift
    .eth_clk200_i     ( 1'b0             ),
    .phy_rx_clk_i     ( eth_txck        ),
    .phy_rxd_i        ( eth_txd         ),
    .phy_rx_ctl_i     ( eth_txctl       ),
    .phy_tx_clk_o     ( eth_rxck        ),
    .phy_txd_o        ( eth_rxd         ),
    .phy_tx_ctl_o     ( eth_rxctl       ),
    .phy_resetn_o     ( eth_rx_rstn     ),
    .phy_intn_i       ( 1'b1            ),
    .phy_pme_i        ( 1'b1            ),
    .phy_mdio_i       ( 1'b0            ),
    .phy_mdio_o       (                 ),
    .phy_mdio_oe      (                 ),
    .phy_mdc_o        (                 ),
    .reg_req_i        ( reg_bus_rx_req  ),
    .reg_rsp_o        ( reg_bus_rx_rsp  ),
    .testmode_i       ( 1'b0            ),
    .axi_req_o        ( axi_rx_req_mem  ),
    .axi_rsp_i        ( axi_rx_rsp_mem  ),
    .eth_rx_irq_o     ( rx_irq          )
  );

  // ------------------------ BEGINNING OF SIMULATION ------------------------

  /// Ethernet Internal Clock generation

  initial begin
    forever begin
    s_clk125 <= 1;
    #(ETH_TCK/2);
    s_clk125 <= 0;
    #(ETH_TCK/2);
    end
  end

  initial begin
    forever begin
    s_clk125q <= 0;
    #(ETH_TCK/4);
    s_clk125q <= 1;
    #(ETH_TCK/2);
    s_clk125q <= 0;
    #(ETH_TCK/4);
    end
  end

  initial begin

    repeat(1)@(posedge s_clk);
    reg_drv_tx.reset_master();
    reg_drv_rx.reset_master();
    reg_drv_tmu.reset_master();

    @(posedge s_rst_n);

    $readmemh("/scratch2/chaoliang/zoix_exercise/pulp-eth/pulp-ethernet/gen/rx_mem_init.vmem", i_rx_axi_sim_mem.mem);
    $readmemh("/scratch2/chaoliang/zoix_exercise/pulp-eth/pulp-ethernet/gen/eth_frame.vmem", i_tx_axi_sim_mem.mem);


    /// TMU config
    // slave unit enable 1 / disable 0
    reg_drv_tmu.send_write(32'h0000_0000, 32'h0000_0100, 4'hf, reg_error);

    // budget from aw_valid to aw_ready
    reg_drv_tmu.send_write(32'h0000_0004, 32'h0000_0001, 4'hf, reg_error);
    // time budget for unit length on w channel
    reg_drv_tmu.send_write(32'h0000_0008, 32'h0000_0001, 4'hf, reg_error);
    // budget from w_valid to w_ready
    reg_drv_tmu.send_write(32'h0000_000c, 32'h0000_0001, 4'hf, reg_error);
    // budget from w_last to b_valid
    reg_drv_tmu.send_write(32'h0000_0010, 32'h0000_0001, 4'hf, reg_error);
    // budget from b_valid to b_ready
    reg_drv_tmu.send_write(32'h0000_0014, 32'h0000_0001, 4'hf, reg_error);

    // budget from ar_valid to ar_ready
    reg_drv_tmu.send_write(32'h0000_0018, 32'h0000_0001, 4'hf, reg_error);
    // time budget for unit length on r channel
    reg_drv_tmu.send_write(32'h0000_001c, 32'h0000_0001, 4'hf, reg_error);
    // budget from rvld to rrdy
    reg_drv_tmu.send_write(32'h0000_0020, 32'h0000_0001, 4'hf, reg_error);

    /// TX eth configs
    reg_drv_tx.send_write( 'h00, 32'h00890702, 'hf, reg_error); //lower 32bits of MAC address
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h04,  16'h2301, 'hf, reg_error); //upper 16bits of MAC address + other configuration set to false/0
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h1c, 32'h0, 'hf, reg_error ); // LOW SRC_ADDR
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h20, 32'h0, 'hf, reg_error ); // HIGH SRC_ADDR
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h24, 32'h0, 'hf, reg_error); // LOW DST_ADDR
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h28, 32'h0, 'hf, reg_error); // HIGH DST_ADDR
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h2c, 'h40, 'hf, reg_error); // Size in bytes LOW
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h30, 'h0, 'hf, reg_error); // Size in bytes HIGH
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h30, 'h0, 'hf, reg_error); // Size in bytes HIGH
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h34, 32'h00014000, 'hff, reg_error); // src and dst protocol AXI
    @(posedge s_clk);

    while(1) begin
      reg_drv_tx.send_read( 'h3c, req_ready, reg_error);   // req ready
      if( req_ready )
        break;
      @(posedge s_clk);
    end

    /// Transaction configs
    reg_drv_tx.send_write( 'h38, 32'h1, 'hf , reg_error);  // req valid
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h0, 32'h89000123, 'hf, reg_error); //lower 32bits of MAC address
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h4, 'h00800207, 'hf, reg_error); //upper 16bits of MAC address + other configuration set to false/0
    @(posedge s_clk);

    @(posedge  rx_irq);

    reg_drv_rx.send_write( 'h1c, 32'h0, 'hf, reg_error ); // SRC_ADDR  64'h0000207098001032
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h24, 32'h0, 'hf, reg_error); // DST_ADDR
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h34, 32'h00002800, 'hf, reg_error); // src and dst protocol
    @(posedge s_clk);

    while(1) begin
      reg_drv_rx.send_read( 'h3c, req_ready, reg_error);   // req ready
      if( req_ready )
        break;
      @(posedge s_clk);
    end

    /// Transaction configs
    reg_drv_rx.send_write( 'h38, 32'h1, 'hf , reg_error);  // req valid - req start
    @(posedge s_clk);

    while(1) begin
      reg_drv_rx.send_read( 'h44, dma_done, reg_error);   // rsp_valid dma completes data moving
      if( dma_done )
        break;
      @(posedge s_clk);
    end
    // can @posedge of rsp_valid
    //reg_drv_rx.send_write( 'h18, 32'h2, 'hf, reg_error ); // to clear rx_complete, thus to clear rx_irq once all data is processed.
    @(posedge s_clk);

    for (int j = 0; j < 64; j++) begin
      if (i_tx_axi_sim_mem.mem[j] != i_rx_axi_sim_mem.mem[j]) begin
        $display("Test FAIL");
        error_found = 1;
        break;
      end
    end

    if (!error_found) begin
      $display("Test PASS");
    end

  $finish;
 end

endmodule
