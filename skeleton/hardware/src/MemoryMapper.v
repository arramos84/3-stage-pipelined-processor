`include "Opcode.vh"

module MemoryMapper (input   [31:0]       ALUoutE,
		                   input   [31:0]    WriteDataE,
		                   input   [5:0]        opcodeE,
       		            input                stall,
		                   output  [3:0]        we_IMEM,
		                   output  [3:0]        we_DMEM,
                     output  [3:0]        we_ISR,	
                     output  [7:0]       UARTData,
		                   output                enable,
		                   output           DataInValid,
                     output reg [31:0]   WriteDataOut_E
                     );

  //local variable
  wire [3:0] we;
		wire storesE;
  wire loadsE;
 

 assign storesE = (opcodeE == `SB | opcodeE == `SH | opcodeE == `SW);
 assign loadsE  = (opcodeE==`LB|opcodeE==`LBU|opcodeE==`LH|opcodeE==`LHU|opcodeE==`LW);
		//Stores Control Instantiation
  StoresControl write_en( .opcodeE(opcodeE),       //inputs
                  		      .ALUoutE(ALUoutE[1:0]),
                  		      .we(we));       //output

  //Set Write Enable signals for IMEM, DMEM, & ISR
  assign we_IMEM = ( storesE & (ALUoutE[31:28] == 4'd2 | ALUoutE[31:28] == 4'd3)) ? we : 4'd0;
		       
  assign we_DMEM = ( storesE & (ALUoutE[31:28] == 4'd1 | ALUoutE[31:28] == 4'd3)) ? we : 4'd0;
		 
  assign we_ISR = ( storesE & (ALUoutE[31:28] == 4'd12) ) ? we : 4'd0;
      
  //proper enable for data mem
  assign enable = ( loadsE & (ALUoutE[31:28] == 4'd1 | ALUoutE[31:28] == 4'd3)); 

   
			

  //Data and DataInValid to UART Transmitter
  assign UARTData    =  WriteDataE[7:0];
  assign DataInValid =  ((ALUoutE == 32'h80000008) && (opcodeE == `SW | opcodeE == `SH | opcodeE == `SB)&& (~stall));

  always @( * )begin
    case(we)
      4'b1000: WriteDataOut_E = {WriteDataE[7:0], {24{1'b0}}};
      4'b0100: WriteDataOut_E = {{8{1'b0}}, WriteDataE[7:0], {16{1'b0}}};
      4'b0010: WriteDataOut_E = {{16{1'b0}}, WriteDataE[7:0], {8{1'b0}}};
      4'b0001: WriteDataOut_E = {{24{1'b0}}, WriteDataE[7:0]};
      4'b1100: WriteDataOut_E = {WriteDataE[15:0], {16{1'b0}}};
      4'b0011: WriteDataOut_E = {{16{1'b0}}, WriteDataE[15:0]};
      4'b1111: WriteDataOut_E = WriteDataE;
      default: WriteDataOut_E = 32'd0;
    endcase
  end
endmodule
