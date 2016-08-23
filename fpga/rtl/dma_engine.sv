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
   input              clk_i              ,
   input              rstn_i             ,

   input              dma_enable_i       ,
   input   [   31: 0] dma_base_addr_i    ,
   input   [   31: 0] dma_bit_len_i      ,
   input              dma_start_i        ,

   input              sha256_rdy_i       ,

  // AXI_HP0 master
   output             S_AXI_HP0_aclk     ,
   output  [   31: 0] S_AXI_HP0_araddr   ,
   output  [    1: 0] S_AXI_HP0_arburst  ,
   output  [    3: 0] S_AXI_HP0_arcache  ,
   output  [    5: 0] S_AXI_HP0_arid     ,
   output  [    3: 0] S_AXI_HP0_arlen    ,
   output  [    1: 0] S_AXI_HP0_arlock   ,
   output  [    2: 0] S_AXI_HP0_arprot   ,
   output  [    3: 0] S_AXI_HP0_arqos    ,
   input              S_AXI_HP0_arready  ,
   output  [    2: 0] S_AXI_HP0_arsize   ,
   output             S_AXI_HP0_arvalid  ,
   output  [   31: 0] S_AXI_HP0_awaddr   ,
   output  [    1: 0] S_AXI_HP0_awburst  ,
   output  [    3: 0] S_AXI_HP0_awcache  ,
   output  [    5: 0] S_AXI_HP0_awid     ,
   output  [    3: 0] S_AXI_HP0_awlen    ,
   output  [    1: 0] S_AXI_HP0_awlock   ,
   output  [    2: 0] S_AXI_HP0_awprot   ,
   output  [    3: 0] S_AXI_HP0_awqos    ,
   input              S_AXI_HP0_awready  ,
   output  [    2: 0] S_AXI_HP0_awsize   ,
   output             S_AXI_HP0_awvalid  ,
   input   [    5: 0] S_AXI_HP0_bid      ,
   output             S_AXI_HP0_bready   ,
   input   [    1: 0] S_AXI_HP0_bresp    ,
   input              S_AXI_HP0_bvalid   ,
   input   [   63: 0] S_AXI_HP0_rdata    ,
   input   [    5: 0] S_AXI_HP0_rid      ,
   input              S_AXI_HP0_rlast    ,
   output             S_AXI_HP0_rready   ,
   input   [    1: 0] S_AXI_HP0_rresp    ,
   input              S_AXI_HP0_rvalid   ,
   output  [   63: 0] S_AXI_HP0_wdata    ,
   output  [    5: 0] S_AXI_HP0_wid      ,
   output             S_AXI_HP0_wlast    ,
   input              S_AXI_HP0_wready   ,
   output  [    7: 0] S_AXI_HP0_wstrb    ,
   output             S_AXI_HP0_wvalid   ,

   output reg         fifo_wr_en_o       ,
   output reg [ 31:0] fifo_wr_in_o       ,
   input      [  8:0] fifo_wr_count_i    ,

   output     [  3:0] dbg_state_o        ,
   output     [ 31:0] dbg_axi_r_state_o  ,
   output     [ 31:0] dbg_axi_w_state_o  ,
   output reg [ 31:0] dbg_axi_last_data
);


// AXIS master MM2S - to the FIFO
wire          [ 31:0] m_axis_mm2s_tdata;
wire          [  3:0] m_axis_mm2s_tkeep;
wire                  m_axis_mm2s_tlast;
wire                  m_axis_mm2s_tready;
wire                  m_axis_mm2s_tvalid;

// AXIS slave MM2S_CMD - command interface
wire          [ 71:0] s_axis_mm2s_cmd_tdata;
wire                  s_axis_mm2s_cmd_tready;
wire                  s_axis_mm2s_cmd_tvalid;

// AXIS master MM2S_STS - status interface
wire          [  7:0] m_axis_mm2s_sts_tdata;
wire          [  0:0] m_axis_mm2s_sts_tkeep;
wire                  m_axis_mm2s_sts_tlast;
wire                  m_axis_mm2s_sts_tready;
wire                  m_axis_mm2s_sts_tvalid;

// interrupt source
wire                  mm2s_err;


