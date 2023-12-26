// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51


`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh" 
`include "idma/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"  
`include "common_cells/registers.svh"
 

module eth_idma_wrap #(
  /// Data width
  parameter int unsigned DataWidth           = 32'd32,
  /// Address width
  parameter int unsigned AddrWidth           = 32'd32,
  /// AXI User width 
  parameter int unsigned UserWidth           = 32'd1,
  /// AXI ID width ( tb exmaple, ID is currently used to distinguish transfers in tb)
  parameter int unsigned AxiIdWidth          = 32'd1, 
  /// Number of transaction that can be in-flight concurrently
  parameter int unsigned NumAxInFlight       = 32'd3,
  /// The depth of the internal reorder buffer
  parameter int unsigned BufferDepth         = 32'd3,
  /// With of a transfer: max transfer size is `2**TFLenWidth` bytes
  parameter int unsigned TFLenWidth          = 32'd32,
  /// The depth of the memory system the backend is attached to
  parameter int unsigned MemSysDepth         = 32'd0,
  /// Should the `R`-`AW` coupling hardware be present? (recommended)
  parameter bit          RAWCouplingAvail    = 1'b0,
  /// Mask invalid data on the manager interface
  parameter bit          MaskInvalidData     = 1'b1,
  parameter bit          CombinedShifter       = 1'b1,
  /// hardware legalization present
  parameter bit          HardwareLegalizer   = 1'b1,
  /// Reject zero-length transfers
  parameter bit          RejectZeroTransfers = 1'b1,
  /// Enable error handling
  parameter bit          ErrorHandling       = 1'b0,
  /// REGBUS
  /// Strobe Width (do not override!)
  parameter int unsigned StrbWidth           = DataWidth / 8,
  /// Offset Width (do not override!)
  parameter int unsigned OffsetWidth         = $clog2(StrbWidth),
  /// non-overriden dependent type for idma req
  /// Address type (do not override!)
  parameter type addr_t                      = logic[AddrWidth-1:0],
  /// Data type (do not override!)
  parameter type data_t                      = logic[DataWidth-1:0],
  /// Strobe type (do not override!)
  parameter type strb_t                      = logic[StrbWidth-1:0],
  /// User type (do not override!)
  parameter type user_t                      = logic[UserWidth-1:0],
  /// ID type (do not override!)
  parameter type id_t                        = logic[AxiIdWidth-1:0],
  /// Transfer length type (do not override!)
  parameter type tf_len_t                    = logic[TFLenWidth-1:0],
  /// Offset type (do not override!)
  parameter type offset_t                    = logic[OffsetWidth-1:0],
  /// 

  parameter type reg_req_t                   = eth_idma_pkg::reg_bus_req_t,
  parameter type reg_rsp_t                   = eth_idma_pkg::reg_bus_rsp_t
)(
  input  logic                       clk_i,
  input  logic                       rst_ni, 

  /// Etherent Internal clocks
  input  logic                       eth_clk_i, 
  input  logic                       eth_clk90_i, 
  input  logic                       eth_clk200M_i, 

  /// Ethernet: 1000BASE-T RGMII
  input  logic                       phy_rx_clk_i,
  input  logic    [3:0]              phy_rxd_i,
  input  logic                       phy_rx_ctl_i,
  output logic                       phy_tx_clk_o,
  output logic    [3:0]              phy_txd_o,
  output logic                       phy_tx_ctl_o,

  output wire                        phy_resetn_o,
  input  wire                        phy_intn_i,
  input  wire                        phy_pme_i,

  /// Ethernet MDIO
  input  wire                        phy_mdio_i,
  output reg                         phy_mdio_o,
  output reg                         phy_mdio_oe,
  output wire                        phy_mdc,

  /// idma testmode in
  input  logic                       testmode_i,

  /// Error handler request
  input  idma_pkg::idma_eh_req_t     idma_eh_req_i,
  input  logic                       eh_req_valid_i,
  output logic                       eh_req_ready_o,

  output               eth_idma_pkg::axi_req_t     axi_read_req_o,
  input                eth_idma_pkg::axi_rsp_t     axi_read_rsp_i,
  output               eth_idma_pkg::axi_req_t     axi_write_req_o,
  input                eth_idma_pkg::axi_rsp_t     axi_write_rsp_i,

  /// iDMA busy flags
  output idma_pkg::idma_busy_t       idma_busy_o,

  /// REGBUS Configuration Interface
  input  reg_req_t                   reg_req_i,
  output reg_rsp_t                   reg_rsp_o

);
 
 logic  idma_req_valid ;
 logic  idma_rsp_ready ;
    
 import eth_idma_reg_pkg::*;
 localparam idma_pkg::error_cap_e ErrorCap = ErrorHandling ? idma_pkg::ERROR_HANDLING :
                                                                idma_pkg::NO_ERROR_HANDLING;
 localparam int unsigned AW_REGBUS = 8; 

 
 /// AXI4+ATOP typedefs
 `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
 `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, data_t, strb_t, user_t)
 `AXI_TYPEDEF_B_CHAN_T(axi_b_chan_t, id_t, user_t) 

 `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
 `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, data_t, id_t, user_t) 


 /// AXI Stream typedefs
 `IDMA_AXI_STREAM_TYPEDEF_S_CHAN_T(axis_t_chan_t, data_t, strb_t, strb_t, id_t, id_t, user_t)
 `IDMA_AXI_STREAM_TYPEDEF_REQ_T(axi_stream_req_t, axis_t_chan_t)
 `IDMA_AXI_STREAM_TYPEDEF_RSP_T(axi_stream_rsp_t)


 /// Meta Channel Widths
 localparam int unsigned axi_aw_chan_width = axi_pkg::aw_width(AddrWidth, AxiIdWidth, UserWidth);
 localparam int unsigned axi_ar_chan_width = axi_pkg::ar_width(AddrWidth, AxiIdWidth, UserWidth); 
 localparam int unsigned axis_t_chan_width = $bits(axis_t_chan_t);

 /// Option struct: AXI4 id as well as AXI and backend options
 /// - `last`: a flag can be set if this transfer is the last of a set of transfers
 `IDMA_TYPEDEF_OPTIONS_T(options_t, id_t)

 /// 1D iDMA request type:
 /// - `length`: the length of the transfer in bytes
 /// - `*_addr`: the source / target byte addresses of the transfer
 /// - `opt`: the options field
 `IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, addr_t, options_t)

 /// 1D iDMA response payload:
 /// - `cause`: the AXI response
 /// - `err_type`: type of the error: read, write, internal, ...
 /// - `burst_addr`: the burst address where the issue error occurred
 `IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, addr_t)

 /// 1D iDMA response type:
 /// - `last`: the response of the request that was marked with the `opt.last` flag
 /// - `error`: 1 if an error occurred
 /// - `pld`: the error payload
 `IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)

 function int unsigned max_width(input int unsigned a, b);
     return (a > b) ? a : b;
 endfunction

 typedef struct packed {
     axi_ar_chan_t ar_chan;
     logic[max_width(axi_ar_chan_width, axis_t_chan_width)-axi_ar_chan_width:0] padding;
 } axi_read_ar_chan_padded_t;

 typedef struct packed {
     axis_t_chan_t t_chan;
     logic[max_width(axi_ar_chan_width, axis_t_chan_width)-axis_t_chan_width:0] padding;
 } axis_read_t_chan_padded_t;

 typedef union packed {
     axi_read_ar_chan_padded_t axi;
     axis_read_t_chan_padded_t axi_stream;
 } read_meta_channel_t;

 typedef struct packed {
     axi_aw_chan_t aw_chan;
     logic[max_width(axi_aw_chan_width, axis_t_chan_width)-axi_aw_chan_width:0] padding;
 } axi_write_aw_chan_padded_t;

 typedef struct packed {
     axis_t_chan_t t_chan;
     logic[max_width(axi_aw_chan_width, axis_t_chan_width)-axis_t_chan_width:0] padding;
 } axis_write_t_chan_padded_t;

 typedef union packed {
     axi_write_aw_chan_padded_t axi;
     axis_write_t_chan_padded_t axi_stream;
 } write_meta_channel_t;

 /// reg intf to idma ctrl intf
 eth_idma_reg_pkg::eth_idma_reg2hw_t reg2hw; // Write
 eth_idma_reg_pkg::eth_idma_hw2reg_t hw2reg; // Read

 eth_idma_reg_top #(
    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t),
    .AW(AW_REGBUS)
  ) i_regs (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .reg_req_i(reg_req_i),
    .reg_rsp_o(reg_rsp_o),
    .reg2hw(reg2hw), // Write
    .hw2reg(hw2reg), // Read
    .devmode_i(1'b1)
  );

  /// AXI Stream request and response
  axi_stream_rsp_t axis_read_req;
  axi_stream_req_t axis_read_rsp;

  axi_stream_req_t axis_write_req;
  axi_stream_rsp_t axis_write_rsp;
 
  assign hw2reg.rsp_valid.de = 1'b1;
  assign hw2reg.req_ready.de = 1'b1;

  idma_req_t idma_reg_req;
  idma_rsp_t idma_reg_rsp;

  assign idma_reg_req.length                     = reg2hw.length.q;
  assign idma_reg_req.src_addr                   = reg2hw.src_addr.q;
  assign idma_reg_req.dst_addr                   = reg2hw.dst_addr.q;

  assign idma_reg_req.opt.src_protocol           = idma_pkg::protocol_e'(reg2hw.src_protocol.q);
  assign idma_reg_req.opt.dst_protocol           = idma_pkg::protocol_e'(reg2hw.dst_protocol.q);
  
  assign idma_reg_req.opt.axi_id                 = reg2hw.axi_id.q;

  assign idma_reg_req.opt.src.burst              = reg2hw.opt_src.burst.q;
  assign idma_reg_req.opt.src.cache              = reg2hw.opt_src.cache.q;
  assign idma_reg_req.opt.src.lock               = reg2hw.opt_src.lock.q;
  assign idma_reg_req.opt.src.prot               = reg2hw.opt_src.prot.q;
  assign idma_reg_req.opt.src.qos                = reg2hw.opt_src.qos.q;
  assign idma_reg_req.opt.src.region             = reg2hw.opt_src.region.q;


  assign idma_reg_req.opt.dst.burst              = reg2hw.opt_dst.burst.q;
  assign idma_reg_req.opt.dst.cache              = reg2hw.opt_dst.cache.q;
  assign idma_reg_req.opt.dst.lock               = reg2hw.opt_dst.lock.q;
  assign idma_reg_req.opt.dst.prot               = reg2hw.opt_dst.prot.q;
  assign idma_reg_req.opt.dst.qos                = reg2hw.opt_dst.qos.q;
  assign idma_reg_req.opt.dst.region             = reg2hw.opt_dst.region.q;

  assign idma_reg_req.opt.beo.decouple_aw        = reg2hw.beo.decouple_aw.q;
  assign idma_reg_req.opt.beo.decouple_rw        = reg2hw.beo.decouple_rw.q;
  assign idma_reg_req.opt.beo.src_max_llen       = reg2hw.beo.src_max_llen.q;
  assign idma_reg_req.opt.beo.dst_max_llen       = reg2hw.beo.dst_max_llen.q;
  assign idma_reg_req.opt.beo.src_reduce_len     = reg2hw.beo.src_reduce_len.q;
  assign idma_reg_req.opt.beo.dst_reduce_len     = reg2hw.beo.dst_reduce_len.q;

  assign idma_reg_req.opt.last                   = reg2hw.last.q;

  // idma control signals
  assign idma_req_valid                        = reg2hw.req_valid.q;
  assign idma_rsp_ready                        = reg2hw.rsp_ready.q;



  eth_top #(
    .axi_stream_req_t   (  axi_stream_req_t  ),
    .axi_stream_rsp_t   (  axi_stream_rsp_t  ),
    .DataWidth          (  DataWidth         ), 
    .IdWidth            (  32'd0             ),
    .DestWidth          (  32'd0             ),
    .UserWidth          (  32'd1             ),
    .AW_REGBUS          (  AW_REGBUS         )
  ) i_eth_top (
    .rst_ni             (  rst_ni            ),
    .clk_i              (  eth_clk_i         ),
    .clk90_int          (  eth_clk90_i       ),
    .clk_200_int        (  eth_clk200M_i     ),

    // Ethernet: 1000BASE-T RGMII
    .phy_rx_clk         (  phy_rx_clk_i      ),
    .phy_rxd            (  phy_rxd_i         ),
    .phy_rx_ctl         (  phy_rx_ctl_i      ),
    .phy_tx_clk         (  phy_tx_clk_o      ),
    .phy_txd            (  phy_txd_o         ),
    .phy_tx_ctl         (  phy_tx_ctl_o      ),
    .phy_reset_n        (  phy_resetn_o      ),
    .phy_int_n          (  phy_intn_i        ),
    .phy_pme_n          (  phy_pme_i         ),
    .phy_mdio_i         (  phy_mdio_i        ),
    .phy_mdio_o         (  phy_mdio_o        ),
    .phy_mdio_oe        (  phy_mdio_oe       ),
    .phy_mdc            (  phy_mdc           ),
    
    // AXIS Interface 
    .tx_axis_req_i      (  axis_write_req    ), // set tuser to 1'b0 to indicate no error
    .tx_axis_rsp_o      (  axis_write_rsp    ),
    .rx_axis_req_o      (  axis_read_rsp     ),
    .rx_axis_rsp_i      (  axis_read_req     ),

    // REGBUS Configuration         
    .reg2hw_i          (  reg2hw             ),
    .hw2reg_o          (  hw2reg             )
  );

   idma_backend_rw_axi_rw_axis #(
    .DataWidth            ( DataWidth            ),
    .AddrWidth            ( AddrWidth            ),
    .AxiIdWidth           ( AxiIdWidth           ),
    .UserWidth            ( UserWidth            ),
    .TFLenWidth           ( TFLenWidth           ),
    .BufferDepth          ( BufferDepth          ),
    .NumAxInFlight        ( NumAxInFlight        ),
    .MemSysDepth          ( MemSysDepth          ),
    .RAWCouplingAvail     ( RAWCouplingAvail     ),
    .MaskInvalidData      ( MaskInvalidData      ),
    .HardwareLegalizer    ( HardwareLegalizer    ),
    .RejectZeroTransfers  ( RejectZeroTransfers  ),
    .ErrorCap             ( ErrorCap             ),
    .idma_req_t           ( idma_req_t           ), // regbus 
    .idma_rsp_t           ( idma_rsp_t           ),
    .idma_eh_req_t        ( idma_pkg::idma_eh_req_t   ),
    .idma_busy_t          ( idma_pkg::idma_busy_t     ),
    .axi_req_t            ( eth_idma_pkg::axi_req_t   ),
    .axi_rsp_t            (eth_idma_pkg::axi_rsp_t   ),
    .axis_read_req_t      ( axi_stream_rsp_t     ),
    .axis_read_rsp_t      ( axi_stream_req_t     ),
    .axis_write_req_t     ( axi_stream_req_t     ),
    .axis_write_rsp_t     ( axi_stream_rsp_t     ),
    /// Address Write Channel type
    .write_meta_channel_t ( write_meta_channel_t ),
    /// Address Read Channel type
    .read_meta_channel_t  ( read_meta_channel_t  )
) i_idma_backend (
    .clk_i                ( clk_i             ),
    .rst_ni               ( rst_ni            ),
    .testmode_i           ( testmode_i        ),
    .idma_req_i           ( idma_reg_req      ),
    .req_valid_i          ( idma_req_valid    ),
    .req_ready_o          ( hw2reg.req_ready.d    ),  
    .idma_rsp_o           ( idma_reg_rsp      ),
    .rsp_valid_o          ( hw2reg.rsp_valid.d  ),
    .rsp_ready_i          ( idma_rsp_ready  ),
    .idma_eh_req_i        ( idma_eh_req_i     ),
    .eh_req_valid_i       ( eh_req_valid_i    ),
    .eh_req_ready_o       ( eh_req_ready_o    ),

    /// AXI Interface
    .axi_write_req_o      ( axi_write_req_o    ),
    .axi_write_rsp_i      ( axi_write_rsp_i    ),
    .axi_read_req_o       ( axi_read_req_o     ),
    .axi_read_rsp_i       ( axi_read_rsp_i     ),

    /// AXIS Interface
    .axis_read_req_o      ( axis_read_req    ),
    .axis_read_rsp_i      ( axis_read_rsp    ), // with data
    .axis_write_req_o     ( axis_write_req   ), // wuth data
    .axis_write_rsp_i     ( axis_write_rsp   ),

    .busy_o               ( idma_busy_o      )
);

endmodule : eth_idma_wrap