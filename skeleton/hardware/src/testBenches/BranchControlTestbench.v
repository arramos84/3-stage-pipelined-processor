// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps
`include "Opcode.vh"

module BranchControlTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Inputs and outputs for StoreControl
  reg [5:0]  opcode;
  reg [4:0]      rs;
  reg [4:0]      rt;
  wire       branch;
  reg        REFout;

   // Task for checking output
   task checkOutput;
        if ( REFout !== branch) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tbranch: 0x%h, REFout: 0x%h", branch, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\tbranch: 0x%h, REFout: 0x%h", branch, REFout);
        end
   endtask

  BranchControl DUT(.opcodeE(opcode),
		    .rsE(rs),
		    .rtE(rt),
		    .branch(branch));
           
  //declare looping variables
  integer i;
  localparam loops = 100;

  // Testing logic:

  initial begin
     #1;
    //Make sure branches work properly
    $display("\nVerifying BEQ/BNE work properly...");

    $display("\nVerifying branch is high when it is supposed to be for BEQ and BNE...");
    for(i = 0; i < loops; i = i + 1)
    begin
	rt = {$random} & 5'b11111;
	rs = {$random} & 5'b11111;
	#1;
    	if(i < 50) opcode = `BEQ; 
	else opcode = `BNE;
	#1;
	if(rs == rt && i < 50) REFout = 1'b1;
	else if(rs != rt && i >= 50) REFout = 1'b1;
        else REFout = 1'b0;
	checkOutput();
        #1;
    end

    $display("\nVerifying branch is high when it is supposed to be for BLEZ and BGTZ...");
    for(i = 0; i < loops; i = i + 1)
    begin
	rs = {$random} & 5'b11111;
	#1;
    	if(i < 50) opcode = `BLEZ; 
	else opcode = `BGTZ;
	#1;
	if(rs <= 5'b0 && i < 50) REFout = 1'b1;
	else if(rs > 5'b0 && i >= 50) REFout = 1'b1;
        else REFout = 1'b0;
	checkOutput();
        #1;
    end

    $display("\nVerifying branch is high when it is supposed to be for BLTZ and BGEZ...");
    for(i = 0; i < loops; i = i + 1)
    begin
	rs = {4'b0, {$random} & 1'b1};
	rt = {4'b0,{$random} & 1'b1};
	#1;
    	opcode = `BLTZBGEZ;
	#1;
	if((rs < 5'b0 && rt == 5'b0) | (rs >= 5'b0 && rt == 5'b00001)) REFout = 1'b1;
        else REFout = 1'b0;
	checkOutput();
        #1;
    end

    $display("All tests passed!");
    $finish();
  end
endmodule
