//--------------------------------------------------------------------------------
//-- Filename: BAR0.v
//--
//-- Description: BAR0 Module
//--              
//--              The module is a interface between HOST and HARWARE . The HOST 
//-- controls the HARDWARE through writing and read the registers in this module.
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`include "CM_HEAD.v"

module BAR0(

						clk,
						rst_n,
						en,
						
						//read and write port
						a_i,
						wr_en_i,
						rd_d_o,
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
                    
	parameter			CONTROLLER_CONFIG = 7'b000_0010;
	//parameter			REQUEST_QUEUE_DOORBELL = 7'b000_0110;
	//parameter			REQUEST_QUEUE_BASE_ADDR = 7'b000_0111;
	parameter			REQUEST_RESPONSE = 7'b000_1000;
	parameter			DEVICE_STATUS = 7'b000_1001;
	parameter			REQUEST_QUEUE_DEPTH = 7'b000_1010;
	parameter			INTERRUPT_COUNT = 7'b000_1110;
	parameter			REQUEST_COUNT = 7'b000_1111;
	parameter			RESPONSE_COUNT = 7'b001_0000;
	
	parameter			BAR0_DMA_RST = 9'b0_0000_0001;
	parameter			BAR0_DMA_CONFIG1 = 9'b0_0000_0010;
	parameter			BAR0_DMA_CONFIG2 = 9'b0_0000_0100;
	parameter			BAR0_DMA_CONFIG3 = 9'b0_0000_1000;
	parameter			BAR0_DMA_CONFIG4 = 9'b0_0001_0000;
	parameter			BAR0_DMA_START = 9'b0_0010_0000;
	parameter			BAR0_DMA_WAIT = 9'b0_0100_0000;
	parameter			BAR0_DMA_CLEAR = 9'b0_1000_0000;
	parameter			BAR0_DMA_CLEAR_ACK = 9'b1_0000_0000;
	
	
	

	parameter			REQ_QUEUE_DEPTH = 64;
	
	/*************ouyang***************/
	input [5:0] response_queue_num_i;
	//msix interface
	output [31:0] msg_lower_addr_o;reg [31:0] msg_lower_addr_o;
  output [31:0] msg_upper_addr_o;reg [31:0] msg_upper_addr_o;
  output [31:0] msg_data_o;reg [31:0] msg_data_o;
  
  //entry 0
  reg [31:0] msg_lower_addr_1;
  reg [31:0] msg_upper_addr_1;
  reg [31:0] msg_data_1;
  //entry 1
  reg [31:0] msg_lower_addr_2;
  reg [31:0] msg_upper_addr_2;
  reg [31:0] msg_data_2;
  //entry 2
  reg [31:0] msg_lower_addr_3;
  reg [31:0] msg_upper_addr_3;
  reg [31:0] msg_data_3;
  //entry 3
  reg [31:0] msg_lower_addr_4;
  reg [31:0] msg_upper_addr_4;
  reg [31:0] msg_data_4;
  //entry 4
  reg [31:0] msg_lower_addr_5;
  reg [31:0] msg_upper_addr_5;
  reg [31:0] msg_data_5;
  //entry 5
  reg [31:0] msg_lower_addr_6;
  reg [31:0] msg_upper_addr_6;
  reg [31:0] msg_data_6;
  //entry 6
  reg [31:0] msg_lower_addr_7;
  reg [31:0] msg_upper_addr_7;
  reg [31:0] msg_data_7;
  //entry 7
  reg [31:0] msg_lower_addr_8;
  reg [31:0] msg_upper_addr_8;
  reg [31:0] msg_data_8;
  
  // the base addr for response queue
  reg [31:0] response_queue_base_addr_1; 
  reg [31:0] response_queue_base_addr_2;
  reg [31:0] response_queue_base_addr_3;
  reg [31:0] response_queue_base_addr_4;
  reg [31:0] response_queue_base_addr_5;
  reg [31:0] response_queue_base_addr_6;
  reg [31:0] response_queue_base_addr_7;
  reg [31:0] response_queue_base_addr_8;
  
  reg [9:0] response_queue_host_addr_offset_1;
  reg [9:0] response_queue_host_addr_offset_2;
  reg [9:0] response_queue_host_addr_offset_3;
  reg [9:0] response_queue_host_addr_offset_4;
  reg [9:0] response_queue_host_addr_offset_5;
  reg [9:0] response_queue_host_addr_offset_6;
  reg [9:0] response_queue_host_addr_offset_7;
  reg [9:0] response_queue_host_addr_offset_8;  
  
  reg [31:0] response_queue_addr_1;
  reg [31:0] response_queue_addr_2;
  reg [31:0] response_queue_addr_3;
  reg [31:0] response_queue_addr_4;
  reg [31:0] response_queue_addr_5;
  reg [31:0] response_queue_addr_6;
  reg [31:0] response_queue_addr_7;
  reg [31:0] response_queue_addr_8;
  
  reg [10:0] response_queue_addr_offset_1;
  reg [10:0] response_queue_addr_offset_2;
  reg [10:0] response_queue_addr_offset_3;
  reg [10:0] response_queue_addr_offset_4;
  reg [10:0] response_queue_addr_offset_5;
  reg [10:0] response_queue_addr_offset_6;  
  reg [10:0] response_queue_addr_offset_7;
  reg [10:0] response_queue_addr_offset_8;
  
  reg [31:0] response_queue_addr;
	reg [10:0] response_queue_addr_offset;
	reg [31:0] response_queue_base_addr;
	reg [9:0] response_queue_host_addr_offset;
	reg [31:0] msg_lower_addr;
  reg [31:0] msg_upper_addr;
  reg [31:0] msg_data      ;
  
  
	output [31:0] response_queue_addr_o;reg [31:0] response_queue_addr_o;
	output [31:0] response_queue_cur_offset_reg_o;reg [31:0] response_queue_cur_offset_reg_o;
	
	output [10:0] response_queue_addr_offset_o;reg [10:0] response_queue_addr_offset_o;
	//count enable for response queue offset
  input response_queue_addr_offset_cnt_en_i; 		
  wire [10:0] response_queue_addr_delta;
  output interrupt_block_o;reg interrupt_block_o;
  
  reg [31:0] cancel;
	/*********************************/
	
	input				clk , rst_n;
	output				en;
	
	input [6:0]			a_i;
	input				wr_en_i;
	output [31:0]		rd_d_o;
	input [31:0]		wr_d_i;
	
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
	input				req_compl_i;
	
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
	
	output				dma_rd_q_wr_en_o;
	output [63:0]		dma_rd_q_wr_data_o;
	input				dma_rd_q_full_i;
	
	reg					en;
	reg [31:0]			rd_d_o;
	
	reg					bar1_wr_en1_o;
	reg [6:0]			bar1_addr1_o;
	reg [3:0]			bar1_wr_be1_o;
	reg [31:0]			bar1_wr_d1_o;
	
	reg					resp_rd_en_o;
	//reg					response_on;
	
	reg					dma_rd_req_flag_o;
	
	reg					cont_rdy_o;
	
	reg					int_en_o;
	reg					int_rd_msk_o;
	reg					int_wr_msk_o;
	
	/**************************ouyang******************/
	reg [15:0] req_queue_doorbell   , req_queue_doorbell_pre;
	reg [15:0] req_queue_doorbell_1 , req_queue_doorbell_pre_1;
	reg [15:0] req_queue_doorbell_2 , req_queue_doorbell_pre_2;
	reg [15:0] req_queue_doorbell_3 , req_queue_doorbell_pre_3;
	reg [15:0] req_queue_doorbell_4 , req_queue_doorbell_pre_4;
	reg [15:0] req_queue_doorbell_5 , req_queue_doorbell_pre_5;
	reg [15:0] req_queue_doorbell_6 , req_queue_doorbell_pre_6;
	reg [15:0] req_queue_doorbell_7 , req_queue_doorbell_pre_7;
	reg [15:0] req_queue_doorbell_8 , req_queue_doorbell_pre_8;
	wire [16:0]			doorbell_delta;
	reg [31:0] req_queue_base_addr_1;
	reg [31:0] req_queue_base_addr_2;
	reg [31:0] req_queue_base_addr_3;
	reg [31:0] req_queue_base_addr_4;
	reg [31:0] req_queue_base_addr_5;
	reg [31:0] req_queue_base_addr_6;
	reg [31:0] req_queue_base_addr_7;
	reg [31:0] req_queue_base_addr_8;
	/**************************************************/
	
	
	reg [31:0]			req_queue_base_addr;
	//reg [31:0]			response;
	reg [31:0]			resp_cnt;
	reg					compl_done_q;
	reg					req_compl_q;
	reg					resp_empty_q;
	
	reg [15:0]			req_queue_depth_o;
	
	
	
	wire [9:0]			req_queue_av;
	wire [9:0]			req_queue_pending;
	wire					req_queue_av_fg;
	
	reg [15:0]			req_cnt;
	
	reg					dma_rd_q_wr_en_o;
	reg [63:0]			dma_rd_q_wr_data_o;
	
	reg [8:0]			bar0_state;
	
	/*************ouyang***************/
	assign        response_queue_addr_delta = response_queue_addr_offset - response_queue_host_addr_offset;
	/*********************************/
	assign				doorbell_delta = { 1'b0 , req_queue_doorbell } - req_queue_doorbell_pre;
	assign				req_queue_pending = req_cnt_i - resp_cnt;
	assign				req_queue_av_fg = ( req_queue_pending >= REQ_QUEUE_DEPTH ) ? 1'b0 : 1'b1;
	assign				req_queue_av = REQ_QUEUE_DEPTH - req_queue_pending;
	
	
	
	/*************ouyang***************/
	reg [2:0] doorbell_num_sel, cur_doorbell_num;
	reg [15:0] cur_req_queue_doorbell_pre;
	reg [31:0] cur_req_queue_base_addr;
	
	reg			flag;
	reg [16:0]	doorbell_delta_q;
	
	always @ (posedge clk) begin
	
		if( !rst_n || !en ) begin
			doorbell_num_sel <= 0;
			flag <= 1'b0;
			doorbell_delta_q <= 0;
		end
		else begin		
		
			doorbell_delta_q <= 0;
			
			if(flag) begin
				flag <= 1'b0;
				doorbell_num_sel <= doorbell_num_sel + 1;
			end else begin
				flag <= 1'b1;
				doorbell_delta_q <= doorbell_delta;	
			end
			
			//doorbell_delta_q <= doorbell_delta;				

		end
	end
	
	
	always @ ( * ) begin
		case(doorbell_num_sel)
			
			'b000: begin
				req_queue_base_addr = req_queue_base_addr_1;
				req_queue_doorbell = req_queue_doorbell_1;
				req_queue_doorbell_pre = req_queue_doorbell_pre_1;
			end
			
			'b001: begin
				req_queue_base_addr = req_queue_base_addr_2;
				req_queue_doorbell = req_queue_doorbell_2;
				req_queue_doorbell_pre = req_queue_doorbell_pre_2;
			end
			
			'b010: begin
				req_queue_base_addr = req_queue_base_addr_3;
				req_queue_doorbell = req_queue_doorbell_3;
				req_queue_doorbell_pre = req_queue_doorbell_pre_3;
			end
			
			'b011: begin
				req_queue_base_addr = req_queue_base_addr_4;
				req_queue_doorbell = req_queue_doorbell_4;
				req_queue_doorbell_pre = req_queue_doorbell_pre_4;
			end
			
			'b100: begin
				req_queue_base_addr = req_queue_base_addr_5;
				req_queue_doorbell = req_queue_doorbell_5;
				req_queue_doorbell_pre = req_queue_doorbell_pre_5;
			end
			
			'b101: begin
				req_queue_base_addr = req_queue_base_addr_6;
				req_queue_doorbell = req_queue_doorbell_6;
				req_queue_doorbell_pre = req_queue_doorbell_pre_6;
			end
			
			'b110: begin
				req_queue_base_addr = req_queue_base_addr_7;
				req_queue_doorbell = req_queue_doorbell_7;
				req_queue_doorbell_pre = req_queue_doorbell_pre_7;
			end
			
			'b111: begin
				req_queue_base_addr = req_queue_base_addr_8;
				req_queue_doorbell = req_queue_doorbell_8;
				req_queue_doorbell_pre = req_queue_doorbell_pre_8;
			end
			
		endcase
	end
	
	
	always @ ( * ) begin
		case(response_queue_num_i[2:0])
			
			'h0: begin
				response_queue_addr = response_queue_addr_1;
				response_queue_addr_offset = response_queue_addr_offset_1;
				response_queue_base_addr = response_queue_base_addr_1;
				response_queue_host_addr_offset = response_queue_host_addr_offset_1;
				msg_lower_addr = msg_lower_addr_1;
  			msg_upper_addr = msg_upper_addr_1;
  			msg_data       = msg_data_1;
			end
			
			'h1: begin
				response_queue_addr = response_queue_addr_2;
				response_queue_addr_offset = response_queue_addr_offset_2;
				response_queue_base_addr = response_queue_base_addr_2;
				response_queue_host_addr_offset = response_queue_host_addr_offset_2;
				msg_lower_addr = msg_lower_addr_2;
  			msg_upper_addr = msg_upper_addr_2;
  			msg_data       = msg_data_2;
			end
			
			'h2: begin
				response_queue_addr = response_queue_addr_3;
				response_queue_addr_offset = response_queue_addr_offset_3;
				response_queue_base_addr = response_queue_base_addr_3;
				response_queue_host_addr_offset = response_queue_host_addr_offset_3;
				msg_lower_addr = msg_lower_addr_3;
  			msg_upper_addr = msg_upper_addr_3;
  			msg_data       = msg_data_3;
			end
			
			'h3: begin
				response_queue_addr = response_queue_addr_4;
				response_queue_addr_offset = response_queue_addr_offset_4;
				response_queue_base_addr = response_queue_base_addr_4;
				response_queue_host_addr_offset = response_queue_host_addr_offset_4;
				msg_lower_addr = msg_lower_addr_4;
  			msg_upper_addr = msg_upper_addr_4;
  			msg_data       = msg_data_4;
			end
			
			'h4: begin
				response_queue_addr = response_queue_addr_5;
				response_queue_addr_offset = response_queue_addr_offset_5;
				response_queue_base_addr = response_queue_base_addr_5;
				response_queue_host_addr_offset = response_queue_host_addr_offset_5;
				msg_lower_addr = msg_lower_addr_5;
  			msg_upper_addr = msg_upper_addr_5;
  			msg_data       = msg_data_5;
			end
			
			'h5: begin
				response_queue_addr = response_queue_addr_6;
				response_queue_addr_offset = response_queue_addr_offset_6;
				response_queue_base_addr = response_queue_base_addr_6;
				response_queue_host_addr_offset = response_queue_host_addr_offset_6;
				msg_lower_addr = msg_lower_addr_6;
  			msg_upper_addr = msg_upper_addr_6;
  			msg_data       = msg_data_6;
			end
			
			'h6: begin
				response_queue_addr = response_queue_addr_7;
				response_queue_addr_offset = response_queue_addr_offset_7;
				response_queue_base_addr = response_queue_base_addr_7;
				response_queue_host_addr_offset = response_queue_host_addr_offset_7;
				msg_lower_addr = msg_lower_addr_7;
  			msg_upper_addr = msg_upper_addr_7;
  			msg_data       = msg_data_7;
			end
			
			'h7: begin
				response_queue_addr = response_queue_addr_8;
				response_queue_addr_offset = response_queue_addr_offset_8;
				response_queue_base_addr = response_queue_base_addr_8;
				response_queue_host_addr_offset = response_queue_host_addr_offset_8;
				msg_lower_addr = msg_lower_addr_8;
  			msg_upper_addr = msg_upper_addr_8;
  			msg_data       = msg_data_8;
			end
			
			default: begin
				response_queue_addr = 0;
				response_queue_addr_offset = 1;
				response_queue_base_addr = 0;
				response_queue_host_addr_offset = 0;
				msg_lower_addr = 0;
  			msg_upper_addr = 0;
  			msg_data       = 0;
			end
		endcase
			
			
	end
	
	
	/*********************************/
	
	
	// write and read port for BAR0
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n ) begin
		
			resp_rd_en_o <= 1'b0;
			//response <= 32'b0;
			resp_cnt <= 32'b0;
			//response_on <= 1'b0;
			compl_done_q <= 1'b0;
			req_compl_q <= 1'b0;
			resp_empty_q <= 1'b1;
			
			en <= 1'b0;
			
			int_wr_msk_o <= 1'b0;
			int_rd_msk_o <= 1'b0;
			int_en_o <= 1'b0;
			
			
			
			req_queue_depth_o <= 15'b0;
			
			rd_d_o <= 32'b0;
			
			cont_rdy_o <= 1'b0;
			
			/*************ouyang***************/
			req_queue_doorbell_1 <= 16'b0;
			req_queue_doorbell_2 <= 16'b0;
			req_queue_doorbell_3 <= 16'b0;
			req_queue_doorbell_4 <= 16'b0;
			req_queue_doorbell_5 <= 16'b0;
			req_queue_doorbell_6 <= 16'b0;
			req_queue_doorbell_7 <= 16'b0;
			req_queue_doorbell_8 <= 16'b0;
			
			req_queue_base_addr_1 <= 32'b0;
			req_queue_base_addr_2 <= 32'b0;
			req_queue_base_addr_3 <= 32'b0;
			req_queue_base_addr_4 <= 32'b0;
			req_queue_base_addr_5 <= 32'b0;
			req_queue_base_addr_6 <= 32'b0;
			req_queue_base_addr_7 <= 32'b0;
			req_queue_base_addr_8 <= 32'b0;
			// the base addr for response queue
			//response_queue_base_addr <= 32'b0;
			response_queue_cur_offset_reg_o <= 32'b0;
			response_queue_addr_o <= 32'b0;	
			response_queue_addr_offset_o <= 1;					
			//msix table
			msg_lower_addr_o <= 32'b0;        		
      msg_upper_addr_o <= 32'b0;        		
      msg_data_o <= 32'b0;
			//--entry 0
      msg_lower_addr_1 <= 32'b0;        		
      msg_upper_addr_1 <= 32'b0;        		
      msg_data_1 <= 32'b0;
      //--entry 1
      msg_lower_addr_2 <= 32'b0;        		
      msg_upper_addr_2 <= 32'b0;        		
      msg_data_2 <= 32'b0;
      //--entry 2
      msg_lower_addr_3 <= 32'b0;        		
      msg_upper_addr_3 <= 32'b0;        		
      msg_data_3 <= 32'b0;
      //--entry 3
      msg_lower_addr_4 <= 32'b0;        		
      msg_upper_addr_4 <= 32'b0;        		
      msg_data_4 <= 32'b0;
      //--entry 4
      msg_lower_addr_5 <= 32'b0;        		
      msg_upper_addr_5 <= 32'b0;        		
      msg_data_5 <= 32'b0;
      //--entry 5
      msg_lower_addr_6 <= 32'b0;        		
      msg_upper_addr_6 <= 32'b0;        		
      msg_data_6 <= 32'b0;
      //--entry 6
      msg_lower_addr_7 <= 32'b0;        		
      msg_upper_addr_7 <= 32'b0;        		
      msg_data_7 <= 32'b0; 
      //--entry 7
      msg_lower_addr_8 <= 32'b0;        		
      msg_upper_addr_8 <= 32'b0;        		
      msg_data_8 <= 32'b0;
      
			response_queue_addr_1 <= 0;
			response_queue_addr_2 <= 0;
			response_queue_addr_3 <= 0;
			response_queue_addr_4 <= 0;
			response_queue_addr_5 <= 0;
			response_queue_addr_6 <= 0;
			response_queue_addr_7 <= 0;
			response_queue_addr_8 <= 0;
			response_queue_addr_offset_1 <= 1;
			response_queue_addr_offset_2 <= 1;
			response_queue_addr_offset_3 <= 1;
			response_queue_addr_offset_4 <= 1;
			response_queue_addr_offset_5 <= 1;
			response_queue_addr_offset_6 <= 1;
			response_queue_addr_offset_7 <= 1;
			response_queue_addr_offset_8 <= 1;
			response_queue_base_addr_1 <= 0;
			response_queue_base_addr_2 <= 0;
			response_queue_base_addr_3 <= 0;
			response_queue_base_addr_4 <= 0;
			response_queue_base_addr_5 <= 0;
			response_queue_base_addr_6 <= 0;
			response_queue_base_addr_7 <= 0;
			response_queue_base_addr_8 <= 0;
			response_queue_host_addr_offset_1 <= 0;
			response_queue_host_addr_offset_2 <= 0;
			response_queue_host_addr_offset_3 <= 0;
			response_queue_host_addr_offset_4 <= 0;
			response_queue_host_addr_offset_5 <= 0;
			response_queue_host_addr_offset_6 <= 0;
			response_queue_host_addr_offset_7 <= 0;
			response_queue_host_addr_offset_8 <= 0;
			
       
      interrupt_block_o <= 0;    
     // response_queue_host_addr_offset_o <= 0;   		
        	
		 /**********************************/
		
		end
		else begin
			
			if(!en) begin
				req_queue_doorbell_1 <= 16'b0;
				req_queue_doorbell_2 <= 16'b0;
				req_queue_doorbell_3 <= 16'b0;
				req_queue_doorbell_4 <= 16'b0;
				req_queue_doorbell_5 <= 16'b0;
				req_queue_doorbell_6 <= 16'b0;
				req_queue_doorbell_7 <= 16'b0;
				req_queue_doorbell_8 <= 16'b0;
				resp_cnt <= 32'b0;
				resp_empty_q <= 1'b1;
				response_queue_addr_offset_1 <= 1;
				response_queue_addr_offset_2 <= 1;
				response_queue_addr_offset_3 <= 1;
				response_queue_addr_offset_4 <= 1;
				response_queue_addr_offset_5 <= 1;
				response_queue_addr_offset_6 <= 1;
				response_queue_addr_offset_7 <= 1;
				response_queue_addr_offset_8 <= 1;
				response_queue_host_addr_offset_1 <= 0;
				response_queue_host_addr_offset_2 <= 0;
				response_queue_host_addr_offset_3 <= 0;
				response_queue_host_addr_offset_4 <= 0;
				response_queue_host_addr_offset_5 <= 0;
				response_queue_host_addr_offset_6 <= 0;
				response_queue_host_addr_offset_7 <= 0;
				response_queue_host_addr_offset_8 <= 0;
				//req_queue_base_addr <= 32'b0;			
			end
			
			/*************ouyang***************/
			response_queue_addr_o <= response_queue_addr;
		  response_queue_addr_offset_o <= response_queue_addr_offset;
			//response_queue_base_addr_o <= response_queue_base_addr;
			//response_queue_host_addr_offset_o <= response_queue_host_addr_offset;
			msg_lower_addr_o <= msg_lower_addr;
  		msg_upper_addr_o <= msg_upper_addr;
  		msg_data_o       <= msg_data;
			
			
			
			response_queue_cur_offset_reg_o <= response_queue_base_addr + 4096;
			
						
			if(response_queue_addr_offset_cnt_en_i) begin
				resp_cnt <= resp_cnt + 1;
				case(response_queue_num_i[2:0])
					
					'h0: begin
						if(response_queue_addr_offset_1 <= 1023) begin
							response_queue_addr_1 <= response_queue_addr_1 + 4;
							response_queue_addr_offset_1 <= response_queue_addr_offset_1 + 1; 
			  		end else begin
			  			response_queue_addr_1 <= response_queue_base_addr_1;
							response_queue_addr_offset_1 <= 1; 
			  		end
					end
					
					'h1: begin
						if(response_queue_addr_offset_2 <= 1023) begin
							response_queue_addr_2 <= response_queue_addr_2 + 4;
							response_queue_addr_offset_2 <= response_queue_addr_offset_2 + 1; 
			  		end else begin
			  			response_queue_addr_2 <= response_queue_base_addr_2;
							response_queue_addr_offset_2 <= 1; 
			  		end
					end
					
					'h2: begin
						if(response_queue_addr_offset_3 <= 1023) begin
							response_queue_addr_3 <= response_queue_addr_3 + 4;
							response_queue_addr_offset_3 <= response_queue_addr_offset_3 + 1; 
			  		end else begin
			  			response_queue_addr_3 <= response_queue_base_addr_3;
							response_queue_addr_offset_3 <= 1; 
			  		end
					end
					
					'h3: begin
						if(response_queue_addr_offset_4 <= 1023) begin
							response_queue_addr_4 <= response_queue_addr_4 + 4;
							response_queue_addr_offset_4 <= response_queue_addr_offset_4 + 1; 
			  		end else begin
			  			response_queue_addr_4 <= response_queue_base_addr_4;
							response_queue_addr_offset_4 <= 1; 
			  		end
					end
					
					'h4: begin
						if(response_queue_addr_offset_5 <= 1023) begin
							response_queue_addr_5 <= response_queue_addr_5 + 4;
							response_queue_addr_offset_5 <= response_queue_addr_offset_5 + 1; 
			  		end else begin
			  			response_queue_addr_5 <= response_queue_base_addr_5;
							response_queue_addr_offset_5 <= 1; 
			  		end
					end
					
					'h5: begin
						if(response_queue_addr_offset_6 <= 1023) begin
							response_queue_addr_6 <= response_queue_addr_6 + 4;
							response_queue_addr_offset_6 <= response_queue_addr_offset_6 + 1; 
			  		end else begin
			  			response_queue_addr_6 <= response_queue_base_addr_6;
							response_queue_addr_offset_6 <= 1; 
			  		end
					end
					
					'h6: begin
						if(response_queue_addr_offset_7 <= 1023) begin
							response_queue_addr_7 <= response_queue_addr_7 + 4;
							response_queue_addr_offset_7 <= response_queue_addr_offset_7 + 1; 
			  		end else begin
			  			response_queue_addr_7 <= response_queue_base_addr_7;
							response_queue_addr_offset_7 <= 1; 
			  		end
					end
					
					'h7: begin
						if(response_queue_addr_offset_8 <= 1023) begin
							response_queue_addr_8 <= response_queue_addr_8 + 4;
							response_queue_addr_offset_8 <= response_queue_addr_offset_8 + 1; 
			  		end else begin
			  			response_queue_addr_8 <= response_queue_base_addr_8;
							response_queue_addr_offset_8 <= 1; 
			  		end
					end
					
					default: begin
						response_queue_addr_1 <= 0;
						response_queue_addr_2 <= 0;
						response_queue_addr_3 <= 0;
						response_queue_addr_4 <= 0;
						response_queue_addr_5 <= 0;
						response_queue_addr_6 <= 0;
						response_queue_addr_7 <= 0;
						response_queue_addr_8 <= 0;
						response_queue_addr_offset_1 <= 1;
						response_queue_addr_offset_2 <= 1;
						response_queue_addr_offset_3 <= 1;
						response_queue_addr_offset_4 <= 1;
						response_queue_addr_offset_5 <= 1;
						response_queue_addr_offset_6 <= 1;
						response_queue_addr_offset_7 <= 1;
						response_queue_addr_offset_8 <= 1;						
					end
					
				endcase  
			end
			
			
			if( response_queue_addr_delta == 0 ) 
				interrupt_block_o <= 1;//cannot send reposnse
			else
			 	interrupt_block_o <= 0;	
        	
		 /**********************************/
			cont_rdy_o <= 1'b1;
			resp_rd_en_o  <= 1'b0;
			compl_done_q <= compl_done_i; 
			req_compl_q <= req_compl_i;
			
			if( !req_compl_q && req_compl_i)
				resp_empty_q <= resp_empty_i;
					
			case ( a_i )
			
				CONTROLLER_CONFIG: begin
				
					if( wr_en_i ) begin
					
						en <= wr_d_i[0];
						int_wr_msk_o <= wr_d_i[17];
						int_rd_msk_o <= wr_d_i[18];
						int_en_o <= wr_d_i[19];
					
					end
					
					rd_d_o <= { 12'b0 , int_en_o, int_rd_msk_o, int_wr_msk_o, 1'b0,  15'b0 , en };
				
				end
			
				
				DEVICE_STATUS: begin
				
					rd_d_o <= { fatal_err_i , req_unsupported_i , lba_ofr_err_i , prp_offset_err_i , id_ob_err_i , cpld_malformed_i , 25'b0 , cont_rdy_o };
									
				end
				
				REQUEST_QUEUE_DEPTH: begin
				
					if( wr_en_i )
						req_queue_depth_o <= wr_d_i[15:0];
					
					rd_d_o <= { 16'b0, req_queue_depth_o };
				
				end
				
				INTERRUPT_COUNT: begin
				
					rd_d_o <= int_cnt_i;
				
				end
				
				REQUEST_COUNT: begin
				
					rd_d_o <= req_cnt_i;
				
				end
				
				RESPONSE_COUNT: begin
				
					rd_d_o <= resp_cnt;
				
				end
				
				
				/*************ouyang***************/
				
				/*************queue 1******************/
				//the base addr for response queue
				'h11: begin
					if (wr_en_i) begin
						response_queue_base_addr_1 <= wr_d_i;	
						response_queue_addr_1 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_1;					
				end
				//current host offset
				'h12: begin
					if(wr_en_i)
						response_queue_host_addr_offset_1 <= wr_d_i[9:0];
				end
				//doorbell register
				'h13: begin				
					if( wr_en_i )
						req_queue_doorbell_1 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_1 };				
				end
				//the base addr of request queue				
				'h14: begin				
					if( wr_en_i )
						req_queue_base_addr_1 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_1;					
				end
				
				/*************queue 3******************/
				//the base addr for response queue
				'h15: begin
					if (wr_en_i) begin
						response_queue_base_addr_2 <= wr_d_i;	
						response_queue_addr_2 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_2;					
				end
				//current host offset
				'h16: begin
					if(wr_en_i)
						response_queue_host_addr_offset_2 <= wr_d_i[9:0];
				end
				//doorbell register
				'h17: begin				
					if( wr_en_i )
						req_queue_doorbell_2 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_2 };				
				end
				//the base addr of request queue				
				'h18: begin				
					if( wr_en_i )
						req_queue_base_addr_2 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_2;					
				end
				
						
				/*************queue 3******************/
				//the base addr for response queue
				'h19: begin
					if (wr_en_i) begin
						response_queue_base_addr_3 <= wr_d_i;	
						response_queue_addr_3 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_3;					
				end
				//current host offset
				'h1a: begin
					if(wr_en_i)
						response_queue_host_addr_offset_3 <= wr_d_i[9:0];
				end
				//doorbell register
				'h1b: begin				
					if( wr_en_i )
						req_queue_doorbell_3 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_3 };				
				end
				//the base addr of request queue				
				'h1c: begin				
					if( wr_en_i )
						req_queue_base_addr_3 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_3;					
				end
				
						
				/*************queue 4******************/
				//the base addr for response queue
				'h1d: begin
					if (wr_en_i) begin
						response_queue_base_addr_4 <= wr_d_i;	
						response_queue_addr_4 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_4;					
				end
				//current host offset
				'h1e: begin
					if(wr_en_i)
						response_queue_host_addr_offset_4 <= wr_d_i[9:0];
				end
				//doorbell register
				'h1f: begin				
					if( wr_en_i )
						req_queue_doorbell_4 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_4 };				
				end
				//the base addr of request queue				
				'h20: begin				
					if( wr_en_i )
						req_queue_base_addr_4 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_4;					
				end
				
						
				/*************queue 5******************/
				//the base addr for response queue
				'h21: begin
					if (wr_en_i) begin
						response_queue_base_addr_5 <= wr_d_i;	
						response_queue_addr_5 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_5;					
				end
				//current host offset
				'h22: begin
					if(wr_en_i)
						response_queue_host_addr_offset_5 <= wr_d_i[9:0];
				end
				//doorbell register
				'h23: begin				
					if( wr_en_i )
						req_queue_doorbell_5 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_5 };				
				end
				//the base addr of request queue				
				'h24: begin				
					if( wr_en_i )
						req_queue_base_addr_5 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_5;					
				end
				
						
				/*************queue 6******************/
				//the base addr for response queue
				'h25: begin
					if (wr_en_i) begin
						response_queue_base_addr_6 <= wr_d_i;	
						response_queue_addr_6 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_6;					
				end
				//current host offset
				'h26: begin
					if(wr_en_i)
						response_queue_host_addr_offset_6 <= wr_d_i[9:0];
				end
				//doorbell register
				'h27: begin				
					if( wr_en_i )
						req_queue_doorbell_6 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_6 };				
				end
				//the base addr of request queue				
				'h28: begin				
					if( wr_en_i )
						req_queue_base_addr_6 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_6;					
				end
				
						
				/*************queue 7******************/
				//the base addr for response queue
				'h29: begin
					if (wr_en_i) begin
						response_queue_base_addr_7 <= wr_d_i;	
						response_queue_addr_7 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_7;					
				end
				//current host offset
				'h2a: begin
					if(wr_en_i)
						response_queue_host_addr_offset_7 <= wr_d_i[9:0];
				end
				//doorbell register
				'h2b: begin				
					if( wr_en_i )
						req_queue_doorbell_7 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_7 };				
				end
				//the base addr of request queue				
				'h2c: begin				
					if( wr_en_i )
						req_queue_base_addr_7 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_7;					
				end
				
						
				/*************queue 8******************/
				//the base addr for response queue
				'h2d: begin
					if (wr_en_i) begin
						response_queue_base_addr_8 <= wr_d_i;	
						response_queue_addr_8 <= wr_d_i;
					end					
					rd_d_o <= response_queue_base_addr_8;					
				end
				//current host offset
				'h2e: begin
					if(wr_en_i)
						response_queue_host_addr_offset_8 <= wr_d_i[9:0];
				end
				//doorbell register
				'h2f: begin				
					if( wr_en_i )
						req_queue_doorbell_8 <= wr_d_i[15:0];					
					rd_d_o <= { 16'b0 , req_queue_doorbell_8 };				
				end
				//the base addr of request queue				
				'h30: begin				
					if( wr_en_i )
						req_queue_base_addr_8 <= wr_d_i[31:0];					
					rd_d_o <= req_queue_base_addr_8;					
				end
			
				
				//cancel reg
				'h41: begin
        	if (wr_en_i)
        		cancel <= wr_d_i;        		
        	rd_d_o <= cancel;
        end
				
				//msix table
				        
        //--entry 1
        7'h48: begin
        	if (wr_en_i)
        		msg_lower_addr_1 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_1;
        end
        
        7'h49: begin
        	if (wr_en_i)
        		msg_upper_addr_1 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_1;
        end
        
        7'h4a: begin
        	if (wr_en_i)
        		msg_data_1 <= wr_d_i;        		
        	rd_d_o <= msg_data_1;
        end
        
        //--entry 2
        7'h4c: begin
        	if (wr_en_i)
        		msg_lower_addr_2 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_2;
        end
        
        7'h4d: begin
        	if (wr_en_i)
        		msg_upper_addr_2 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_2;
        end
        
        7'h4e: begin
        	if (wr_en_i)
        		msg_data_2 <= wr_d_i;        		
        	rd_d_o <= msg_data_2;
        end
        
        //--entry 3
        7'h50: begin
        	if (wr_en_i)
        		msg_lower_addr_3 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_3;
        end
        
        7'h51: begin
        	if (wr_en_i)
        		msg_upper_addr_3 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_3;
        end
        
        7'h52: begin
        	if (wr_en_i)
        		msg_data_3 <= wr_d_i;        		
        	rd_d_o <= msg_data_3;
        end
        
        //--entry 4
        7'h54: begin
        	if (wr_en_i)
        		msg_lower_addr_4 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_4;
        end
        
        7'h55: begin
        	if (wr_en_i)
        		msg_upper_addr_4 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_4;
        end
        
        7'h56: begin
        	if (wr_en_i)
        		msg_data_4 <= wr_d_i;        		
        	rd_d_o <= msg_data_4;
        end
        
        //--entry 5
        7'h58: begin
        	if (wr_en_i)
        		msg_lower_addr_5 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_5;
        end
        
        7'h59: begin
        	if (wr_en_i)
        		msg_upper_addr_5 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_5;
        end
        
        7'h5a: begin
        	if (wr_en_i)
        		msg_data_5 <= wr_d_i;        		
        	rd_d_o <= msg_data_5;
        end
        
        //--entry 6
        7'h5c: begin
        	if (wr_en_i)
        		msg_lower_addr_6 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_6;
        end
        
        7'h5d: begin
        	if (wr_en_i)
        		msg_upper_addr_6 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_6;
        end
        
        7'h5e: begin
        	if (wr_en_i)
        		msg_data_6 <= wr_d_i;        		
        	rd_d_o <= msg_data_6;
        end
        
        //--entry 7
        7'h60: begin
        	if (wr_en_i)
        		msg_lower_addr_7 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_7;
        end
        
        7'h61: begin
        	if (wr_en_i)
        		msg_upper_addr_7 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_7;
        end
        
        7'h62: begin
        	if (wr_en_i)
        		msg_data_7 <= wr_d_i;        		
        	rd_d_o <= msg_data_7;
        end
        
        //--entry 8
        7'h64: begin
        	if (wr_en_i)
        		msg_lower_addr_8 <= wr_d_i;        		
        	rd_d_o <= msg_lower_addr_8;
        end
        
        7'h65: begin
        	if (wr_en_i)
        		msg_upper_addr_8 <= wr_d_i;        		
        	rd_d_o <= msg_upper_addr_8;
        end
        
        7'h66: begin
        	if (wr_en_i)
        		msg_data_8 <= wr_d_i;        		
        	rd_d_o <= msg_data_8;
        end
        
        
				/**********************************/
				default: rd_d_o <= 32'b0;
			
			endcase
		
		end //( !rst_n )
	
	end
	
	// the new doorbell's coming triggers this state machine to fetch
	// requests from request queue in the HOST.
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n || !en ) begin
		
			req_cnt <= 16'b0;
			//req_queue_doorbell_pre <= 16'b0;
			
			dma_rd_req_flag_o <= 1'b0;
			
			bar1_wr_en1_o <= 1'b0;
			bar1_addr1_o <= 7'b0;
			bar1_wr_be1_o <= 4'b0;
			bar1_wr_d1_o <= 32'b0;
			
			dma_rd_q_wr_en_o <= 1'b0;
			dma_rd_q_wr_data_o <= 64'b0;
		
			bar0_state <= BAR0_DMA_RST;
			/*********ouyang*************/
			cur_req_queue_doorbell_pre <= 0;
			cur_doorbell_num <= 0;
			cur_req_queue_base_addr <= 0;
			req_queue_doorbell_pre_1 <= 16'b0;
			req_queue_doorbell_pre_2 <= 16'b0;
			req_queue_doorbell_pre_3 <= 16'b0;
			req_queue_doorbell_pre_4 <= 16'b0;
			req_queue_doorbell_pre_5 <= 16'b0;
			req_queue_doorbell_pre_6 <= 16'b0;
			req_queue_doorbell_pre_7 <= 16'b0;
			req_queue_doorbell_pre_8 <= 16'b0;
			/****************************/
		
		end
		else begin
		
			dma_rd_q_wr_en_o <= 1'b0;
			dma_rd_q_wr_data_o <= 64'b0;
		
			case ( bar0_state )
			
				BAR0_DMA_RST: begin
				
					if( ( doorbell_delta_q != 0 ) && req_queue_av_fg ) begin
						
						if( !doorbell_delta_q[16] ) begin
						
							if( doorbell_delta_q[15:0] > req_queue_av )
								req_cnt <= req_queue_av;
							else
								req_cnt <= doorbell_delta_q[15:0];
						
						end
						else begin
						
							if( ( req_queue_depth_o - req_queue_doorbell_pre ) > req_queue_av )
								req_cnt <= req_queue_av;
							else
								req_cnt <= req_queue_depth_o - req_queue_doorbell_pre;
						
						end //if( !doorbell_delta_q[16] )
						
						bar0_state <= BAR0_DMA_CONFIG1;
						/*********ouyang*************/
						cur_req_queue_doorbell_pre <= req_queue_doorbell_pre;
						cur_doorbell_num <= doorbell_num_sel;
						cur_req_queue_base_addr <= req_queue_base_addr;
						/****************************/
						
					end	//if( doorbell_delta_q != 0 )		
						
				end
				
				BAR0_DMA_CONFIG1: begin
				
					if( !mrd_start_i && !bar1_arbiter_busy_i && !bar1_wr_busy_i && !dma_rd_q_full_i ) begin
					
						bar1_wr_en1_o <= 1'b1;
						bar1_addr1_o <= `DMA_RD_SIZE_REG;
						bar1_wr_be1_o <= 4'b1111;
						bar1_wr_d1_o <= req_cnt << `REQUEST_SIZE_ORDER;
						
						bar0_state <= BAR0_DMA_CONFIG2;
					
					end				
				
				end
				
				BAR0_DMA_CONFIG2: begin
				
					if( !bar1_wr_ack1_n_i ) begin
					
						if( !bar1_wr_busy_i ) begin
							
							bar1_wr_en1_o <= 1'b1;
							bar1_addr1_o <= `DMA_RD_ADDR_REG;
							bar1_wr_be1_o <= 4'b1111;
							//bar1_wr_d1_o <= req_queue_base_addr + ( req_queue_doorbell_p << `REQUEST_SIZE_ORDER );
							/*********ouyang*************/
							bar1_wr_d1_o <= cur_req_queue_base_addr + ( cur_req_queue_doorbell_pre << `REQUEST_SIZE_ORDER );
							/****************************/
							
							bar0_state <= BAR0_DMA_CONFIG3;
							
						end
					
					end
					else begin
					
						bar1_wr_en1_o <= 1'b0;
						
						bar0_state <= BAR0_DMA_RST;
					
					end //if( !bar1_wr_ack2_n_i )					
				
				end
				
				BAR0_DMA_CONFIG3: begin
					
					if( !bar1_wr_busy_i ) begin
						
						bar1_wr_en1_o <= 1'b1;
						bar1_addr1_o <= `DMA_RD_UPADDR_REG;
						bar1_wr_be1_o <= 4'b1111;
						bar1_wr_d1_o <= 32'b0;

						bar0_state <= BAR0_DMA_CONFIG4;							
					
					end					
					
				end
				
				BAR0_DMA_CONFIG4: begin
				
					if( !bar1_wr_busy_i ) begin
						
						bar1_wr_en1_o <= 1'b1;
						bar1_addr1_o <= `DMA_CTRL_STA_REG;
						bar1_wr_be1_o <= 4'b1100;
						bar1_wr_d1_o <= { 15'b0 , 1'b1 , 16'b0 };
						
						dma_rd_q_wr_en_o <= 1'b1;
						dma_rd_q_wr_data_o <= ( req_cnt << `REQUEST_SIZE_ORDER ) | ( 1 << 62 );							

						bar0_state <= BAR0_DMA_START;							
					
					end					
				
				end
				
				BAR0_DMA_START: begin
				
					if( !bar1_wr_busy_i ) begin
					
						bar1_wr_en1_o <= 1'b0;
						dma_rd_req_flag_o <= 1'b1;
						
						bar0_state <= BAR0_DMA_WAIT;
					
					end
				
				end
				
				BAR0_DMA_WAIT: begin
				
					if( mrd_start_i && mrd_done_i ) begin
						
						//if( ( req_queue_doorbell_p + req_cnt ) == req_queue_depth_o )
						//	req_queue_doorbell_p <= 0;
						//else
						//	req_queue_doorbell_p <= req_queue_doorbell_p + req_cnt;
						/**************ouyang*******************/
						if( ( cur_req_queue_doorbell_pre + req_cnt ) == req_queue_depth_o ) begin
							
							case(cur_doorbell_num)
								'h0:
									req_queue_doorbell_pre_1 <= 0;
								'h1:
									req_queue_doorbell_pre_2 <= 0;
								'h2:
									req_queue_doorbell_pre_3 <= 0;
								'h3:
									req_queue_doorbell_pre_4 <= 0;
								'h4:
									req_queue_doorbell_pre_5 <= 0;
								'h5:
									req_queue_doorbell_pre_6 <= 0;
								'h6:
									req_queue_doorbell_pre_7 <= 0;
								'h7:
									req_queue_doorbell_pre_8 <= 0;
							endcase
						end
						else begin
							case(cur_doorbell_num)
								'h0:
									req_queue_doorbell_pre_1 <= req_queue_doorbell_pre_1 + req_cnt;
								'h1:
									req_queue_doorbell_pre_2 <= req_queue_doorbell_pre_2 + req_cnt;
								'h2:
									req_queue_doorbell_pre_3 <= req_queue_doorbell_pre_3 + req_cnt;
								'h3:
									req_queue_doorbell_pre_4 <= req_queue_doorbell_pre_4 + req_cnt;
								'h4:
									req_queue_doorbell_pre_5 <= req_queue_doorbell_pre_5 + req_cnt;
								'h5:
									req_queue_doorbell_pre_6 <= req_queue_doorbell_pre_6 + req_cnt;
								'h6:
									req_queue_doorbell_pre_7 <= req_queue_doorbell_pre_7 + req_cnt;
								'h7:
									req_queue_doorbell_pre_8 <= req_queue_doorbell_pre_8 + req_cnt;
							endcase
						end
						/**************************************************/	
							
						dma_rd_req_flag_o <= 1'b0;
						
						bar0_state <= BAR0_DMA_CLEAR;
						
					end
				
				end
				
				BAR0_DMA_CLEAR: begin
				
					if( !bar1_arbiter_busy_i ) begin
						
						bar1_wr_en1_o <= 1'b1;
						bar1_addr1_o <= `DMA_CTRL_STA_REG;
						bar1_wr_be1_o <= 4'b1100;
						bar1_wr_d1_o <= 32'b0;
						
						bar0_state <= BAR0_DMA_CLEAR_ACK;
						
					end
				
				end
				
				BAR0_DMA_CLEAR_ACK: begin
				
					if( !bar1_wr_ack1_n_i ) begin
					
						if( !bar1_wr_busy_i ) begin
						
							bar1_wr_en1_o <= 1'b0;
							bar0_state <= BAR0_DMA_RST;							
						
						end
					
					end
					else begin
					
						bar1_wr_en1_o <= 1'b0;
						bar0_state <= BAR0_DMA_CLEAR;
					
					end //if( !bar1_wr_ack2_n_i )
				
				end
				
				default: bar0_state <= BAR0_DMA_RST;
			
			endcase
		
		end
	
	end
	
	
endmodule
