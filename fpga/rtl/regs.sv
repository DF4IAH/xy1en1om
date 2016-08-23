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
   input        [  3: 0] clks            ,  // clocks
   input        [  3: 0] rstsn           ,  // clock reset lines - active low

   // activation
   output                x11_activated   ,  // x11 sub-module is activated

   // System bus - slave
   input        [ 31: 0] sys_addr        ,  // bus saddress
   input        [ 31: 0] sys_wdata       ,  // bus write data
   input        [  3: 0] sys_sel         ,  // bus write byte select
   input                 sys_wen         ,  // bus write enable
   input                 sys_ren         ,  // bus read enable
   output reg   [ 31: 0] sys_rdata       ,  // bus read data
   output reg            sys_err         ,  // bus error indicator
   output reg            sys_ack         ,  // bus acknowledge signal

   // AXI streaming master from XADC
   input              xadc_axis_aclk     ,  // AXI-streaming from the XADC, clock from the AXI-S FIFO
   input   [   15: 0] xadc_axis_tdata    ,  // AXI-streaming from the XADC, data
   input   [    4: 0] xadc_axis_tid      ,  // AXI-streaming from the XADC, analog data source channel for this data
                                            // TID=0x10:VAUXp0_VAUXn0 & TID=0x18:VAUXp8_VAUXn8, TID=0x11:VAUXp1_VAUXn1 & TID=0x19:VAUXp9_VAUXn9, TID=0x03:Vp_Vn
   output reg         xadc_axis_tready   ,  // AXI-streaming from the XADC, slave indicating ready for data
   input              xadc_axis_tvalid   ,  // AXI-streaming from the XADC, data transfer valid

   // AXI0 master
   output                axi0_clk_o      ,  // global clock
   output                axi0_rstn_o     ,  // global reset
   output     [   31: 0] axi0_waddr_o    ,  // system write address
   output     [   63: 0] axi0_wdata_o    ,  // system write data
   output     [    7: 0] axi0_wsel_o     ,  // system write byte select
   output                axi0_wvalid_o   ,  // system write data valid
   output     [    3: 0] axi0_wlen_o     ,  // system write burst length
   output                axi0_wfixed_o   ,  // system write burst type (fixed / incremental)
   input                 axi0_werr_i     ,  // system write error
   input                 axi0_wrdy_i     ,  // system write ready
   output     [   31: 0] axi0_raddr_o    ,  // system read address
   output                axi0_rvalid_o   ,  // system read data valid
   output     [    7: 0] axi0_rsel_o     ,  // system read byte select
   output     [    3: 0] axi0_rlen_o     ,  // system read burst length
   output                axi0_rfixed_o   ,  // system read burst type (fixed / incremental)
   input      [   63: 0] axi0_rdata_i    ,  // system read data
   input                 axi0_rrdy_i     ,  // system read data is ready
   input                 axi0_rerr_i     ,  // system read error

   // AXI1 master
   output                axi1_clk_o      ,  // global clock
   output                axi1_rstn_o     ,  // global reset
   output     [   31: 0] axi1_waddr_o    ,  // system write address
   output     [   63: 0] axi1_wdata_o    ,  // system write data
   output     [    7: 0] axi1_wsel_o     ,  // system write byte select
   output                axi1_wvalid_o   ,  // system write data valid
   output     [    3: 0] axi1_wlen_o     ,  // system write burst length
   output                axi1_wfixed_o   ,  // system write burst type (fixed / incremental)
   input                 axi1_werr_i     ,  // system write error
   input                 axi1_wrdy_i     ,  // system write ready
   output     [   31: 0] axi1_raddr_o    ,  // system read address
   output                axi1_rvalid_o   ,  // system read data valid
   output     [    7: 0] axi1_rsel_o     ,  // system read byte select
   output     [    3: 0] axi1_rlen_o     ,  // system read burst length
   output                axi1_rfixed_o   ,  // system read burst type (fixed / incremental)
   input      [   63: 0] axi1_rdata_i    ,  // system read data
   input                 axi1_rrdy_i     ,  // system read data is ready
   input                 axi1_rerr_i        // system read error
);


