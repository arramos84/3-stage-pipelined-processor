`include "Opcode.vh"

module StoresControl (input [5:0] opcodeE,
               	      input [1:0] ALUoutE,
                      output reg [3:0] we);

	always @ (*) begin
		case(opcodeE)
			`SB: case(ALUoutE)
				2'b00: we = 4'b1000;
				2'b01: we = 4'b0100;
				2'b10: we = 4'b0010;
				2'b11: we = 4'b0001;
			     endcase
			`SH: case(ALUoutE[1])
				1'b0:  we = 4'b1100;
				1'b1:  we = 4'b0011;
				endcase
			`SW: we = 4'b1111;
			default: we = 4'b0000;
		endcase
	end
endmodule
