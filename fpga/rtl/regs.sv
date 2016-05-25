/**
 * $Id: red_pitaya_radiobox.v 001 2015-09-11 18:10:00Z DF4IAH $
 *
 * @brief Red Pitaya RadioBox application, used to expand RedPitaya for
 * radio ham operators. Transmitter as well as receiver components are
 * included like modulators/demodulators, filters, (R)FFT transformations
 * and that like.
 *
 * @Author Ulrich Habel, DF4IAH
 *
 * (c) Ulrich Habel / GitHub.com open source  https://github.com/DF4IAH/RedPitaya_RadioBox/
 *
 * This part of code is written in Verilog hardware description language (HDL).
 * Please visit http://en.wikipedia.org/wiki/Verilog
 * for more details on the language used herein.
 */

/**
 * GENERAL DESCRIPTION:
 *
 * This modules enables the Red Pitaya to behave like a Transceiver for voice transmission. At the time of writing these modulation variants are supported:
 *   transmitter:  SSB - USB upper-side-band modulation                      - realized with a weaver oscillator @ 1700 Hz
 *                 SSB - LSB lower-side-band modulation                      - realized with a weaver oscillator @ 1700 Hz
 *                 AM  - amplitude modulation                                - realized by modulating the carrier output amplifier
 *                 FM  - frequency modulation                                - realized by modulating the DDS phase increment value
 *                 PM  - phase modulation                                    - realized by modulating the DDS phase offset value
 *
 *   receiver:     SSB - USB upper-side-band demodulation                    - realized with a weaver oscillator @ 1700 Hz
 *                 SSB - LSB lower-side-band demodulation                    - realized with a weaver oscillator @ 1700 Hz
 *                 AM  - amplitude envelope demodulation                     - realized by the OORDIC magnitude information
 *                 AM  - synchronized carrier upper-side-band demodulation   - realized by a CORDIC assisted automatic frequency correction (AFC) and weaver USB demodulation
 *                 AM  - synchronized carrier lower-side-band demodulation   - realized by a CORDIC assisted automatic frequency correction (AFC) and weaver LSB demodulation
 *                 FM  - frequency demodulation                              - realized by a CORDIC assisted automatic frequency correction (AFC) frequency offset as demodulation information
 *                 PM  - phase demodulation                                  - realized by an integrator of the FM signal
 *
 *
 * TODO: graphics - exmaple by red_pitaya_scope.v
 *
 *
 * The idea of this concept is to realize a complete audio transceiver for all known analog voice transmissions by short wave radio stations as well as HAM radio operators. Due to the used digital
 * concept all frequencies could be kept at a very low value because the "amplifiers" and "mixers" are simply multiplicators which does not have any "DC" blockers within. Students and radio enthusiasts
 * are able to play and learn about the idea behind modulation and demodulation of radio frequencies (RF). Any new ideas to have any variants of "modulation" and "demodulation" are welcome.
 *
 * For any further connections to the Red Pitaya the Linux sound system could be connected as audio streams to enable SDR radio-software to access this RadioBox submodule. Want to connect digital
 * CODECS to this RadioBox submodule? Simply connect the audio system to and from it. By doinf this it would be easy to use fldigi or other digital software working with a baseband concept.
 *
 * Another realization would be to adapt a front plate on top of the Red Pitaya to have a display, controllers and anything you need to operate this Red Pitaya anywhere you like and without the help
 * of a browser.
 *
 * Just have fun and learn!
 */