// === CONST: OMNI section ===

//---------------------------------------------------------------------------------
// current date of compilation

localparam CURRENT_DATE = 32'h16082310;         // current date: 0xYYMMDDss - YY=year, MM=month, DD=day, ss=serial from 0x01 .. 0x09, 0x10, 0x11 .. 0x99


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
    REG_RW_KECCAK512_CTRL,                      // h200: KECCAK512 submodule control register
//  REG_RD_KECCAK512_STATUS,                    // h204: KECCAK512 submodule status register

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
    SHA256_CTRL_RSVD_D07,

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


// === NET: X11 - OMNI section ===

reg          [ 31:0]     regs[REG_COUNT];                   // registers to be accessed by the system bus

wire                     bus_clk             = clks[0];     // 125.0 MHz;
wire                     bus_rstn            = rstsn[0];

wire                     x11_enable          = regs[REG_RW_CTRL][CTRL_ENABLE];
wire         [ 31:0]     status;


// === NET: SHA256 section ===

wire                     sha256_clk          = clks[2];     // 62.5 MHz
wire                     sha256_rstn         = rstsn[2];
wire                     sha256_enable       = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_ENABLE] &  x11_enable;
wire                     sha256_reset        = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_RESET]  | !x11_enable;
wire                     sha256_dbl_hash     = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DBL_HASH];
wire                     sha256_dma_mode     = regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DMA_MODE];
wire                     sha256_dma_multihash= regs[REG_RW_SHA256_CTRL][SHA256_CTRL_DMA_MULTIHASH];
wire         [ 31:0]     sha256_dma_base_addr= regs[REG_RW_SHA256_DMA_BASE_ADDR];
wire         [ 31:0]     sha256_dma_bit_len  = regs[REG_RW_SHA256_DMA_BIT_LEN];
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

reg                      sha256_start = 'b0;
wire                     sha256_hash_valid;
wire         [255:0]     sha256_hash_data;

// debugging DMA engine
wire         [  3:0]     sha256_dma_state;
wire         [ 31:0]     sha256_dma_axi_r_state;
wire         [ 31:0]     sha256_dma_axi_w_state;
wire         [ 31:0]     sha256_dma_last_data;


// === NET: KECCAK512 section ===

wire                     kek512_clk          = clks[0];     // 125.0 MHz
wire                     kek512_rstn         = rstsn[0];
wire                     kek512_enable       = regs[REG_RW_KECCAK512_CTRL][KEK512_CTRL_ENABLE] &  x11_enable;
wire                     kek512_reset        = regs[REG_RW_KECCAK512_CTRL][KEK512_CTRL_RESET]  | !x11_enable;

wire         [ 31:0]     kek512_status;
wire                     kek512_rdy;                        // keccak engine is ready to feed and/or to read-out

reg          [ 63:0]     kek512_in[25]  = '{25{0}};         // feeding keccak engine
reg                      kek512_start   = 'b0;              // start keccak engine
wire         [ 63:0]     kek512_out[25];                    // result of keccak engine


// === IMPL: X11 - OMNI section ===

assign        x11_activated = x11_enable;


//---------------------------------------------------------------------------------
//  regs sub-module activation

wire          bus_sha256_reset_n;
red_pitaya_rst_clken i_rst_clken_sha256_bus (
  // global signals
  .clk                     ( bus_clk                     ), // clock 125.0 MHz
  .rstn                    ( bus_rstn                    ), // clock reset - active low

  // input signals
  .enable_i                ( sha256_enable               ),

  // output signals
  .clk_en_o                (                             ),
  .reset_n_o               ( bus_sha256_reset_n          )
);

