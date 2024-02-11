// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

//
// Chaoqun Liang <chaoqun.liang@unibo.it>

module eth_clk_gen (
  input  logic ref_clk_i,
  input  logic rst_ni,
  output logic clk_eth_125_o,
  output logic clk_eth_125_90_o
);

logic clk_eth_125;
assign clk_eth_125 = clk_eth_125_o;

fll_dummy i_gf12_fll (         // Clock & reset
  .OUTCLK ( clk_eth_125_o  ), // FLL clock outputs
  .REFCLK ( ref_clk_i      ), // Reference clock input
  .RSTB   ( rst_ni         ), // Asynchronous reset (active low)
  .CFGREQ (                ), // CFG I/F access request (active high)
  .CFGACK (                ), // CFG I/F access granted (active high)
  .CFGAD  (                ), // CFG I/F address bus
  .CFGD   (                ), // CFG I/F input data bus (write)
  .CFGQ   (                ), // CFG I/F output data bus (read)
  .CFGWEB (                ), // CFG I/F write enable (active low)
  .PWD    ( 1'b0           ), // Asynchronous power down (active high)
  .RET    ( 1'b0           ), // Asynchronous retention/isolation control (active high)
  .TM     ( 1'b0           ), // Test mode (active high)
  .TE     ( 1'b0           ), // Scan enable (active high)
  .TD     ( '0             ), // Scan data input for chain 1:4
  .TQ     (                ), // Scan data output for chain 1:4
  .JTD    ( 1'b0           ), // Scan data in 5
  .JTQ    (                )  // Scan data out 5
);

clk_gen_hyper i_clk_gen_ethernet (
  .clk_i    ( clk_eth_125       ),
  .rst_ni   ( rst_ni            ),
  .clk0_o   (                   ),
  .clk90_o  ( clk_eth_125_90_o  ),
  .clk180_o (                   ),
  .clk270_o (                   )
);

endmodule : eth_clk_gen