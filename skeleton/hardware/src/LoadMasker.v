`include "Opcode.vh"

module LoadMasker(input  [31:0] ReadDataM,
		  input  [5:0]  opcodeM,
                  input  [1:0]  ALUoutM,
                  output reg [31:0] LoadMaskOut);

	always @ (*) begin
		case(opcodeM)
			`LB: case(ALUoutM)
				2'b11: LoadMaskOut = {{24{ReadDataM[7]}}, ReadDataM[7:0]};
				2'b10: LoadMaskOut = {{24{ReadDataM[15]}}, ReadDataM[15:8]};
				2'b01: LoadMaskOut = {{24{ReadDataM[23]}}, ReadDataM[23:16]};
				2'b00: LoadMaskOut = {{24{ReadDataM[31]}} , ReadDataM[31:24]};
			endcase
			`LBU: case(ALUoutM)
				2'b11: LoadMaskOut = {24'b0, ReadDataM[7:0]};
				2'b10: LoadMaskOut = {24'b0, ReadDataM[15:8]};
				2'b01: LoadMaskOut = {24'b0, ReadDataM[23:16]};
				2'b00: LoadMaskOut = {24'b0, ReadDataM[31:24]};
			endcase
			`LH: case(ALUoutM[1])
				1'b1: LoadMaskOut = {{16{ReadDataM[15]}} , ReadDataM[15:0]};
				1'b0: LoadMaskOut = {{16{ReadDataM[31]}} , ReadDataM[31:16]};
			endcase
			`LHU: case(ALUoutM[1])
				1'b1: LoadMaskOut = {16'b0, ReadDataM[15:0]};
				1'b0: LoadMaskOut = {16'b0, ReadDataM[31:16]};
			endcase
			`LW: LoadMaskOut = ReadDataM;
			default: LoadMaskOut = ReadDataM;
		endcase
	end
endmodule

