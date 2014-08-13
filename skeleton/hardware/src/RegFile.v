//-----------------------------------------------------------------------------
//  Module: RegFile
//  Desc: An array of 32 32-bit registers
//  Inputs Interface:
//    clk: Clock signal
//    A1: first read address (asynchronous)
//    A2: second read address (asynchronous)
//    A3: write address (synchronous)
//    WE3: write enable (synchronous)
//    WD3: data to write (synchronous)
//  Output Interface:
//    RD1: data stored at address A1
//    RD2: data stored at address A2
//  Author: <<YOUR NAME HERE>>
//-----------------------------------------------------------------------------

module RegFile(input clk,
               input WE3,
               input  [4:0] A1, A2, A3,
               input  [31:0] WD3,
               output [31:0] RD1, RD2);

 (* ram_style = "distributed" *) reg [31:0] regfile_reg [31:0];

	always @ (posedge clk)begin
  regfile_reg[5'd0] <= 32'd0;
		regfile_reg[A3] <= ((WE3 == 1'b1) && (A3 != 5'd0)) ? WD3: regfile_reg[A3]; // (WE3 && (A3 != 5'd0))
	end

	assign RD1 = regfile_reg[A1];
	assign RD2 = regfile_reg[A2]; 

endmodule
