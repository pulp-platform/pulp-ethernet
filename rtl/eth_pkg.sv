// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>

`include "axi/typedef.svh"
`include "axi_stream/typedef.svh"
`include "idma/typedef.svh"

package slv_pkg;

  // AXI parameters
  parameter int unsigned AddrWidth  = 48;
  parameter int unsigned DataWidth  = 32;
  parameter int unsigned AxiIdWidth = 6;
  parameter int unsigned UserWidth  = 1;

  // Regbus parameters
  parameter int unsigned RegAddrWidth = 32,
  parameter int unsigned RegDataWidth = 32,

  // AXI type dependent parameters; do not override!
  parameter type addr_t   = logic [AddrWidth-1:0];
  parameter type data_t   = logic [DataWidth-1:0];
  parameter type strb_t   = logic [DataWidth/8-1:0];
  parameter type id_t     = logic [AxiIdWidth-1:0];
  parameter type user_t   = logic [UserWidth-1:0];

  //  reg type dependent parameters; do not override!
  parameter type reg_addr_t   = logic [RegAddrWidth-1:0];
  parameter type reg_data_t   = logic [RegDataWidth-1:0];
  parameter type reg_strb_t   = logic [RegDataWidth/8-1:0];

  `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t)

  `REG_BUS_TYPEDEF_ALL(reg, reg_addr_t, reg_data_t, reg_strb_t);

endpackage