`timescale 1ns / 1ps

module regs #(
  // parameter RSZ = 14  // RAM size 2^RSZ
)(
   // ADC clock & reset
   input                 clk_adc_125mhz  ,      // ADC based clock, 125 MHz
   input                 adc_rstn_i      ,      // ADC reset - active low
   input        [  1: 0] ac97_clks_i     ,      // sound interface sample rates

   // activation
   output                rb_activated    ,      // RB sub-module is activated

   // LEDs
   output reg            rb_leds_en      ,      // RB LEDs are enabled and overwrites HK sub-module
   output reg   [  7: 0] rb_leds_data    ,      // RB LEDs data, LED0 is located at the connector, ... , LED7 is located near to the red / green / blue LEDs
   input        [  7: 0] ac97_leds_i     ,      // AC97 diagnostic LEDs

   // ADC data
   input        [ 13: 0] adc_i[1:0]      ,      // ADC data { CHB, CHA }

   // DAC data
   output reg   [ 15: 0] rb_out_ch [1:0] ,      // RadioBox output signals

   // ALSA
   input        [ 31: 0] rb_line_out_i   ,      // Linux sound system ALSA LINE-OUT stereo, 2x 16 bit
   output reg   [ 31: 0] rb_line_in_o    ,      // Linux sound system ALSA LINE-IN  stereo, 2x 16 bit
   input                 ac97_irq_play_i ,      // monitor IRQ line for playing stream
   input                 ac97_irq_rec_i  ,      // monitor IRQ line for recording stream

   // System bus - slave
   input        [ 31: 0] sys_addr        ,      // bus saddress
   input        [ 31: 0] sys_wdata       ,      // bus write data
   input        [  3: 0] sys_sel         ,      // bus write byte select
   input                 sys_wen         ,      // bus write enable
   input                 sys_ren         ,      // bus read enable
   output reg   [ 31: 0] sys_rdata       ,      // bus read data
   output reg            sys_err         ,      // bus error indicator
   output reg            sys_ack         ,      // bus acknowledge signal

   // AXI streaming master from XADC
   input              xadc_axis_aclk     ,      // AXI-streaming from the XADC, clock from the AXI-S FIFO
   input   [ 16-1: 0] xadc_axis_tdata    ,      // AXI-streaming from the XADC, data
   input   [  5-1: 0] xadc_axis_tid      ,      // AXI-streaming from the XADC, analog data source channel for this data
                                                // TID=0x10:VAUXp0_VAUXn0 & TID=0x18:VAUXp8_VAUXn8, TID=0x11:VAUXp1_VAUXn1 & TID=0x19:VAUXp9_VAUXn9, TID=0x03:Vp_Vn
   output reg         xadc_axis_tready   ,      // AXI-streaming from the XADC, slave indicating ready for data
   input              xadc_axis_tvalid   ,      // AXI-streaming from the XADC, data transfer valid

   // AXI0 master
   output                axi0_clk_o      ,  // global clock
   output                axi0_rstn_o     ,  // global reset
   output     [ 32-1: 0] axi0_waddr_o    ,  // system write address
   output     [ 64-1: 0] axi0_wdata_o    ,  // system write data
   output     [  8-1: 0] axi0_wsel_o     ,  // system write byte select
   output                axi0_wvalid_o   ,  // system write data valid
   output     [  4-1: 0] axi0_wlen_o     ,  // system write burst length
   output                axi0_wfixed_o   ,  // system write burst type (fixed / incremental)
   input                 axi0_werr_i     ,  // system write error
   input                 axi0_wrdy_i     ,  // system write ready
   
   // AXI1 master
   output                axi1_clk_o      ,  // global clock
   output                axi1_rstn_o     ,  // global reset
   output     [ 32-1: 0] axi1_waddr_o    ,  // system write address
   output     [ 64-1: 0] axi1_wdata_o    ,  // system write data
   output     [  8-1: 0] axi1_wsel_o     ,  // system write byte select
   output                axi1_wvalid_o   ,  // system write data valid
   output     [  4-1: 0] axi1_wlen_o     ,  // system write burst length
   output                axi1_wfixed_o   ,  // system write burst type (fixed / incremental)
   input                 axi1_werr_i     ,  // system write error
   input                 axi1_wrdy_i        // system write ready
);


//---------------------------------------------------------------------------------
// current date of compilation
localparam CURRENT_DATE = 32'h16052501;         // current date: 0xYYMMDDss - YY=year, MM=month, DD=day, ss=serial from 0x01 .. 0x09, 0x10, 0x11 .. 0x99


//---------------------------------------------------------------------------------
//  Registers accessed by the system bus

enum {
    /* OMNI section */
    REG_RW_RB_CTRL                        =  0, // h000: RB control register
    REG_RD_RB_STATUS,                           // h004: EB status register

    REG_RB_COUNT
} REG_RB_ENUMS;

reg  [31: 0]    regs    [REG_RB_COUNT];         // registers to be accessed by the system bus

enum {
    RB_CTRL_ENABLE                        =  0, // enabling the RadioBox sub-module
    RB_CTRL_RSVD_D01,
    RB_CTRL_RSVD_D02,
    RB_CTRL_RSVD_D03,

    RB_CTRL_RSVD_D04,
    RB_CTRL_RSVD_D05,
    RB_CTRL_RSVD_D06,
    RB_CTRL_RSVD_D07,

    RB_CTRL_RSVD_D08,
    RB_CTRL_RSVD_D09,
    RB_CTRL_RSVD_D10,
    RB_CTRL_RSVD_D11,

    RB_CTRL_RSVD_D12,
    RB_CTRL_RSVD_D13,
    RB_CTRL_RSVD_D14,
    RB_CTRL_RSVD_D15,

    RB_CTRL_RSVD_D16,
    RB_CTRL_RSVD_D17,
    RB_CTRL_RSVD_D18,
    RB_CTRL_RSVD_D19,

    RB_CTRL_RSVD_D20,
    RB_CTRL_RSVD_D21,
    RB_CTRL_RSVD_D22,
    RB_CTRL_RSVD_D23,

    RB_CTRL_RSVD_D24,
    RB_CTRL_RSVD_D25,
    RB_CTRL_RSVD_D26,
    RB_CTRL_RSVD_D27,

    RB_CTRL_RSVD_D28,
    RB_CTRL_RSVD_D29,
    RB_CTRL_RSVD_D30,
    RB_CTRL_RSVD_D31
} RB_CTRL_BITS_ENUM;

enum {
    RB_STAT_CLK_EN                        =  0, // RB clock enable
    RB_STAT_RSVD_D01,
    RB_STAT_RSVD_D02,
    RB_STAT_RSVD_D03,

    RB_STAT_RSVD_D04,
    RB_STAT_RSVD_D05,
    RB_STAT_RSVD_D06,
    RB_STAT_RSVD_D07,

    RB_STAT_RSVD_D08,
    RB_STAT_RSVD_D09,
    RB_STAT_RSVD_D10,
    RB_STAT_RSVD_D11,

    RB_STAT_RSVD_D12,
    RB_STAT_RSVD_D13,
    RB_STAT_RSVD_D14,
    RB_STAT_RSVD_D15,

    RB_STAT_RSVD_D16,
    RB_STAT_RSVD_D17,
    RB_STAT_RSVD_D18,
    RB_STAT_RSVD_D19,

    RB_STAT_RSVD_D20,
    RB_STAT_RSVD_D21,
    RB_STAT_RSVD_D22,
    RB_STAT_RSVD_D23,

    RB_STAT_RSVD_D24,
    RB_STAT_RSVD_D25,
    RB_STAT_RSVD_D26,
    RB_STAT_RSVD_D27,

    RB_STAT_RSVD_D28,
    RB_STAT_RSVD_D29,
    RB_STAT_RSVD_D30,
    RB_STAT_RSVD_D31
} RB_STAT_BITS_ENUM;


// === OMNI section ===

//---------------------------------------------------------------------------------
// Short hand names

wire                   rb_enable              = regs[REG_RW_RB_CTRL][RB_CTRL_ENABLE];


//---------------------------------------------------------------------------------
//  regs sub-module activation

wire          rb_clk_en;
wire          rb_reset_n;
assign        rb_activated = rb_reset_n;

red_pitaya_rst_clken rb_rst_clken_master (
  // global signals
  .clk                     ( clk_adc_125mhz              ),  // global 125 MHz clock
  .global_rst_n            ( adc_rstn_i                  ),  // ADC global reset

  // input signals
  .enable_i                ( rb_enable                   ),

  // output signals
  .reset_n_o               ( rb_reset_n                  ),
  .clk_en_o                ( rb_clk_en                   )
);


// === Bus handling ===

//---------------------------------------------------------------------------------
//  Status register

always @(posedge clk_adc_125mhz)
if (!adc_rstn_i)
   regs[REG_RD_RB_STATUS] <= 32'b0;
else begin
   regs[REG_RD_RB_STATUS][RB_STAT_CLK_EN]                    <= rb_clk_en;
   end


//---------------------------------------------------------------------------------
//  System bus connection

// write access to the registers
always @(posedge clk_adc_125mhz)
if (!adc_rstn_i) begin
   regs[REG_RW_RB_CTRL]                      <= 32'h00000000;
   end

else begin
   if (sys_wen) begin
      casez (sys_addr[19:0])

      /* control */
      20'h00000: begin
         regs[REG_RW_RB_CTRL]                     <= sys_wdata[31:0];
         end

      default:   begin
         end

      endcase
      end
   end


wire sys_en;
assign sys_en = sys_wen | sys_ren;

// read access to the registers
always @(posedge clk_adc_125mhz)
if (!adc_rstn_i) begin
   sys_err      <= 1'b0;
   sys_ack      <= 1'b0;
   sys_rdata    <= 32'h00000000;
   end

else begin
   sys_err <= 1'b0;
   if (sys_ren) begin
      case (sys_addr[19:0])

      /* control */
      20'h00000: begin
         sys_ack   <= sys_en;
         sys_rdata <= regs[REG_RW_RB_CTRL];
         end
      20'h00004: begin
         sys_ack   <= sys_en;
         sys_rdata <= regs[REG_RD_RB_STATUS];
         end

      default:   begin
         sys_ack   <= sys_en;
         sys_rdata <= 32'h00000000;
         end

      endcase
      end

   else if (sys_wen) begin                                                                                  // keep sys_ack assignment in this process
      sys_ack <= sys_en;
      end

   else begin
      sys_ack <= 1'b0;
      end
   end

endmodule
