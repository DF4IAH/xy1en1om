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
  input               clk_i                ,
  input               rstn_i               ,

  input               dma_enable_i         ,
  input      [ 31: 0] dma_base_addr_i      ,
  input      [ 25: 0] dma_bit_len_i        ,
  input               dma_start_i          ,

  input               sha256_rdy_i         ,

  // AXI_HP0 master
  output              S_AXI_HP0_aclk_o     ,
  output     [ 31: 0] S_AXI_HP0_araddr_o   ,
  output     [  1: 0] S_AXI_HP0_arburst_o  ,
  output     [  3: 0] S_AXI_HP0_arcache_o  ,
  output     [  5: 0] S_AXI_HP0_arid_o     ,
  output     [  3: 0] S_AXI_HP0_arlen_o    ,
  output     [  1: 0] S_AXI_HP0_arlock_o   ,
  output     [  2: 0] S_AXI_HP0_arprot_o   ,
  output     [  3: 0] S_AXI_HP0_arqos_o    ,
  input               S_AXI_HP0_arready_i  ,
  output     [  2: 0] S_AXI_HP0_arsize_o   ,
  output     [  4: 0] S_AXI_HP0_aruser_o   ,
  output              S_AXI_HP0_arvalid_o  ,
  output     [ 31: 0] S_AXI_HP0_awaddr_o   ,
  output     [  1: 0] S_AXI_HP0_awburst_o  ,
  output     [  3: 0] S_AXI_HP0_awcache_o  ,
  output     [  5: 0] S_AXI_HP0_awid_o     ,
  output     [  3: 0] S_AXI_HP0_awlen_o    ,
  output     [  1: 0] S_AXI_HP0_awlock_o   ,
  output     [  2: 0] S_AXI_HP0_awprot_o   ,
  output     [  3: 0] S_AXI_HP0_awqos_o    ,
  input               S_AXI_HP0_awready_i  ,
  output     [  2: 0] S_AXI_HP0_awsize_o   ,
  output     [  4: 0] S_AXI_HP0_awuser_o   ,
  output              S_AXI_HP0_awvalid_o  ,
  input      [  5: 0] S_AXI_HP0_bid_i      ,
  output              S_AXI_HP0_bready_o   ,
  input      [  1: 0] S_AXI_HP0_bresp_i    ,
  input               S_AXI_HP0_bvalid_i   ,
  input      [ 63: 0] S_AXI_HP0_rdata_i    ,
  input      [  5: 0] S_AXI_HP0_rid_i      ,
  input               S_AXI_HP0_rlast_i    ,
  output              S_AXI_HP0_rready_o   ,
  input      [  1: 0] S_AXI_HP0_rresp_i    ,
  input               S_AXI_HP0_rvalid_i   ,
  output     [ 63: 0] S_AXI_HP0_wdata_o    ,
  output     [  5: 0] S_AXI_HP0_wid_o      ,
  output              S_AXI_HP0_wlast_o    ,
  input               S_AXI_HP0_wready_i   ,
  output     [  7: 0] S_AXI_HP0_wstrb_o    ,
  output              S_AXI_HP0_wvalid_o   ,

  output reg          fifo_wr_en_o         ,
  output reg [ 31: 0] fifo_wr_in_o         ,
  input      [  8: 0] fifo_wr_count_i      ,

  output              dma_in_progress_o    ,

  input      [ 31: 0] masterclock_i        ,    // masterclock progress with each 125 MHz tick and starts after release of reset 

  output reg [ 31: 0] dbg_clock_start_o    ,
  output reg [ 31: 0] dbg_clock_last_o     ,
  output reg [ 31: 0] dbg_clock_stop_o     ,
  output     [  7: 0] dbg_state_o          ,
  output     [ 31: 0] dbg_axi_r_state_o    ,
  output     [ 31: 0] dbg_axi_w_state_o    ,
  output reg [ 31: 0] dbg_axi_last_data_o
);


// AXIS master MM2S - to the FIFO
wire          [ 31:0] m_axis_mm2s_tdata_o;
wire                  m_axis_mm2s_tvalid_o;
wire          [  3:0] m_axis_mm2s_tkeep_o;
wire                  m_axis_mm2s_tlast_o;
reg                   m_axis_mm2s_tready_i     =  1'b0;

// AXIS slave MM2S_CMD - command interface
wire          [ 79:0] s_axis_mm2s_cmd_tdata_i;
reg                   s_axis_mm2s_cmd_tvalid_i =  1'b0;
wire                  s_axis_mm2s_cmd_tready_o;

