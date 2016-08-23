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
   input                 clk_i,
   input                 rstn_i,

   input                 dma_enable_i,
   input         [ 31:0] dma_base_addr_i,
   input         [ 31:0] dma_bit_len_i,
   input                 dma_start_i,

   input                 sha256_rdy_i,

   // <--> axi_master.v <--> AXI HP0, HP1
   output                axi_clk_o,
   output                axi_rstn_o,
   output        [ 31:0] axi_waddr_o,
   output        [ 63:0] axi_wdata_o,
   output        [  7:0] axi_wsel_o,
   output                axi_wvalid_o,
   output        [  3:0] axi_wlen_o,
   output                axi_wfixed_o,
   input                 axi_werr_i,
   input                 axi_wrdy_i,
   output reg    [ 31:0] axi_raddr_o,
   output reg            axi_rvalid_o,
   output reg    [  7:0] axi_rsel_o,
   output reg    [  3:0] axi_rlen_o,
   output reg            axi_rfixed_o,
   input         [ 63:0] axi_rdata_i,
   input                 axi_rrdy_i,
   input                 axi_rerr_i,

   output reg            fifo_wr_en_o,
   output reg    [ 31:0] fifo_wr_in_o,
   input         [  8:0] fifo_wr_count_i,

   output        [  3:0] dbg_state_o,
   output        [ 31:0] dbg_axi_r_state_o,
   output        [ 31:0] dbg_axi_w_state_o,
   output reg    [ 31:0] dbg_axi_last_data
);


reg  unsigned [31:0]     ofs_addr;
reg  unsigned [31:0]     rd_len;
reg           [31:0]     rd_cache;
reg           [ 3:0]     state;

// debugging
assign dbg_state_o       = state;
assign dbg_axi_r_state_o = { axi_rdata_i[7:0],  1'b0, dma_enable_i, dma_start_i, sha256_rdy_i,  1'b0, axi_rerr_i, axi_rrdy_i, axi_rvalid_o,  axi_raddr_o[15:0] };
assign dbg_axi_w_state_o = { axi_wdata_o[7:0],  1'b0, dma_enable_i, dma_start_i, sha256_rdy_i,  1'b0, axi_werr_i, axi_wrdy_i, axi_wvalid_o,  axi_waddr_o[15:0] };

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
   rd_len       <= 16'b0;
   rd_cache     <= 32'b0;
   ofs_addr     <= 32'b0;
   fifo_wr_in_o <= 32'b0;
   fifo_wr_en_o <=  1'b0;
   axi_raddr_o  <= 32'b0;
   axi_rvalid_o <=  1'b0;
   axi_rsel_o   <=  8'b0;
   axi_rlen_o   <=  4'b0;
   axi_rfixed_o <=  1'b0;
   state <= 4'h0;
   end

else
   case (state)

   4'h0: if (sha256_rdy_i && dma_enable_i && dma_start_i && (|dma_bit_len_i) && (fifo_wr_count_i <= 9'h1E0)) begin
            rd_len       <= dma_bit_len_i;
            rd_cache     <= 32'b0;
            ofs_addr     <= 32'b0;
            fifo_wr_in_o <= 32'b0;
            fifo_wr_en_o <= 1'b0;
            axi_raddr_o  <= dma_base_addr_i;                // start read address
            axi_rvalid_o <= 1'b1;
            axi_rsel_o   <= 8'hFF;                          // keep all bits on for 64 bit transfers
            axi_rlen_o   <= 4'h6;  // DEBUGGING
/*          if (dma_bit_len_i >= 32'h400)                   // longest burst is 16 words for one hashing sub-process
               axi_rlen_o <= 4'h7;                          // AXI4 says: axi_rlen[3:0] + 1
            else if (dma_bit_len_i >= 32'h40)               // burst length as needed
               axi_rlen_o <= (dma_bit_len_i >> 10) - 32'h1;
            else
               axi_rlen_o <= 4'h0;                          // minimal length is one transfer
*/          axi_rfixed_o <= 1'b0;                           // keep it cleared
            state <= 4'h1;
            end

   4'h1: if (axi_rrdy_i && !axi_rerr_i) begin               // read data valid
            rd_cache     <= axi_rdata_i[31: 0];
            fifo_wr_in_o <= axi_rdata_i[63:32];             // push upper part into FIFO
            dbg_axi_last_data <= axi_rdata_i[63:32];        // DEBUGGING
            fifo_wr_en_o <= 1'b1;
            axi_rvalid_o <= 1'b0;

            if (rd_len >= 32'h40) begin                     // 64 bits to be stored, next data to request
               rd_len   <= rd_len - 32'h40;                 // remaining bits to read
               ofs_addr <= ofs_addr + 32'h08;               // byte address increments by 64 bits = 8 bytes
               state <= 4'h2;                               // goto push lower part branch
               end
            else if (rd_len > 32'h20) begin                 // 64 bits to be stored, but no more data request
               rd_len <= 32'b0;                             // no more data to request
               state <= 4'h2;
               end
            else begin                                      // less data to be stored, no more data request
               rd_len <= 32'b0;                             // no more data to read
               state <= 4'h4;
               end
            end
         else if (axi_rerr_i) begin                         // error case stop transfer and trap
            axi_raddr_o  <= 32'b0;
            axi_rvalid_o <=  1'b0;
            fifo_wr_en_o <=  1'b0;
            state <= 4'hF;
            end

   4'h2: begin                                              // prepare for lower FIFO push
            fifo_wr_en_o <= 1'b0;
            state <= 4'h3;
            end

   4'h3: begin
            fifo_wr_in_o <= rd_cache;                       // push lower part into FIFO
            dbg_axi_last_data <= rd_cache;                  // DEBUGGING
            fifo_wr_en_o <= 1'b1;
            state <= 4'h4;
            end

   4'h4: begin
            fifo_wr_en_o <= 1'b0;
            if (|rd_len)
               if (fifo_wr_count_i <= 9'h1E0) begin         // DMA read access requests next address
                  axi_raddr_o  <= dma_base_addr_i + ofs_addr;
                  axi_rvalid_o <= 1'b1;
                  if (dma_bit_len_i >= 32'h400)             // longest burst is 16 words for one hashing sub-process
                     axi_rlen_o <= 4'h7;                    // AXI4 says: axi_rlen[3:0] + 1
                  else if (dma_bit_len_i >= 32'h40)         // burst length as needed
                     axi_rlen_o <= (dma_bit_len_i >> 10) - 32'h1;
                  else
                     axi_rlen_o <= 4'h0;                    // minimal length is one transfer
                  state <= 4'h1;
                  end
            else
               state <= 4'h0;                               // DMA access finished
         end

   default: state <= 4'hF;                                  // being trapped in case of an error

   endcase
   end


endmodule: dma_engine