wire          sha256_clk_en;
wire          sha256_reset_n;
red_pitaya_rst_clken i_rst_clken_sha256 (
  // global signals
  .clk                     ( sha256_clk                  ), // clock 62.5 MHz
  .rstn                    ( sha256_rstn                 ), // clock reset - active low

  // input signals
  .enable_i                ( sha256_enable               ),

  // output signals
  .clk_en_o                ( sha256_clk_en               ),
  .reset_n_o               ( sha256_reset_n              )
);
wire          sha256_activated = sha256_reset_n;


wire          kek512_clk_en;
wire          kek512_reset_n;
red_pitaya_rst_clken i_rst_clken_kek512 (
  // global signals
  .clk                     ( kek512_clk                  ), // clock 125.0 MHz
  .rstn                    ( kek512_rstn                 ), // clock reset - active low

  // input signals
  .enable_i                ( kek512_enable               ),

  // output signals
  .clk_en_o                ( kek512_clk_en               ),
  .reset_n_o               ( kek512_reset_n              )
);

wire          kek512_activated = kek512_reset_n;

assign status = { 20'b0,  3'b0 , kek512_activated,  3'b0, sha256_activated,  3'b0, x11_activated };


// AXIS
assign xadc_axis_tready = 1'b0;

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
  .clk_i                   ( bus_clk                     ), // clock 125.0 MHz
  .rstn_i                  ( bus_sha256_reset_n          ), // SHA256 enabled clock reset - active low

  .dma_enable_i            ( sha256_dma_mode             ), // 1 = DMA mode, 0 = FIFO mode
  .dma_base_addr_i         ( sha256_dma_base_addr        ), // DMA byte base address, bits [1:0] always 0 (32 bit alignment)
  .dma_bit_len_i           ( sha256_dma_bit_len          ), // submodule number of data bits to be hashed, bits [4:0] always 0 (32 bit alignment)
  .dma_start_i             ( sha256_start                ),

  .sha256_rdy_i            ( sha256_rdy                  ),

  .axi_clk_o               ( axi0_clk_o                  ),
  .axi_rstn_o              ( axi0_rstn_o                 ),
  .axi_waddr_o             ( axi0_waddr_o                ),
  .axi_wdata_o             ( axi0_wdata_o                ),
  .axi_wsel_o              ( axi0_wsel_o                 ),
  .axi_wvalid_o            ( axi0_wvalid_o               ),
  .axi_wlen_o              ( axi0_wlen_o                 ),
  .axi_wfixed_o            ( axi0_wfixed_o               ),
  .axi_werr_i              ( axi0_werr_i                 ),
  .axi_wrdy_i              ( axi0_wrdy_i                 ),
  .axi_raddr_o             ( axi0_raddr_o                ),
  .axi_rvalid_o            ( axi0_rvalid_o               ),
  .axi_rsel_o              ( axi0_rsel_o                 ),
  .axi_rlen_o              ( axi0_rlen_o                 ),
  .axi_rfixed_o            ( axi0_rfixed_o               ),
  .axi_rdata_i             ( axi0_rdata_i                ),
  .axi_rrdy_i              ( axi0_rrdy_i                 ),
  .axi_rerr_i              ( axi0_rerr_i                 ),

  .fifo_wr_en_o            ( sha256_dma_fifo_wr_en       ),
  .fifo_wr_in_o            ( sha256_dma_fifo_wr_in       ),
  .fifo_wr_count_i         ( sha256_fifo_rd_count        ),

  .dbg_state_o             ( sha256_dma_state            ),
  .dbg_axi_r_state_o       ( sha256_dma_axi_r_state      ),
  .dbg_axi_w_state_o       ( sha256_dma_axi_w_state      ),
  .dbg_axi_last_data       ( sha256_dma_last_data        )
);


