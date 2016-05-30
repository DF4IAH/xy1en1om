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
   input                 clk_100mhz      , // clock 100 MHz
   input                 rstn_i          , // ADC reset - active low

   // activation
   output                x11_activated   , // RB sub-module is activated

   // System bus - slave
   input        [ 31: 0] sys_addr        ,  // bus saddress
   input        [ 31: 0] sys_wdata       ,  // bus write data
   input        [  3: 0] sys_sel         ,  // bus write byte select
   input                 sys_wen         ,  // bus write enable
   input                 sys_ren         ,  // bus read enable
   output reg   [ 31: 0] sys_rdata       ,  // bus read data
   output reg            sys_err         ,  // bus error indicator
   output reg            sys_ack            // bus acknowledge signal

/*
   // AXI streaming master from XADC
   input              xadc_axis_aclk     ,  // AXI-streaming from the XADC, clock from the AXI-S FIFO
   input   [  151: 0] xadc_axis_tdata    ,  // AXI-streaming from the XADC, data
   input   [    4: 0] xadc_axis_tid      ,  // AXI-streaming from the XADC, analog data source channel for this data
                                            // TID=0x10:VAUXp0_VAUXn0 & TID=0x18:VAUXp8_VAUXn8, TID=0x11:VAUXp1_VAUXn1 & TID=0x19:VAUXp9_VAUXn9, TID=0x03:Vp_Vn
   output reg         xadc_axis_tready   ,  // AXI-streaming from the XADC, slave indicating ready for data
   input              xadc_axis_tvalid   ,  // AXI-streaming from the XADC, data transfer valid
*/

/*
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
   input                 axi1_wrdy_i        // system write ready
*/
);


//---------------------------------------------------------------------------------
// current date of compilation
localparam CURRENT_DATE = 32'h16052901;         // current date: 0xYYMMDDss - YY=year, MM=month, DD=day, ss=serial from 0x01 .. 0x09, 0x10, 0x11 .. 0x99


//---------------------------------------------------------------------------------
//  Registers accessed by the system bus

enum {
    /* OMNI section */
    REG_RW_CTRL                           =  0, // h000: RB control register
    REG_RD_STATUS,                              // h004: EB status register

    REG_COUNT
} REG_ENUMS;

reg  [31: 0]    regs    [REG_COUNT];            // registers to be accessed by the system bus

enum {
    CTRL_ENABLE                           =  0, // enabling the RadioBox sub-module
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

enum {
    STAT_CLK_EN                           =  0, // RB clock enable
    STAT_RSVD_D01,
    STAT_RSVD_D02,
    STAT_RSVD_D03,

    STAT_KEK_RDY,
    STAT_RSVD_D05,
    STAT_RSVD_D06,
    STAT_RSVD_D07,

    STAT_RSVD_D08,
    STAT_RSVD_D09,
    STAT_RSVD_D10,
    STAT_RSVD_D11,

    STAT_RSVD_D12,
    STAT_RSVD_D13,
    STAT_RSVD_D14,
    STAT_RSVD_D15,

    STAT_RSVD_D16,
    STAT_RSVD_D17,
    STAT_RSVD_D18,
    STAT_RSVD_D19,

    STAT_RSVD_D20,
    STAT_RSVD_D21,
    STAT_RSVD_D22,
    STAT_RSVD_D23,

    STAT_RSVD_D24,
    STAT_RSVD_D25,
    STAT_RSVD_D26,
    STAT_RSVD_D27,

