`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DF4IAH-Solutions
// Engineer: Ulrich Habel, DF4IAH
// 
// Create Date: 05.06.2016 23:42:32
// Design Name: DMA engine 
// Module Name: dma_engine
// Project Name: xy1en1om
// Target Devices: xc7z010clg400-1
// Tool Versions: Vivado 2015.4
// Description: Engine to drive data via direct memory access.
// 
// Dependencies: Hardware RedPitaya V1.1 board, Software RedPitaya image with uboot and Ubuntu partition
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dma_engine #(
  // parameter none = 0  // hint
)(
   // clock & reset
    input                clk_i,
    input                rstn_i,

    input                dma_enable_i,
    input       [ 31:0]  dma_base_addr_i,
    input       [ 31:0]  dma_bit_len_i,
    input                dma_start_i,

    input                sha256_rdy_i,

    output               axi_clk_o,
    output               axi_rstn_o,
    output      [ 31:0]  axi_waddr_o,
    output      [ 63:0]  axi_wdata_o,
    output      [  7:0]  axi_wsel_o,
    output               axi_wvalid_o,
    output      [  3:0]  axi_wlen_o,
    output               axi_wfixed_o,
    input                axi_werr_i,
    input                axi_wrdy_i,
    output reg  [ 31:0]  axi_raddr_o,
    output reg           axi_rvalid_o,
    output reg  [  7:0]  axi_rsel_o,
    output reg  [  3:0]  axi_rlen_o,
    output reg           axi_rfixed_o,
    input    [   63: 0]  axi_rdata_i,
    input                axi_rrdy_i,
    input                axi_rerr_i,

    output reg           fifo_wr_en_o,
    output reg  [ 31:0]  fifo_wr_in_o,
    input       [  8:0]  fifo_wr_count_i
);


reg  unsigned [31:0]     ofs_addr;
reg  unsigned [31:0]     rd_len;
reg                      upper;
reg           [ 3:0]     state;

integer                  loop;


// AXI master system write bus not used
assign axi_clk_o    = clk_i;
assign axi_rstn_o   = rstn_i;
assign axi_waddr_o  = 32'b0;
assign axi_wdata_o  = 64'b0;
assign axi_wsel_o   =  8'b0;
assign axi_wvalid_o =  1'b0;
assign axi_wlen_o   =  4'b0;
assign axi_wfixed_o =  1'b0;


always @(posedge clk_i) begin
if (!rstn_i) begin
   axi_raddr_o  <= 32'b0;
   axi_rvalid_o <=  1'b0;
   axi_rsel_o   <=  8'b0;
   axi_rlen_o   <=  4'b0;
   axi_rfixed_o <=  1'b0;
   fifo_wr_in_o  <= 32'b0;
   fifo_wr_en_o  <=  1'b0;
   ofs_addr      <= 32'b0;
   upper  <= 1'b0;
   rd_len <= 16'b0;
   loop  <= 0;
   state <= 4'h0;
   end

else
   case (state)

   4'h0: if (dma_enable_i && dma_start_i && sha256_rdy_i && (fifo_wr_count_i < 9'h1E0)) begin
            axi_raddr_o  <= dma_base_addr_i + ofs_addr;     // start read address
            axi_rvalid_o <= 1'b1;
            axi_rsel_o   <= 8'hFF;
            axi_rlen_o   <= 4'h1;                           // one transfer only
            axi_rfixed_o <= 1'b0;
            fifo_wr_in_o  <= 32'b0;
            fifo_wr_en_o  <=  1'b0;
            upper  <= 1'b0;
            rd_len <= dma_bit_len_i;
            state <= 4'h1;
         end

   4'h1: if (axi_rrdy_i && !axi_rerr_i) begin               // read data valid
         loop <= 0;
         if (rd_len >= 32'h40) begin                        // at least another 64 bits are to be read
            upper  <= 1'b1;                                 // upper word to be read also
            rd_len <= rd_len - 32'h40;                      // remaining bits to read
            ofs_addr <= ofs_addr + 32'h08;                  // byte address increments by 64 bits = 8 bytes
            fifo_wr_in_o <= axi_rdata_i[31:0];              // push lower part into FIFO
            fifo_wr_en_o <= 1'b1;
            state <= 4'h2;
            end
         else if (|rd_len) begin                            // next read is truncated
            upper  <= (rd_len >= 32'h20) ?  1'b1 : 1'b0;    // upper word to be read also?
            rd_len <= 32'b0;                                // no more data to read
            ofs_addr <= ofs_addr + 32'h08;                  // next byte address increments by 64 bits = 8 bytes
            fifo_wr_in_o <= axi_rdata_i[31:0];              // push lower part into FIFO
            fifo_wr_en_o <= 1'b1;
            state <= 4'h2;
            end
         else begin                                         // end of DMA job
            axi_raddr_o  <= 32'b0;
            axi_rvalid_o <=  1'b0;
            axi_rsel_o   <=  8'b0;
            axi_rlen_o   <=  4'b0;
            fifo_wr_en_o <=  1'b0;
            ofs_addr <= 32'h00;
            state <= 4'h0;
            end
         end
      else if (axi_rerr_i) begin                            // error case stop transfer and trap
           axi_raddr_o  <= 32'b0;
           axi_rvalid_o <=  1'b0;
           axi_rsel_o   <=  8'b0;
           axi_rlen_o   <=  4'b0;
           axi_rfixed_o <=  1'b0;
           fifo_wr_en_o <=  1'b0;
           state <= 4'hF;
         end

   4'h2: if (!loop && upper) begin                          // prepare for upper FIFO push
         fifo_wr_en_o <= 1'b0;
         loop <= 1;
         state <= 4'h3;
         end
      else begin
         fifo_wr_en_o <= 1'b0;
         loop <= 0;
         if (|rd_len) begin                                 // DMA read access continues
            axi_rvalid_o <= 1'b0;
            state <= 4'h4;
            end
         else begin                                         // end of DMA job
            axi_raddr_o  <= 32'b0;
            axi_rvalid_o <= 1'b0;
            axi_rsel_o   <=  8'b0;
            axi_rlen_o   <=  4'b0;
            axi_rfixed_o <=  1'b0;
            state <= 4'h0;
            end
         end

   4'h3: begin
         fifo_wr_in_o <= axi_rdata_i[63:32];                // push upper part into FIFO
         fifo_wr_en_o <= 1'b1;
         axi_rvalid_o <= 1'b0;
         state <= 4'h2;
         end

   4'h4: if (fifo_wr_count_i < 9'h1E0) begin                // DMA read access requests next address
         axi_raddr_o  <= dma_base_addr_i + ofs_addr;
         axi_rvalid_o <= 1'b1;
         axi_rsel_o   <= 8'hFF;
         axi_rlen_o   <= 4'h1;                              // one transfer only
         axi_rfixed_o <= 1'b0;
         state <= 4'h1;
         end

   default: state <= 4'hF;                                  // being trapped in case of an error

   endcase
   end


endmodule: dma_engine