// AXIS master MM2S_STS - status interface
wire          [  7:0] m_axis_mm2s_sts_tdata_o;
wire                  m_axis_mm2s_sts_tvalid_o;
wire          [  0:0] m_axis_mm2s_sts_tkeep_o;
wire                  m_axis_mm2s_sts_tlast_o;
reg                   m_axis_mm2s_sts_tready_i =  1'b0;

// interrupt source
wire                  mm2s_err;


reg           [  3:0] cmd_tag                =  4'h0;
reg           [ 31:0] cmd_start_addr         = 32'b0;
reg                   cmd_eof                =  1'b0;
reg           [ 22:0] cmd_btt                = 23'h0;
reg                   cmd_running            =  1'b0;
reg           [  7:0] sts_last               =  8'h0;
reg           [  7:0] dbg_sts                =  8'h0;
wire          [  3:0] sts_dec_tag;
wire                  sts_dec_interr;
wire                  sts_dec_decerr;
wire                  sts_dec_slverr;
wire                  sts_dec_ok;


assign S_AXI_HP0_aclk_o = clk_i;

// dummy size connection parts
wire          [ 3: 0] S_AXI_HP0_arlen_nc;
//wire        [ 3: 0] S_AXI_HP0_awlen_nc;

// AXI datamover: master --> read slave, master --> FIFO
axi_datamover_s_axi_hp0 datamover (

  // AXI_HP0 master - read access - M_AXI_MM2S
  .m_axi_mm2s_aclk         ( clk_i                       ),
  .m_axi_mm2s_aresetn      ( rstn_i                      ),
  .m_axi_mm2s_arid         ( S_AXI_HP0_arid_o            ),
  .m_axi_mm2s_araddr       ( S_AXI_HP0_araddr_o          ),
  .m_axi_mm2s_arvalid      ( S_AXI_HP0_arvalid_o         ),
//.m_axi_mm2s_arlock       ( S_AXI_HP0_arlock_o          ),
  .m_axi_mm2s_arprot       ( S_AXI_HP0_arprot_o          ),
//.m_axi_mm2s_arqos        ( S_AXI_HP0_arqos_o           ),
  .m_axi_mm2s_arburst      ( S_AXI_HP0_arburst_o         ),
  .m_axi_mm2s_arcache      ( S_AXI_HP0_arcache_o         ),
  .m_axi_mm2s_arlen        ({S_AXI_HP0_arlen_nc, S_AXI_HP0_arlen_o}),
  .m_axi_mm2s_arsize       ( S_AXI_HP0_arsize_o          ),
  .m_axi_mm2s_arready      ( S_AXI_HP0_arready_i         ),
  .m_axi_mm2s_aruser       ( S_AXI_HP0_aruser_o[3:0]     ),
//.m_axi_mm2s_rid          ( S_AXI_HP0_rid_i             ),
  .m_axi_mm2s_rdata        ( S_AXI_HP0_rdata_i           ),
  .m_axi_mm2s_rvalid       ( S_AXI_HP0_rvalid_i          ),
  .m_axi_mm2s_rlast        ( S_AXI_HP0_rlast_i           ),
  .m_axi_mm2s_rresp        ( S_AXI_HP0_rresp_i           ),
  .m_axi_mm2s_rready       ( S_AXI_HP0_rready_o          ),

/*
  // AXI_HP0 master - write access - M_AXI_MM2S
  .m_axi_mm2s_awid         ( S_AXI_HP0_awid_o            ),
  .m_axi_mm2s_awaddr       ( S_AXI_HP0_awaddr_o          ),
  .m_axi_mm2s_awvalid      ( S_AXI_HP0_awvalid_o         ),
  .m_axi_mm2s_awlock       ( S_AXI_HP0_awlock_o          ),
  .m_axi_mm2s_awprot       ( S_AXI_HP0_awprot_o          ),
  .m_axi_mm2s_awqos        ( S_AXI_HP0_awqos_o           ),
  .m_axi_mm2s_awburst      ( S_AXI_HP0_awburst_o         ),
  .m_axi_mm2s_awcache      ( S_AXI_HP0_awcache_o         ),
  .m_axi_mm2s_awlen        ({S_AXI_HP0_awlen_nc, S_AXI_HP0_awlen_o}),
  .m_axi_mm2s_awsize       ( S_AXI_HP0_awsize_o          ),
  .m_axi_mm2s_awuser       ({ 1'b0, S_AXI_HP0_awuser_o } ),
  .m_axi_mm2s_awready      ( S_AXI_HP0_awready_i         ),
  .m_axi_mm2s_wid          ( S_AXI_HP0_wid_o             ),
  .m_axi_mm2s_wdata        ( S_AXI_HP0_wdata_o           ),
  .m_axi_mm2s_wvalid       ( S_AXI_HP0_wvalid_o          ),
  .m_axi_mm2s_wstrb        ( S_AXI_HP0_wstrb_o           ),
  .m_axi_mm2s_wlast        ( S_AXI_HP0_wlast_o           ),
  .m_axi_mm2s_wready       ( S_AXI_HP0_wready_i          ),
  .m_axi_mm2s_bid          ( S_AXI_HP0_bid_i             ),
  .m_axi_mm2s_bresp        ( S_AXI_HP0_bresp_i           ),
  .m_axi_mm2s_bvalid       ( S_AXI_HP0_bvalid_i          ),
  .m_axi_mm2s_bready       ( S_AXI_HP0_bready_o          ),
*/

  // AXIS master MM2S - to the FIFO
  .m_axis_mm2s_tdata       ( m_axis_mm2s_tdata_o         ),
  .m_axis_mm2s_tkeep       ( m_axis_mm2s_tkeep_o         ),
  .m_axis_mm2s_tlast       ( m_axis_mm2s_tlast_o         ),
  .m_axis_mm2s_tvalid      ( m_axis_mm2s_tvalid_o        ),
  .m_axis_mm2s_tready      ( m_axis_mm2s_tready_i        ),

  // AXIS slave MM2S_CMD - command interface
  .m_axis_mm2s_cmdsts_aclk ( clk_i                       ),
  .m_axis_mm2s_cmdsts_aresetn ( rstn_i                   ),
  .s_axis_mm2s_cmd_tdata   ( s_axis_mm2s_cmd_tdata_i     ),
  .s_axis_mm2s_cmd_tvalid  ( s_axis_mm2s_cmd_tvalid_i    ),
  .s_axis_mm2s_cmd_tready  ( s_axis_mm2s_cmd_tready_o    ),

  // AXIS master MM2S_STS - status interface
  .m_axis_mm2s_sts_tdata   ( m_axis_mm2s_sts_tdata_o     ),
  .m_axis_mm2s_sts_tkeep   ( m_axis_mm2s_sts_tkeep_o     ),
  .m_axis_mm2s_sts_tlast   ( m_axis_mm2s_sts_tlast_o     ),
  .m_axis_mm2s_sts_tvalid  ( m_axis_mm2s_sts_tvalid_o    ),
  .m_axis_mm2s_sts_tready  ( m_axis_mm2s_sts_tready_i    ),

  .mm2s_err                ( mm2s_err_o                  )
);

