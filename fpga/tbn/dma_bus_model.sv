`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DF4IAH-Solutions
// Engineer: Ulrich Habel, DF4IAH
// 
// Create Date: 21.08.2016 00:36:02
// Design Name: Testbench for SHA256 DMA access
// Module Name: dma_bus_model
// Project Name: xy1en1om
// Target Devices: xc7z010clg400-1
// Tool Versions: Vivado 2015.4
// Description: AXI client DMA bus access emulation
// 
// Dependencies: Hardware RedPitaya V1.1 board, Software RedPitaya image with uboot and Ubuntu partition
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dma_bus_model(
   // clock & reset
   input                 axi_clk_i      ,  // clock
   input                 axi_rstn_i     ,  // clock reset line - active low

   input      [   31: 0] axi_waddr_i    ,  // system write address
   input      [   63: 0] axi_wdata_i    ,  // system write data
   input      [    7: 0] axi_wsel_i     ,  // system write byte select
   input                 axi_wvalid_i   ,  // system write data valid
   input      [    3: 0] axi_wlen_i     ,  // system write burst length
   input                 axi_wfixed_i   ,  // system write burst type (fixed / incremental)
   output reg            axi_werr_o     ,  // system write error
   output reg            axi_wrdy_o     ,  // system write ready
   input      [   31: 0] axi_raddr_i    ,  // system read address
   input                 axi_rvalid_i   ,  // system read data valid
   input      [    7: 0] axi_rsel_i     ,  // system read byte select
   input      [    3: 0] axi_rlen_i     ,  // system read burst length
   input                 axi_rfixed_i   ,  // system read burst type (fixed / incremental)
   output reg [   63: 0] axi_rdata_o    ,  // system read data
   output reg            axi_rrdy_o     ,  // system read data is ready
   output reg            axi_rerr_o        // system read error
);


reg           [ 3:0]     state;


initial begin
   axi_werr_o  <=  1'b0;
   axi_wrdy_o  <=  1'b0;

   axi_rdata_o <= 64'b0;
   axi_rrdy_o  <=  1'b0;
   axi_rerr_o  <=  1'b0;
end


always @(posedge axi_clk_i) begin
if (!axi_rstn_i) begin
   axi_rdata_o <= 64'b0;
   axi_rrdy_o  <=  1'b0;
   axi_rerr_o  <=  1'b0;
   state <= 4'h0;
   end
else
   case (state)

   4'h0: if (axi_rvalid_i && (axi_rsel_i == 8'hFF) && (axi_rlen_i == 4'h1) && !axi_rfixed_i) begin
         case (axi_raddr_i)
            32'h10000000: begin
               axi_rdata_o <= 64'h81cd02ab_01000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000008: begin
               axi_rdata_o <= 64'hcd9317e2_7e569e8b;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000010: begin
               axi_rdata_o <= 64'h44d49ab2_fe99f2de;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000018: begin
               axi_rdata_o <= 64'ha3080000_b8851ba4;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000020: begin
               axi_rdata_o <= 64'he320b6c2_00000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000028: begin
               axi_rdata_o <= 64'h0423db8b_fffc8d75;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000030: begin
               axi_rdata_o <= 64'h710e951e_1eb942ae;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000038: begin
               axi_rdata_o <= 64'hfc8892b0_d797f7af;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000040: begin
               axi_rdata_o <= 64'hc7f5d74d_f1fc122b;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000048: begin
               axi_rdata_o <= 64'h42a14695_f2b9441a;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000050: begin
               axi_rdata_o <= 64'h00000000_80000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000058: begin
               axi_rdata_o <= 64'h00000000_00000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000060: begin
               axi_rdata_o <= 64'h00000000_00000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000068: begin
               axi_rdata_o <= 64'h00000000_00000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000070: begin
               axi_rdata_o <= 64'h00000000_00000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            32'h10000078: begin
               axi_rdata_o <= 64'h00000280_00000000;
               axi_rrdy_o  <=  1'b1;
               state <= 4'h1;
               end

            default: begin
               axi_rdata_o <= 64'hdeaddead_deaddead;
               axi_rrdy_o  <=  1'b0;
               axi_rerr_o  <=  1'b1;
               state <= 4'hF;
               end
         endcase
         end

   4'h1: if (!axi_rvalid_i) begin
         axi_rrdy_o <= 1'b0;
         state <= 4'h0;
         end

   default: state <= 4'hF;                                  // being trapped in case of an error

   endcase
   end


endmodule: dma_bus_model
