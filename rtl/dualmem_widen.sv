
module dualmem_widen(clka, clkb, dina, dinb, addra, addrb, wea, web, douta, doutb, ena, enb);

   input wire clka, clkb;
   input  [15:0] dina;
   input  [63:0] dinb;
   input  [10:0] addra;
   input   [8:0] addrb;
   input   [1:0]        wea;
   input   [1:0]        web;
   input   [0:0]        ena, enb;
   output [15:0]      douta;
   output [63:0]      doutb;

   genvar r;
   wire [47:0]        dout;

/*
`ifndef verilator
 `define RAMB16
`endif
*/

`ifdef GENESYSII
 `define RAMB16
`endif

`ifdef RAMB16
   //FPGA XILINX MEM
   generate for (r = 0; r < 2; r=r+1)
     RAMB16_S9_S36
     RAMB16_S9_S36_inst
       (
        .CLKA   ( clka                     ),     // Port A Clock
        .DOA    ( douta[r*8 +: 8]          ),     // Port A 8-bit Data Output
        .DOPA   (                          ),
        .ADDRA  ( addra                    ),     // Port A 14-bit Address Input
        .DIA    ( dina[r*8 +: 8]           ),     // Port A 1-bit Data Input
        .DIPA   ( 1'b0                     ),
        .ENA    ( ena                      ),     // Port A RAM Enable Input
        .SSRA   ( 1'b0                     ),     // Port A Synchronous Set/Reset Input
        .WEA    ( wea[r]                   ),     // Port A Write Enable Input
        .CLKB   ( clkb                     ),     // Port B Clock
        .DOB    ( doutb[r*32 +: 32]        ),     // Port B 1-bit Data Output
        .DOPB   (                          ),
        .ADDRB  ( addrb                    ),     // Port B 14-bit Address Input
        .DIB    ( dinb[r*32 +: 32]         ),     // Port B 1-bit Data Input
        .DIPB   ( 4'b0                     ),
        .ENB    ( enb                      ),     // Port B RAM Enable Input
        .SSRB   ( 1'b0                     ),     // Port B Synchronous Set/Reset Input
        .WEB    ( web[r]                   )      // Port B Write Enable Input
        );
   endgenerate

`else // !`ifdef RAMB16

 //`ifdef GF22_BEHAV
   // RAM BEHAVIOURAL GF22

    generate for (r = 0; r < 2; r=r+1)

        mem_wrap_tx mem_wrap_tx_inst
          (
           .clkA  ( clka             ),
           .clkB  ( clkb             ),
           .weB   ( web[r]           ),
           .enaA  ( ena              ),
           .enaB  ( enb              ),
           .addrA ( addra            ),
           .addrB ( addrb            ),
           .diB   ( dinb[r*32 +: 32] ), // port B is write only
           .doA   ( douta[r*8 +: 8]  )  // port A is read only
           );

     endgenerate

 //`elif
     // BEHAVIOURAL RAMB16 XILINX
  /* generate for (r = 0; r < 2; r=r+1)

     asym_ram_tdp_read_first
       #(
   .WIDTHA(32),
   .SIZEA(512),
   .ADDRWIDTHA(9),
   .WIDTHB(8),
   .SIZEB(2048),
   .ADDRWIDTHB(11)
   )
     asym_ram_tdp_read_first_inst
       (
        .clkA   ( clkb                     ),     // Port A Clock
        .doA    ( doutb[r*32 +: 32]        ),     // Port A 32-bit Data Output
        .addrA  ( addrb                    ),     // Port A 9-bit Address Input
        .diA    ( dinb[r*32 +: 32]         ),     // Port A 32-bit Data Input
        .enaA   ( enb                      ),     // Port A RAM Enable Input
        .weA    ( web[r]                   ),     // Port A Write Enable Input
        .clkB   ( clka                     ),     // Port B Clock
        .doB    ( douta[r*8 +: 8]          ),     // Port B 8-bit Data Output
        .addrB  ( addra                    ),     // Port B 11-bit Address Input
        .diB    ( dina[r*8 +: 8]           ),     // Port B 8-bit Data Input
        .enaB   ( ena                      ),     // Port B RAM Enable Input
        .weB    ( wea[r]                   )      // Port B Write Enable Input
        );

   endgenerate*/

// `endif //  `ifdef GF22_BEHAV

`endif // !`ifdef RAMB16


endmodule // dualmem
