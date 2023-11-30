
module dualmem_widen8(rst_int, clka, clkb, dina, dinb, addra, addrb, wea, web, douta, doutb, ena, enb);

   input wire rst_int, clka, clkb;
   input  [15:0] dina;
   input  [63:0] dinb;
   input  [12:0] addra;
   input  [10:0] addrb;
   input   [1:0]        wea;
   input   [1:0]        web;
   input   [0:0]        ena, enb;
   output [15:0]      douta;
   output [63:0]      doutb;

   genvar r;
   wire [63:0]        dout0;
   wire [255:0]       dout1;
   wire [7:0] 	      we0, we1, en0, en1;
   wire [63:0]        din0;
   wire [255:0]       din1;

   reg [12:0]       addra_dly;
   reg [10:0]       addrb_dly;

/*
`ifndef verilator
 `define RAMB16
`endif
*/

`ifdef GENESYSII
 `define RAMB16
`endif


   assign douta = dout0 >> {addra_dly[12:11],4'b0000};
   assign doutb = dout1 >> {addrb_dly[10:9],6'b000000};
   assign we0 = wea << {addra[12:11],1'b0};
   assign we1 = web << {addrb[10:9],1'b0};
   assign en0 = {ena,ena} << {addra[12:11],1'b0};
   assign en1 = {enb,enb} << {addrb[10:9],1'b0};
   assign din0 = {dina,dina,dina,dina};
   assign din1 = {dinb,dinb,dinb,dinb};

   always @(posedge clka or posedge rst_int) begin
        if (rst_int) begin
          addra_dly <= 'd0;
          addrb_dly <= 'd0;
        end else begin
          addra_dly <= addra;
          addrb_dly <= addrb;
        end
     end

`ifdef RAMB16
   //FPGA XILINX MEM

   generate for (r = 0; r < 8; r=r+1)
     RAMB16_S9_S36
     RAMB16_S9_S36_inst
       (
        .CLKA   ( clka                     ),     // Port A Clock
        .DOA    ( dout0[r*8 +: 8]          ),     // Port A 8-bit Data Output
        .DOPA   (                          ),
        .ADDRA  ( addra[10:0]              ),     // Port A 11-bit Address Input
        .DIA    ( din0[r*8 +: 8]           ),     // Port A 8-bit Data Input
        .DIPA   ( 1'b0                     ),
        .ENA    ( en0[r]                   ),     // Port A RAM Enable Input
        .SSRA   ( 1'b0                     ),     // Port A Synchronous Set/Reset Input
        .WEA    ( we0[r]                   ),     // Port A Write Enable Input
        .CLKB   ( clkb                     ),     // Port B Clock
        .DOB    ( dout1[r*32 +: 32]        ),     // Port B 32-bit Data Output
        .DOPB   (                          ),
        .ADDRB  ( addrb[8:0]               ),     // Port B 9-bit Address Input
        .DIB    ( din1[r*32 +: 32]         ),     // Port B 32-bit Data Input
        .DIPB   ( 4'b0                     ),
        .ENB    ( en1[r]                   ),     // Port B RAM Enable Input
        .SSRB   ( 1'b0                     ),     // Port B Synchronous Set/Reset Input
        .WEB    ( we1[r]                   )      // Port B Write Enable Input
        );
   endgenerate

`else // !`ifdef RAMB16

// `ifdef GF22_BEHAV
   // RAM BEHAVIOURAL GF22
   generate for (r = 0; r < 8; r=r+1)

   mem_wrap_rx mem_wrap_rx_inst
   (
    .clkA(clkb),
    .clkB(clka),
    .weB(we0[r]),
    .enaA(en1[r]),
    .enaB(en0[r]),
    .addrA(addrb[8:0]),//9 bit
    .addrB(addra[10:0]),
    .diB(din0[r*8 +: 8]), // port B is write only
    .doA(dout1[r*32 +: 32]) // port A is read only
   );

   endgenerate

// `elif
   // BEHAVIOURAL RAMB10 XILINX
  /* generate for (r = 0; r < 8; r=r+1)
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
        .doA    ( dout1[r*32 +: 32]        ),     // Port A 32-bit Data Output
        .addrA  ( addrb[8:0]               ),     // Port A 9-bit Address Input
        .diA    ( din1[r*32 +: 32]         ),     // Port A 32-bit Data Input
        .enaA   ( en1[r]                   ),     // Port A RAM Enable Input
        .weA    ( we1[r]                   ),     // Port A Write Enable Input
        .clkB   ( clka                     ),     // Port B Clock
        .doB    ( dout0[r*8 +: 8]          ),     // Port B 8-bit Data Output
        .addrB  ( addra[10:0]              ),     // Port B 11-bit Address Input
        .diB    ( din0[r*8 +: 8]           ),     // Port B 8-bit Data Input
        .enaB   ( en0[r]                   ),     // Port B RAM Enable Input
        .weB    ( we0[r]                   )      // Port B Write Enable Input
        );

   endgenerate*/

// `endif
`endif // !`ifdef RAMB16


endmodule // dualmem
