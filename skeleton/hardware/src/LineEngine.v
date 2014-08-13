
module LineEngine(
  input                 clk,
  input                 rst,
  output                LE_ready, //get set sychronisely
  // 8-bit each for RGB, and 8 bits zeros at the top
  input [31:0]          LE_color,
  input [19:0]          LE_point,
  // Valid signals for the inputs
  input                 LE_color_valid,
  input                 LE_X0_Y0_valid,
  input                 LE_X1_Y1_valid,
  // Trigger signal - line engine should
  // Start drawing the line
  input                 LE_trigger,
  // FIFO connections
  input                 af_full, 
  input                 wdf_full, 
  
  output [30:0]         af_addr_din,
  output                af_wr_en,
  output [127:0]        wdf_din,
  output [15:0]         wdf_mask_din,
  output                wdf_wr_en,

  input [31:0] 		LE_frame_base
);


    localparam IDLE = 1'b0,
               DRAW = 1'b1;


    reg[9:0]      X0, Y0, X1, Y1, X, Y;
    reg[9:0]      dx, dy;  
    reg           yStep;
    reg[9:0]      error;
    reg           steep;
    reg[31:0]     color;
    wire[16:0]    XY_or_YX;
    wire[2:0]     ignore;
    reg           burstNum;
    wire[31:0]    mask;
    reg           CS, NS;
    wire          ready;
    reg           done;

    
    always @(posedge clk) begin
      done <= rst ? 1'b1 : (LE_trigger ? 1'b0 : (((X==X1) & (burstNum==1)) ? 1'b1 : done));
    end

    always @(posedge clk) begin
      if(rst) begin
        X0 <= 0;
        Y0 <= 0;
        X1 <= 0;
        Y1 <= 0;
        color <= 0;
      end else if(LE_trigger) begin
        X0 <= steep ? ((Y0>Y1) ? Y1:Y0) : ((X0>X1) ? X1:X0);
        Y0 <= steep ? ((Y0>Y1) ? X1:X0) : ((X0>X1) ? Y1:Y0);
        X1 <= steep ? ((Y0>Y1) ? Y0:Y1) : ((X0>X1) ? X0:X1);
        Y1 <= steep ? ((Y0>Y1) ? X0:X1) : ((X0>X1) ? Y0:Y1);
      end
      else begin
        {X0,Y0} <= LE_X0_Y0_valid ? LE_point : {X0,Y0};
        {X1,Y1} <= LE_X1_Y1_valid ? LE_point : {X1,Y1};
        color <= LE_color_valid ? LE_color : color;
      end
    end
    
    always @(posedge clk) begin
      if(rst) begin
        dx <= 0;
        dy <= 0;
        error <= 0;
        yStep <= 0;
        X <= 0;
        Y <= 0;
        burstNum <= 0;
      end else if(LE_trigger) begin
        X <= steep ? ((Y0>Y1) ? Y1:Y0) : ((X0>X1) ? X1:X0);
        Y <= steep ? ((Y0>Y1) ? X1:X0) : ((X0>X1) ? Y1:Y0);
        dx <= steep ? ((Y0>Y1) ? (Y0-Y1):(Y1-Y0)) : ((X0>X1) ? (X0-X1):(X1-X0));
        dy <= steep ? ((X0>X1) ? (X0-X1):(X1-X0)) : ((Y0>Y1) ? (Y0-Y1):(Y1-Y0));
        error <= (steep ? ((Y0>Y1) ? (Y0-Y1):(Y1-Y0)) 
                        : ((X0>X1) ? (X0-X1):(X1-X0))) >> 2'h1;
        yStep <= steep ? ((Y1>Y0 && X1>X0) || (Y0>Y1 && X0>X1)) 
                       : ((X0>X1 && Y0>Y1) || (X1>X0 && Y1>Y0)) ;
        burstNum <= 0;
      end else if(NS == DRAW) begin
        error <= burstNum ? ((error < dy) ? (error-dy+dx) : (error-dy)) : error;
        X <= burstNum ? (X + 1) : X;
        Y <= burstNum ? ((error < dy) ? (yStep ? (Y+1):(Y-1)) : Y ) : Y;
        burstNum <= ~burstNum;
      end else begin
        error <= error;
        X <= X;
        Y <= Y;
        burstNum <= burstNum;
      end
    end

   always @(posedge clk) begin
      if(rst) CS <= 0;
      else CS <= NS; 
    end

    always @(*) begin
      NS = CS;
      case(CS) 
        IDLE: begin 
          NS = (!done && ready) ? DRAW : IDLE; 
          steep = (LE_trigger && done)? 
                  ((((Y1<Y0)?(Y0-Y1):(Y1-Y0)) > ((X1<X0)?(X0-X1):(X1-X0))) ? 1'b1:1'b0) 
                  : steep;
        end
        DRAW: begin
          NS = (done || !ready) ? IDLE : DRAW;
        end
      endcase
    end

    assign LE_ready = done;
    assign ready = (!af_full && !wdf_full);
    assign af_wr_en = !done && !burstNum;
    assign af_addr_din = {9'd0, LE_frame_base[24:22], XY_or_YX, 2'b0};
    assign wdf_wr_en = !done;
    assign wdf_mask_din = burstNum ? mask[15:0] : mask[31:16];
    assign wdf_din = {4{8'h0, color[23:0]}};
    assign ignore = steep ? Y[2:0] : X[2:0];
    assign XY_or_YX = steep ? {X, Y[9:3]} : {Y, X[9:3]};
    assign mask = done ? 32'hFFFFFFFF :
                        {(ignore == 3'h0 ? 4'h0 : 4'hF),
                         (ignore == 3'h1 ? 4'h0 : 4'hF),  
                         (ignore == 3'h2 ? 4'h0 : 4'hF),  
                         (ignore == 3'h3 ? 4'h0 : 4'hF),  
                         (ignore == 3'h4 ? 4'h0 : 4'hF),  
                         (ignore == 3'h5 ? 4'h0 : 4'hF),  
                         (ignore == 3'h6 ? 4'h0 : 4'hF),  
                         (ignore == 3'h7 ? 4'h0 : 4'hF)  
                        };

endmodule
