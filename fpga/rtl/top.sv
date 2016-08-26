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

/*
// AXI_ACP master
wire             S_AXI_ACP_aclk            ;
wire  [   31: 0] S_AXI_ACP_araddr          ;
wire  [    1: 0] S_AXI_ACP_arburst         ;
wire  [    3: 0] S_AXI_ACP_arcache         ;
wire  [    2: 0] S_AXI_ACP_arid            ;
wire  [    3: 0] S_AXI_ACP_arlen           ;
wire  [    1: 0] S_AXI_ACP_arlock          ;
wire  [    2: 0] S_AXI_ACP_arprot          ;
wire  [    3: 0] S_AXI_ACP_arqos           ;
wire             S_AXI_ACP_arready         ;
wire  [    2: 0] S_AXI_ACP_arsize          ;
wire  [    4: 0] S_AXI_ACP_aruser          ;
wire             S_AXI_ACP_arvalid         ;
wire  [   31: 0] S_AXI_ACP_awaddr          ;
wire  [    1: 0] S_AXI_ACP_awburst         ;
wire  [    3: 0] S_AXI_ACP_awcache         ;
wire  [    2: 0] S_AXI_ACP_awid            ;
wire  [    3: 0] S_AXI_ACP_awlen           ;
wire  [    1: 0] S_AXI_ACP_awlock          ;
wire  [    2: 0] S_AXI_ACP_awprot          ;
wire  [    3: 0] S_AXI_ACP_awqos           ;
wire             S_AXI_ACP_awready         ;
wire  [    2: 0] S_AXI_ACP_awsize          ;
wire  [    4: 0] S_AXI_ACP_awuser          ;
wire             S_AXI_ACP_awvalid         ;
wire  [    2: 0] S_AXI_ACP_bid             ;
wire             S_AXI_ACP_bready          ;
wire  [    1: 0] S_AXI_ACP_bresp           ;
wire             S_AXI_ACP_bvalid          ;
wire  [   63: 0] S_AXI_ACP_rdata           ;
wire  [    2: 0] S_AXI_ACP_rid             ;
wire             S_AXI_ACP_rlast           ;
wire             S_AXI_ACP_rready          ;
wire  [    1: 0] S_AXI_ACP_rresp           ;
wire             S_AXI_ACP_rvalid          ;
wire  [   63: 0] S_AXI_ACP_wdata           ;
wire  [    2: 0] S_AXI_ACP_wid             ;
wire             S_AXI_ACP_wlast           ;
wire             S_AXI_ACP_wready          ;
wire  [    7: 0] S_AXI_ACP_wstrb           ;
wire             S_AXI_ACP_wvalid          ;
*/

// AXI_HP0 master
wire             S_AXI_HP0_aclk            ;
wire  [   31: 0] S_AXI_HP0_araddr          ;
wire  [    1: 0] S_AXI_HP0_arburst         ;
wire  [    3: 0] S_AXI_HP0_arcache         ;
wire  [    5: 0] S_AXI_HP0_arid            ;
wire  [    3: 0] S_AXI_HP0_arlen           ;
wire  [    1: 0] S_AXI_HP0_arlock          ;
wire  [    2: 0] S_AXI_HP0_arprot          ;
wire  [    3: 0] S_AXI_HP0_arqos           ;
wire             S_AXI_HP0_arready         ;
wire  [    2: 0] S_AXI_HP0_arsize          ;
wire             S_AXI_HP0_arvalid         ;
wire  [   31: 0] S_AXI_HP0_awaddr          ;
wire  [    1: 0] S_AXI_HP0_awburst         ;
wire  [    3: 0] S_AXI_HP0_awcache         ;
wire  [    5: 0] S_AXI_HP0_awid            ;
wire  [    3: 0] S_AXI_HP0_awlen           ;
wire  [    1: 0] S_AXI_HP0_awlock          ;
wire  [    2: 0] S_AXI_HP0_awprot          ;
wire  [    3: 0] S_AXI_HP0_awqos           ;
wire             S_AXI_HP0_awready         ;
wire  [    2: 0] S_AXI_HP0_awsize          ;
wire             S_AXI_HP0_awvalid         ;
wire  [    5: 0] S_AXI_HP0_bid             ;
wire             S_AXI_HP0_bready          ;
wire  [    1: 0] S_AXI_HP0_bresp           ;
wire             S_AXI_HP0_bvalid          ;
wire  [   63: 0] S_AXI_HP0_rdata           ;
wire  [    5: 0] S_AXI_HP0_rid             ;
wire             S_AXI_HP0_rlast           ;
wire             S_AXI_HP0_rready          ;
wire  [    1: 0] S_AXI_HP0_rresp           ;
wire             S_AXI_HP0_rvalid          ;
wire  [   63: 0] S_AXI_HP0_wdata           ;
wire  [    5: 0] S_AXI_HP0_wid             ;
wire             S_AXI_HP0_wlast           ;
wire             S_AXI_HP0_wready          ;
wire  [    7: 0] S_AXI_HP0_wstrb           ;
wire             S_AXI_HP0_wvalid          ;

