/*
 * Copyright (c) 2024 Tommy Thorn
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
   wire	Ql, Qc, R4l, R4c, R16l, R16c, RBigl, RBigc;

   latchcgate latchcgate_inst(rst_n, A, B, Ql);
   combcgate1 combcgate_inst(rst_n, A, B, Qc);

   latchring #(4) r4li(rst_n, R4l);
   combring  #(4) r4ci(rst_n, R4c);
   latchring #(16) r16li(rst_n, R16l);
   combring  #(16) r16ci(rst_n, R16c);
   latchring #(64) rtbdli(rst_n, RBigl);
   combring  #(64) rtbdci(rst_n, RBigc);

   // The Cgate rings pulses are very tiny, so we add a toggle FF for
   // each so be able to observe it.
   reg	R4lt, R4ct, R16lt, R16ct, RBiglt, RBigct;
   always @(posedge R4l or negedge rst_n) if (!rst_n) R4lt <= 0; else R4lt <= !R4lt;
   always @(posedge R4c or negedge rst_n) if (!rst_n) R4ct <= 0; else R4ct <= !R4ct;
   always @(posedge R16l or negedge rst_n) if (!rst_n) R16lt <= 0; else R16lt <= !R16lt;
   always @(posedge R16c or negedge rst_n) if (!rst_n) R16ct <= 0; else R16ct <= !R16ct;
   always @(posedge RBigl or negedge rst_n) if (!rst_n) RBiglt <= 0; else RBiglt <= !RBiglt;
   always @(posedge RBigc or negedge rst_n) if (!rst_n) RBigct <= 0; else RBigct <= !RBigct;

   assign uo_out = {RBigct, RBiglt, R16ct, R16lt, R4ct, R4lt, Qc, Ql};
endmodule

module latchcgate #(parameter q0 = 0) (input rst_n, input A, input B, output reg Q);
`ifdef TEST
   always @* if (!rst_n) Q = q0; else if (A == B) Q = #3 A;
`else
   always_latch if (!rst_n) Q = q0; else if (A == B) Q = A;
`endif
endmodule

module combcgate0(input rst_n, input A, input B, output wire Q);
`ifdef TEST
   reg Qr;
   assign Q = Qr;
   always @* Qr = #3 rst_n ? A & B | (A | B) & Qr : 0;
`else
   // (A & B | (A | B) & Q) & rst_n
   // ==
   // Q = (A1 | A2) & rst_n
   // A1 = A & B
   // A2 = (A | B) & Q

   wire A2;
   sky130_fd_sc_hd__o21a_1 i1(Q, A & B, A2, rst_n);
   sky130_fd_sc_hd__o21a_1 i2(A2, A, B, Q);
`endif
endmodule

module combcgate1(input rst_n, input A, input B, output wire Q);
`ifdef TEST
   reg Qr;
   assign Q = Qr;
   always @* Qr = #3 rst_n ? A & B | (A | B) & Qr : 0;
`else
   // A & B | (A | B) & Q | !rst_n
   // ==
   // Q = (A & B) | A1 | !rst_n
   // A1 = (A | B) & Q

   wire A1;
   sky130_fd_sc_hd__a211o_1 i1(Q, A, B, A1, !rst_n);
   sky130_fd_sc_hd__o21a_1 i2(A1, A, B, Q);
`endif
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
      if (i == 0)
	combcgate1 combcgate_inst(.rst_n(rst_n),
				   .A(o[(i + N - 1) % N]),
				   .B(!o[(i + 1) % N]),
				   .Q(o[i]));
      else
	combcgate0 combcgate_inst(.rst_n(rst_n),
				   .A(o[(i + N - 1) % N]),
				   .B(!o[(i + 1) % N]),
				   .Q(o[i]));
   end
endmodule