assign S_AXI_HP0_arlock_o    =  2'b00;
assign S_AXI_HP0_arqos_o     =  4'b0000;
assign S_AXI_HP0_aruser_o[4] =  1'b0;

assign S_AXI_HP0_awaddr_o    = 32'h0;
assign S_AXI_HP0_awburst_o   =  2'h0;
assign S_AXI_HP0_awcache_o   =  4'h0;
assign S_AXI_HP0_awid_o      =  6'h0;
assign S_AXI_HP0_awlen_o     =  4'h0;
assign S_AXI_HP0_awlock_o    =  2'h0;
assign S_AXI_HP0_awprot_o    =  3'h0;
assign S_AXI_HP0_awqos_o     =  4'h0;
assign S_AXI_HP0_awsize_o    =  3'h0;
assign S_AXI_HP0_awuser_o    =  5'b0;
assign S_AXI_HP0_awvalid_o   =  1'b0;
assign S_AXI_HP0_wdata_o     = 64'h0;
assign S_AXI_HP0_wid_o       =  6'h0;
assign S_AXI_HP0_wlast_o     =  1'b0;
assign S_AXI_HP0_wstrb_o     =  8'h0;
assign S_AXI_HP0_wvalid_o    =  1'b0;
assign S_AXI_HP0_bready_o    =  1'b0;


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
   m_axis_mm2s_tready_i <= 1'b0;
