// Use this as the top-level module for your CPU. You
// will likely want to break control and datapath out
// into separate modules that you instantiate here.


module MIPS150( input clk,
                input rst,
                input stall,

                // Serial
                input FPGA_SERIAL_RX,
                output FPGA_SERIAL_TX,

                // Memory system connections
                output [31:0] dcache_addr,
                output [31:0] icache_addr,
                output [3:0] dcache_we,
                output [3:0] icache_we,
                output dcache_re,
                output icache_re,
                output [31:0] dcache_din,
                output [31:0] icache_din,
                input [31:0] dcache_dout,
                input [31:0] instruction,
                output [31:0]    gp_code,
                output [31:0]   gp_frame,
                output          gp_valid,
                input           gp_Done,
                input   [31:0]  PFcurFrame,
                output [31:0]  PFnextFrame
                );

// Wire Declarations

 wire [31:0] nextPC;
 wire [31:0] PC;
 wire [31:0] PCplus4_I;
 wire        pc_Plus8_E;
 wire [31:0] PCplus8_E;

 wire [31:0] biosFetchOut;
 wire [31:0] biosReadOut;

 wire [31:0] Inst_I;
 wire [5:0]  Opcde_E;
 wire [4:0]  Rs_E;
 wire [4:0]  Rt_E; 
 	
 wire        Jump_E;
 wire [31:0] Jaddr;
 wire        JReg;
 wire [31:0] JRegAddr;
 wire        Branch_E;
 wire [31:0] BranchAddr;  

 wire        FwdA;
 wire        FwdB;	

 wire [31:0] ALUout_E;
 wire [31:0] ALUout_M;
 wire [31:0] AluOutE_or_M;
 
 wire        EN_forDataMem;
 wire [3:0]  WE_IMEM;	
 wire [3:0]  WE_DMEM;
 wire [31:0] Din_forMem;

 wire	     DataInVaild_forTx;
 wire [7:0]  Din_forTx;
 wire UART0request;
 wire UART1request;

 wire        MemToReg_E;	
 wire        RegWrite_E; 
 wire        RegWrite_M;
 wire [31:0] WriteData_M;
 wire [4:0]  RegDstForWB_E;
 wire [4:0]  RegDstForWB_M;

 wire InterruptHandled;
 wire [31:0] isrFetchOut;
 wire [3:0] WE_ISR;
 wire [3:0] isr_we;
 wire [31:0] isrAddr;

 wire [31:0] PCorPCreg;
 reg         DcacheENreg;

 
 

/*
//////////////////////////////  Mem Mapped Pixel Feedeer Frames /////////////
      
 always@(posedge clk)begin
   if (rst) PFnextFrame <= 32'h10400000;
   else if(gp_Done) PFnextFrame <= (PFcurFrame==32'h10800000) ? 32'h10400000 : 32'h10800000;
   else PFnextFrame <= PFnextFrame;
 end 
 
///////////////////////////////////////////////////////////////////////////
*/

 always @(posedge clk) begin
  if(rst) DcacheENreg <= 1'd0;
  else if(stall) DcacheENreg <= DcacheENreg;
  else DcacheENreg <= EN_forDataMem;
 end

// Data Cache signals
 assign dcache_re   = ~stall ? EN_forDataMem : DcacheENreg;
 assign dcache_addr = AluOutE_or_M;
 assign dcache_we   = ~stall ? WE_DMEM : 4'b0;
 assign dcache_din  = Din_forMem;


// Inst Cache signals
 assign icache_re   = ~stall ? nextPC[31:28] == 4'b0001 : PC[31:28] == 4'b0001;
 assign icache_addr = PCorPCreg[31:28] == 4'b0001 ?  PCorPCreg : AluOutE_or_M;
 assign icache_we   = ~stall & nextPC[30] ? WE_IMEM : 4'd0;
 assign icache_din  = Din_forMem;

//stalls stuff
 assign AluOutE_or_M = ~stall ?  ALUout_E : ALUout_M;
 assign PCorPCreg = ~stall ? nextPC : PC;

