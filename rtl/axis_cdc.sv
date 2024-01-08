module axis_cdc #(
  parameter int unsigned  FIFODepth  = 4,
  parameter int unsigned  DataWidth  = 64,
  parameter int unsigned  IdWidth    = 5,
  parameter int unsigned  UserWidth  = 1,
  parameter int unsigned  DestWidth = 5
)(
 // FIFO IN
 input logic clk_src_i,
 input logic rstn_src_i,
 input logic [DataWidth-1 : 0] tdata_i,
 input logic [DataWidth/8-1:0] tstrb_i,
 input logic [DataWidth/8-1:0] tkeep_i,
 input logic tlast_i,
 input logic [IdWidth-1:0]     tid_i,
 input logic [DestWidth-1:0]   tdest_i,
 input logic tuser_i,
 input logic tvalid_i,
 output logic tready_o,
 
 // FIFO OUT
 input logic  clk_dst_i,
 input logic  rstn_dst_i,
 output logic [DataWidth-1 : 0] tdata_o,
 output logic [DataWidth/8-1:0] tstrb_o,
 output logic [DataWidth/8-1:0] tkeep_o,
 output logic tlast_o,
 output logic [IdWidth-1:0]     tid_o,
 output logic [DestWidth-1:0]   tdest_o,
 output logic tuser_o,
 output logic tvalid_o,
 input  logic tready_i
);


logic [$clog2(FIFODepth)-1:0] wr_ptr;
logic [$clog2(FIFODepth)-1:0] rd_ptr;
logic [$clog2(FIFODepth):0] write_count, read_count;

logic [DataWidth-1:0] fifo_tdata [0:FIFODepth-1]; // index up
logic [DataWidth/8-1:0] fifo_tstrb [0:FIFODepth-1];
logic [DataWidth/8-1:0] fifo_tkeep [0:FIFODepth-1];
logic fifo_tlast [0:FIFODepth-1];
logic [IdWidth-1:0] fifo_tid   [0:FIFODepth-1];
logic [DestWidth-1:0] fifo_tdest [0:FIFODepth-1];
logic fifo_tuser [0:FIFODepth-1];

// write
always_ff @(posedge clk_src_i or negedge rstn_src_i) begin
  if(!rstn_src_i) begin
    wr_ptr <= 0;
    write_count  <= 0;
    tready_o <= 1; // fifo empty, ready to accept
  end else begin
    tready_o <= (write_count - read_count < FIFODepth); // not full 

    if( tready_o && tvalid_i) begin
      fifo_tdata[wr_ptr] <= tdata_i;
      fifo_tstrb[wr_ptr] <= tstrb_i;
      fifo_tkeep[wr_ptr] <= tkeep_i;
      fifo_tlast[wr_ptr] <= tlast_i;
      fifo_tid[wr_ptr]   <= tid_i;
      fifo_tdest[wr_ptr] <= tdest_i;
      fifo_tuser[wr_ptr] <= tuser_i;
      
      wr_ptr <= (wr_ptr + 1) % FIFODepth;
      write_count  <= write_count + 1;
      
    end
  end
end
//read 
always_ff @(posedge clk_dst_i or negedge rstn_dst_i) begin 
  if(!rstn_dst_i) begin
    rd_ptr <= 0;
    read_count  <= 0;
    tvalid_o <= 0;
  end else begin
    if(read_count < write_count) begin
      tvalid_o <= 1;
      if(tready_i) begin
        tdata_o <= fifo_tdata[rd_ptr];
        tstrb_o <= fifo_tstrb[rd_ptr];
        tkeep_o <= fifo_tkeep[rd_ptr];
        tlast_o <= fifo_tlast[rd_ptr];
        tid_o   <=  fifo_tid[rd_ptr];
        tdest_o <=  fifo_tdest[rd_ptr];
        tuser_o <=  fifo_tuser[rd_ptr];
      
        rd_ptr <= (rd_ptr + 1) % FIFODepth;
        read_count  <= read_count + 1;  
      end
    end else begin 
       tvalid_o <= 0;
    end 
end

end

endmodule


