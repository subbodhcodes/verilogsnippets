`include "svunit_defines.svh"

import svunit_pkg::*;

module apb_slave_unit_test;

  string name = "apb_slave_ut";
  svunit_testcase svunit_ut;

  logic [7:0] addr;
  logic [31:0] data, rdata;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  reg         clk;
  reg         rst_n;
  reg [7:0]   paddr;
  reg         pwrite;
  reg         psel;
  reg         penable;
  reg [31:0]  pwdata;
  wire [31:0] prdata;

  // clk generator
  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  apb_slave my_apb_slave(.*);

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();

    //-----------------------------------------
    // move the bus into the IDLE state
    // before each test
    //-----------------------------------------
    idle();

    //-----------------------------
    // then do a reset for the uut
    //-----------------------------
    rst_n = 0;
    repeat (8) @(posedge clk);
    rst_n = 1;
  endtask


  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================
  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */
  endtask


  //===================================
  // All tests are defined between the
  // SVUNIT_TESTS_BEGIN/END macros
  //
  // Each individual test must be
  // defined between `SVTEST(_NAME_)
  // `SVTEST_END
  //
  // i.e.
  //   `SVTEST(mytest)
  //     <test code>
  //   `SVTEST_END
  //===================================
  `SVUNIT_TESTS_BEGIN


  //************************************************************
  // Test:
  //   single_write_then_read
  //
  // Desc:
  //   do a write then a read at the same address
  //************************************************************
  `SVTEST(single_write_then_read)
    addr = 'h32;
    data = 'h61;

    write(addr, data);
    read(addr, rdata);
    `FAIL_IF(data !== rdata);
  `SVTEST_END


  //************************************************************
  // Test:
  //   write_wo_psel
  //
  // Desc:
  //   do a write then a read at the same address but insert a
  //   write without psel asserted during setup to ensure mem
  //   isn't corrupted by a protocol error.
  //************************************************************
  `SVTEST(write_wo_psel)
    addr = 'h0;
    data = 'hffff_ffff;

    write(addr, data);
    write(addr, 'hff, 0, 0);
    read(addr, rdata);
    `FAIL_IF(data !== rdata);
  `SVTEST_END


  //************************************************************
  // Test:
  //   write_wo_write
  //
  // Desc:
  //   do a write then a read at the same address but insert a
  //   write without pwrite asserted during setup to ensure mem
  //   isn't corrupted by a protocol error.
  //************************************************************
  `SVTEST(write_wo_write)
    addr = 'h10;
    data = 'h99;

    write(addr, data);
    write(addr, 'hff, 0, 1, 0);
    read(addr, rdata);
    `FAIL_IF(data !== rdata);
  `SVTEST_END


  //************************************************************
  // Test:
  //   _2_writes_then_2_reads
  //
  // Desc:
  //   Do back-to-back writes then back-to-back reads
  //************************************************************
  `SVTEST(_2_writes_then_2_reads)
    addr = 'hfe;
    data = 'h31;

    write(addr, data, 1);
    write(addr+1, data+1, 1);
    read(addr, rdata, 1);
    `FAIL_IF(data !== rdata);
    read(addr+1, rdata, 1);
    `FAIL_IF(data+1 !== rdata);

  `SVTEST_END


  `SVUNIT_TESTS_END


  // write ()
  //
  // Simple write method used in the unit tests.
  // Includes options for back-to-back writes and protocol
  // errors on the psel and pwrite.
  task write(logic [7:0] addr,
             logic [31:0] data,
             logic back2back = 0,
             logic setup_psel = 1,
             logic setup_pwrite = 1);

    // if !back2back, insert an idle cycle before the write
    if (!back2back) begin
      @(negedge clk);
      psel = 0;
      penable = 0;
    end

    // this is the SETUP state where the psel,
    // pwrite, paddr and pdata are set
    //
    // NOTE:
    //   setup_psel == 0 for protocol errors on the psel
    //   setup_pwrite == 0 for protocol errors on the pwrite
    @(negedge clk);
    psel = setup_psel;
    pwrite = setup_pwrite;
    paddr = addr;
    pwdata = data;
    penable = 0;

    // this is the ENABLE state where the penable is asserted
    @(negedge clk);
    pwrite = 1;
    penable = 1;
    psel = 1;
  endtask


  // read ()
  //
  // Simple read method used in the unit tests.
  // Includes options for back-to-back reads.
  //
  task read(logic [7:0] addr, output logic [31:0] data,
  	        input logic back2back = 0);

    // if !back2back, insert an idle cycle before the read
    if (!back2back) begin
      @(negedge clk);
      psel = 0;
      penable = 0;
    end

    // this is the SETUP state where the psel, pwrite and paddr
    @(negedge clk);
    psel = 1;
    paddr = addr;
    penable = 0;
    pwrite = 0;

    // this is the ENABLE state where the penable is asserted
    @(negedge clk);
    penable = 1;

    // the prdata should be flopped after the subsequent posedge
    @(posedge clk);
    #1 data = prdata;
  endtask

  // idle ()
  //
  // Clear the all the inputs to the uut (i.e. move to the IDLE state)
  task idle();
    @(negedge clk);
    psel = 0;
    penable = 0;
    pwrite = 0;
    paddr = 0;
    pwdata = 0;
  endtask
  
  initial begin
    // Dump waves
    $dumpvars(0, apb_slave_unit_test);
  end

endmodule






module apb_slave
#(
  addrWidth = 8,
  dataWidth = 32
)
(
  input                        clk,
  input                        rst_n,
  input        [addrWidth-1:0] paddr,
  input                        pwrite,
  input                        psel,
  input                        penable,
  input        [dataWidth-1:0] pwdata,
  output logic [dataWidth-1:0] prdata
);

logic [dataWidth-1:0] mem [256];

logic [1:0] apb_st;
const logic [1:0] SETUP = 0;
const logic [1:0] W_ENABLE = 1;
const logic [1:0] R_ENABLE = 2;

// SETUP -> ENABLE
always @(negedge rst_n or posedge clk) begin
  if (rst_n == 0) begin
    apb_st <= 0;
    prdata <= 0;
  end

  else begin
    case (apb_st)
      SETUP : begin
        // clear the prdata
        prdata <= 0;

        // Move to ENABLE when the psel is asserted
        if (psel && !penable) begin
          if (pwrite) begin
            apb_st <= W_ENABLE;
          end

          else begin
            apb_st <= R_ENABLE;
          end
        end
      end

      W_ENABLE : begin
        // write pwdata to memory
        if (psel && penable && pwrite) begin
          mem[paddr] <= pwdata;
        end

        // return to SETUP
        apb_st <= SETUP;
      end

      R_ENABLE : begin

        // read prdata from memory
        if (psel && penable && !pwrite) begin
          prdata <= mem[paddr];
        end

        // return to SETUP
        apb_st <= SETUP; 
      end
    endcase
  end
end 


endmodule

`include "svunit_defines.svh"

import svunit_pkg::*;

module apb_slave_unit_test;

  string name = "apb_slave_ut";
  svunit_testcase svunit_ut;

  logic [7:0] addr;
  logic [31:0] data, rdata;

  //===================================
  // DUT signals
  //===================================
  logic        clk;
  logic        rst_n;
  logic [7:0]  paddr;
  logic        pwrite;
  logic        psel;
  logic        penable;
  logic [31:0] pwdata;
  logic [31:0] prdata;

  // Instantiate DUT with named connections (Cadence dislikes .*)
  apb_slave #(
    .addrWidth(8),
    .dataWidth(32)
  ) my_apb_slave (
    .clk     (clk),
    .rst_n   (rst_n),
    .paddr   (paddr),
    .pwrite  (pwrite),
    .psel    (psel),
    .penable (penable),
    .pwdata  (pwdata),
    .prdata  (prdata)
  );

  // Clock generator
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction

  //===================================
  // Setup
  //===================================
  task setup();
    svunit_ut.setup();
    idle();
    rst_n = 0;
    repeat (8) @(posedge clk);
    rst_n = 1;
  endtask

  //===================================
  // Teardown
  //===================================
  task teardown();
    svunit_ut.teardown();
  endtask

  //===================================
  // Unit Tests
  //===================================
  `SVUNIT_TESTS_BEGIN

  `SVTEST(single_write_then_read)
    addr = 'h32;
    data = 'h61;
    write(addr, data);
    read(addr, rdata);
    `FAIL_IF(data !== rdata);
  `SVTEST_END

  `SVTEST(write_wo_psel)
    addr = 'h0;
    data = 'hffff_ffff;
    write(addr, data);
    write(addr, 'hff, 0, 0);
    read(addr, rdata);
    `FAIL_IF(data !== rdata);
  `SVTEST_END

  `SVTEST(write_wo_write)
    addr = 'h10;
    data = 'h99;
    write(addr, data);
    write(addr, 'hff, 0, 1, 0);
    read(addr, rdata);
    `FAIL_IF(data !== rdata);
  `SVTEST_END

  `SVTEST(_2_writes_then_2_reads)
    addr = 'hfe;
    data = 'h31;
    write(addr, data, 1);
    write(addr+1, data+1, 1);
    read(addr, rdata, 1);
    `FAIL_IF(data !== rdata);
    read(addr+1, rdata, 1);
    `FAIL_IF(data+1 !== rdata);
  `SVTEST_END

  `SVUNIT_TESTS_END

  //===============================
  // Utility Tasks
  //===============================
  task write(
    input logic [7:0] addr,
    input logic [31:0] data,
    input logic back2back = 0,
    input logic setup_psel = 1,
    input logic setup_pwrite = 1
  );
    if (!back2back) begin
      @(negedge clk);
      psel = 0;
      penable = 0;
    end

    @(negedge clk);
    psel = setup_psel;
    pwrite = setup_pwrite;
    paddr = addr;
    pwdata = data;
    penable = 0;

    @(negedge clk);
    pwrite = 1;
    penable = 1;
    psel = 1;
  endtask

  task read(
    input logic [7:0] addr,
    output logic [31:0] data,
    input logic back2back = 0
  );
    if (!back2back) begin
      @(negedge clk);
      psel = 0;
      penable = 0;
    end

    @(negedge clk);
    psel = 1;
    paddr = addr;
    penable = 0;
    pwrite = 0;

    @(negedge clk);
    penable = 1;

    @(posedge clk);
    #1 data = prdata;
  endtask

  task idle();
    @(negedge clk);
    psel = 0;
    penable = 0;
    pwrite = 0;
    paddr = 0;
    pwdata = 0;
  endtask

  // Cadence-compatible waveform dumping
  initial begin
    `ifdef FSDB
      $fsdbDumpfile("wave.fsdb");
      $fsdbDumpvars(0, apb_slave_unit_test, "+mda");
    `elsif SHM
      $shm_open("wave.shm");
      $shm_probe("AS", apb_slave_unit_test, "AS");
    `endif
  end

endmodule
