//--------------------------------------------------------------------------------
//-- Filename: REQ_MANAGER.v
//--
//-- Description: Request Manager Module
//--              
//--              Multiple low layer module are linked in this module.
//-- 
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module REQ_MANAGER(

						clk,
						rst_n,
						en,
						
						// REQ_QUEUE_WRAPPER
						rdata_i,
						rdata_wr_en_i,
						req_queue_full_o,
						
						//CPM
						CMGFTL_cmd_fifo_full_i,
						CMGFTL_cmd_fifo_almost_full_i,
						CMGFTL_cmd_fifo_wr_en_o,
						CMGFTL_cmd_fifo_data_o,

						FTLCMG_cmd_fifo_empty_i,
						FTLCMG_cmd_fifo_almost_empty_i,
						FTLCMG_cmd_fifo_rd_en_o,
						FTLCMG_cmd_fifo_data_i,					

						bar1_wr_en2_o,
						bar1_addr2_o,
						bar1_wr_be2_o,
						bar1_wr_d2_o,
						bar1_wr_ack2_n_i,
						
						bar1_wr_en3_o,
						bar1_addr3_o,
						bar1_wr_be3_o,
						bar1_wr_d3_o,
						bar1_wr_ack3_n_i,
						
						bar1_arbiter_busy_i,
						bar1_wr_busy_i,

						mrd_start_i,
						mrd_done_i,
						mwr_start_i,
						mwr_done_i,
						req_compl_i,

						recv_fifo_av_i,
						
						//BAR0_WRAPPER
						a_i,
						wr_en_i,
						wr_be_i,
						wr_busy_o,
						rd_d_o,
						rd_be_i,
						wr_d_i,
						
						bar1_wr_en1_o,
						bar1_addr1_o,
						bar1_wr_be1_o,
						bar1_wr_d1_o,
						bar1_wr_ack1_n_i,

						compl_done_i,
						dma_rd_req_flag_o,
						
						cpld_malformed_i,
						
						//INT_MANAGER
						msi_on,
						
						cfg_interrupt_assert_n_o,
						cfg_interrupt_rdy_n_i,
						cfg_interrupt_n_o,
						cfg_interrupt_legacyclr,
						
						//DMA READ QUEUE
						dma_rd_q_rd_en_i,
						dma_rd_q_rd_data_o,
						dma_rd_q_empty_o,
						dma_rd_xfer_done_i,
						dma_rd_done_entry_i,
						dma_rd_xfer_done_ack_o,
						/*************ouyang***************/
						//response queue interface
						response_queue_empty_o,
	          response_queue_data_o,
  					response_queue_rd_en_i ,//read enable signal for response queue
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
            response_queue_addr_offset_o
            /**********************************/							
					
    );

	/*************ouyang***************/
	//response queue interface
	output response_queue_empty_o;
	output [31:0] response_queue_data_o;
  input response_queue_rd_en_i ;//read enable signal for response queue
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
	
	input				clk;
	input				rst_n;
	output				en;
	
	// Request Queue Wrapper
	//
	input [127:0]		rdata_i;
	input				rdata_wr_en_i;
	output				req_queue_full_o;
	
	// CPM
	//
	input				CMGFTL_cmd_fifo_full_i;
	input				CMGFTL_cmd_fifo_almost_full_i;
	output				CMGFTL_cmd_fifo_wr_en_o;
	output [127:0]		CMGFTL_cmd_fifo_data_o;
	
	input 				FTLCMG_cmd_fifo_empty_i;
	input				FTLCMG_cmd_fifo_almost_empty_i;
	output				FTLCMG_cmd_fifo_rd_en_o;
	input [127:0]		FTLCMG_cmd_fifo_data_i;
	
	output				bar1_wr_en2_o;
	output [6:0]		bar1_addr2_o;
	output [3:0]		bar1_wr_be2_o;
	output [31:0]		bar1_wr_d2_o;
	input				bar1_wr_ack2_n_i;

	output				bar1_wr_en3_o;
	output [6:0]		bar1_addr3_o;
	output [3:0]		bar1_wr_be3_o;
	output [31:0]		bar1_wr_d3_o;
	input				bar1_wr_ack3_n_i;
	
	input				bar1_arbiter_busy_i;
	input				bar1_wr_busy_i;

	input				mrd_start_i , mwr_start_i;
	input				mrd_done_i , mwr_done_i;
	input				req_compl_i;
	
	input				recv_fifo_av_i;	
	
	// BAR0 Wrapper
	//
	input [6:0]			a_i;
	input [3:0]			rd_be_i;
	output [31:0]		rd_d_o;
	
	input				wr_en_i;
	input [7:0]			wr_be_i;
	input [31:0]		wr_d_i;
	output				wr_busy_o;
	
	output				bar1_wr_en1_o;
	output [6:0]		bar1_addr1_o;
	output [3:0]		bar1_wr_be1_o;
	output [31:0]		bar1_wr_d1_o;
	input				bar1_wr_ack1_n_i;

	input				compl_done_i;	
	output				dma_rd_req_flag_o;
	
	input				cpld_malformed_i;
	
	// Interrupt Manager
	//
	input				msi_on;
	output				cfg_interrupt_assert_n_o;
	input				cfg_interrupt_rdy_n_i;
	output				cfg_interrupt_n_o;
	input				cfg_interrupt_legacyclr;
	
	input				dma_rd_q_rd_en_i;
	output [63:0]		dma_rd_q_rd_data_o;
	output				dma_rd_q_empty_o;
	input				dma_rd_xfer_done_i;
	input [63:0]		dma_rd_done_entry_i;
	output				dma_rd_xfer_done_ack_o;	

	reg					dma_rd_q_wr_en;
	wire				dma_rd_q_wr_en0 , dma_rd_q_wr_en1;
	reg [63:0]			dma_rd_q_wr_data;	
	wire [63:0]			dma_rd_q_wr_data0 , dma_rd_q_wr_data1;

	wire				dma_rd_q_rd_en;
	wire [63:0]			dma_rd_q_rd_data;
	wire				dma_rd_q_empty;
	wire				dma_rd_q_full;
	
	// local Wires
	//
	wire [9:0]			req_queue_av;
	
	wire				rd_req_empty;
	wire				rd_req_rd_en;
	wire [127:0]		rd_req_data;
	
	wire				wr_req_empty;
	wire				wr_req_rd_en;
	wire [127:0]		wr_req_data;	
	
	wire [31:0]			req_cnt;
	wire				req_unsupported;
	
	
	wire [15:0]			req_queue_depth;
	wire				resp_empty;
	wire [31:0]			resp;
	wire				resp_rd_en;
	
	wire				fatal_err = 1'b0;
	wire				lba_ofr_err = 1'b0;
	wire				prp_offset_err = 1'b0;
	wire				id_ob_err = 1'b0;
	
	wire				rd_req_done;
	wire				wr_req_done;
	
	wire [31:0]			int_cnt;
	wire				int_en;
	wire				int_rd_msk;
	wire				int_wr_msk;
	
	assign				dma_rd_q_rd_en = dma_rd_q_rd_en_i;
	assign				dma_rd_q_rd_data_o = dma_rd_q_rd_data;
	assign				dma_rd_q_empty_o = dma_rd_q_empty;	
	
	REQ_QUEUE_WRAPPER REQ_QUEUE_WRAP(

						.clk(clk),
						.rst_n(rst_n),
						.en(en),
						
						//receive request queue
						.rdata_i(rdata_i),
						.rdata_wr_en_i(rdata_wr_en_i),
						.req_queue_av_o(req_queue_av),
						.req_queue_full_o(req_queue_full_o),
						
						//rd request queue
						.rd_req_empty_o(rd_req_empty),
						.rd_req_rd_en_i(rd_req_rd_en),
						.rd_req_data_o(rd_req_data),
						
						//wr request queue
						.wr_req_empty_o(wr_req_empty),
						.wr_req_rd_en_i(wr_req_rd_en),
						.wr_req_data_o(wr_req_data),
						
						.req_cnt_o(req_cnt),
						.req_unsupported_o(req_unsupported)

    );
	
	CPM CMD_PROCESS_UNIT(
	
						.clk(clk),
						.rst_n(rst_n),
						.en(en),
						
						//REQ QUEUE WRAPPER
						.rd_req_data_i(rd_req_data),
						.rd_req_rd_en_o(rd_req_rd_en),
						.rd_req_empty_i(rd_req_empty),
						
						.wr_req_data_i(wr_req_data),
						.wr_req_rd_en_o(wr_req_rd_en),
						.wr_req_empty_i(wr_req_empty),
						
						//receive cmd fifo
						.CMGFTL_cmd_fifo_full_i(CMGFTL_cmd_fifo_full_i),
						.CMGFTL_cmd_fifo_almost_full_i(CMGFTL_cmd_fifo_almost_full_i),
						.CMGFTL_cmd_fifo_wr_en_o(CMGFTL_cmd_fifo_wr_en_o),
						.CMGFTL_cmd_fifo_data_o(CMGFTL_cmd_fifo_data_o),
						
						//send cmd fifo
						.FTLCMG_cmd_fifo_empty_i(FTLCMG_cmd_fifo_empty_i),
						.FTLCMG_cmd_fifo_almost_empty_i(FTLCMG_cmd_fifo_almost_empty_i),
						.FTLCMG_cmd_fifo_rd_en_o(FTLCMG_cmd_fifo_rd_en_o),
						.FTLCMG_cmd_fifo_data_i(FTLCMG_cmd_fifo_data_i),
						
						//BAR1 Write Arbiter write port 2
						.bar1_wr_en2_o(bar1_wr_en2_o),
						.bar1_addr2_o(bar1_addr2_o),
						.bar1_wr_be2_o(bar1_wr_be2_o),
						.bar1_wr_d2_o(bar1_wr_d2_o),
						.bar1_wr_ack2_n_i(bar1_wr_ack2_n_i),
						
						//BAR1 Write Arbiter write port 3
						.bar1_wr_en3_o(bar1_wr_en3_o),
						.bar1_addr3_o(bar1_addr3_o),
						.bar1_wr_be3_o(bar1_wr_be3_o),
						.bar1_wr_d3_o(bar1_wr_d3_o),
						.bar1_wr_ack3_n_i(bar1_wr_ack3_n_i),
						
						.bar1_arbiter_busy_i(bar1_arbiter_busy_i),
						.bar1_wr_busy_i(bar1_wr_busy_i),

						//BAR1
						.mrd_start_i(mrd_start_i),
						.mrd_done_i(mrd_done_i),
						.mwr_start_i(mwr_start_i),
						.mwr_done_i(mwr_done_i),
						
						.recv_fifo_av_i(recv_fifo_av_i),
						
						//BAR0 register
						.req_queue_depth_i(req_queue_depth),
						.resp_o(resp),
						.resp_empty_o(resp_empty),
						.resp_rd_en_i(resp_rd_en),
						
						.fatal_err_o(),
						.lba_ofr_err_o(),
						.prp_offset_err_o(),
						.id_ob_err_o(),
						
						//Interrupt Generator
						.rd_req_done_o(rd_req_done),
						.wr_req_done_o(wr_req_done),
						
						.dma_rd_q_wr_en_o(dma_rd_q_wr_en0),
						.dma_rd_q_wr_data_o(dma_rd_q_wr_data0),
						.dma_rd_q_full_i(dma_rd_q_full),
						.dma_rd_xfer_done_i(dma_rd_xfer_done_i),
						.dma_rd_done_entry_i(dma_rd_done_entry_i),
						.dma_rd_xfer_done_ack_o(dma_rd_xfer_done_ack_o),
						
						/*************ouyang***************/
						//response queue interface
    				.response_queue_empty_o(response_queue_empty_o),
    				.response_queue_data_o(response_queue_data_o),
    				.response_queue_rd_en_i(response_queue_rd_en_i) //read enable signal for response queue
    				/**********************************/						
	);
	
	BAR0_WRAPPER BAR0_WRAP(
	
						.clk(clk),
						.rst_n(rst_n),
						.en(en),
						
						//read and write port
						.a_i(a_i),
						.wr_en_i(wr_en_i),
						.wr_be_i(wr_be_i),
						.wr_busy_o(wr_busy_o),
						.rd_d_o(rd_d_o),
						.rd_be_i(rd_be_i),
						.wr_d_i(wr_d_i),
						
						//BAR1 Write Arbiter write port 1
						.bar1_wr_en1_o(bar1_wr_en1_o),
						.bar1_addr1_o(bar1_addr1_o),
						.bar1_wr_be1_o(bar1_wr_be1_o),
						.bar1_wr_d1_o(bar1_wr_d1_o),
						.bar1_wr_ack1_n_i(bar1_wr_ack1_n_i),
						.bar1_arbiter_busy_i(bar1_arbiter_busy_i),
						
						.bar1_wr_busy_i(bar1_wr_busy_i),
						
						//response message read port
						.resp_i(resp),
						.resp_empty_i(resp_empty),
						.resp_rd_en_o(resp_rd_en),
						.req_compl_i(req_compl_i),
						
						.mrd_start_i(mrd_start_i),
						.mrd_done_i(mrd_done_i),
						
						.compl_done_i(compl_done_i),
						
						.dma_rd_req_flag_o(dma_rd_req_flag_o),
						
						.req_queue_av_i(req_queue_av),
						.req_queue_depth_o(req_queue_depth),
						
						.int_cnt_i(int_cnt),
						.req_cnt_i(req_cnt),
						
						//error report
						.cpld_malformed_i(cpld_malformed_i),
						.fatal_err_i(fatal_err),
						.req_unsupported_i(req_unsupported),
						.lba_ofr_err_i(lba_ofr_err),
						.prp_offset_err_i(prp_offset_err),
						.id_ob_err_i(id_ob_err),
						
						.cont_rdy_o(),
						
						//INT ctrl
						.int_en_o(int_en),
						.int_rd_msk_o(int_rd_msk),
						.int_wr_msk_o(int_wr_msk),
						
						.dma_rd_q_wr_en_o(dma_rd_q_wr_en1),
						.dma_rd_q_wr_data_o(dma_rd_q_wr_data1),
						.dma_rd_q_full_i(dma_rd_q_full),
						
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
            .response_queue_num_i(response_queue_data_o[15:10])
            /**********************************/						
    );
	
	
	INT_MANAGER INT_CTRL(
					
						.clk(clk),
						.rst_n(rst_n),
						.en(en),
						
						.int_en(int_en),
						.rd_int_msk_i(int_rd_msk),
						.wr_int_msk_i(int_wr_msk),
						
						.rd_req_done_i(rd_req_done),
						.wr_req_done_i(wr_req_done),
						
						.int_cnt_o(int_cnt),
						
						.msi_on(msi_on),
						
						.cfg_interrupt_assert_n_o(cfg_interrupt_assert_n_o),
						.cfg_interrupt_rdy_n_i(cfg_interrupt_rdy_n_i),
						.cfg_interrupt_n_o(cfg_interrupt_n_o),
						.cfg_interrupt_legacyclr(cfg_interrupt_legacyclr)
    );

	wire srst = !rst_n || !en;
	
	always @ ( * ) begin
	
		if( !rst_n || !en ) begin
		
			dma_rd_q_wr_en = 1'b0;
			dma_rd_q_wr_data = 64'b0;
			
		end
		else begin
			if( dma_rd_q_wr_en0 && !dma_rd_q_wr_en1 ) begin
			
				dma_rd_q_wr_en = 1'b1;
				dma_rd_q_wr_data = dma_rd_q_wr_data0;
				
			end else if( dma_rd_q_wr_en1 && !dma_rd_q_wr_en0 ) begin
			
				dma_rd_q_wr_en = 1'b1;
				dma_rd_q_wr_data = dma_rd_q_wr_data1;			
			
			end else begin
		
				dma_rd_q_wr_en = 1'b0;
				dma_rd_q_wr_data = 64'b0;
						
			end
		end
	
	end
	
	DMA_READ_QUEUE DMA_READ_QUEUE (
	
		.clk(clk), // input clk
		.srst(srst), // input srst
		.din(dma_rd_q_wr_data), // input [31 : 0] din
		.wr_en(dma_rd_q_wr_en), // input wr_en
		.rd_en(dma_rd_q_rd_en), // input rd_en
		.dout(dma_rd_q_rd_data), // output [31 : 0] dout
		.full(dma_rd_q_full), // output full
		.empty(dma_rd_q_empty) // output empty
	);
	
endmodule
