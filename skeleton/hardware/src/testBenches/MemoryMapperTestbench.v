// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps
`include "Opcode.vh"

module MemoryMapperTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Inputs and outputs for MemoryMapper
  reg   [31:0]               ALUoutE;
  reg   [31:0]            WriteDataE;
  reg   [5:0]                opcodeE;
  wire  [3:0]                we_IMEM;
  wire  [3:0]                we_DMEM;	
  wire  [7:0]               UARTData;
  wire  [11:0]           addr_to_MEM;
  wire                   DataInValid;  
  reg   [3:0]         REFout_we_IMEM;
  reg   [3:0]         REFout_we_DMEM;
  reg   [7:0]        REFout_UARTData;
  reg             REFout_DataInValid;
  reg   [11:0]    REFout_addr_to_MEM;
  reg   [23:0]               rand_24;

   // Tasks for checking outputs
   task checkOutput_we;
   	if ( REFout_we_DMEM !== we_DMEM ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\twe_DMEM: 0x%h, REFout_we_DMEM: 0x%h", we_DMEM, REFout_we_DMEM) ;
            $finish();
        end
	else if( REFout_we_IMEM !== we_IMEM ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\twe_IMEM: 0x%h, REFout_we_IMEM: 0x%h", we_IMEM, REFout_we_IMEM);
            $finish();
        end	
        else begin
            $display("PASS: Got correct results!!!!");
            $display("\twe_DMEM: 0x%h, REFout_we_DMEM: 0x%h", we_DMEM, REFout_we_DMEM);
	    $display("\twe_IMEM: 0x%h, REFout_we_IMEM: 0x%h", we_IMEM, REFout_we_IMEM);
        end
   endtask
   
   task checkData;
   	if ( REFout_DataInValid !== DataInValid | REFout_UARTData !== UARTData | REFout_addr_to_MEM !== addr_to_MEM ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\tDataInValid: 0x%h, REFout_DataInValid: 0x%h", DataInValid, REFout_DataInValid) ;
            $display("\tUARTData: 0x%h, REFout_UARTData: 0x%h", UARTData, REFout_UARTData) ;
            $display("\taddr_to_MEM: 0x%h, REFout_addr_to_MEM: 0x%h", addr_to_MEM, REFout_addr_to_MEM) ;
            $finish();
        end
        else begin
            $display("PASS: Got correct results!!!!");
            $display("\taddr_to_MEM: 0x%h, REFout_DataInValid: 0x%h", addr_to_MEM, REFout_DataInValid);
            $display("\tUARTData: 0x%h, REFout_UARTData: 0x%h", UARTData, REFout_UARTData) ;
            $display("\taddr_to_MEM: 0x%h, REFout_addr_to_MEM: 0x%h", addr_to_MEM, REFout_addr_to_MEM) ;
        end
   endtask

  MemoryMapper DUT(
                 .ALUoutE(ALUoutE),
                 .WriteDataE(WriteDataE),
                 .opcodeE(opcodeE),
                 .we_IMEM(we_IMEM),
                 .we_DMEM(we_DMEM),
                 .UARTData(UARTData),
                 .addr_to_MEM(addr_to_MEM),
                 .DataInValid(DataInValid));

           
  //declare looping variables
  integer i;
  localparam loops = 10;

  // Testing logic:

  initial begin
     #1;
    
    //Check write enable signals for IMEM and DMEM
    $display("\nVerifying Write Enable signals for IMEM and DMEM are both active...");
    
    //Set address so that DMEM and IMEM can be written to , DMEM also read from.
    
    for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
        #1;
    	ALUoutE = {4'b0111,rand_24, 4'b0000};
    	opcodeE = `SW;
	#1;
	REFout_we_DMEM = 4'b1111;
	REFout_we_IMEM = 4'b1111;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0111, rand_24 , 4'b0000};
    	opcodeE = `SH;
	#1;
	REFout_we_DMEM = 4'b1100;
	REFout_we_IMEM = 4'b1100;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0111, rand_24 , 4'b0010};
    	opcodeE = `SH;
	#1;
	REFout_we_DMEM = 4'b0011;
	REFout_we_IMEM = 4'b0011;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0111, rand_24 , 4'b0000};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b1000;
	REFout_we_IMEM = 4'b1000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0111, rand_24, 4'b0001};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0100;
	REFout_we_IMEM = 4'b0100;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0111, rand_24 , 4'b0010};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0010;
	REFout_we_IMEM = 4'b0010;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0111, rand_24 , 4'b0011};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0001;
	REFout_we_IMEM = 4'b0001;
	#1;
	checkOutput_we();
	#1;
     end
     
     //Set address so that DMEM can only be written or read to.
     $display("\nVerifying Write Enable signals for only DMEM are active...");
     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
        #1;
    	ALUoutE = {4'b0101,rand_24, 4'b0000};
    	opcodeE = `SW;
	#1;
	REFout_we_DMEM = 4'b1111;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0101, rand_24 , 4'b0000};
    	opcodeE = `SH;
	#1;
	REFout_we_DMEM = 4'b1100;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0101, rand_24 , 4'b0010};
    	opcodeE = `SH;
	#1;
	REFout_we_DMEM = 4'b0011;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0101, rand_24 , 4'b0000};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b1000;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0101, rand_24, 4'b0001};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0100;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0101, rand_24 , 4'b0010};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0010;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0101, rand_24 , 4'b0011};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0001;
	REFout_we_IMEM = 4'b0000;
	#1;
	checkOutput_we();
	#1;
     end
 
     //Set address so that IMEM can only be written to.
     $display("\nVerifying Write Enable signals for only IMEM are active...");
    
     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
        #1;
    	ALUoutE = {4'b0110,rand_24, 4'b0000};
    	opcodeE = `SW;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b1111;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0110, rand_24 , 4'b0000};
    	opcodeE = `SH;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b1100;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0110, rand_24 , 4'b0010};
    	opcodeE = `SH;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0011;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0110, rand_24 , 4'b0000};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b1000;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
        rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0110, rand_24, 4'b0001};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0100;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0110, rand_24 , 4'b0010};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0010;
	#1;
	checkOutput_we();
	#1;
     end

     for(i = 0; i < loops; i = i + 1) begin
	rand_24 = {$random} & 24'hFFFFFF;
	#1;
    	ALUoutE = {4'b0110, rand_24 , 4'b0011};
    	opcodeE = `SB;
	#1;
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0001;
	#1;
	checkOutput_we();
	#1;
     end

     //Ensure that only I/O can be written/read to 
     $display("\nVerifying Write Enable signals for IMEM and DMEM are inactive due to I/O, DataValid is high, Data and Addre output are correct...");
    
     for(i = 0; i < loops; i = i + 1) begin
        #1;
    	ALUoutE = {4'b1000, 24'b0 , 4'b1000};
    	WriteDataE = {$random} & 32'hFFFFFFFF;
    	opcodeE = `SW;
	#1;
        $display("0x%h, 0x%h", WriteDataE, WriteDataE[7:0]);
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0000;
	REFout_DataInValid = 1'b1;
	REFout_UARTData = WriteDataE[7:0];
	REFout_addr_to_MEM = ALUoutE[13:2];
	#1;
	checkOutput_we();
	#1;
	checkData();
     end

     for(i = 0; i < loops; i = i + 1) begin
        #1;
    	ALUoutE = {4'b1000, 24'b0 , 4'b1000};
    	WriteDataE = {$random} & 32'hFFFFFFFF;
    	opcodeE = `SH;
	#1;
        $display("0x%h, 0x%h", WriteDataE, WriteDataE[7:0]);
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0000;
	REFout_DataInValid = 1'b1;
	REFout_UARTData = WriteDataE[7:0];
	REFout_addr_to_MEM = ALUoutE[13:2];
	#1;
	checkOutput_we();
	#1;
	checkData();
     end

     for(i = 0; i < loops; i = i + 1) begin
        #1;
    	ALUoutE = {4'b1000, 24'b0 , 4'b1000};
    	WriteDataE = {$random} & 32'hFFFFFFFF;
    	opcodeE = `SB;
	#1;
        $display("0x%h, 0x%h", WriteDataE, WriteDataE[7:0]);
	REFout_we_DMEM = 4'b0000;
	REFout_we_IMEM = 4'b0000;
	REFout_DataInValid = 1'b1;
	REFout_UARTData = WriteDataE[7:0];
	REFout_addr_to_MEM = ALUoutE[13:2];
	#1;
	checkOutput_we();
	#1;
	checkData();
     end

        $display("\n\nALL TESTS PASSED!");
        $finish();
    end

 endmodule

 
	
	






