/* not in use
// AXI masters via axi_master
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
wire  [   31: 0] axi1_raddr  , axi0_raddr  ;
wire             axi1_rvalid , axi0_rvalid ;
wire  [    7: 0] axi1_rsel   , axi0_rsel   ;
wire  [    3: 0] axi1_rlen   , axi0_rlen   ;
wire             axi1_rfixed , axi0_rfixed ;
wire  [   63: 0] axi1_rdata  , axi0_rdata  ;
wire             axi1_rrdy   , axi0_rrdy   ;
wire             axi1_rerr   , axi0_rerr   ;
*/

// AXIS MASTER from the XADC
wire             xadc_axis_aclk            ;
wire  [   15: 0] xadc_axis_tdata           ;
wire  [    4: 0] xadc_axis_tid             ;
wire             xadc_axis_tready          ;
wire             xadc_axis_tvalid          ;

red_pitaya_ps i_ps (
  .FIXED_IO_mio       (FIXED_IO_mio               ),
  .FIXED_IO_ps_clk    (FIXED_IO_ps_clk            ),
  .FIXED_IO_ps_porb   (FIXED_IO_ps_porb           ),
  .FIXED_IO_ps_srstb  (FIXED_IO_ps_srstb          ),
  .FIXED_IO_ddr_vrn   (FIXED_IO_ddr_vrn           ),
  .FIXED_IO_ddr_vrp   (FIXED_IO_ddr_vrp           ),

  // DDR
  .DDR_addr           (DDR_addr                   ),
  .DDR_ba             (DDR_ba                     ),
  .DDR_cas_n          (DDR_cas_n                  ),
  .DDR_ck_n           (DDR_ck_n                   ),
  .DDR_ck_p           (DDR_ck_p                   ),
  .DDR_cke            (DDR_cke                    ),
  .DDR_cs_n           (DDR_cs_n                   ),
  .DDR_dm             (DDR_dm                     ),
  .DDR_dq             (DDR_dq                     ),
  .DDR_dqs_n          (DDR_dqs_n                  ),
  .DDR_dqs_p          (DDR_dqs_p                  ),
  .DDR_odt            (DDR_odt                    ),
  .DDR_ras_n          (DDR_ras_n                  ),
  .DDR_reset_n        (DDR_reset_n                ),
  .DDR_we_n           (DDR_we_n                   ),

  .fclk_clk_o         (fclk                       ),
  .fclk_rstn_o        (frstn                      ),
  .dcm_locked         (pll_locked                 ),

  // Interrupts
  .irq_f2p            (irqs                       ),

  // system read/write channel
  .sys_clk_o          (ps_sys_clk                 ),  // system clock
  .sys_rstn_o         (ps_sys_rstn                ),  // system reset - active low
  .sys_addr_o         (ps_sys_addr                ),  // system read/write address
  .sys_wdata_o        (ps_sys_wdata               ),  // system write data
  .sys_sel_o          (ps_sys_sel                 ),  // system write byte select
  .sys_wen_o          (ps_sys_wen                 ),  // system write enable
  .sys_ren_o          (ps_sys_ren                 ),  // system read enable
  .sys_rdata_i        (ps_sys_rdata               ),  // system read data
  .sys_err_i          (ps_sys_err                 ),  // system error indicator
  .sys_ack_i          (ps_sys_ack                 ),  // system acknowledge signal

/*
  // AXI_ACP master
  .S_AXI_ACP_aclk     (S_AXI_ACP_aclk             ),
  .S_AXI_ACP_araddr   (S_AXI_ACP_araddr           ),
  .S_AXI_ACP_arburst  (S_AXI_ACP_arburst          ),
  .S_AXI_ACP_arcache  (S_AXI_ACP_arcache          ),
  .S_AXI_ACP_arid     (S_AXI_ACP_arid             ),
  .S_AXI_ACP_arlen    (S_AXI_ACP_arlen            ),
  .S_AXI_ACP_arlock   (S_AXI_ACP_arlock           ),
  .S_AXI_ACP_arprot   (S_AXI_ACP_arprot           ),
  .S_AXI_ACP_arqos    (S_AXI_ACP_arqos            ),
  .S_AXI_ACP_arready  (S_AXI_ACP_arready          ),
  .S_AXI_ACP_arsize   (S_AXI_ACP_arsize           ),
  .S_AXI_ACP_aruser   (S_AXI_ACP_aruser           ),
  .S_AXI_ACP_arvalid  (S_AXI_ACP_arvalid          ),
  .S_AXI_ACP_awaddr   (S_AXI_ACP_awaddr           ),
  .S_AXI_ACP_awburst  (S_AXI_ACP_awburst          ),
  .S_AXI_ACP_awcache  (S_AXI_ACP_awcache          ),
  .S_AXI_ACP_awid     (S_AXI_ACP_awid             ),
  .S_AXI_ACP_awlen    (S_AXI_ACP_awlen            ),
  .S_AXI_ACP_awlock   (S_AXI_ACP_awlock           ),
  .S_AXI_ACP_awprot   (S_AXI_ACP_awprot           ),
  .S_AXI_ACP_awqos    (S_AXI_ACP_awqos            ),
  .S_AXI_ACP_awready  (S_AXI_ACP_awready          ),
  .S_AXI_ACP_awsize   (S_AXI_ACP_awsize           ),
  .S_AXI_ACP_awuser   (S_AXI_ACP_awuser           ),
  .S_AXI_ACP_awvalid  (S_AXI_ACP_awvalid          ),
  .S_AXI_ACP_bid      (S_AXI_ACP_bid              ),
  .S_AXI_ACP_bready   (S_AXI_ACP_bready           ),
  .S_AXI_ACP_bresp    (S_AXI_ACP_bresp            ),
  .S_AXI_ACP_bvalid   (S_AXI_ACP_bvalid           ),
  .S_AXI_ACP_rdata    (S_AXI_ACP_rdata            ),
  .S_AXI_ACP_rid      (S_AXI_ACP_rid              ),
  .S_AXI_ACP_rlast    (S_AXI_ACP_rlast            ),
  .S_AXI_ACP_rready   (S_AXI_ACP_rready           ),
  .S_AXI_ACP_rresp    (S_AXI_ACP_rresp            ),
  .S_AXI_ACP_rvalid   (S_AXI_ACP_rvalid           ),
  .S_AXI_ACP_wdata    (S_AXI_ACP_wdata            ),
  .S_AXI_ACP_wid      (S_AXI_ACP_wid              ),
  .S_AXI_ACP_wlast    (S_AXI_ACP_wlast            ),
  .S_AXI_ACP_wready   (S_AXI_ACP_wready           ),
  .S_AXI_ACP_wstrb    (S_AXI_ACP_wstrb            ),
  .S_AXI_ACP_wvalid   (S_AXI_ACP_wvalid           ),
*/

  // AXI_HP master
  .S_AXI_HP0_aclk     (S_AXI_HP0_aclk             ),
  .S_AXI_HP0_araddr   (S_AXI_HP0_araddr           ),
  .S_AXI_HP0_arburst  (S_AXI_HP0_arburst          ),
  .S_AXI_HP0_arcache  (S_AXI_HP0_arcache          ),
  .S_AXI_HP0_arid     (S_AXI_HP0_arid             ),
  .S_AXI_HP0_arlen    (S_AXI_HP0_arlen            ),
  .S_AXI_HP0_arlock   (S_AXI_HP0_arlock           ),
  .S_AXI_HP0_arprot   (S_AXI_HP0_arprot           ),
  .S_AXI_HP0_arqos    (S_AXI_HP0_arqos            ),
  .S_AXI_HP0_arready  (S_AXI_HP0_arready          ),
  .S_AXI_HP0_arsize   (S_AXI_HP0_arsize           ),
  .S_AXI_HP0_arvalid  (S_AXI_HP0_arvalid          ),
  .S_AXI_HP0_awaddr   (S_AXI_HP0_awaddr           ),
  .S_AXI_HP0_awburst  (S_AXI_HP0_awburst          ),
  .S_AXI_HP0_awcache  (S_AXI_HP0_awcache          ),
  .S_AXI_HP0_awid     (S_AXI_HP0_awid             ),
  .S_AXI_HP0_awlen    (S_AXI_HP0_awlen            ),
  .S_AXI_HP0_awlock   (S_AXI_HP0_awlock           ),
  .S_AXI_HP0_awprot   (S_AXI_HP0_awprot           ),
  .S_AXI_HP0_awqos    (S_AXI_HP0_awqos            ),
  .S_AXI_HP0_awready  (S_AXI_HP0_awready          ),
  .S_AXI_HP0_awsize   (S_AXI_HP0_awsize           ),
  .S_AXI_HP0_awvalid  (S_AXI_HP0_awvalid          ),
  .S_AXI_HP0_bid      (S_AXI_HP0_bid              ),
  .S_AXI_HP0_bready   (S_AXI_HP0_bready           ),
  .S_AXI_HP0_bresp    (S_AXI_HP0_bresp            ),
  .S_AXI_HP0_bvalid   (S_AXI_HP0_bvalid           ),
  .S_AXI_HP0_rdata    (S_AXI_HP0_rdata            ),
  .S_AXI_HP0_rid      (S_AXI_HP0_rid              ),
  .S_AXI_HP0_rlast    (S_AXI_HP0_rlast            ),
  .S_AXI_HP0_rready   (S_AXI_HP0_rready           ),
  .S_AXI_HP0_rresp    (S_AXI_HP0_rresp            ),
  .S_AXI_HP0_rvalid   (S_AXI_HP0_rvalid           ),
  .S_AXI_HP0_wdata    (S_AXI_HP0_wdata            ),
  .S_AXI_HP0_wid      (S_AXI_HP0_wid              ),
  .S_AXI_HP0_wlast    (S_AXI_HP0_wlast            ),
  .S_AXI_HP0_wready   (S_AXI_HP0_wready           ),
  .S_AXI_HP0_wstrb    (S_AXI_HP0_wstrb            ),
  .S_AXI_HP0_wvalid   (S_AXI_HP0_wvalid           ),

/* not in use
  // AXI master via axi_master
  .axi1_clk_i        (axi1_clk    ),  .axi0_clk_i        (axi0_clk    ),  // global clock
  .axi1_rstn_i       (axi1_rstn   ),  .axi0_rstn_i       (axi0_rstn   ),  // global reset
  .axi1_waddr_i      (axi1_waddr  ),  .axi0_waddr_i      (axi0_waddr  ),  // system write address
  .axi1_wdata_i      (axi1_wdata  ),  .axi0_wdata_i      (axi0_wdata  ),  // system write data
  .axi1_wsel_i       (axi1_wsel   ),  .axi0_wsel_i       (axi0_wsel   ),  // system write byte select
  .axi1_wvalid_i     (axi1_wvalid ),  .axi0_wvalid_i     (axi0_wvalid ),  // system write data valid
  .axi1_wlen_i       (axi1_wlen   ),  .axi0_wlen_i       (axi0_wlen   ),  // system write burst length
  .axi1_wfixed_i     (axi1_wfixed ),  .axi0_wfixed_i     (axi0_wfixed ),  // system write burst type (fixed / incremental)
  .axi1_werr_o       (axi1_werr   ),  .axi0_werr_o       (axi0_werr   ),  // system write error
  .axi1_wrdy_o       (axi1_wrdy   ),  .axi0_wrdy_o       (axi0_wrdy   ),  // system write ready
  .axi1_raddr_i      (axi1_raddr  ),  .axi0_raddr_i      (axi0_raddr  ),  // system read address
  .axi1_rvalid_i     (axi1_rvalid ),  .axi0_rvalid_i     (axi0_rvalid ),  // system read data valid
  .axi1_rsel_i       (axi1_rsel   ),  .axi0_rsel_i       (axi0_rsel   ),  // system read byte select
  .axi1_rlen_i       (axi1_rlen   ),  .axi0_rlen_i       (axi0_rlen   ),  // system read burst length
  .axi1_rfixed_i     (axi1_rfixed ),  .axi0_rfixed_i     (axi0_rfixed ),  // system read burst type (fixed / incremental)
  .axi1_rdata_o      (axi1_rdata  ),  .axi0_rdata_o      (axi0_rdata  ),  // system read data
  .axi1_rrdy_o       (axi1_rrdy   ),  .axi0_rrdy_o       (axi0_rrdy   ),  // system read data is ready
  .axi1_rerr_o       (axi1_rerr   ),  .axi0_rerr_o       (axi0_rerr   ),  // system read error
*/

  // ADC analog inputs
  .vinp_i             (vinp_i                     ),  // voltages p
  .vinn_i             (vinn_i                     ),  // voltages n

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
  .clk_adc_in_p       (adc_clk_p_i                ),
  .clk_adc_in_n       (adc_clk_n_i                ),

  // Clock out ports
  .clk_adc            (adc_clk                    ),
  .clk_dac_1x         (dac_clk_1x                 ),
  .clk_dac_2x         (dac_clk_2x                 ),
  .clk_dac_2p         (dac_clk_2p                 ),
  .clk_ser            (ser_clk                    ),
  .clk_pwm            (pwm_clk                    ),

   // Status and control signals
  .reset              (frstn[0]                   ),
  .locked             (pll_locked                 )
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
  .clk_i              (fclk[0]                    ),  // clock 125.0 MHz
  .rstn_i             (frstn[0]                   ),  // clock reset - active low

  // LED
  .led_o              (led_o                      ),  // LED output

  // global configuration
  .digital_loop       (digital_loop               ),

  // Expansion connector
  .exp_p_dat_i        (exp_p_in                   ),  // input data
  .exp_p_dat_o        (exp_p_out                  ),  // output data
  .exp_p_dir_o        (exp_p_dir                  ),  // 1-output enable
  .exp_n_dat_i        (exp_n_in                   ),
  .exp_n_dat_o        (exp_n_out                  ),
  .exp_n_dir_o        (exp_n_dir                  ),

   // System bus
  .sys_addr           (sys_addr                   ),  // address
  .sys_wdata          (sys_wdata                  ),  // write data
  .sys_sel            (sys_sel                    ),  // write byte select
  .sys_wen            (sys_wen[0]                 ),  // write enable
  .sys_ren            (sys_ren[0]                 ),  // read enable
  .sys_rdata          (sys_rdata[ 0*32+31: 0*32]  ),  // read data
  .sys_err            (sys_err[0]                 ),  // error indicator
  .sys_ack            (sys_ack[0]                 )   // acknowledge signal
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
  .clks               (fclk                       ),  // clocks
  .rstsn              (frstn                      ),  // clock reset lines - active low

  // activation
  .x11_activated      (x11_activated              ),  // x11 crypto engine is enabled

  // System bus
  .sys_addr           (sys_addr                   ),  // address
  .sys_wdata          (sys_wdata                  ),  // write data
  .sys_sel            (sys_sel                    ),  // write byte select
  .sys_wen            (sys_wen[1]                 ),  // write enable
  .sys_ren            (sys_ren[1]                 ),  // read enable
  .sys_rdata          (sys_rdata[ 1*32+:32]       ),  // read data
  .sys_err            (sys_err[1]                 ),  // error indicator
  .sys_ack            (sys_ack[1]                 ),  // acknowledge signal

  // AXI_HP0 master
  .S_AXI_HP0_aclk     (S_AXI_HP0_aclk             ),
  .S_AXI_HP0_araddr   (S_AXI_HP0_araddr           ),
  .S_AXI_HP0_arburst  (S_AXI_HP0_arburst          ),
  .S_AXI_HP0_arcache  (S_AXI_HP0_arcache          ),
  .S_AXI_HP0_arid     (S_AXI_HP0_arid             ),
  .S_AXI_HP0_arlen    (S_AXI_HP0_arlen            ),
  .S_AXI_HP0_arlock   (S_AXI_HP0_arlock           ),
  .S_AXI_HP0_arprot   (S_AXI_HP0_arprot           ),
  .S_AXI_HP0_arqos    (S_AXI_HP0_arqos            ),
  .S_AXI_HP0_arready  (S_AXI_HP0_arready          ),
  .S_AXI_HP0_arsize   (S_AXI_HP0_arsize           ),
  .S_AXI_HP0_arvalid  (S_AXI_HP0_arvalid          ),
  .S_AXI_HP0_awaddr   (S_AXI_HP0_awaddr           ),
  .S_AXI_HP0_awburst  (S_AXI_HP0_awburst          ),
  .S_AXI_HP0_awcache  (S_AXI_HP0_awcache          ),
  .S_AXI_HP0_awid     (S_AXI_HP0_awid             ),
  .S_AXI_HP0_awlen    (S_AXI_HP0_awlen            ),
  .S_AXI_HP0_awlock   (S_AXI_HP0_awlock           ),
  .S_AXI_HP0_awprot   (S_AXI_HP0_awprot           ),
  .S_AXI_HP0_awqos    (S_AXI_HP0_awqos            ),
  .S_AXI_HP0_awready  (S_AXI_HP0_awready          ),
  .S_AXI_HP0_awsize   (S_AXI_HP0_awsize           ),
  .S_AXI_HP0_awvalid  (S_AXI_HP0_awvalid          ),
  .S_AXI_HP0_bid      (S_AXI_HP0_bid              ),
  .S_AXI_HP0_bready   (S_AXI_HP0_bready           ),
  .S_AXI_HP0_bresp    (S_AXI_HP0_bresp            ),
  .S_AXI_HP0_bvalid   (S_AXI_HP0_bvalid           ),
  .S_AXI_HP0_rdata    (S_AXI_HP0_rdata            ),
  .S_AXI_HP0_rid      (S_AXI_HP0_rid              ),
  .S_AXI_HP0_rlast    (S_AXI_HP0_rlast            ),
  .S_AXI_HP0_rready   (S_AXI_HP0_rready           ),
  .S_AXI_HP0_rresp    (S_AXI_HP0_rresp            ),
  .S_AXI_HP0_rvalid   (S_AXI_HP0_rvalid           ),
  .S_AXI_HP0_wdata    (S_AXI_HP0_wdata            ),
  .S_AXI_HP0_wid      (S_AXI_HP0_wid              ),
  .S_AXI_HP0_wlast    (S_AXI_HP0_wlast            ),
  .S_AXI_HP0_wready   (S_AXI_HP0_wready           ),
  .S_AXI_HP0_wstrb    (S_AXI_HP0_wstrb            ),
  .S_AXI_HP0_wvalid   (S_AXI_HP0_wvalid           ),

  // AXIS MASTER from the XADC
  .xadc_axis_aclk     (xadc_axis_aclk             ),  // AXI-streaming from the XADC, clock from the AXI-S FIFO
  .xadc_axis_tdata    (xadc_axis_tdata            ),  // AXI-streaming from the XADC, data
  .xadc_axis_tid      (xadc_axis_tid              ),  // AXI-streaming from the XADC, analog data source channel for this data
  .xadc_axis_tready   (xadc_axis_tready           ),  // AXI-streaming from the XADC, slave indicating ready for data
  .xadc_axis_tvalid   (xadc_axis_tvalid           )   // AXI-streaming from the XADC, data transfer valid
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


endmodule: top
