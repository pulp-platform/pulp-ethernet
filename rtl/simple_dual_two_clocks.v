module simple_dual_two_clocks
#(
  parameter int unsigned NumWords     = 32'd1024, // Number of Words in data array
  parameter int unsigned DataWidth    = 32'd128,  // Data signal width
  parameter int unsigned ByteWidthA   = 32'd8,    // Width of a data byte
  parameter int unsigned ByteWidthB   = 32'd8,    // Width of a data byte
  // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
  parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned BeWidthA  = (DataWidth + ByteWidthA - 32'd1) / ByteWidthA, // ceil_div
  parameter int unsigned BeWidthB  = (DataWidth + ByteWidthB - 32'd1) / ByteWidthB  // ceil_div
)
(
input clkA,
input enaA,
input [BeWidthA-1:0] weA,
input [AddrWidth-1:0] addrA,
input [DataWidth-1:0] dinA,
output reg [DataWidth-1:0] doutA,
input clkB,
input enaB,
input [BeWidthB-1:0] weB,
input [AddrWidth-1:0] addrB,
input [DataWidth-1:0] dinB,
output reg [DataWidth-1:0] doutB
);
// Core Memory
reg [DataWidth-1:0] ram_block [NumWords-1:0];
integer i;

// Port-A Operation
always @ (posedge clkA) begin
   if(enaA) begin
      for(i=0;i<BeWidthA;i=i+1) begin
         if(weA[i]) begin
            ram_block[addrA][i*ByteWidthA +: ByteWidthA] <= dinA[i*ByteWidthA +: ByteWidthA];
         end
      end
      doutA <= ram_block[addrA];
   end
end

// Port-B Operation:
always @ (posedge clkB) begin
   if(enaB) begin
      for(i=0;i<BeWidthB;i=i+1) begin
         if(weB[i]) begin
            ram_block[addrB][i*ByteWidthB +: ByteWidthB] <= dinB[i*ByteWidthB +: ByteWidthB];
         end
      end
      doutB <= ram_block[addrB];
   end
end

endmodule // bytewrite_tdp_ram_rf
