`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DF4IAH-Solutions
// Engineer: Ulrich Habel, DF4IAH
// 
// Create Date: 05.06.2016 23:42:32
// Design Name: SHA-256
// Module Name: sha256_engine
// Project Name: xy1en1om
// Target Devices: xc7z010clg400-1
// Tool Versions: Vivado 2015.4
// Description: SHA-256 engine does process input vector of 512 bit length until finalize is signalled.
//              The result is a 256 bit wide hash vector.
// 
// Dependencies: Hardware RedPitaya V1.1 board, Software RedPitaya image with uboot and Ubuntu partition
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sha256_engine #(
  // parameter none = 0  // hint
)(
   // clock & reset
    input                clk,
    input                rstn,

    output reg           ready_o,
//  input       [ 31:0]  bitlen_i,
    input                start_i,
    input                sha256_fifo_empty,
    output reg           fifo_rd_en,
    input                fifo_rd_vld,
    input       [ 31:0]  fifo_rd_dat,
    output reg           valid_o,
    output      [255:0]  hash_o,

    output      [ 31:0]  w_mon[63:0]
);


function [31:0] leftshift;
   input [31:0] v;
   input [ 5:0] r;
   leftshift = (v << r);
endfunction;

function [31:0] leftrotate;
   input [31:0] v;
   input [ 5:0] r;
   leftrotate = (v << r) | (v >> (32 - r));
endfunction;

function [31:0] rightshift;
   input [31:0] v;
   input [ 5:0] r;
   rightshift = (v >> r);
endfunction;

function [31:0] rightrotate;
   input [31:0] v;
   input [ 5:0] r;
   rightrotate = (v >> r) | (v << (32 - r));
endfunction;


reg  unsigned [31:0]     ha[7:0];
reg  unsigned [31:0]     k[63:0];
reg  unsigned [31:0]     w[63:0];
reg  unsigned [31:0]     a, b, c, d, e, f, g, h;
reg  unsigned [ 7:0]     state;

integer                  loop_i;
integer                  s0, s1, S0, S1;
integer                  ch, maj, temp1, temp2;

assign s0 = rightrotate(w[loop_i - 15], 5'd7 ) ^ rightrotate(w[loop_i - 15], 5'd18) ^ rightshift(w[loop_i - 15], 5'd3 );
assign s1 = rightrotate(w[loop_i -  2], 5'd17) ^ rightrotate(w[loop_i -  2], 5'd19) ^ rightshift(w[loop_i -  2], 5'd10);

assign S1 = rightrotate(e, 5'd6) ^ rightrotate(e, 5'd11) ^ rightrotate(e, 5'd25);
assign ch = (e & f) ^ ((~e) & g);
assign temp1 = h + S1 + ch + k[loop_i] + w[loop_i];
assign S0 = rightrotate(a, 5'd2) ^ rightrotate(a, 5'd13) ^ rightrotate(a, 5'd22);
assign maj = (a & b) ^ (a & c) ^ (b & c);
assign temp2 = S0 + maj;

assign hash_o = { ha[0], ha[1], ha[2], ha[3], ha[4], ha[5], ha[6], ha[7] };

assign w_mon = w;

always @(posedge clk) begin

if (!rstn) begin
   ha[0] <= 32'h6a09e667;
   ha[1] <= 32'hbb67ae85;
   ha[2] <= 32'h3c6ef372;
   ha[3] <= 32'ha54ff53a;
   ha[4] <= 32'h510e527f;
   ha[5] <= 32'h9b05688c;
   ha[6] <= 32'h1f83d9ab;
   ha[7] <= 32'h5be0cd19;

   k[ 0] <= 32'h428a2f98;
   k[ 1] <= 32'h71374491;
   k[ 2] <= 32'hb5c0fbcf;
   k[ 3] <= 32'he9b5dba5;
   k[ 4] <= 32'h3956c25b;
   k[ 5] <= 32'h59f111f1;
   k[ 6] <= 32'h923f82a4;
   k[ 7] <= 32'hab1c5ed5;
   k[ 8] <= 32'hd807aa98;
   k[ 9] <= 32'h12835b01;
   k[10] <= 32'h243185be;
   k[11] <= 32'h550c7dc3;
   k[12] <= 32'h72be5d74;
   k[13] <= 32'h80deb1fe;
   k[14] <= 32'h9bdc06a7;
   k[15] <= 32'hc19bf174;
   k[16] <= 32'he49b69c1;
   k[17] <= 32'hefbe4786;
   k[18] <= 32'h0fc19dc6;
   k[19] <= 32'h240ca1cc;
   k[20] <= 32'h2de92c6f;
   k[21] <= 32'h4a7484aa;
   k[22] <= 32'h5cb0a9dc;
   k[23] <= 32'h76f988da;
   k[24] <= 32'h983e5152;
   k[25] <= 32'ha831c66d;
   k[26] <= 32'hb00327c8;
   k[27] <= 32'hbf597fc7;
   k[28] <= 32'hc6e00bf3;
   k[29] <= 32'hd5a79147;
   k[30] <= 32'h06ca6351;
   k[31] <= 32'h14292967;
   k[32] <= 32'h27b70a85;
   k[33] <= 32'h2e1b2138;
   k[34] <= 32'h4d2c6dfc;
   k[35] <= 32'h53380d13;
   k[36] <= 32'h650a7354;
   k[37] <= 32'h766a0abb;
   k[38] <= 32'h81c2c92e;
   k[39] <= 32'h92722c85;
   k[40] <= 32'ha2bfe8a1;
   k[41] <= 32'ha81a664b;
   k[42] <= 32'hc24b8b70;
   k[43] <= 32'hc76c51a3;
   k[44] <= 32'hd192e819;
   k[45] <= 32'hd6990624;
   k[46] <= 32'hf40e3585;
   k[47] <= 32'h106aa070;
   k[48] <= 32'h19a4c116;
   k[49] <= 32'h1e376c08;
   k[50] <= 32'h2748774c;
   k[51] <= 32'h34b0bcb5;
   k[52] <= 32'h391c0cb3;
   k[53] <= 32'h4ed8aa4a;
   k[54] <= 32'h5b9cca4f;
   k[55] <= 32'h682e6ff3;
   k[56] <= 32'h748f82ee;
   k[57] <= 32'h78a5636f;
   k[58] <= 32'h84c87814;
   k[59] <= 32'h8cc70208;
   k[60] <= 32'h90befffa;
   k[61] <= 32'ha4506ceb;
   k[62] <= 32'hbef9a3f7;
   k[63] <= 32'hc67178f2;

   fifo_rd_en <= 1'b0;
   ready_o <= 1'b0;
   valid_o <= 1'b0;
   loop_i <= 0;
   state <= 'b0;
   end

else
   case (state)

   8'h00: if (!start_i) begin
         ready_o <= 1'b1;
         end
      else begin
         fifo_rd_en <= 1'b1;
         if (fifo_rd_vld) begin
            ready_o <= 1'b0;
            w[0] <= fifo_rd_dat;
            loop_i <= 1;
            state <= 8'h01;
            end
         end

   8'h01: begin
      if (fifo_rd_vld) begin
         w[loop_i] <= fifo_rd_dat;
         if (loop_i == 15) begin
            fifo_rd_en <= 1'b0;
            state <= 8'h02;
            end
         loop_i <= loop_i + 1;
         end
      end

   8'h02: if (loop_i < 63) begin
         // assign s0 = rightrotate(w[loop_i - 15], 5'd7 ) ^ rightrotate(w[loop_i - 15], 5'd18) ^ rightshift(w[loop_i - 15], 5'd3 );
         // assign s1 = rightrotate(w[loop_i -  2], 5'd17) ^ rightrotate(w[loop_i -  2], 5'd19) ^ rightshift(w[loop_i -  2], 5'd10);

         w[loop_i] <= w[loop_i - 16] + s0 + w[loop_i - 7] + s1;

         loop_i <= loop_i + 1;
         end
      else begin
         w[loop_i] <= w[loop_i - 16] + s0 + w[loop_i - 7] + s1;

         a <= ha[0];
         b <= ha[1];
         c <= ha[2];
         d <= ha[3];
         e <= ha[4];
         f <= ha[5];
         g <= ha[6];
         h <= ha[7];

         loop_i <= 0;
         state <= 8'h03;
         end

   8'h03: if (loop_i < 64) begin
         // assign S1 = rightrotate(e, 5'd6) ^ rightrotate(e, 5'd11) ^ rightrotate(e, 5'd25);
         // assign ch = (e & f) ^ ((~e) & g);
         // assign temp1 = h + S1 + ch + k[loop_i] + w[loop_i];
         // assign S0 = rightrotate(a, 5'd2) ^ rightrotate(a, 5'd13) ^ rightrotate(a, 5'd22);
         // assign maj = (a & b) ^ (a & c) ^ (b & c);
         // assign temp2 = S0 + maj;

         h <= g;
         g <= f;
         f <= e;
         e <= d + temp1;
         d <= c;
         c <= b;
         b <= a;
         a <= temp1 + temp2;

         loop_i <= loop_i + 1;
         end
      else begin
         ha[0] <= ha[0] + a;
         ha[1] <= ha[1] + b;
         ha[2] <= ha[2] + c;
         ha[3] <= ha[3] + d;
         ha[4] <= ha[4] + e;
         ha[5] <= ha[5] + f;
         ha[6] <= ha[6] + g;
         ha[7] <= ha[7] + h;

         ready_o <= 1'b1;
         if (sha256_fifo_empty)
            valid_o <= 1'b1;

         state <= 8'h00;
         end

   default: state <= 8'hFF;

   endcase
   end


endmodule
