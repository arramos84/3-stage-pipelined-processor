// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps

module LoadMaskerTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Inputs and outputs for StoreControl
  reg [31:0] ReadDataM;
  reg [5:0] opcode;
  reg [1:0] addr;
  wire  [31:0] LoadMaskOut;
  reg  [31:0] REFout;

   // Task for checking output
   task checkOutput;
        if ( REFout !== LoadMaskOut ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tLoadMaskOut: 0x%h, REFout: 0x%h", LoadMaskOut, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\tLoadMaskOut: 0x%h, REFout: 0x%h", LoadMaskOut, REFout);
        end
   endtask

  LoadMasker DUT (.ReadDataM(ReadDataM),
		      .opcodeM(opcode),
                        .ALUoutM(addr),
            .LoadMaskOut(LoadMaskOut));
           
  //declare looping variables
  integer i;
  localparam loops = 100;

  // Testing logic:

  initial begin
     #1;
    // Verifying that load bytes function properly
    $display("\nVerifying that load bytes behave properly...");

    //LB
    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b100000;
	addr = {$random} & 2'b11;
	ReadDataM = {$random} & 32'hFFFFFFFF;
	#2;

	case(addr)
		2'b00: REFout = {{24{ReadDataM[31]}}, ReadDataM[31:24]};
		2'b01: REFout = {{24{ReadDataM[23]}}, ReadDataM[23:16]};
		2'b10: REFout = {{24{ReadDataM[15]}}, ReadDataM[15:8]};
		2'b11: REFout = {{24{ReadDataM[7]}}, ReadDataM[7:0]};
	endcase
	#2;

	checkOutput();
	#1;
    end

    //LBU
    #1;
    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b100100;
	addr = {$random} & 2'b11;
	ReadDataM = {$random} & 32'hFFFFFFFF;
	#2;

	case(addr)
		2'b00: REFout = {24'b0, ReadDataM[31:24]};
		2'b01: REFout = {24'b0, ReadDataM[23:16]};
		2'b10: REFout = {24'b0, ReadDataM[15:8]};
		2'b11: REFout = {24'b0, ReadDataM[7:0]};
	endcase
	#2;

	checkOutput();
	#1;
    end

    

     #1;
    // Verifying that load halves function properly
    $display("\nVerifying that load halves behave properly...");

    //LH
    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b100001;
	addr[1] = {$random} & 1'b1;
	ReadDataM = {$random} & 32'hFFFFFFFF;
	#2;

	case(addr[1])
		1'b0: REFout = {{16{ReadDataM[31]}}, ReadDataM[31:16]};
		1'b1: REFout = {{16{ReadDataM[15]}}, ReadDataM[15:0]};
	endcase
	#2;

	checkOutput();
	#1;
    end

    //LHU
    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b100101;
	addr[1] = {$random} & 1'b1;
	ReadDataM = {$random} & 32'hFFFFFFFF;
	#2;

	case(addr[1])
		1'b0: REFout = {16'b0, ReadDataM[31:16]};
		1'b1: REFout = {16'b0, ReadDataM[15:0]};
	endcase
	#2;

	checkOutput();
	#1;
    end
    
    // Verifying that load words function properly
    $display("\nVerifying that load words behave properly...");

    //LW
    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b100011;
	ReadDataM = {$random} & 32'hFFFFFFFF;
	#2;

	REFout = ReadDataM;

	#2;

	checkOutput();
	#1;
    end

    // Verifying that non-load opcodes function properly
    $display("\nVerifying that non-store opcodes behave properly...");

    
    for(i = 0; i < loops; i = i + 1)
    begin
        
        while(opcode === 6'b100000 | opcode === 6'b100001 | opcode === 6'b100011 | opcode === 6'b100100 | opcode === 6'b100101)
		opcode = {$random} & 6'b111111;

	#2;
	
	REFout = ReadDataM;
	
	#2;

	checkOutput();
        #1;
    end
   
    $display("All tests passed!");
    $finish();
  end
endmodule
