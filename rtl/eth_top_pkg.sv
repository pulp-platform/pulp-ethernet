`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

package eth_top_pkg;

  parameter int unsigned DataWidth = 64;
  parameter int unsigned IdWidth = 0;
  parameter int unsigned DestWidth = 0;
  parameter int unsigned UserWidth = 1;

  // AXI stream channels typedefs
  typedef logic [DataWidth-1:0]   axis_tdata_t;
  typedef logic [DataWidth/8-1:0] axis_tstrb_t;
  typedef logic [DataWidth/8-1:0] axis_tkeep_t;
  typedef logic [IdWidth-1:0]     axis_tid_t;
  typedef logic [DestWidth-1:0]   axis_tdest_t;
  typedef logic [UserWidth-1:0]   axis_tuser_t;

  `AXI_STREAM_TYPEDEF_ALL(s, axis_tdata_t, axis_tstrb_t, axis_tkeep_t, axis_tid_t, axis_tdest_t, axis_tuser_t)


  parameter int AW_REGBUS = 4;
  localparam int DW_REGBUS = 32;
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  // Define structs for reg_bus
  typedef logic [AW_REGBUS-1:0] reg_bus_addr_t;
  typedef logic [DW_REGBUS-1:0] reg_bus_data_t;
  typedef logic [STRB_WIDTH-1:0] reg_bus_strb_t;
  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)

endpackage : eth_top_pkg
