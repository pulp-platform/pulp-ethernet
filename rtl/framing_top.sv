// See LICENSE for license details.

`ifdef GENESYSII
  `default_nettype none
`endif

module framing_top #(
  /// AXI Stream in request struct
  parameter type axi_stream_req_t  = logic,
  /// AXI Stream in response struct
  parameter type axi_stream_rsp_t  = logic,
  /// reg intf
  parameter type reg2hw_itf_t      = logic,
  parameter type hw2reg_itf_t      = logic,
  /// regbus address width
  parameter int AW_REGBUS          = 4
) (
  // Internal 125 MHz clock
  input  wire                                           clk_i        ,
  input  wire                                           rst_ni       ,
  input  wire                                           clk90_int    ,
  input  wire                                           clk_200_int  ,
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
  output reg                                            phy_mdio_o   ,
  output reg                                            phy_mdio_oe  ,
  output wire                                           phy_mdc      ,
  // AXIS TX/RX
  input  axi_stream_req_t                               tx_axis_req_i,
  output axi_stream_rsp_t                               tx_axis_rsp_o,
  output axi_stream_req_t                               rx_axis_req_o,
  input  axi_stream_rsp_t                               rx_axis_rsp_i,
  // REGBUS configs
  input  reg2hw_itf_t                                   reg2hw_i,
  output hw2reg_itf_t                                   hw2reg_o    
);

  import eth_idma_reg_pkg::* ;

  logic        mac_gmii_tx_en;
  logic        accept_frame_q, accept_frame_d;
  logic [47:0] mac_address, rx_dest_mac;
  logic        promiscuous;

  //AXIS RX
  logic [7:0] rx_axis_tdata_5_q,  rx_axis_tdata_4_q,  rx_axis_tdata_3_q,  rx_axis_tdata_2_q,  rx_axis_tdata_1_q,  rx_axis_tdata_0_q;
  logic [7:0] rx_axis_tdata_5_d,  rx_axis_tdata_4_d,  rx_axis_tdata_3_d,  rx_axis_tdata_2_d,  rx_axis_tdata_1_d,  rx_axis_tdata_0_d;
  logic       rx_axis_tvalid_5_q, rx_axis_tvalid_4_q, rx_axis_tvalid_3_q, rx_axis_tvalid_2_q, rx_axis_tvalid_1_q, rx_axis_tvalid_0_q;
  logic       rx_axis_tvalid_5_d, rx_axis_tvalid_4_d, rx_axis_tvalid_3_d, rx_axis_tvalid_2_d, rx_axis_tvalid_1_d, rx_axis_tvalid_0_d;
  logic       rx_axis_tlast_5_q,  rx_axis_tlast_4_q,  rx_axis_tlast_3_q,  rx_axis_tlast_2_q,  rx_axis_tlast_1_q,  rx_axis_tlast_0_q;
  logic       rx_axis_tlast_5_d,  rx_axis_tlast_4_d,  rx_axis_tlast_3_d,  rx_axis_tlast_2_d,  rx_axis_tlast_1_d,  rx_axis_tlast_0_d;
  logic       rx_axis_tuser_5_q,  rx_axis_tuser_4_q,  rx_axis_tuser_3_q,  rx_axis_tuser_2_q,  rx_axis_tuser_1_q,  rx_axis_tuser_0_q;
  logic       rx_axis_tuser_5_d,  rx_axis_tuser_4_d,  rx_axis_tuser_3_d,  rx_axis_tuser_2_d,  rx_axis_tuser_1_d,  rx_axis_tuser_0_d;

  assign mac_address = {reg2hw_i.machi_mdio.upper_mac_address.q, reg2hw_i.maclo_addr.q}; // combine upper and lower mac address from registers
  assign promiscuous = reg2hw_i.machi_mdio.promiscuous.q;
  assign phy_mdc     = reg2hw_i.machi_mdio.phy_mdclk.q;
  assign phy_mdio_o  = reg2hw_i.machi_mdio.phy_mdio_o.q;
  assign phy_mdio_oe = reg2hw_i.machi_mdio.phy_mdio_oe.q;

  assign hw2reg_o.tx_fcs.de = 1'b1;
  assign hw2reg_o.rx_fcs.de = 1'b1;

  always_comb begin
    rx_axis_tdata_4_d  = rx_axis_tdata_5_q;
    rx_axis_tvalid_4_d = rx_axis_tvalid_5_q;
    rx_axis_tlast_4_d  = rx_axis_tlast_5_q;
    rx_axis_tuser_4_d  = rx_axis_tuser_5_q;
    rx_axis_tdata_3_d  = rx_axis_tdata_4_q;
    rx_axis_tvalid_3_d = rx_axis_tvalid_4_q;
    rx_axis_tlast_3_d  = rx_axis_tlast_4_q;
    rx_axis_tuser_3_d  = rx_axis_tuser_4_q;
    rx_axis_tdata_2_d  = rx_axis_tdata_3_q;
    rx_axis_tvalid_2_d = rx_axis_tvalid_3_q;
    rx_axis_tlast_2_d  = rx_axis_tlast_3_q;
    rx_axis_tuser_2_d  = rx_axis_tuser_3_q;
    rx_axis_tdata_1_d  = rx_axis_tdata_2_q;
    rx_axis_tvalid_1_d = rx_axis_tvalid_2_q;
    rx_axis_tlast_1_d  = rx_axis_tlast_2_q;
    rx_axis_tuser_1_d  = rx_axis_tuser_2_q;
    rx_axis_tdata_0_d  = rx_axis_tdata_1_q;
    rx_axis_tvalid_0_d = rx_axis_tvalid_1_q;
    rx_axis_tlast_0_d  = rx_axis_tlast_1_q;
    rx_axis_tuser_0_d  = rx_axis_tuser_1_q;

    rx_dest_mac = {rx_axis_tdata_5_d, rx_axis_tdata_5_q, rx_axis_tdata_4_q, rx_axis_tdata_3_q,
                   rx_axis_tdata_2_q, rx_axis_tdata_1_q};

    accept_frame_d = accept_frame_q;
      if (!rx_axis_tvalid_0_q && rx_axis_tvalid_1_q) begin // check for beginning of eth frame
        // accept_frame_d = isMulticastRange || isBroadcast (ff:ff:ff:ff:ff) ||
        //                isFrameAdresssedToOurMacAddress || isPromiscous (store all frames)
        accept_frame_d = (rx_dest_mac[47:24]==24'h01005E) | (&rx_dest_mac) |
                         (mac_address == rx_dest_mac) | promiscuous;
      end

    rx_axis_req_o.t.data = accept_frame_q ? rx_axis_tdata_0_q  : 'd0;
    rx_axis_req_o.tvalid = accept_frame_q ? rx_axis_tvalid_0_q : 'd0;
    rx_axis_req_o.t.last = accept_frame_q ? rx_axis_tlast_0_q  : 'd0;
    rx_axis_req_o.t.user = accept_frame_q ? rx_axis_tuser_0_q  : 'd0;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) begin
      rx_axis_tdata_5_q  <= 'd0;
      rx_axis_tvalid_5_q <= 'd0;
      rx_axis_tlast_5_q  <= 'd0;
      rx_axis_tuser_5_q  <= 'd0;
      rx_axis_tdata_4_q  <= 'd0;
      rx_axis_tvalid_4_q <= 'd0;
      rx_axis_tlast_4_q  <= 'd0;
      rx_axis_tuser_4_q  <= 'd0;
      rx_axis_tdata_3_q  <= 'd0;
      rx_axis_tvalid_3_q <= 'd0;
      rx_axis_tlast_3_q  <= 'd0;
      rx_axis_tuser_3_q  <= 'd0;
      rx_axis_tdata_2_q  <= 'd0;
      rx_axis_tvalid_2_q <= 'd0;
      rx_axis_tlast_2_q  <= 'd0;
      rx_axis_tuser_2_q  <= 'd0;
      rx_axis_tdata_1_q  <= 'd0;
      rx_axis_tvalid_1_q <= 'd0;
      rx_axis_tlast_1_q  <= 'd0;
      rx_axis_tuser_1_q  <= 'd0;
      rx_axis_tdata_0_q  <= 'd0;
      rx_axis_tvalid_0_q <= 'd0;
      rx_axis_tlast_0_q  <= 'd0;
      rx_axis_tuser_0_q  <= 'd0;

      accept_frame_q <= 'd0;
    end else begin
      rx_axis_tdata_5_q  <= rx_axis_tdata_5_d;
      rx_axis_tvalid_5_q <= rx_axis_tvalid_5_d;
      rx_axis_tlast_5_q  <= rx_axis_tlast_5_d;
      rx_axis_tuser_5_q  <= rx_axis_tuser_5_d;
      rx_axis_tdata_4_q  <= rx_axis_tdata_4_d;
      rx_axis_tvalid_4_q <= rx_axis_tvalid_4_d;
      rx_axis_tlast_4_q  <= rx_axis_tlast_4_d;
      rx_axis_tuser_4_q  <= rx_axis_tuser_4_d;
      rx_axis_tdata_3_q  <= rx_axis_tdata_3_d;
      rx_axis_tvalid_3_q <= rx_axis_tvalid_3_d;
      rx_axis_tlast_3_q  <= rx_axis_tlast_3_d;
      rx_axis_tuser_3_q  <= rx_axis_tuser_3_d;
      rx_axis_tdata_2_q  <= rx_axis_tdata_2_d;
      rx_axis_tvalid_2_q <= rx_axis_tvalid_2_d;
      rx_axis_tlast_2_q  <= rx_axis_tlast_2_d;
      rx_axis_tuser_2_q  <= rx_axis_tuser_2_d;
      rx_axis_tdata_1_q  <= rx_axis_tdata_1_d;
      rx_axis_tvalid_1_q <= rx_axis_tvalid_1_d;
      rx_axis_tlast_1_q  <= rx_axis_tlast_1_d;
      rx_axis_tuser_1_q  <= rx_axis_tuser_1_d;
      rx_axis_tdata_0_q  <= rx_axis_tdata_0_d;
      rx_axis_tvalid_0_q <= rx_axis_tvalid_0_d;
      rx_axis_tlast_0_q  <= rx_axis_tlast_0_d;
      rx_axis_tuser_0_q  <= rx_axis_tuser_0_d;

      accept_frame_q <= accept_frame_d;
    end
  end

  rgmii_soc rgmii_soc1 (
    .rst_int       (~rst_ni             ),
    .clk_int       (clk_i               ),
    .clk90_int     (clk90_int           ),
    .clk_200_int   (clk_200_int         ),

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
    .rx_axis_tdata (rx_axis_tdata_5_d   ),
    .rx_axis_tvalid(rx_axis_tvalid_5_d  ),
    .rx_axis_tlast (rx_axis_tlast_5_d   ),
    .rx_axis_tuser (rx_axis_tuser_5_d   ),

    // Error registers
    .rx_fcs_reg    (hw2reg_o.rx_fcs.d    ),
    .tx_fcs_reg    (hw2reg_o.tx_fcs.d    )
  );

endmodule // framing_top

`ifdef GENESYSII
  `default_nettype none
`endif


