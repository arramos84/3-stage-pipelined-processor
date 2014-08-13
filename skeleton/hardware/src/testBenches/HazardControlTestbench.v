// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps

module HazardControlTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Inputs and outputs for StoreControl
  reg [31:0]    Instr;
  reg [4:0]       RsE;
  reg [4:0]       RtE;
  reg [4:0]  WriteReg;
  reg        Stall;
  reg        RegWrite;
  wire       ForwardA;
  wire       ForwardB;
  wire       StallCPU;
  reg        REFout;

   // Task for checking output
   task checkOutputFA;
        if ( REFout !== ForwardA ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tForwardA: 0x%h, REFout: 0x%h", ForwardA, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\tForwardA: 0x%h, REFout: 0x%h", ForwardA, REFout);
        end
   endtask

   task checkOutputFB;
        if ( REFout !== ForwardB ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tForwardB: 0x%h, REFout: 0x%h", ForwardB, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\tForwardB: 0x%h, REFout: 0x%h", ForwardB, REFout);
        end
   endtask

  task checkOutputStall;
        if ( REFout !== StallCPU ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tStallCPU: 0x%h, REFout: 0x%h", StallCPU, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\tStallCPU: 0x%h, REFout: 0x%h", StallCPU, REFout);
        end
   endtask

  HazardControl DUT(.RsE(Instr[25:21]),
		    .RtE(Instr[20:16]),
		    .WriteRegM(WriteReg),
		    .Stall(Stall),
                    .RegWriteM(RegWrite),
	            .StallCPU(StallCPU),
                    .ForwardA_E(ForwardA),
		    .ForwardB_E(ForwardB));
           
  //declare looping variables
  integer i;
  localparam loops = 100;

  // Testing logic:

  initial begin
     #1;
    // Verifying Forwarding of Operand A functions properly
    $display("\nVerifying Forwarding of Operand A functions properly...");

    //Make sure ForwardA is always zero when RegWrite is low.

    $display("\nMake sure ForwardA is zero when RegWrite is low.");
    for(i = 0; i < loops; i = i + 1)
    begin
    	RegWrite = 1'b0;
	#1;
	Instr = 32'b0;
	#1;
	Instr[25:21] = {$random} & 5'b11111;
	#2;
	WriteReg = Instr[25:21];
	#2;
	REFout = 1'b0;
        #1;
	checkOutputFA();
        #1;
    end

    //Make sure ForwardA is zero when WriteReg isn't equal to rs
    $display("\nMake sure ForwardA is zero when WriteReg isn't equal to rs.");
    for(i = 0; i < loops; i = i + 1)
    begin
    	RegWrite = 1'b1;
        Instr = 32'b0;
	#2;
	Instr[25:21] = {$random} & 5'b11111;
	#2;
	while(WriteReg === Instr[25:21])
		WriteReg = {$random} & 5'b11111;
	#2;
	REFout = 1'b0;
	#1;
	checkOutputFA();
        #1;
    end

    //Make sure ForwardA is high when rs equals WriteRegM & regwrite is high

    $display("\nMake sure ForwardA is high when rs equals WriteRegM & regwrite is high.");
    for(i = 0; i < loops; i = i + 1)
    begin
    	RegWrite = 1'b1;
	Instr = 32'b0;
	#1;
        while(Instr[25:21] == 5'b0)
		Instr[25:21] = {$random} & 5'b11111;
	#2;
	WriteReg = Instr[25:21];
	#2;
	REFout = 1'b1;
	#1;
	checkOutputFA();
        #1;
    end

    // Verifying Forwarding of Operand B functions properly
    $display("\nVerifying Forwarding of Operand B functions properly...");

     for(i = 0; i < loops; i = i + 1)
    begin
    	RegWrite = 1'b0;
	Instr = 32'b0;
	#1;
	Instr[20:16] = {$random} & 5'b11111;
	#2;
	WriteReg = Instr[20:16];
	#2;
	REFout = 1'b0;
        #1;
	checkOutputFB();
        #1;
    end

    //Make sure ForwardB is zero when WriteReg isn't equal to rt
    $display("\nMake sure ForwardB is zero when WriteReg isn't equal to rt.");
    for(i = 0; i < loops; i = i + 1)
    begin
    	RegWrite = 1'b1;
	Instr = 32'b0;
	#1;
	Instr[20:16] = {$random} & 5'b11111;
	#2;
	while(WriteReg === Instr[20:16])
		WriteReg = {$random} & 5'b11111;
	#2;
	REFout = 1'b0;
	#1;
	checkOutputFB();
        #1;
    end

    //Make sure ForwardB is high when rt equals WriteRegM & regwrite is high

    $display("\nMake sure ForwardB is high when rt equals WriteRegM & regwrite is high.");
    for(i = 0; i < loops; i = i + 1)
    begin
    	RegWrite = 1'b1;
	Instr = 32'b0;
	#1;
        while(Instr[20:16] == 5'b0)
		Instr[20:16] = {$random} & 5'b11111;
	#2;
	WriteReg = Instr[20:16];
	#2;
	REFout = 1'b1;
	#1;
	checkOutputFB();
        #1;
    end

    //Stall Check
    $display("\nMake sure CPU stalls when stall is high/doesn't when stall is low.");
    for(i = 0; i < loops; i = i + 1)
    begin  

	Stall = 1'b1;
	#1;
	REFout = 1'b1;
	#1;
	checkOutputStall();
	#1;
	Stall = 1'b0;
	#1;
	REFout = 1'b0;
	#1;
	checkOutputStall();
    end

    $display("All tests passed!");
    $finish();
  end
endmodule
