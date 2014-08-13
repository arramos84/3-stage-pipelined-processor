/* This module keeps a FIFO filled that then outputs to the DVI module. */

module PixelFeeder( //System:
                    input          cpu_clk_g,
                    input          clk50_g, // DVI Clock
                    input          rst,
                    //DDR2 FIFOS:
                    input          rdf_valid,
                    input          af_full,
                    input  [127:0] rdf_dout,
                    output         rdf_rd_en,
                    output         af_wr_en,
                    output [30:0]  af_addr_din,
                    // DVI module:
                    output [23:0]  video,
                    output         video_valid,
                    input          video_ready,
                    output reg [31:0]  PF_curFrame,
                    input  [31:0]  PF_nextFrame);


    // Hint: States
    localparam IDLE = 1'b0;
    localparam FETCH = 1'b1;
    reg  [31:0] ignore_count;
    reg  CS, NS;
    reg [9:0] x,y;
    reg  [13:0] pixelInFifoCount;
    
    //assign real_x = 10'd792 - x;

    assign af_addr_din = {6'd0,PF_curFrame[27:22],y,x[9:3],2'd0};
    assign af_wr_en = ((CS == FETCH) && (ignore_count == 0));
    assign rdf_rd_en = 1'd1;

    always @(*) begin
      case (CS)
        IDLE: NS = (pixelInFifoCount < 8000) ? FETCH : IDLE;
        FETCH: NS = (pixelInFifoCount < 8000) ? FETCH : IDLE;
        default: NS = IDLE;
      endcase
    end
  
    always @(posedge cpu_clk_g) begin
      if (rst) begin 
        CS <= IDLE; pixelInFifoCount <= 14'd0; 
        x <= 10'd0; y <= 10'd0; PF_curFrame <= 32'h10400000; 
      end else begin 
        CS <= NS;
        pixelInFifoCount <= pixelInFifoCount + ((af_wr_en && (!af_full)) ? 14'd8:14'd0) 
                                            - {13'd0,((video_ready) && (ignore_count == 0) && (pixelInFifoCount != 14'd0))};
        if(af_wr_en && (!af_full))begin
          if(x == 10'd792)begin 
            x <= 10'd0;           
            if (y == 10'd599)begin
              y <= 10'd0;
              PF_curFrame <= PF_nextFrame;
            end else begin y <= y + 10'd1; PF_curFrame <= PF_curFrame; end
          end else begin x <= x + 10'd8; y <= y; PF_curFrame <= PF_curFrame; end
        end else begin x <= x; y <= y; PF_curFrame <= PF_curFrame; end 
      end
    end 

    /* We drop the first frame to allow the buffer to fill with data from
    * DDR2. This gives alignment of the frame. */
    always @(posedge cpu_clk_g) begin
       if(rst)
            ignore_count <= 32'd480000; // 600*800 
       else if(ignore_count != 0 & video_ready)
            ignore_count <= ignore_count - 32'b1;
       else
            ignore_count <= ignore_count;
    end

    // FIFO to buffer the reads with a write width of 128 and read width of 32. We try to fetch blocks
    // until the FIFO is full.
    wire [31:0] feeder_dout;

    pixel_fifo feeder_fifo(
    	.rst(rst),
    	.wr_clk(cpu_clk_g),
    	.rd_clk(clk50_g),
    	.din(rdf_dout),
    	.wr_en(rdf_valid),
    	.rd_en(video_ready & ignore_count == 0),
    	.dout(feeder_dout),
    	.full(feeder_full),
    	.empty(feeder_empty));

    assign video = feeder_dout[23:0];
    assign video_valid = 1'b1;

endmodule

