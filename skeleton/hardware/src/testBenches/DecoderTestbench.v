// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps
`include "Opcode.vh"

module DecoderTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Inputs and outputs for StoreControl
  reg [5:0]         OpcodeE;
  reg [5:0]           Funct;
  reg [4:0]             RsE;
  reg [4:0]             RtE;
  wire		 SignExtend;
  wire               RegDst;
  wire		    PCplus8;
  wire		     ALUsrc;
  wire		      Shift;
  wire		  MemToRegE;
  wire		  RegWriteE;
  wire		      JumpE;
  wire		       JReg;
  wire               Branch;
  reg   [7:0]         Zeros;
  reg   [7:0]       REFout;
  reg   [6:0]       REFout2;
  reg   [4:0]       REFout3;
  reg   [5:0]       REFout4;
  reg   [3:0]       REFout5;
  reg               REFoutB;

   // Tasks for checking output
   
   task checkOutput_Jalr;
        if ( REFout !== {RegDst, PCplus8, Shift, MemToRegE, RegWriteE, JumpE, JReg, Branch}) begin
            $display("FAIL: Incorrect result for Jalr!!!");
            $display("\tDUTout: %b, REFout: %b", {RegDst, PCplus8, Shift, MemToRegE, RegWriteE, JumpE, JReg, Branch}, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for Jalr!!!!");
            $display("\tDUTout: %b, REFout: %b", {RegDst, PCplus8, Shift, MemToRegE, RegWriteE, JumpE, JReg, Branch}, REFout);
        end
   endtask
   
   task checkOutput_Rtype;
        if ( REFout2 !== {RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}) begin
            $display("FAIL: Incorrect result for rtypes!!!");
            $display("\tDUTout: %b, REFout2: %b", {RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout2);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for rtypes!!!!");
            $display("\tDUTout: %b, REFout2: %b", {RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout2);
        end
   endtask
   
   task checkOutput_Shifts;
        if ( REFout2 !== {RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}) begin
            $display("FAIL: Incorrect result for shifts!!!");
            $display("\tDUTout: %b, REFout2: %b", {RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout2);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for shifts!!!!");
            $display("\tDUTout: %b, REFout2: %b", {RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout2);
        end
   endtask
   
   task checkOutput_Jr;
        if ( REFout3 !== {Shift, RegWriteE, JumpE, JReg, Branch}) begin
            $display("FAIL: Incorrect result JR!!!");
            $display("\tDUTout: %b, REFout3: %b", {Shift, RegWriteE, JumpE, JReg, Branch}, REFout3);
            $finish();
        end
        else begin
            $display("PASS: Got correct result JR!!!!");
            $display("\tDUTout: %b, REFout3: %b", {Shift, RegWriteE, JumpE, JReg, Branch}, REFout3);
        end
   endtask
   
   task checkOutput_Loads;
        if ( REFout !== {SignExtend, RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}) begin
            $display("FAIL: Incorrect result for loads!!!");
            $display("\tDUTout: %b, REFout: %b", {SignExtend, RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for loads!!!!");
            $display("\tDUTout: %b, REFout: %b", {SignExtend, RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout);
        end
   endtask
   
   task checkOutput_Itype;
        if ( REFout !== {SignExtend, RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}) begin
            $display("FAIL: Incorrect result for itypes!!!");
            $display("\tDUTout: %b, REFout: %b", {SignExtend, RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for itypes!!!!");
            $display("\tDUTout: %b, REFout: %b", {SignExtend, RegDst, ALUsrc, Shift, MemToRegE, RegWriteE, JumpE, Branch}, REFout);
        end
   endtask
   
   task checkOutput_Stores;
        if ( REFout4 !== {SignExtend, ALUsrc, Shift, RegWriteE, JumpE, Branch}) begin
            $display("FAIL: Incorrect result for stores!!!");
            $display("\tDUTout: %b, REFout4: %b", {SignExtend, ALUsrc, Shift, RegWriteE, JumpE, Branch}, REFout4);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for stores!!!!");
            $display("\tDUTout: %b, REFout4: %b", {SignExtend, ALUsrc, Shift, RegWriteE, JumpE, Branch}, REFout4);
        end
   endtask
   
   task checkOutput_Lui;
        if ( REFout2 !== {SignExtend, RegDst, ALUsrc, MemToRegE, RegWriteE, JumpE, Branch}) begin
            $display("FAIL: Incorrect result for lui!!!");
            $display("\tDUTout: %b, REFout2: %b", {SignExtend, RegDst, ALUsrc, MemToRegE, RegWriteE, JumpE, Branch}, REFout2);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for lui!!!!");
            $display("\tDUTout: %b, REFout2: %b", {SignExtend, RegDst, ALUsrc, MemToRegE, RegWriteE, JumpE, Branch}, REFout2);
        end
   endtask
   
   task checkOutput_Jal;
        if ( REFout4 !== {PCplus8, MemToRegE, RegWriteE, JumpE, JReg, Branch}) begin
            $display("FAIL: Incorrect result for Jal!!!");
            $display("\tDUTout: %b, REFout: %b", {PCplus8, MemToRegE, RegWriteE, JumpE, JReg, Branch}, REFout4);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for Jal!!!!");
            $display("\tDUTout: %b, REFout: %b", {PCplus8, MemToRegE, RegWriteE, JumpE, JReg, Branch}, REFout4);
        end
   endtask
   
   task checkOutput_Jump;
        if ( REFout5 !== {RegWriteE, JumpE, JReg, Branch}) begin
            $display("FAIL: Incorrect result for Jump!!!");
            $display("\tDUTout: %b, REFout5: %b", {RegWriteE, JumpE, JReg, Branch}, REFout5);
            $finish();
        end
        else begin
            $display("PASS: Got correct result for Jump!!!!");
            $display("\tDUTout: %b, REFout5: %b", {RegWriteE, JumpE, JReg, Branch}, REFout5);
        end
   endtask
   
   task checkOutputBranch;
        if ( REFoutB !== Branch) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tBranch: 0x%h, REFout: 0x%h", Branch, REFoutB);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\tBranch: 0x%h, REFout: 0x%h", Branch, REFoutB);
        end
   endtask

   Decoder DUT(
                  .OpcodeE(OpcodeE),
                  .Funct(Funct),
                  .RsE(RsE),
                  .RtE(RtE),
                  .SignExtend(SignExtend),
                  .RegDst(RegDst),
                  .PCplus8(PCplus8),
                  .ALUsrc(ALUsrc),
                  .Shift(Shift),
                  .MemToRegE(MemToRegE),
                  .RegWriteE(RegWriteE),
                  .JumpE(JumpE),
                  .JReg(JReg),
                  .Branch(Branch)
                );
           
  //declare looping variables
  integer i;
  localparam loops = 100;
  localparam testcases = 3300;
  
  //Test vectors for control signals
  reg [19:0] testvector [0:testcases - 1];
  
  initial begin
     #1;
     
     $display("\nVerifying CONTROL SIGNALS!!!!!");
     
     $readmemb("ghettoDecoderTestVector.input" , testvector );
     
     for(i = 0; i < testcases; i = i + 1) begin
     	
        if(i < 100) begin
        	#4; {OpcodeE, Funct, REFout} = testvector[i];
        	#2;
        	checkOutput_Jalr();
        end	
        else if(i >= 100 && i < 1200) begin
        	#1; {OpcodeE, Funct, REFout2 , Zeros[0]} = testvector[i];
        	#2;
        	checkOutput_Rtype();
        end	
        else if(i >= 1200 && i < 1500) begin
        	#1; {OpcodeE, Funct, REFout2, Zeros[0]} = testvector[i];
        	#2;
        	checkOutput_Shifts();
        end	
        else if(i >= 1500 && i < 1600) begin
        	#1; {OpcodeE, Funct, REFout3, Zeros[2:0]} = testvector[i];
        	#2;
        	checkOutput_Jr();
        end	
        else if(i >= 1600 && i < 2100) begin
        	#1; {OpcodeE, REFout, Zeros[5:0]} = testvector[i];
        	#2;
        	checkOutput_Loads();
        end	
        else if(i >= 2100 && i < 2700) begin
        	#1; {OpcodeE, REFout, Zeros[5:0]} = testvector[i];
        	#2;
        	checkOutput_Itype();
        end	
        else if(i >= 2700 && i < 3000) begin
        	#1; {OpcodeE, REFout4, Zeros[7:0]} = testvector[i];
        	#2;
        	checkOutput_Stores();
        end	
        else if(i >= 3000 && i < 3100) begin
        	#1; {OpcodeE, REFout2, Zeros[6:0]} = testvector[i];
        	#2;
        	checkOutput_Lui();
        end	
        else if(i >= 3100 && i < 3200) begin
        	#1; {OpcodeE, REFout4, Zeros[7:0]} = testvector[i];
        	#2;
        	checkOutput_Jal();
        end	
        else if(i >= 3200 && i < 3300) begin
        	#1; {OpcodeE, REFout5, Zeros[7:0]} = testvector[i];
        	#2;
        	checkOutput_Jump();
        end
     end
     
     
     // Testing logic for branches:
    //Make sure Branches work properly
    $display("\nVerifying BEQ/BNE work properly...");

    $display("\nVerifying Branch is high when it is supposed to be for BEQ and BNE...");
    for(i = 0; i < loops; i = i + 1)
    begin
	RtE = {$random} & 5'b11111;
	RsE = {$random} & 5'b11111;
	#1;
    	if(i < 50) OpcodeE = `BEQ; 
	else OpcodeE = `BNE;
	#1;
	if(RsE == RtE && i < 50) REFoutB = 1'b1;
	else if(RsE != RtE && i >= 50) REFoutB = 1'b1;
        else REFoutB = 1'b0;
	checkOutputBranch();
        #1;
    end

    $display("\nVerifying Branch is high when it is supposed to be for BLEZ and BGTZ...");
    for(i = 0; i < loops; i = i + 1)
    begin
	RsE = {$random} & 5'b11111;
	#1;
    	if(i < 50) OpcodeE = `BLEZ; 
	else OpcodeE = `BGTZ;
	#1;
	if(RsE <= 5'b0 && i < 50) REFoutB = 1'b1;
	else if(RsE > 5'b0 && i >= 50) REFoutB = 1'b1;
        else REFoutB = 1'b0;
	checkOutputBranch();
        #1;
    end

    $display("\nVerifying Branch is high when it is supposed to be for BLTZ and BGEZ...");
    for(i = 0; i < loops; i = i + 1)
    begin
	RsE = {4'b0, {$random} & 1'b1};
	RtE = {4'b0,{$random} & 1'b1};
	#1;
    	OpcodeE = `BLTZBGEZ;
	#1;
	if((RsE < 5'b0 && RtE == 5'b0) | (RsE >= 5'b0 && RtE == 5'b00001)) REFoutB = 1'b1;
        else REFoutB = 1'b0;
	checkOutputBranch();
        #1;
    end

    $display("All tests passed!");
    $finish();
  end
  
  
  
endmodule
