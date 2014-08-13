
module IF_STAGE ( input		   Clk,
		  input		   Stall,
		  input		   Reset,
		  input		   Branch_E,
		  input		   JReg,
		  input		   Jump_E,
		  input   [31:0]   Jaddr,
		  input   [31:0]   JRegAddr,
		  input   [31:0]   BranchAddr,
    output  [31:0]   nextPC,
    output reg [31:0]   PC,
		  output  [31:0]   PCplus4_I,
    input      InterruptHandled
		  );
		 		
	//local variables
 wire [31:0]  BranchWire;
 wire [31:0]  JumpWire;
 wire [31:0]  PCpreResetMux;

 //PC Register
 always @(posedge Clk) begin
  if(Reset) PC <= 32'h40000000;
  else if(Stall) PC <= PC;
  else if (InterruptHandled) PC <= 32'hc0000000;
  else PC <= nextPC;
 end


 assign nextPC = Reset ? PC : PCpreResetMux;

 assign PCpreResetMux = Jump_E ? JumpWire : BranchWire;	
 assign BranchWire = Branch_E ? BranchAddr : PCplus4_I;	
 assign JumpWire = JReg ? JRegAddr : Jaddr;	
 
 assign PCplus4_I = PC + 4;	 
	
endmodule
				


















