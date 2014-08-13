//----------------------------------------------------------------------
// Module: LineEngineTestbench.v
// This module tests the line engine by
// drawing a few example lines
//----------------------------------------------------------------------

`define MODELSIM 1
`timescale 1ns / 1ps

module FrameFillerTestbench();

    parameter HalfCycle = 5;
    localparam Cycle = 2*HalfCycle;	
    reg	Clock;
    initial Clock	= 0;	
    always #(HalfCycle) Clock= ~Clock;

	  wire                FF_ready;
	  // 8-bit each for RGB
	  reg [31:0]          FF_color;  
  reg [31:0]          FF_frame_base; 
	  reg [9:0]   LE_point;
	  // Valid signals for the regs
	  reg                 LE_color_valid;
	  reg                 valid;
	 
	  // Trigger signal - line engine should
	  // Start drawing the line
//	  reg                 LE_trigger;
	  // FIFO connections
	  reg                 af_full;
	  reg                 wdf_full;
	  
	  wire [2:0]          af_cmd_din;
	  wire [30:0]         af_addr_din;
	  wire                af_wr_en;
	  wire [127:0]        wdf_din;
	  wire [15:0]         wdf_mask_din;
	  wire                wdf_wr_en;
    reg                 rst;
    wire [9:0]          x;
    wire [9:0]          y;
    reg [2:0]          mask;

    wire [9:0] ydiff;
    wire [9:0] xdiff;
    assign af_cmd_din = 3'b000;

    always@(*) begin
      if(af_wr_en) begin
        if(wdf_mask_din[15:12] == 4'h0) mask = 3'h0;
        else if(wdf_mask_din[11:8] == 4'h0) mask = 3'h1;
        else if(wdf_mask_din[7:4] == 4'h0) mask = 3'h2;
        else if(wdf_mask_din[3:0] == 4'h0) mask = 3'h3;
        else mask = 3'h0;
      end
      else begin
        if(wdf_mask_din[15:12] == 4'h0) mask = 3'h4;
        else if(wdf_mask_din[11:8] == 4'h0) mask = 3'h5;
        else if(wdf_mask_din[7:4] == 4'h0) mask = 3'h6;
        else if(wdf_mask_din[3:0] == 4'h0) mask = 3'h7;
        else mask = 3'h0;
      end
    end

    assign x = {af_addr_din[8:2], 3'h0};
    assign y = af_addr_din[18:9];





FrameFiller FF(
  .clk(Clock),
  .rst(rst),
  .valid(valid),
  .color(FF_color),
  .af_full(af_full),
  .wdf_full(wdf_full),
  .wdf_din(wdf_din),
  .wdf_wr_en(wdf_wr_en),
  .af_addr_din(af_addr_din),
  .af_wr_en(af_wr_en),
  .wdf_mask_din(wdf_mask_din),
  .ready(FF_ready),
  .FF_frame_base(FF_frame_base)
);





   
    initial begin
      @(posedge Clock);
      af_full = 1'b0;
      wdf_full = 1'b0;
      valid = 1'b0;
      rst = 1'b1;
      #(10*Cycle);
      rst = 1'b0;
      #(Cycle);
      drawFrame(32'h10400000, 32'h007F0000);
      // drawLine(10'd1000, 10'd700, 10'd0, 10'd0, 32'h00_7F_00_00);
      // drawLine(10'd500, 10'd700, 10'd0, 10'd0, 32'h00_7F_00_00);
      // drawLine(10'd0, 10'd0, 10'd400, 10'd652, 32'h00_7F_00_00);
    end

    task drawFrame;
       input [31:0] frame_base;
       
      input [31:0] color;
    begin
      FF_color = color;
      FF_frame_base = frame_base;
      valid = 1'b1;
       #(Cycle);
       valid = 1'b0;
       #(Cycle);
 
      while(!FF_ready) begin
        if(wdf_wr_en && wdf_mask_din != 16'hFFFF) begin
          $display("%4d %4d", x, y);
        end
        #(Cycle);
      end

    end
    endtask

endmodule