// module axis_cdc #(
//     parameter int unsigned FIFODepth = 4,
//     parameter int unsigned DataWidth = 64,
//     parameter int unsigned IdWidth = 5,
//     parameter int unsigned UserWidth = 1,
//     parameter int unsigned DestWidth = 5
// )(
//     // FIFO IN
//     input logic clk_src_i,
//     input logic rstn_i,
//     input logic [DataWidth-1 : 0] tdata_i,
//     input logic [DataWidth/8-1:0] tstrb_i,
//     input logic [DataWidth/8-1:0] tkeep_i,
//     input logic tlast_i,
//     input logic [IdWidth-1:0] tid_i,
//     input logic [DestWidth-1:0] tdest_i,
//     input logic tuser_i,
//     input logic tvalid_i,
//     output logic tready_o,
     
//     // FIFO OUT
//     input logic clk_dst_i,
//     output logic [DataWidth-1 : 0] tdata_o,
//     output logic [DataWidth/8-1:0] tstrb_o,
//     output logic [DataWidth/8-1:0] tkeep_o,
//     output logic tlast_o,
//     output logic [IdWidth-1:0] tid_o,
//     output logic [DestWidth-1:0] tdest_o,
//     output logic tuser_o,
//     output logic tvalid_o,
//     input logic tready_i
// );

//     // Internal FIFO storage
//     logic [DataWidth-1:0] fifo_tdata [0:FIFODepth-1];
//     logic [DataWidth/8-1:0] fifo_tstrb [0:FIFODepth-1];
//     logic [DataWidth/8-1:0] fifo_tkeep [0:FIFODepth-1];
//     logic fifo_tlast [0:FIFODepth-1];
//     logic [IdWidth-1:0] fifo_tid [0:FIFODepth-1];
//     logic [DestWidth-1:0] fifo_tdest [0:FIFODepth-1];
//     logic fifo_tuser [0:FIFODepth-1];

//     // Pointers
//     logic [$clog2(FIFODepth)-1:0] wr_ptr, rd_ptr;
//     logic [$clog2(FIFODepth):0] count;

//     // Full and Empty flags
//     logic full, empty;

//     // Write logic in source domain
//     always_ff @(posedge clk_src_i or negedge rstn_i) begin
//         if (!rstn_i) begin
//             wr_ptr <= 0;
//             count <= 0;
//             full <= 0;
//         end else begin
//             if (tvalid_i && !full) begin
//                 fifo_tdata[wr_ptr] <= tdata_i;
//                 fifo_tstrb[wr_ptr] <= tstrb_i;
//                 fifo_tkeep[wr_ptr] <= tkeep_i;
//                 fifo_tlast[wr_ptr] <= tlast_i;
//                 fifo_tid[wr_ptr]   <= tid_i;
//                 fifo_tdest[wr_ptr] <= tdest_i;
//                 fifo_tuser[wr_ptr] <= tuser_i;
//                 wr_ptr <= (wr_ptr + 1) % FIFODepth;
//                 count <= count + 1;
//                 full <= (count + 1 == FIFODepth);
//             end
//         end
//     end

//     // Read logic in destination domain
//     always_ff @(posedge clk_dst_i or negedge rstn_i) begin
//         if (!rstn_i) begin
//             rd_ptr <= 0;
//             empty <= 1;
//         end else begin
//             if (tready_i && !empty) begin
//                 tdata_o <= fifo_tdata[rd_ptr];
//                 tstrb_o <= fifo_tstrb[rd_ptr];
//                 tkeep_o <= fifo_tkeep[rd_ptr];
//                 tlast_o <= fifo_tlast[rd_ptr];
//                 tid_o   <= fifo_tid[rd_ptr];
//                 tdest_o <= fifo_tdest[rd_ptr];
//                 tuser_o <= fifo_tuser[rd_ptr];
//                 rd_ptr <= (rd_ptr + 1) % FIFODepth;
//                 count <= count - 1;
//                 empty <= (count == 0); // Will be empty after this read
//             end
//         end
//     end

//     // Generate tready_o and tvalid_o signals
//     assign tready_o = !full;
//     //assign tvalid_o = !empty && (rd_ptr != wr_ptr);
//     assign tvalid_o = !empty;

// endmodule