else if (!mm2s_err_o && (fifo_wr_count_i < 9'h1E0))
   m_axis_mm2s_tready_i <= 1'b1;
else
   m_axis_mm2s_tready_i <= 1'b0;

always @(posedge clk_i)
if (!rstn_i) begin
   fifo_wr_in_o        <= 32'b0;
   fifo_wr_en_o        <=  1'b0;
   end
else if (m_axis_mm2s_tvalid_o && m_axis_mm2s_tready_i) begin
   fifo_wr_en_o        <= 1'b1;
   fifo_wr_in_o        <= m_axis_mm2s_tdata_o;
   dbg_axi_last_data_o <= m_axis_mm2s_tdata_o;
   dbg_clock_last_o    <= masterclock_i[31:0];
   end
else
   fifo_wr_en_o        <= 1'b0;


/* CMD */
always @(posedge clk_i)
if (!rstn_i) begin
   cmd_running              <=  1'b0;
   cmd_tag                  <=  4'h0;
   cmd_start_addr           <= 32'h0;
   cmd_eof                  <=  1'b0;
   cmd_btt                  <= 23'b0;
   s_axis_mm2s_cmd_tvalid_i <=  1'b0;
   end
else begin
   if (!cmd_running && s_axis_mm2s_cmd_tready_o && sha256_rdy_i && dma_enable_i && dma_start_i) begin
      cmd_running              <= 1'b1;
      cmd_start_addr           <= dma_base_addr_i;
      cmd_eof                  <= 1'b1;
      cmd_btt                  <= (|dma_bit_len_i[2:0]) ?  (dma_bit_len_i[25:3] + 23'd1) : dma_bit_len_i[25:3];
      cmd_tag                  <= cmd_tag + 4'h1;
      s_axis_mm2s_cmd_tvalid_i <= 1'b1;
      end
   else if (cmd_running && s_axis_mm2s_cmd_tready_o && s_axis_mm2s_cmd_tvalid_i) begin
      s_axis_mm2s_cmd_tvalid_i <= 1'b0;
      dbg_clock_start_o        <= masterclock_i[31:0];
      end
   else if (cmd_running && !dma_start_i && m_axis_mm2s_tlast_o) begin
// else if (cmd_running && !dma_start_i && (sts_dec_tag == cmd_tag)) begin  // HINT: no! transaction finishes before streamed data has completed
      dbg_clock_stop_o         <= masterclock_i[31:0];
      cmd_running              <= 1'b0;
      end
   else if (cmd_running && !dma_enable_i) begin
      s_axis_mm2s_cmd_tvalid_i <= 1'b0;
      dbg_clock_stop_o         <= masterclock_i[31:0];
      cmd_running              <= 1'b0;
      end
   end

//                                 bufferable, non-cacheable
//                                 CACHE  , XUSER, RSVD, TAG         , START ADDRES        , DRR , EOF    , DSA , INCR, BTT
assign s_axis_mm2s_cmd_tdata_i = { 4'b0001,  4'h0, 4'h0, cmd_tag[3:0], cmd_start_addr[31:0], 1'b1, cmd_eof, 6'h0, 1'b1, cmd_btt[22:0]};

// debugging
assign dbg_axi_r_state_o = { 4'b0, cmd_tag[3:0],  4'b0, s_axis_mm2s_cmd_tvalid_i, s_axis_mm2s_cmd_tready_o, cmd_running, dma_start_i,  cmd_start_addr[15:0] };
assign dbg_axi_w_state_o = { 32'b0 };


/* STS */
always @(posedge clk_i)
if (!rstn_i)
   m_axis_mm2s_sts_tready_i <= 1'b0;
else
   m_axis_mm2s_sts_tready_i <= 1'b1;

always @(posedge clk_i)
if (!rstn_i) begin
   dbg_sts  <= 8'b0;
   sts_last <= 8'b0;
   end
else begin
   if (m_axis_mm2s_sts_tvalid_o && m_axis_mm2s_sts_tready_i) begin
      dbg_sts  <= m_axis_mm2s_sts_tdata_o;
      sts_last <= m_axis_mm2s_sts_tdata_o;
      end
   else
      dbg_sts  <= 8'b0;                                     // current status value only valid for one clock

   if (s_axis_mm2s_cmd_tready_o && s_axis_mm2s_cmd_tvalid_i)
      sts_last <= 8'b0;                                     // reset when new command is sent
   end

assign sts_dec_tag       = sts_last[3:0];
assign sts_dec_interr    = sts_last[4];
assign sts_dec_decerr    = sts_last[5];
assign sts_dec_slverr    = sts_last[6];
assign sts_dec_ok        = sts_last[7];

assign dma_in_progress_o = cmd_running;

assign dbg_state_o       = sts_last;


endmodule: dma_engine
