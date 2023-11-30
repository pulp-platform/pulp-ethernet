`timescale 1 ns/1 ps
`include "axi/assign.svh"


module eth_tb;

   parameter AW = 32;  //Address width
   parameter DW = 64;  //Data width
   parameter IW = 8;   //ID width
   parameter UW = 8;   //User width

   localparam tCK    = 1ns;
   localparam tCK200 = 5ns;
   localparam tCK125 = 8ns;

   logic s_clk           = 0;
   logic s_clk_200MHz    = 0;
   logic s_clk_125MHz_0  = 0;
   logic s_clk_125MHz_90 = 0;
   logic s_rst_n         = 1;
   logic done            = 0;

   // signals to instantiate the DUT
   wire       eth_rxck;
   wire       eth_rxctl;
   wire [3:0] eth_rxd;
   wire       eth_txck;
   wire       eth_txctl;
   wire [3:0] eth_txd;
   wire       eth_tx_rst_n;
   wire       eth_rx_rst_n;

   //------------------------ AXI drivers --------------------------

   AXI_BUS_DV
     #(
       .AXI_ADDR_WIDTH(AW),
       .AXI_DATA_WIDTH(DW),
       .AXI_ID_WIDTH(IW),
       .AXI_USER_WIDTH(UW)
       )
   axi_master_tx_dv(s_clk), axi_master_rx_dv(s_clk);

   AXI_BUS
     #(
       .AXI_ADDR_WIDTH(AW),
       .AXI_DATA_WIDTH(DW),
       .AXI_ID_WIDTH(IW),
       .AXI_USER_WIDTH(UW)
       )
   axi_master_tx(),axi_master_rx();

   `AXI_ASSIGN(axi_master_tx, axi_master_tx_dv)
   `AXI_ASSIGN(axi_master_rx, axi_master_rx_dv)

   typedef axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(IW), .UW(UW), .TA(200ps), .TT(700ps)) axi_drv_t;
   axi_drv_t axi_master_tx_drv =  new(axi_master_tx_dv);
   axi_drv_t axi_master_rx_drv =  new(axi_master_rx_dv);


   // ---------------------------- DUT -----------------------------
   // TX ETH_RGMII
   eth_rgmii_synth i_eth_rgmii_tx
     (
      .clk_i           ( s_clk             ),
      .clk_200MHz_i    ( s_clk_200MHz      ),
      .rst_ni          ( s_rst_n           ),
      .eth_clk_i       ( s_clk_125MHz_90   ), //90

      .aw_id    (axi_master_tx.aw_id    ),
      .aw_addr  (axi_master_tx.aw_addr  ),
      .aw_len   (axi_master_tx.aw_len   ),
      .aw_size  (axi_master_tx.aw_size  ),
      .aw_burst (axi_master_tx.aw_burst ),
      .aw_lock  (axi_master_tx.aw_lock  ),
      .aw_cache (axi_master_tx.aw_cache ),
      .aw_prot  (axi_master_tx.aw_prot  ),
      .aw_qos   (axi_master_tx.aw_qos   ),
      .aw_region(axi_master_tx.aw_region),
      .aw_atop  (axi_master_tx.aw_atop  ),
      .aw_user  (axi_master_tx.aw_user  ),
      .aw_valid (axi_master_tx.aw_valid ),
      .aw_ready (axi_master_tx.aw_ready ),
      .w_data   (axi_master_tx.w_data   ),
      .w_strb   (axi_master_tx.w_strb   ),
      .w_last   (axi_master_tx.w_last   ),
      .w_user   (axi_master_tx.w_user   ),
      .w_valid  (axi_master_tx.w_valid  ),
      .w_ready  (axi_master_tx.w_ready  ),
      .b_id     (axi_master_tx.b_id     ),
      .b_resp   (axi_master_tx.b_resp   ),
      .b_user   (axi_master_tx.b_user   ),
      .b_valid  (axi_master_tx.b_valid  ),
      .b_ready  (axi_master_tx.b_ready  ),
      .ar_id    (axi_master_tx.ar_id    ),
      .ar_addr  (axi_master_tx.ar_addr  ),
      .ar_len   (axi_master_tx.ar_len   ),
      .ar_size  (axi_master_tx.ar_size  ),
      .ar_burst (axi_master_tx.ar_burst ),
      .ar_lock  (axi_master_tx.ar_lock  ),
      .ar_cache (axi_master_tx.ar_cache ),
      .ar_prot  (axi_master_tx.ar_prot  ),
      .ar_qos   (axi_master_tx.ar_qos   ),
      .ar_region(axi_master_tx.ar_region),
      .ar_user  (axi_master_tx.ar_user  ),
      .ar_valid (axi_master_tx.ar_valid ),
      .ar_ready (axi_master_tx.ar_ready ),
      .r_id     (axi_master_tx.r_id     ),
      .r_data   (axi_master_tx.r_data   ),
      .r_resp   (axi_master_tx.r_resp   ),
      .r_last   (axi_master_tx.r_last   ),
      .r_user   (axi_master_tx.r_user   ),
      .r_valid  (axi_master_tx.r_valid  ),
      .r_ready  (axi_master_tx.r_ready  ),

      .eth_rxck        ( eth_rxck          ),
      .eth_rxctl       ( eth_rxctl         ),
      .eth_rxd         ( eth_rxd           ),

      .eth_txck        ( eth_txck          ),
      .eth_txctl       ( eth_txctl         ),
      .eth_txd         ( eth_txd           ),

      .eth_irq         (),

      .eth_rst_n       ( eth_tx_rst_n      ),
      .phy_tx_clk_i    ( s_clk_125MHz_0    ) //0
      );

   // RX ETH_RGMII
   eth_rgmii_synth i_eth_rgmii_rx
     (
      .clk_i           ( s_clk             ),
      .clk_200MHz_i    ( s_clk_200MHz      ),
      .rst_ni          ( s_rst_n           ),

      .eth_clk_i       ( s_clk_125MHz_90   ), // 90

      .aw_id    (axi_master_rx.aw_id    ),
      .aw_addr  (axi_master_rx.aw_addr  ),
      .aw_len   (axi_master_rx.aw_len   ),
      .aw_size  (axi_master_rx.aw_size  ),
      .aw_burst (axi_master_rx.aw_burst ),
      .aw_lock  (axi_master_rx.aw_lock  ),
      .aw_cache (axi_master_rx.aw_cache ),
      .aw_prot  (axi_master_rx.aw_prot  ),
      .aw_qos   (axi_master_rx.aw_qos   ),
      .aw_region(axi_master_rx.aw_region),
      .aw_atop  (axi_master_rx.aw_atop  ),
      .aw_user  (axi_master_rx.aw_user  ),
      .aw_valid (axi_master_rx.aw_valid ),
      .aw_ready (axi_master_rx.aw_ready ),
      .w_data   (axi_master_rx.w_data   ),
      .w_strb   (axi_master_rx.w_strb   ),
      .w_last   (axi_master_rx.w_last   ),
      .w_user   (axi_master_rx.w_user   ),
      .w_valid  (axi_master_rx.w_valid  ),
      .w_ready  (axi_master_rx.w_ready  ),
      .b_id     (axi_master_rx.b_id     ),
      .b_resp   (axi_master_rx.b_resp   ),
      .b_user   (axi_master_rx.b_user   ),
      .b_valid  (axi_master_rx.b_valid  ),
      .b_ready  (axi_master_rx.b_ready  ),
      .ar_id    (axi_master_rx.ar_id    ),
      .ar_addr  (axi_master_rx.ar_addr  ),
      .ar_len   (axi_master_rx.ar_len   ),
      .ar_size  (axi_master_rx.ar_size  ),
      .ar_burst (axi_master_rx.ar_burst ),
      .ar_lock  (axi_master_rx.ar_lock  ),
      .ar_cache (axi_master_rx.ar_cache ),
      .ar_prot  (axi_master_rx.ar_prot  ),
      .ar_qos   (axi_master_rx.ar_qos   ),
      .ar_region(axi_master_rx.ar_region),
      .ar_user  (axi_master_rx.ar_user  ),
      .ar_valid (axi_master_rx.ar_valid ),
      .ar_ready (axi_master_rx.ar_ready ),
      .r_id     (axi_master_rx.r_id     ),
      .r_data   (axi_master_rx.r_data   ),
      .r_resp   (axi_master_rx.r_resp   ),
      .r_last   (axi_master_rx.r_last   ),
      .r_user   (axi_master_rx.r_user   ),
      .r_valid  (axi_master_rx.r_valid  ),
      .r_ready  (axi_master_rx.r_ready  ),

      .eth_rxck        ( eth_txck          ),
      .eth_rxctl       ( eth_txctl         ),
      .eth_rxd         ( eth_txd           ),

      .eth_txck        ( eth_rxck          ),
      .eth_txctl       ( eth_rxctl         ),
      .eth_txd         ( eth_rxd           ),

      .eth_irq         (),

      .eth_rst_n       ( eth_rx_rst_n      ),
      .phy_tx_clk_i    ( s_clk_125MHz_0    ) //0
      );

   // high level functions for axi operations
   fixture_eth fix();

   logic [63:0] rx_read_data;
   assign rx_read_data=axi_master_rx.r_data;

   // initialization data array (data to be sent by TX)
   logic [DW-1:0] data_array [7:0];
   initial begin
      data_array[0] = 64'h1032207098001032; //1 --> 230100890702 2301, mac dest + inizio di mac source
      data_array[1] = 64'h3210E20020709800; //2 --> 00890702 002E 0123, fine mac source + length + payload
      data_array[2] = 64'h1716151413121110; // payload
      data_array[3] = 64'h2726252423222120;
      data_array[4] = 64'h3736353433323130;
      data_array[5] = 64'h4746454443424140;
      data_array[6] = 64'h5756555453525150;
      data_array[7] = 64'h6766656463626160;
   end

   // initialization read addresses
   logic [AW-1:0] read_addr [7:0];
   initial begin
      read_addr[0] = 32'h00004000;
      read_addr[1] = 32'h00004008;
      read_addr[2] = 32'h00004010;
      read_addr[3] = 32'h00004018;
      read_addr[4] = 32'h00004020;
      read_addr[5] = 32'h00004028;
      read_addr[6] = 32'h00004030;
      read_addr[7] = 32'h00004038;
   end

   // initialization write addresses
   logic [AW-1:0] write_addr [7:0];
   initial begin
      write_addr[0] = 32'h00001000;
      write_addr[1] = 32'h00001008;
      write_addr[2] = 32'h00001010;
      write_addr[3] = 32'h00001018;
      write_addr[4] = 32'h00001020;
      write_addr[5] = 32'h00001028;
      write_addr[6] = 32'h00001030;
      write_addr[7] = 32'h00001038;
   end

   event       tx_complete;
  // logic       en_rx_memw;
  // assign en_rx_memw = i_eth_rgmii_rx.eth_rgmii.RAMB16_inst_rx.genblk1[0].asym_ram_tdp_read_first_inst.enaB;
  // assign en_rx_memw = i_eth_rgmii_rx.eth_rgmii.dualmem_widen8.mem_wrap_rx_0.enaB;


   // ---------------------- CLOCK GENERATION ------------------------

   initial begin
      while (!done) begin //SYSTEM CLOCK
               s_clk <= 1;
               #(tCK/2);
               s_clk <= 0;
               #(tCK/2);
      end
   end

   initial begin
      while (!done) begin
               s_clk_200MHz <= 1;
               #(tCK200/2);
               s_clk_200MHz <= 0;
               #(tCK200/2);
      end
   end

   initial begin
      while (!done) begin
               s_clk_125MHz_0 <= 1;
               #(tCK125/2);
               s_clk_125MHz_0 <= 0;
               #(tCK125/2);
      end
   end

   initial begin
      while (!done) begin
               s_clk_125MHz_90 <= 0;
               #(tCK125/2);
               s_clk_125MHz_90 <= 1;
                 #(tCK125/2);
      end
   end


   // ------------------------ BEGINNING OF SIMULATION ------------------------

   initial begin
      // General reset
      axi_master_rx_drv.reset_slave();
      axi_master_rx_drv.reset_master();
      axi_master_tx_drv.reset_slave();
      axi_master_tx_drv.reset_master();
      s_rst_n <= 0;
      repeat(10) @(posedge s_clk);
      s_rst_n <= 1;
      #tCK;


      #3000ns;


      // Packet length
      fix.write_axi(axi_master_tx_drv,'h00000810,'h00000040, 'h0f);
      repeat(5) @(posedge s_clk);

      // TX BUFFER FILLING ----------------------------------------------
      for(int j=0; j<8; j++) begin
         fix.write_axi(axi_master_tx_drv, write_addr[j], data_array[j], 'hff);
         @(posedge s_clk);
      end
      repeat(10) @(posedge s_clk);

      // TRANSMISSION OF PACKET -----------------------------------------
      // 1 --> mac_address[31:0]
      fix.write_axi(axi_master_tx_drv,'h00000800,'h00890702, 'h0f);
      @(posedge s_clk);

      // 2 --> {irq_en,promiscuous,spare,loopback,cooked,mac_address[47:32]}
      fix.write_axi(axi_master_tx_drv,'h00000808,'h00002301, 'h0f);
      @(posedge s_clk);

      // 3 --> Rx frame check sequence register(read) and last register(write)
      fix.write_axi(axi_master_tx_drv,'h00000828,'h00000008, 'h0f);
      @(posedge s_clk);

   end

   // -------------- CHECK IF RECEIVED DATA == TRANSMITTED DATA ----------------
   // Event trigger (wait for the rx memory to be written)
   initial begin
      while(1) begin
         repeat(15000) @(posedge s_clk);
         -> tx_complete;
      end
   end

   // Check if the data received and stored in the rx memory matches the transmitted data
   initial begin
      while(1) begin
         wait(tx_complete.triggered);

         for(int i=0; i<8; i++) begin
            fix.read_axi(axi_master_rx_drv, read_addr[i]);
            if(rx_read_data == data_array[i]) $display("Data check: OK");
            else begin
               $display("[FAIL] At least one mismatch between written and read data");
               $stop();
            end
         end
          $display("[SUCCESS] All written and read data match");
         $stop();
      end
   end


endmodule
