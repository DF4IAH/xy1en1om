`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DF4IAH-Solutions
// Engineer: Ulrich Habel, DF4IAH
//
// Create Date: 29.05.2016 20:33:43
// Design Name: sha3
// Module Name: regs
// Project Name: xy1en1om
// Target Devices: xc7z010clg400-1
// Tool Versions: Vivado 2015.4
// Description: PS to PL register access
//
// Dependencies: Hardware RedPitaya V1.1 board, Software RedPitaya image with uboot and Ubuntu partition
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module regs #(
  // parameter RSZ = 14  // RAM size 2^RSZ
)(
  // clock & reset
  input      [  3: 0] clks_i               ,  // clocks
  input      [  3: 0] rstsn_i              ,  // clock reset lines - active low

  // activation
  output              x11_activated_o      ,  // x11 sub-module is activated

  // System bus - slave
  input      [ 31: 0] sys_addr_i           ,  // bus saddress
  input      [ 31: 0] sys_wdata_i          ,  // bus write data
  input      [  3: 0] sys_sel_i            ,  // bus write byte select
  input               sys_wen_i            ,  // bus write enable
  input               sys_ren_i            ,  // bus read enable
  output reg [ 31: 0] sys_rdata_o          ,  // bus read data
  output reg          sys_err_o            ,  // bus error indicator
  output reg          sys_ack_o            ,  // bus acknowledge signal

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

  // AXI streaming master from XADC
  input               xadc_axis_aclk_i     ,  // AXI-streaming from the XADC, clock from the AXI-S FIFO
  input      [ 15: 0] xadc_axis_tdata_i    ,  // AXI-streaming from the XADC, data
  input      [  4: 0] xadc_axis_tid_i      ,  // AXI-streaming from the XADC, analog data source channel for this data
                                                // TID=0x10:VAUXp0_VAUXn0 & TID=0x18:VAUXp8_VAUXn8, TID=0x11:VAUXp1_VAUXn1 & TID=0x19:VAUXp9_VAUXn9, TID=0x03:Vp_Vn
  output reg          xadc_axis_tready_o   ,  // AXI-streaming from the XADC, slave indicating ready for data
  input               xadc_axis_tvalid_i   ,  // AXI-streaming from the XADC, data transfer valid

  input      [ 31: 0] masterclock_i             // masterclock progress with each 125 MHz tick and starts after release of reset
);


// === CONST: OMNI section ===

//---------------------------------------------------------------------------------
// current date of compilation

localparam CURRENT_DATE = 32'h16082811;         // current date: 0xYYMMDDss - YY=year, MM=month, DD=day, ss=serial from 0x01 .. 0x09, 0x10, 0x11 .. 0x99


//---------------------------------------------------------------------------------
//  Registers accessed by the system bus

enum {
    /* OMNI section */
    REG_RW_CTRL                           =  0, // h000: xy1en1om control register
//  REG_RD_STATUS,                              // h004: xy1en1om status register
//  REG_RD_VERSION,                             // h00C: FPGA version information

    /* SHA256 section */
    REG_RW_SHA256_CTRL,                         // h100: SHA256 submodule control register
//  REG_RD_SHA256_STATUS,                       // h104: SHA256 submodule status register
//  REG_WR_SHA256_DATA_PUSH,                    // h10C: SHA256 submodule data push in FIFO
    REG_RD_SHA256_HASH_H7,                      // h110: SHA256 submodule hash out H7, LSB
    REG_RD_SHA256_HASH_H6,                      // h114: SHA256 submodule hash out H6
    REG_RD_SHA256_HASH_H5,                      // h118: SHA256 submodule hash out H5
    REG_RD_SHA256_HASH_H4,                      // h11C: SHA256 submodule hash out H4
    REG_RD_SHA256_HASH_H3,                      // h120: SHA256 submodule hash out H3
    REG_RD_SHA256_HASH_H2,                      // h124: SHA256 submodule hash out H2
    REG_RD_SHA256_HASH_H1,                      // h128: SHA256 submodule hash out H1
    REG_RD_SHA256_HASH_H0,                      // h12C: SHA256 submodule hash out H0, MSB
//  REG_RD_SHA256_FIFO_WR_COUNT,                // h130: SHA256 FIFO stack count, at most this number of items are in the FIFO
//  REG_RD_SHA256_FIFO_RD_COUNT,                // h134: SHA256 FIFO stack count, at least this number of items can be pulled from the FIFO
    REG_RW_SHA256_DMA_BASE_ADDR,                // h140: SHA256 DMA byte base address, bits [1:0] always 0 (32 bit alignment)
    REG_RW_SHA256_DMA_BIT_LEN,                  // h144: SHA256 submodule number of data bits to be hashed, bits [4:0] always 0 (32 bit alignment)
    REG_RW_SHA256_DMA_NONCE_OFS,                // h148: SHA256 offset location of the 32 bit nonce value for the autoincrementer, bits [4:0] always 0 (32 bit alignment)

    /* KECCAK512 section */
/*
    REG_RW_KECCAK512_CTRL,                      // h200: KECCAK512 submodule control register
//  REG_RD_KECCAK512_STATUS,                    // h204: KECCAK512 submodule status register
*/

    REG_COUNT
} REG_ENUMS;

enum {
    CTRL_ENABLE                           =  0, // enabling the xy1en1om sub-module
    CTRL_RSVD_D01,
    CTRL_RSVD_D02,
    CTRL_RSVD_D03,

    CTRL_RSVD_D04,
    CTRL_RSVD_D05,
    CTRL_RSVD_D06,
    CTRL_RSVD_D07,

    CTRL_RSVD_D08,
    CTRL_RSVD_D09,
    CTRL_RSVD_D10,
    CTRL_RSVD_D11,

    CTRL_RSVD_D12,
    CTRL_RSVD_D13,
    CTRL_RSVD_D14,
    CTRL_RSVD_D15,

    CTRL_RSVD_D16,
    CTRL_RSVD_D17,
    CTRL_RSVD_D18,
    CTRL_RSVD_D19,

    CTRL_RSVD_D20,
    CTRL_RSVD_D21,
    CTRL_RSVD_D22,
    CTRL_RSVD_D23,

    CTRL_RSVD_D24,
    CTRL_RSVD_D25,
    CTRL_RSVD_D26,
    CTRL_RSVD_D27,

    CTRL_RSVD_D28,
    CTRL_RSVD_D29,
    CTRL_RSVD_D30,
    CTRL_RSVD_D31
} CTRL_BITS_ENUM;


// === CONST: SHA256 section ===

enum {
    SHA256_CTRL_ENABLE                    =  0, // SHA256: reset engine
    SHA256_CTRL_RESET,
    SHA256_CTRL_RSVD_D02,
    SHA256_CTRL_RSVD_D03,

    SHA256_CTRL_DBL_HASH,
    SHA256_CTRL_DMA_MODE,
    SHA256_CTRL_DMA_MULTIHASH,
    SHA256_CTRL_DMA_START,

    SHA256_CTRL_RSVD_D08,
    SHA256_CTRL_RSVD_D09,
    SHA256_CTRL_RSVD_D10,
    SHA256_CTRL_RSVD_D11,

    SHA256_CTRL_RSVD_D12,
    SHA256_CTRL_RSVD_D13,
    SHA256_CTRL_RSVD_D14,
    SHA256_CTRL_RSVD_D15,

    SHA256_CTRL_RSVD_D16,
    SHA256_CTRL_RSVD_D17,
    SHA256_CTRL_RSVD_D18,
    SHA256_CTRL_RSVD_D19,

    SHA256_CTRL_RSVD_D20,
    SHA256_CTRL_RSVD_D21,
    SHA256_CTRL_RSVD_D22,
    SHA256_CTRL_RSVD_D23,

    SHA256_CTRL_RSVD_D24,
    SHA256_CTRL_RSVD_D25,
    SHA256_CTRL_RSVD_D26,
    SHA256_CTRL_RSVD_D27,

    SHA256_CTRL_RSVD_D28,
    SHA256_CTRL_RSVD_D29,
    SHA256_CTRL_RSVD_D30,
    SHA256_CTRL_RSVD_D31
} SHA256_CTRL_BITS_ENUM;


// === CONST: KEK512 section ===

/*
enum {
    KEK512_CTRL_ENABLE                    =  0, // KEK512: reset engine
    KEK512_CTRL_RESET,
    KEK512_CTRL_RSVD_D02,
    KEK512_CTRL_RSVD_D03,

    KEK512_CTRL_RSVD_D04,
    KEK512_CTRL_RSVD_D05,
    KEK512_CTRL_RSVD_D06,
    KEK512_CTRL_RSVD_D07,

    KEK512_CTRL_RSVD_D08,
    KEK512_CTRL_RSVD_D09,
    KEK512_CTRL_RSVD_D10,
    KEK512_CTRL_RSVD_D11,

    KEK512_CTRL_RSVD_D12,
    KEK512_CTRL_RSVD_D13,
    KEK512_CTRL_RSVD_D14,
    KEK512_CTRL_RSVD_D15,

    KEK512_CTRL_RSVD_D16,
    KEK512_CTRL_RSVD_D17,
    KEK512_CTRL_RSVD_D18,
    KEK512_CTRL_RSVD_D19,

    KEK512_CTRL_RSVD_D20,
    KEK512_CTRL_RSVD_D21,
    KEK512_CTRL_RSVD_D22,
    KEK512_CTRL_RSVD_D23,

    KEK512_CTRL_RSVD_D24,
    KEK512_CTRL_RSVD_D25,
    KEK512_CTRL_RSVD_D26,
    KEK512_CTRL_RSVD_D27,

    KEK512_CTRL_RSVD_D28,
    KEK512_CTRL_RSVD_D29,
    KEK512_CTRL_RSVD_D30,
    KEK512_CTRL_RSVD_D31
} KEK512_CTRL_BITS_ENUM;
*/


// === NET: X11 - OMNI section ===

reg          [ 31:0]     regs[REG_COUNT];                   // registers to be accessed by the system bus

wire                     bus_clk             = clks_i[0];   // 125.0 MHz;
wire                     bus_rstn            = rstsn_i[0];

wire                     x11_enable          = regs[REG_RW_CTRL][CTRL_ENABLE];
wire         [ 31:0]     status;


// === NET: SHA256 section ===

wire                     sha256_clk          = clks_i[2];   // 62.5 MHz
wire                     sha256_rstn         = rstsn_i[2];
wire                     sha256_enable       = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_ENABLE] &  x11_enable;
wire                     sha256_reset_pulse  = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_RESET]  | !x11_enable;
wire                     sha256_dbl_hash     = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DBL_HASH];
wire                     sha256_dma_mode     = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DMA_MODE];
wire                     sha256_dma_multihash= regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DMA_MULTIHASH];
wire                     sha256_dma_start    = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DMA_START];
wire         [ 31:0]     sha256_dma_base_addr= regs[REG_RW_SHA256_DMA_BASE_ADDR];
wire         [ 25:0]     sha256_dma_bit_len  = regs[REG_RW_SHA256_DMA_BIT_LEN][25:0];
wire         [ 31:0]     sha256_dma_nonce_ofs= regs[REG_RW_SHA256_DMA_NONCE_OFS];

wire         [ 31:0]     sha256_status;
wire                     sha256_rdy;

reg                      sha256_port_fifo_wr_en = 'b0;
reg          [ 31:0]     sha256_port_fifo_wr_in = 'b0;

wire                     sha256_dma_fifo_wr_en;
wire         [ 31:0]     sha256_dma_fifo_wr_in;

wire                     sha256_32b_fifo_wr_en;
wire         [ 31:0]     sha256_32b_fifo_wr_in;
wire                     sha256_fifo_m1full;
wire                     sha256_fifo_full;
wire         [  8:0]     sha256_fifo_wr_count;

wire                     sha256_32b_fifo_rd_en;
wire         [ 31:0]     sha256_32b_fifo_rd_out;
wire                     sha256_32b_fifo_rd_vld;
wire                     sha256_fifo_empty;
wire         [  8:0]     sha256_fifo_rd_count;

wire                     sha256_dma_in_progress;

reg                      sha256_start = 'b0;
wire                     sha256_hash_valid;
wire         [255:0]     sha256_hash_data;

// debugging DMA engine
wire         [ 31:0]     sha256_dma_clock_start;
wire         [ 31:0]     sha256_dma_clock_last;
wire         [ 31:0]     sha256_dma_clock_stop;
wire         [ 31:0]     sha256_eng_clock_complete;
wire         [ 31:0]     sha256_eng_clock_finish;
wire         [  7:0]     sha256_dma_state;
wire         [ 31:0]     sha256_dma_axi_r_state;
wire         [ 31:0]     sha256_dma_axi_w_state;
wire         [ 31:0]     sha256_dma_last_data;
reg          [ 31:0]     sha256_fifo_read_last = 32'b0;
reg                      dbg_fifo_read_next    =  1'b0;



// === NET: KECCAK512 section ===

/*
wire                     kek512_clk          = clks[0];     // 125.0 MHz
wire                     kek512_rstn         = rstsn[0];
wire                     kek512_enable       = regs[REG_RW_KECCAK512_CTRL][KEK512_CTRL_ENABLE] &  x11_enable;
wire                     kek512_reset        = regs[REG_RW_KECCAK512_CTRL][KEK512_CTRL_RESET]  | !x11_enable;

wire         [ 31:0]     kek512_status;
wire                     kek512_rdy;                        // keccak engine is ready to feed and/or to read-out

reg          [ 63:0]     kek512_in[25]  = '{25{0}};         // feeding keccak engine
reg                      kek512_start   = 'b0;              // start keccak engine
wire         [ 63:0]     kek512_out[25];                    // result of keccak engine
*/


// === IMPL: X11 - OMNI section ===

assign        x11_activated_o = x11_enable;


//---------------------------------------------------------------------------------
//  regs sub-module activation

wire          bus_sha256_reset_n;
red_pitaya_rst_clken i_rst_clken_sha256_bus (
  // global signals
  .clk_i                   ( bus_clk                     ), // clock 125.0 MHz
  .rstn_i                  ( bus_rstn                    ), // clock reset - active low

  // input signals
  .enable_i                ( sha256_enable & !sha256_reset_pulse ),

  // output signals
  .clk_en_o                (                             ),
  .reset_n_o               ( bus_sha256_reset_n          )
);

wire          sha256_clk_en;
wire          sha256_reset_n;
red_pitaya_rst_clken i_rst_clken_sha256 (
  // global signals
  .clk_i                   ( sha256_clk                  ), // clock 62.5 MHz
  .rstn_i                  ( sha256_rstn                 ), // clock reset - active low

  // input signals
  .enable_i                ( sha256_enable & !sha256_reset_pulse ),

  // output signals
  .clk_en_o                ( sha256_clk_en               ),
  .reset_n_o               ( sha256_reset_n              )
);
wire          sha256_activated = sha256_reset_n;

/*
wire          kek512_clk_en;
wire          kek512_reset_n;
red_pitaya_rst_clken i_rst_clken_kek512 (
  // global signals
  .clk_i                   ( kek512_clk                  ), // clock 125.0 MHz
  .rstn_i                  ( kek512_rstn                 ), // clock reset - active low

  // input signals
  .enable_i                ( kek512_enable               ),

  // output signals
  .clk_en_o                ( kek512_clk_en               ),
  .reset_n_o               ( kek512_reset_n              )
);

wire          kek512_activated = kek512_reset_n;
*/

assign status = { 20'b0,  3'b0 , 1'b0 /*kek512_activated*/,  3'b0, sha256_activated,  3'b0, x11_activated_o };


// AXIS
assign xadc_axis_tready_o = 1'b0;

// AXI masters
assign axi1_clk_o    = bus_clk;
assign axi1_rstn_o   = bus_rstn;
assign axi1_waddr_o  = 32'b0;
assign axi1_wdata_o  = 64'b0;
assign axi1_wsel_o   =  8'b0;
assign axi1_wvalid_o =  1'b0;
assign axi1_wlen_o   =  4'b0;
assign axi1_wfixed_o =  1'b0;
assign axi1_raddr_o  = 32'b0;
assign axi1_rvalid_o =  1'b0;
assign axi1_rsel_o   =  8'b0;
assign axi1_rlen_o   =  4'b0;
assign axi1_rfixed_o =  1'b0;


// === IMPL: SHA256 section ===

reg    sha256_hash_valid_d;

always @(posedge sha256_clk)
if (!sha256_reset_n) begin
   regs[REG_RD_SHA256_HASH_H0] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H1] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H2] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H3] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H4] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H5] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H6] <= 32'b0;
   regs[REG_RD_SHA256_HASH_H7] <= 32'b0;
   sha256_hash_valid_d <= 1'b0;
   end
else if (!sha256_hash_valid_d && sha256_hash_valid) begin
   regs[REG_RD_SHA256_HASH_H0] <= sha256_hash_data[7*32+:32];
   regs[REG_RD_SHA256_HASH_H1] <= sha256_hash_data[6*32+:32];
   regs[REG_RD_SHA256_HASH_H2] <= sha256_hash_data[5*32+:32];
   regs[REG_RD_SHA256_HASH_H3] <= sha256_hash_data[4*32+:32];
   regs[REG_RD_SHA256_HASH_H4] <= sha256_hash_data[3*32+:32];
   regs[REG_RD_SHA256_HASH_H5] <= sha256_hash_data[2*32+:32];
   regs[REG_RD_SHA256_HASH_H6] <= sha256_hash_data[1*32+:32];
   regs[REG_RD_SHA256_HASH_H7] <= sha256_hash_data[0*32+:32];
   sha256_hash_valid_d <= sha256_hash_valid;
   end
else
   sha256_hash_valid_d <= sha256_hash_valid;


dma_engine i_dma_engine (
  // global signals
  .clk_i                   ( bus_clk                     ),  // clock 125.0 MHz
  .rstn_i                  ( bus_sha256_reset_n          ),  // SHA256 enabled clock reset - active low

  .dma_enable_i            ( sha256_dma_mode             ),  // 1 = DMA mode, 0 = FIFO mode
  .dma_base_addr_i         ( sha256_dma_base_addr        ),  // DMA byte base address, bits [1:0] always 0 (32 bit alignment)
  .dma_bit_len_i           ( sha256_dma_bit_len          ),  // submodule number of data bits to be hashed, bits [4:0] always 0 (32 bit alignment)
  .dma_start_i             ( sha256_dma_start            ),  // start flag of the DMA engine, that flag is auto-clearing

  .sha256_rdy_i            ( sha256_rdy                  ),

  // AXI_HP0 master
  .S_AXI_HP0_aclk_o        ( S_AXI_HP0_aclk_o            ),
  .S_AXI_HP0_araddr_o      ( S_AXI_HP0_araddr_o          ),
  .S_AXI_HP0_arburst_o     ( S_AXI_HP0_arburst_o         ),
  .S_AXI_HP0_arcache_o     ( S_AXI_HP0_arcache_o         ),
  .S_AXI_HP0_arid_o        ( S_AXI_HP0_arid_o            ),
  .S_AXI_HP0_arlen_o       ( S_AXI_HP0_arlen_o           ),
  .S_AXI_HP0_arlock_o      ( S_AXI_HP0_arlock_o          ),
  .S_AXI_HP0_arprot_o      ( S_AXI_HP0_arprot_o          ),
  .S_AXI_HP0_arqos_o       ( S_AXI_HP0_arqos_o           ),
  .S_AXI_HP0_arready_i     ( S_AXI_HP0_arready_i         ),
  .S_AXI_HP0_arsize_o      ( S_AXI_HP0_arsize_o          ),
  .S_AXI_HP0_aruser_o      ( S_AXI_HP0_aruser_o          ),
  .S_AXI_HP0_arvalid_o     ( S_AXI_HP0_arvalid_o         ),
  .S_AXI_HP0_awaddr_o      ( S_AXI_HP0_awaddr_o          ),
  .S_AXI_HP0_awburst_o     ( S_AXI_HP0_awburst_o         ),
  .S_AXI_HP0_awcache_o     ( S_AXI_HP0_awcache_o         ),
  .S_AXI_HP0_awid_o        ( S_AXI_HP0_awid_o            ),
  .S_AXI_HP0_awlen_o       ( S_AXI_HP0_awlen_o           ),
  .S_AXI_HP0_awlock_o      ( S_AXI_HP0_awlock_o          ),
  .S_AXI_HP0_awprot_o      ( S_AXI_HP0_awprot_o          ),
  .S_AXI_HP0_awqos_o       ( S_AXI_HP0_awqos_o           ),
  .S_AXI_HP0_awready_i     ( S_AXI_HP0_awready_i         ),
  .S_AXI_HP0_awsize_o      ( S_AXI_HP0_awsize_o          ),
  .S_AXI_HP0_awuser_o      ( S_AXI_HP0_awuser_o          ),
  .S_AXI_HP0_awvalid_o     ( S_AXI_HP0_awvalid_o         ),
  .S_AXI_HP0_bid_i         ( S_AXI_HP0_bid_i             ),
  .S_AXI_HP0_bready_o      ( S_AXI_HP0_bready_o          ),
  .S_AXI_HP0_bresp_i       ( S_AXI_HP0_bresp_i           ),
  .S_AXI_HP0_bvalid_i      ( S_AXI_HP0_bvalid_i          ),
  .S_AXI_HP0_rdata_i       ( S_AXI_HP0_rdata_i           ),
  .S_AXI_HP0_rid_i         ( S_AXI_HP0_rid_i             ),
  .S_AXI_HP0_rlast_i       ( S_AXI_HP0_rlast_i           ),
  .S_AXI_HP0_rready_o      ( S_AXI_HP0_rready_o          ),
  .S_AXI_HP0_rresp_i       ( S_AXI_HP0_rresp_i           ),
  .S_AXI_HP0_rvalid_i      ( S_AXI_HP0_rvalid_i          ),
  .S_AXI_HP0_wdata_o       ( S_AXI_HP0_wdata_o           ),
  .S_AXI_HP0_wid_o         ( S_AXI_HP0_wid_o             ),
  .S_AXI_HP0_wlast_o       ( S_AXI_HP0_wlast_o           ),
  .S_AXI_HP0_wready_i      ( S_AXI_HP0_wready_i          ),
  .S_AXI_HP0_wstrb_o       ( S_AXI_HP0_wstrb_o           ),
  .S_AXI_HP0_wvalid_o      ( S_AXI_HP0_wvalid_o          ),

  .fifo_wr_en_o            ( sha256_dma_fifo_wr_en       ),
  .fifo_wr_in_o            ( sha256_dma_fifo_wr_in       ),
  .fifo_wr_count_i         ( sha256_fifo_wr_count        ),

  .dma_in_progress_o       ( sha256_dma_in_progress      ),

  .masterclock_i           ( masterclock_i[31:0]         ), // masterclock progress with each 125 MHz tick and starts after release of reset

  .dbg_clock_start_o       ( sha256_dma_clock_start      ),
  .dbg_clock_last_o        ( sha256_dma_clock_last       ),
  .dbg_clock_stop_o        ( sha256_dma_clock_stop       ),
  .dbg_state_o             ( sha256_dma_state            ),
  .dbg_axi_r_state_o       ( sha256_dma_axi_r_state      ),
  .dbg_axi_w_state_o       ( sha256_dma_axi_w_state      ),
  .dbg_axi_last_data_o     ( sha256_dma_last_data        )
);

// FIFO input MUX for DMA access or push()
assign sha256_32b_fifo_wr_en = sha256_dma_mode ?  sha256_dma_fifo_wr_en : sha256_port_fifo_wr_en;
assign sha256_32b_fifo_wr_in = sha256_dma_mode ?  sha256_dma_fifo_wr_in : sha256_port_fifo_wr_in;

fifo_32i_32o_512d i_fifo_32i_32o (
  .rst                     ( !sha256_reset_n             ), // reset active high
  .wr_clk                  ( bus_clk                     ), // clock 125.0 MHz
  .rd_clk                  ( sha256_clk  /*bus_clk*/     ), // clock  62.5 MHz

  .wr_en                   ( sha256_32b_fifo_wr_en       ), // write signal to push into the FIFO
  .din                     ( sha256_32b_fifo_wr_in       ), // 32 bit word in
  .almost_full             ( sha256_fifo_m1full          ), // FIFO does except one more write access
  .full                    ( sha256_fifo_full            ), // FIFO would spill over by next write access
  .wr_data_count           ( sha256_fifo_wr_count        ), // at least this number of entries are pushed on the FIFO

  .rd_en                   ( sha256_32b_fifo_rd_en  /*dbg_fifo_read_next*/), // enable reading from the FIFO
  .valid                   ( sha256_32b_fifo_rd_vld      ), // read data is valid
  .dout                    ( sha256_32b_fifo_rd_out      ), // 32 bit word out for the SHA-256 engine to process
  .empty                   ( sha256_fifo_empty           ), // FIFO does not contain any data
  .rd_data_count           ( sha256_fifo_rd_count        )  // at most this number of entries can be pulled from the FIFO
);


sha256_engine i_sha256_engine (
  // global signals
  .clk_i                   ( sha256_clk                  ), // clock 62.5 MHz
  .rstn_i                  ( sha256_reset_n              ), // clock reset - active low

  .ready_o                 ( sha256_rdy                  ), // sha256 engine ready to start
  .start_i                 ( sha256_start                ), // start engine

//.sha256_nonce_ofs_i      ( sha256_nonce_ofs            ), // offset of nonce value address in bit count on word boundary [4:0] = 0
//.sha256_bit_len_i        ( sha256_bit_len              ), // count of bits on byte boundary [2:0] = 0
//.sha256_multihash_i      ( sha256_multihash            ), // 1 = re-do automatic enabled with nonce incrementation
  .sha256_dbl_hash_i       ( sha256_dbl_hash             ), // do a sha256(sha256(x)) operation

  .fifo_empty_i            ( sha256_fifo_empty           ), // indicator for continuation with next block
  .fifo_rd_en_o            ( sha256_32b_fifo_rd_en       ), // enable reading of the FIFO
  .fifo_rd_vld_i           ( sha256_32b_fifo_rd_vld      ), // read data from the FIFO is valid
  .fifo_rd_dat_i           ( sha256_32b_fifo_rd_out      ), // 32 bit word out of the FIFO for the SHA-256 engine to process

  .dma_in_progress_i       ( sha256_dma_in_progress      ), // DMA process is running and has not completed now

  .valid_o                 ( sha256_hash_valid           ), // hash output vector is valid
  .hash_o                  ( sha256_hash_data            ), // computated hash value

  .masterclock_i           ( masterclock_i[31:0]         ), // masterclock progress with each 125 MHz tick and starts after release of reset 

  .dbg_clock_complete_o    ( sha256_eng_clock_complete   ),
  .dbg_clock_finish_o      ( sha256_eng_clock_finish     )
);

always @(posedge sha256_clk)
if (!sha256_reset_n)
   sha256_start <= 1'b0;
else if (!sha256_fifo_empty && sha256_rdy)
   sha256_start <= 1'b1;
else
   sha256_start <= 1'b0;

assign sha256_status = { 24'b0,  1'b0, sha256_fifo_full, sha256_fifo_m1full, sha256_fifo_empty,  1'b0, sha256_dma_in_progress, sha256_hash_valid, sha256_rdy };

always @(posedge sha256_clk)
if (!sha256_reset_n)
   sha256_fifo_read_last <= 32'b0;
else if (sha256_32b_fifo_rd_vld)
   sha256_fifo_read_last <= sha256_32b_fifo_rd_out;


// === IMPL: KECCAK512 section ===
/*
keccak_f1600_round i_keccak_f1600_round (
  // global signals
  .clk_i                   ( kek512_clk                  ),  // clock 125 MHz
  .rstn_i                  ( kek512_reset_n              ),  // clock reset - active low

  .ready_o                 ( kek512_rdy                  ),  // 1: ready to fill and read out
  .vec_i                   ( kek512_in                   ),  // 1600 bit data input
  .start                   ( kek512_start                ),  // 1: starting the function
  .vec_o                   ( kek512_out                  )   // 1600 bit data output
);

assign kek512_status = { 32'b0 };
*/


// === BUS: OMNI section ===

//---------------------------------------------------------------------------------
//  System bus connection

// WRITE access to the registers
always @(posedge bus_clk)
if (!bus_rstn) begin
  regs[REG_RW_CTRL]                               <= 32'b0;
  regs[REG_RW_SHA256_CTRL]                        <= 32'b0;
  regs[REG_RW_SHA256_DMA_BASE_ADDR]               <= 32'b0;
  regs[REG_RW_SHA256_DMA_BIT_LEN]                 <= 32'b0;
  regs[REG_RW_SHA256_DMA_NONCE_OFS]               <= 32'b0;
//regs[REG_RW_KECCAK512_CTRL]                     <= 32'b0;

  sha256_port_fifo_wr_en                          <= 'b0;
//kek512_in                                       <= '{25{0}};
//kek512_start                                    <= 'b0;
  end

else begin
  regs[REG_RW_SHA256_CTRL] <= regs[REG_RW_SHA256_CTRL] & ~(32'h00000082);  // mask out one-shot flags (DMA_START, RESET)
  sha256_port_fifo_wr_en <= 1'b0;
//kek512_start <= 1'b0;

  if (sys_wen_i) begin
    casez (sys_addr_i[19:0])

    /* OMNI section */

    20'h00000: begin
      regs[REG_RW_CTRL]                           <= sys_wdata_i[31:0];
      end


    /* SHA256 section */

    20'h00100: begin
      regs[REG_RW_SHA256_CTRL]                    <= sys_wdata_i[31:0];
      end
/*  20'h00108: begin
      regs[REG_RW_SHA256_BIT_LEN]                 <= sys_wdata[31:0];
      end */
    20'h0010C: begin
      sha256_port_fifo_wr_in[31:0]                <= sys_wdata_i[31:0];
      sha256_port_fifo_wr_en <= 1'b1;
      end

    20'h00140: begin
      regs[REG_RW_SHA256_DMA_BASE_ADDR]           <= sys_wdata_i[31:0];
      end

    20'h00144: begin
      regs[REG_RW_SHA256_DMA_BIT_LEN]             <= sys_wdata_i[31:0];
      end

    20'h00148: begin
      regs[REG_RW_SHA256_DMA_NONCE_OFS]           <= sys_wdata_i[31:0];
      end


    /* KECCAK512 section */

/*
    20'h00200: begin
      regs[REG_RW_KECCAK512_CTRL]                 <= sys_wdata_i[31:0];
      end

    20'h100zz: begin
      if ((sys_addr & 20'hFF) < 8'd26) begin
        kek512_in[sys_addr & 8'hF]                <= sys_wdata_i;
        kek512_start <= 1'b1;
        end
    end
*/

    default:   begin
    end

    endcase
    end
  end


wire sys_en;
assign sys_en = sys_wen_i | sys_ren_i;

// READ access to the registers
always @(posedge bus_clk)
if (!bus_rstn) begin
  sys_err_o      <= 1'b0;
  sys_ack_o      <= 1'b0;
  sys_rdata_o    <= 32'h00000000;
  dbg_fifo_read_next <= 1'b0;
  end

else begin
  dbg_fifo_read_next <= 1'b0;

  sys_err_o <= 1'b0;
  if (sys_ren_i) begin
    casez (sys_addr_i[19:0])

    /* OMNI section */

    20'h00000: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RW_CTRL];
      end
    20'h00004: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= status;
      end
    20'h0000C: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= CURRENT_DATE;
      end


    /* SHA256 section */

    20'h00100: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RW_SHA256_CTRL];
      end
    20'h00104: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_status;
      end

    20'h0010C: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_fifo_read_last;
      dbg_fifo_read_next <= 1'b1;
      end

    20'h00110: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H7];
      end
    20'h00114: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H6];
      end
    20'h00118: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H5];
      end
    20'h0011C: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H4];
      end
    20'h00120: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H3];
      end
    20'h00124: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H2];
      end
    20'h00128: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H1];
      end
    20'h0012C: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RD_SHA256_HASH_H0];
      end

    20'h00130: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= { 23'b0, sha256_fifo_wr_count[8:0] };
      end
    20'h00134: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= { 23'b0, sha256_fifo_rd_count[8:0] };
      end

    20'h00140: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RW_SHA256_DMA_BASE_ADDR];
      end
    20'h00144: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= { 6'b0, regs[REG_RW_SHA256_DMA_BIT_LEN][25:0] };
      end
    20'h00148: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RW_SHA256_DMA_NONCE_OFS];
      end

    20'h00150: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= { 24'b0, sha256_dma_state[7:0] };
      end
    20'h00154: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_dma_axi_r_state;
      end
    20'h00158: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_dma_axi_w_state;
      end
    20'h0015C: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_dma_last_data;
      end
    20'h00160: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_dma_clock_start;
      end
    20'h00164: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_dma_clock_last;
      end
    20'h00168: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_dma_clock_stop;
      end
    20'h0016C: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_eng_clock_complete;
      end
    20'h00170: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= sha256_eng_clock_finish;
      end


    /* KECCAK512 section */

/*
    20'h00200: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= regs[REG_RW_KECCAK512_CTRL];
      end
    20'h00204: begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= kek512_status;
      end

    20'h100zz: begin
      sys_ack_o <= sys_en;
      if ((sys_addr_i & 20'hFF) < 8'd26)
        sys_rdata_o <= kek512_in[sys_addr & 8'hFF];
      else
        sys_rdata_o <= 32'h00000000;
    end

    20'h020zz: begin
      sys_ack_o <= sys_en;
      if ((sys_addr_i & 20'hFF) < 8'd26)
        sys_rdata_o <= kek512_out[sys_addr & 8'hFF];
      else
        sys_rdata_o <= 32'h00000000;
    end
*/


    default:   begin
      sys_ack_o   <= sys_en;
      sys_rdata_o <= 32'b0;
      end

    endcase
    end

  else if (sys_wen_i) begin                                                                                   // keep sys_ack assignment in this process
    sys_ack_o <= sys_en;
    end

  else begin
    sys_ack_o <= 1'b0;
    end
  end

endmodule: regs
