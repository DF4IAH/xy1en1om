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
    input                clk_100mhz,
    input                rstn_i,

    output               ready_o,
//  input       [ 31:0]  bitlen_i,
    input                start_i,
    input       [511:0]  vec_i,
    output               valid_o,
    output      [255:0]  hash_o
);

assign ready_o = 1'b0;
assign valid_o = 1'b0;
assign hash_o  = 256'b0;


endmodule