// Foward signals
 assign FwdA = ((Rs_E != 5'd0) && RegWrite_M)? (RegDstForWB_M == Rs_E) : 1'd0;
 assign FwdB = ((Rt_E != 5'd0) && RegWrite_M)? (RegDstForWB_M == Rt_E) : 1'd0;

 //Instruction 
 assign Inst_I = (PC[31:28] == 4'b0001) ? instruction : (PC[31:28] == 4'b1100) ? isrFetchOut : biosFetchOut;

 //ISR signals 
 assign isrAddr = InterruptHandled ? 32'd0 : PCorPCreg;
 assign isr_we = ~stall ? WE_ISR : 4'd0;

 // Bios
	bios_mem Bmem(  .clka(clk),
                 .ena(1'b1),
                 .addra(PCorPCreg[13:2]),
                 .douta(biosFetchOut),
                 .clkb(clk),
                 .enb(1'b1),
                 .addrb(AluOutE_or_M[13:2]), 
                 .doutb(biosReadOut)
               );

 // ISR
 isr_mem ISRmem( .clka(clk),
	                .ena(~stall),
	                .wea(isr_we), /////////////////
	                .addra(AluOutE_or_M[13:2]),
	                .dina(Din_forMem),
	                .clkb(clk),
	                .addrb(isrAddr[13:2]),
	                .doutb(isrFetchOut)
                );
	
 // Instruction Fetch Stage
	IF_STAGE InstFetch_Stage(
                 .Clk(clk),
                 .Stall(stall),
                 .Reset(rst),
                 .Branch_E(Branch_E),
                 .JReg(JReg),
                 .Jump_E(Jump_E),
                 .Jaddr(Jaddr),
                 .JRegAddr(JRegAddr),
                 .BranchAddr(BranchAddr),
                 .nextPC(nextPC),
                 .PC(PC),
                 .PCplus4_I(PCplus4_I),
                 .InterruptHandled(InterruptHandled)
               );

 // RegFile/Execute Stage
	RE_STAGE RegEx_Stage(
                 .Clk(clk),
                 .Stall(stall),
                 .Reset(rst),
                 .FwdA(FwdA),
                 .FwdB(FwdB),
                 .RegWrite_M(RegWrite_M),
                 .RegDstForWB_M(RegDstForWB_M),
                 .WriteData_M(WriteData_M),
                 .Inst_I(Inst_I),
                 .nextPC(nextPC),
                 .PCplus4_I(PCplus4_I),
                 .Jump_E(Jump_E),
                 .Jaddr(Jaddr),
                 .Branch(Branch_E),
                 .BranchAddr(BranchAddr),
                 .JReg(JReg),
                 .JRegAddr(JRegAddr),
                 .RegWrite_E(RegWrite_E),
                 .MemToReg_E(MemToReg_E),
                 .Opcde_E(Opcde_E),
                 .EN_forDataMem(EN_forDataMem),
                 .WE_IMEM(WE_IMEM),
                 .WE_DMEM(WE_DMEM),
                 .WE_ISR(WE_ISR),
                 .Din_forMem(Din_forMem),
                 .ALUout_E(ALUout_E),
                 .PCplus8_E(PCplus8_E),
                 .pc_Plus8_E(pc_Plus8_E),
                 .RegDstForWB_E(RegDstForWB_E),
                 .DataInVaild_forTx(DataInVaild_forTx),
                 .Din_forTx(Din_forTx),
                 .Rs_E(Rs_E),
                 .Rt_E(Rt_E),
                 .UART0request(UART0request),
                 .UART1request(UART1request),
                 .InterruptHandled(InterruptHandled)
               );
            
 // Data Mem acces/Write Back stage
	MWB_STAGE MemWriteBack_Stage(
                 .Clk(clk),
                 .Stall(stall),
                 .Reset(rst),
                 .pc_Plus8_E(pc_Plus8_E),
                 .RegWrite_E(RegWrite_E),
                 .MemToReg_E(MemToReg_E),
                 .Opcde_E(Opcde_E),
                 .DataMemOut(dcache_dout), 
                 .BiosDataOut(biosReadOut), 
                 .ALUout_E(ALUout_E),
                 .ALUout_M(ALUout_M),
                 .PCplus8_E(PCplus8_E),
                 .RegDstForWB_E(RegDstForWB_E),
                 .DataInVaild_forTx(DataInVaild_forTx),
                 .Din_forTx(Din_forTx),
                 .SIn_UART(FPGA_SERIAL_RX),
                 .SOut_UART(FPGA_SERIAL_TX),
                 .RegWrite_M(RegWrite_M),
                 .WriteData_M(WriteData_M),
                 .RegDstForWB_M(RegDstForWB_M),
                 .UART0request(UART0request),
                 .UART1request(UART1request),
                 .PF_curFrame(PFcurFrame),
                 .PF_nextFrame(PFnextFrame),
                 .Din_forMem(Din_forMem),
                 .gpFrame(gp_frame),
                 .gpCode(gp_code),
                 .gpValid(gp_valid),
                 .gpDone(gp_Done)
               );

endmodule
    