reg  unsigned [ 31:0] ofs_addr;
reg  unsigned [ 31:0] rd_len;
reg           [ 31:0] rd_cache;
reg           [  3:0] state;


assign S_AXI_HP0_aclk = clk_i;


// debugging
assign dbg_state_o       = state;
//assign dbg_axi_r_state_o = { axi_rdata_i[7:0],  1'b0, dma_enable_i, dma_start_i, sha256_rdy_i,  1'b0, axi_rerr_i, axi_rrdy_i, axi_rvalid_o,  axi_raddr_o[15:0] };
//assign dbg_axi_w_state_o = { axi_wdata_o[7:0],  1'b0, dma_enable_i, dma_start_i, sha256_rdy_i,  1'b0, axi_werr_i, axi_wrdy_i, axi_wvalid_o,  axi_waddr_o[15:0] };

// AXI datamover: master --> read slave, master --> FIFO
axi_datamover_s_axi_hp0 datamover (

  // AXI_HP0 master - read access - M_AXI_MM2S
  .m_axi_mm2s_aclk    (S_AXI_HP0_aclk             ),
  .m_axi_mm2s_aresetn (rstn_i                     ),
  .m_axi_mm2s_arid    (S_AXI_HP0_arid             ),
  .m_axi_mm2s_araddr  (S_AXI_HP0_araddr           ),
  .m_axi_mm2s_arvalid (S_AXI_HP0_arvalid          ),
//.m_axi_mm2s_arlock  (S_AXI_HP0_arlock           ),
  .m_axi_mm2s_arprot  (S_AXI_HP0_arprot           ),
//.m_axi_mm2s_arqos   (S_AXI_HP0_arqos            ),
  .m_axi_mm2s_arburst (S_AXI_HP0_arburst          ),
  .m_axi_mm2s_arcache (S_AXI_HP0_arcache          ),
  .m_axi_mm2s_arlen   (S_AXI_HP0_arlen            ),
  .m_axi_mm2s_arsize  (S_AXI_HP0_arsize           ),
  .m_axi_mm2s_arready (S_AXI_HP0_arready          ),
  .m_axi_mm2s_aruser  (                           ),
//.m_axi_mm2s_rid     (S_AXI_HP0_rid              ),
  .m_axi_mm2s_rdata   (S_AXI_HP0_rdata            ),
  .m_axi_mm2s_rvalid  (S_AXI_HP0_rvalid           ),
  .m_axi_mm2s_rlast   (S_AXI_HP0_rlast            ),
  .m_axi_mm2s_rresp   (S_AXI_HP0_rresp            ),
  .m_axi_mm2s_rready  (S_AXI_HP0_rready           ),

/*
  // AXI_HP0 master - write access - M_AXI_MM2S
  .m_axi_mm2s_awid    (S_AXI_HP0_awid             ),
  .m_axi_mm2s_awaddr  (S_AXI_HP0_awaddr           ),
  .m_axi_mm2s_awvalid (S_AXI_HP0_awvalid          ),
  .m_axi_mm2s_awlock  (S_AXI_HP0_awlock           ),
  .m_axi_mm2s_awprot  (S_AXI_HP0_awprot           ),
  .m_axi_mm2s_awqos   (S_AXI_HP0_awqos            ),
  .m_axi_mm2s_awburst (S_AXI_HP0_awburst          ),
  .m_axi_mm2s_awcache (S_AXI_HP0_awcache          ),
  .m_axi_mm2s_awlen   (S_AXI_HP0_awlen            ),
  .m_axi_mm2s_awsize  (S_AXI_HP0_awsize           ),
  .m_axi_mm2s_awready (S_AXI_HP0_awready          ),
  .m_axi_mm2s_wid     (S_AXI_HP0_wid              ),
  .m_axi_mm2s_wdata   (S_AXI_HP0_wdata            ),
  .m_axi_mm2s_wvalid  (S_AXI_HP0_wvalid           ),
  .m_axi_mm2s_wstrb   (S_AXI_HP0_wstrb            ),
  .m_axi_mm2s_wlast   (S_AXI_HP0_wlast            ),
  .m_axi_mm2s_wready  (S_AXI_HP0_wready           ),
  .m_axi_mm2s_bid     (S_AXI_HP0_bid              ),
  .m_axi_mm2s_bresp   (S_AXI_HP0_bresp            ),
  .m_axi_mm2s_bvalid  (S_AXI_HP0_bvalid           ),
  .m_axi_mm2s_bready  (S_AXI_HP0_bready           ),
*/

  // AXIS master MM2S - to the FIFO
  .m_axis_mm2s_tdata          (m_axis_mm2s_tdata          ),
  .m_axis_mm2s_tkeep          (m_axis_mm2s_tkeep          ),
  .m_axis_mm2s_tlast          (m_axis_mm2s_tlast          ),
  .m_axis_mm2s_tvalid         (m_axis_mm2s_tvalid         ),
  .m_axis_mm2s_tready         (m_axis_mm2s_tready         ),

  // AXIS slave MM2S_CMD - command interface
  .m_axis_mm2s_cmdsts_aclk    (clk_i                      ),
  .m_axis_mm2s_cmdsts_aresetn (rstn_i                     ),
  .s_axis_mm2s_cmd_tdata      (s_axis_mm2s_cmd_tdata      ),
  .s_axis_mm2s_cmd_tvalid     (s_axis_mm2s_cmd_tvalid     ),
  .s_axis_mm2s_cmd_tready     (s_axis_mm2s_cmd_tready     ),

  // AXIS master MM2S_STS - status interface
  .m_axis_mm2s_sts_tdata      (m_axis_mm2s_sts_tdata      ),
  .m_axis_mm2s_sts_tkeep      (m_axis_mm2s_sts_tkeep      ),
  .m_axis_mm2s_sts_tlast      (m_axis_mm2s_sts_tlast      ),
  .m_axis_mm2s_sts_tvalid     (m_axis_mm2s_sts_tvalid     ),
  .m_axis_mm2s_sts_tready     (m_axis_mm2s_sts_tready     ),

  .mm2s_err                   (mm2s_err                   )
);

