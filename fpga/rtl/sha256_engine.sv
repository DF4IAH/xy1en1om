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
  input                clk_i               ,
  input                rstn_i              ,

  output reg           ready_o             ,
  input                start_i             ,

//input      [ 31: 0]  sha256_nonce_ofs_i  ,
//input      [ 31: 0]  sha256_bit_len_i    ,
//input                sha256_multihash_i  ,
  input                sha256_dbl_hash_i   ,

  input                fifo_empty_i        ,
  output reg           fifo_rd_en_o        ,
  input                fifo_rd_vld_i       ,
  input      [511: 0]  fifo_rd_dat_i       ,

  input                dma_in_progress_i   ,

  output reg           valid_o             ,
  output     [255: 0]  hash_o
);


parameter unsigned [31:0] K_ARRAY [63:0] = {                // set look-up constants
   32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
   32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
   32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
   32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
   32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
   32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
   32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
   32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
};

parameter unsigned [31:0] HA_ARRAY [7:0] = {                // preset hash table
   32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a, 32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
};


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


reg           [511:0]    fifo_rd_dat_r = 'b0;

reg  unsigned [ 31:0]    w [   64];                         //            64 regs - preparation
reg  unsigned [ 31:0]    ha[64* 8];                         // 64 steps x  8 regs - compression
//reg  unsigned [31:0]     a, b, c, d, e, f, g, h;
//reg                      sha256_dbl_hash_op  = 1'b0;

integer                  i;
integer                  s0, s1;
//integer                  S0, S1;
//integer                  ch, maj, temp1, temp2;

/*
assign s0 = rightrotate(w[loop - 15], 5'd7 ) ^ rightrotate(w[loop - 15], 5'd18) ^ rightshift(w[loop - 15], 5'd3 );
assign s1 = rightrotate(w[loop -  2], 5'd17) ^ rightrotate(w[loop -  2], 5'd19) ^ rightshift(w[loop -  2], 5'd10);

assign S1 = rightrotate(e, 5'd6) ^ rightrotate(e, 5'd11) ^ rightrotate(e, 5'd25);
assign ch = (e & f) ^ ((~e) & g);
assign temp1 = h + S1 + ch + k[loop] + w[loop];
assign S0 = rightrotate(a, 5'd2) ^ rightrotate(a, 5'd13) ^ rightrotate(a, 5'd22);
assign maj = (a & b) ^ (a & c) ^ (b & c);
assign temp2 = S0 + maj;

assign hash_o = { ha[0], ha[1], ha[2], ha[3], ha[4], ha[5], ha[6], ha[7] };

assign dbg_state_loop_o = { 4'b0, state[3:0],  loop[23:0]};
*/


// pop FIFO
always @(posedge clk_i)
if (!rstn_i)
   fifo_rd_en_o <= 1'b0;
else if (!fifo_empty_i)
   fifo_rd_en_o <= 1'b1;
else
   fifo_rd_en_o <= 1'b0;

// read FIFO
always @(posedge clk_i)
if (!rstn_i)
   fifo_rd_dat_r <= 512'b0;
else if (fifo_rd_vld_i)
   fifo_rd_dat_r <= fifo_rd_dat_i;


/*
   ready_o <= 1'b0;
   valid_o <= 1'b0;
*/


always @(posedge clk_i) begin
if (!rstn_i) begin
   for (i = 0; i < (24*64); i++)
      w[i] = 32'b0;
   end

