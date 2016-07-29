`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
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
  realtime  TP100 =  10.0ns                     // 100 MHz
);


////////////////////////////////////////////////////////////////////////////////
//
// Connections

// System signals
int unsigned               clk_cntr = 999999 ;
reg                        clk_100mhz        ;
reg                        rstn_i            ;

// System bus
wire           [ 32-1: 0]  sys_addr          ;
wire           [ 32-1: 0]  sys_wdata         ;
wire           [  4-1: 0]  sys_sel           ;
wire                       sys_wen           ;
wire                       sys_ren           ;
wire           [ 32-1: 0]  sys_rdata         ;
wire                       sys_err           ;
wire                       sys_ack           ;

// Local
reg            [ 32-1: 0]  task_check        ;


////////////////////////////////////////////////////////////////////////////////
//
// Module instances

sys_bus_model bus (
  // system signals
  .clk            ( clk_100mhz              ),
  .rstn           ( rstn_i                  ),

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

regs #(
) regs            (
  // clocks & reset
  .clk_100mhz     ( clk_100mhz              ),  // 100 MHz
  .rstn_i         ( rstn_i                  ),  // reset - active low

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
initial begin
   clk_100mhz = 1'b0;
   rstn_i = 1'b0;

   repeat(10) @(negedge clk_100mhz);
   rstn_i = 1'b1;
end

always begin
   #(TP100 / 2)
   clk_100mhz = 1'b1;

   if (rstn_i)
      clk_cntr = clk_cntr + 1;
   else
      clk_cntr = 32'd0;


   #(TP100 / 2)
   clk_100mhz = 1'b0;
end


// main FSM
initial begin
  // get to initial state
  wait (rstn_i)
  repeat(2) @(posedge clk_100mhz);

  // TASK 01: enable hash facilities
  bus.write(20'h00000, 32'h00000001);           // control: enable

  bus.write(20'h00100, 32'h00000001);           // SHA256 control: RESET
  bus.write(20'h00100, 32'h00000000);           // SHA256 control: (none)

//bus.write(20'h00200, 32'h00000000);           // KECCAK512 control: (none)

  // write data to the FIFO - LSB first
/*
  // variant 1: have a single letter 'A' - OK
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #0
  bus.write(20'h0010C, 32'h41800000);           // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #1
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #1
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #2
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #2
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #3
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #3
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #4
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #4
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #5
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #5
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #6
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #6
  bus.write(20'h0010C, 32'h00000008);           // SHA256 FIFO LSB - #7
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #7
*/


  // variant 2: have two letters 'A' - OK
/*
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #0
  bus.write(20'h0010C, 32'h41418000);           // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #1
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #1
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #2
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #2
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #3
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #3
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #4
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #4
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #5
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #5
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #6
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #6
  bus.write(20'h0010C, 32'h00000010);           // SHA256 FIFO LSB - #7 2x8 bit = 16d = 0x10
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #7
*/


  // variant 3: have 55x the letter 'A' - OK
/*
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #0
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #5
  bus.write(20'h0010C, 32'h41414180);           // SHA256 FIFO LSB - #6
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #6
  bus.write(20'h0010C, 32'h000001B8);           // SHA256 FIFO LSB - #7
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #7   55x8 bit = 440d = 0x1B8
*/


/*
  // variant 4: have 56x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #0
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #6
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #6
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #7
  bus.write(20'h0010C, 32'h80000000);           // SHA256 FIFO MSB - #7
  // second block follows
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #8
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #8 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #9
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #9
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #10
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #10
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #11
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #11
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #12
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #12
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #13
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #13
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #14
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #14
  bus.write(20'h0010C, 32'h000001C0);           // SHA256 FIFO LSB - #15  56x8 bit = 448d = 0x1C0
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #15
*/


/*
  // variant 5: have 64x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #0
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #6
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #6
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #7
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #7
  // second block follows
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #8
  bus.write(20'h0010C, 32'h80000000);           // SHA256 FIFO MSB - #8 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #9
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #9
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #10
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #10
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #11
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #11
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #12
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #12
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #13
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #13
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO LSB - #14
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #14
  bus.write(20'h0010C, 32'h00000200);           // SHA256 FIFO LSB - #15  64x8 bit = 512d = 0x200
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #15
*/


  // variant 6: have 119x the letter 'A' (2x 512 bytes for the hash to be built) - OK
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #0
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #0 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #1
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #2
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #3
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #4
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #5
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #6
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #6
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #7
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #7
  // second block follows
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #8
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #8 - one bit after the last data message is set
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #9
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #9
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #10
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #10
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #11
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #11
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #12
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #12
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO LSB - #13
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #13
  bus.write(20'h0010C, 32'h41414180);           // SHA256 FIFO LSB - #14
  bus.write(20'h0010C, 32'h41414141);           // SHA256 FIFO MSB - #14
  bus.write(20'h0010C, 32'h000003B8);           // SHA256 FIFO LSB - #15  119x8 bit = 952d = 0x3B8
  bus.write(20'h0010C, 32'h00000000);           // SHA256 FIFO MSB - #15

  bus.read (20'h00104, task_check);             // read result register
  while (!(task_check & 32'h00000002)) begin    // wait until sha256_hash_valid is set
     bus.read (20'h00104, task_check);
     end

/*
  bus.read (20'h00104, task_check);             // read result register
  if (!(task_check & 32'h00000010))
     $display("PASS - Task:01.01 read REG_RD_SHA256_STATUS");
  else
     $display("FAIL - Task:01.01 read REG_RD_SHA256_STATUS, read=%08x, masked read=%08x, (should be: %08x)", task_check, task_check & 32'h00000010, 32'h00000000);

  repeat(115) @(posedge clk_100mhz);

  bus.read (20'h00104, task_check);             // read result register
  if (task_check & 32'h00000002)
     $display("PASS - Task:01.02 read REG_RD_SHA256_STATUS");
  else
     $display("FAIL - Task:01.02 read REG_RD_SHA256_STATUS, read=%08x, masked read=%08x, (should be: %08x)", task_check, task_check & 32'h00000002, 32'h00000002);
*/

  $display("INFO - Task:99 disabling regs sub-module");
  bus.write(20'h00000, 32'h00000000);           // control: disable
  repeat(10) @(posedge clk_100mhz);

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