    STAT_RSVD_D28,
    STAT_RSVD_D29,
    STAT_RSVD_D30,
    STAT_RSVD_D31
} STAT_BITS_ENUM;


// === OMNI section ===

//---------------------------------------------------------------------------------
// Global signals

wire                     kek_rdy;                            // keccak function is ready to feed and/or to read-out
reg           [63:0]     kek_in[25]  = '{25{0}};             // feeding keccak function
reg                      kek_start   = 'b0;                  // start keccak function
wire          [63:0]     kek_out[25] = '{25{0}};             // result of keccak function


//---------------------------------------------------------------------------------
// Short hand names

wire          x11_enable = regs[REG_RW_CTRL][CTRL_ENABLE];


//---------------------------------------------------------------------------------
//  regs sub-module activation

wire          x11_clk_en;
wire          x11_reset_n;
assign        x11_activated = x11_reset_n;

red_pitaya_rst_clken i_rst_clken_master (
  // global signals
  .clk                     ( clk_100mhz                  ),  // clock 100 MHz
  .global_rst_n            ( rstn_i                      ),  // global reset

  // input signals
  .enable_i                ( x11_enable                  ),

  // output signals
  .reset_n_o               ( x11_reset_n                 ),
  .clk_en_o                ( x11_clk_en                  )
);


// === Crypto calculations ===

//---------------------------------------------------------------------------------
// sub system keccak_f1600_round

keccak_f1600_round i_keccak_f1600_round(
  // global signals
  .clk_100mhz              ( clk_100mhz                  ),  // clock 100 MHz
  .rstn_i                  ( x11_reset_n                 ),  // ADC reset - active low

  .ready                   ( kek_rdy                     ),  // 1: ready to fill and read out
  .vec_i                   ( kek_in                      ),  // 1600 bit data input
  .start                   ( kek_start                   ),  // 1: starting the function
  .vec_o                   ( kek_out                     )   // 1600 bit data output
);


// === Bus handling ===

//---------------------------------------------------------------------------------
//  Status register

always @(posedge clk_100mhz)
if (!rstn_i)
   regs[REG_RD_STATUS]                            <= 32'b0;
else begin
   regs[REG_RD_STATUS][STAT_CLK_EN]               <= x11_clk_en;
   regs[REG_RD_STATUS][STAT_KEK_RDY]              <= kek_rdy;
   end


//---------------------------------------------------------------------------------
//  System bus connection

// write access to the registers
always @(posedge clk_100mhz)
if (!rstn_i) begin
  kek_in                                          <= '{25{0}};
  kek_start                                       <= 'b0;
  regs[REG_RW_CTRL]                               <= 32'h00000000;
  end

else begin
  kek_start <= 1'b0;

  if (sys_wen) begin
    casez (sys_addr[19:0])

    /* control */
    20'h00000: begin
      regs[REG_RW_CTRL]                           <= sys_wdata[31:0];
      end

    20'h010zz: begin
      if ((sys_addr & 20'hFF) < 8'd26) begin
        kek_in[sys_addr & 8'hF]                   <= sys_wdata;
        kek_start <= 1'b1;
        end
    end

    default:   begin
    end

    endcase
    end
  end


wire sys_en;
assign sys_en = sys_wen | sys_ren;

// read access to the registers
always @(posedge clk_100mhz)
if (!rstn_i) begin
  sys_err      <= 1'b0;
  sys_ack      <= 1'b0;
  sys_rdata    <= 32'h00000000;
  end

else begin
  sys_err <= 1'b0;
  if (sys_ren) begin
    casez (sys_addr[19:0])

    /* control */
    20'h00000: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RW_CTRL];
      end
    20'h00004: begin
      sys_ack   <= sys_en;
      sys_rdata <= regs[REG_RD_STATUS];
      end

    20'h010zz: begin
      sys_ack <= sys_en;
      if ((sys_addr & 20'hFF) < 8'd26)
        sys_rdata <= kek_in[sys_addr & 8'hFF];
      else
        sys_rdata <= 32'h00000000;
    end

    20'h020zz: begin
      sys_ack <= sys_en;
      if ((sys_addr & 20'hFF) < 8'd26)
        sys_rdata <= kek_out[sys_addr & 8'hFF];
      else
        sys_rdata <= 32'h00000000;
    end

    default:   begin
      sys_ack   <= sys_en;
      sys_rdata <= 32'h00000000;
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


endmodule
