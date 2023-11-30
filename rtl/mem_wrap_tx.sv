
module mem_wrap_tx
   (
    input logic        clkA,
    input logic        clkB,
    input logic        weB,
    input logic        enaA,
    input logic        enaB,
    input logic [10:0] addrA,
    input logic [8:0]  addrB,
    input logic [31:0] diB, // port B is write only

    output logic [7:0] doA // port A is read only
   );

   logic               cenB; //chip enable port B
   logic               cenA; //chip enable port A

   logic [31:0]        read_data;
   logic [10:0]        addrA_q, addrA_d;

   assign cenB = ~(weB & enaB); // enable write
   assign cenA = ~enaA;         // enable read

   always_comb begin
      addrA_q=addrA;
      if(enaA) begin
         case(addrA_d[1:0])
           0: doA=read_data[7:0];
           1: doA=read_data[15:8];
           2: doA=read_data[23:16];
           3: doA=read_data[31:24];
         endcase // case (addrA_d[1:0])
      end
   end

   always_ff @(posedge clkA) begin
      addrA_d<=addrA_q;
   end

   `ifdef TARGET_GF22

   IN22FDX_R2PV_WFVG_W00512B032M04C128 GF22_inst
     (
      .CLK_A(clkA),        // Clock Input for READ Port
      .CLK_B(clkB),        // Clock Input for WRITE Port
      .CEN_A(cenA),        // Port-A chip enable (active low)
      .CEN_B(cenB),        // Port-B chip enable (active low)
      .DEEPSLEEP(1'b0),
      .POWERGATE(1'b0),
      .AW_A(addrA[10:4]),  // [6:0] Port-A Address Word line inputs
      .AC_A(addrA[3:2]),   // [1:0] Port-A Address Column inputs
      .AW_B(addrB[8:2]),   // [6:0] Port-B Address Word line inputs
      .AC_B(addrB[1:0]),   // [1:0] Port-B Address Column inputs
      .D(diB),             // [31:0] Port-B Data Inputs during write operation
      .BW(32'hFFFFFFFF),   // [31:0] Port-B Bit Write Input to enable independent data bit write
      .T_LOGIC(1'b0),
      .MA_SAWL(1'b0),
      .MA_WL(1'b0),
      .MA_WRAS(1'b0),
      .MA_WRASD(1'b0),
      .MA_TPA(1'b0),
      .MA_TPB(1'b0),
      .RWE(),
      .RWFA(),
      .Q(read_data),       // [31:0] Port-A Data Output pins
      .OBSV_DBW(),
      .OBSV_CTL_A(),
      .OBSV_CTL_B()
      );

   `else
   simple_dual_two_clocks #(
      .NumWords   ( 2**9 ), // Number of Words in data array
      .DataWidth  ( 32 ), // Data signal width
      .ByteWidthA ( 10 ), // Width of a data byte
      .ByteWidthB ( 10 )  // Width of a data byte
   ) simple_inst
     (
      .clkA(clkA),
      .enaA(enaA),
      .weA(4'b0000),
      .addrA(addrA[10:2]),
      .dinA(32'h00000000),
      .doutA(read_data),
      .clkB(clkB),
      .enaB(enaB),
      .weB(4'b1111),
      .addrB(addrB[8:0]),
      .dinB(diB),
      .doutB()
      );
   `endif

endmodule // mem_wrap_tx
