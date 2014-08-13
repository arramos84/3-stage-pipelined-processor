
/*
 Command procesor module that handles the logic for parsing the graphics commands
 Three graphics commands for line engine:
 1. Write start point
 2. Write end-point
 3. Write line color
 If trigger bit set in command, command will also fire on start or end point
 Frame buffer fill will trigger automatically also... 
  I Alexander Ramos wish to indusputably declare my unwavering love for male genitalia.
  I love it on a boat, in my moat, but most passionatly in my throat!
 
 */
`include "gpcommands.vh"

module GraphicsProcessor(
    input clk,
    input rst,

    //line engine processor interface
    input LE_ready,
    output [31:0] LE_color,
    output [19:0] LE_point,
    output LE_color_valid,
    output LE_x0_y0_valid,
    output LE_x1_y1_valid,

    output LE_trigger,
    output [31:0] LE_frame,
		       
    //frame filler processor interface
    input FF_ready,
    output FF_valid,
    output [23:0] FF_color,
    output [31:0] FF_frame,
		       
    //DRAM request controller interface
    input rdf_valid,
    input af_full,
    input [127:0] rdf_dout,
    output rdf_rd_en,
    output af_wr_en,
    output [30:0] af_addr_din,
		       
    //processor interface
    input [31:0] GP_CODE,
    input [31:0] GP_FRAME,
    input GP_valid,
    output reg done
    );
     
//--------------------------------------------------
//     FSM: Varibles
//--------------------------------------------------.

   localparam gpIDLE       = 4'd0,
              gpRESET      = 4'd1,
              gpFETCH      = 4'd2,
              gpDecode     = 4'd3,
              gpFF_COLOR   = 4'd4,
              gpFF_WAIT    = 4'd5,
              gpLE_COLOR   = 4'd6,
              gpLE_POINT1  = 4'd7,
              gpLE_POINT2  = 4'd8,
              gpLE_TRIGGER = 4'd9,
              gpLE_WAIT    = 4'd10;
              
   localparam cmdIDLE    = 2'd0,
              cmdREQUEST = 2'd1,
              cmdFETCH_1 = 2'd2,
              cmdFETCH_2 = 2'd3;
 
   wire gotFirstBurst;
   wire gotSecondBurst;
   wire incrementCmdPtr;
   wire needCommands;
   wire dump;
   wire stopCmd;          

   reg [31:0] curCmd;
   reg [255:0] cmdBuff [1:0];  //TODO: Check if this instatiation is right
   reg [2:0] cmdNum;
   reg curCmdBuff, buffToFill;
   reg buffDirty [1:0];
   
   reg [1:0] cmdCS, cmdNS;
   reg [3:0] gpCS, gpNS;

   reg [31:0] gpCodeAddr, gpFrame;
     reg [31:0] counter;


    //////////////CHIPSCOPE SHIT////////////////////////////////////
   wire [35:0] chipscope_control;

   chipscope_icon icon(
	.CONTROL0(chipscope_control)
   )/* synthesis syn_noprune=1 */;

   chipscope_ila ila(
	.CONTROL(chipscope_control),
	.CLK(clk),
	.TRIG0({FF_ready, FF_valid, rdf_valid, FF_frame, curCmd, cmdNum, curCmdBuff, buffToFill, cmdCS, cmdNS, gpCS, gpNS, GP_CODE, GP_FRAME, GP_valid, buffDirty[0], buffDirty[1], af_full, af_wr_en, af_addr_din, done,LE_x0_y0_valid,LE_x1_y1_valid,gotFirstBurst,gotSecondBurst,incrementCmdPtr,needCommands,dump,stopCmd,counter,rst })
     ) /* synthesis syn_noprune=1 */;

    always @ (posedge clk) begin
	if(GP_valid) counter <= 32'd0;
	else counter <= counter + 32'd1;
    end
   ////////////////////////////////////////////////////////////////
   
//--------------------------------------------------
//   GP FSM: Current State => Next State Logic
//-------------------------------------------------- 
         


   //  CS Register
   always@(posedge clk)begin
     if(rst) gpCS <= gpIDLE; 
     else if((gpCS != gpIDLE) & GP_valid) gpCS <= gpRESET; 
     else gpCS <= gpNS;
   end 
  
   // NS Logic
   always@(buffDirty[0],buffDirty[1],gpCS,cmdCS,GP_valid,curCmd,FF_ready,LE_ready,curCmdBuff,gpFF_COLOR,gpDecode,gpFETCH,gpIDLE,gpFF_WAIT,gpLE_POINT1,gpLE_POINT2,gpLE_TRIGGER,gpLE_WAIT,gpRESET,gpDecode)begin
     gpNS = gpCS;
     case(gpCS)
       gpIDLE: gpNS = GP_valid ? gpFETCH : gpIDLE;
       gpRESET: gpNS = (cmdCS==cmdIDLE) ? gpFETCH : gpRESET;
       gpFETCH: gpNS = (!buffDirty[curCmdBuff]) ? gpDecode : gpFETCH;
       gpDecode: if(!buffDirty[curCmdBuff])begin
                   case(curCmd[31:24])
                     `STOP: gpNS = gpIDLE;
                     `FILL: gpNS = (FF_ready) ? gpFF_COLOR : gpDecode;
                     `LINE: gpNS = (LE_ready) ? gpLE_COLOR : gpDecode;
                     default: gpNS = gpIDLE;
                   endcase   
                 end else gpNS = gpDecode;
       gpFF_COLOR: gpNS = gpFF_WAIT;
       gpFF_WAIT: gpNS = (FF_ready & !buffDirty[curCmdBuff]) ? gpDecode : gpFF_WAIT;
       gpLE_COLOR: gpNS = !buffDirty[curCmdBuff] ? gpLE_POINT1 : gpLE_COLOR;
       gpLE_POINT1: gpNS = !buffDirty[curCmdBuff] ? gpLE_POINT2 : gpLE_POINT1;
       gpLE_POINT2: gpNS = gpLE_TRIGGER;
       gpLE_TRIGGER: gpNS = gpLE_WAIT;
       gpLE_WAIT: gpNS = (LE_ready & !buffDirty[curCmdBuff]) ? gpDecode : gpLE_WAIT;
     endcase
   end
   
