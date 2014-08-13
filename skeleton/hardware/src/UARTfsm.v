module UARTfsm(input clk,
               input reset,
               input in,
               output out
              );

 localparam STATE_0 = 1'b0,
            STATE_1 = 1'b1;

 reg cs,ns;

 assign out = in & (cs == STATE_0);

 always @(posedge clk)begin
  if(reset)cs <= in;
  else cs <= ns;
 end

 always @(*) begin
  case(cs)
   STATE_0:  ns <= in ? STATE_1 : STATE_0; 
   STATE_1:  ns <= in ? STATE_1 : STATE_0; 
  endcase
 end
endmodule
