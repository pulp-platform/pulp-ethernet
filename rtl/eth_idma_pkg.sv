// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51


`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"
`include "axi/typedef.svh"
`include "idma/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

package eth_idma_pkg;
  
  /// Ethernet reg typedefs
  parameter  int AW_REGBUS           = 32;
  localparam int DW_REGBUS           = 32;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  typedef logic [AW_REGBUS-1:0]   reg_bus_addr_t;
  typedef logic [DW_REGBUS-1:0]   reg_bus_data_t;
  typedef logic [STRB_WIDTH-1:0]  reg_bus_strb_t;

  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)
   
  parameter int unsigned DataWidth           = 64;
  parameter int unsigned AddrWidth           = 64;
  parameter int unsigned UserWidth           = 1;
  parameter int unsigned AxiIdWidth          = 5;
  parameter int unsigned TFLenWidth          = 32;

  localparam int unsigned StrbWidth     = DataWidth / 8;
  localparam int unsigned OffsetWidth   = $clog2(StrbWidth);

  typedef logic [AddrWidth-1:0]   addr_t;
  typedef logic [AxiIdWidth-1:0]   id_t;
  typedef logic [UserWidth-1:0]   user_t;
  typedef logic [StrbWidth-1:0]   strb_t;
  typedef logic [DataWidth-1:0]   data_t;
  typedef logic [TFLenWidth-1:0]  tf_len_t;

 /// AXI4+ATOP typedefs
 `AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)
 `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, data_t, strb_t, user_t)
 `AXI_TYPEDEF_B_CHAN_T(axi_b_chan_t, id_t, user_t) 

 `AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
 `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, data_t, id_t, user_t) 

 `AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_chan_t, axi_w_chan_t, axi_ar_chan_t)
 `AXI_TYPEDEF_RESP_T(axi_rsp_t, axi_b_chan_t, axi_r_chan_t)

 /// AXI Stream typedefs
 `IDMA_AXI_STREAM_TYPEDEF_S_CHAN_T(axis_t_chan_t, data_t, strb_t, strb_t, id_t, id_t, user_t)
 `IDMA_AXI_STREAM_TYPEDEF_REQ_T(axi_stream_req_t, axis_t_chan_t)
 `IDMA_AXI_STREAM_TYPEDEF_RSP_T(axi_stream_rsp_t)

 /// Meta Channel Widths
 localparam int unsigned axi_aw_chan_width = axi_pkg::aw_width(AddrWidth, AxiIdWidth, UserWidth);
 localparam int unsigned axi_ar_chan_width = axi_pkg::ar_width(AddrWidth, AxiIdWidth, UserWidth); 
 localparam int unsigned axis_t_chan_width = $bits(axis_t_chan_t);
 
 `IDMA_TYPEDEF_OPTIONS_T(options_t, id_t)
 `IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, addr_t, options_t)
 `IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, addr_t)
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
    axis_read_t_chan_padded_t axis;
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
    axis_write_t_chan_padded_t axis;
} write_meta_channel_t;

endpackage : eth_idma_pkg
