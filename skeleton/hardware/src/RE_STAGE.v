
module RE_STAGE ( input		 Clk,
		 		input		 Stall,
		 		input		 Reset,
		 		input		 FwdA,
		 		input		 FwdB,
		 		input		 RegWrite_M,
		 		input   [4:0]	 RegDstForWB_M,
		 		input   [31:0] 	 WriteData_M,
		 		input   [31:0] 	 Inst_I,
     input   [31:0] nextPC,
		 		input   [31:0]   PCplus4_I,		 		
		 		output		 Jump_E,
		 		output [31:0]   Jaddr,
		 		output		 Branch,
		 		output [31:0]   BranchAddr,
		 		output		 JReg,		
		 		output [31:0]   JRegAddr,
		 		output		 RegWrite_E,
		 		output		 MemToReg_E,
		 		output [5:0]	 Opcde_E,
		 		output		 EN_forDataMem,
		 		output [3:0]	 WE_IMEM,
		 		output [3:0]	 WE_DMEM,
     output [3:0]  WE_ISR,
		 		output [31:0]   Din_forMem,	
		 		output [31:0]   ALUout_E,
		 		output [31:0]   PCplus8_E,
     output  pc_Plus8_E,
		 		output [4:0]	 RegDstForWB_E,
		 		output		 DataInVaild_forTx,
		 		output [7:0]     Din_forTx,
		 		output [4:0]     Rs_E,
		 		output [4:0]     Rt_E,  
     input             UART0request,
     input             UART1request,
     output             InterruptHandled
		 		);
		 		

	//pipeline registers
	reg  [31:0]  Inst_E;
	reg  [31:0]  PCplus4_E;
	
	//connecting wires
	wire SignExtend;
	wire RegDst;
	wire ALUsrc;
	wire Shift;
 wire Jal;
	wire [3:0]  ALUop;
	wire [4:0]  Rt_or_Rd;
	wire [31:0]  RegData1_PreFwdMux;
	wire [31:0]  RegData1_PostFwdMux;
	wire [31:0]  RegData2_PreFwdMux;
	wire [31:0]  RegData2_PostFwdMux;
	wire [31:0]  ExtendedImm;
	wire [31:0]  AdderInputB;
	wire [31:0]  AdderOut;
	wire [31:0]  ALUinputA;
	wire [31:0]  ALUinputB;
	wire [31:0]  ALUout;
 wire InterruptRequest;
 wire [31:0] cpoDataOut;
 wire copOut;
 wire copWE;
                 
	always @(posedge Clk) begin
		if (Reset) begin Inst_E <= 32'd0; PCplus4_E <= 32'd0; 
  end else	if (Stall) begin Inst_E <= Inst_E; PCplus4_E <= PCplus4_E; end
		else begin Inst_E <= Inst_I ; PCplus4_E <= PCplus4_I; end
	end
	
	assign Opcde_E = Inst_E[31:26];
	assign Rs_E = Inst_E[25:21];
	assign Rt_E = Inst_E[20:16];
	assign Jaddr = {PCplus4_E[31:28], Inst_E[25:0], 2'd0};
	assign JRegAddr = ALUinputA;
	assign BranchAddr = AdderOut;               
	assign PCplus8_E = AdderOut;
	
	Decoder decoder(.Stall(Stall),
                 .Inst_I(Inst_I),
                 .OpcodeE(Opcde_E),
                 .Funct(Inst_E[5:0]),
                 .RsE(Rs_E),
                 .RtE(Rt_E),
                 .RegRsE(RegData1_PostFwdMux),
                 .RegRtE(RegData2_PostFwdMux),
                 .SignExtend(SignExtend),
                 .RegDst(RegDst),
                 .PCplus8(pc_Plus8_E),
                 .ALUsrc(ALUsrc),
                 .Shift(Shift),
                 .MemToRegE(MemToReg_E),
                 .RegWriteE(RegWrite_E),
                 .JumpE(Jump_E),
                 .JalE(Jal),
                 .JReg(JReg),
                 .Branch(Branch), 
                 .InterruptRequest(InterruptRequest),
                 .InterruptHandled(InterruptHandled),
                 .copOut(copOut),
                 .copWE(copWE)
               );
          
 assign Rt_or_Rd = RegDst ? Inst_E[15:11] : Inst_E[20:16];
 assign RegDstForWB_E = Jal ? 5'd31 : Rt_or_Rd;       
 assign ExtendedImm = SignExtend ? {{16{Inst_E[15]}}, Inst_E[15:0]} : {16'd0, Inst_E[15:0]};        
 assign AdderInputB = pc_Plus8_E ? 32'd4 : {ExtendedImm[29:0], 2'd0};       
 assign AdderOut = PCplus4_E + AdderInputB;
               
	RegFile regFile(
                 .clk(Clk),
                 .WE3(RegWrite_M),
                 .A1(Inst_E[25:21]),
                 .A2(Inst_E[20:16]),
                 .A3(RegDstForWB_M),
                 .WD3(WriteData_M),
                 .RD1(RegData1_PreFwdMux),
                 .RD2(RegData2_PreFwdMux)
               );
               
 COP0150 cpo(
   			  .Clock(Clk),
  			   .Enable(1'b1), // must be high to change anything in CPO
    			 .Reset(Reset),
    			 .DataAddress(Inst_E[15:11]), // always rd
    			 .DataOut(cpoDataOut),   // read data out
    			 .DataInEnable(copWE & ~Stall),  //write enable for CPO
    			 .DataIn(RegData2_PostFwdMux), 
    			 .InterruptedPC(nextPC), 
    			 .InterruptHandled(InterruptHandled),  // in // high when ISR is about to be fetched.
    			 				                  // lets CPO know interupt is being handled
    			 .InterruptRequest(InterruptRequest), // out // high when an iterupt is requested 
    			 .UART0Request(UART0request), // in // RX
    			 .UART1Request(UART1request) // in //TX
			);
               
 assign RegData1_PostFwdMux = FwdA ? WriteData_M : RegData1_PreFwdMux;
 assign RegData2_PostFwdMux = FwdB ? WriteData_M : RegData2_PreFwdMux;
           
	ALUdec aluDecoder(
                 .funct(Inst_E[5:0]),
                 .opcode(Inst_E[31:26]),
                 .ALUop(ALUop)
               );
               
 assign ALUinputA = Shift ? {27'd0, Inst_E[10:6]} : RegData1_PostFwdMux;
 assign ALUinputB = ALUsrc ? ExtendedImm : RegData2_PostFwdMux;
               
	ALU alu(
                 .A(ALUinputA),
                 .B(ALUinputB),
                 .ALUop(ALUop),
                 .Out(ALUout)
               );
               
	MemoryMapper memMapper(
                 .ALUoutE(ALUout_E),
                 .WriteDataE(RegData2_PostFwdMux),
                 .opcodeE(Inst_E[31:26]),
                 .stall(Stall),
                 .we_IMEM(WE_IMEM),
                 .we_DMEM(WE_DMEM),
                 .we_ISR(WE_ISR),
                 .UARTData(Din_forTx),
                 .enable(EN_forDataMem),
                 .DataInValid(DataInVaild_forTx),
                 .WriteDataOut_E(Din_forMem)
                 );
          
	assign ALUout_E = copOut ? cpoDataOut : ALUout;
endmodule