assign S_AXI_HP0_arlock   =  2'b00;
assign S_AXI_HP0_arqos    =  4'b0000;

assign S_AXI_HP0_awaddr   = 32'h0;
assign S_AXI_HP0_awburst  =  2'h0;
assign S_AXI_HP0_awcache  =  4'h0;
assign S_AXI_HP0_awid     =  6'h0;
assign S_AXI_HP0_awlen    =  4'h0;
assign S_AXI_HP0_awlock   =  2'h0;
assign S_AXI_HP0_awprot   =  3'h0;
assign S_AXI_HP0_awqos    =  4'h0;
assign S_AXI_HP0_awsize   =  3'h0;
assign S_AXI_HP0_awvalid  =  1'b0;
assign S_AXI_HP0_wdata    = 64'h0;
assign S_AXI_HP0_wid      =  6'h0;
assign S_AXI_HP0_wlast    =  1'b0;
assign S_AXI_HP0_wstrb    =  8'h0;
assign S_AXI_HP0_wvalid   =  1'b0;
assign S_AXI_HP0_bready   =  1'b0;


// AXI master system write bus not used
/*
assign axi_clk_o    = clk_i;
assign axi_rstn_o   = rstn_i;
assign axi_waddr_o  = 32'b0;
assign axi_wdata_o  = 64'b0;
assign axi_wsel_o   =  8'b0;
assign axi_wvalid_o =  1'b0;
assign axi_wlen_o   =  4'b0;
assign axi_wfixed_o =  1'b0;
*/

/*
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
//          if (dma_bit_len_i >= 32'h400)                   // longest burst is 16 words for one hashing sub-process
//             axi_rlen_o <= 4'h7;                          // AXI4 says: axi_rlen[3:0] + 1
//          else if (dma_bit_len_i >= 32'h40)               // burst length as needed
//             axi_rlen_o <= (dma_bit_len_i >> 10) - 32'h1;
//          else
//             axi_rlen_o <= 4'h0;                          // minimal length is one transfer
//          axi_rfixed_o <= 1'b0;                           // keep it cleared
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
*/

endmodule: dma_engine
