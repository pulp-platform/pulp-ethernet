
`timescale 1 ns/1 ps

`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module eth_tb ();
  localparam tCK    = 8ns;
  localparam tCK200 = 5ns;

  localparam TEST_TIME = 6ns;
  localparam APPLY_TIME = 2ns;

  localparam int unsigned REG_BUS_DW = 32;
  localparam int unsigned REG_BUS_AW = 8;

  localparam int unsigned DW = 64;
  localparam int unsigned DW_FRAMING = 8;
  localparam int unsigned ID_WIDTH  = 0;
  localparam int unsigned DEST_WIDTH  = 0;
  localparam int unsigned USER_WIDTH  = 1;

  logic clk_i           = 0; // 125 MHz
  logic clk_90_i        = 0; // 125 MHz phase shifted
  logic clk_200MHz_i    = 0; // 200 MHz
  logic rst_ni          = 1;
  logic done            = 0;

  // signals to instantiate the DUT
  wire       eth_rxck    ;
  wire       eth_rxctl   ;
  wire [3:0] eth_rxd     ;
  wire       eth_txck    ;
  wire       eth_txctl   ;
  wire [3:0] eth_txd     ;
  wire       eth_tx_rst_n;
  wire       eth_rx_rst_n;

  logic [7:0] tx_axis_tdata ;
  logic       tx_axis_tvalid;
  logic       tx_axis_tready;
  logic       tx_axis_tlast ;

  // ----------------------- AXI-Stream master drivers --------------------------
  typedef axi_stream_test::axi_stream_rand_tx #(
    .DataWidth (DW),
    .IdWidth   (ID_WIDTH),
    .DestWidth (DEST_WIDTH),
    .UserWidth (USER_WIDTH),
    .TestTime  (TEST_TIME),
    .ApplTime  (APPLY_TIME),
    .MinWaitCycles(0),
    .MaxWaitCycles(50)
  ) master_drv_t;

  // TX_FRAMING master driver
  AXI_STREAM_BUS_DV #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) tx_framing_master_dv (
    .clk_i(clk_i)
  );

  AXI_STREAM_BUS #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) tx_axis_tx_big();

  `AXI_STREAM_ASSIGN(tx_axis_tx_big, tx_framing_master_dv);

  master_drv_t tx_framing_master_drv = new(tx_framing_master_dv, "tx_framing_master_dvr_tx_path");

  eth_top_pkg::s_req_t tx_axis_tx_req_i;
  eth_top_pkg::s_rsp_t tx_axis_tx_rsp_o;
  `AXI_STREAM_ASSIGN_TO_REQ(tx_axis_tx_req_i, tx_axis_tx_big)
  `AXI_STREAM_ASSIGN_FROM_RSP(tx_axis_tx_big, tx_axis_tx_rsp_o)


  // RX_FRAMING master driver
  AXI_STREAM_BUS_DV #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) rx_framing_master_dv (
    .clk_i(clk_i)
  );

  AXI_STREAM_BUS #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) tx_axis_rx_big();

  `AXI_STREAM_ASSIGN(tx_axis_rx_big, rx_framing_master_dv);

  master_drv_t rx_framing_master_drv = new(rx_framing_master_dv, "rx_framing_master_dvr_tx_path");

  eth_top_pkg::s_req_t tx_axis_rx_req_i;
  eth_top_pkg::s_rsp_t tx_axis_rx_rsp_o;
  `AXI_STREAM_ASSIGN_TO_REQ(tx_axis_rx_req_i, tx_axis_rx_big)
  `AXI_STREAM_ASSIGN_FROM_RSP(tx_axis_rx_big, tx_axis_rx_rsp_o)


