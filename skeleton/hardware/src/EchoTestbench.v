`timescale 1ns/1ps

module EchoTestbench();

    reg Clock, Reset;
    wire FPGA_SERIAL_RX, FPGA_SERIAL_TX;

    reg   [7:0] DataIn;
    reg         DataInValid;
    wire        DataInReady;
    wire  [7:0] DataOut;
    wire        DataOutValid;
    reg         DataOutReady;
    wire 	stall;

    parameter HalfCycle = 5;
    parameter Cycle = 2*HalfCycle;
    parameter ClockFreq = 50_000_000;

    initial Clock = 0;
    always #(HalfCycle) Clock <= ~Clock;

/*
    always@(posedge Clock) 
      if(Reset)
          stall <= 1'b0;
      else
          stall <= ~stall;
*/

    assign stall = 1'b0;
  
    MIPS150 CPU(
    .clk(Clock), .rst(Reset), .stall(stall),
    .FPGA_SERIAL_RX(FPGA_SERIAL_RX),
    .FPGA_SERIAL_TX(FPGA_SERIAL_TX),
    .dcache_addr(),
    .icache_addr(),
    .dcache_we(),
    .icache_we(),
    .dcache_re(),
    .icache_re(),
    .dcache_din(),
    .icache_din(),
    .dcache_dout(),
    .instruction());




    UART          #( .ClockFreq(       ClockFreq))
                  uart( .Clock(           Clock),
                        .Reset(           Reset),
                        .DataIn(          DataIn),
                        .DataInValid(     DataInValid),
                        .DataInReady(     DataInReady),
                        .DataOut(         DataOut),
                        .DataOutValid(    DataOutValid),
                        .DataOutReady(    DataOutReady),
                        .SIn(             FPGA_SERIAL_TX),
                        .SOut(            FPGA_SERIAL_RX));

    initial begin
      // Reset. Has to be long enough to not be eaten by the debouncer.
      Reset = 0;
      DataIn = 8'h7a;
      DataInValid = 0;
      DataOutReady = 0;
      #(100*Cycle)

      Reset = 1;
      #(30*Cycle)
      Reset = 0;

      // Wait until transmit is ready
      while (!DataInReady) #(Cycle);
      DataInValid = 1'b1;
      #(Cycle)
      DataInValid = 1'b0; 

      // Wait for something to come back

      while (!DataOutValid) #(Cycle);
	  DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;
      $display("Got %d", DataOut); //supposed to be 13 (\r)


	  DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;
      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 10 (\n)
      #(30*Cycle);	
	  DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;
      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 13 (\r)
      #(30*Cycle);
	  DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;
      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 10 (\n)
      #(30*Cycle);
	DataOutReady = 1;
	#(Cycle)
	DataOutReady = 0;	

      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 13 (\r)
      #(30*Cycle);
	DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;

      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 10 (\n)
      #(30*Cycle);	
	DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;

      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 13 (\r)
      #(30*Cycle);
	DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;

      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 10 (\n)
      #(30*Cycle);
	DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;

      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 62 (>)
      #(30*Cycle);
	DataOutReady = 1;
	  #(Cycle)
	  DataOutReady = 0;

      while (!DataOutValid) #(Cycle);
      $display("Got %d", DataOut); //supposed to be 32 (space)
      #(30*Cycle);

      $finish();
  end
/*
initial begin
	stall=0;
	#(250*Cycle);
	stall=1;
	#(10*Cycle);
	stall=0;
end
*/
endmodule
