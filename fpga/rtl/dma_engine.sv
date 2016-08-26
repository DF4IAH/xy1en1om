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

  // AXI_ACP master
   output             S_AXI_ACP_aclk     ,
   output  [   31: 0] S_AXI_ACP_araddr   ,
   output  [    1: 0] S_AXI_ACP_arburst  ,
   output  [    3: 0] S_AXI_ACP_arcache  ,
   output  [    2: 0] S_AXI_ACP_arid     ,
   output  [    3: 0] S_AXI_ACP_arlen    ,
   output  [    1: 0] S_AXI_ACP_arlock   ,
   output  [    2: 0] S_AXI_ACP_arprot   ,
   output  [    3: 0] S_AXI_ACP_arqos    ,
   input              S_AXI_ACP_arready  ,
   output  [    2: 0] S_AXI_ACP_arsize   ,
   output  [    4: 0] S_AXI_ACP_aruser   ,
   output             S_AXI_ACP_arvalid  ,
   output  [   31: 0] S_AXI_ACP_awaddr   ,
   output  [    1: 0] S_AXI_ACP_awburst  ,
   output  [    3: 0] S_AXI_ACP_awcache  ,
   output  [    2: 0] S_AXI_ACP_awid     ,
   output  [    3: 0] S_AXI_ACP_awlen    ,
   output  [    1: 0] S_AXI_ACP_awlock   ,
   output  [    2: 0] S_AXI_ACP_awprot   ,
   output  [    3: 0] S_AXI_ACP_awqos    ,
   input              S_AXI_ACP_awready  ,
   output  [    2: 0] S_AXI_ACP_awsize   ,
   output  [    4: 0] S_AXI_ACP_awuser   ,
   output             S_AXI_ACP_awvalid  ,
   input   [    2: 0] S_AXI_ACP_bid      ,
   output             S_AXI_ACP_bready   ,
   input   [    1: 0] S_AXI_ACP_bresp    ,
   input              S_AXI_ACP_bvalid   ,
   input   [   63: 0] S_AXI_ACP_rdata    ,
   input   [    2: 0] S_AXI_ACP_rid      ,
   input              S_AXI_ACP_rlast    ,
   output             S_AXI_ACP_rready   ,
   input   [    1: 0] S_AXI_ACP_rresp    ,
   input              S_AXI_ACP_rvalid   ,
   output  [   63: 0] S_AXI_ACP_wdata    ,
   output  [    2: 0] S_AXI_ACP_wid      ,
   output             S_AXI_ACP_wlast    ,
   input              S_AXI_ACP_wready   ,
   output  [    7: 0] S_AXI_ACP_wstrb    ,
   output             S_AXI_ACP_wvalid   ,

   output reg         fifo_wr_en_o       ,
   output reg [ 31:0] fifo_wr_in_o       ,
   input      [  8:0] fifo_wr_count_i    ,

   output     [  7:0] dbg_state_o        ,
   output     [ 31:0] dbg_axi_r_state_o  ,
   output     [ 31:0] dbg_axi_w_state_o  ,
   output reg [ 31:0] dbg_axi_last_data
);


// AXIS master MM2S - to the FIFO
wire          [ 31:0] m_axis_mm2s_tdata;
wire                  m_axis_mm2s_tvalid;
wire          [  3:0] m_axis_mm2s_tkeep;
wire                  m_axis_mm2s_tlast;
reg                   m_axis_mm2s_tready     =  1'b0;

// AXIS slave MM2S_CMD - command interface
wire          [ 71:0] s_axis_mm2s_cmd_tdata;
reg                   s_axis_mm2s_cmd_tvalid =  1'b0;
wire                  s_axis_mm2s_cmd_tready;

// AXIS master MM2S_STS - status interface
wire          [  7:0] m_axis_mm2s_sts_tdata;
wire                  m_axis_mm2s_sts_tvalid;
wire          [  0:0] m_axis_mm2s_sts_tkeep;
wire                  m_axis_mm2s_sts_tlast;
reg                   m_axis_mm2s_sts_tready =  1'b0;

// interrupt source
wire                  mm2s_err;


reg           [  2:0] cmd_tag                =  3'h0;
reg           [ 31:0] cmd_start_addr         = 32'b0;
reg                   cmd_eof                =  1'b0;
reg           [ 22:0] cmd_btt                = 23'h0;
reg                   cmd_running            =  1'b0;
reg           [  7:0] sts_last               =  8'h0;
reg           [  7:0] dbg_sts                =  8'h0;
wire                  sts_dec_ok;
wire          [  3:0] sts_dec_tag;
wire                  sts_dec_interr;
wire                  sts_dec_decerr;
wire                  sts_dec_slverr;
wire                  sts_dec_ok;


