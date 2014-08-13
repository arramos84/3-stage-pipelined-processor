`include "Opcode.vh"
module MWB_STAGE( input		     Clk,
		  input		     Stall,
		  input		     Reset,
		  input		     pc_Plus8_E,
		  input		     RegWrite_E,
		  input		     MemToReg_E,
		  input       [5:0]  Opcde_E,
    input      [31:0]  DataMemOut,
    input      [31:0]  BiosDataOut,
		  input      [31:0]  ALUout_E,
    output reg [31:0]  ALUout_M,
		  input      [31:0]  PCplus8_E,
		  input      [4:0]   RegDstForWB_E,
		  input  	     DataInVaild_forTx,
		  input      [7:0]   Din_forTx,
		  input 	     SIn_UART,
		  output 	     SOut_UART,
		  output 	     RegWrite_M,
		  output reg [31:0]  WriteData_M,
		  output reg [4:0]   RegDstForWB_M,
    output             UART0request,
    output             UART1request,
    input [31:0] PF_curFrame,
    output reg [31:0] PF_nextFrame,
    input [31:0] Din_forMem,
    output reg [31:0] gpFrame,
    output reg [31:0] gpCode,
    output reg gpValid,
    input  gpDone
		  );
		 
// Register Declarations		 		    

 reg        DataOutReady_toUART;
 reg        RegWrite;
 reg        MemToReg_M;
 reg        pc_Plus8_M;
 reg [5:0]  Opcde_M;
 reg [31:0] PCplus8_M;
 reg [31:0] CycleCounter;
 reg [31:0] InstCounter;

// Wire Declarations
	
 wire        DataOutReady;
 wire        DataInReady;
 wire        DataInValid;
 wire        DataOutValid;
 wire [7:0]  DinTX;
 wire [7:0]  DataOut;
 wire [31:0] LoadMaskInput;
 wire [31:0] ALUout_orPCplus8;
 wire [31:0] LoadMaskerOut;
 wire [31:0] pipelineWBdata;
 wire        resetCounters;

// Mem Mapped GP reg declarations
 
 wire setGPframe, setGPcode, setPFnextFrame, flipFrams;

// Pipeline Register for Mem Access/Write Back Stage	

 assign RegWrite_M = RegWrite;

 always @(posedge Clk) begin
  if (Reset) begin 
   RegWrite <= 1'd0; MemToReg_M<= 1'd0; pc_Plus8_M <=1'd0; Opcde_M <=6'd0;
   ALUout_M <= 32'd0; PCplus8_M <= 32'd0; RegDstForWB_M <= 5'd0;
  end else if (Stall) begin
   RegWrite <= RegWrite; MemToReg_M<= MemToReg_M; 
   pc_Plus8_M <= pc_Plus8_M; Opcde_M <=Opcde_M; ALUout_M <= ALUout_M; 
   PCplus8_M <= PCplus8_M; RegDstForWB_M <= RegDstForWB_M;DataOutReady_toUART <= DataOutReady;
  end else begin
   RegWrite <= RegWrite_E; MemToReg_M<= MemToReg_E; 
   pc_Plus8_M <= pc_Plus8_E; Opcde_M <=Opcde_E; ALUout_M <= ALUout_E; 
   PCplus8_M <= PCplus8_E; RegDstForWB_M <= RegDstForWB_E; DataOutReady_toUART <= DataOutReady;
  end
 end
	
// Counters and signals

 assign resetCounters = ((ALUout_E == 32'h80000018) & (Opcde_E == `SB | Opcde_E == `SH | Opcde_E == `SW) & ~Stall);
	
 always @(posedge Clk)begin
  if (Reset || resetCounters) begin
   CycleCounter <= 32'd0; InstCounter <= 32'd0;
  end else if (Stall) begin
   CycleCounter <= CycleCounter + 32'd1; InstCounter <= InstCounter;
  end else begin
   CycleCounter <= CycleCounter + 32'd1; InstCounter <= InstCounter + 32'd1;
  end
 end
         
