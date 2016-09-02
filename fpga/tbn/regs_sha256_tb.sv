`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  DF4IAH solutions
// Engineer: Ulrich Habel
// 
// Create Date: 25.07.2016 20:03:50
// Design Name: 
// Module Name: regs_sha256_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module regs_sha256_tb #(
   // time periods
   realtime  TP125  =   8.0ns,                    // 125.0 MHz
   realtime  TP250  =   4.0ns,                    // 250.0 MHz
   realtime  TP62P5 =  16.0ns,                    //  62.5 MHz (differs to RedPitaya = 50.0 MHz !)
   realtime  TP200  =   5.0ns                     // 200.0 MHz
);


////////////////////////////////////////////////////////////////////////////////
//
// Connections

// System signals
reg [3:0]                  clks;
reg [3:0]                  rstsn;

// System bus
wire           [ 32-1: 0]  sys_addr;
wire           [ 32-1: 0]  sys_wdata;
wire           [  4-1: 0]  sys_sel;
wire                       sys_wen;
wire                       sys_ren;
wire           [ 32-1: 0]  sys_rdata;
wire                       sys_err;
wire                       sys_ack;

/*
// AXI0 bus
wire                       axi0_clk;
wire                       axi0_rstn;
wire           [   31: 0]  axi0_waddr;
wire           [   63: 0]  axi0_wdata;
wire           [    7: 0]  axi0_wsel;
wire                       axi0_wvalid;
wire           [    3: 0]  axi0_wlen;
wire                       axi0_wfixed;
wire                       axi0_werr;
wire                       axi0_wrdy;
wire           [   31: 0]  axi0_raddr;
wire                       axi0_rvalid;
wire           [    7: 0]  axi0_rsel;
wire           [    3: 0]  axi0_rlen;
wire                       axi0_rfixed;
wire           [   63: 0]  axi0_rdata;
wire                       axi0_rrdy;
wire                       axi0_rerr;

// AXI1 bus
wire                       axi1_clk;
wire                       axi1_rstn;
wire           [   31: 0]  axi1_waddr;
wire           [   63: 0]  axi1_wdata;
wire           [    7: 0]  axi1_wsel;
wire                       axi1_wvalid;
wire           [    3: 0]  axi1_wlen;
wire                       axi1_wfixed;
wire                       axi1_werr;
wire                       axi1_wrdy;
wire           [   31: 0]  axi1_raddr;
wire                       axi1_rvalid;
wire           [    7: 0]  axi1_rsel;
wire           [    3: 0]  axi1_rlen;
wire                       axi1_rfixed;
wire           [   63: 0]  axi1_rdata;
wire                       axi1_rrdy;
wire                       axi1_rerr;
*/


// Local
int unsigned               clk_cntr    = 999999;
reg            [ 32-1: 0]  task_check  = 'b0;
wire                       x11_activated;

wire                       clk_125mhz  = clks[0];
wire                       rstn_125mhz = rstsn[0];

wire                       clk_62mhz5  = clks[2];
wire                       rstn_62mhz5 = rstsn[2];


////////////////////////////////////////////////////////////////////////////////
//
// Module instances

sys_bus_model i_sys_bus (
  // system signals
  .clk            ( clk_125mhz              ),
  .rstn           ( rstn_125mhz             ),

  // bus protocol signals
  .sys_addr       ( sys_addr                ),
  .sys_wdata      ( sys_wdata               ),
  .sys_sel        ( sys_sel                 ),
  .sys_wen        ( sys_wen                 ),
  .sys_ren        ( sys_ren                 ),
  .sys_rdata      ( sys_rdata               ),
  .sys_err        ( sys_err                 ),
  .sys_ack        ( sys_ack                 )
);

/*
dma_bus_model i0_dma_bus (
  // system signals
  .axi_clk_i      ( axi0_clk                ),  // global clock
  .axi_rstn_i     ( axi0_rstn               ),  // global reset

  .axi_waddr_i    ( axi0_waddr              ),  // system write address
  .axi_wdata_i    ( axi0_wdata              ),  // system write data
  .axi_wsel_i     ( axi0_wsel               ),  // system write byte select
  .axi_wvalid_i   ( axi0_wvalid             ),  // system write data valid
  .axi_wlen_i     ( axi0_wlen               ),  // system write burst length
  .axi_wfixed_i   ( axi0_wfixed             ),  // system write burst type (fixed / incremental)
  .axi_werr_o     ( axi0_werr               ),  // system write error
  .axi_wrdy_o     ( axi0_wrdy               ),  // system write ready
  .axi_raddr_i    ( axi0_raddr              ),  // system read address
  .axi_rvalid_i   ( axi0_rvalid             ),  // system read data valid
  .axi_rsel_i     ( axi0_rsel               ),  // system read byte select
  .axi_rlen_i     ( axi0_rlen               ),  // system read burst length
  .axi_rfixed_i   ( axi0_rfixed             ),  // system read burst type (fixed / incremental)
  .axi_rdata_o    ( axi0_rdata              ),  // system read data
  .axi_rrdy_o     ( axi0_rrdy               ),  // system read data is ready
  .axi_rerr_o     ( axi0_rerr               )   // system read error
);

dma_bus_model i1_dma_bus (
  // system signals
  .axi_clk_i      ( axi1_clk                ),  // global clock
  .axi_rstn_i     ( axi1_rstn               ),  // global reset

  .axi_waddr_i    ( axi1_waddr              ),  // system write address
  .axi_wdata_i    ( axi1_wdata              ),  // system write data
  .axi_wsel_i     ( axi1_wsel               ),  // system write byte select
  .axi_wvalid_i   ( axi1_wvalid             ),  // system write data valid
  .axi_wlen_i     ( axi1_wlen               ),  // system write burst length
  .axi_wfixed_i   ( axi1_wfixed             ),  // system write burst type (fixed / incremental)
  .axi_werr_o     ( axi1_werr               ),  // system write error
  .axi_wrdy_o     ( axi1_wrdy               ),  // system write ready
  .axi_raddr_i    ( axi1_raddr              ),  // system read address
  .axi_rvalid_i   ( axi1_rvalid             ),  // system read data valid
  .axi_rsel_i     ( axi1_rsel               ),  // system read byte select
  .axi_rlen_i     ( axi1_rlen               ),  // system read burst length
  .axi_rfixed_i   ( axi1_rfixed             ),  // system read burst type (fixed / incremental)
  .axi_rdata_o    ( axi1_rdata              ),  // system read data
  .axi_rrdy_o     ( axi1_rrdy               ),  // system read data is ready
  .axi_rerr_o     ( axi1_rerr               )   // system read error
);
*/


regs i_regs (
  // clocks & reset
  .clks_i             ( clks                    ),  // clocks
  .rstsn_i            ( rstsn                   ),  // clock reset lines - active low

   // activation
  .x11_activated_o    ( x11_activated           ),

  // System bus
  .sys_addr_i         ( sys_addr                ),
  .sys_wdata_i        ( sys_wdata               ),
  .sys_sel_i          ( sys_sel                 ),
  .sys_wen_i          ( sys_wen                 ),
  .sys_ren_i          ( sys_ren                 ),
  .sys_rdata_o        ( sys_rdata               ),
  .sys_err_o          ( sys_err                 ),
  .sys_ack_o          ( sys_ack                 ),

  // AXI streaming master from XADC
  .xadc_axis_aclk_i   ( clk_125mhz              ),
  .xadc_axis_tdata_i  ( 16'b0                   ),
  .xadc_axis_tid_i    (  5'b0                   ),
  .xadc_axis_tready_o (                         ),
  .xadc_axis_tvalid_i (  1'b0                   )

/*
  // AXI0 master
  .axi0_clk_o     ( axi0_clk                ),  // global clock
  .axi0_rstn_o    ( axi0_rstn               ),  // global reset
  .axi0_waddr_o   ( axi0_waddr              ),  // system write address
  .axi0_wdata_o   ( axi0_wdata              ),  // system write data
  .axi0_wsel_o    ( axi0_wsel               ),  // system write byte select
  .axi0_wvalid_o  ( axi0_wvalid             ),  // system write data valid
  .axi0_wlen_o    ( axi0_wlen               ),  // system write burst length
  .axi0_wfixed_o  ( axi0_wfixed             ),  // system write burst type (fixed / incremental)
  .axi0_werr_i    ( axi0_werr               ),  // system write error
  .axi0_wrdy_i    ( axi0_wrdy               ),  // system write ready
  .axi0_raddr_o   ( axi0_raddr              ),  // system read address
  .axi0_rvalid_o  ( axi0_rvalid             ),  // system read data valid
  .axi0_rsel_o    ( axi0_rsel               ),  // system read byte select
  .axi0_rlen_o    ( axi0_rlen               ),  // system read burst length
  .axi0_rfixed_o  ( axi0_rfixed             ),  // system read burst type (fixed / incremental)
  .axi0_rdata_i   ( axi0_rdata              ),  // system read data
  .axi0_rrdy_i    ( axi0_rrdy               ),  // system read data is ready
  .axi0_rerr_i    ( axi0_rerr               ),  // system read error

  // AXI1 master
  .axi1_clk_o     ( axi1_clk                ),  // global clock
  .axi1_rstn_o    ( axi1_rstn               ),  // global reset
  .axi1_waddr_o   ( axi1_waddr              ),  // system write address
  .axi1_wdata_o   ( axi1_wdata              ),  // system write data
  .axi1_wsel_o    ( axi1_wsel               ),  // system write byte select
  .axi1_wvalid_o  ( axi1_wvalid             ),  // system write data valid
  .axi1_wlen_o    ( axi1_wlen               ),  // system write burst length
  .axi1_wfixed_o  ( axi1_wfixed             ),  // system write burst type (fixed / incremental)
  .axi1_werr_i    ( axi1_werr               ),  // system write error
  .axi1_wrdy_i    ( axi1_wrdy               ),  // system write ready
  .axi1_raddr_o   ( axi1_raddr              ),  // system read address
  .axi1_rvalid_o  ( axi1_rvalid             ),  // system read data valid
  .axi1_rsel_o    ( axi1_rsel               ),  // system read byte select
  .axi1_rlen_o    ( axi1_rlen               ),  // system read burst length
  .axi1_rfixed_o  ( axi1_rfixed             ),  // system read burst type (fixed / incremental)
  .axi1_rdata_i   ( axi1_rdata              ),  // system read data
  .axi1_rrdy_i    ( axi1_rrdy               ),  // system read data is ready
  .axi1_rerr_i    ( axi1_rerr               )   // system read error
*/
);


////////////////////////////////////////////////////////////////////////////////
//
// Helpers

/*
// Task: read_blk
logic signed   [ 32-1: 0]  rdata_blk [];

task read_blk (
  input int          adr,
  input int unsigned len
);
  rdata_blk = new [len];
  for (int unsigned i=0; i<len; i++) begin
    bus.read(adr + 4*i, rdata_blk[i]);
  end
endtask: read_blk
*/


////////////////////////////////////////////////////////////////////////////////
//
// Stimuli

// Clock and Reset generation
always begin
   #(TP125 / 2)
   clks[0] = 1'b1;

   if (rstsn[0])
      clk_cntr = clk_cntr + 1;
   else
      clk_cntr = 32'd0;

   #(TP125 / 2)
   clks[0] = 1'b0;
end

initial begin
   rstsn[0] = 1'b1;

   #(10.3 * TP125)
   rstsn[0] = 1'b0;

   repeat(12) @(posedge clks[0]);
   rstsn[0] = 1'b1;
end

always begin
   #(TP250 / 2)
   clks[1] = 1'b1;

   #(TP250 / 2)
   clks[1] = 1'b0;
end

initial begin
   rstsn[1] = 1'b1;

   #(20.3 * TP250)
   rstsn[1] = 1'b0;

   repeat(20) @(posedge clks[1]);
   rstsn[1] = 1'b1;
end

always begin
   #(TP62P5 / 2)
   clks[2] = 1'b1;

   #(TP62P5 / 2)
   clks[2] = 1'b0;
end

initial begin
   rstsn[2] = 1'b1;

   #(5.3 * TP62P5)
   rstsn[2] = 1'b0;

   repeat(5) @(posedge clks[2]);
   rstsn[2] = 1'b1;
end

always begin
   #(TP200 / 2)
   clks[3] = 1'b1;

   #(TP200 / 2)
   clks[3] = 1'b0;
end

initial begin
   rstsn[3] = 1'b1;

   #(15.3 * TP200)
   rstsn[3] = 1'b0;

   repeat(13) @(posedge clks[3]);
   rstsn[3] = 1'b1;
end


////////////////////////////////////////////////////////////////////////////////
//
// Main FSM
initial begin
  #(15.3 * TP125);

  // get to initial state
  wait (rstn_125mhz)
  repeat(2) @(posedge clk_125mhz);

  // TASK 01: enable hash facilities
  i_sys_bus.write(20'h00000, 32'h00000001);       // control: enable
  i_sys_bus.write(20'h00100, 32'h00000001);       // SHA256 control: ENABLE
  i_sys_bus.write(20'h00200, 32'h00000000);       // KECCAK512 control: no ENABLE
  repeat(2) @(posedge clk_125mhz);

// INFO: in SHA256 all values are stored as Little Endian. The resulting hash value is Little Endian, also.


// --- SINGLE HASH TEST

/*
  i_sys_bus.write(20'h00100, 32'h00000003);       // SHA256 control: RESET trigger | ENABLE
  repeat(2) @(posedge clk_125mhz);
*/

  // write data to the FIFO - test FIFO
  i_sys_bus.write(20'h00108, 32'h12345678);       // SHA256 FIFO MSB - #00
  i_sys_bus.write(20'h0010C, 32'h12345678);       // SHA256 FIFO LSB - #00
  i_sys_bus.write(20'h00108, 32'h23456789);       // SHA256 FIFO MSB - #01
  i_sys_bus.write(20'h0010C, 32'h23456789);       // SHA256 FIFO LSB - #01
  i_sys_bus.write(20'h00108, 32'h3456789A);       // SHA256 FIFO MSB - #02
  i_sys_bus.write(20'h0010C, 32'h3456789A);       // SHA256 FIFO LSB - #02
  i_sys_bus.write(20'h00108, 32'h456789AB);       // SHA256 FIFO MSB - #03
  i_sys_bus.write(20'h0010C, 32'h456789AB);       // SHA256 FIFO LSB - #03
  i_sys_bus.write(20'h00108, 32'h56789ABC);       // SHA256 FIFO MSB - #04
  i_sys_bus.write(20'h0010C, 32'h56789ABC);       // SHA256 FIFO LSB - #04
  i_sys_bus.write(20'h00108, 32'h6789ABCD);       // SHA256 FIFO MSB - #05
  i_sys_bus.write(20'h0010C, 32'h6789ABCD);       // SHA256 FIFO LSB - #05
  i_sys_bus.write(20'h00108, 32'h789ABCDE);       // SHA256 FIFO MSB - #06
  i_sys_bus.write(20'h0010C, 32'h789ABCDE);       // SHA256 FIFO LSB - #06
  i_sys_bus.write(20'h00108, 32'h89ABCDEF);       // SHA256 FIFO MSB - #07
  i_sys_bus.write(20'h0010C, 32'h89ABCDEF);       // SHA256 FIFO LSB - #07
  i_sys_bus.write(20'h00108, 32'h9ABCDEF0);       // SHA256 FIFO MSB - #08
  i_sys_bus.write(20'h0010C, 32'h9ABCDEF0);       // SHA256 FIFO LSB - #08
  i_sys_bus.write(20'h00108, 32'hABCDEF01);       // SHA256 FIFO MSB - #09
  i_sys_bus.write(20'h0010C, 32'hABCDEF01);       // SHA256 FIFO LSB - #09
  i_sys_bus.write(20'h00108, 32'hBCDEF012);       // SHA256 FIFO MSB - #10
  i_sys_bus.write(20'h0010C, 32'hBCDEF012);       // SHA256 FIFO LSB - #10
  i_sys_bus.write(20'h00108, 32'hCDEF0123);       // SHA256 FIFO MSB - #11
  i_sys_bus.write(20'h0010C, 32'hCDEF0123);       // SHA256 FIFO LSB - #11
  i_sys_bus.write(20'h00108, 32'hDEF01234);       // SHA256 FIFO MSB - #12
  i_sys_bus.write(20'h0010C, 32'hDEF01234);       // SHA256 FIFO LSB - #12
  i_sys_bus.write(20'h00108, 32'hEF012345);       // SHA256 FIFO MSB - #13
  i_sys_bus.write(20'h0010C, 32'hEF012345);       // SHA256 FIFO LSB - #13
  i_sys_bus.write(20'h00108, 32'hF0123456);       // SHA256 FIFO MSB - #14
  i_sys_bus.write(20'h0010C, 32'hF0123456);       // SHA256 FIFO LSB - #14
  i_sys_bus.write(20'h00108, 32'h01234567);       // SHA256 FIFO MSB - #15
  i_sys_bus.write(20'h0010C, 32'h01234567);       // SHA256 FIFO LSB - #15

/*
  // variant 1: have a single letter 'A' - OK
  i_sys_bus.write(20'h0010C, 32'h41800000);       // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #0
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #1
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #1
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #2
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #2
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #3
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #3
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #4
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #4
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #5
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #5
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #6
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #6
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #7
  i_sys_bus.write(20'h0010C, 32'h00000008);       // SHA256 FIFO LSB - #7
  // result shall be: 559aead08264d5795d3909718cdd05abd49572e84fe55590eef31a88a08fdffd   (Litte Endian)
*/

/*
  // variant 2: have two letters 'A' - OK
  i_sys_bus.write(20'h0010C, 32'h41418000);       // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #0
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #1
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #1
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #2
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #2
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #3
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #3
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #4
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #4
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #5
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #5
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #6
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #6
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #7
  i_sys_bus.write(20'h0010C, 32'h00000010);       // SHA256 FIFO LSB - #7 2x8 bit = 16d = 0x10
  // result shall be: 58bb119c35513a451d24dc20ef0e9031ec85b35bfc919d263e7e5d9868909cb5   (Litte Endian)
*/

/*
  // variant 3: have 55x the letter 'A' - OK
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #6
  i_sys_bus.write(20'h0010C, 32'h41414180);       // SHA256 FIFO LSB - #6 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #7
  i_sys_bus.write(20'h0010C, 32'h000001B8);       // SHA256 FIFO LSB - #7   55x8 bit = 440d = 0x1B8
  // result shall be: 8963cc0afd622cc7574ac2011f93a3059b3d65548a77542a1559e3d202e6ab00   (Litte Endian)
*/

/*
  // variant 4: have 56x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #6
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #6
  i_sys_bus.write(20'h0010C, 32'h80000000);       // SHA256 FIFO MSB - #7 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #7
  // second block follows
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #8
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #8
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #9
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #9
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #10
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #10
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #11
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #11
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #12
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #12
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #13
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #13
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #14
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #14
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #15
  i_sys_bus.write(20'h0010C, 32'h000001C0);       // SHA256 FIFO LSB - #15  56x8 bit = 448d = 0x1C0
  // result shall be: 6ea719cefa4b31862035a7fa606b7cc3602f46231117d135cc7119b3c1412314   (Litte Endian)
*/

/*
  // variant 5: have 64x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #6
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #6
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #7
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #7
  // second block follows
  i_sys_bus.write(20'h0010C, 32'h80000000);       // SHA256 FIFO MSB - #8 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #8
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #9
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #9
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #10
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #10
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #11
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #11
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #12
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #12
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #13
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #13
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #14
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO LSB - #14
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #15
  i_sys_bus.write(20'h0010C, 32'h00000200);       // SHA256 FIFO LSB - #15  64x8 bit = 512d = 0x200
  // result shall be: d53eda7a637c99cc7fb566d96e9fa109bf15c478410a3f5eb4d4c4e26cd081f6   (Litte Endian)
*/

/*
  // variant 6: have 119x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #0
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #1
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #2
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #3
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #4
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #5
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #6
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #6
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #7
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #7
  // second block follows
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #8
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #8
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #9
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #9
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #10
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #10
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #11
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #11
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #12
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #12
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #13
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO LSB - #13
  i_sys_bus.write(20'h0010C, 32'h41414141);       // SHA256 FIFO MSB - #14
  i_sys_bus.write(20'h0010C, 32'h41414180);       // SHA256 FIFO LSB - #14 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO MSB - #15
  i_sys_bus.write(20'h0010C, 32'h000003B8);       // SHA256 FIFO LSB - #15  119x8 bit = 952d = 0x3B8
  // result shall be: 17d2f0f7197a6612e311d141781f2b9539c4aef7affd729246c401890e000dde   (Litte Endian)
*/


// --- DOUBLE HASH TEST

/*
//i_sys_bus.write(20'h00100, 32'h00000003);       // SHA256 control: RESET trigger | ENABLE
  i_sys_bus.write(20'h00100, 32'h00000013);       // SHA256 control: RESET trigger | ENABLE | DBL_HASH
  repeat(2) @(posedge clk_125mhz);

  // INFO: all data is entered as Little Endian

  // variant 7: do a sha256(sha256(x)) operation on Bitcoin blockchain height 125552
  i_sys_bus.write(20'h0010C, 32'h01000000);       // SHA256 FIFO - #00 Version

  i_sys_bus.write(20'h0010C, 32'h81cd02ab);       // SHA256 FIFO - #01 hashPrevBlock: 0x00000000000008a3a41b85b8b29ad444def299fee21793cd8b9e567eab02cd81
  i_sys_bus.write(20'h0010C, 32'h7e569e8b);       // SHA256 FIFO - #02
  i_sys_bus.write(20'h0010C, 32'hcd9317e2);       // SHA256 FIFO - #03
  i_sys_bus.write(20'h0010C, 32'hfe99f2de);       // SHA256 FIFO - #04
  i_sys_bus.write(20'h0010C, 32'h44d49ab2);       // SHA256 FIFO - #05
  i_sys_bus.write(20'h0010C, 32'hb8851ba4);       // SHA256 FIFO - #06
  i_sys_bus.write(20'h0010C, 32'ha3080000);       // SHA256 FIFO - #07
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #08

  i_sys_bus.write(20'h0010C, 32'he320b6c2);       // SHA256 FIFO - #09 hashMerkleRoot: 0x2b12fcf1b09288fcaff797d71e950e71ae42b91e8bdb2304758dfcffc2b620e3
  i_sys_bus.write(20'h0010C, 32'hfffc8d75);       // SHA256 FIFO - #10
  i_sys_bus.write(20'h0010C, 32'h0423db8b);       // SHA256 FIFO - #11
  i_sys_bus.write(20'h0010C, 32'h1eb942ae);       // SHA256 FIFO - #12
  i_sys_bus.write(20'h0010C, 32'h710e951e);       // SHA256 FIFO - #13
  i_sys_bus.write(20'h0010C, 32'hd797f7af);       // SHA256 FIFO - #14
  i_sys_bus.write(20'h0010C, 32'hfc8892b0);       // SHA256 FIFO - #15
  // second block follows
  i_sys_bus.write(20'h0010C, 32'hf1fc122b);       // SHA256 FIFO - #16

  i_sys_bus.write(20'h0010C, 32'hc7f5d74d);       // SHA256 FIFO - #17 Time:  2011-05-21 17:26:31

  i_sys_bus.write(20'h0010C, 32'hf2b9441a);       // SHA256 FIFO - #18 Bits:  dec  440711666

  i_sys_bus.write(20'h0010C, 32'h42a14695);       // SHA256 FIFO - #19 Nonce: dec 2504433986

  i_sys_bus.write(20'h0010C, 32'h80000000);       // SHA256 FIFO - #20 - one bit after the last data message is set
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #21
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #22
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #23
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #24
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #25
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #26
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #27
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #28
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #29
  i_sys_bus.write(20'h0010C, 32'h00000000);       // SHA256 FIFO - #30
  i_sys_bus.write(20'h0010C, 32'h00000280);       // SHA256 FIFO - #31  20x32 bit = 640 = 0x280
  // result shall be: 1dbd981fe6985776b644b173a4d0385ddc1aa2a829688d1e0000000000000000   (Litte Endian)
*/


// --- DMA TEST

/*
  i_sys_bus.write(20'h00140, 32'h10000000);       // SHA256 DMA - base address
  i_sys_bus.write(20'h00144, 32'h00000400);       // SHA256 DMA - bit len
  i_sys_bus.write(20'h00148, 32'h00000260);       // SHA256 DMA - nonce register bit offset (DOUBLE HASH TEST DATA)
  i_sys_bus.write(20'h00100, 32'h00000033);       // SHA256 control: RESET trigger | ENABLE | DBL_HASH | DMA_MODE

// ----

  i_sys_bus.read (20'h00104, task_check);         // read result register
  while (!(task_check & 32'h00000002)) begin      // wait until sha256_hash_valid is set
     i_sys_bus.read (20'h00104, task_check);
     end
*/

  // INFO: result to be interpreted as Litte Endian

/*
  i_sys_bus.read(20'h00104, task_check);          // read result register
  if (!(task_check & 32'h00000010))
     $display("PASS - Task:01.01 read REG_RD_SHA256_STATUS");
  else
     $display("FAIL - Task:01.01 read REG_RD_SHA256_STATUS, read=%08x, masked read=%08x, (should be: %08x)", task_check, task_check & 32'h00000010, 32'h00000000);

  repeat(115) @(posedge clk_125mhz);

  i_sys_bus.read(20'h00104, task_check);          // read result register
  if (task_check & 32'h00000002)
     $display("PASS - Task:01.02 read REG_RD_SHA256_STATUS");
  else
     $display("FAIL - Task:01.02 read REG_RD_SHA256_STATUS, read=%08x, masked read=%08x, (should be: %08x)", task_check, task_check & 32'h00000002, 32'h00000002);
*/

  $display("INFO - Task:99 disabling regs sub-module");
  i_sys_bus.write(20'h00000, 32'h00000000);       // control: disable
  repeat(10) @(posedge clk_125mhz);

  $display("FINISH");
  $finish () ;
end


////////////////////////////////////////////////////////////////////////////////
// Waveforms output
////////////////////////////////////////////////////////////////////////////////

initial begin
  $dumpfile("regs_sha256_tb.vcd");
  $dumpvars(0, regs_sha256_tb);
end


endmodule: regs_sha256_tb
