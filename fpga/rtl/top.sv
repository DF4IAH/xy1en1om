`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DF4IAH-Solutions
// Engineer: Ulrich Habel, DF4IAH
//
// Create Date: 29.05.2016 22:21:43
// Design Name: x11, sha3
// Module Name: top
// Project Name: xy1en1om
// Target Devices: xc7z010clg400-1
// Tool Versions: Vivado 2015.4
// Description: top design of FPGA section of Zynq010 on the RedPitaya V1.1 board
//
// Dependencies: Hardware RedPitaya V1.1 board, Software RedPitaya image with uboot and Ubuntu partition
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module top (
   // PS connections
   inout  [  53: 0] FIXED_IO_mio       ,
   inout            FIXED_IO_ps_clk    ,
   inout            FIXED_IO_ps_porb   ,
   inout            FIXED_IO_ps_srstb  ,
   inout            FIXED_IO_ddr_vrn   ,
   inout            FIXED_IO_ddr_vrp   ,

   // DDR
   inout  [  14: 0] DDR_addr           ,
   inout  [   2: 0] DDR_ba             ,
   inout            DDR_cas_n          ,
   inout            DDR_ck_n           ,
   inout            DDR_ck_p           ,
   inout            DDR_cke            ,
   inout            DDR_cs_n           ,
   inout  [   3: 0] DDR_dm             ,
   inout  [  31: 0] DDR_dq             ,
   inout  [   3: 0] DDR_dqs_n          ,
   inout  [   3: 0] DDR_dqs_p          ,
   inout            DDR_odt            ,
   inout            DDR_ras_n          ,
   inout            DDR_reset_n        ,
   inout            DDR_we_n           ,


   // Red Pitaya periphery

   // ADC
   input  [  15: 2] adc_dat_a_i        ,  // ADC CH1
   input  [  15: 2] adc_dat_b_i        ,  // ADC CH2
   input            adc_clk_p_i        ,  // ADC data clock
   input            adc_clk_n_i        ,  // ADC data clock
   output [   1: 0] adc_clk_o          ,  // optional ADC clock source
   output           adc_cdcs_o         ,  // ADC clock duty cycle stabilizer

   // DAC
   output [  13: 0] dac_dat_o          ,  // DAC combined data
   output           dac_wrt_o          ,  // DAC write
   output           dac_sel_o          ,  // DAC channel select
   output           dac_clk_o          ,  // DAC clock
   output           dac_rst_o          ,  // DAC reset

   // PWM DAC
   output [   3: 0] dac_pwm_o          ,  // serial PWM DAC

   // XADC
   input  [   4: 0] vinp_i             ,  // voltages p
   input  [   4: 0] vinn_i             ,  // voltages n

   // Expansion connector
   inout  [   7: 0] exp_p_io           ,
   inout  [   7: 0] exp_n_io           ,

   // SATA connectors
   output [   1: 0] daisy_p_o          ,  // line 1 is clock capable
   output [   1: 0] daisy_n_o          ,
   input  [   1: 0] daisy_p_i          ,  // line 1 is clock capable
   input  [   1: 0] daisy_n_i          ,

   // LED
   output [   7: 0] led_o
);


////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// PLL signals
wire                  adc_clk_in;
wire                  pll_adc_clk;
wire                  pll_dac_clk_1x;
wire                  pll_dac_clk_2x;
wire                  pll_dac_clk_2p;
wire                  pll_ser_clk;
wire                  pll_pwm_clk;
wire                  pll_locked;

// fast serial signals
wire                  ser_clk;

// Interrupt signals
wire         [  15:1] irqs = { 15'b0 };                                                                     // irqs[1] is mapped to IRQ-ID=62, SPI[30] -  high active. SPI[30]: play IRQ, SPI[31]: record IRQ

// ADC signals
wire                  adc_clk;
reg                   adc_rstn;
reg          [  13:0] adc_dat_a, adc_dat_b;
wire  signed [  13:0] adc_a    , adc_b    ;

// DAC signals
wire                  dac_clk_1x;
wire                  dac_clk_2x;
wire                  dac_clk_2p;
reg                   dac_rst;
reg          [  13:0] dac_dat_a, dac_dat_b;
wire         [  13:0] dac_a    , dac_b    ;
wire  signed [  14:0] dac_a_sum, dac_b_sum;

wire         [  15:0] rb_out_ch[1:0];

wire                  x11_activated;

// TODO: to be removed when rb_out_ch[x] driver exists
assign rb_out_ch[0] = 16'b0;
assign rb_out_ch[1] = 16'b0;
assign dac_pwm_o    =  4'b0;


//---------------------------------------------------------------------------------
//
//  Connections to PS

wire  [    3: 0] fclk                      ; // [0] = 125.0 MHz, [1] = 250.0 MHz, [2] = 62.5 MHz, [3] = 200.0 MHz.
wire  [    3: 0] frstn                     ;

wire             ps_sys_clk                ;
wire             ps_sys_rstn               ;
wire  [   31: 0] ps_sys_addr               ;
wire  [   31: 0] ps_sys_wdata              ;
wire  [    3: 0] ps_sys_sel                ;
wire             ps_sys_wen                ;
wire             ps_sys_ren                ;
wire  [   31: 0] ps_sys_rdata              ;
wire             ps_sys_err                ;
wire             ps_sys_ack                ;

// AXI masters
wire             axi1_clk    , axi0_clk    ;
wire             axi1_rstn   , axi0_rstn   ;
wire  [   31: 0] axi1_waddr  , axi0_waddr  ;
wire  [   63: 0] axi1_wdata  , axi0_wdata  ;
wire  [    7: 0] axi1_wsel   , axi0_wsel   ;
wire             axi1_wvalid , axi0_wvalid ;
wire  [    3: 0] axi1_wlen   , axi0_wlen   ;
wire             axi1_wfixed , axi0_wfixed ;
wire             axi1_werr   , axi0_werr   ;
wire             axi1_wrdy   , axi0_wrdy   ;

// AXIS MASTER from the XADC
wire             xadc_axis_aclk            ;
wire  [   15: 0] xadc_axis_tdata           ;
wire  [    4: 0] xadc_axis_tid             ;
wire             xadc_axis_tready          ;
wire             xadc_axis_tvalid          ;

red_pitaya_ps i_ps (
  .FIXED_IO_mio       (  FIXED_IO_mio                ),
  .FIXED_IO_ps_clk    (  FIXED_IO_ps_clk             ),
  .FIXED_IO_ps_porb   (  FIXED_IO_ps_porb            ),
  .FIXED_IO_ps_srstb  (  FIXED_IO_ps_srstb           ),
  .FIXED_IO_ddr_vrn   (  FIXED_IO_ddr_vrn            ),
  .FIXED_IO_ddr_vrp   (  FIXED_IO_ddr_vrp            ),

  // DDR
  .DDR_addr      (DDR_addr    ),
  .DDR_ba        (DDR_ba      ),
  .DDR_cas_n     (DDR_cas_n   ),
  .DDR_ck_n      (DDR_ck_n    ),
  .DDR_ck_p      (DDR_ck_p    ),
  .DDR_cke       (DDR_cke     ),
  .DDR_cs_n      (DDR_cs_n    ),
  .DDR_dm        (DDR_dm      ),
  .DDR_dq        (DDR_dq      ),
  .DDR_dqs_n     (DDR_dqs_n   ),
  .DDR_dqs_p     (DDR_dqs_p   ),
  .DDR_odt       (DDR_odt     ),
  .DDR_ras_n     (DDR_ras_n   ),
  .DDR_reset_n   (DDR_reset_n ),
  .DDR_we_n      (DDR_we_n    ),

  .fclk_clk_o    (fclk        ),
  .fclk_rstn_o   (frstn       ),
  .dcm_locked    (pll_locked  ),

  // Interrupts
  .irq_f2p       (irqs        ),

  // ADC analog inputs
  .vinp_i        (vinp_i      ),  // voltages p
  .vinn_i        (vinn_i      ),  // voltages n

   // system read/write channel
  .sys_clk_o     (ps_sys_clk  ),  // system clock
  .sys_rstn_o    (ps_sys_rstn ),  // system reset - active low
  .sys_addr_o    (ps_sys_addr ),  // system read/write address
  .sys_wdata_o   (ps_sys_wdata),  // system write data
  .sys_sel_o     (ps_sys_sel  ),  // system write byte select
  .sys_wen_o     (ps_sys_wen  ),  // system write enable
  .sys_ren_o     (ps_sys_ren  ),  // system read enable
  .sys_rdata_i   (ps_sys_rdata),  // system read data
  .sys_err_i     (ps_sys_err  ),  // system error indicator
  .sys_ack_i     (ps_sys_ack  ),  // system acknowledge signal

  // AXI masters
  .axi1_clk_i    (axi1_clk    ),  .axi0_clk_i    (axi0_clk    ),  // global clock
  .axi1_rstn_i   (axi1_rstn   ),  .axi0_rstn_i   (axi0_rstn   ),  // global reset
  .axi1_waddr_i  (axi1_waddr  ),  .axi0_waddr_i  (axi0_waddr  ),  // system write address
  .axi1_wdata_i  (axi1_wdata  ),  .axi0_wdata_i  (axi0_wdata  ),  // system write data
  .axi1_wsel_i   (axi1_wsel   ),  .axi0_wsel_i   (axi0_wsel   ),  // system write byte select
  .axi1_wvalid_i (axi1_wvalid ),  .axi0_wvalid_i (axi0_wvalid ),  // system write data valid
  .axi1_wlen_i   (axi1_wlen   ),  .axi0_wlen_i   (axi0_wlen   ),  // system write burst length
  .axi1_wfixed_i (axi1_wfixed ),  .axi0_wfixed_i (axi0_wfixed ),  // system write burst type (fixed / incremental)
  .axi1_werr_o   (axi1_werr   ),  .axi0_werr_o   (axi0_werr   ),  // system write error
  .axi1_wrdy_o   (axi1_wrdy   ),  .axi0_wrdy_o   (axi0_wrdy   ),  // system write ready

  // AXIS MASTER from the XADC
  .xadc_axis_aclk     (xadc_axis_aclk             ),  // AXI-streaming from the XADC, clock to the AXI-S FIFO
  .xadc_axis_tdata    (xadc_axis_tdata            ),  // AXI-streaming from the XADC, data
  .xadc_axis_tid      (xadc_axis_tid              ),  // AXI-streaming from the XADC, analog data source channel for this data
  .xadc_axis_tready   (xadc_axis_tready           ),  // AXI-streaming from the XADC, slave indicating ready for data
  .xadc_axis_tvalid   (xadc_axis_tvalid           )   // AXI-streaming from the XADC, data transfer valid
);


////////////////////////////////////////////////////////////////////////////////
// system bus decoder & multiplexer (it breaks memory addresses into 8 regions)
////////////////////////////////////////////////////////////////////////////////

wire              sys_clk   = ps_sys_clk  ;
wire              sys_rstn  = ps_sys_rstn ;
wire  [    31: 0] sys_addr  = ps_sys_addr ;
wire  [    31: 0] sys_wdata = ps_sys_wdata;
wire  [     3: 0] sys_sel   = ps_sys_sel  ;
wire  [8   -1: 0] sys_wen   ;
wire  [8   -1: 0] sys_ren   ;
wire  [8*32-1: 0] sys_rdata ;
wire  [8* 1-1: 0] sys_err   ;
wire  [8* 1-1: 0] sys_ack   ;
wire  [8   -1: 0] sys_cs    ;

assign sys_cs = 8'h01 << sys_addr[22:20];  // one-hot assignment

assign sys_wen = sys_cs & {8{ps_sys_wen}};
assign sys_ren = sys_cs & {8{ps_sys_ren}};

assign ps_sys_rdata = sys_rdata[sys_addr[22:20]*32+:32];

assign ps_sys_err   = |(sys_cs & sys_err);
assign ps_sys_ack   = |(sys_cs & sys_ack);


////////////////////////////////////////////////////////////////////////////////
// PLL (clock and reset)
////////////////////////////////////////////////////////////////////////////////

//(* //KEEP = "TRUE" *)
//(* //ASYNC_REG = "TRUE" *)
adc_clk_pll i_adc_clk_pll (
 // Clock in ports
  .clk_adc_in_p      ( adc_clk_p_i     ),
  .clk_adc_in_n      ( adc_clk_n_i     ),

  // Clock out ports
  .clk_adc           ( adc_clk         ),
  .clk_dac_1x        ( dac_clk_1x      ),
  .clk_dac_2x        ( dac_clk_2x      ),
  .clk_dac_2p        ( dac_clk_2p      ),
  .clk_ser           ( ser_clk         ),
  .clk_pwm           ( pwm_clk         ),

   // Status and control signals
  .reset             ( frstn[0]        ),
  .locked            ( pll_locked      )
);

// ADC reset (active low) 
always @(posedge adc_clk)
adc_rstn <=  frstn[0] &  pll_locked;

// DAC reset (active high)
always @(posedge dac_clk_1x)
dac_rst  <= ~frstn[0] | ~pll_locked;


////////////////////////////////////////////////////////////////////////////////
// ADC IO
////////////////////////////////////////////////////////////////////////////////

// generating ADC clock is disabled
assign adc_clk_o = 2'b10;
//ODDR i_adc_clk_p ( .Q(adc_clk_o[0]), .D1(1'b1), .D2(1'b0), .C(fclk[0]), .CE(1'b1), .R(1'b0), .S(1'b0));
//ODDR i_adc_clk_n ( .Q(adc_clk_o[1]), .D1(1'b0), .D2(1'b1), .C(fclk[0]), .CE(1'b1), .R(1'b0), .S(1'b0));

// ADC clock duty cycle stabilizer is enabled
assign adc_cdcs_o = 1'b1 ;

// IO block registers should be used here
// lowest 2 bits reserved for 16bit ADC
always @(posedge adc_clk)
begin
  adc_dat_a <= adc_dat_a_i[15:2];
  adc_dat_b <= adc_dat_b_i[15:2];
end
    
// transform into 2's complement (negative slope)
assign adc_a = digital_loop ?  dac_a : {adc_dat_a[13], ~adc_dat_a[12:0]};
assign adc_b = digital_loop ?  dac_b : {adc_dat_b[13], ~adc_dat_b[12:0]};


////////////////////////////////////////////////////////////////////////////////
// DAC IO
////////////////////////////////////////////////////////////////////////////////

// output registers + signed to unsigned (also to negative slope)
always @(posedge dac_clk_1x)
begin
   dac_dat_a <= {rb_out_ch[0][15], ~rb_out_ch[0][14:2]};
   dac_dat_b <= {rb_out_ch[1][15], ~rb_out_ch[1][14:2]};
end

// DDR outputs
//ODDR #( .DDR_CLK_EDGE("SAME_EDGE") )  oddr_dac_clk          ( .Q(dac_clk_o), .D1(1'b0     ), .D2(1'b1     ), .C(dac_clk_2p), .CE(1'b1), .R(1'b0   ), .S(1'b0) );
ODDR oddr_dac_clk          ( .Q(dac_clk_o), .D1(1'b0     ), .D2(1'b1     ), .C(dac_clk_2p), .CE(1'b1), .R(1'b0   ), .S(1'b0) );
ODDR oddr_dac_wrt          ( .Q(dac_wrt_o), .D1(1'b0     ), .D2(1'b1     ), .C(dac_clk_2x), .CE(1'b1), .R(1'b0   ), .S(1'b0) );
ODDR oddr_dac_sel          ( .Q(dac_sel_o), .D1(1'b1     ), .D2(1'b0     ), .C(dac_clk_1x), .CE(1'b1), .R(dac_rst), .S(1'b0) );
ODDR oddr_dac_rst          ( .Q(dac_rst_o), .D1(dac_rst  ), .D2(dac_rst  ), .C(dac_clk_1x), .CE(1'b1), .R(1'b0   ), .S(1'b0) );
ODDR oddr_dac_dat [  13:0] ( .Q(dac_dat_o), .D1(dac_dat_b), .D2(dac_dat_a), .C(dac_clk_1x), .CE(1'b1), .R(dac_rst), .S(1'b0) );


//---------------------------------------------------------------------------------
// 0: House Keeping

wire  [  8-1: 0] exp_p_in , exp_n_in ;
wire  [  8-1: 0] exp_p_out, exp_n_out;
wire  [  8-1: 0] exp_p_dir, exp_n_dir;

red_pitaya_hk i_hk (
  // system signals
  .clk_i           (  fclk[0]                    ),  // clock 125.0 MHz
  .rstn_i          (  frstn[0]                   ),  // clock reset - active low

  // LED
  .led_o           (  led_o                      ),  // LED output

  // global configuration
  .digital_loop    (  digital_loop               ),

  // Expansion connector
  .exp_p_dat_i     (  exp_p_in                   ),  // input data
  .exp_p_dat_o     (  exp_p_out                  ),  // output data
  .exp_p_dir_o     (  exp_p_dir                  ),  // 1-output enable
  .exp_n_dat_i     (  exp_n_in                   ),
  .exp_n_dat_o     (  exp_n_out                  ),
  .exp_n_dir_o     (  exp_n_dir                  ),

   // System bus
  .sys_addr        (  sys_addr                   ),  // address
  .sys_wdata       (  sys_wdata                  ),  // write data
  .sys_sel         (  sys_sel                    ),  // write byte select
  .sys_wen         (  sys_wen[0]                 ),  // write enable
  .sys_ren         (  sys_ren[0]                 ),  // read enable
  .sys_rdata       (  sys_rdata[ 0*32+31: 0*32]  ),  // read data
  .sys_err         (  sys_err[0]                 ),  // error indicator
  .sys_ack         (  sys_ack[0]                 )   // acknowledge signal
);

IOBUF i_iobufp [7:0] (.O(exp_p_in), .IO(exp_p_io), .I(exp_p_out), .T(~exp_p_dir) );
IOBUF i_iobufn [7:0] (.O(exp_n_in), .IO(exp_n_io), .I(exp_n_out), .T(~exp_n_dir) );


//---------------------------------------------------------------------------------
// 1: xy1en1om Sub-Module

/*
assign sys_rdata[1*32+:32] = 32'h0;
assign sys_err  [1       ] =  1'b0;
assign sys_ack  [1       ] =  1'b1;
*/

regs i_regs (
  // clock & reset
  .clks            ( fclk                        ),  // clocks
  .rstsn           ( frstn                       ),  // clock reset lines - active low

  // activation
  .x11_activated   ( x11_activated               ),  // x11 crypto engine is enabled

/*
  // ADC data
  .adc_i           ( {adc_b, adc_a}              ),  // ADC data { CHB, CHA }
*/

/*
  // DAC data
  .rb_out_ch       ({rb_out_ch[1], rb_out_ch[0] }),  // RadioBox output signals
*/

  // System bus
  .sys_addr        ( sys_addr                    ),  // address
  .sys_wdata       ( sys_wdata                   ),  // write data
  .sys_sel         ( sys_sel                     ),  // write byte select
  .sys_wen         ( sys_wen[1]                  ),  // write enable
  .sys_ren         ( sys_ren[1]                  ),  // read enable
  .sys_rdata       ( sys_rdata[ 1*32+:32]        ),  // read data
  .sys_err         ( sys_err[1]                  ),  // error indicator
  .sys_ack         ( sys_ack[1]                  ),  // acknowledge signal

  // AXIS MASTER from the XADC
  .xadc_axis_aclk  ( xadc_axis_aclk              ),  // AXI-streaming from the XADC, clock from the AXI-S FIFO
  .xadc_axis_tdata ( xadc_axis_tdata             ),  // AXI-streaming from the XADC, data
  .xadc_axis_tid   ( xadc_axis_tid               ),  // AXI-streaming from the XADC, analog data source channel for this data
  .xadc_axis_tready( xadc_axis_tready            ),  // AXI-streaming from the XADC, slave indicating ready for data
  .xadc_axis_tvalid( xadc_axis_tvalid            ),  // AXI-streaming from the XADC, data transfer valid

  // AXI0 master                 // AXI1 master
  .axi0_clk_o    (axi0_clk   ),  .axi1_clk_o    (axi1_clk   ),
  .axi0_rstn_o   (axi0_rstn  ),  .axi1_rstn_o   (axi1_rstn  ),
  .axi0_waddr_o  (axi0_waddr ),  .axi1_waddr_o  (axi1_waddr ),
  .axi0_wdata_o  (axi0_wdata ),  .axi1_wdata_o  (axi1_wdata ),
  .axi0_wsel_o   (axi0_wsel  ),  .axi1_wsel_o   (axi1_wsel  ),
  .axi0_wvalid_o (axi0_wvalid),  .axi1_wvalid_o (axi1_wvalid),
  .axi0_wlen_o   (axi0_wlen  ),  .axi1_wlen_o   (axi1_wlen  ),
  .axi0_wfixed_o (axi0_wfixed),  .axi1_wfixed_o (axi1_wfixed),
  .axi0_werr_i   (axi0_werr  ),  .axi1_werr_i   (axi1_werr  ),
  .axi0_wrdy_i   (axi0_wrdy  ),  .axi1_wrdy_i   (axi1_wrdy  )
);


//---------------------------------------------------------------------------------
// 2: unused system bus slave ports
assign sys_rdata[2*32+:32] = 32'h0;
assign sys_err  [2       ] =  1'b0;
assign sys_ack  [2       ] =  1'b1;


//---------------------------------------------------------------------------------
// 3: unused system bus slave ports
assign sys_rdata[3*32+:32] = 32'h0;
assign sys_err  [3       ] =  1'b0;
assign sys_ack  [3       ] =  1'b1;


//---------------------------------------------------------------------------------
// 4: unused system bus slave ports
assign sys_rdata[4*32+:32] = 32'h0;
assign sys_err  [4       ] =  1'b0;
assign sys_ack  [4       ] =  1'b1;


//---------------------------------------------------------------------------------
// 5: unused system bus slave port

assign sys_rdata[5*32+:32] = 32'h0;
assign sys_err  [5       ] =  1'b0;
assign sys_ack  [5       ] =  1'b1;

//---------------------------------------------------------------------------------
// 6: unused system bus slave ports

assign sys_rdata[6*32+:32] = 32'h0;
assign sys_err  [6       ] =  1'b0;
assign sys_ack  [6       ] =  1'b1;


//---------------------------------------------------------------------------------
// 7: unused system bus slave ports

assign sys_rdata[7*32+:32] = 32'h0;
assign sys_err  [7       ] =  1'b0;
assign sys_ack  [7       ] =  1'b1;


//---------------------------------------------------------------------------------
//  SATA connectors

assign daisy_p_o = 2'bzz;
assign daisy_n_o = 2'bzz;


endmodule