`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"

/// framing_top (interface wrapper).
module framing_top_intf (
  // Internal 125 MHz clock
  input  wire           clk_i       ,
  input  wire           rst_ni      ,
  input  wire           clk90_int   ,
  input  wire           clk_200_int ,
  /// Ethernet: 1000BASE-T RGMII
  input  wire           phy_rx_clk  ,
  input  wire     [3:0] phy_rxd     ,
  input  wire           phy_rx_ctl  ,
  output wire           phy_tx_clk  ,
  output wire     [3:0] phy_txd     ,
  output wire           phy_tx_ctl  ,
  output wire           phy_reset_n ,
  input  wire           phy_int_n   ,
  input  wire           phy_pme_n   ,
  /// MDIO
  input  wire           phy_mdio_i  ,
  output      reg       phy_mdio_o  ,
  output      reg       phy_mdio_oe ,
  output wire           phy_mdc     ,
  /// AXI Stream Bus TX Port
  AXI_STREAM_BUS.Rx     axis_tx     ,
  /// AXI Stream Bus RX Port
  AXI_STREAM_BUS.Tx     axis_rx     ,
  // configuration (register interface)
  REG_BUS.in            regbus_slave
);

// -------------------- REGBUS defines ----------------------
  parameter int AW_REGBUS = 4;
  localparam int DW_REGBUS = 32;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  `include "register_interface/typedef.svh"
  `include "register_interface/assign.svh"

  // Define structs for reg_bus
  typedef logic [AW_REGBUS-1:0] addr_t;
  typedef logic [DW_REGBUS-1:0] data_t;
  typedef logic [STRB_WIDTH-1:0] strb_t;
  `REG_BUS_TYPEDEF_ALL(reg_bus, addr_t, data_t, strb_t)

  reg_bus_req_t s_reg_req;
  reg_bus_rsp_t s_reg_rsp;

  // Assign SV interface to structs
  `REG_BUS_ASSIGN_TO_REQ(s_reg_req, regbus_slave)
  `REG_BUS_ASSIGN_FROM_RSP(regbus_slave, s_reg_rsp)


