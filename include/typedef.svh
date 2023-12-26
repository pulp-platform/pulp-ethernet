// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51


// Macros to define ethernet and iDMA structs

`ifndef ETH_IDMA_TYPEDEF_SVH_
`define ETH_IDMA_TYPEDEF_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// Register Request and Response Structs
//
// Usage Example:
// `IDMA_TYPEDEF_OPTIONS_T(options_t, axi_id_t)
// `IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, axi_addr_t)
// `IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, axi_addr_t, options_t)
// `IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)
`define IDMA_TYPEDEF_OPTIONS_T(options_t, axi_id_t)                      \
    typedef struct packed {                                              \
        idma_pkg::protocol_e        src_protocol;                        \
        idma_pkg::protocol_e        dst_protocol;                        \
        axi_id_t                    axi_id;                              \
        idma_pkg::axi_options_t     src;                                 \
        idma_pkg::axi_options_t     dst;                                 \
        idma_pkg::backend_options_t beo;                                 \
        logic                       last;                                \
    } options_t;
`define IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, axi_addr_t)            \
    typedef struct packed {                                              \
        axi_pkg::resp_t      cause;                                      \
        idma_pkg::err_type_t err_type;                                   \
        axi_addr_t           burst_addr;                                 \
    } err_payload_t;
`define IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, axi_addr_t, options_t)  \
    typedef struct packed {                                              \
        tf_len_t   length;                                               \
        axi_addr_t src_addr;                                             \
        axi_addr_t dst_addr;                                             \
        options_t  opt;                                                  \
    } idma_req_t;
`define IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)                    \
    typedef struct packed {                                              \
        logic         last;                                              \
        logic         error;                                             \
        err_payload_t pld;                                               \
    } idma_rsp_t;

      /// reg typedefs
  parameter  int AW_REGBUS           = 8;
  localparam int DW_REGBUS           = 64;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  typedef logic [AW_REGBUS-1:0]   reg_bus_addr_t;
  typedef logic [DW_REGBUS-1:0]   reg_bus_data_t;
  typedef logic [STRB_WIDTH-1:0]  reg_bus_strb_t;

  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// iDMA Full Request and Response Structs
//
// Usage Example:
// `IDMA_TYPEDEF_FULL_REQ_T(idma_req_t, axi_id_t, axi_addr_t, tf_len_t)
// `IDMA_TYPEDEF_FULL_RSP_T(idma_rsp_t, axi_addr_t)
`define IDMA_TYPEDEF_FULL_REQ_T(idma_req_t, axi_id_t, axi_addr_t, tf_len_t) \
    `IDMA_TYPEDEF_OPTIONS_T(options_t, axi_id_t)                            \
    `IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, axi_addr_t, options_t)
`define IDMA_TYPEDEF_FULL_RSP_T(idma_rsp_t, axi_addr_t)                     \
    `IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, axi_addr_t)                  \
    `IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// iDMA n-dimensional Request Struct
//
// Usage Example:
// `IDMA_TYPEDEF_D_REQ_T(idma_d_req_t, reps_t, strides_t)
// `IDMA_TYPEDEF_ND_REQ_T(idma_nd_req_t, idma_req_t, idma_d_req_t)
`define IDMA_TYPEDEF_D_REQ_T(idma_d_req_t, reps_t, strides_t)            \
    typedef struct packed {                                              \
        reps_t    reps;                                                  \
        strides_t src_strides;                                           \
        strides_t dst_strides;                                           \
    } idma_d_req_t;
`define IDMA_TYPEDEF_ND_REQ_T(idma_nd_req_t, idma_req_t, idma_d_req_t)   \
    typedef struct packed {                                              \
        idma_req_t                burst_req;                             \
        idma_d_req_t [NumDim-2:0] d_req;                                 \
    } idma_nd_req_t;
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// iDMA Full n-dimensional Request Struct
//
// Usage Example:
// `IDMA_TYPEDEF_FULL_ND_REQ_T(idma_nd_req_t, idma_req_t, reps_t, strides_t)
`define IDMA_TYPEDEF_FULL_ND_REQ_T(idma_nd_req_t, idma_req_t, reps_t, strides_t) \
    `IDMA_TYPEDEF_D_REQ_T(idma_d_req_t, reps_t, strides_t)                       \
    `IDMA_TYPEDEF_ND_REQ_T(idma_nd_req_t, idma_req_t, idma_d_req_t)
////////////////////////////////////////////////////////////////////////////////////////////////////


`define IDMA_AXI_STREAM_TYPEDEF_S_CHAN_T(s_chan_t, tdata_t, tstrb_t, tkeep_t, tid_t, tdest_t, tuser_t) \
  typedef struct packed {                                                                         \
    tdata_t data;                                                                                 \
    tstrb_t strb;                                                                                 \
    tkeep_t keep;                                                                                 \
    logic   last;                                                                                 \
    tid_t   id;                                                                                   \
    tdest_t dest;                                                                                 \
    tuser_t user;                                                                                 \
  } s_chan_t;

`define IDMA_AXI_STREAM_TYPEDEF_REQ_T(req_stream_t, s_chan_t) \
  typedef struct packed {                                \
    s_chan_t            t;                               \
    logic               tvalid;                          \
  } req_stream_t;

`define IDMA_AXI_STREAM_TYPEDEF_RSP_T(rsp_stream_t) \
  typedef struct packed {                      \
    logic                tready;               \
  } rsp_stream_t;

`endif