else begin
   for (i = 0; i < 16; i = i + 1)                           // fill input array
      w[i] <= fifo_rd_dat_r[(15 - i)*32+:32];

   for (i = 16; i < 64; i = i + 2) begin
      assign s0 = rightrotate(w[i-15], 5'd7 ) ^ rightrotate(w[i-15], 5'd18) ^ rightshift(w[i-15], 5'd3 );
      assign s1 = rightrotate(w[i- 2], 5'd17) ^ rightrotate(w[i- 2], 5'd19) ^ rightshift(w[i- 2], 5'd10);
      w[i  ] <= w[i-16] + s0 + w[i-7] + s1;

      assign s0 = rightrotate(w[i-14], 5'd7 ) ^ rightrotate(w[i-14], 5'd18) ^ rightshift(w[i-14], 5'd3 );
      assign s1 = rightrotate(w[i- 2], 5'd17) ^ rightrotate(w[i- 2], 5'd19) ^ rightshift(w[i- 2], 5'd10);
      w[i+1] <= w[i-15] + s0 + w[i-6] + s1;
      end

/*
//   4'h2: if (loop < 63) begin                               // expand input array
         // assign s0 = rightrotate(w[loop - 15], 5'd7 ) ^ rightrotate(w[loop - 15], 5'd18) ^ rightshift(w[loop - 15], 5'd3 );
         // assign s1 = rightrotate(w[loop -  2], 5'd17) ^ rightrotate(w[loop -  2], 5'd19) ^ rightshift(w[loop -  2], 5'd10);

         w[loop] <= w[loop - 16] + s0 + w[loop - 7] + s1;

         loop <= loop + 1;
         end
      else begin
         w[loop] <= w[loop - 16] + s0 + w[loop - 7] + s1;

         a <= ha[0];
         b <= ha[1];
         c <= ha[2];
         d <= ha[3];
         e <= ha[4];
         f <= ha[5];
         g <= ha[6];
         h <= ha[7];

         loop <= 0;
         state <= 4'h3;
         end

//   4'h3: if (loop < 64) begin                               // hashing operation
         // assign S1 = rightrotate(e, 5'd6) ^ rightrotate(e, 5'd11) ^ rightrotate(e, 5'd25);
         // assign ch = (e & f) ^ ((~e) & g);
         // assign temp1 = h + S1 + ch + k[loop] + w[loop];
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

         loop <= loop + 1;
         end

      else begin
         if (!fifo_empty_i || dma_in_progress) begin        // continue with next frame
            if (!(|dbg_clock_continue_o))
               dbg_clock_continue_o <= masterclock_i;

            ha[0] <= ha[0] + a;
            ha[1] <= ha[1] + b;
            ha[2] <= ha[2] + c;
            ha[3] <= ha[3] + d;
            ha[4] <= ha[4] + e;
            ha[5] <= ha[5] + f;
            ha[6] <= ha[6] + g;
            ha[7] <= ha[7] + h;

            fifo_rd_en_o <= 1'b1;
            loop  <= 0;
            state <= 4'h1;
            end
         else begin
            if (sha256_dbl_hash_op) begin
               if (!(|dbg_clock_dblhash_o))
                  dbg_clock_dblhash_o <= masterclock_i;

               sha256_dbl_hash_op <= 1'b0;

               w[ 0] <= ha[0] + a;
               w[ 1] <= ha[1] + b;
               w[ 2] <= ha[2] + c;
               w[ 3] <= ha[3] + d;
               w[ 4] <= ha[4] + e;
               w[ 5] <= ha[5] + f;
               w[ 6] <= ha[6] + g;
               w[ 7] <= ha[7] + h;
               w[ 8] <= 32'h80000000;                       // final additional '1' bit
               w[ 9] <= 32'h00000000;
               w[10] <= 32'h00000000;
               w[11] <= 32'h00000000;
               w[12] <= 32'h00000000;
               w[13] <= 32'h00000000;
               w[14] <= 32'h00000000;
               w[15] <= 32'h00000100;                       // length of message

               ha[0] <= 32'h6a09e667;                       // preset hash table for a new run
               ha[1] <= 32'hbb67ae85;
               ha[2] <= 32'h3c6ef372;
               ha[3] <= 32'ha54ff53a;
               ha[4] <= 32'h510e527f;
               ha[5] <= 32'h9b05688c;
               ha[6] <= 32'h1f83d9ab;
               ha[7] <= 32'h5be0cd19;

               loop <= 16;
               state <= 4'h2;
               end
            else begin
               if (!(|dbg_clock_complete_o))
                  dbg_clock_complete_o <= masterclock_i;

               ha[0] <= ha[0] + a;
               ha[1] <= ha[1] + b;
               ha[2] <= ha[2] + c;
               ha[3] <= ha[3] + d;
               ha[4] <= ha[4] + e;
               ha[5] <= ha[5] + f;
               ha[6] <= ha[6] + g;
               ha[7] <= ha[7] + h;

               valid_o <= 1'b1;                             // job execution finished
               state <= 4'h4;
               end
            end
         end

//   4'h4: begin
         // regulary end state - trapped until reset line is pulled
         if (!(|dbg_clock_finish_o))
            dbg_clock_finish_o <= masterclock_i;
         end
*/

   end
end


endmodule: sha256_engine
