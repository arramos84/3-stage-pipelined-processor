`timescale 1ns/1ps

module GraphicsProcessorTestbench();

  reg Clock, Reset;

  parameter HalfCycle = 5;
  parameter Cycle = 2*HalfCycle;
  parameter ClockFreq = 50_000_000;

  initial Clock = 0;
  always #(HalfCycle) Clock <= ~Clock;
    

  reg rdf_valid;
  reg af_full;
  reg [127:0] rdf_dout;
  wire rdf_rd_en;
  wire af_wr_en;
  wire [30:0] af_addr_din;
  reg gp_FF_ready;
  reg gp_LE_ready;
    

  //frame filler commands
  wire FF_ready; 
  wire FF_valid;
  wire [23:0] FF_color;
  wire [31:0] FF_frame;
  wire [9:0]          ff_x;
  wire [9:0]          ff_y;
  wire [127:0]        ff_wdf_din;
  wire [15:0]         ff_wdf_mask_din;
  reg [2:0]           ff_mask;
  wire [30:0]         ff_af_addr_din;
  wire                ff_af_wr_en;
  wire                ff_wdf_wr_en;
    
  //line engine commands 
  wire LE_ready;
  wire [31:0] LE_color;
  wire [9:0]          le_x;
  wire [9:0]          le_y;
  wire [127:0]        le_wdf_din;
  wire [15:0]         le_wdf_mask_din;
  reg [2:0]           le_mask;
  wire [30:0]         le_af_addr_din;
  wire                le_af_wr_en;
  wire                le_wdf_wr_en;
  wire [19:0] LE_point;
  wire LE_color_valid;
  wire LE_x0_y0_valid;
  wire LE_x1_y1_valid;
  wire LE_trigger; 
  wire [31:0] LE_frame;

  //Shared Variables
  wire gp_interrupt;   
  reg [31:0] gp_code;
  reg [31:0] gp_frame;
  reg gp_valid;
  reg                 wdf_full;
  wire [127:0]        wdf_din;
  wire [15:0]         wdf_mask_din;
  wire                wdf_wr_en;
   
always @ (*) begin 
    gp_FF_ready = FF_ready; 
    gp_LE_ready = LE_ready; 
end

 GraphicsProcessor DUT(	
        .clk(Clock),
	.rst(Reset),

	//line engine control signals
	.LE_ready(gp_LE_ready),
	.LE_color(LE_color),
	.LE_point(LE_point),
	.LE_color_valid(LE_color_valid),
	.LE_x0_y0_valid(LE_x0_y0_valid),
	.LE_x1_y1_valid(LE_x1_y1_valid),
	.LE_trigger(LE_trigger),
	.LE_frame(LE_frame),

	//frame filler control signals
	.FF_ready(gp_FF_ready),
	.FF_valid(FF_valid),
	.FF_color(FF_color),
	.FF_frame(FF_frame),

	//DRAM request controller interface
	.rdf_valid(rdf_valid),
	.af_full(af_full),
	.rdf_dout(rdf_dout),
	.rdf_rd_en(rdf_rd_en),
	.af_wr_en(af_wr_en),
	.af_addr_din(af_addr_din),
	.GP_CODE(gp_code),
	.GP_FRAME(gp_frame),
	.GP_valid(gp_valid),
   .done()
	);



FrameFiller FF(
  .clk(Clock),
  .rst(Reset),
  .valid(FF_valid),
  .color(FF_color),
  .af_full(af_full),
  .wdf_full(wdf_full),
  .wdf_din(ff_wdf_din),
  .wdf_wr_en(ff_wdf_wr_en),
  .af_addr_din(ff_af_addr_din),
  .af_wr_en(ff_af_wr_en),
  .wdf_mask_din(ff_wdf_mask_din),
  .ready(FF_ready),
  .FF_frame_base(FF_frame)
);

LineEngine LE(
  .clk(Clock),
  .rst(Reset),
  .LE_ready(LE_ready),
  .LE_color(LE_color),
  .LE_point(LE_point), 
  .LE_color_valid(LE_color_valid),
  .LE_x0_y0_valid(LE_x0_y0_valid),
  .LE_x1_y1_valid(LE_x1_y1_valid),
  .LE_trigger(LE_trigger),
  .af_full(af_full),
  .wdf_full(wdf_full), 
  .af_addr_din(le_af_addr_din),
  .af_wr_en(le_af_wr_en),
  .wdf_din(le_wdf_din),
  .wdf_mask_din(le_wdf_mask_din),
  .wdf_wr_en(le_wdf_wr_en),
  .LE_frame_base(LE_frame)
);

 //FRAME FILLER MASKING
  always@(*) begin
    if(ff_af_wr_en) begin
      if(ff_wdf_mask_din[15:12] == 4'h0) ff_mask = 3'h0;
      else if(ff_wdf_mask_din[11:8] == 4'h0) ff_mask = 3'h1;
      else if(ff_wdf_mask_din[7:4] == 4'h0) ff_mask = 3'h2;
      else if(ff_wdf_mask_din[3:0] == 4'h0) ff_mask = 3'h3;
      else ff_mask = 3'h0;
    end
    else begin
      if(ff_wdf_mask_din[15:12] == 4'h0) ff_mask = 3'h4;
      else if(ff_wdf_mask_din[11:8] == 4'h0) ff_mask = 3'h5;
      else if(ff_wdf_mask_din[7:4] == 4'h0) ff_mask = 3'h6;
      else if(ff_wdf_mask_din[3:0] == 4'h0) ff_mask = 3'h7;
      else ff_mask = 3'h0;
    end
  end

  //LINE ENGINE MASKING
  always@(*) begin
    if(le_af_wr_en) begin
      if(le_wdf_mask_din[15:12] == 4'h0) le_mask = 3'h0;
      else if(le_wdf_mask_din[11:8] == 4'h0) le_mask = 3'h1;
      else if(le_wdf_mask_din[7:4] == 4'h0) le_mask = 3'h2;
      else if(le_wdf_mask_din[3:0] == 4'h0) le_mask = 3'h3;
      else le_mask = 3'h0;
    end
    else begin
      if(le_wdf_mask_din[15:12] == 4'h0) le_mask = 3'h4;
      else if(le_wdf_mask_din[11:8] == 4'h0) le_mask = 3'h5;
      else if(le_wdf_mask_din[7:4] == 4'h0) le_mask = 3'h6;
      else if(le_wdf_mask_din[3:0] == 4'h0) le_mask = 3'h7;
      else le_mask = 3'h0;
    end
  end

  assign ff_x = {ff_af_addr_din[8:2], 3'h0};
  assign ff_y = ff_af_addr_din[18:9];

  assign le_x = {le_af_addr_din[8:2], le_mask};
  assign le_y = le_af_addr_din[18:9];   

  initial begin
    @(posedge Clock);

    rdf_valid = 1'b0;
    af_full = 1'b0;
    gp_valid = 1'b0;
    wdf_full = 1'b0;
       
    gp_frame = 32'h10400000;
    gp_code = 32'h10200000;
    Reset = 1'b1;
       
    #(10*Cycle);
    Reset = 1'b0;
    #(10*Cycle);
    gp_valid = 1'b1;
    #(Cycle);    
    gp_valid = 1'b0;
    #(Cycle);

    while(!af_wr_en)#(Cycle);
    $display("%9h %9h", af_addr_din, gp_code);
    #(Cycle);
    rdf_dout = 128'h00000000_00FF00FF_02AABBCC_010000EE;
    rdf_valid = 1'b1;
    #(Cycle);
    rdf_valid = 1'b0;
    #(Cycle);

    rdf_dout = 128'h00FF00FF_00000000_020000FF_010000FF;
    rdf_valid = 1'b1;
    #(Cycle);
    rdf_valid = 1'b0;
    #(Cycle);

    gp_code = gp_code + 32'd8;
    while(!af_wr_en)#(Cycle);
    $display("%9h %9h", af_addr_din, gp_code);
    #(Cycle);
    rdf_dout = 128'h00000000_01123456_010000FF_00000257;
    rdf_valid = 1'b1;
    #(Cycle);
    rdf_valid = 1'b0;
    #(Cycle);
    rdf_dout = 128'h031F0000_02332211_01F0F0F0_011a2b3c;
    rdf_valid = 1'b1;
    #(Cycle);
    rdf_valid = 1'b0;
    #(Cycle);

//FF
    while(FF_ready)#(Cycle);
    $display("FRAME FILLER RUNNING...");
    while(!FF_ready) begin
      if(ff_wdf_wr_en && ff_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", ff_x, ff_y, ff_wdf_din);
      end
      #(Cycle);
    end 
//LE
    while(LE_ready)#(Cycle);
    $display("LINE ENGINE RUNNING...");
    while(!LE_ready) begin
      if(le_wdf_wr_en && le_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", le_x, le_y, le_wdf_din);
      end
      #(Cycle);
    end 
//FF
    #(100*Cycle);
    while(FF_ready)#(Cycle);
    $display("FRAME FILLER RUNNING...");
    while(!FF_ready) begin
      if(ff_wdf_wr_en && ff_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", ff_x, ff_y, ff_wdf_din);
      end
      #(Cycle);
    end 
//LE
    while(LE_ready)#(Cycle);
    $display("LINE ENGINE RUNNING...");
    while(!LE_ready) begin
      if(le_wdf_wr_en && le_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", le_x, le_y, le_wdf_din);
      end
      #(Cycle);
    end 
//FF
    while(FF_ready)#(Cycle);
    $display("FRAME FILLER RUNNING...");
    while(!FF_ready) begin
      if(ff_wdf_wr_en && ff_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", ff_x, ff_y, ff_wdf_din);
      end
      #(Cycle);
    end 
//FF
    while(FF_ready)#(Cycle);
    $display("FRAME FILLER RUNNING...");
    while(!FF_ready) begin
      if(ff_wdf_wr_en && ff_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", ff_x, ff_y, ff_wdf_din);
      end
      #(Cycle);
    end 
//LE
    while(LE_ready)#(Cycle);
    $display("LINE ENGINE RUNNING...");
    while(!LE_ready) begin
      if(le_wdf_wr_en && le_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", le_x, le_y, le_wdf_din);
      end
      #(Cycle);
    end 
//FF
    while(FF_ready)#(Cycle);
    $display("FRAME FILLER RUNNING...");
    while(!FF_ready) begin
      if(ff_wdf_wr_en && ff_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", ff_x, ff_y, ff_wdf_din);
      end
      #(Cycle);
    end 
//FF
    while(FF_ready)#(Cycle);
    $display("FRAME FILLER RUNNING...");
    while(!FF_ready) begin
      if(ff_wdf_wr_en && ff_wdf_mask_din != 16'hFFFF) begin
              $display("%4d %4d %32h", ff_x, ff_y, ff_wdf_din);
      end
      #(Cycle);
    end 


    #(100*Cycle);
    $finish();
  end

    
endmodule