//////////////////////////////  Mem Mapped Pixel Feedeer Frames /////////////

 assign flipFrams = ((ALUout_E == 32'h8000001c) & (Opcde_E == `SW) & ~Stall);      
 assign setPFnextFrame = ((ALUout_E == 32'h80000020) & (Opcde_E == `SW) & ~Stall);

 always@(posedge Clk)begin
   if (Reset) PF_nextFrame <= 32'h10400000;
   else if(gpDone | flipFrams) PF_nextFrame <= (PF_nextFrame==32'h10800000) ? 32'h10400000 : 32'h10800000;
   else if(setPFnextFrame) PF_nextFrame <= Din_forMem;
   else PF_nextFrame <= PF_nextFrame;
 end 
 
/////////////////////////////////  GP Registers   ////////////////////////////
 
 assign setGPframe = ((ALUout_E == 32'h80000024) & (Opcde_E == `SW) & ~Stall);
 assign setGPcode = ((ALUout_E == 32'h80000028) & (Opcde_E == `SW) & ~Stall);
 
 always@(posedge Clk)begin
  if (Reset) begin gpFrame <= 32'd0; gpCode <= 32'd0; gpValid <= 1'd0; end
  else if(setGPframe)begin gpFrame <= Din_forMem; gpCode <= gpCode; gpValid <= 1'd0; end
  else if(setGPcode)begin gpFrame <= gpFrame; gpCode <= Din_forMem; gpValid <= 1'd1; end
  else begin gpFrame <= gpFrame; gpCode <= gpCode; gpValid <= 1'd0; end  
 end

//////////////////////////////////////////////////////////////////////////////         
         
// Load Masker and signals

 assign LoadMaskInput = (ALUout_M[31:28] == 4'b0100) ? BiosDataOut : DataMemOut;

 LoadMasker loadMasker(.ReadDataM(LoadMaskInput),
                       .opcodeM(Opcde_M),
                       .ALUoutM(ALUout_M[1:0]),
                       .LoadMaskOut(LoadMaskerOut)
                       );
      
// UART and respective signals

 assign DinTX = Din_forTx;
 assign DataInValid = Reset ? 1'd0 : DataInVaild_forTx  && DataInReady;
 assign DataOutReady = ((Opcde_M == `LB || Opcde_M == `LH || Opcde_M == `LW || 
                         Opcde_M == `LBU || Opcde_M == `LHU) && (ALUout_M == 32'h8000000c) );  

 UART uart(.Clock(Clk),
           .Reset(Reset),
           .DataIn(DinTX),
           .DataInValid(DataInValid),
           .DataInReady(DataInReady),
           .DataOut(DataOut),
           .DataOutValid(DataOutValid),
           .DataOutReady(DataOutReady_toUART & ~Stall),
           .SIn(SIn_UART),
           .SOut(SOut_UART)
           );

UARTfsm TXfsm( .clk(Clk),
               .reset(Reset),
               .in(DataInReady),
               .out(UART1request)
              );

UARTfsm RXfsm( .clk(Clk),
               .reset(Reset),
               .in(DataOutValid),
               .out(UART0request)
              );

// Multiplexers for Write Back Data into RegFile

 assign ALUout_orPCplus8 = pc_Plus8_M ? PCplus8_M : ALUout_M;
 assign pipelineWBdata = MemToReg_M ? LoadMaskerOut : ALUout_orPCplus8;

 always @ ( * ) begin
  if (Opcde_M == `LB || Opcde_M == `LH || Opcde_M == `LW ||
      Opcde_M == `LBU || Opcde_M == `LHU) begin
   case(ALUout_M)
    32'h80000000: WriteData_M = {31'd0, DataInReady};
    32'h80000004: WriteData_M = {31'd0, DataOutValid};
    32'h8000000c: WriteData_M = {24'd0, DataOut}; 
    32'h80000010: WriteData_M = CycleCounter;
    32'h80000014: WriteData_M = InstCounter;
    32'h8000001c: WriteData_M = PF_curFrame;
    32'h80000020: WriteData_M = PF_nextFrame;
    32'h80000024: WriteData_M = gpFrame;
    32'h80000028: WriteData_M = gpCode;
    default: WriteData_M = pipelineWBdata;
   endcase        
  end else WriteData_M = pipelineWBdata;
 end
               	 		    
endmodule
