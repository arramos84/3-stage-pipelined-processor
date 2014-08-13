`include "Opcode.vh"

module Decoder( input Stall,
         input   [31:0] 	 Inst_I,
         input  [5:0]       OpcodeE,
							  input  [5:0]     Funct,
         input  [4:0]       RsE,
							  input  [4:0]       RtE,
         input  [31:0]       RegRsE,
							  input  [31:0]       RegRtE,
							  output        SignExtend,
							  output          RegDst,
							  output          PCplus8,
							  output          ALUsrc,
							  output          Shift,
							  output          MemToRegE,
							  output          RegWriteE,
							  output          JumpE,
         output          JalE,
							  output          JReg,
							  output          Branch,
         input           InterruptRequest,
         output          InterruptHandled,
         output          copOut,
         output          copWE
         );

 reg [11:0] control;
 wire nextInstIsJumpOrBranch;
 wire [5:0] opcodeI;
 wire [5:0] functI;


 assign opcodeI = Inst_I[31:26];
 assign functI = Inst_I[5:0];
 assign nextInstIsJumpOrBranch = (opcodeI==`BEQ|opcodeI==`BNE|opcodeI==`BLEZ|opcodeI==`BGTZ|opcodeI==`BLTZBGEZ
                                    |functI==`JR|functI==`JALR|opcodeI==`J|opcodeI==`JAL);
 assign InterruptHandled = InterruptRequest & !(JumpE | Branch | Stall | nextInstIsJumpOrBranch);
 assign copWE = ((OpcodeE == `CPO) & (RsE == `MTC0));

 assign copOut = control[11];
 assign SignExtend = control[10];
 assign RegDst = control[9];
 assign PCplus8 = control[8];
 assign ALUsrc = control[7];
 assign Shift = control[6];
 assign MemToRegE = control[5];
 assign RegWriteE = control[4];
 assign JalE = control[3];
 assign JumpE = control[2];
 assign JReg = control[1];
 assign Branch = control[0];

	always @ ( * ) begin
		case(OpcodeE)
   //CoProcessor
   `CPO:
     case(RsE)
      `MFC0: control = 12'b100000010000;
      `MTC0: control = 12'b000000000000; 
     endcase

			//Loads/Stores
			`LB, `LH, `LW, `LBU, `LHU: 	control = 12'b010010110000;
			`SB, `SH, `SW: control = 12'b010010000000;

			//I-TYPE Instructions
			`ADDIU, `SLTI, `SLTIU: control = 12'b010010010000;
			`ANDI, `ORI, `XORI: control = 12'b000010010000;
			`LUI: control = 12'b000010010000;

			//R-TYPE Instructions
			`RTYPE:  
				case(Funct) 
					`SLL, `SRL, `SRA: control = 12'b001001010000;
					`SLLV, `SRLV, `SRAV, `ADDU, `SUBU, `AND, `OR, `XOR, 	`NOR, 	`SLT, 	`SLTU:	control = 12'b001000010000;

				   //Jump to Registers
					`JR: control = 12'b000000000110;
				 `JALR: control = 12'b001100010110;

				endcase	

	    //Jumps
		`J: control = 12'b000000000100;
		`JAL: control = 12'b000100011100;
  
		//Branches		
  `BEQ, `BNE, `BLEZ, `BGTZ, `BLTZBGEZ: begin
     case (OpcodeE)
		     `BEQ: control = {11'b01000100000, (RegRsE == RegRtE)};
		     `BNE: control = {11'b01000100000, (RegRsE != RegRtE)};
		     `BLEZ: control = {11'b01000100000,(RegRsE <= 5'd0)};
		     `BGTZ: control = {11'b01000100000, (RegRsE >  5'd0)};
		     `BLTZBGEZ: 
          case(RtE)
			         5'd0: control = {11'b01000100000, (RegRsE < 5'd0)};
			         5'd1: control = {11'b01000100000, (RegRsE >= 5'd0)};
				      endcase
     endcase
   end
   default:  control = 12'b000000000000;
		endcase
	end
endmodule	
