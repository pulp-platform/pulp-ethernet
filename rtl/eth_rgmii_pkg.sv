package eth_rgmii_pkg;

  parameter int unsigned AXI_ADDR_WIDTH = 32;
  parameter int unsigned AXI_DATA_WIDTH = 64;
  parameter int unsigned AXI_ID_WIDTH   = 8;
  parameter int unsigned AXI_USER_WIDTH = 8;

  localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

  typedef logic [AXI_ID_WIDTH-1:0]   id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] data_t;
  typedef logic [AXI_STRB_WIDTH-1:0] strb_t;
  typedef logic [AXI_USER_WIDTH-1:0] user_t;

endpackage : eth_rgmii_pkg