assign S_AXI_ACP_aclk = clk_i;

// dummy size connection parts
wire          [ 3: 0] S_AXI_ACP_arlen_nc;
//wire        [ 3: 0] S_AXI_ACP_awlen_nc;

// AXI datamover: master --> read slave, master --> FIFO
axi_datamover_s_axi_acp datamover (

  // AXI_ACP master - read access - M_AXI_MM2S
  .m_axi_mm2s_aclk    (S_AXI_ACP_aclk             ),
  .m_axi_mm2s_aresetn (rstn_i                     ),
  .m_axi_mm2s_arid    (S_AXI_ACP_arid             ),
  .m_axi_mm2s_araddr  (S_AXI_ACP_araddr           ),
  .m_axi_mm2s_arvalid (S_AXI_ACP_arvalid          ),
//.m_axi_mm2s_arlock  (S_AXI_ACP_arlock           ),
  .m_axi_mm2s_arprot  (S_AXI_ACP_arprot           ),
//.m_axi_mm2s_arqos   (S_AXI_ACP_arqos            ),
  .m_axi_mm2s_arburst (S_AXI_ACP_arburst          ),
  .m_axi_mm2s_arcache (S_AXI_ACP_arcache          ),
  .m_axi_mm2s_arlen   ({S_AXI_ACP_arlen_nc, S_AXI_ACP_arlen}),
  .m_axi_mm2s_arsize  (S_AXI_ACP_arsize           ),
  .m_axi_mm2s_arready (S_AXI_ACP_arready          ),
  .m_axi_mm2s_aruser  (S_AXI_ACP_aruser[3:0]      ),
//.m_axi_mm2s_rid     (S_AXI_ACP_rid              ),
  .m_axi_mm2s_rdata   (S_AXI_ACP_rdata            ),
  .m_axi_mm2s_rvalid  (S_AXI_ACP_rvalid           ),
  .m_axi_mm2s_rlast   (S_AXI_ACP_rlast            ),
  .m_axi_mm2s_rresp   (S_AXI_ACP_rresp            ),
  .m_axi_mm2s_rready  (S_AXI_ACP_rready           ),

/*
  // AXI_ACP master - write access - M_AXI_MM2S
  .m_axi_mm2s_awid    (S_AXI_ACP_awid             ),
  .m_axi_mm2s_awaddr  (S_AXI_ACP_awaddr           ),
  .m_axi_mm2s_awvalid (S_AXI_ACP_awvalid          ),
  .m_axi_mm2s_awlock  (S_AXI_ACP_awlock           ),
  .m_axi_mm2s_awprot  (S_AXI_ACP_awprot           ),
  .m_axi_mm2s_awqos   (S_AXI_ACP_awqos            ),
  .m_axi_mm2s_awburst (S_AXI_ACP_awburst          ),
  .m_axi_mm2s_awcache (S_AXI_ACP_awcache          ),
  .m_axi_mm2s_awlen   ({S_AXI_ACP_awlen_nc, S_AXI_ACP_awlen}),
  .m_axi_mm2s_awsize  (S_AXI_ACP_awsize           ),
  .m_axi_mm2s_awuser  ({ 1'b0, S_AXI_ACP_awuser } ),
  .m_axi_mm2s_awready (S_AXI_ACP_awready          ),
  .m_axi_mm2s_wid     (S_AXI_ACP_wid              ),
  .m_axi_mm2s_wdata   (S_AXI_ACP_wdata            ),
  .m_axi_mm2s_wvalid  (S_AXI_ACP_wvalid           ),
  .m_axi_mm2s_wstrb   (S_AXI_ACP_wstrb            ),
  .m_axi_mm2s_wlast   (S_AXI_ACP_wlast            ),
  .m_axi_mm2s_wready  (S_AXI_ACP_wready           ),
  .m_axi_mm2s_bid     (S_AXI_ACP_bid              ),
  .m_axi_mm2s_bresp   (S_AXI_ACP_bresp            ),
  .m_axi_mm2s_bvalid  (S_AXI_ACP_bvalid           ),
  .m_axi_mm2s_bready  (S_AXI_ACP_bready           ),
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

assign S_AXI_ACP_arlock   =  2'b00;
assign S_AXI_ACP_arqos    =  4'b0000;
assign S_AXI_ACP_aruser[4]=  1'b0;

assign S_AXI_ACP_awaddr   = 32'h0;
assign S_AXI_ACP_awburst  =  2'h0;
assign S_AXI_ACP_awcache  =  4'h0;
assign S_AXI_ACP_awid     =  6'h0;
assign S_AXI_ACP_awlen    =  4'h0;
assign S_AXI_ACP_awlock   =  2'h0;
assign S_AXI_ACP_awprot   =  3'h0;
assign S_AXI_ACP_awqos    =  4'h0;
assign S_AXI_ACP_awsize   =  3'h0;
assign S_AXI_ACP_awuser   =  5'b0;
assign S_AXI_ACP_awvalid  =  1'b0;
assign S_AXI_ACP_wdata    = 64'h0;
assign S_AXI_ACP_wid      =  6'h0;
assign S_AXI_ACP_wlast    =  1'b0;
assign S_AXI_ACP_wstrb    =  8'h0;
assign S_AXI_ACP_wvalid   =  1'b0;
assign S_AXI_ACP_bready   =  1'b0;


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


/* FIFO */
always @(posedge clk_i)
if (!rstn_i)
   m_axis_mm2s_tready <= 1'b0;
else if (!mm2s_err && !m_axis_mm2s_tlast && (fifo_wr_count_i < 9'h1E0))
   m_axis_mm2s_tready <= 1'b1;                              // clear m_axis_mm2s_tready for one clock when last block enters
else
   m_axis_mm2s_tready <= 1'b0;

always @(posedge clk_i)
if (!rstn_i) begin
   fifo_wr_in_o <= 32'b0;
   fifo_wr_en_o <=  1'b0;
   end
else if (m_axis_mm2s_tvalid && m_axis_mm2s_tready) begin
   fifo_wr_in_o      <= m_axis_mm2s_tdata;
   dbg_axi_last_data <= m_axis_mm2s_tdata;
   fifo_wr_en_o <= 1'b1;
   end
else
   fifo_wr_en_o <= 1'b0;


/* CMD */
always @(posedge clk_i)
if (!rstn_i) begin
   cmd_running            <=  1'b0;
   cmd_tag                <=  3'h0;
   cmd_start_addr         <= 32'h0;
   cmd_eof                <=  1'b0;
   cmd_btt                <= 23'b0;
   s_axis_mm2s_cmd_tvalid <=  1'b0;
   end
else begin
   if (!cmd_running && s_axis_mm2s_cmd_tready && sha256_rdy_i && dma_enable_i && dma_start_i) begin
      cmd_running            <= 1'b1;
      cmd_start_addr         <= dma_base_addr_i;
      cmd_eof                <= 1'b1;
      cmd_btt                <= (|dma_bit_len_i[7:0]) ?  (dma_bit_len_i[25:3] + 23'd1) : dma_bit_len_i[25:3];
      cmd_tag                <= cmd_tag + 3'h1;
      s_axis_mm2s_cmd_tvalid <= 1'b1;
      end
   else if (cmd_running && s_axis_mm2s_cmd_tready && s_axis_mm2s_cmd_tvalid)
      s_axis_mm2s_cmd_tvalid <= 1'b0;
   else if (!dma_enable_i)
      s_axis_mm2s_cmd_tvalid <= 1'b0;

   if (cmd_running && !s_axis_mm2s_cmd_tvalid && dbg_sts && !dma_start_i)
      cmd_running <= 1'b0;
   end

//                                 bufferable, non-cacheable
//                                 CACHE, XUSER, RSVD,     TAG,   START ADDRES,  DRR,     EOF,  DSA, INCR,     BTT
assign s_axis_mm2s_cmd_tdata = { 4'b0001,  4'h0, 4'h0, cmd_tag, cmd_start_addr, 1'b0, cmd_eof, 4'h0, 1'b1, cmd_btt};

// debugging
assign dbg_axi_r_state_o = { 1'b0, cmd_tag[2:0], 8'b0,  dma_start_i, cmd_running, s_axis_mm2s_cmd_tvalid, s_axis_mm2s_cmd_tready,  cmd_start_addr[15:0] };
assign dbg_axi_w_state_o = { 9'b0, cmd_btt };


/* STS */
always @(posedge clk_i)
if (!rstn_i)
   m_axis_mm2s_sts_tready <= 1'b0;
else
   m_axis_mm2s_sts_tready <= 1'b1;

always @(posedge clk_i)
if (!rstn_i) begin
   dbg_sts  <= 8'b0;
   sts_last <= 8'hFF;
   end
else if (m_axis_mm2s_sts_tvalid && m_axis_mm2s_sts_tready) begin
   dbg_sts  <= m_axis_mm2s_sts_tdata;
   sts_last <= m_axis_mm2s_sts_tdata;
   end
else
   dbg_sts <= 8'b0;


assign sts_dec_tag    = sts_last[3:0];
assign sts_dec_interr = sts_last[4];
assign sts_dec_decerr = sts_last[5];
assign sts_dec_slverr = sts_last[6];
assign sts_dec_ok     = sts_last[7];

assign dbg_state_o = sts_last;


endmodule: dma_engine