//--------------------------------------------------
//   GP  FSM: Control Logic
//-------------------------------------------------- 

   // GP_FRAME Register
   always@(posedge clk)begin
     if(rst) gpFrame <= 32'h10400000;
     else if(GP_valid) gpFrame <= GP_FRAME; 
     else gpFrame <= gpFrame; 
   end

   //  GP_CODE Register
   always@(posedge clk)begin
     if(rst | done) gpCodeAddr <= 32'd0;
     else if(GP_valid) gpCodeAddr <= {6'd0,GP_CODE[27:5],2'd0}; 
     else if(gotSecondBurst) gpCodeAddr <= gpCodeAddr + 32'd4; 
     else gpCodeAddr <= gpCodeAddr;
   end

   assign incrementCmdPtr = ( (gpCS==gpFF_COLOR)   | 
                              ((gpCS==gpLE_COLOR)  & ~buffDirty[curCmdBuff])  | 
                              ((gpCS==gpLE_POINT1) & ~buffDirty[curCmdBuff])  |  
                              (gpCS==gpLE_POINT2)  ); 

   always@(cmdBuff[0], cmdBuff[1], cmdNum, curCmdBuff)begin
     case(cmdNum)   
       3'd0: curCmd = cmdBuff[curCmdBuff][8'd31:8'd0];  
       3'd1: curCmd = cmdBuff[curCmdBuff][8'd63:8'd32];  
       3'd2: curCmd = cmdBuff[curCmdBuff][8'd95:8'd64];
       3'd3: curCmd = cmdBuff[curCmdBuff][8'd127:8'd96];
       3'd4: curCmd = cmdBuff[curCmdBuff][8'd159:8'd128];
       3'd5: curCmd = cmdBuff[curCmdBuff][8'd191:8'd160];
       3'd6: curCmd = cmdBuff[curCmdBuff][8'd223:8'd192];
       3'd7: curCmd = cmdBuff[curCmdBuff][8'd255:8'd224]; 
     endcase
   end


   // maintain command pointers
   always@(posedge clk)begin
     if(rst | dump | done)begin 
       cmdNum <= 3'd0;
       curCmdBuff <= 1'd0;
       buffToFill <= 1'd0;
       buffDirty[1'd0] <= 1'd1; 
       buffDirty[1'd1] <= 1'd1; 
     end else begin
       if(gotSecondBurst) begin
         buffDirty[buffToFill] <= 1'd0;         
         buffToFill <= ~buffToFill;
       end
       if(incrementCmdPtr) begin
         if(cmdNum==3'd7) begin 
           cmdNum <= 3'd0;
           buffDirty[curCmdBuff] <= 1'd1;
           curCmdBuff <= ~curCmdBuff;                            
         end else begin
           cmdNum <= cmdNum + 3'd1;
         end
       end
     end 
   end
   
//--------------------------------------------------
//Commands Fifo FSM: Current State => Next State Logic
//-------------------------------------------------- 
    
   // CS Register  
   always@(posedge clk)begin
     if(rst) cmdCS <= cmdIDLE;
     else cmdCS <= cmdNS;
   end 
  
  always@(posedge clk)begin
    if(rst | dump | done)begin
      cmdBuff[1'd0] <= 256'd0;
      cmdBuff[1'd1] <= 256'd0;
    end else if((cmdCS==cmdFETCH_1) & rdf_valid)begin 
      cmdBuff[buffToFill][8'd255:8'd128] <= rdf_dout;
    end else if((cmdCS==cmdFETCH_2) & rdf_valid)begin 
      cmdBuff[buffToFill][8'd127:8'd0] <= rdf_dout;
    end
  end

   // NS logic
   always@(*)begin
     cmdNS = cmdCS;
     case(cmdCS)
       cmdIDLE: cmdNS = needCommands ? cmdREQUEST : cmdIDLE;
       cmdREQUEST: cmdNS = (~af_full) ? cmdFETCH_1 : cmdREQUEST;
       cmdFETCH_1: cmdNS = (rdf_valid) ? cmdFETCH_2 : cmdFETCH_1;
       cmdFETCH_2: cmdNS = (rdf_valid) ? cmdIDLE : cmdFETCH_2;
     endcase
   end
   
//--------------------------------------------------
//   Commands Fifo FSM: Control Logic
//-------------------------------------------------- 
   
   assign needCommands = (buffDirty[buffToFill] & (gpCS!=gpIDLE) & (gpCS!=gpRESET));
   assign dump = (cmdCS==cmdIDLE & gpCS==gpRESET);
   assign gotFirstBurst = ((cmdCS==cmdFETCH_1) & rdf_valid);
   assign gotSecondBurst = ((cmdCS==cmdFETCH_2) & rdf_valid);
   
//--------------------------------------------------
//     GP: output assignment
//-------------------------------------------------- 
    always@(posedge clk)begin
      if(rst)done <= 1'd0;
      else if(stopCmd) done <= 1'd1;
      else done <= 1'd0;
    end
    
    //MIPS interface
   assign stopCmd = ((gpCS==gpDecode) & ~buffDirty[curCmdBuff] & (curCmd[31:24]==`STOP));  
   assign LE_color = {8'd0,curCmd[23:0]};
   assign LE_point = {curCmd[25:16],curCmd[9:0]};
   assign LE_color_valid = (gpCS==gpLE_COLOR) & ~buffDirty[curCmdBuff];
   assign LE_x0_y0_valid = (gpCS==gpLE_POINT1) & ~buffDirty[curCmdBuff];
   assign LE_x1_y1_valid = (gpCS==gpLE_POINT2) & ~buffDirty[curCmdBuff];
   assign LE_trigger = (gpCS==gpLE_TRIGGER);
   assign LE_frame = gpFrame;
		       
   //frame filler processor interface
   assign FF_valid  = (gpCS==gpFF_COLOR);
   assign FF_color = curCmd[23:0];
   assign FF_frame = gpFrame;
		       
   //DRAM request controller interface
   assign rdf_rd_en = 1'b1;//(cmdCS != cmdIDLE);
   assign af_wr_en = (cmdCS == cmdREQUEST);
   assign af_addr_din = gpCodeAddr;
		       
endmodule
