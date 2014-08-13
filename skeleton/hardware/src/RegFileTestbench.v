// If #1 is in the initial block of your testbench, time advances by
// 1ns rather than 1ps
`timescale 1ns / 1ps

module RegFileTestbench();

  parameter Halfcycle = 5; //half period is 5ns

  localparam Cycle = 2*Halfcycle;

  reg Clock;

  // Clock Sinal generation:
  initial Clock = 0; 
  always #(Halfcycle) Clock = ~Clock;

  // Register and wires to test the RegFile
  reg [4:0] ra1;
  reg [4:0] ra2;
  reg [4:0] wa;
  reg we;
  reg [31:0] wd;
  wire [31:0] rd1;
  wire [31:0] rd2;
  reg  [31:0] REFout;

   // Task for checking output
   task checkOutput1rd1;
        if ( REFout !== rd1 ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\trd1: 0x%h, REFout: 0x%h", rd1, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\trd1: 0x%h, REFout: 0x%h", rd1, REFout);
        end
    endtask

     task checkOutput1rd2;
        if ( REFout !== rd2 ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\trd2: 0x%h, REFout: 0x%h", rd2, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\trd2: 0x%h, REFout: 0x%h", rd2, REFout);
        end
    endtask

   task checkOutput2rd1;
        if ( REFout === rd1 ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\trd1: 0x%h, REFout: 0x%h", rd1, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\trd1: 0x%h, REFout: 0x%h", rd1, REFout);
        end
    endtask

    task checkOutput2rd2;
        if ( REFout === rd2 ) begin
            $display("FAIL: Incorrect result!!!");
            $display("\trd2: 0x%h, REFout: 0x%h", rd2, REFout);
            $finish();
        end
        else begin
            $display("PASS: Got correct result!!!!");
            $display("\trd2: 0x%h, REFout: 0x%h", rd2, REFout);
        end
    endtask
  
  RegFile DUT(.clk(Clock),
              .WE3(we),
              .A1(ra1),
              .A2(ra2),
              .A3(wa),
              .WD3(wd),
              .RD1(rd1),
              .RD2(rd2));
  
  //declare looping variables
  integer i;
  localparam loops = 32;

  // Testing logic:

  initial begin
     #1;
    // Verify that writing to reg 0 is a nop
    $display("Verifying writing to register 0 is a nop...");
    for(i = 0; i < loops; i = i + 1)
    begin
        ra1 = 5'b0;
        ra2 = 5'b0;
	we  = 1'b1;
	wd  = {$random} & 32'hFFFFFFFF;
	wa  = 5'b0;
	if (i === 0)
	     #4;
        else
	     #(Halfcycle);

	REFout = 1'b0;
	
	#(Halfcycle);
	if(i < 16)
		checkOutput1rd1();
	else
		checkOutput1rd2();
	
    end

    // Verify that data written to any other register is returned the same
    // cycle
    $display("\nVerify that data written to any other register is returned the same cycle...");

    for(i = 1; i < loops; i = i + 1)
    begin

	ra1 = i;
	ra2 = i;
	we = 1'b1;
	wd = {$random} & 32'hFFFFFFFF;
	wa = i;
	#1;
	REFout = wd;
	#5;

	if(i < 16)
		checkOutput1rd1();
	else
		checkOutput1rd2();

	#4;
    end
  
    // Verify that the we pin prevents data from being written
    $display("\nVerify that the we pin prevents data from being written...");
     for(i = 1; i < loops; i = i + 1)
     begin

	ra1 = i;
	ra2 = i;
	we = 1'b0;
	wd = {$random} & 32'hFFFFFFFF;
	wa = i;
	#1;
	REFout = wd;
	#5;

	if(i < 16)
		checkOutput2rd1();
	else
		checkOutput2rd2();

	#4;
    end


    // Verify the reads are asynchronous
    $display("\nVerify the reads are asynchronous...");
    for(i = 1; i < loops; i = i + 1)
    begin

	ra1 = i;
	ra2 = i;
        we = 1'b1;
        wa =  i;
	wd = i;
        #1
        REFout = wd;
	#9;
    end
    
    for(i = 1; i < loops; i = i + 1)
    begin
       #1;
       ra1 = i;
       ra2 = i;
       REFout = i;
       #1;
       checkOutput1rd1();
       #1;
       checkOutput1rd2();
       #1;
    end

   
    $display("All tests passed!");
    $finish();
  end
endmodule
