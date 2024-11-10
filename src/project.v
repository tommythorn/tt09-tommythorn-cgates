/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tommythorn_cgates (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

   wire	A = ui_in[0];
   wire	B = ui_in[1];
   wire	Ql, Qc, R4l, R4c, R16l, R16c, RTBDl, RTBDc;

   assign uo_out = {RTBDc, RTBDl, R16c, R16l, R4c, R4l, Qc, Ql};
   latchcgate latchcgate_inst(rst_n, A, B, Ql);
   combcgate combcgate_inst(rst_n, A, B, Qc);

   latchring #(4) r4li(rst_n, R4l);
   combring  #(4) r4ci(rst_n, R4c);
   latchring #(16) r16li(rst_n, R16l);
   combring  #(16) r16ci(rst_n, R16c);
   latchring #(16) rtbdli(rst_n, RTBDl);
   combring  #(16) rtbdci(rst_n, RTBDc);
endmodule

module latchcgate #(parameter q0 = 0) (input rst_n, input A, input B, output reg Q);
   always @* if (!rst_n) Q = q0; else if (A == B) Q = #3 A;
endmodule

module combcgate #(parameter q0 = 0) (input rst_n, input A, input B, output reg Q);
   always @* Q = #3 rst_n ? A & B | (A | B) & Q : q0;
endmodule

module latchring #(parameter N = 3) (input rst_n, output Q);
   wire [N-1:0] o;
   assign Q = o[0];
   genvar	i;
   for (i = 0; i < N; i = i + 1) begin
      latchcgate #(i == 0) latchcgate_inst(.rst_n(rst_n),
				   .A(o[(i + N - 1) % N]),
				   .B(!o[(i + 1) % N]),
				   .Q(o[i]));
   end
endmodule

module combring#(parameter N = 3) (input rst_n, output Q);
   wire [N-1:0] o;
   assign Q = o[0];
   genvar	i;
   for (i = 0; i < N; i = i + 1) begin
      latchcgate #(i == 0) combcgate_inst(.rst_n(rst_n),
				  .A(o[(i + N - 1) % N]),
				  .B(!o[(i + 1) % N]),
				  .Q(o[i]));
   end
endmodule

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