// -------------------- AXIS defines ----------------------
  localparam int unsigned DataWidth = 8;
  localparam int unsigned IdWidth   = 0;
  localparam int unsigned DestWidth = 0;
  localparam int unsigned UserWidth = 1;

  // AXI stream channels typedefs
  typedef logic [DataWidth-1:0]   tdata_t;
  typedef logic [DataWidth/8-1:0] tstrb_t;
  typedef logic [DataWidth/8-1:0] tkeep_t;
  typedef logic [IdWidth-1:0]     tid_t;
  typedef logic [DestWidth-1:0]   tdest_t;
  typedef logic [UserWidth-1:0]   tuser_t;

  `AXI_STREAM_TYPEDEF_ALL(s, tdata_t, tstrb_t, tkeep_t, tid_t, tdest_t, tuser_t)

  // AXI stream signals
  s_req_t s_tx_req, s_rx_req;
  s_rsp_t s_tx_rsp, s_rx_rsp;

  // connect modports to req/rsp signals
  `AXI_STREAM_ASSIGN_TO_REQ(s_tx_req, axis_tx)
  `AXI_STREAM_ASSIGN_FROM_RSP(axis_tx, s_tx_rsp)
  `AXI_STREAM_ASSIGN_FROM_REQ(axis_rx, s_rx_req)
  `AXI_STREAM_ASSIGN_TO_RSP(s_rx_rsp, axis_rx)

  framing_top #(
    .axi_stream_req_t(s_req_t),
    .axi_stream_rsp_t(s_rsp_t),
    .reg_req_t       (reg_bus_req_t),
    .reg_rsp_t       (reg_bus_rsp_t),
    .AW_REGBUS       (AW_REGBUS)
  ) i_framing_top (
    .rst_ni(rst_ni),
    .clk_i(clk_i),
    .clk90_int(clk90_int),
    .clk_200_int(clk_200_int),

    // Ethernet: 1000BASE-T RGMII
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd),
    .phy_rx_ctl(phy_rx_ctl),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    .phy_reset_n(phy_reset_n),
    .phy_int_n(phy_int_n),
    .phy_pme_n(phy_pme_n),

    // MDIO
    .phy_mdio_i(phy_mdio_i),
    .phy_mdio_o(phy_mdio_o),
    .phy_mdio_oe(phy_mdio_oe),
    .phy_mdc(phy_mdc),

    // AXIS TX/RX
    .tx_axis_req_i(s_tx_req),
    .tx_axis_rsp_o(s_tx_rsp),
    .rx_axis_req_o(s_rx_req),
    .rx_axis_rsp_i(s_rx_rsp),

    // REGBUS Configuration Interface
    .reg_req_i(s_reg_req),
    .reg_rsp_o(s_reg_rsp)
  );

endmodule : framing_top_intf
