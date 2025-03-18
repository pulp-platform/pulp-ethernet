// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>

module framing_top #(
  /// AXI Stream in request struct
  parameter type axi_stream_req_t  = logic,
  /// AXI Stream in response struct
  parameter type axi_stream_rsp_t  = logic
) (
  // Internal 125 MHz clock
  input  logic                 clk_i        ,
  input  logic                 rst_ni       ,
  input  logic                 clk90_int    ,
  input  logic                 clk200_int   ,

  // Ethernet: 1000BASE-T RGMII
  (* mark_debug = "true" *) input  logic                 phy_rx_clk   ,
  (* mark_debug = "true" *) input  logic     [3:0]       phy_rxd      ,
  (* mark_debug = "true" *) input  logic                 phy_rx_ctl   ,
  output logic                 phy_tx_clk   ,
  output logic     [3:0]       phy_txd      ,
  output logic                 phy_tx_ctl   ,
  output logic                 phy_reset_n  ,
  input  logic                 phy_int_n    ,
  input  logic                 phy_pme_n    ,

  input  logic                 rsp_valid_i  ,
  // AXIS TX/RX
  input  axi_stream_req_t      tx_axis_req_i,
  output axi_stream_rsp_t      tx_axis_rsp_o,
  output axi_stream_req_t      rx_axis_req_o,
  input  axi_stream_rsp_t      rx_axis_rsp_i,

  (* mark_debug = "true" *) output logic                eth_rx_irq_o ,
  output logic [11:0]         eth_len_o    ,
  output logic                rx_complete_o,
  output logic                tx_busy_o    ,
  (* mark_debug = "true" *) output logic                sync_o,
  input logic [47:0]          mac_address  ,
  input logic                 promiscuous  ,
  input logic                 irq_en       ,
  output logic [31:0]         tx_fcs_rev   ,
  output logic [31:0]         rx_fcs_rev
);

  localparam HEADER_LEN = 6;
  logic eth_irq;
  logic [2:0] last;
  (* mark_debug = "true" *)logic buf_busy;
  (* mark_debug = "true" *)logic rsp_valid;
  logic mac_gmii_tx_en;
  logic [47:0] rx_dest_mac;
  //(* mark_debug = "true" *) logic [47:0] dest_mac_sync1, dest_mac_sync2, dest_mac_sync3;
  logic [31:0] tx_fcs, rx_fcs;

  logic [11:0] rx_packet_length;
  (* mark_debug = "true" *) logic byte_sync;

  logic [7:0] rx_axis_tdata;
  logic       rx_axis_tvalid;
  logic       rx_axis_tlast;
  logic       rx_axis_tuser;

   logic  [6:0] rx_axis_tvalid_pipe;

  logic  [6:0] rx_axis_tlast_pipe;
  logic  [6:0] rx_axis_tuser_pipe;
  logic [7:0] rx_axis_tdata_pipe [6:0];

  assign eth_rx_irq_o = eth_irq && irq_en;

  sync #(
  .STAGES     ( 32'd3      ),
  .ResetValue ( 1'b0       )
) i_rsp_sync (
  .clk_i    ( phy_rx_clk    ),
  .rst_ni   ( rst_ni        ),
  .serial_i ( rsp_valid_i   ),
  .serial_o ( rsp_valid  )
);

  always_ff @(posedge phy_rx_clk or negedge rst_ni) begin
    if(!rst_ni) begin
      byte_sync    <= 1'b0;
      buf_busy     <= 1'b0;
      rx_packet_length <= 12'b0;
      eth_len_o <= 12'b0;
      rx_dest_mac <= 48'b0;
      rx_complete_o <= 1'b0;
      last <= 3'b0;
      for ( int i = 0; i < 7; i++) begin
        rx_axis_tdata_pipe[i]  <= 8'd0;
        rx_axis_tlast_pipe[i]  <= 1'b0;
        rx_axis_tuser_pipe[i]  <= 1'b0;
        rx_axis_tvalid_pipe[i] <= 1'b0;
      end
    end else begin
      if( rx_axis_tvalid && !byte_sync && !buf_busy) begin
        byte_sync  <= 1'b1;               // Start frame reception
        buf_busy   <= 1'b1;
      end
      // Capture Incoming Data
       if((!rx_complete_o) && (rx_axis_tvalid || (|rx_axis_tvalid_pipe))) begin
        // Shift data through the pipeline stages
        for (int i = 6; i > 0; i--) begin
          rx_axis_tdata_pipe[i]  <= rx_axis_tdata_pipe[i-1];
          rx_axis_tlast_pipe[i]  <= rx_axis_tlast_pipe[i-1];
          rx_axis_tuser_pipe[i]  <= rx_axis_tuser_pipe[i-1];
          rx_axis_tvalid_pipe[i] <= rx_axis_tvalid_pipe[i-1];
        end
        // Capture current data into stage 0
        rx_axis_tdata_pipe[0]  <= rx_axis_tdata;
        rx_axis_tlast_pipe[0]  <= rx_axis_tlast;
        rx_axis_tuser_pipe[0]  <= rx_axis_tuser;
        rx_axis_tvalid_pipe[0] <= rx_axis_tvalid;
      end
      // Increment packet length
      // also make sure between tlast and rsp_valid where rx_complete is up, no new packets are accepted
      if (rx_axis_tvalid && (!rx_complete_o)) begin
        rx_packet_length <= rx_packet_length + 1;
        if (rx_packet_length < HEADER_LEN)
          rx_dest_mac <= {rx_dest_mac[39:0], rx_axis_tdata};
      end

      if(rx_axis_tlast_pipe[6] && byte_sync) begin
        last <= 3'b1;
        eth_len_o <= rx_packet_length;
        //eth_len <= rx_packet_length -4;
        rx_packet_length <= 'b0;
        byte_sync <= 1'b0;
        rx_complete_o <= 1'b1;
      end else if ((last > 0) && (last < 7)) begin
        last <= last + 3'b1;
      end else begin
        last <= 3'b0;
      end

      if (rsp_valid) begin
        buf_busy <= 1'b0;
        rx_complete_o <= 1'b0;
      end
    end
  end

  // MAC Address Validation and IRQ Handling with conditional
  always_ff @(posedge phy_rx_clk or negedge rst_ni) begin
    if(!rst_ni) begin
      sync_o <= 1'b0;
      eth_irq <= 1'b0;
    end else begin
      // Sync evaluation afte header reception
      if((rx_packet_length == HEADER_LEN) && !sync_o ) begin
          sync_o <= (rx_dest_mac[47:24] == 24'h01005E) // Multicast
                           || (rx_dest_mac == 48'hFF_FF_FF_FF_FF_FF) // Broadcast
                           || (rx_dest_mac == mac_address) // Unicast to our MAC
                           || promiscuous;
      end
      // length is written to reg at tlast. stabalize for several cycles and trigger the irq
      if(last == 7) begin
        eth_irq <= 1'b1;
        sync_o <= 1'b0;
      end
      if( rsp_valid)  begin
        eth_irq <= 1'b0;
      end
    end
  end

  always_comb begin
    rx_axis_req_o.t  = '0;
    rx_axis_req_o.tvalid = '0;
    if (rx_axis_tvalid_pipe[6]) begin
      rx_axis_req_o.t.data = rx_axis_tdata_pipe[6];
      rx_axis_req_o.t.last = rx_axis_tlast_pipe[6];
      rx_axis_req_o.t.user =  rx_axis_tuser_pipe[6];
      rx_axis_req_o.t.strb = 'd1;
      rx_axis_req_o.t.keep = 'd1;
      rx_axis_req_o.tvalid = rx_axis_tvalid_pipe[6];
    end
  end

  rgmii_soc rgmii_soc1 (
    .rst_int       (~rst_ni             ),
    .clk_int       (clk_i               ),
    .clk90_int     (clk90_int           ),
    .clk_200_int   (clk200_int          ),

    // Ethernet: 1000BASE-T RGMII
    .phy_rx_clk    (phy_rx_clk          ),
    .phy_rxd       (phy_rxd             ),
    .phy_rx_ctl    (phy_rx_ctl          ),
    .phy_tx_clk    (phy_tx_clk          ),
    .phy_txd       (phy_txd             ),
    .phy_tx_ctl    (phy_tx_ctl          ),
    .phy_reset_n   (phy_reset_n         ),
    .phy_int_n     (phy_int_n           ),
    .phy_pme_n     (phy_pme_n           ),

    // TX ready signal
    .mac_gmii_tx_en(mac_gmii_tx_en      ),

    // AXIS TX
    .tx_axis_tdata (tx_axis_req_i.t.data),
    .tx_axis_tvalid(tx_axis_req_i.tvalid),
    .tx_axis_tready(tx_axis_rsp_o.tready),
    .tx_axis_tlast (tx_axis_req_i.t.last),
    .tx_axis_tuser (tx_axis_req_i.t.user), /// set to 0 if data is correct and set to 1 to abort TX

    // AXIS RX
    .rx_axis_tdata (rx_axis_tdata       ),
    .rx_axis_tvalid(rx_axis_tvalid      ),
    .rx_axis_tlast (rx_axis_tlast       ),
    .rx_axis_tuser (rx_axis_tuser       ),

    // Error registers
    .rx_fcs_reg    (rx_fcs               ),
    .tx_fcs_reg    (tx_fcs               ),
    .tx_busy       (tx_busy_o            )
  );

  assign tx_fcs_rev = {<<{tx_fcs}};
  assign rx_fcs_rev = {<<{rx_fcs}};

endmodule // framing_top

`ifdef GENESYSII
  `default_nettype none
`endif
