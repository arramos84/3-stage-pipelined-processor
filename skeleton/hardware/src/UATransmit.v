module UATransmit(
  input   Clock,
  input   Reset,

  input   [7:0] DataIn,
  input         DataInValid,
  output        DataInReady,

  output        SOut
);
  // for log2 function
  `include "util.vh"

  //--|Parameters|--------------------------------------------------------------

  parameter   ClockFreq         =   100_000_000;
  parameter   BaudRate          =   115_200;

  // See diagram in the lab guide
  localparam  SymbolEdgeTime    =   ClockFreq / BaudRate;
  localparam  ClockCounterWidth =   log2(SymbolEdgeTime);

  //--|Solution|----------------------------------------------------------------
  //--|Declarations|------------------------------------------------------------

  wire                            SymbolEdge;
  wire                            Start;
  wire                            TXRunning;

  reg    [9:0]                   TXShift;
  reg     [3:0]                   BitCounter;
  reg     [ClockCounterWidth-1:0] ClockCounter;

  //--|Signal Assignments|------------------------------------------------------

  // Goes high at every symbol edge
  assign  SymbolEdge   = (ClockCounter == SymbolEdgeTime - 1);

  // Goes high when it is time to start transmitting a new character
  assign  Start         = DataInValid && DataInReady;

  // Currently transmitting a character
  assign  TXRunning     = BitCounter != 4'd0;

  // Data can only be ready if not currently transmitting
  assign DataInReady = !TXRunning;
  

  // Send out bits one at a time if transmit running is high
  assign  SOut = TXShift[0];


  //--|Counters|----------------------------------------------------------------

  // Counts cycles until a single symbol is done
  always @ (posedge Clock) begin
    ClockCounter <= (Start || Reset || SymbolEdge) ? 0 : ClockCounter + 1;
  end

  // Counts down from 10 bits for every character
  always @ (posedge Clock) begin
    if (Reset) begin
      BitCounter <= 0;
    end else if (Start) begin
      BitCounter <= 10;
    end else if (SymbolEdge && TXRunning) begin
      BitCounter <= BitCounter - 1;
    end
  end

  always @ (posedge Clock) begin
    if (Reset) begin
      TXShift <= 10'b1111111111;
    end else if (Start) begin
      TXShift <= {1'b1, DataIn, 1'b0};
    end else if (SymbolEdge && TXRunning) begin
      TXShift <= {1'b1, TXShift[9:1]};
    end
  end
endmodule