assign sha256_32b_fifo_wr_en = sha256_dma_mode ?  sha256_dma_fifo_wr_en : sha256_port_fifo_wr_en;
assign sha256_32b_fifo_wr_in = sha256_dma_mode ?  sha256_dma_fifo_wr_in : sha256_port_fifo_wr_in;

fifo_32i_32o_512d i_fifo_32i_32o (
  .rst                     ( !sha256_reset_n             ), // reset active high
  .wr_clk                  ( bus_clk                     ), // clock 125.0 MHz
  .rd_clk                  ( sha256_clk                  ), // clock  62.5 MHz

  .wr_en                   ( sha256_32b_fifo_wr_en       ), // write signal to push into the FIFO
  .din                     ( sha256_32b_fifo_wr_in       ), // 32 bit word in
  .almost_full             ( sha256_fifo_m1full          ), // FIFO does except one more write access
  .full                    ( sha256_fifo_full            ), // FIFO would spill over by next write access
  .wr_data_count           ( sha256_fifo_wr_count        ), // at least this number of entries are pushed on the FIFO

  .rd_en                   ( sha256_32b_fifo_rd_en       ), // enable reading from the FIFO
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

  .fifo_empty              ( sha256_fifo_empty           ), // indicator for continuation with next block
  .fifo_rd_en              ( sha256_32b_fifo_rd_en       ), // enable reading of the FIFO
  .fifo_rd_vld             ( sha256_32b_fifo_rd_vld      ), // read data from the FIFO is valid
  .fifo_rd_dat             ( sha256_32b_fifo_rd_out      ), // 32 bit word out of the FIFO for the SHA-256 engine to process

  .valid_o                 ( sha256_hash_valid           ), // hash output vector is valid
  .hash_o                  ( sha256_hash_data            )  // computated hash value
);

always @(posedge sha256_clk)
if (!sha256_reset_n)
   sha256_start <= 1'b0;
else if ((!sha256_fifo_empty || sha256_dma_mode) && sha256_rdy)
   sha256_start <= 1'b1;
else
   sha256_start <= 1'b0;

