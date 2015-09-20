//--------------------------------------------------------------------------------
//-- Filename: BAR1_WR_ARBITER.v
//--
//-- Description: BAR1 Write Arbiter Module
//--              
//--              The module designed to arbitrate different write port to BAR1.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module BAR1_WR_ARBITER (
						rst_n,
						init_rst_i,

						//write port 0
						wr_en0_i,
						addr0_i,
						wr_be0_i,
						wr_d0_i,
						
						//write port 1
						wr_en1_i,
						addr1_i,
						wr_be1_i,
						wr_d1_i,
						
						//write port 2
						wr_en2_i,
						addr2_i,
						wr_be2_i,
						wr_d2_i,
						
						//write port 3						
						wr_en3_i,
						addr3_i,
						wr_be3_i,
						wr_d3_i,

						//read port 0						
						rd_be0_i,
						rd_d0_o,

						//write port arbitration output						
						wr_en_o,
						addr_o,
						wr_be_o,
						wr_d_o,

						//write port feedback signals						
						ack0_n_o,
						ack1_n_o,
						ack2_n_o,
						ack3_n_o,
						
						rd_be_o,
						rd_d_i,
						busy_o
						);

	input				rst_n;
	input				init_rst_i;
						
	input				wr_en0_i;
	input [6:0]			addr0_i;
	input [3:0]			wr_be0_i;
	input [31:0]		wr_d0_i;
	
	input				wr_en1_i;
	input [6:0]			addr1_i;
	input [3:0]			wr_be1_i;
	input [31:0]		wr_d1_i;

	input				wr_en2_i;
	input [6:0]			addr2_i;
	input [3:0]			wr_be2_i;
	input [31:0]		wr_d2_i;

	input				wr_en3_i;
	input [6:0]			addr3_i;
	input [3:0]			wr_be3_i;
	input [31:0]		wr_d3_i;

	input [3:0]			rd_be0_i;
	output [31:0]		rd_d0_o;
	
	output				wr_en_o;
	output [6:0]		addr_o;
	output [3:0]		wr_be_o;
	output [31:0]		wr_d_o;
	
	output				ack0_n_o;
	output				ack1_n_o;
	output				ack2_n_o;
	output				ack3_n_o;
	
	output [3:0]		rd_be_o;
	input [31:0]		rd_d_i;
	
	output				busy_o;
	
	reg [31:0]			rd_d0_o;

	reg					wr_en_o;
	reg [6:0]			addr_o;
	reg [3:0]			wr_be_o;
	reg [31:0]			wr_d_o;
	
	reg					ack0_n_o;
	reg					ack1_n_o;
	reg					ack2_n_o;
	reg					ack3_n_o;

	reg [3:0]			rd_be_o;
	


	assign 				busy_o = wr_en0_i | wr_en1_i | wr_en2_i | wr_en3_i;
	
	//write port arbitration
	always @( * ) begin
	
		if( !rst_n | init_rst_i ) begin
		
			wr_en_o = 1'b0;
			addr_o = 7'b0;
			wr_be_o = 4'b0;
			wr_d_o = 32'b0;
			
			ack0_n_o = 1'b1;
			ack1_n_o = 1'b1;
			ack2_n_o = 1'b1;
			ack3_n_o = 1'b1;
			
		end
		else begin
		
			//write priority: port0 > port1 > port2 > port3
				
			if( wr_en0_i ) begin
				
				wr_en_o = wr_en0_i;
				addr_o = addr0_i;
				wr_be_o = wr_be0_i;
				wr_d_o = wr_d0_i;
				
				ack0_n_o = 1'b0;
				ack1_n_o = 1'b1;
				ack2_n_o = 1'b1;
				ack3_n_o = 1'b1;	
				
			end
			else if( wr_en1_i ) begin
				
				wr_en_o = wr_en1_i;
				addr_o = addr1_i;
				wr_be_o = wr_be1_i;
				wr_d_o = wr_d1_i;
				
				ack0_n_o = 1'b1;
				ack1_n_o = 1'b0;
				ack2_n_o = 1'b1;
				ack3_n_o = 1'b1;	
								
			end
			else if ( wr_en2_i ) begin
				
				wr_en_o = wr_en2_i;
				addr_o = addr2_i;
				wr_be_o = wr_be2_i;
				wr_d_o = wr_d2_i;
				
				ack0_n_o = 1'b1;
				ack1_n_o = 1'b1;
				ack2_n_o = 1'b0;
				ack3_n_o = 1'b1;	
								
			end
			else if ( wr_en3_i ) begin
				
				wr_en_o = wr_en3_i;
				addr_o = addr3_i;
				wr_be_o = wr_be3_i;
				wr_d_o = wr_d3_i;
				
				ack0_n_o = 1'b1;
				ack1_n_o = 1'b1;
				ack2_n_o = 1'b1;
				ack3_n_o = 1'b0;	
								
			end
			else begin
			
				wr_en_o = 1'b0;
				addr_o = 7'b0;
				wr_be_o = 4'b0;
				wr_d_o = 32'b0;
				
				ack0_n_o = 1'b1;
				ack1_n_o = 1'b1;
				ack2_n_o = 1'b1;
				ack3_n_o = 1'b1;	
				
			end //if( wr_en0_i )
				
		end //if( !rst_n | !en )
	end
	
	//read port control
	always @( * ) begin
	
		if( !rst_n | init_rst_i ) begin
		
			rd_be_o = 4'b0;			
			rd_d0_o = 32'b0;
		
		end else begin
		
			if( !wr_en1_i & !wr_en2_i & !wr_en3_i ) begin
				
				rd_be_o = rd_be0_i;			
				rd_d0_o = rd_d_i;
				
			end 
			else begin
			
				rd_be_o = 4'b0;
				rd_d0_o = 32'b0;
			
			end //if( wr_en1_i & wr_en2_i & wr_en3_i )
		
		end //if( !rst_n | !en )
	
	end
	
endmodule