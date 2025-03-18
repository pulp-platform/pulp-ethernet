// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chaoqun Liang <chaoqun.liang@unibo.it>

`include "axi/typedef.svh"
`include "register_interface/typedef.svh"
`include "idma/typedef.svh"

package eth_pkg;

  // AXI parameters
  parameter int unsigned AddrWidth  = 48;
  parameter int unsigned DataWidth  = 64;
  parameter int unsigned AxiIdWidth = 6;
  parameter int unsigned UserWidth  = 2;

  // Regbus parameters
  parameter int unsigned RegAddrWidth = 32;
  parameter int unsigned RegDataWidth = 32;

  // iDMA parameters
  parameter int unsigned NumAxInFlight    = 32'd16;
  parameter int unsigned BufferDepth      = 32'd3;
  parameter int unsigned TFLenWidth       = 32'd12;
  parameter int unsigned MemSysDepth      = 32'd0;
  parameter bit CombinedShifter           = 1'b1;
  parameter bit HardwareLegalizer         = 1'b1;
  parameter bit RejectZeroTransfers       = 1'b1;

  /// Ethernet internal FIFO confioguration
  parameter int unsigned TxFifoLogDepth   = 32'd2;
  parameter int unsigned RxFifoLogDepth   = 32'd4;

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

  `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t);

  `REG_BUS_TYPEDEF_ALL(reg, reg_addr_t, reg_data_t, reg_strb_t);

endpackage
