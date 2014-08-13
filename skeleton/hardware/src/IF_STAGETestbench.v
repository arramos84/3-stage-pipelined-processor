`timescale 1ns/1ps

module IF_STAGETestbench();

     reg		 Clock;
     reg		 Stall;
     reg		 Reset;
     reg		 Branch_E;
     reg		 JReg;
     reg		 Jump_E;
     reg   [3:0] 	 WE;
     reg   [11:0] 	 AddrToMem;
     reg   [31:0]      WriteData_E;
     reg   [31:0]            Jaddr;
     reg   [31:0]         JRegAddr;
     reg   [31:0]       BranchAddr;
     wire  [31:0]           Inst_I;
     wire  [31:0]         PCplus4_I; 
		 		

    parameter HalfCycle = 5;
    parameter Cycle = 2*HalfCycle;

    initial Clock = 0;
    always #(HalfCycle) Clock <= ~Clock;
    
    IF_STAGE IF(
                  .Clk(Clock),
                  .Stall(Stall),
                  .Reset(Reset),
                  .Branch_E(Branch_E),
                  .JReg(JReg),
                  .Jump_E(Jump_E),
                  .WE(WE),
                  .AddrToMem(AddrToMem),
                  .WriteData_E(WriteData_E),
                  .Jaddr(Jaddr),
                  .JRegAddr(JRegAddr),
                  .BranchAddr(BranchAddr),
                  .Inst_I(Inst_I),
                  .PCplus4_I(PCplus4_I)
                );
   
    integer i;
    localparam loops = 30;
      
    initial begin
      // Reset. Has to be long enough to not be eaten by the debouncer.
      Reset = 1;
      Stall = 0;
      Jump_E = 0;
      Branch_E = 0;
      #(Cycle);
      Reset = 0;
     
      
      for(i = 0; i < loops; i = i + 1) begin
      	
	
      	$display("Instruction: %b" , Inst_I);
      	$display("PCplus4:     %d" , PCplus4_I);
      #(Cycle);
      end
     

      $finish();
  end

endmodule
