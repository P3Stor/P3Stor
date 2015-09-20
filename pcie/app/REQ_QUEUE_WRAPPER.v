//--------------------------------------------------------------------------------
//-- Filename: REQ_QUEUE_WRAPPER.v
//--
//-- Description: REQUEST QUEUE WRAPPER Module
//--              
//--              The module receives requests from HOST and distinguish read req-
//-- uests from write requests then sends them to corresponded request fifo. Thro-
//-- ugh this module we can fully use the duplex feature of PCIe LINK.
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module REQ_QUEUE_WRAPPER(

						clk,
						rst_n,
						en,
						
						//receive request queue
						rdata_i,
						rdata_wr_en_i,
						req_queue_av_o,
						req_queue_full_o,
						
						//rd request queue
						rd_req_empty_o,
						rd_req_rd_en_i,
						rd_req_data_o,
						
						//wr request queue
						wr_req_empty_o,
						wr_req_rd_en_i,
						wr_req_data_o,
						
						req_cnt_o,
						req_unsupported_o

    );
	
	parameter			REQ_QUEUE_DEPTH = 64;
	parameter			RD_REQ_QUEUE_DEPTH = 64;
	parameter			WR_REQ_QUEUE_DEPTH = 64;
	
	parameter			RD_REQUEST = 8'h01;
	parameter			WR_REQUEST = 8'h02;
	
	parameter			QUEUE_WRAPPER_RST = 2'b01;
	parameter			QUEUE_WRAPPER_REQ_XFER = 2'b10;
	
	input				clk , rst_n;
	input				en;
	
	input [127:0]		rdata_i;
	input				rdata_wr_en_i;
	output [9:0]		req_queue_av_o;
	output				req_queue_full_o;

	output				rd_req_empty_o;
	input				rd_req_rd_en_i;
	output [127:0]		rd_req_data_o;
	
	output				wr_req_empty_o;
	input				wr_req_rd_en_i;
	output [127:0]		wr_req_data_o;
	
	output [31:0]		req_cnt_o;
	output				req_unsupported_o;
	
	reg [31:0]			req_cnt_o;
	reg					req_unsupported_o;
	
	wire				srst = !rst_n | !en;
	
	wire [9:0]			req_queue_data_count;
	wire [6:0]			req_queue_req_count;
	wire [127:0]		req_queue_data;

	reg					req_queue_rd_en;
	
	wire [9:0]			rd_req_queue_data_count , wr_req_queue_data_count;
	wire [6:0]			rd_req_queue_req_count , wr_req_queue_req_count;	
	wire [9:0]			rd_req_queue_av , wr_req_queue_av;
	reg					rd_req_queue_wr_en , wr_req_queue_wr_en;
	
	reg [3:0]			xfer_cnt;
	
	reg [1:0]			queue_wrapper_state;
	
	assign				req_queue_req_count = req_queue_data_count >> 3;
	assign				req_queue_av_o = REQ_QUEUE_DEPTH - req_queue_req_count;
	
	assign				rd_req_queue_req_count = rd_req_queue_data_count >> 3;
	assign				wr_req_queue_req_count = wr_req_queue_data_count >> 3;
	assign				rd_req_queue_av = RD_REQ_QUEUE_DEPTH - rd_req_queue_req_count;
	assign				wr_req_queue_av = WR_REQ_QUEUE_DEPTH - wr_req_queue_req_count;
	
	assign				rd_req_empty_o = ( rd_req_queue_req_count == 0 ) ? 1'b1 : 1'b0;
	assign				wr_req_empty_o = ( wr_req_queue_req_count == 0 ) ? 1'b1 : 1'b0;
	
	
	// request queue fifo
	// DEPTH: 512
	// WIDTH: 128
	// REQUEST DEPTH: 64
	RECV_REQ_QUEUE REQ_QUEUE (
					  .clk( clk ), // input clk
					  .srst( srst ), // input srst
					  .din( rdata_i ), // input [127 : 0] din
					  .wr_en( rdata_wr_en_i ), // input wr_en
					  .rd_en( req_queue_rd_en ), // input rd_en
					  .dout( req_queue_data ), // output [127 : 0] dout
					  .full( req_queue_full_o ), // output full
					  .empty( ), // output empty
					  .data_count( req_queue_data_count ) // output [9 : 0] data_count
		);
		
	// read request queue fifo
	// DEPTH: 512
	// WIDTH: 128
	// REQUEST DEPTH: 64		
	RECV_REQ_QUEUE RD_REQ_QUEUE (
					  .clk( clk ), // input clk
					  .srst( srst ), // input srst
					  .din( req_queue_data ), // input [127 : 0] din
					  .wr_en( rd_req_queue_wr_en ), // input wr_en
					  .rd_en( rd_req_rd_en_i ), // input rd_en
					  .dout( rd_req_data_o ), // output [127 : 0] dout
					  .full(  ), // output full
					  .empty(  ), // output empty
					  .data_count( rd_req_queue_data_count ) // output [9 : 0] data_count	
		);
	
	// write request queue fifo
	// DEPTH: 512
	// WIDTH: 128
	// REQUEST DEPTH: 64
	RECV_REQ_QUEUE WR_REQ_QUEUE (
					  .clk( clk ), // input clk
					  .srst( srst ), // input srst
					  .din( req_queue_data ), // input [127 : 0] din
					  .wr_en( wr_req_queue_wr_en ), // input wr_en
					  .rd_en( wr_req_rd_en_i ), // input rd_en
					  .dout( wr_req_data_o ), // output [127 : 0] dout
					  .full(  ), // output full
					  .empty(  ), // output empty
					  .data_count( wr_req_queue_data_count ) // output [9 : 0] data_count	
		);		
	
	// this state machine gets requests from request fifo and checks requests 
	// then sends requests to read request fifo or write request fifo.
	// NOTICE: Each request is 128 bytes = 8 * 128 bits.
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n || !en ) begin
		
			req_queue_rd_en <= 1'b0;
			
			rd_req_queue_wr_en <= 1'b0;
			wr_req_queue_wr_en <= 1'b0;
			
			xfer_cnt <= 4'b0;
			req_cnt_o <= 32'b0;
			
			req_unsupported_o <= 1'b0;
			
			queue_wrapper_state <= QUEUE_WRAPPER_RST;
		
		end
		else begin
		
			case ( queue_wrapper_state )
			
				QUEUE_WRAPPER_RST: begin
				
					if( req_queue_req_count != 0 ) begin
					
						case ( req_queue_data[103:96] )
						
							RD_REQUEST: begin
							
								if( rd_req_queue_av != 0 ) begin
								
									req_queue_rd_en <= 1'b1;
									rd_req_queue_wr_en <= 1'b1;
									
									xfer_cnt <= 4'b1;
									req_cnt_o <= req_cnt_o + 1'b1;
									
									queue_wrapper_state <= QUEUE_WRAPPER_REQ_XFER;
								
								end
							
							end
							WR_REQUEST: begin
							
								if( wr_req_queue_av != 0 ) begin
								
									req_queue_rd_en <= 1'b1;
									wr_req_queue_wr_en <= 1'b1;
									
									xfer_cnt <= 4'b1;
									req_cnt_o <= req_cnt_o + 1'b1;
									
									queue_wrapper_state <= QUEUE_WRAPPER_REQ_XFER;
								
								end							
							
							end
							default: begin
							
								req_queue_rd_en <= 1'b1;
								
								xfer_cnt <= 4'b1;
								req_cnt_o <= req_cnt_o + 1'b1;
								
								req_unsupported_o <= 1'b1;
									
								queue_wrapper_state <= QUEUE_WRAPPER_REQ_XFER;
							
							end
						
						endcase						
					
					end // if( req_queue_req_count != 0 )
				
				end
				
				QUEUE_WRAPPER_REQ_XFER: begin
				
					if( xfer_cnt < 8 ) begin
					
						xfer_cnt <= xfer_cnt + 1'b1;
						queue_wrapper_state <= QUEUE_WRAPPER_REQ_XFER;
					
					end
					else begin
					
						req_queue_rd_en <= 1'b0;
						wr_req_queue_wr_en <= 1'b0;
						rd_req_queue_wr_en <= 1'b0;
						
						queue_wrapper_state <= QUEUE_WRAPPER_RST;
					
					end
				
				end
				
				default: begin
				
					queue_wrapper_state <= QUEUE_WRAPPER_RST;
				
				end
			
			endcase
		
		end //if( !rst_n || !en )
	
	end
	
	
endmodule
