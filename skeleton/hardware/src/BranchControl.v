`include "Opcode.vh"

module BranchControl(input [5:0]  opcodeE,
		     input [4:0]      rsE,
		     input [4:0]      rtE,
		     output reg      branch);

	always @ (*) begin
		case(opcodeE)
			`BEQ:  branch = (rsE == rtE);
			`BNE:  branch = (rsE != rtE);
			`BLEZ: branch = (rsE <= 5'b0);
			`BGTZ: branch = (rsE >  5'b0);
			`BLTZBGEZ: case(rtE)
					5'b00000: branch = (rsE < 5'b0);
					5'b00001: branch = (rsE >= 5'b0);
				    endcase
			default: branch = 1'b0;
		endcase
	end
endmodule
