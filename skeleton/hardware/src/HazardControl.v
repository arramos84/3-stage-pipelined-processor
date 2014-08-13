module HazardControl(input [4:0]           RsE,
		     input [4:0]           RtE,
		     input [4:0]     WriteRegM,
		     input               Stall,
                     input           RegWriteM,
	             output           StallCPU,
                     output          ForwardA_E,
		     output          ForwardB_E);

	//Forward if register being written to in the Mem Stage is the same as one needed in the Execute Stage
	assign ForwardA_E = ((RsE != 5'b0) && (RsE == WriteRegM) && (RegWriteM));
	assign ForwardB_E = ((RtE != 5'b0) && (RtE == WriteRegM) && (RegWriteM));

	//If the input Stall is high, stall the CPU
	assign StallCPU = Stall;

endmodule