assign sha256_status = { 24'b0,  1'b0, sha256_fifo_full, sha256_fifo_m1full, sha256_fifo_empty,  2'b0, sha256_hash_valid, sha256_rdy };


// === IMPL: KECCAK512 section ===

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
  regs[REG_RW_KECCAK512_CTRL]                     <= 32'b0;

  sha256_port_fifo_wr_en                          <= 'b0;
  kek512_in                                       <= '{25{0}};
  kek512_start                                    <= 'b0;
  end

else begin
  regs[REG_RW_SHA256_CTRL] <= regs[REG_RW_SHA256_CTRL] & ~(32'h00000002);  // mask out one-shot flags (RESET)
  sha256_port_fifo_wr_en <= 1'b0;
  kek512_start <= 1'b0;

  if (sys_wen) begin
    casez (sys_addr[19:0])

    /* OMNI section */

    20'h00000: begin
      regs[REG_RW_CTRL]                           <= sys_wdata[31:0];
      end


    /* SHA256 section */

    20'h00100: begin
      regs[REG_RW_SHA256_CTRL]                    <= sys_wdata[31:0];
      end
/*  20'h00108: begin
      regs[REG_RW_SHA256_BIT_LEN]                 <= sys_wdata[31:0];
      end */
    20'h0010C: begin
      sha256_port_fifo_wr_in[31:0]                <= sys_wdata[31:0];
      sha256_port_fifo_wr_en <= 1'b1;
      end

    20'h00140: begin
      regs[REG_RW_SHA256_DMA_BASE_ADDR]           <= sys_wdata[31:0];
      end

    20'h00144: begin
      regs[REG_RW_SHA256_DMA_BIT_LEN]             <= sys_wdata[31:0];
      end

    20'h00148: begin
      regs[REG_RW_SHA256_DMA_NONCE_OFS]           <= sys_wdata[31:0];
      end


    /* KECCAK512 section */

    20'h00200: begin
      regs[REG_RW_KECCAK512_CTRL]                 <= sys_wdata[31:0];
      end

/*
    20'h100zz: begin
      if ((sys_addr & 20'hFF) < 8'd26) begin
        kek512_in[sys_addr & 8'hF]                <= sys_wdata;
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
assign sys_en = sys_wen | sys_ren;

// READ access to the registers
always @(posedge bus_clk)
if (!bus_rstn) begin
  sys_err      <= 1'b0;
  sys_ack      <= 1'b0;
  sys_rdata    <= 32'h00000000;
  end

else begin
  sys_err <= 1'b0;
  if (sys_ren) begin
    casez (sys_addr[19:0])

    /* OMNI section */

    20'h00000: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_CTRL];
      end
    20'h00004: begin
      sys_ack   <= sys_en;
      sys_rdata <= status;
      end
    20'h0000C: begin
      sys_ack   <= sys_en;
      sys_rdata <= CURRENT_DATE;
      end


    /* SHA256 section */

    20'h00100: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_SHA256_CTRL];
      end
    20'h00104: begin
      sys_ack   <= sys_en;
      sys_rdata <= sha256_status;
      end

    20'h0010C: begin
      sys_ack   <= sys_en;
      sys_rdata <= { 23'b0, sha256_fifo_wr_count[8:0] };
      end

    20'h00110: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H7];
      end
    20'h00114: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H6];
      end
    20'h00118: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H5];
      end
    20'h0011C: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H4];
      end
    20'h00120: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H3];
      end
    20'h00124: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H2];
      end
    20'h00128: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H1];
      end
    20'h0012C: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_SHA256_HASH_H0];
      end

    20'h00130: begin
      sys_ack   <= sys_en;
      sys_rdata <= { 23'b0, sha256_fifo_wr_count[8:0] };
      end
    20'h00134: begin
      sys_ack   <= sys_en;
      sys_rdata <= { 23'b0, sha256_fifo_rd_count[8:0] };
      end

    20'h00140: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_SHA256_DMA_BASE_ADDR];
      end
    20'h00144: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_SHA256_DMA_BIT_LEN];
      end
    20'h00148: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_SHA256_DMA_NONCE_OFS];
      end

    20'h00150: begin
      sys_ack   <= sys_en;
      sys_rdata <= { 24'b0, sha256_dma_state[3:0] };
      end
    20'h00154: begin
      sys_ack   <= sys_en;
      sys_rdata <= sha256_dma_axi_r_state;
      end
    20'h00158: begin
      sys_ack   <= sys_en;
      sys_rdata <= sha256_dma_axi_w_state;
      end
    20'h0015C: begin
      sys_ack   <= sys_en;
      sys_rdata <= sha256_dma_last_data;
      end


    /* KECCAK512 section */

    20'h00200: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_KECCAK512_CTRL];
      end
    20'h00204: begin
      sys_ack   <= sys_en;
      sys_rdata <= kek512_status;
      end

/*
    20'h100zz: begin
      sys_ack <= sys_en;
      if ((sys_addr & 20'hFF) < 8'd26)
        sys_rdata <= kek512_in[sys_addr & 8'hFF];
      else
        sys_rdata <= 32'h00000000;
    end

    20'h020zz: begin
      sys_ack <= sys_en;
      if ((sys_addr & 20'hFF) < 8'd26)
        sys_rdata <= kek512_out[sys_addr & 8'hFF];
      else
        sys_rdata <= 32'h00000000;
    end
*/


    default:   begin
      sys_ack   <= sys_en;
      sys_rdata <= 32'b0;
      end

    endcase
    end

  else if (sys_wen) begin                                                                                   // keep sys_ack assignment in this process
    sys_ack <= sys_en;
    end

  else begin
    sys_ack <= 1'b0;
    end
  end

endmodule: regs
