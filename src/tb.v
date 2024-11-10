/*
 * Copyright (c) 2024 Tommy Thorn
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`ifdef TEST
module tb;
   reg  [7:0] ui_in = 0;
   wire [7:0] uo_out;
   wire [7:0] uio_in;
   wire [7:0] uio_out;
   wire [7:0] uio_oe;
   wire	      ena;
   reg	      clk = 1;
   reg	      rst_n = 0;

   tt_um_tommythorn_cgates inst(ui_in, uo_out, uio_in, uio_out, uio_oe, ena, clk, rst_n);

   initial begin
      $monitor("%05d  %02x", $time, uo_out);
      #10 rst_n = 1;
      $display("Expect uo[1:0] to remain low");
      #10 ui_in[1] = 1;
      #10 ui_in[0] = 0;
      #10 ui_in[1] = 1;
      $display("Expect uo[1:0] to go high");
      #10 ui_in[0] = 1;
      #10 ui_in[1] = 0;
      $display("Expect uo[1:0] to go low");
      #10 ui_in[0] = 0;

      #1000 $finish;
   end
endmodule
`endif
