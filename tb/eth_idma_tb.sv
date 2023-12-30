// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang  <chaoqun.liang@unibo.it>

`timescale 1 ns/1 ns
`include "axi/typedef.svh"
`include "idma/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"
`include "register_interface/assign.svh"


module eth_idma_tb
 #(
  parameter int unsigned DataWidth           = 64,
  parameter int unsigned AddrWidth           = 64,
  parameter int unsigned UserWidth           = 1,
  parameter int unsigned AxiIdWidth          = 5,
  parameter int unsigned NumAxInFlight       = 3,
  parameter int unsigned BufferDepth         = 3,
  parameter int unsigned TFLenWidth          = 32,
  parameter int unsigned MemSysDepth         = 0,
  parameter bit          RAWCouplingAvail    = 0,
  parameter bit          MaskInvalidData     = 1,
  parameter bit          HardwareLegalizer   = 1,
  parameter bit          RejectZeroTransfers = 1,
  parameter bit          ErrorHandling       = 0
);
  
  import idma_pkg::*;
 
  /// timing parameters
  localparam time SYS_TCK       = 8ns;
  localparam time TCK200        = 5ns;
  localparam time TCK125        = 8ns;
  localparam time SYS_TA        = 2ns;
  localparam time SYS_TT        = 6ns;

  /// regbus
  localparam int unsigned REG_BUS_DW  = 64;
  localparam int unsigned REG_BUS_AW  = 8;
   
  /// parse error handling caps
  localparam idma_pkg::error_cap_e ErrorCap = ErrorHandling ? idma_pkg::ERROR_HANDLING :
                                                                idma_pkg::NO_ERROR_HANDLING;
  
  /// dependent parameters
  localparam int unsigned StrbWidth     = DataWidth / 8;
  localparam int unsigned OffsetWidth   = $clog2(StrbWidth);

  typedef logic [AddrWidth-1:0]      addr_t;
  typedef logic [DataWidth-1:0]      data_t;
  typedef logic [StrbWidth-1:0]      strb_t;
  typedef logic [UserWidth-1:0]      user_t;
  typedef logic [AxiIdWidth-1:0]     id_t;
  typedef logic [OffsetWidth-1:0]    offset_t;
  typedef logic [TFLenWidth-1:0]     tf_len_t;

  /// AXI4+ATOP typedefs
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_b_chan_t, id_t, user_t)

  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, data_t, id_t, user_t)

  `AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_chan_t, axi_w_chan_t, axi_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(axi_rsp_t, axi_b_chan_t, axi_r_chan_t)

  /// ethernet pads
  logic       s_clk;
  logic       s_clk_125MHz_0;
  logic       s_clk_125MHz_90;
  logic       s_clk_200MHz;
  logic       s_rst_n;
  logic       done   = 0;

  logic       eth_rxck;
  logic       eth_rxctl;
  logic [3:0] eth_rxd;
  logic       eth_txck;
  logic       eth_txctl;
  logic [3:0] eth_txd;
  logic       eth_tx_rstn, eth_rx_rstn;

  logic tx_idma_req_valid, tx_idma_req_ready, tx_idma_rsp_valid, tx_idma_rsp_ready;
  logic rx_idma_req_valid, rx_idma_req_ready, rx_idma_rsp_valid, rx_idma_rsp_ready;


  /// AXI4+ATOP request and response
  axi_req_t axi_tx_read_req, axi_tx_write_req, axi_rx_read_req, axi_rx_write_req ;
  axi_rsp_t axi_tx_read_rsp, axi_tx_write_rsp, axi_rx_read_rsp, axi_rx_write_rsp ;

  axi_req_t axi_tx_req_mem, axi_rx_req_mem;
  axi_rsp_t axi_tx_rsp_mem, axi_rx_rsp_mem;

  /// error handler
  idma_pkg::idma_eh_req_t idma_eh_req;
  logic                   eh_req_valid;
  logic                   eh_req_ready;

  /// busy signal
  idma_busy_t             tx_busy, rx_busy;
  
  
  /// -------------------- REG Drivers -----------------------
   
  typedef reg_test::reg_driver #(
    .AW(REG_BUS_AW),
    .DW(REG_BUS_DW),
    .TT(SYS_TT),
    .TA(SYS_TA)
  ) reg_bus_drv_t;

  REG_BUS #(
    .DATA_WIDTH(REG_BUS_DW),
    .ADDR_WIDTH(REG_BUS_AW)
  )  reg_bus_tx (
    .clk_i(s_clk)
  );

  REG_BUS #(
    .DATA_WIDTH(REG_BUS_DW),
    .ADDR_WIDTH(REG_BUS_AW)
  )  reg_bus_rx (
    .clk_i(s_clk)
  );
 
  logic reg_error;
  
  reg_bus_drv_t reg_drv_tx  = new(reg_bus_tx);
  reg_bus_drv_t reg_drv_rx  = new(reg_bus_rx);
  
  eth_idma_pkg::reg_bus_req_t reg_bus_tx_req, reg_bus_rx_req;
  eth_idma_pkg::reg_bus_rsp_t reg_bus_tx_rsp, reg_bus_rx_rsp;
 
  
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
      .AcqDelay          ( SYS_TT       )  // to do
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
    
  
   // ---------------------------- DUT -----------------------------
  eth_idma_wrap#(
    .DataWidth           ( DataWidth           ),    
    .AddrWidth           ( AddrWidth           ),
    .UserWidth           ( UserWidth           ),
    .AxiIdWidth          ( AxiIdWidth          ),
    .NumAxInFlight       ( NumAxInFlight       ),
    .BufferDepth         ( BufferDepth         ),
    .TFLenWidth          ( TFLenWidth          ),
    /// The depth of the memory system the backend is attached to
    .MemSysDepth         ( MemSysDepth         ),
    .RAWCouplingAvail    ( RAWCouplingAvail    ),
    .HardwareLegalizer   ( HardwareLegalizer   ),
    .RejectZeroTransfers ( RejectZeroTransfers )
) i_tx_eth_idma_wrap (
    .clk_i               (  s_clk              ),
    .rst_ni              (  s_rst_n            ),
     /// Etherent Internal clocks
    .eth_clk_i           ( s_clk_125MHz_0      ), // 125MHz in-phase
    .eth_clk90_i         ( s_clk_125MHz_90     ), // 125 MHz with 90 phase shift
    .eth_clk200M_i       ( s_clk_200MHz        ), // 200 MHz
  
    .phy_rx_clk_i        ( eth_rxck            ),
    .phy_rxd_i           ( eth_rxd             ),
    .phy_rx_ctl_i        ( eth_rxctl           ),
    .phy_tx_clk_o        ( eth_txck            ),
    .phy_txd_o           ( eth_txd             ),
    .phy_tx_ctl_o        ( eth_txctl           ),
    .phy_resetn_o        ( eth_tx_rstn         ),  // output
    .phy_intn_i          ( 1'b1                ),
    .phy_pme_i           ( 1'b1                ),
    .phy_mdio_i          ( 1'b0                ),
    .phy_mdio_o          (                     ),
    .phy_mdio_oe         (                     ),
    .phy_mdc             (                     ),
    .reg_req_i           ( reg_bus_tx_req      ),
    .reg_rsp_o           ( reg_bus_tx_rsp      ),
    .testmode_i          ( 1'b0                ),
    .idma_eh_req_i       ( idma_eh_req         ), // error handling disabled now
    .eh_req_valid_i      ( eh_req_valid        ),
    .eh_req_ready_o      ( eh_req_ready        ),
    .axi_read_req_o      ( axi_tx_read_req     ),
    .axi_read_rsp_i      ( axi_tx_read_rsp     ),

    .axi_write_req_o     ( axi_tx_write_req    ),
    .axi_write_rsp_i     ( axi_tx_write_rsp    ),
    .idma_busy_o         ( tx_busy             )
);
 

axi_rw_join #(
    .axi_req_t        ( axi_req_t ),
    .axi_resp_t       ( axi_rsp_t )
) i_axi_tx_rw_join (
    .clk_i            ( s_clk            ),
    .rst_ni           ( s_rst_n          ),
    .slv_read_req_i   ( axi_tx_read_req  ),
    .slv_read_resp_o  ( axi_tx_read_rsp  ),
    .slv_write_req_i  ( axi_tx_write_req ),
    .slv_write_resp_o ( axi_tx_write_rsp ),
    .mst_req_o        ( axi_tx_req_mem   ),
    .mst_resp_i       ( axi_tx_rsp_mem   )
);

axi_rw_join #(
    .axi_req_t        ( axi_req_t ),
    .axi_resp_t       ( axi_rsp_t )
) i_axi_rx_rw_join (
    .clk_i            ( s_clk             ),
    .rst_ni           ( s_rst_n           ),
    .slv_read_req_i   ( axi_rx_read_req   ),
    .slv_read_resp_o  ( axi_rx_read_rsp   ),
    .slv_write_req_i  ( axi_rx_write_req  ),
    .slv_write_resp_o ( axi_rx_write_rsp  ),
    .mst_req_o        ( axi_rx_req_mem    ),
    .mst_resp_i       ( axi_rx_rsp_mem    )
);

 eth_idma_pkg::reg_bus_req_t rx_reg_idma_req, tx_reg_idma_req;
 eth_idma_pkg::reg_bus_rsp_t rx_reg_idma_rsp, tx_reg_idma_rsp;

 eth_idma_wrap #(
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
)i_rx_eth_idma_wrap (
    .clk_i            ( s_clk           ),
    .rst_ni           ( s_rst_n         ),
  /// Etherent Internal clocks
    .eth_clk_i        ( s_clk_125MHz_0  ), // 125MHz in-phase
    .eth_clk90_i      ( s_clk_125MHz_90 ), // 125 MHz with 90 phase shift
    .eth_clk200M_i    ( s_clk_200MHz    ), // 200 MHz

    .phy_rx_clk_i     ( eth_txck        ),
    .phy_rxd_i        ( eth_txd         ),
    .phy_rx_ctl_i     ( eth_txctl       ),
    .phy_tx_clk_o     ( eth_rxck        ),
    .phy_txd_o        ( eth_rxd         ),
    .phy_tx_ctl_o     ( eth_rxctl       ),
    .phy_resetn_o     ( eth_rx_rstn     ),  
    .phy_intn_i       ( 1'b1            ),
    .phy_pme_i        ( 1'b1            ),

     /// Ethernet MDIO
    .phy_mdio_i       ( 1'b0            ),
    .phy_mdio_o       (                 ), // not used
    .phy_mdio_oe      (                 ), // not used
    .phy_mdc          (                 ), // not used

    .reg_req_i        ( reg_bus_rx_req  ),
    .reg_rsp_o        ( reg_bus_rx_rsp  ),
    
    /// idma 
    .testmode_i       (  1'b0           ),

    /// idma request

    .idma_eh_req_i    (                    ), // error handling disabled now
    .eh_req_valid_i   (                    ),
    .eh_req_ready_o   (                    ),

    .axi_read_req_o   ( axi_rx_read_req    ),
    .axi_read_rsp_i   ( axi_rx_read_rsp    ),

    .axi_write_req_o  ( axi_rx_write_req   ),
    .axi_write_rsp_i  ( axi_rx_write_rsp   ),
    .idma_busy_o      ( rx_busy            )
  );

  /// Ethernet Internal Clock generation
   initial begin
      while (!done) begin
         s_clk_200MHz <= 1;
         #(TCK200/2);
         s_clk_200MHz <= 0;
         #(TCK200/2);
      end
   end

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
         #(TCK125/2);
         s_clk_125MHz_90 <= 1;
           #(TCK125/2);
      end
   end

   // ------------------------ BEGINNING OF SIMULATION ------------------------

   initial begin
      
      @(posedge s_rst_n);
      @(posedge s_clk);
  
   
    $readmemh("/scratch/chaol/eth-ETH/fe-ethernet/scripts/rx_mem_init.vmem", i_rx_axi_sim_mem.mem);
    $readmemh("/scratch/chaol/eth-ETH/fe-ethernet/scripts/eth_packet_frame.vmem", i_tx_axi_sim_mem.mem);

 
    /// Tx path reg configs
    
   //set framing rx mac address to 48'h207098001032
    reg_drv_tx.send_write( 'h0, 64'h98001032, 'hff, reg_error); //lower 32bits of MAC address
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h8,  64'h00002070, 'h0f, reg_error); //upper 16bits of MAC address + other configuration set to false/0
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h20, 64'h0, 'h0fff, reg_error ); // SRC_ADDR
    @(posedge s_clk);
     
    reg_drv_tx.send_write( 'h28, 64'h0, 'h0fff, reg_error); // DST_ADDR 64'h0000207098001032
    @(posedge s_clk);

    reg_drv_tx.send_write( 'h30, 64'h40,'h0f , reg_error); // Size in bytes 
    @(posedge s_clk)
    
    reg_drv_tx.send_write( 'h38, 64'h0,'h0f , reg_error); // src protocol
    @(posedge s_clk)

    reg_drv_tx.send_write( 'h40, 64'h5,'h0f , reg_error); // dst protocol
    @(posedge s_clk)
    
    reg_drv_tx.send_write( 'h70, 64'h1,'h0f , reg_error);  // tx req valid
    @(posedge s_clk)
    

   // tx_idma_req_valid = 1;  // a valid reuqest is available

     // wait for req_ready to become 1, indicate the dma module is ready to accept the request. 
     /// wait till transfer request is accpeted (valid to 0 after the transaction complete)
    //  while (tx_idma_req_ready != 1) begin
    // @(posedge s_clk); // wait for req_ready to become 1, indicating the DMA module is ready to accept the request.
    // end
    reg_drv_tx.send_write( 'h80, 64'h1,'h0f , reg_error);  // launch transfer
    @(posedge s_clk)

    //tx_idma_rsp_ready = 1; // transfer launch

    /// rx path reg configs
    //rx_idma_req_valid = 1;

   

    reg_drv_rx.send_write( 'h0, 64'h98001032, 'hff, reg_error); //lower 32bits of MAC address
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h8,  64'h00002070, 'h0f, reg_error); //upper 16bits of MAC address + other configuration set to false/0
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h20, 64'h0, 'h0fff, reg_error ); // SRC_ADDR  64'h0000207098001032
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h28, 64'h0, 'h0fff, reg_error); // DST_ADDR
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h30, 64'h40,'h0f , reg_error); // Size in bytes 
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h38, 64'h5,'h0f , reg_error); // src protocol
    @(posedge s_clk);

    reg_drv_rx.send_write( 'h40, 64'h0,'h0f , reg_error); // dst protocol
    @(posedge s_clk);
    
    reg_drv_rx.send_write( 'h70, 64'h1,'h0f , reg_error);  // rx req valid
    @(posedge s_clk)
     
    //  while (rx_idma_req_ready != 1) begin
    // @(posedge s_clk); // wait for req_ready to become 1, indicating the DMA module is ready to accept the request.
    // end
    reg_drv_rx.send_write( 'h80, 64'h1,'h0f , reg_error);  // launch transfer
    @(posedge s_clk)
   // rx_idma_rsp_ready = 1; 

    //wait for rsp valid to be asserted to see the response
    //rsp_ready to be 0 done

    repeat(70) @(posedge s_clk); // wait enough till all  data are written into rx mem. 

    // tx_idma_req_valid = 0;
    // rx_idma_req_valid = 0;
    
    reg_drv_tx.send_write( 'h70, 64'h0,'h0f , reg_error);  // tx req valid
    @(posedge s_clk)

    reg_drv_rx.send_write( 'h70, 64'h0,'h0f , reg_error);  // rx req valid
    @(posedge s_clk)

    // repeat(10) @(posedge s_clk);

    for(int j=0; j<64; j++) begin
      if (i_tx_axi_sim_mem.mem[j] != i_rx_axi_sim_mem.mem[j]) begin
        $display("Data at mem[%d] was received %h but was sent as %h", j, i_rx_axi_sim_mem.mem[j], i_tx_axi_sim_mem.mem[j]);
      end else begin
        $display("Data at mem[%d] was correctly received: %h", j, i_rx_axi_sim_mem.mem[j] );
      end
    end

    $finish;

 end

endmodule