`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DF4IAH-Solutions
// Engineer: Ulrich Habel, DF4IAH
//
// Create Date: 29.05.2016 20:33:43
// Design Name: sha3
// Module Name: keccak_f1600_round
// Project Name: xy1en1om
// Target Devices: xc7z010clg400-1
// Tool Versions: Vivado 2015.4
// Description: SHA-3 implementation detail
//
// Dependencies: Hardware RedPitaya V1.1 board, Software RedPitaya image with uboot and Ubuntu partition
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module keccak_f1600_round(
  // global signals
  input                  clk             , // clock
  input                  rstn            , // clock reset - active low

  output reg             ready_o         , // 1: ready to fill and read out
  input      [63:0]      vec_i[25]       , // 1600 bit data input
  input                  start           , // 1: starting the function
  output reg [63:0]      vec_o[25]         // 1600 bit data output
);


//---------------------------------------------------------------------------------
//  Global

reg           [63:0]     a[25];            // internal work vector 'a'


//---------------------------------------------------------------------------------
//  FSM

reg           [ 3:0]     state;

// processor
always @(posedge clk)
if (!rstn) begin
  ready_o                                         <= 1'b0;
  vec_o                                           <= '{25{0}};
  state                                           <= 'b0;
  end

else begin
  case (state)

  /* control */
  4'h0: begin
    ready_o <= 1'b1;
    vec_o <= '{25{0}};
    if (start)
      state <= 4'h1;
    end

  4'h1: begin
    a <= vec_i;
    ready_o <= 1'b0;
    state <= 4'h2;
    end

  default:   begin
    ready_o <= 1'b0;
    vec_o <= '{25{0}};
    state <= 4'h0;
    end

  endcase
  end


endmodule
