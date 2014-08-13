module FrameFiller(//system:
 input             clk,
  input             rst,
  // fill control:
  input             valid,
  input [23:0]      color,
  // ddr2 fifo control:
  input             af_full,
  input             wdf_full,
  // ddr2 fifo outputs:
  output [127:0]    wdf_din,
  output            wdf_wr_en,
  output [30:0]     af_addr_din,
  output            af_wr_en,
  output [15:0]     wdf_mask_din,
  // handshaking:
  output            ready,
  //Frame_Select
  input [31:0] FF_frame_base
);				

	reg [1:0] cs, ns;
	reg [31:0] pixel_data;
	reg [9:0] x, y;
	reg [31:0] frameBase;
	
	localparam IDLE = 2'd0;
	localparam FILL1 = 2'd1;
	localparam FILL2 = 2'd2;

	always @( posedge clk ) begin
		if(rst) begin
		    cs <= IDLE;
			  x <= 10'd0;
			  y <= 10'd0;
		end
		else begin
	      cs <= ns;
			  if(valid)begin
			      pixel_data = { 8'd0, color };
            frameBase = FF_frame_base;
        end
			  if((cs == FILL2) && (ns == FILL1)) begin
				    if (x == 10'd792) begin
				        x <= 10'd0;
						    if (y == 10'd599)
					          y <= 10'd0;
						    else
							      y <= y + 10'd1;		
				    end
				    else 
				        x <= x + 10'd8;	
			  end 
			  if ((cs == FILL2 ) && (x == 10'd792 ) && ( y == 10'd599 )) begin
				    x <= 10'd0;
				    y <= 10'd0;
			  end					
		 end 
	 end 

	always @( * ) begin
		ns = cs;
		case ( cs )
			IDLE 		: ns = valid ? FILL1 : cs;							
			FILL1	:	if ( af_full || wdf_full ) 
									ns = FILL1;
							else if ( !af_full && !wdf_full )
									ns = FILL2;
			FILL2	:	if (( x >= 10'd792) && (y >= 10'd599 ))
									ns = IDLE;
								else if ( af_full || wdf_full )
									ns = FILL2;								
								else 
									ns = FILL1;
		endcase
	end 
	
	assign 	af_wr_en	= (cs == FILL1);
	assign 	wdf_din = {4{pixel_data}};
	assign 	wdf_wr_en	=	(cs == FILL1) || (cs == FILL2);
	assign	af_addr_din	=	{6'd0, frameBase[27:22], y, x[9:3], 2'b00 };
	assign 	wdf_mask_din = 16'd0;	
	assign 	ready = (cs == IDLE);	

endmodule