// ----------------------- AXI-Stream slave drivers -------------------------
  typedef axi_stream_test::axi_stream_rand_rx #(
    .DataWidth (DW),
    .IdWidth   (ID_WIDTH),
    .DestWidth (DEST_WIDTH),
    .UserWidth (USER_WIDTH),
    .TestTime  (TEST_TIME),
    .ApplTime  (APPLY_TIME),
    .MinWaitCycles(0),
    .MaxWaitCycles(50)
  ) slave_drv_t;

  // TX_FRAMING slave driver
  AXI_STREAM_BUS_DV #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) tx_framing_slave_dv (
    .clk_i(clk_i)
  );

  AXI_STREAM_BUS #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) rx_axis_tx_big();

  `AXI_STREAM_ASSIGN(tx_framing_slave_dv, rx_axis_tx_big);

  slave_drv_t tx_framing_slave_drv = new(tx_framing_slave_dv, "tx_framing_slave_dvr_rx_path");

  eth_top_pkg::s_req_t rx_axis_tx_req_o;
  eth_top_pkg::s_rsp_t rx_axis_tx_rsp_i;
  `AXI_STREAM_ASSIGN_FROM_REQ(rx_axis_tx_big, rx_axis_tx_req_o)
  `AXI_STREAM_ASSIGN_TO_RSP(rx_axis_tx_rsp_i, rx_axis_tx_big)

  // RX_FRAMING slave driver
  AXI_STREAM_BUS_DV #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) rx_framing_slave_dv (
    .clk_i(clk_i)
  );

  AXI_STREAM_BUS #(
    .DataWidth(DW),
    .IdWidth  (ID_WIDTH),
    .DestWidth(DEST_WIDTH),
    .UserWidth(USER_WIDTH)
  ) rx_axis_rx_big();

  `AXI_STREAM_ASSIGN(rx_framing_slave_dv, rx_axis_rx_big);

  slave_drv_t rx_framing_slave_drv = new(rx_framing_slave_dv, "rx_framing_slave_dvr_rx_path");

  eth_top_pkg::s_req_t rx_axis_rx_req_o;
  eth_top_pkg::s_rsp_t rx_axis_rx_rsp_i;
  `AXI_STREAM_ASSIGN_FROM_REQ(rx_axis_rx_big, rx_axis_rx_req_o)
  `AXI_STREAM_ASSIGN_TO_RSP(rx_axis_rx_rsp_i, rx_axis_rx_big)


// -------------------- (configuration) REG Drivers ------------------------
  REG_BUS #(
     .DATA_WIDTH(REG_BUS_DW),
     .ADDR_WIDTH(REG_BUS_AW)
  ) reg_bus_mst_tx (.clk_i(clk_i));

  logic reg_tx_error;

  REG_BUS #(
     .DATA_WIDTH(REG_BUS_DW),
     .ADDR_WIDTH(REG_BUS_AW)
  ) reg_bus_mst_rx (.clk_i(clk_i));

  logic reg_rx_error;

  typedef reg_test::reg_driver #(
     .AW(REG_BUS_AW),
     .DW(REG_BUS_DW),
     .TT(TEST_TIME),
     .TA(APPLY_TIME)
  ) reg_bus_master_t;

  reg_bus_master_t reg_master_tx = new(reg_bus_mst_tx);
  reg_bus_master_t reg_master_rx = new(reg_bus_mst_rx);

  eth_top_pkg::reg_bus_req_t rx_reg_req_i, tx_reg_req_i;
  eth_top_pkg::reg_bus_rsp_t rx_reg_rsp_o, tx_reg_rsp_o;

  `REG_BUS_ASSIGN_TO_REQ(rx_reg_req_i, reg_bus_mst_rx)
  `REG_BUS_ASSIGN_TO_REQ(tx_reg_req_i, reg_bus_mst_tx)
  `REG_BUS_ASSIGN_FROM_RSP(reg_bus_mst_rx, rx_reg_rsp_o)
  `REG_BUS_ASSIGN_FROM_RSP(reg_bus_mst_tx, tx_reg_rsp_o)

