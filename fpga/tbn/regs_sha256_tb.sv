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

sys_bus_model i_bus (
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

regs i_regs (
  // clocks & reset
  .clks           ( clks                    ),  // clocks
  .rstsn          ( rstsn                   ),  // clock reset lines - active low

   // activation
  .x11_activated  ( x11_activated           ),

  // System bus
  .sys_addr       ( sys_addr                ),
  .sys_wdata      ( sys_wdata               ),
  .sys_sel        ( sys_sel                 ),
  .sys_wen        ( sys_wen                 ),
  .sys_ren        ( sys_ren                 ),
  .sys_rdata      ( sys_rdata               ),
  .sys_err        ( sys_err                 ),
  .sys_ack        ( sys_ack                 )
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
  i_bus.write(20'h00000, 32'h00000001);         // control: enable
  i_bus.write(20'h00100, 32'h00000001);         // SHA256 control: ENABLE
  i_bus.write(20'h00200, 32'h00000000);         // KECCAK512 control: no ENABLE
  repeat(2) @(posedge clk_125mhz);

  i_bus.write(20'h00100, 32'h00000003);         // SHA256 control: RESET trigger | ENABLE
  repeat(2) @(posedge clk_125mhz);

  // write data to the FIFO - test FIFO
/*
  i_bus.write(20'h0010C, 32'h12345678);         // SHA256 FIFO MSB - #0
  i_bus.write(20'h0010C, 32'h23456789);         // SHA256 FIFO LSB - #0 - one bit after the last data message is set
  i_bus.write(20'h0010C, 32'h3456789A);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h456789AB);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h56789ABC);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h6789ABCD);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h789ABCDE);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h89ABCDEF);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h9ABCDEF0);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'hABCDEF01);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'hBCDEF012);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'hCDEF0123);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'hDEF01234);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'hEF012345);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'hF0123456);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h01234567);         // SHA256 FIFO LSB - #7
*/

  // write data to the FIFO - MSB first
  // variant 1: have a single letter 'A' - OK
/*
  i_bus.write(20'h0010C, 32'h41800000);         // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #0
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h00000008);         // SHA256 FIFO LSB - #7
  // result shall be: 559aead08264d5795d3909718cdd05abd49572e84fe55590eef31a88a08fdffd
*/


  // variant 2: have two letters 'A' - OK
/*
  i_bus.write(20'h0010C, 32'h41418000);         // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #0
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h00000010);         // SHA256 FIFO LSB - #7 2x8 bit = 16d = 0x10
  // result shall be: 58bb119c35513a451d24dc20ef0e9031ec85b35bfc919d263e7e5d9868909cb5
*/


  // variant 3: have 55x the letter 'A' - OK
/*
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'h41414180);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h000001B8);         // SHA256 FIFO LSB - #7   55x8 bit = 440d = 0x1B8
  // result shall be: 8963cc0afd622cc7574ac2011f93a3059b3d65548a77542a1559e3d202e6ab00
*/


/*
  // variant 4: have 56x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'h80000000);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #7
  // second block follows
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #8
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #8
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #9
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #9
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #10
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #10
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #11
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #11
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #12
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #12
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #13
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #13
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #14
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #14
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #15
  i_bus.write(20'h0010C, 32'h000001C0);         // SHA256 FIFO LSB - #15  56x8 bit = 448d = 0x1C0
  // result shall be: 6ea719cefa4b31862035a7fa606b7cc3602f46231117d135cc7119b3c1412314
*/


/*
  // variant 5: have 64x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #7
  // second block follows
  i_bus.write(20'h0010C, 32'h80000000);         // SHA256 FIFO MSB - #8
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #8
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #9
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #9
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #10
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #10
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #11
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #11
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #12
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #12
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #13
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #13
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #14
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO LSB - #14
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #15
  i_bus.write(20'h0010C, 32'h00000200);         // SHA256 FIFO LSB - #15  64x8 bit = 512d = 0x200
  // result shall be: d53eda7a637c99cc7fb566d96e9fa109bf15c478410a3f5eb4d4c4e26cd081f6
*/


  // variant 6: have 119x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #0
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #1
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #2
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #3
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #4
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #5
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #6
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #6
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #7
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #7
  // second block follows
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #8
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #8
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #9
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #9
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #10
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #10
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #11
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #11
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #12
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #12
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #13
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO LSB - #13
  i_bus.write(20'h0010C, 32'h41414141);         // SHA256 FIFO MSB - #14
  i_bus.write(20'h0010C, 32'h41414180);         // SHA256 FIFO LSB - #14
  i_bus.write(20'h0010C, 32'h00000000);         // SHA256 FIFO MSB - #15
  i_bus.write(20'h0010C, 32'h000003B8);         // SHA256 FIFO LSB - #15  119x8 bit = 952d = 0x3B8
  // result shall be: 17d2f0f7197a6612e311d141781f2b9539c4aef7affd729246c401890e000dde


  i_bus.read (20'h00104, task_check);           // read result register
  while (!(task_check & 32'h00000002)) begin    // wait until sha256_hash_valid is set
     i_bus.read (20'h00104, task_check);
     end

/*
  i_bus.read(20'h00104, task_check);            // read result register
  if (!(task_check & 32'h00000010))
     $display("PASS - Task:01.01 read REG_RD_SHA256_STATUS");
  else
     $display("FAIL - Task:01.01 read REG_RD_SHA256_STATUS, read=%08x, masked read=%08x, (should be: %08x)", task_check, task_check & 32'h00000010, 32'h00000000);

  repeat(115) @(posedge clk_125mhz);

  i_bus.read(20'h00104, task_check);            // read result register
  if (task_check & 32'h00000002)
     $display("PASS - Task:01.02 read REG_RD_SHA256_STATUS");
  else
     $display("FAIL - Task:01.02 read REG_RD_SHA256_STATUS, read=%08x, masked read=%08x, (should be: %08x)", task_check, task_check & 32'h00000002, 32'h00000002);
*/

  $display("INFO - Task:99 disabling regs sub-module");
  i_bus.write(20'h00000, 32'h00000000);         // control: disable
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
