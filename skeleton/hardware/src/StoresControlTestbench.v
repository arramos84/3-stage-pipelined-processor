// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps

module StoresControlTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Inputs and outputs for StoreControl
  reg [5:0] opcode;
  reg [1:0] addr;
  wire  [3:0] we;
  reg  [31:0] REFout;

   // Task for checking output
   task checkOutput;
        if ( REFout !== we ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\twe: 0x%h, REFout: 0x%h", we, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\twe: 0x%h, REFout: 0x%h", we, REFout);
        end
   endtask

  StoresControl DUT(.opcodeE(opcode),
              		   .ALUoutE(addr),
              		   .we(we));
           
  //declare looping variables
  integer i;
  localparam loops = 100;

  // Testing logic:

  initial begin
     #1;
    // Verifying that store bytes function properly
    $display("\nVerifying that store bytes behave properly...");

    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b101000;
	addr = {$random} & 2'b11;
	#2;

	case(addr)
		2'b00: REFout = 4'b1000;
		2'b01: REFout = 4'b0100;
		2'b10: REFout = 4'b0010;
		2'b11: REFout = 4'b0001;
	endcase
	#2;

	checkOutput();
	#1;
    end

     #1;
    // Verifying that store halves function properly
    $display("\nVerifying that store halves behave properly...");

    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b101001;
	addr[1] = {$random} & 1'b1;
	#2;

	case(addr[1])
		1'b0: REFout = 4'b1100;
		1'b1: REFout = 4'b0011;
	endcase
	#2;

	checkOutput();
	#1;
    end
    
    // Verifying that store words function properly
    $display("\nVerifying that store words behave properly...");

    for(i = 0; i < loops; i = i + 1)
    begin
        
        opcode = 6'b101011;
	#2;
	
	REFout = 4'b1111;
	
	#2;

	checkOutput();
	#1;
    end

    // Verifying that non-store opcodes function properly
    $display("\nVerifying that non-store opcodes behave properly...");

    
    for(i = 0; i < loops; i = i + 1)
    begin
        
        while(opcode === 6'b101011 | opcode === 6'b101001 | opcode === 6'b101000)
		opcode = {$random} & 6'b111111;

	#2;
	
	REFout = 4'b0000;
	
	#2;

	checkOutput();
        #1;
    end
   
    $display("All tests passed!");
    $finish();
  end
endmodule
