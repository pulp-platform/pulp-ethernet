// RX frame queue for framing_top (phy_rx_clk domain).
// Lets up to MaxFrames received frames wait in the RX CDC FIFO for the RX
// DMA. A frame that starts while MaxFrames frames are already accepted is
// dropped whole.
module eth_rx_frame_queue #(
  parameter int unsigned MaxFrames = 32'd2,
  parameter int unsigned HoldOff   = 32'd16,
  parameter int unsigned LenWidth  = 32'd12
) (
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic                valid_i,
  input  logic                last_i,
  output logic                accept_o,
  input  logic                end_out_i,
  input  logic                done_i,
  output logic                complete_o,
  output logic [LenWidth-1:0] len_o,
  output logic                busy_o,
  output logic                drop_o
);

  localparam int unsigned PtrW = (MaxFrames > 1) ? $clog2(MaxFrames) : 1;
  localparam int unsigned CntW = $clog2(MaxFrames + 1);
  localparam int unsigned HoW  = $clog2(HoldOff + 1);

  logic                in_frame_q, drop_q;
  logic [CntW-1:0]     frames_q;
  logic [CntW-1:0]     waiting_q;
  logic [LenWidth-1:0] len_cnt_q, len_pend_q;
  logic [LenWidth-1:0] len_q [MaxFrames];
  logic [PtrW-1:0]     wr_ptr_q, rd_ptr_q;
  logic [HoW-1:0]      holdoff_q;
  logic                complete_q;

  logic start, room, push, pop;

  assign start    = valid_i & ~in_frame_q;
  assign room     = (frames_q < CntW'(MaxFrames));
  assign accept_o = valid_i & (start ? room : ~drop_q);
  assign push     = end_out_i;
  assign pop      = done_i & (waiting_q != '0);

  assign complete_o = complete_q;
  assign len_o      = len_q[rd_ptr_q];
  assign busy_o     = (frames_q != '0);
  assign drop_o     = start & ~room;

  function automatic logic [PtrW-1:0] inc(logic [PtrW-1:0] p);
    return (p == PtrW'(MaxFrames - 1)) ? '0 : p + 1'b1;
  endfunction

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      in_frame_q <= 1'b0;
      drop_q     <= 1'b0;
      frames_q   <= '0;
      waiting_q  <= '0;
      len_cnt_q  <= '0;
      len_pend_q <= '0;
      wr_ptr_q   <= '0;
      rd_ptr_q   <= '0;
      holdoff_q  <= '0;
      complete_q <= 1'b0;
      for (int i = 0; i < MaxFrames; i++) len_q[i] <= '0;
    end else begin
      // Frame boundaries; accept or drop is decided at the first byte
      if (valid_i) begin
        in_frame_q <= ~last_i;
        if (start) drop_q <= ~room;
      end

      // Length of the accepted frame (bytes)
      if (accept_o) begin
        if (last_i) begin
          len_pend_q <= len_cnt_q + 1'b1;
          len_cnt_q  <= '0;
        end else begin
          len_cnt_q  <= len_cnt_q + 1'b1;
        end
      end

      // Accepted frames not yet taken by the RX DMA
      case ({start & room, pop})
        2'b10:   frames_q <= frames_q + 1'b1;
        2'b01:   frames_q <= frames_q - 1'b1;
        default: ;
      endcase

      // Length queue
      if (push) begin
        len_q[wr_ptr_q] <= len_pend_q;
        wr_ptr_q        <= inc(wr_ptr_q);
      end
      if (pop) rd_ptr_q <= inc(rd_ptr_q);
      case ({push, pop})
        2'b10:   waiting_q <= waiting_q + 1'b1;
        2'b01:   waiting_q <= waiting_q - 1'b1;
        default: ;
      endcase

      // "Frame waiting" flag, low for HoldOff cycles after every pop
      if (pop)                   holdoff_q <= HoW'(HoldOff);
      else if (holdoff_q != '0)  holdoff_q <= holdoff_q - 1'b1;
      complete_q <= (waiting_q != '0) & (holdoff_q == '0) & ~pop;
    end
  end

endmodule : eth_rx_frame_queue