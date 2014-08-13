/**module FlipFlopEN #(parameter WIDTH = 32)
		   (input          clk,en,rst,
		    input      [WIDTH - 1] d,
		    output reg [WIDTH - 1] q);

	always @ (posedge clk) begin
		if(rst) q <= 32'b0;
		else if(en) q <= d;
		else  q <= q;
	end
endmodule**/
