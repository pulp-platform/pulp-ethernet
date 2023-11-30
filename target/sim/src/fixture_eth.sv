`timescale 1 ns/1 ps

`include "axi/assign.svh"

module fixture_eth();

   parameter AW = 32;  //Address width
   parameter DW = 64;  //Data width
   parameter IW = 8;   //ID width
   parameter UW = 8;   //User width

   typedef axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(IW), .UW(UW), .TA(200ps), .TT(700ps)) axi_drv_t;

   typedef logic [AW-1:0]   axi_addr_t;
   typedef logic [DW-1:0]   axi_data_t;
   typedef logic [DW/8-1:0] axi_strb_t;
   typedef logic [IW-1:0]   axi_id_t;

   //beats
   axi_test::axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) ar_beat = new();
   axi_test::axi_r_beat  #(.DW(DW), .IW(IW), .UW(UW)) r_beat  = new();
   axi_test::axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) aw_beat = new();
   axi_test::axi_w_beat  #(.DW(DW), .UW(UW))          w_beat  = new();
   axi_test::axi_b_beat  #(.IW(IW), .UW(UW))          b_beat  = new();


   // -------------------------- TB TASKS --------------------------

   // reset master ------------------------------------------------

   task reset_master;
      input axi_drv_t axi_master_drv;

      axi_master_drv.reset_master();

   endtask // reset_master


   // axi read task ------------------------------------------------

   task read_axi;
      input axi_drv_t axi_master_drv;
      input axi_addr_t raddr;

      ar_beat.ax_addr  = raddr;
      axi_master_drv.send_ar(ar_beat);
      axi_master_drv.recv_r(r_beat);
      $display("Read data: %x", r_beat.r_data);

   endtask // read_axi


   // axi write task ----------------------------------------------

   task write_axi;
      input axi_drv_t axi_master_drv;
      input axi_addr_t waddr;
      input axi_data_t wdata;
      input axi_strb_t wstrb;

      aw_beat.ax_addr  = waddr;
      w_beat.w_strb    = wstrb;
      w_beat.w_last    = 1'b1;
      w_beat.w_data    = wdata;

      axi_master_drv.send_aw(aw_beat);
      axi_master_drv.send_w(w_beat);
      $display("Written data: %x", w_beat.w_data);
      axi_master_drv.recv_b(b_beat);

   endtask; // write_axi


endmodule