// -------------------------------- DUT ---------------------------------
  // TX ETH_RGMII
  eth_top_synth tx_eth_top_synth (
    .rst_ni      (rst_ni         ),
    .clk_i       (clk_i          ),
    .clk90_i     (clk_90_i       ),
    .clk_200MHz_i(clk_200MHz_i   ),


    // Ethernet: 1000BASE-T RGMII
    .phy_rx_clk  (eth_rxck       ),
    .phy_rxd     (eth_rxd        ),
    .phy_rx_ctl  (eth_rxctl      ),

    .phy_tx_clk  (eth_txck       ),
    .phy_txd     (eth_txd        ),
    .phy_tx_ctl  (eth_txctl      ),

    .phy_reset_n (eth_tx_rst_n   ),
    .phy_int_n   (1'b1           ),
    .phy_pme_n   (1'b1           ),

    // MDIO
    .phy_mdio_i  (1'b0           ),
    .phy_mdio_o  (               ),
    .phy_mdio_oe (               ),
    .phy_mdc     (               ),
    // TX AXIS
    .tx_axis_tdata_i (tx_axis_tx_req_i.t.data),
    .tx_axis_tstrb_i (tx_axis_tx_req_i.t.strb),
    .tx_axis_tkeep_i (tx_axis_tx_req_i.t.keep),
    .tx_axis_tlast_i (tx_axis_tx_req_i.t.last),
    .tx_axis_tid_i   (tx_axis_tx_req_i.t.id),
    .tx_axis_tdest_i (tx_axis_tx_req_i.t.dest),
    .tx_axis_tuser_i (tx_axis_tx_req_i.t.user), // set tuser to 1'b0 to indicate no error
    .tx_axis_tvalid_i(tx_axis_tx_req_i.tvalid),
    .tx_axis_tready_o(tx_axis_tx_rsp_o.tready),
    // RX AXIS
    .rx_axis_tdata_o (rx_axis_tx_req_o.t.data),
    .rx_axis_tstrb_o (rx_axis_tx_req_o.t.strb),
    .rx_axis_tkeep_o (rx_axis_tx_req_o.t.keep),
    .rx_axis_tlast_o (rx_axis_tx_req_o.t.last),
    .rx_axis_tid_o   (rx_axis_tx_req_o.t.id),
    .rx_axis_tdest_o (rx_axis_tx_req_o.t.dest),
    .rx_axis_tuser_o (rx_axis_tx_req_o.t.user),
    .rx_axis_tvalid_o(rx_axis_tx_req_o.tvalid),
    .rx_axis_tready_i(rx_axis_tx_rsp_i.tready),

    // Configuration Interface
    .reg_bus_addr_i  (tx_reg_req_i.addr),
    .reg_bus_write_i (tx_reg_req_i.write),
    .reg_bus_wdata_i (tx_reg_req_i.wdata),
    .reg_bus_valid_i (tx_reg_req_i.valid),
    .reg_bus_wstrb_i (tx_reg_req_i.wstrb),
    .reg_bus_rdata_o (tx_reg_rsp_o.rdata),
    .reg_bus_ready_o (tx_reg_rsp_o.ready),
    .reg_bus_error_o (tx_reg_rsp_o.error)
  );



   // RX ETH_RGMII
    eth_top_synth rx_eth_top_synth (
    .rst_ni      (rst_ni         ),
    .clk_i       (clk_i          ),
    .clk90_i     (clk_90_i       ),
    .clk_200MHz_i(clk_200MHz_i   ),

    // Ethernet: 1000BASE-T RGMII
    .phy_rx_clk  (eth_txck       ),
    .phy_rxd     (eth_txd        ),
    .phy_rx_ctl  (eth_txctl      ),

    .phy_tx_clk  (eth_rxck       ),
    .phy_txd     (eth_rxd        ),
    .phy_tx_ctl  (eth_rxctl      ),

    .phy_reset_n (eth_rx_rst_n   ),
    .phy_int_n   (1'b1           ),
    .phy_pme_n   (1'b1           ),

    // MDIO
    .phy_mdio_i  (1'b0           ),
    .phy_mdio_o  (               ),
    .phy_mdio_oe (               ),
    .phy_mdc     (               ),

    // TX AXIS
    .tx_axis_tdata_i (tx_axis_rx_req_i.t.data),
    .tx_axis_tstrb_i (tx_axis_rx_req_i.t.strb),
    .tx_axis_tkeep_i (tx_axis_rx_req_i.t.keep),
    .tx_axis_tlast_i (tx_axis_rx_req_i.t.last),
    .tx_axis_tid_i   (tx_axis_rx_req_i.t.id),
    .tx_axis_tdest_i (tx_axis_rx_req_i.t.dest),
    .tx_axis_tuser_i (tx_axis_rx_req_i.t.user), // set tuser to 1'b0 to indicate no error
    .tx_axis_tvalid_i(tx_axis_rx_req_i.tvalid),
    .tx_axis_tready_o(tx_axis_rx_rsp_o.tready),
    // RX AXIS
    .rx_axis_tdata_o (rx_axis_rx_req_o.t.data),
    .rx_axis_tstrb_o (rx_axis_rx_req_o.t.strb),
    .rx_axis_tkeep_o (rx_axis_rx_req_o.t.keep),
    .rx_axis_tlast_o (rx_axis_rx_req_o.t.last),
    .rx_axis_tid_o   (rx_axis_rx_req_o.t.id),
    .rx_axis_tdest_o (rx_axis_rx_req_o.t.dest),
    .rx_axis_tuser_o (rx_axis_rx_req_o.t.user),
    .rx_axis_tvalid_o(rx_axis_rx_req_o.tvalid),
    .rx_axis_tready_i(rx_axis_rx_rsp_i.tready),

    // Configuration Interface
    .reg_bus_addr_i  (rx_reg_req_i.addr),
    .reg_bus_write_i (rx_reg_req_i.write),
    .reg_bus_wdata_i (rx_reg_req_i.wdata),
    .reg_bus_valid_i (rx_reg_req_i.valid),
    .reg_bus_wstrb_i (rx_reg_req_i.wstrb),
    .reg_bus_rdata_o (rx_reg_rsp_o.rdata),
    .reg_bus_ready_o (rx_reg_rsp_o.ready),
    .reg_bus_error_o (rx_reg_rsp_o.error)
  );

// ------------------------- DATA ----------------------------

  // initialization data array (data to be sent by TX)
  logic [DW-1:0] data_array[7:0];
  initial begin
     data_array[0] = 64'h1032207098001032; //1 --> 230100890702 (Multicast Address) 2301, mac dest + begi of src mac address
     data_array[1] = 64'h3210E20020709800; //2 --> 00890702 002E 0123, end of soource mac address + length/Ethertype(002E=IEEE802.3) + payload (2 byte)
     data_array[2] = 64'h1716151413121110; //3 --> payload 8 byte
     data_array[3] = 64'h2726252423222120; //4 --> payload 8 byte
     data_array[4] = 64'h3736353433323130; //5 --> payload 8 byte
     data_array[5] = 64'h4746454443424140; //6 --> payload 8 byte
     data_array[6] = 64'h5756555453525150; //7 --> payload 8 byte
     data_array[7] = 64'h6766656463626160; //8 --> payload 8 byte
  end

  logic [DW-1:0] data_recv_array[8:0];
  logic last_recv;


  // ---------------------- CLOCK GENERATION ------------------------
  initial begin
     while (!done) begin //SYSTEM CLOCK
        clk_i <= 1;
        #(tCK/2);
        clk_i <= 0;
        #(tCK/2);
     end
  end

  initial begin
     while (!done) begin
        clk_90_i <= 0;
        #(tCK/2);
        clk_90_i <= 1;
        #(tCK/2);
     end
  end

  initial begin
     while (!done) begin
        clk_200MHz_i <= 1;
        #(tCK200/2);
        clk_200MHz_i <= 0;
        #(tCK200/2);
     end
  end

  // ------------------------ BEGINNING OF SIMULATION ------------------------
  initial begin
    // General reset

    // Reset axi master and reg master
    reg_master_tx.reset_master();
    reg_master_rx.reset_master();
    // Master drivers TX-paths
    tx_framing_master_drv.reset();
    rx_framing_master_drv.reset();
    // Slave drivers RX-paths
    tx_framing_slave_drv.reset();
    rx_framing_slave_drv.reset();

    @(posedge clk_i);
    rst_ni <= 0;
    repeat(10000) @(posedge clk_i);
    rst_ni <= 1;
    @(posedge clk_i);

    // set receive array to 0;
    reset_recv_array();
    repeat(5) @(posedge clk_i);

    //set framing rx mac address to 48'h207098001032
    reg_master_rx.send_write(4'h0, 32'h98001032, 4'b1111, reg_tx_error); //lower 32bits of MAC address
    @(posedge clk_i);
    reg_master_rx.send_write(4'h4, 32'h00002070, 4'b1111, reg_tx_error); //upper 16bits of MAC address + other configuration set to false/0

    // TEST 1: Send Frame with the destination_MAC = RX_module_MAC
    $display("Test 1");
    data_array[0] = 64'h1032_207098001032;
    send_and_receive();
    check_data_received();
    @(posedge clk_i);

    // TEST 2: Send Broadcast Frame
    $display("Test 2");
    reset_recv_array();
    data_array[0] = 64'h1032_FFFFFFFFFFFF;
    send_and_receive();
    check_data_received();
    @(posedge clk_i);

    // TEST 3: Send Multicast Frame
    $display("Test 3");
    reset_recv_array();
    data_array[0] = 64'h1032_01005EFFFFFF;
    send_and_receive();
    check_data_received();
    @(posedge clk_i);

    // TEST 4: Send Frame not addressed to RX_module without promiscuous flag
    $display("Test 4");
    reset_recv_array();
    data_array[0] = 64'h1032_00015EFF3FFF;
    send_and_receive();
    check_no_data_received();
    @(posedge clk_i);

    // TEST 5: Send Frame not addressed to RX_module with promiscuous flag
    $display("Test 5");
    reset_recv_array();
    data_array[0] = 64'h1032_00015EFF3FFF;
    reg_master_rx.send_write(4'h4, 32'h00012070, 4'b1111, reg_tx_error); // set promiscuous flag
    @(posedge clk_i);
    send_and_receive();
    check_data_received();
    @(posedge clk_i);


    $stop();
  end

  task reset_recv_array();
    for (int i = 0; i < 8; i++) begin
      data_recv_array[i] = 'd0;
    end
  endtask : reset_recv_array

  task send_and_receive();
    fork
      begin // send
        tx_framing_master_drv.send(data_array[0], 1'b0);
        tx_framing_master_drv.send(data_array[1], 1'b0);
        tx_framing_master_drv.send(data_array[2], 1'b0);
        tx_framing_master_drv.send(data_array[3], 1'b0);
        tx_framing_master_drv.send(data_array[4], 1'b0);
        tx_framing_master_drv.send(data_array[5], 1'b0);
        tx_framing_master_drv.send(data_array[6], 1'b0);
        tx_framing_master_drv.send(data_array[7], 1'b1);
        repeat(34) @(posedge clk_i);
      end
      begin // receive
        rx_framing_slave_drv.recv(data_recv_array[0], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[1], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[2], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[3], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[4], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[5], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[6], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[7], last_recv);
        rx_framing_slave_drv.recv(data_recv_array[8], last_recv); // SFD
      end
    join_any
  endtask : send_and_receive

  task check_data_received();
    for(int j=0; j<8; j++) begin
      if (data_array[j] != data_recv_array[j]) begin
        $display("Data at j= %d was recived %h but was sent as %h", j, data_recv_array[j], data_array[j]);
      end else begin
        $display("Data at j= %d was correctly recived: %h", j, data_recv_array[j]);
      end
    end
  endtask : check_data_received

  task check_no_data_received();
    for(int j=0; j<8; j++) begin
      if (data_recv_array[j] != 'd0) begin
        $display("Data at j= %d was recived %h but no data should have been received", j, data_recv_array[j]);
      end
    end
  endtask : check_no_data_received

endmodule
