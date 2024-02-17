// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`timescale 1 ns/1 ns
`include "axi/typedef.svh"
`include "idma/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module eth_idma_tb
 #(
  parameter int unsigned DataWidth           = 32'd64,
  parameter int unsigned AddrWidth           = 32'd64,
  parameter int unsigned UserWidth           = 32'd1,
  parameter int unsigned AxiIdWidth          = 32'd5,
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
  localparam time SYS_TCK       = 8ns;
  localparam time TCK125        = 8ns;
  localparam time SYS_TA        = 2ns;
  localparam time SYS_TT        = 6ns;

  /// Register interface parameters
  localparam int AW_REGBUS           = 32;
  localparam int DW_REGBUS           = 32;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  /// Dependent parameters
  localparam int unsigned StrbWidth     = DataWidth / 8;
  localparam int unsigned OffsetWidth   = $clog2(StrbWidth);

  /// AXI4+ATOP typedefs
  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [AxiIdWidth-1:0]  id_t;
  typedef logic [UserWidth-1:0]   user_t;
  typedef logic [StrbWidth-1:0]   strb_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [TFLenWidth-1:0]  tf_len_t;
  
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_b_chan_t, id_t, user_t) 
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, data_t, id_t, user_t) 

  `AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_chan_t, axi_w_chan_t, axi_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(axi_rsp_t, axi_b_chan_t, axi_r_chan_t)

  /// Regsiter bus typedefs
  typedef logic [AW_REGBUS-1:0]   reg_bus_addr_t;
  typedef logic [DW_REGBUS-1:0]   reg_bus_data_t;
  typedef logic [STRB_WIDTH-1:0]  reg_bus_strb_t;

  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)
 
  /// AXI Stream typedefs
  `IDMA_AXI_STREAM_TYPEDEF_S_CHAN_T(axis_t_chan_t, data_t, strb_t, strb_t, id_t, id_t, user_t)
  `IDMA_AXI_STREAM_TYPEDEF_REQ_T(axi_stream_req_t, axis_t_chan_t)
  `IDMA_AXI_STREAM_TYPEDEF_RSP_T(axi_stream_rsp_t)

  logic       s_clk;
  logic       s_clk_125MHz_0;
  logic       s_clk_125MHz_90;
  logic       s_rst_n;
  logic       done  = 0;
  logic       error_found = 0;

  /// ethernet pads
  logic       eth_rxck;
  logic       eth_rxctl;
  logic [3:0] eth_rxd;
  logic       eth_txck;
  logic       eth_txctl;
  logic [3:0] eth_txd;
  logic       eth_tx_rstn, eth_rx_rstn;

  logic [AW_REGBUS-1:0] tx_req_ready, tx_rsp_valid; 
  logic [DW_REGBUS-1:0] rx_req_ready, rx_rsp_valid;

  logic tx_idma_req_valid, tx_idma_req_ready, tx_idma_rsp_valid, tx_idma_rsp_ready;
  logic rx_idma_req_valid, rx_idma_req_ready, rx_idma_rsp_valid, rx_idma_rsp_ready;

  /// AXI4+ATOP request and response
  axi_req_t axi_tx_req_mem, axi_rx_req_mem;
  axi_rsp_t axi_tx_rsp_mem, axi_rx_rsp_mem;

  /// busy signal
  idma_busy_t   tx_busy, rx_busy;
  
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
  )  reg_bus_rx (
    .clk_i(s_clk)
  );
 
  logic reg_error;
  
  reg_bus_drv_t reg_drv_tx  = new(reg_bus_tx);
  reg_bus_drv_t reg_drv_rx  = new(reg_bus_rx);
  
  reg_bus_req_t reg_bus_tx_req, reg_bus_rx_req;
  reg_bus_rsp_t reg_bus_tx_rsp, reg_bus_rx_rsp;
  
  `REG_BUS_ASSIGN_TO_REQ (reg_bus_tx_req, reg_bus_tx)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_tx, reg_bus_tx_rsp)
  
  `REG_BUS_ASSIGN_TO_REQ (reg_bus_rx_req, reg_bus_rx)
  `REG_BUS_ASSIGN_FROM_RSP (reg_bus_rx, reg_bus_rx_rsp)

  // clocking block
  clk_rst_gen #(
    .ClkPeriod    ( SYS_TCK   ),
    .RstClkCycles ( 1         )
  ) i_clk_rst_gen (
    .clk_o        ( s_clk     ),
    .rst_no       ( s_rst_n   )
  );

  // AXI4 TX sim memory
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
    .AcqDelay          ( SYS_TT       )  
  ) i_tx_axi_sim_mem (
    .clk_i              ( s_clk           ),
    .rst_ni             ( s_rst_n         ),
    .axi_req_i          ( axi_tx_req_mem  ),
    .axi_rsp_o          ( axi_tx_rsp_mem  ),
    .mon_r_last_o       ( /* NOT CONNECTED */ ),
    .mon_r_beat_count_o ( /* NOT CONNECTED */ ),
    .mon_r_user_o       ( /* NOT CONNECTED */ ),
    .mon_r_id_o         ( /* NOT CONNECTED */ ),
    .mon_r_data_o       ( /* NOT CONNECTED */ ),
    .mon_r_addr_o       ( /* NOT CONNECTED */ ),
    .mon_r_valid_o      ( /* NOT CONNECTED */ ),
    .mon_w_last_o       ( /* NOT CONNECTED */ ),
    .mon_w_beat_count_o ( /* NOT CONNECTED */ ),
    .mon_w_user_o       ( /* NOT CONNECTED */ ),
    .mon_w_id_o         ( /* NOT CONNECTED */ ),
    .mon_w_data_o       ( /* NOT CONNECTED */ ),
    .mon_w_addr_o       ( /* NOT CONNECTED */ ),
    .mon_w_valid_o      ( /* NOT CONNECTED */ )
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
    .AcqDelay          ( SYS_TT       )
  ) i_rx_axi_sim_mem (
    .clk_i              ( s_clk             ),
    .rst_ni             ( s_rst_n           ),
    .axi_req_i          ( axi_rx_req_mem    ),
    .axi_rsp_o          ( axi_rx_rsp_mem    ),
    .mon_r_last_o       ( /* NOT CONNECTED */ ),
    .mon_r_beat_count_o ( /* NOT CONNECTED */ ),
    .mon_r_user_o       ( /* NOT CONNECTED */ ),
    .mon_r_id_o         ( /* NOT CONNECTED */ ),
    .mon_r_data_o       ( /* NOT CONNECTED */ ),
    .mon_r_addr_o       ( /* NOT CONNECTED */ ),
    .mon_r_valid_o      ( /* NOT CONNECTED */ ),
    .mon_w_last_o       ( /* NOT CONNECTED */ ),
    .mon_w_beat_count_o ( /* NOT CONNECTED */ ),
    .mon_w_user_o       ( /* NOT CONNECTED */ ),
    .mon_w_id_o         ( /* NOT CONNECTED */ ),
    .mon_w_data_o       ( /* NOT CONNECTED */ ),
    .mon_w_addr_o       ( /* NOT CONNECTED */ ),
    .mon_w_valid_o      ( /* NOT CONNECTED */ )
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
    .axi_stream_req_t    ( axi_stream_req_t    ),
    .axi_stream_rsp_t    ( axi_stream_rsp_t    ),
    .reg_req_t           ( reg_bus_req_t       ),
    .reg_rsp_t           ( reg_bus_rsp_t       )
  ) i_tx_eth_idma_wrap (
    .clk_i               ( s_clk               ),
    .rst_ni              ( s_rst_n             ),
     /// Etherent Internal clocks
    .eth_clk_i           ( s_clk_125MHz_0      ), // 125MHz in-phase
    .eth_clk90_i         ( s_clk_125MHz_90     ), // 125 MHz with 90 phase shift
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
    .axi_req_o           ( axi_tx_req_mem      ),
    .axi_rsp_i           ( axi_tx_rsp_mem      ),
    .idma_busy_o         ( tx_busy             )
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
    .RejectZeroTransfers ( RejectZeroTransfers ),
    .axi_req_t           ( axi_req_t           ),
    .axi_rsp_t           ( axi_rsp_t           ),
    .axi_stream_req_t    ( axi_stream_req_t    ),
    .axi_stream_rsp_t    ( axi_stream_rsp_t    ),
    .reg_req_t           ( reg_bus_req_t       ),
    .reg_rsp_t           ( reg_bus_rsp_t       )
  )i_rx_eth_idma_wrap (
    .clk_i            ( s_clk           ),
    .rst_ni           ( s_rst_n         ),
    .eth_clk_i        ( s_clk_125MHz_0  ), // 125MHz in-phase
    .eth_clk90_i      ( s_clk_125MHz_90 ), // 125 MHz with 90 phase shift
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
    .idma_busy_o      ( rx_busy         )
  );

    // ------------------------ BEGINNING OF SIMULATION ------------------------
   
  /// Ethernet Internal Clock generation
  initial begin
    while (!done) begin
      s_clk_125MHz_0 <= 1;
      #(TCK125/2);
      s_clk_125MHz_0 <= 0;
      #(TCK125/2);
    end
  end

  initial begin
    while (!done) begin
      s_clk_125MHz_90 <= 0;
      #(TCK125/4);
      s_clk_125MHz_90 <= 1;
      #(TCK125/2);
      s_clk_125MHz_90 <= 0;
       #(TCK125/4);
    end
  end

  initial begin
      
    @(posedge s_rst_n);
    @(posedge s_clk);

    $readmemh("/scratch/chaol/git_test/alsaqr-eth/ethernet/gen/rx_mem_init.vmem", i_rx_axi_sim_mem.mem);
    $readmemh("/scratch/chaol/git_test/alsaqr-eth/ethernet/gen/eth_frame.vmem", i_tx_axi_sim_mem.mem);
    
    /// TX eth configs
    reg_drv_tx.send_write( 'h00, 32'h98001032, 'hf, reg_error); //lower 32bits of MAC address
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h04,  32'h00002070, 'hf, reg_error); //upper 16bits of MAC address + other configuration set to false/0
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h10, 32'h0, 'hf, reg_error ); // SRC_ADDR
    @(posedge s_clk);
     
    reg_drv_tx.send_write( 'h14, 32'h0, 'hf, reg_error); // DST_ADDR 
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h18, 32'h40, 'hf, reg_error); // Size in bytes 
    @(posedge s_clk);
    
    reg_drv_tx.send_write( 'h1c, 32'h0, 'hf, reg_error); // src protocol AXI
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h20, 32'h5, 'hf, reg_error); // dst protocol AXIS
    @(posedge s_clk);

    /// RX eth configs
    reg_drv_rx.send_write( 'h0, 32'h98001032, 'hf, reg_error); //lower 32bits of MAC address
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h4, 32'h00002070, 'hf, reg_error); //upper 16bits of MAC address + other configuration set to false/0
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h10, 32'h0, 'hf, reg_error ); // SRC_ADDR  64'h0000207098001032
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h14, 32'h0, 'hf, reg_error); // DST_ADDR
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h18, 32'h40, 'hf, reg_error); // Size in bytes, 48 for transmission including appended FCS 
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h1c, 32'h5, 'hf, reg_error); // src protocol
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h20, 32'h0, 'hf, reg_error); // dst protocol
    @(posedge s_clk);
    
    /// Transaction configs
    while(1) begin
      reg_drv_tx.send_read( 'h3c, tx_req_ready, reg_error);   // req ready 
      if( tx_req_ready ) begin
        reg_drv_tx.send_write( 'h38, 32'h1, 'hf , reg_error);  // req valid - req start
        @(posedge s_clk);
        break;
      end
      @(posedge s_clk);
    end
   
    reg_drv_tx.send_write( 'h38, 32'h0, 'hf, reg_error);  // req valid - lock in
    reg_drv_tx.send_write( 'h40, 32'h1, 'hf, reg_error);  // rsp_ready - data transfer launch
    @(posedge s_clk);

    while(1) begin
      reg_drv_rx.send_read( 'h3c, rx_req_ready, reg_error);   // req ready
      if( rx_req_ready ) begin
        reg_drv_rx.send_write( 'h38, 32'h1, 'hf, reg_error);  // req_valid
        @(posedge s_clk);
        break;
      end
      @(posedge s_clk);
    end

    reg_drv_rx.send_write( 'h38, 32'h0, 'hf, reg_error);  // req valid
    reg_drv_rx.send_write( 'h40, 32'h1, 'hf, reg_error);  // rsp ready  
    @(posedge s_clk);
  
    repeat(160) @(posedge s_clk); // adjust based on num_bytes to write into rx sim mem

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