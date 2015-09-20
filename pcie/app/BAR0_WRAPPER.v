//--------------------------------------------------------------------------------
//-- Filename: BAR0_WRAPPER.v
//--
//-- Description: BAR0 WRAPPER Module
//--              
//--              The module is a simple warpper to BAR0 module. it provides write
//-- control and byte enable access on BAR0.
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module BAR0_WRAPPER(
						clk,
						rst_n,
						en,
						
						//read and write port
						a_i,
						wr_en_i,
						wr_be_i,
						wr_busy_o,
						rd_d_o,
						rd_be_i,
						wr_d_i,
						
						//BAR1 Write Arbiter write port 1
						bar1_wr_en1_o,
						bar1_addr1_o,
						bar1_wr_be1_o,
						bar1_wr_d1_o,
						bar1_wr_ack1_n_i,
						bar1_arbiter_busy_i,
						
						bar1_wr_busy_i,
						
						//response message read port
						resp_i,
						resp_empty_i,
						resp_rd_en_o,
						req_compl_i,
						
						mrd_start_i,
						mrd_done_i,
						
						compl_done_i,
						
						dma_rd_req_flag_o,
						
						req_queue_av_i,
						req_queue_depth_o,
						
						int_cnt_i,
						req_cnt_i,
						
						//error report
						cpld_malformed_i,
						fatal_err_i,
						req_unsupported_i,
						lba_ofr_err_i,
						prp_offset_err_i,
						id_ob_err_i,
						
						cont_rdy_o,
						
						//INT ctrl
						int_en_o,
						int_rd_msk_o,
						int_wr_msk_o,
						
						//DMA READ QUEUE
						dma_rd_q_wr_en_o,
						dma_rd_q_wr_data_o,
						dma_rd_q_full_i,
						/*************ouyang***************/
            //msix interface
            msg_lower_addr_o,
            msg_upper_addr_o,
            msg_data_o,
            // the base addr for response queue
            response_queue_addr_o,
            //count enable for response queue offset
            response_queue_addr_offset_cnt_en_i,
            interrupt_block_o,
            response_queue_cur_offset_reg_o,
            response_queue_addr_offset_o,
            response_queue_num_i
            /**********************************/						
    );
	
	parameter			BAR0_WR_RST = 4'b0001;
	parameter			BAR0_WR_WAIT = 4'b0010;
	parameter			BAR0_WR_READ = 4'b0100;
	parameter			BAR0_WR_WRITE = 4'b1000;
	
	/*************ouyang***************/
	input [5:0] response_queue_num_i;
	//msix interface
	output [31:0] msg_lower_addr_o;
  output [31:0] msg_upper_addr_o;
  output [31:0] msg_data_o;
  // the base addr for response queue
	output [31:0] response_queue_addr_o;
	//count enable for response queue offset
  input response_queue_addr_offset_cnt_en_i;	
  output interrupt_block_o;	
  output [31:0] response_queue_cur_offset_reg_o;
	output [10:0] response_queue_addr_offset_o;
	/*********************************/

	input				clk , rst_n;
	output				en;
	
	
	// read port
	//
	input [6:0]			a_i;
	input [3:0]			rd_be_i;
	output [31:0]		rd_d_o;
	
	// write port
	//
	input				wr_en_i;
	input [7:0]			wr_be_i;
	input [31:0]		wr_d_i;
	output				wr_busy_o;
	
	output				bar1_wr_en1_o;
	output [6:0]		bar1_addr1_o;
	output [3:0]		bar1_wr_be1_o;
	output [31:0]		bar1_wr_d1_o;
	input				bar1_wr_ack1_n_i;
	input				bar1_arbiter_busy_i;
	
	input				bar1_wr_busy_i;
	
	input [31:0]		resp_i;
	input				resp_empty_i;
	output				resp_rd_en_o;
	input					req_compl_i;
	
	input				mrd_start_i;
	input				mrd_done_i;
	
	input				compl_done_i;
	
	output				dma_rd_req_flag_o;
	input [9:0]			req_queue_av_i;
	output [15:0]		req_queue_depth_o;
	
	input [31:0]		int_cnt_i;
	input [31:0]		req_cnt_i;
	
	input				cpld_malformed_i;
	input				fatal_err_i;
	input				req_unsupported_i;
	input				lba_ofr_err_i;
	input				prp_offset_err_i;
	input				id_ob_err_i;
	
	output				cont_rdy_o;
	
	output				int_en_o;
	output				int_rd_msk_o;
	output				int_wr_msk_o;
	
	wire [31:0]			bar0_rd_data;
	
	reg [6:0]			addr_q;
	reg [3:0]			wr_be_q;
	reg [31:0]			wr_d_q;
	
	reg					wr_busy_o;
	
	output				dma_rd_q_wr_en_o;
	output [63:0]		dma_rd_q_wr_data_o;
	input				dma_rd_q_full_i;	
	
	reg					bar0_wr_en;
	reg [31:0]			pre_wr_data;
	reg [31:0]			bar0_wr_data;
	
	reg [3:0]			bar0_wr_state;
	
	// BAR0 write control state machine
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n ) begin
		
			bar0_wr_en <= 1'b0;
			wr_busy_o <= 1'b0;
			
			addr_q <= 7'b0;
			wr_be_q <= 4'b0;
			wr_d_q <= 32'b0;
			
			pre_wr_data <= 32'b0;
			bar0_wr_data <= 32'b0;
		
			bar0_wr_state <= BAR0_WR_RST;
		
		end
		else begin
		
			case ( bar0_wr_state )
			
				BAR0_WR_RST: begin
				
					bar0_wr_en <= 1'b0;
					wr_busy_o <= 1'b0;
				
					addr_q <= a_i;
					
					if( wr_en_i ) begin					

						wr_be_q <= wr_be_i[3:0];
						wr_d_q <= wr_d_i;
						
						wr_busy_o <= 1'b1;
						
						bar0_wr_state <= BAR0_WR_WAIT;
					
					end
				
				end
				
				BAR0_WR_WAIT: begin
				
					bar0_wr_state <= BAR0_WR_READ;
				
				end
				
				BAR0_WR_READ: begin
				
					pre_wr_data <= bar0_rd_data;
					
					bar0_wr_state <= BAR0_WR_WRITE;
				
				end
				
				BAR0_WR_WRITE: begin
				
					bar0_wr_en <= 1'b1;
					bar0_wr_data <= { { wr_be_q[3] ? wr_d_q[31:24] : pre_wr_data[31:24] } ,
									  { wr_be_q[2] ? wr_d_q[23:16] : pre_wr_data[23:16] } ,
									  { wr_be_q[1] ? wr_d_q[15:8] : pre_wr_data[15:8] } ,
									  { wr_be_q[0] ? wr_d_q[7:0] : pre_wr_data[7:0] }
									};
					wr_busy_o <= 1'b0;
					
					bar0_wr_state <= BAR0_WR_RST;
				
				end
				
				default: bar0_wr_state <= BAR0_WR_RST;
			
			endcase
		
		end
	
	end
	
    /*
     *  BAR0 Read Controller
     */

    /* Handle Read byte enables */

    assign rd_d_o = {{rd_be_i[0] ? bar0_rd_data[07:00] : 8'h0},
                     {rd_be_i[1] ? bar0_rd_data[15:08] : 8'h0}, 
                     {rd_be_i[2] ? bar0_rd_data[23:16] : 8'h0}, 
                     {rd_be_i[3] ? bar0_rd_data[31:24] : 8'h0}};	
	
	BAR0 bar0 (

						.clk(clk),
						.rst_n(rst_n),
						.en(en),
						
						//read and write port
						.a_i(addr_q),
						.wr_en_i(bar0_wr_en),
						.rd_d_o(bar0_rd_data),
						.wr_d_i(bar0_wr_data),
						
						//BAR1 Write Arbiter write port 1
						.bar1_wr_en1_o(bar1_wr_en1_o),
						.bar1_addr1_o(bar1_addr1_o),
						.bar1_wr_be1_o(bar1_wr_be1_o),
						.bar1_wr_d1_o(bar1_wr_d1_o),
						.bar1_wr_ack1_n_i(bar1_wr_ack1_n_i),
						.bar1_arbiter_busy_i(bar1_arbiter_busy_i),
						
						.bar1_wr_busy_i(bar1_wr_busy_i),
						
						//response message read port
						.resp_i(resp_i),
						.resp_empty_i(resp_empty_i),
						.resp_rd_en_o(resp_rd_en_o),
						.req_compl_i(req_compl_i),
						
						.mrd_start_i(mrd_start_i),
						.mrd_done_i(mrd_done_i),
						
						.compl_done_i(compl_done_i),
						
						.dma_rd_req_flag_o(dma_rd_req_flag_o),
						
						.req_queue_av_i(req_queue_av_i),
						.req_queue_depth_o(req_queue_depth_o),
						
						.int_cnt_i(int_cnt_i),
						.req_cnt_i(req_cnt_i),
						
						//error report
						.cpld_malformed_i(cpld_malformed_i),
						.fatal_err_i(fatal_err_i),
						.req_unsupported_i(req_unsupported_i),
						.lba_ofr_err_i(lba_ofr_err_i),
						.prp_offset_err_i(prp_offset_err_i),
						.id_ob_err_i(id_ob_err_i),
						
						.cont_rdy_o(cont_rdy_o),
						
						//INT ctrl
						.int_en_o(int_en_o),
						.int_rd_msk_o(int_rd_msk_o),
						.int_wr_msk_o(int_wr_msk_o),

						.dma_rd_q_wr_en_o(dma_rd_q_wr_en_o),
						.dma_rd_q_wr_data_o(dma_rd_q_wr_data_o),
						.dma_rd_q_full_i(dma_rd_q_full_i),
						
						/*************ouyang***************/
            //msix interface
            .msg_lower_addr_o(msg_lower_addr_o),
            .msg_upper_addr_o(msg_upper_addr_o),
            .msg_data_o(msg_data_o),
            // the base addr for response queue
            .response_queue_addr_o(response_queue_addr_o),
            //count enable for response queue offset
            .response_queue_addr_offset_cnt_en_i(response_queue_addr_offset_cnt_en_i),
            .interrupt_block_o(interrupt_block_o),
            .response_queue_cur_offset_reg_o(response_queue_cur_offset_reg_o),
            .response_queue_addr_offset_o(response_queue_addr_offset_o),
            .response_queue_num_i(response_queue_num_i)
            /**********************************/
	);
endmodule
