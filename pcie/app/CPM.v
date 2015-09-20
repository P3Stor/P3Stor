//--------------------------------------------------------------------------------
//-- Filename: CPM.v
//--
//-- Description: Command Process Module(CPM)
//--              
//--              The module designed to process read and write command from host.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`include "CM_HEAD.v"

module CPM (
						clk,
						rst_n,
						en,
						
						//REQ QUEUE WRAPPER
						rd_req_data_i,
						rd_req_rd_en_o,
						rd_req_empty_i,
						
						wr_req_data_i,
						wr_req_rd_en_o,
						wr_req_empty_i,
						
						//receive cmd fifo
						CMGFTL_cmd_fifo_full_i,
						CMGFTL_cmd_fifo_almost_full_i,
						CMGFTL_cmd_fifo_wr_en_o,
						CMGFTL_cmd_fifo_data_o,
						
						//send cmd fifo
						FTLCMG_cmd_fifo_empty_i,
						FTLCMG_cmd_fifo_almost_empty_i,
						FTLCMG_cmd_fifo_rd_en_o,
						FTLCMG_cmd_fifo_data_i,
						
						//BAR1 Write Arbiter write port 2
						bar1_wr_en2_o,
						bar1_addr2_o,
						bar1_wr_be2_o,
						bar1_wr_d2_o,
						bar1_wr_ack2_n_i,
						//bar1_wr_exclu2_i,
						//bar1_wr_busy2_i,
						
						//BAR1 Write Arbiter write port 3
						bar1_wr_en3_o,
						bar1_addr3_o,
						bar1_wr_be3_o,
						bar1_wr_d3_o,
						bar1_wr_ack3_n_i,
						//bar1_wr_exclu3_i,
						//bar1_wr_busy3_i,
						
						bar1_arbiter_busy_i,
						bar1_wr_busy_i,

						//BAR1
						mrd_start_i,
						mrd_done_i,
						mwr_start_i,
						mwr_done_i,
						
						recv_fifo_av_i,
						
						//BAR0 register
						req_queue_depth_i,
						resp_o,
						resp_empty_o,
						resp_rd_en_i,
						
						fatal_err_o,
						lba_ofr_err_o,
						prp_offset_err_o,
						id_ob_err_o,
						
						//Interrupt Generator
						rd_req_done_o,
						wr_req_done_o,
						
						//DMA READ QUEUE
						dma_rd_q_wr_en_o,
						dma_rd_q_wr_data_o,
						dma_rd_q_full_i,
						dma_rd_xfer_done_i,
						dma_rd_done_entry_i,
						dma_rd_xfer_done_ack_o,
						
						/*************ouyang***************/
						//response queue interface
						response_queue_empty_o,
	          response_queue_data_o,
  					response_queue_rd_en_i ,//read enable signal for response queue
  					/**********************************/
            );
                    

	

	parameter			WR_REQ_Q_RST = 10'b00_0000_0001;
	parameter			WR_REQ_Q_FETCH_DW0_3 = 10'b00_0000_0010;
	parameter			WR_REQ_Q_FETCH_DW4_7 = 10'b00_0000_0100;
	parameter			WR_REQ_Q_FETCH_DW8_11 = 10'b00_0000_1000;
	parameter			WR_REQ_Q_FETCH_DW12_15 = 10'b00_0001_0000;
	parameter			WR_REQ_Q_FETCH_DW16_19 = 10'b00_0010_0000;
	parameter			WR_REQ_Q_FETCH_DW20_23 = 10'b00_0100_0000;
	parameter			WR_REQ_Q_FETCH_DW24_27 = 10'b00_1000_0000;
	parameter			WR_REQ_Q_FETCH_DW28_31 = 10'b01_0000_0000;
	parameter			WR_REQ_Q_WAIT = 10'b10_0000_0000;
	
	parameter			WR_REQ_RST = 4'b0000;
	parameter			WR_REQ_DECODE = 4'b0001;	
	parameter			WR_REQ_PREPARE = 4'b0010;
	parameter			WR_REQ_DMA_CONFIG1 = 4'b0011;
	parameter			WR_REQ_DMA_CONFIG2 = 4'b0100;
	parameter			WR_REQ_DMA_CONFIG3 = 4'b0101;
	parameter			WR_REQ_DMA_CONFIG4 = 4'b0110;
	parameter			WR_REQ_DMA_START = 4'b0111;
	parameter			WR_REQ_DMA_WAIT = 4'b1000;
	parameter			WR_REQ_DMA_CLEAR = 4'b1001;
	parameter			WR_REQ_DMA_CLEAR_ACK = 4'b1010;
	parameter			WR_REQ_DONE = 4'b1011;	

	parameter			WR_REQ_DONE_RST = 5'b00001;	
	parameter			WR_REQ_DONE_WR_CMD = 5'b00010;
	parameter			WR_REQ_DONE_WR_CMD_ACK = 5'b00100;
	parameter			WR_REQ_DONE_WR_RESP = 5'b01000;
	parameter			WR_REQ_DONE_WR_RESP_ACK = 5'b10000;
	
	parameter			RD_REQ_RST = 5'b00000;
	parameter			RD_REQ_FETCH_DW0_3 = 5'b00001;
	parameter			RD_REQ_FETCH_DW4_7 = 5'b00010;
	parameter			RD_REQ_FETCH_DW8_11 = 5'b00011;
	parameter			RD_REQ_FETCH_DW12_15 = 5'b00100;
	parameter			RD_REQ_FETCH_DW16_19 = 5'b00101;
	parameter			RD_REQ_FETCH_DW20_23 = 5'b00110;
	parameter			RD_REQ_FETCH_DW24_27 = 5'b00111;
	parameter			RD_REQ_FETCH_DW28_31 = 5'b01000;
	parameter			RD_REQ_DECODE = 5'b01001;
	parameter			RD_REQ_GET_ENTRY = 5'b01010;
	parameter			RD_REQ_GET_ENTRY_ST1 = 5'b01011;
	parameter			RD_REQ_GET_ENTRY_ST2 = 5'b01100;
	parameter			RD_REQ_GET_ENTRY_ST3 = 5'b01101;
	parameter			RD_REQ_GET_ENTRY_ST4 = 5'b01110;
	parameter			RD_REQ_WRITE_ENTRY = 5'b01111;
	parameter			RD_REQ_PREPARE = 5'b10000;
	parameter			RD_REQ_WR_CMD = 5'b10001;
	parameter			RD_REQ_WR_CMD_ACK = 5'b10010;
	
	parameter			RD_REQ_DMA_RST = 4'b0000;
	parameter			RD_REQ_DMA_FETCH_CMD = 4'b0001;
	parameter			RD_REQ_DMA_CMD_DECODE = 4'b0010;
	parameter			RD_REQ_DMA_CONFIG1 = 4'b0011;
	parameter			RD_REQ_DMA_CONFIG2 = 4'b0100;
	parameter			RD_REQ_DMA_CONFIG3 = 4'b0101;
	parameter			RD_REQ_DMA_CONFIG4 = 4'b0110;
	parameter			RD_REQ_DMA_START = 4'b0111;
	parameter			RD_REQ_DMA_WAIT = 4'b1000;
	parameter			RD_REQ_DMA_CLEAR = 4'b1001;
	parameter			RD_REQ_DMA_CLEAR_ACK = 4'b1010;
	parameter			RD_REQ_DMA_DONE = 4'b1011;
	parameter			RD_REQ_DONE_CHECK = 4'b1100;
	parameter			RD_REQ_WR_RESP = 4'b1101;
	parameter			RD_REQ_WR_RESP_ACK = 4'b1110;

	/*************ouyang***************/
	//response queue interface
	output response_queue_empty_o;
	output [31:0] response_queue_data_o;
  input response_queue_rd_en_i ;//read enable signal for response queue		
	/*********************************/
	
	input				clk , rst_n , en;
	
	input [127:0]		rd_req_data_i , wr_req_data_i;
	output 				rd_req_rd_en_o , wr_req_rd_en_o;
	input				rd_req_empty_i , wr_req_empty_i;
	
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
	//input				bar1_wr_exclu2_i;
	//input				bar1_wr_busy2_i;
	
	output				bar1_wr_en3_o;
	output [6:0]		bar1_addr3_o;
	output [3:0]		bar1_wr_be3_o;
	output [31:0]		bar1_wr_d3_o;
	input				bar1_wr_ack3_n_i;
	//input				bar1_wr_exclu3_i;
	//input				bar1_wr_busy3_i;
	
	input				bar1_arbiter_busy_i;
	input				bar1_wr_busy_i;

	input				mrd_start_i , mwr_start_i;
	input				mrd_done_i , mwr_done_i;
	
	input				recv_fifo_av_i;
	
	input [15:0]		req_queue_depth_i;
	output				resp_empty_o;
	output [31:0]		resp_o;
	input				resp_rd_en_i;
	
	output				fatal_err_o;
	output				lba_ofr_err_o;
	output				prp_offset_err_o;
	output				id_ob_err_o;
	
	output				rd_req_done_o;
	output				wr_req_done_o;
		
	output				dma_rd_q_wr_en_o;
	output [63:0]		dma_rd_q_wr_data_o;
	input				dma_rd_q_full_i;
	input				dma_rd_xfer_done_i;
	input [63:0]		dma_rd_done_entry_i;
	output				dma_rd_xfer_done_ack_o;
	
	reg 				rd_req_rd_en_o , wr_req_rd_en_o;

	reg					CMGFTL_cmd_fifo_wr_en_o;
	reg [127:0]			CMGFTL_cmd_fifo_data_o;
	
	reg					FTLCMG_cmd_fifo_rd_en_o;
	
	reg					bar1_wr_en2_o;
	reg	[6:0]			bar1_addr2_o;
	reg [3:0]			bar1_wr_be2_o;
	reg [31:0]			bar1_wr_d2_o;
	
	reg					bar1_wr_en3_o;
	reg [6:0]			bar1_addr3_o;
	reg [3:0]			bar1_wr_be3_o;
	reg [31:0]			bar1_wr_d3_o;
	
	wire				resp_empty_o;
	wire [31:0]			resp_o;
	
	reg					rd_req_done_o;
	reg					wr_req_done_o;
	
	reg [127:0]			wr_req_dw0_3_q , wr_req_dw0_3;
	reg [127:0]			wr_req_dw4_7_q , wr_req_dw4_7;
	reg [127:0]			wr_req_dw8_11_q , wr_req_dw8_11;
	reg [127:0]			wr_req_dw12_15_q , wr_req_dw12_15;
	reg [127:0]			wr_req_dw16_19_q , wr_req_dw16_19;
	reg [127:0]			wr_req_dw20_23_q , wr_req_dw20_23;
	reg [127:0]			wr_req_dw24_27_q , wr_req_dw24_27;
	reg [127:0]			wr_req_dw28_31_q , wr_req_dw28_31;
	
	reg [127:0]			rd_req_dw0_3;
	reg [127:0]			rd_req_dw4_7;
	reg [127:0]			rd_req_dw8_11;
	reg [127:0]			rd_req_dw12_15;
	reg [127:0]			rd_req_dw16_19;
	reg [127:0]			rd_req_dw20_23;
	reg [127:0]			rd_req_dw24_27;
	reg [127:0]			rd_req_dw28_31;
	
	wire [127:0]		rd_req_data_i_sw , wr_req_data_i_sw;
	
	reg					wr_req_q_empty;
	reg					wr_req_empty , wr_req_empty_prev;
	
	//reg					rd_req_empty;
	
	reg 				WrReqFTL_cmd_fifo_wr_en , RdReqFTL_cmd_fifo_wr_en;
	reg [127:0]			WrReqFTL_cmd_fifo_data , RdReqFTL_cmd_fifo_data;
	reg					WrReqFTL_cmd_fifo_wr_ack_n , RdReqFTL_cmd_fifo_wr_ack_n;	
	
	reg					RespQ_wr_en;
	reg [31:0]			RespQ_wr_data;
	
	wire 				RespQ_full;
	
	reg					WrReq_RespQ_wr_en , RdReq_RespQ_wr_en;
	reg [31:0]			WrReq_RespQ_wr_data , RdReq_RespQ_wr_data;
	reg					WrReq_RespQ_wr_ack_n , RdReq_RespQ_wr_ack_n;
	
	`ifdef DEBUG
	reg [13:0]			resp_tag;
	`endif
	
	reg					wr_fatal_err;
	wire				wr_lba_ofr_err = 1'b0;
	wire				wr_prp_offset_err = 1'b0;
	reg					wr_id_ob_err;
	
	wire				rd_fatal_err;
	wire				rd_lba_ofr_err;
	wire				rd_prp_offset_err;
	wire				rd_id_ob_err;
	
	reg [9:0]			wr_req_dma_cnt , rd_req_dma_cnt;
	reg [15:0]			wr_req_id , rd_req_id;
	reg [31:0]			wr_req_lba , rd_req_lba;
	reg [31:0]			wr_req_len , rd_req_len;
	
	reg [31:0]			wr_req_prp_pending , rd_req_prp_pending;
	reg [31:0]			wr_req_lba_pending , rd_req_lba_pending;
	
	reg					rd_req_entry_flag [`RD_REQ_BUF_TBSIZE - 1:0];
	reg					rd_req_done_flag [`RD_REQ_BUF_TBSIZE - 1:0];
	reg [15:0]			rd_req_entry_id [`RD_REQ_BUF_TBSIZE - 1:0];
	reg [31:0]			rd_req_total_size [`RD_REQ_BUF_TBSIZE - 1:0];
	reg [31:0]			rd_req_sent_size [`RD_REQ_BUF_TBSIZE - 1:0];
	
	reg [`RD_REQ_BUF_TBSIZ_ORDER:0]	rd_cnt , rd_cnt2;
	reg [`RD_REQ_BUF_TBSIZ_ORDER:0]		entry_used;
	reg [`RD_REQ_BUF_TBSIZ_ORDER - 1:0]	free_index;
	reg [`RD_REQ_BUF_TBSIZ_ORDER - 1:0]	done_index;
	
	reg					rd_req_done , rd_req_done_prev;
	reg	[127:0]			rd_req_cmd;
	reg [15:0]			rd_req_cmd_id;
	reg [31:0]			rd_req_cmd_prp;
	
	reg					dma_rd_q_wr_en_o;
	reg [63:0]			dma_rd_q_wr_data_o;

	reg					dma_rd_xfer_done_q;
	reg					dma_rd_xfer_done_ack_o;
	
	reg [9:0]			wr_req_q_state;
	reg	[3:0]			wr_req_state;
	reg [4:0]			wr_req_done_state;
	
	reg [4:0]			rd_req_state;
	reg [3:0]			rd_req_dma_state;
	
	wire				srst = !rst_n | !en;
	
	
	assign 				wr_req_data_i_sw = { wr_req_data_i[103:96] , wr_req_data_i[111:104] , wr_req_data_i[119:112] , wr_req_data_i[127:120] ,
											 wr_req_data_i[71:64] , wr_req_data_i[79:72] , wr_req_data_i[87:80] , wr_req_data_i[95:88] ,
											 wr_req_data_i[39:32] , wr_req_data_i[47:40] , wr_req_data_i[55:48] , wr_req_data_i[63:56] ,
											 wr_req_data_i[7:0] , wr_req_data_i[15:8] , wr_req_data_i[23:16] , wr_req_data_i[31:24] };

	assign 				rd_req_data_i_sw = { rd_req_data_i[103:96] , rd_req_data_i[111:104] , rd_req_data_i[119:112] , rd_req_data_i[127:120] ,
											 rd_req_data_i[71:64] , rd_req_data_i[79:72] , rd_req_data_i[87:80] , rd_req_data_i[95:88] ,
											 rd_req_data_i[39:32] , rd_req_data_i[47:40] , rd_req_data_i[55:48] , rd_req_data_i[63:56] ,
											 rd_req_data_i[7:0] , rd_req_data_i[15:8] , rd_req_data_i[23:16] , rd_req_data_i[31:24] };													 
	
	assign 			fatal_err_o = wr_fatal_err | rd_fatal_err;
	assign			lba_ofr_err_o = wr_lba_ofr_err | rd_lba_ofr_err;
	assign			prp_offset_err_o = wr_prp_offset_err | rd_prp_offset_err;
	assign			id_ob_err_o = wr_id_ob_err | rd_id_ob_err;
	
	assign			wr_req_err = wr_fatal_err | wr_lba_ofr_err | wr_prp_offset_err | wr_id_ob_err;
	assign			rd_req_err = rd_fatal_err | rd_lba_ofr_err | rd_prp_offset_err | rd_id_ob_err;
	
	// response queue
	// DEPTH: 128
	// WIDTH: 32
	/*
	RESPONSE_QUEUE CPM_RESPQ (
							  .clk( clk ), // input clk
							  .srst( srst ), // input srst
							  .din( RespQ_wr_data ), // input [31 : 0] din
							  .wr_en( RespQ_wr_en ), // input wr_en
							  .rd_en( resp_rd_en_i ), // input rd_en
							  .dout( resp_o ), // output [31 : 0] dout
							  .full( RespQ_full ), // output full
							  .empty( resp_empty_o ) // output empty
	);*/
	/***********************ouyang***********************************/
	assign resp_o = 0;
	assign resp_empty_o = 0;
	RESPONSE_QUEUE CPM_RESPQ (
							  .clk( clk ), // input clk
							  .srst( srst ), // input srst
							  .din( RespQ_wr_data ), // input [31 : 0] din
							  .wr_en( RespQ_wr_en ), // input wr_en
							  .rd_en( response_queue_rd_en_i ), // input rd_en
							  .dout( response_queue_data_o ), // output [31 : 0] dout
							  .full( RespQ_full ), // output full
							  .empty( response_queue_empty_o ) // output empty
	);
	/**********************************************************/
	
	
	
	//fetch write request from write requset queue to wr_req_dw*_*_q register
	//
	always @ ( posedge clk ) begin
		
		if( !rst_n | !en ) begin

			wr_req_rd_en_o <= 1'b0;
			wr_req_q_empty <= 1'b1;
			
			wr_req_dw0_3_q <= 32'b0;
			wr_req_dw4_7_q <= 32'b0;
			wr_req_dw8_11_q <= 32'b0;
			wr_req_dw12_15_q <= 32'b0;
			wr_req_dw16_19_q <= 32'b0;
			wr_req_dw20_23_q <= 32'b0;
			wr_req_dw24_27_q <= 32'b0;
			wr_req_dw28_31_q <= 32'b0;
			
			wr_req_q_state <= WR_REQ_Q_RST;				
				
		end 
		else begin
		
			case ( wr_req_q_state )
			
			WR_REQ_Q_RST: begin
			
				if( wr_req_q_empty &&  !wr_req_empty_i ) begin
				
					wr_req_rd_en_o <= 1'b1;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW0_3;					
					
				end
			end
				
			WR_REQ_Q_FETCH_DW0_3: begin
			
					wr_req_dw0_3_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW4_7;
					
			end
			
			WR_REQ_Q_FETCH_DW4_7: begin
			
					wr_req_dw4_7_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW8_11;
					
			end
			
			WR_REQ_Q_FETCH_DW8_11: begin
			
					wr_req_dw8_11_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW12_15;
					
			end
			
			WR_REQ_Q_FETCH_DW12_15: begin
			
					wr_req_dw12_15_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW16_19;
					
			end

			WR_REQ_Q_FETCH_DW16_19: begin
			
					wr_req_dw16_19_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW20_23;
					
			end

			WR_REQ_Q_FETCH_DW20_23: begin
			
					wr_req_dw20_23_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW24_27;
					
			end

			WR_REQ_Q_FETCH_DW24_27: begin			
					
					wr_req_dw24_27_q <= wr_req_data_i_sw;					
					
					wr_req_q_state <= WR_REQ_Q_FETCH_DW28_31;
					
			end

			WR_REQ_Q_FETCH_DW28_31: begin
			
					wr_req_dw28_31_q <= wr_req_data_i_sw;
					wr_req_q_empty <= 1'b0;
					
					wr_req_rd_en_o <= 1'b0;

					wr_req_q_state <= WR_REQ_Q_WAIT;
					
			end

			WR_REQ_Q_WAIT: begin
			
				if( !wr_req_empty && wr_req_empty_prev ) begin
				
					wr_req_q_empty <= 1'b1;
					wr_req_q_state <= WR_REQ_Q_RST;
				
				end
			
			end
			
			default: begin
			
				wr_req_rd_en_o <= 1'b0;
				wr_req_q_empty <= 1'b1;
				
				wr_req_q_state <= WR_REQ_Q_RST;
			
			end
			
			endcase
		
		end //if( !rst_n | !en )
	end
	
	//write receive cmd fifo arbitration between write request and read request
	//
	always @ ( * ) begin
	
		if( !rst_n || !en ) begin
		
			CMGFTL_cmd_fifo_wr_en_o = 1'b0;
			CMGFTL_cmd_fifo_data_o = 128'b0;
			
			WrReqFTL_cmd_fifo_wr_ack_n = 1'b1;
			RdReqFTL_cmd_fifo_wr_ack_n = 1'b1;	
			
		end 
		else begin
		
			if( WrReqFTL_cmd_fifo_wr_en ) begin
			
				CMGFTL_cmd_fifo_wr_en_o = WrReqFTL_cmd_fifo_wr_en;
				CMGFTL_cmd_fifo_data_o = WrReqFTL_cmd_fifo_data;
				
				WrReqFTL_cmd_fifo_wr_ack_n = 1'b0;
				RdReqFTL_cmd_fifo_wr_ack_n = 1'b1;
			
			end
			else if( RdReqFTL_cmd_fifo_wr_en ) begin
			
				CMGFTL_cmd_fifo_wr_en_o = RdReqFTL_cmd_fifo_wr_en;
				CMGFTL_cmd_fifo_data_o = RdReqFTL_cmd_fifo_data;
				
				WrReqFTL_cmd_fifo_wr_ack_n = 1'b1;
				RdReqFTL_cmd_fifo_wr_ack_n = 1'b0;				
			
			end
			else begin
			
				CMGFTL_cmd_fifo_wr_en_o = 1'b0;
				CMGFTL_cmd_fifo_data_o = 128'b0;
			
				WrReqFTL_cmd_fifo_wr_ack_n = 1'b1;
				RdReqFTL_cmd_fifo_wr_ack_n = 1'b1;	
			
			end //if( WrReqFTL_cmd_fifo_wr_en )
		
		end //if( !rst_n || !en )
	
	end
	
	`ifdef DEBUG
		always @ ( posedge clk ) begin
		
			if( !rst_n || !en ) begin			
				resp_tag <= 14'b0;				
			end else begin
				if( RespQ_wr_en )
					resp_tag <= resp_tag + 1'b1;
			end
			
		end
	`endif
	
	
	//write response message arbitration between write request and read request
	//
	always @ ( * ) begin
	
		if( !rst_n || !en ) begin
		
			RespQ_wr_en = 1'b0;
			RespQ_wr_data = 32'b0;
			
			WrReq_RespQ_wr_ack_n = 1'b1;
			RdReq_RespQ_wr_ack_n = 1'b1;
		
		end
		else begin
		
			if( RdReq_RespQ_wr_en ) begin
			
				RespQ_wr_en = RdReq_RespQ_wr_en;
				RespQ_wr_data = RdReq_RespQ_wr_data;
				
				WrReq_RespQ_wr_ack_n = 1'b1;
				RdReq_RespQ_wr_ack_n = 1'b0;			
			
			end
			else if( WrReq_RespQ_wr_en ) begin
			
				RespQ_wr_en = WrReq_RespQ_wr_en;
				RespQ_wr_data = WrReq_RespQ_wr_data;
				
				WrReq_RespQ_wr_ack_n = 1'b0;
				RdReq_RespQ_wr_ack_n = 1'b1;			
						
			end
			else begin
			
				RespQ_wr_en = 1'b0;
				RespQ_wr_data = 32'b0;
				
				WrReq_RespQ_wr_ack_n = 1'b1;
				RdReq_RespQ_wr_ack_n = 1'b1;
				
			end //if( RdReq_RespQ_wr_en )
		
		end //if( !rst_n || !en ) 
	
	end
	
	//write request error check
	//
	always @ ( * ) begin
	
		if( !rst_n || !en ) begin
		
			wr_fatal_err = 1'b0;
			//wr_lba_ofr_err = 1'b0;
			//wr_prp_offset_err = 1'b0;
			wr_id_ob_err = 1'b0;
			
		end
		else begin
		
			if( !wr_req_empty ) begin
			
				if( wr_req_dw0_3[111:96] >= req_queue_depth_i )
					wr_id_ob_err = 1'b1;
				else
					wr_id_ob_err = 1'b0;
					
				if( ( wr_req_dw0_3[63:32] >> `PAGE_SIZE_ORDER ) > `REQ_PRP_NUMS )
					wr_fatal_err = 1'b1;
				else
					wr_fatal_err = 1'b0;
			
			end
			else begin
			
				wr_fatal_err = 1'b0;
				//wr_lba_ofr_err = 1'b0;
				//wr_prp_offset_err = 1'b0;
				wr_id_ob_err = 1'b0;
							
			end
		
		end //if( !rst_n || !en )
	
	end
	
	// this state machine fetch write request and then process 
	// the request through DMA until the request is finished
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n || !en ) begin
		
			wr_req_empty <= 1'b1;
			wr_req_empty_prev <= 1'b1;
			
			wr_req_dw0_3 <= 128'b0;
			wr_req_dw4_7 <= 128'b0;
			wr_req_dw8_11 <= 128'b0;
			wr_req_dw12_15 <= 128'b0;
			wr_req_dw16_19 <= 128'b0;
			wr_req_dw20_23 <= 128'b0;
			wr_req_dw24_27 <= 128'b0;
			wr_req_dw28_31 <= 128'b0;
			
			//WrReqFTL_cmd_fifo_wr_en <= 1'b0;
			//WrReqFTL_cmd_fifo_data <= 128'b0;
			
			//WrReq_RespQ_wr_en <= 1'b0;
			//WrReq_RespQ_wr_data <= 32'b0;
			
			bar1_wr_en2_o <= 1'b0;
			bar1_addr2_o <= 7'b0;
			bar1_wr_be2_o <= 4'b0;
			bar1_wr_d2_o <= 32'b0;

			//wr_req_done_o <= 1'b0;
			
			wr_req_id <= 16'b0;
			wr_req_lba <= 32'b0;
			wr_req_len <= 32'b0;
			
			wr_req_dma_cnt <= 10'b0;
			
			wr_req_lba_pending <= 32'b0;
			wr_req_prp_pending <= 32'b0;
			
			dma_rd_q_wr_en_o <= 1'b0;
			dma_rd_q_wr_data_o <= 64'b0;				
			
			wr_req_state <= WR_REQ_RST;
		
		end 
		else begin
		
			wr_req_empty_prev <= wr_req_empty;
			
			dma_rd_q_wr_en_o <= 1'b0;
			dma_rd_q_wr_data_o <= 64'b0;				
		
			case ( wr_req_state )
			
				WR_REQ_RST: begin
				
					//wr_req_done_o <= 1'b0;	
				
					if( !wr_req_q_empty && wr_req_empty ) begin
					
						wr_req_empty <= 1'b0;											
						
						wr_req_dw0_3 <= wr_req_dw0_3_q;
						wr_req_dw4_7 <= wr_req_dw4_7_q;
						wr_req_dw8_11 <= wr_req_dw8_11_q;
						wr_req_dw12_15 <= wr_req_dw12_15_q;
						wr_req_dw16_19 <= wr_req_dw16_19_q;
						wr_req_dw20_23 <= wr_req_dw20_23_q;
						wr_req_dw24_27 <= wr_req_dw24_27_q;
						wr_req_dw28_31 <= wr_req_dw28_31_q;						

						wr_req_state <= WR_REQ_DECODE;
					
					end
				end
					
				WR_REQ_DECODE: begin
					
						wr_req_id <= wr_req_dw0_3[111:96];
						wr_req_lba <= wr_req_dw0_3[95:64];
						wr_req_len <= wr_req_dw0_3[63:32];
						
						wr_req_dma_cnt <= 0;
						
						//if( wr_req_err )
						//	wr_req_state <= WR_REQ_DONE;
						//else
							wr_req_state <= WR_REQ_PREPARE;
				
				end
				
				WR_REQ_PREPARE: begin
				
					if( wr_req_dma_cnt == 0 )
						wr_req_lba_pending <= wr_req_lba;
					else
						wr_req_lba_pending <= wr_req_lba_pending + 1;
						
					case ( wr_req_dma_cnt[4:2] )
					
						3'b000: begin
						
							case ( wr_req_dma_cnt[1:0] )
							
								2'b00: wr_req_prp_pending <= wr_req_dw8_11[127:96];
								2'b01: wr_req_prp_pending <= wr_req_dw8_11[95:64];
								2'b10: wr_req_prp_pending <= wr_req_dw8_11[63:32];
								2'b11: wr_req_prp_pending <= wr_req_dw8_11[31:0];								
							
							endcase
						
						end
					
						3'b001: begin
						
							case ( wr_req_dma_cnt[1:0] )
							
								2'b00: wr_req_prp_pending <= wr_req_dw12_15[127:96];
								2'b01: wr_req_prp_pending <= wr_req_dw12_15[95:64];
								2'b10: wr_req_prp_pending <= wr_req_dw12_15[63:32];
								2'b11: wr_req_prp_pending <= wr_req_dw12_15[31:0];								
							
							endcase
						
						end
					
						3'b010: begin
						
							case ( wr_req_dma_cnt[1:0] )
							
								2'b00: wr_req_prp_pending <= wr_req_dw16_19[127:96];
								2'b01: wr_req_prp_pending <= wr_req_dw16_19[95:64];
								2'b10: wr_req_prp_pending <= wr_req_dw16_19[63:32];
								2'b11: wr_req_prp_pending <= wr_req_dw16_19[31:0];								
							
							endcase
						
						end	
					
						3'b011: begin
						
							case ( wr_req_dma_cnt[1:0] )
							
								2'b00: wr_req_prp_pending <= wr_req_dw20_23[127:96];
								2'b01: wr_req_prp_pending <= wr_req_dw20_23[95:64];
								2'b10: wr_req_prp_pending <= wr_req_dw20_23[63:32];
								2'b11: wr_req_prp_pending <= wr_req_dw20_23[31:0];								
							
							endcase
						
						end
					
						3'b100: begin
						
							case ( wr_req_dma_cnt[1:0] )
							
								2'b00: wr_req_prp_pending <= wr_req_dw24_27[127:96];
								2'b01: wr_req_prp_pending <= wr_req_dw24_27[95:64];
								2'b10: wr_req_prp_pending <= wr_req_dw24_27[63:32];
								2'b11: wr_req_prp_pending <= wr_req_dw24_27[31:0];								
							
							endcase
						
						end	
					
						3'b101: begin
						
							case ( wr_req_dma_cnt[1:0] )
							
								2'b00: wr_req_prp_pending <= wr_req_dw28_31[127:96];
								2'b01: wr_req_prp_pending <= wr_req_dw28_31[95:64];
								2'b10: wr_req_prp_pending <= wr_req_dw28_31[63:32];
								2'b11: wr_req_prp_pending <= wr_req_dw28_31[31:0];								
							
							endcase
						
						end

						default: wr_req_prp_pending <= 32'b0;
					
					endcase
					
					wr_req_state <= WR_REQ_DMA_CONFIG1;
				
				end
				
				WR_REQ_DMA_CONFIG1: begin
				
					if( !mrd_start_i && !bar1_arbiter_busy_i && recv_fifo_av_i && !bar1_wr_busy_i && !dma_rd_q_full_i ) begin
					
						bar1_wr_en2_o <= 1'b1;
						bar1_addr2_o <= `DMA_RD_SIZE_REG;
						bar1_wr_be2_o <= 4'b1111;
						bar1_wr_d2_o <= `PAGE_SIZE;

						wr_req_state <= WR_REQ_DMA_CONFIG2;
					
					end
				
				end
				
				WR_REQ_DMA_CONFIG2: begin
				
					if( !bar1_wr_ack2_n_i ) begin
					
						if( !bar1_wr_busy_i ) begin
							
							bar1_wr_en2_o <= 1'b1;
							bar1_addr2_o <= `DMA_RD_ADDR_REG;
							bar1_wr_be2_o <= 4'b1111;
							bar1_wr_d2_o <= { wr_req_prp_pending[31:2] , 2'b0 };
							
							wr_req_dma_cnt <= wr_req_dma_cnt + 1;
							
							wr_req_state <= WR_REQ_DMA_CONFIG3;							
						
						end
					
					end
					else begin
					
						bar1_wr_en2_o <= 1'b0;
						
						wr_req_state <= WR_REQ_DMA_CONFIG1;
					
					end //if( !bar1_wr_ack2_n_i )
				
				end
					
				WR_REQ_DMA_CONFIG3: begin
					
					if( !bar1_wr_busy_i ) begin
						
						bar1_wr_en2_o <= 1'b1;
						bar1_addr2_o <= `DMA_RD_UPADDR_REG;
						bar1_wr_be2_o <= 4'b1111;
						
						if( wr_req_prp_pending[1:0] != 0 )
							bar1_wr_d2_o <= { 6'b0 , wr_req_prp_pending[1:0] , 4'b0 , 1'b1 , 19'b0 };
						else
							bar1_wr_d2_o <= 32'b0;

						wr_req_state <= WR_REQ_DMA_CONFIG4;							
					
					end					
					
				end
				
				WR_REQ_DMA_CONFIG4: begin
				
					if( !bar1_wr_busy_i ) begin
						
						bar1_wr_en2_o <= 1'b1;
						bar1_addr2_o <= `DMA_CTRL_STA_REG;
						bar1_wr_be2_o <= 4'b1100;
						bar1_wr_d2_o <= { 15'b0 , 1'b1 , 16'b0 };
						
						dma_rd_q_wr_en_o <= 1'b1;
						if( wr_req_dma_cnt == ( wr_req_len >> `PAGE_SIZE_ORDER ) )
							dma_rd_q_wr_data_o <= wr_req_lba_pending | { wr_req_id , 32'b0 } | (3 << 62);
						else
							dma_rd_q_wr_data_o <= wr_req_lba_pending | (1 << 63);

						wr_req_state <= WR_REQ_DMA_START;							
					
					end					
				
				end
				
				WR_REQ_DMA_START: begin
				
					if( !bar1_wr_busy_i ) begin
					
						bar1_wr_en2_o <= 1'b0;
						wr_req_state <= WR_REQ_DMA_WAIT;
					
					end
				
				end
				
				WR_REQ_DMA_WAIT: begin
				
					if( mrd_start_i && mrd_done_i ) begin
						
						wr_req_state <= WR_REQ_DMA_CLEAR;
						
					end
				
				end				
				
				WR_REQ_DMA_CLEAR: begin
				
					if( !bar1_arbiter_busy_i ) begin
						
						bar1_wr_en2_o <= 1'b1;
						bar1_addr2_o <= `DMA_CTRL_STA_REG;
						bar1_wr_be2_o <= 4'b1100;
						bar1_wr_d2_o <= 32'b0;
						
						wr_req_state <= WR_REQ_DMA_CLEAR_ACK;
						
					end
				
				end
				
				WR_REQ_DMA_CLEAR_ACK: begin
				
					if( !bar1_wr_ack2_n_i ) begin
					
						if( !bar1_wr_busy_i ) begin
						
							bar1_wr_en2_o <= 1'b0;
							wr_req_state <= WR_REQ_DONE;							
						
						end
					
					end
					else begin
					
						bar1_wr_en2_o <= 1'b0;
						wr_req_state <= WR_REQ_DMA_CLEAR;
					
					end //if( !bar1_wr_ack2_n_i )
				
				end
				
				WR_REQ_DONE: begin
					
					if( wr_req_dma_cnt == ( wr_req_len >> `PAGE_SIZE_ORDER ) ) begin
					
						wr_req_empty <= 1'b1;
						wr_req_state <= WR_REQ_RST;
						
					end
					else
						wr_req_state <= WR_REQ_PREPARE;
				end
				
				default: begin
				
					wr_req_state <= WR_REQ_RST;
					
				end
			
			endcase
		
		end //if( !rst_n || !en )
	
	end
	
	always @ ( posedge clk ) begin
	
		if( !rst_n || !en ) begin
		
			WrReqFTL_cmd_fifo_wr_en <= 1'b0;
			WrReqFTL_cmd_fifo_data <= 128'b0;
			
			WrReq_RespQ_wr_en <= 1'b0;
			WrReq_RespQ_wr_data <= 32'b0;
			
			dma_rd_xfer_done_q <= 1'b0;
			dma_rd_xfer_done_ack_o <= 1'b0;
			wr_req_done_o <= 1'b0;

			wr_req_done_state <= WR_REQ_DONE_RST;
		
		end else begin
		
			dma_rd_xfer_done_q <= dma_rd_xfer_done_i;
			
			case(wr_req_done_state)
			
				WR_REQ_DONE_RST: begin
				
					wr_req_done_o <= 1'b0;
				
					if( !dma_rd_xfer_done_q && dma_rd_xfer_done_i ) begin
					
						dma_rd_xfer_done_ack_o <= 1'b1;
						wr_req_done_state <= WR_REQ_DONE_WR_CMD;
					
					end
				
				end
				
				WR_REQ_DONE_WR_CMD: begin
				
					if( !CMGFTL_cmd_fifo_full_i && !RdReqFTL_cmd_fifo_wr_en ) begin
					
						WrReqFTL_cmd_fifo_wr_en <= 1'b1;
						WrReqFTL_cmd_fifo_data <= { 2'b01 , 94'b0 , dma_rd_done_entry_i[31:0] };
						
						wr_req_done_state <= WR_REQ_DONE_WR_CMD_ACK;
					
					end
				
				end
				
				WR_REQ_DONE_WR_CMD_ACK: begin
				
					WrReqFTL_cmd_fifo_wr_en <= 1'b0;
					
					if( !WrReqFTL_cmd_fifo_wr_ack_n ) begin
						if(dma_rd_done_entry_i[62])
							wr_req_done_state <= WR_REQ_DONE_WR_RESP;
						else begin
							dma_rd_xfer_done_ack_o <= 1'b0;
							wr_req_done_state <= WR_REQ_DONE_RST;
						end
					end
					else
						wr_req_done_state <= WR_REQ_DONE_WR_CMD;
				
				end	

				WR_REQ_DONE_WR_RESP: begin
				
					if( !RespQ_full && !RdReq_RespQ_wr_en ) begin
					
						WrReq_RespQ_wr_en <= 1'b1;
						`ifdef DEBUG
						WrReq_RespQ_wr_data <= { 1'b1 , wr_req_err , resp_tag , dma_rd_done_entry_i[47:32] };
						`else
						WrReq_RespQ_wr_data <= { 1'b1 , wr_req_err , 14'b0 , dma_rd_done_entry_i[47:32] };
						`endif
						
						wr_req_done_state <= WR_REQ_DONE_WR_RESP_ACK;
					
					end
				
				end
				
				WR_REQ_DONE_WR_RESP_ACK: begin
				
					WrReq_RespQ_wr_en <= 1'b0;
				
					if( !WrReq_RespQ_wr_ack_n )	 begin
					
						wr_req_done_o <= 1'b1;
						dma_rd_xfer_done_ack_o <= 1'b0;
						wr_req_done_state <= WR_REQ_DONE_RST;
						
					end
					else
						wr_req_done_state <= WR_REQ_DONE_WR_RESP;					
					
				end

				default:
					wr_req_done_state <= WR_REQ_DONE_RST;
					
			endcase
		
		end
	
	end
	
				
					
	
	
	// this state machine fetchs requests from read request queue and
	// decodes the request then sends corresponded 4K cmd to FTL cmd 
	// receive fifo.
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n || !en ) begin
		
			entry_used <= 0;
			
			rd_req_rd_en_o <= 1'b0;
			
			rd_req_dw0_3 <= 128'b0;
			rd_req_dw4_7 <= 128'b0;
			rd_req_dw8_11 <= 128'b0;
			rd_req_dw12_15 <= 128'b0;
			rd_req_dw16_19 <= 128'b0;
			rd_req_dw20_23 <= 128'b0;
			rd_req_dw24_27 <= 128'b0;
			rd_req_dw28_31 <= 128'b0;
			
			rd_req_id <= 16'b0;
			rd_req_lba <= 32'b0;
			rd_req_len <= 32'b0;
			
			rd_req_dma_cnt <= 10'b0;
			free_index <= 0;
			
			for( rd_cnt = 0 ; rd_cnt < `RD_REQ_BUF_TBSIZE ; rd_cnt = rd_cnt + 1 ) begin
			
				rd_req_entry_flag[rd_cnt] <= 1'b1;
				rd_req_entry_id[rd_cnt] <= 16'b0;
				rd_req_total_size[rd_cnt] <= 32'b0;
			
			end
			
			rd_req_lba_pending <= 32'b0;
			rd_req_prp_pending <= 32'b0;
			
			RdReqFTL_cmd_fifo_wr_en <= 1'b0;
			RdReqFTL_cmd_fifo_data <= 128'b0;
			
			rd_req_state <= RD_REQ_RST;
		
		end
		else begin
		
			if( rd_req_done && !rd_req_done_prev ) begin
			
				entry_used <= entry_used - 1'b1;
				rd_req_entry_flag[done_index] <= 1'b1;
				
			end
		
			case ( rd_req_state )
			
				RD_REQ_RST: begin
				
					if( !rd_req_empty_i ) begin
					
						rd_req_rd_en_o <= 1'b1;
						rd_req_state <= RD_REQ_FETCH_DW0_3;
					
					end
				
				end
				
				RD_REQ_FETCH_DW0_3: begin
				
					rd_req_dw0_3 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW4_7;
				
				end
				
				RD_REQ_FETCH_DW4_7: begin
				
					rd_req_dw4_7 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW8_11;	
					
				end
				
				RD_REQ_FETCH_DW8_11: begin
				
					rd_req_dw8_11 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW12_15;	
					
				end

				RD_REQ_FETCH_DW12_15: begin
				
					rd_req_dw12_15 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW16_19;	
					
				end

				RD_REQ_FETCH_DW16_19: begin
				
					rd_req_dw16_19 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW20_23;	
					
				end

				RD_REQ_FETCH_DW20_23: begin
				
					rd_req_dw20_23 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW24_27;	
					
				end

				RD_REQ_FETCH_DW24_27: begin
				
					rd_req_dw24_27 <= rd_req_data_i_sw;
					rd_req_state <= RD_REQ_FETCH_DW28_31;	
					
				end

				RD_REQ_FETCH_DW28_31: begin
				
					rd_req_dw28_31 <= rd_req_data_i_sw;
					rd_req_rd_en_o <= 1'b0;
					
					rd_req_state <= RD_REQ_DECODE;	
					
				end
				
				RD_REQ_DECODE: begin
				
					rd_req_id <= rd_req_dw0_3[111:96];
					rd_req_lba <= rd_req_dw0_3[95:64];
					rd_req_len <= rd_req_dw0_3[63:32];
					
					rd_req_dma_cnt <= 10'b0;
					
					rd_req_state <= RD_REQ_GET_ENTRY;
				
				end

				RD_REQ_GET_ENTRY: begin
				
					if( entry_used < `RD_REQ_BUF_TBSIZE ) begin
					
						if( rd_req_entry_flag[0] | rd_req_entry_flag[1] | rd_req_entry_flag[2] | rd_req_entry_flag[3] )
							rd_req_state <= RD_REQ_GET_ENTRY_ST1;
						else if( rd_req_entry_flag[4] | rd_req_entry_flag[5] | rd_req_entry_flag[6] | rd_req_entry_flag[7] )
							rd_req_state <= RD_REQ_GET_ENTRY_ST2;
						else if( rd_req_entry_flag[8] | rd_req_entry_flag[9] | rd_req_entry_flag[10] | rd_req_entry_flag[11] )
							rd_req_state <= RD_REQ_GET_ENTRY_ST3;
						else
							rd_req_state <= RD_REQ_GET_ENTRY_ST4;
					
					end
				
				end
				
				RD_REQ_GET_ENTRY_ST1: begin
				
					if( rd_req_entry_flag[0] )
						free_index <= 0;
					else if( rd_req_entry_flag[1] )
						free_index <= 1;
					else if( rd_req_entry_flag[2] )
						free_index <= 2;
					else
						free_index <= 3;

					rd_req_state <= RD_REQ_WRITE_ENTRY;
				
				end
				
				RD_REQ_GET_ENTRY_ST2: begin
				
					if( rd_req_entry_flag[4] )
						free_index <= 4;
					else if( rd_req_entry_flag[5] )
						free_index <= 5;
					else if( rd_req_entry_flag[6] )
						free_index <= 6;
					else
						free_index <= 7;

					rd_req_state <= RD_REQ_WRITE_ENTRY;
				
				end	
				
				RD_REQ_GET_ENTRY_ST3: begin
				
					if( rd_req_entry_flag[8] )
						free_index <= 8;
					else if( rd_req_entry_flag[9] )
						free_index <= 9;
					else if( rd_req_entry_flag[10] )
						free_index <= 10;
					else
						free_index <= 11;

					rd_req_state <= RD_REQ_WRITE_ENTRY;
				
				end

				RD_REQ_GET_ENTRY_ST4: begin
				
					if( rd_req_entry_flag[12] )
						free_index <= 12;
					else if( rd_req_entry_flag[13] )
						free_index <= 13;
					else if( rd_req_entry_flag[14] )
						free_index <= 14;
					else
						free_index <= 15;

					rd_req_state <= RD_REQ_WRITE_ENTRY;
				
				end

				RD_REQ_WRITE_ENTRY: begin
				
					entry_used <= entry_used + 1'b1;
					rd_req_entry_flag[free_index] <= 1'b0;
					
					rd_req_entry_id[free_index] <= rd_req_id;
					rd_req_total_size[free_index] <= rd_req_len;
					
					rd_req_state <= RD_REQ_PREPARE;
				
				end
				
				RD_REQ_PREPARE: begin
				
					if( rd_req_dma_cnt == 0 )
						rd_req_lba_pending <= rd_req_lba;
					else
						rd_req_lba_pending <= rd_req_lba_pending + 1;
				
					case ( rd_req_dma_cnt[4:2] )
					
						3'b000: begin
						
							case ( rd_req_dma_cnt[1:0] )
							
								2'b00: rd_req_prp_pending <= rd_req_dw8_11[127:96];
								2'b01: rd_req_prp_pending <= rd_req_dw8_11[95:64];
								2'b10: rd_req_prp_pending <= rd_req_dw8_11[63:32];
								2'b11: rd_req_prp_pending <= rd_req_dw8_11[31:0];								
							
							endcase
						
						end
					
						3'b001: begin
						
							case ( rd_req_dma_cnt[1:0] )
							
								2'b00: rd_req_prp_pending <= rd_req_dw12_15[127:96];
								2'b01: rd_req_prp_pending <= rd_req_dw12_15[95:64];
								2'b10: rd_req_prp_pending <= rd_req_dw12_15[63:32];
								2'b11: rd_req_prp_pending <= rd_req_dw12_15[31:0];								
							
							endcase
						
						end
					
						3'b010: begin
						
							case ( rd_req_dma_cnt[1:0] )
							
								2'b00: rd_req_prp_pending <= rd_req_dw16_19[127:96];
								2'b01: rd_req_prp_pending <= rd_req_dw16_19[95:64];
								2'b10: rd_req_prp_pending <= rd_req_dw16_19[63:32];
								2'b11: rd_req_prp_pending <= rd_req_dw16_19[31:0];								
							
							endcase
						
						end	
					
						3'b011: begin
						
							case ( rd_req_dma_cnt[1:0] )
							
								2'b00: rd_req_prp_pending <= rd_req_dw20_23[127:96];
								2'b01: rd_req_prp_pending <= rd_req_dw20_23[95:64];
								2'b10: rd_req_prp_pending <= rd_req_dw20_23[63:32];
								2'b11: rd_req_prp_pending <= rd_req_dw20_23[31:0];								
							
							endcase
						
						end
					
						3'b100: begin
						
							case ( rd_req_dma_cnt[1:0] )
							
								2'b00: rd_req_prp_pending <= rd_req_dw24_27[127:96];
								2'b01: rd_req_prp_pending <= rd_req_dw24_27[95:64];
								2'b10: rd_req_prp_pending <= rd_req_dw24_27[63:32];
								2'b11: rd_req_prp_pending <= rd_req_dw24_27[31:0];								
							
							endcase
						
						end	
					
						3'b101: begin
						
							case ( rd_req_dma_cnt[1:0] )
							
								2'b00: rd_req_prp_pending <= rd_req_dw28_31[127:96];
								2'b01: rd_req_prp_pending <= rd_req_dw28_31[95:64];
								2'b10: rd_req_prp_pending <= rd_req_dw28_31[63:32];
								2'b11: rd_req_prp_pending <= rd_req_dw28_31[31:0];								
							
							endcase
						
						end

						default: rd_req_prp_pending <= 32'b0;
					
					endcase
					
					rd_req_state <= RD_REQ_WR_CMD;
					
				end
				
				RD_REQ_WR_CMD: begin
				
					if( !CMGFTL_cmd_fifo_full_i && !WrReqFTL_cmd_fifo_wr_en ) begin
					
						RdReqFTL_cmd_fifo_wr_en <= 1'b1;
						//CMD format negotiated with FTL
						RdReqFTL_cmd_fifo_data <= { 2'b00 , 5'b0 , rd_req_prp_pending , 25'b0 , rd_req_id[12:0] , 19'b0 , rd_req_lba_pending };
						
						rd_req_state <= RD_REQ_WR_CMD_ACK;
					
					end
				
				end
				
				RD_REQ_WR_CMD_ACK: begin
				
					RdReqFTL_cmd_fifo_wr_en <= 1'b0;
					if( !RdReqFTL_cmd_fifo_wr_ack_n ) begin
					
						rd_req_dma_cnt <= rd_req_dma_cnt + 1;
						
						if( rd_req_dma_cnt + 1 == ( rd_req_len >> `PAGE_SIZE_ORDER ) )
							rd_req_state <= RD_REQ_RST;
						else
							rd_req_state <= RD_REQ_PREPARE;
					
					end
					else
						rd_req_state <= RD_REQ_WR_CMD;
				
				end
				
				default:
					rd_req_state <= RD_REQ_RST;
			
			endcase
		
		end
	
	end
	
	// this state machine fetch 4KB DMA write cmd from send cmd fifo 
	// and start DMA transfer.
	always @ ( posedge clk ) begin
	
		if( !rst_n || !en ) begin
		
			rd_req_done_prev <= 1'b0;
			rd_req_done <= 1'b0;
			rd_req_done_o <= 1'b0;
			
			FTLCMG_cmd_fifo_rd_en_o <= 1'b0;
			
			rd_req_cmd <= 128'b0;
			rd_req_cmd_id <= 16'b0;
			rd_req_cmd_prp <= 32'b0;
			
			bar1_wr_en3_o <= 1'b0;
			bar1_addr3_o <= 7'b0;
			bar1_wr_be3_o <= 4'b0;
			bar1_wr_d3_o <= 32'b0;
			
			for( rd_cnt2 = 0 ; rd_cnt2 < `RD_REQ_BUF_TBSIZE ; rd_cnt2 = rd_cnt2 + 1 ) begin
				rd_req_sent_size[rd_cnt2] <= 32'b0;
				rd_req_done_flag[rd_cnt2] <= 1'b0;
			end
			
			done_index <= 0;
			
			RdReq_RespQ_wr_en <= 1'b0;
			RdReq_RespQ_wr_data <= 32'b0;
			
			rd_req_dma_state <= RD_REQ_DMA_RST;
		
		end
		else begin
		
			rd_req_done_prev <= rd_req_done;
		
			case ( rd_req_dma_state )
			
				RD_REQ_DMA_RST: begin
				
					rd_req_done_o <= 1'b0;
					rd_req_done <= 1'b0;
				
					if( !FTLCMG_cmd_fifo_empty_i ) begin												
					
						FTLCMG_cmd_fifo_rd_en_o <= 1'b1;
						rd_req_dma_state <= RD_REQ_DMA_FETCH_CMD;
					
					end
				
				end
				
				RD_REQ_DMA_FETCH_CMD: begin
				
					FTLCMG_cmd_fifo_rd_en_o <= 1'b0;
					rd_req_cmd <= FTLCMG_cmd_fifo_data_i;
					
					rd_req_dma_state <= RD_REQ_DMA_CMD_DECODE;
				
				end
				
				RD_REQ_DMA_CMD_DECODE: begin
				
					rd_req_cmd_id <= rd_req_cmd[63:51];
					rd_req_cmd_prp <= rd_req_cmd[120:89];
					
					rd_req_dma_state <= RD_REQ_DMA_CONFIG1;
				
				end
			
				RD_REQ_DMA_CONFIG1: begin
			
					if( !mwr_start_i && !bar1_arbiter_busy_i ) begin
					
						bar1_wr_en3_o <= 1'b1;
						bar1_addr3_o <= `DMA_WR_SIZE_REG;
						bar1_wr_be3_o <= 4'b1111;
						bar1_wr_d3_o <= `PAGE_SIZE;

						rd_req_dma_state <= RD_REQ_DMA_CONFIG2;
					
					end
				
				end
				
				RD_REQ_DMA_CONFIG2: begin
				
					if( !bar1_wr_ack3_n_i ) begin
					
						if( !bar1_wr_busy_i ) begin
							
							bar1_wr_en3_o <= 1'b1;
							bar1_addr3_o <= `DMA_WR_ADDR_REG;
							bar1_wr_be3_o <= 4'b1111;
							bar1_wr_d3_o <= { rd_req_cmd_prp[31:2] , 2'b0 };

							rd_req_dma_state <= RD_REQ_DMA_CONFIG3;						
						
						end
					
					end
					else begin
					
						bar1_wr_en3_o <= 1'b0;
						
						rd_req_dma_state <= RD_REQ_DMA_CONFIG1;
					
					end //if( !bar1_wr_ack3_n_i )
				
				end	
					
				RD_REQ_DMA_CONFIG3: begin
					
					if( !bar1_wr_busy_i ) begin
						
						bar1_wr_en3_o <= 1'b1;
						bar1_addr3_o <= `DMA_WR_UPADDR_REG;
						bar1_wr_be3_o <= 4'b1111;
						
						if( rd_req_cmd_prp[1:0] != 0 )
							bar1_wr_d3_o <= { 6'b0 , rd_req_cmd_prp[1:0] , 4'b0 , 1'b1 , 19'b0 };
						else
							bar1_wr_d3_o <= 32'b0;

						rd_req_dma_state <= RD_REQ_DMA_CONFIG4;						
					
					end					
					
				end

				RD_REQ_DMA_CONFIG4: begin
				
					if( !bar1_wr_busy_i ) begin
						
						bar1_wr_en3_o <= 1'b1;
						bar1_addr3_o <= `DMA_CTRL_STA_REG;
						bar1_wr_be3_o <= 4'b0011;
						bar1_wr_d3_o <= { 16'b0 , 15'b0 , 1'b1 };

						rd_req_dma_state <= RD_REQ_DMA_START;						
					
					end					
				
				end
				
				RD_REQ_DMA_START: begin
				
					if( !bar1_wr_busy_i ) begin
					
						bar1_wr_en3_o <= 1'b0;
						rd_req_dma_state <= RD_REQ_DMA_WAIT;
					
					end
				
				end

				RD_REQ_DMA_WAIT: begin
				
					if( mwr_start_i && mwr_done_i ) begin
					
						rd_req_dma_state <= RD_REQ_DMA_CLEAR;
					
					end
				
				end
				
				RD_REQ_DMA_CLEAR: begin
				
					if( !bar1_arbiter_busy_i ) begin
						
						bar1_wr_en3_o <= 1'b1;
						bar1_addr3_o <= `DMA_CTRL_STA_REG;
						bar1_wr_be3_o <= 4'b0011;
						bar1_wr_d3_o <= 32'b0;
						
						rd_req_dma_state <= RD_REQ_DMA_CLEAR_ACK;
						
					end
								
				end
				
				RD_REQ_DMA_CLEAR_ACK: begin
				
					if( !bar1_wr_ack3_n_i ) begin
					
						if( !bar1_wr_busy_i ) begin
						
							bar1_wr_en3_o <= 1'b0;
							rd_req_dma_state <= RD_REQ_DMA_DONE;							
						
						end
					
					end
					else begin
					
						bar1_wr_en3_o <= 1'b0;
						rd_req_dma_state <= RD_REQ_DMA_CLEAR;
					
					end //if( !bar1_wr_ack3_n_i )
				
				end				
				
				RD_REQ_DMA_DONE: begin
				
					//rd_req_dma_state <= RD_REQ_DMA_RST;
				
					for( rd_cnt2 = 0 ; rd_cnt2 < `RD_REQ_BUF_TBSIZE ; rd_cnt2 = rd_cnt2 + 1 ) begin
					
						if( !rd_req_entry_flag[rd_cnt2] && (rd_req_cmd_id == rd_req_entry_id[rd_cnt2]) ) begin						
							
							//done_index <= rd_cnt2;
							
							if( rd_req_sent_size[rd_cnt2] + `PAGE_SIZE == rd_req_total_size[rd_cnt2] ) begin
					
								//rd_req_done <= 1'b1;
								rd_req_sent_size[rd_cnt2] <= 32'b0;
								rd_req_done_flag[rd_cnt2] <= 1'b1;
								//rd_req_dma_state <= RD_REQ_WR_RESP;
					
							end	else begin
							
								rd_req_sent_size[rd_cnt2] <= rd_req_sent_size[rd_cnt2] + `PAGE_SIZE;
								//rd_req_dma_state <= RD_REQ_DMA_RST;	
								
							end
						end
							
					end	

					rd_req_dma_state <= RD_REQ_DONE_CHECK;
				
				end
				
				RD_REQ_DONE_CHECK: begin
					/*
					rd_req_dma_state <= RD_REQ_DMA_RST;				
				
					if( rd_req_sent_size[done_index] == rd_req_total_size[done_index] ) begin
					
						rd_req_done <= 1'b1;
						rd_req_sent_size[done_index] <= 32'b0;
						
						rd_req_dma_state <= RD_REQ_WR_RESP;
					
					end
					
					if( rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15]
					  | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15]
					  | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15]
					  | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15] | rd_req_done_flag[15]
					  ) begin
					
						rd_req_done <= 1'b1;
						rd_req_done_flag <= 0;
						rd_req_dma_state <= RD_REQ_WR_RESP;
						
					end else
					
						rd_req_dma_state <= RD_REQ_DMA_RST;
					*/
						
					case({ rd_req_done_flag[15] , rd_req_done_flag[14] , rd_req_done_flag[13] , rd_req_done_flag[12]
					  , rd_req_done_flag[11] , rd_req_done_flag[10] , rd_req_done_flag[9] , rd_req_done_flag[8]
					  , rd_req_done_flag[7] , rd_req_done_flag[6] , rd_req_done_flag[5] , rd_req_done_flag[4]
					  , rd_req_done_flag[3] , rd_req_done_flag[2] , rd_req_done_flag[1] , rd_req_done_flag[0]
					  })
					
						16'b0000_0000_0000_0001: begin
							done_index <= 0;
							rd_req_done <= 1'b1;
							rd_req_done_flag[0] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;							
						end
						16'b0000_0000_0000_0010: begin
							done_index <= 1;
							rd_req_done <= 1'b1;
							rd_req_done_flag[1] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0000_0000_0100: begin
							done_index <= 2;
							rd_req_done <= 1'b1;
							rd_req_done_flag[2] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0000_0000_1000: begin
							done_index <= 3;
							rd_req_done <= 1'b1;
							rd_req_done_flag[3] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0000_0001_0000: begin
							done_index <= 4;
							rd_req_done <= 1'b1;
							rd_req_done_flag[4] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0000_0010_0000: begin 
							done_index <= 5;
							rd_req_done <= 1'b1;
							rd_req_done_flag[5] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0000_0100_0000: begin
							done_index <= 6;
							rd_req_done <= 1'b1;
							rd_req_done_flag[6] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0000_1000_0000: begin
							done_index <= 7;
							rd_req_done <= 1'b1;
							rd_req_done_flag[7] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0001_0000_0000: begin
							done_index <= 8;
							rd_req_done <= 1'b1;
							rd_req_done_flag[8] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0010_0000_0000: begin
							done_index <= 9;
							rd_req_done <= 1'b1;
							rd_req_done_flag[9] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_0100_0000_0000: begin
							done_index <= 10;
							rd_req_done <= 1'b1;
							rd_req_done_flag[10] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0000_1000_0000_0000: begin
							done_index <= 11;
							rd_req_done <= 1'b1;
							rd_req_done_flag[11] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0001_0000_0000_0000: begin
							done_index <= 12;
							rd_req_done <= 1'b1;
							rd_req_done_flag[12] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0010_0000_0000_0000: begin
							done_index <= 13;
							rd_req_done <= 1'b1;
							rd_req_done_flag[13] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b0100_0000_0000_0000: begin
							done_index <= 14;
							rd_req_done <= 1'b1;
							rd_req_done_flag[14] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						16'b1000_0000_0000_0000: begin
							done_index <= 15;
							rd_req_done <= 1'b1;
							rd_req_done_flag[15] <= 1'b0;
							rd_req_dma_state <= RD_REQ_WR_RESP;								
						end
						default: begin
							//done_index <= 0;
							//rd_req_done <= 1'b0;
							//rd_req_done_flag[0] <= 1'b0;
							rd_req_dma_state <= RD_REQ_DMA_RST;								
						end
							
					endcase
				
				end
				
				RD_REQ_WR_RESP: begin
				
					if( !RespQ_full && !WrReq_RespQ_wr_en ) begin
					
						RdReq_RespQ_wr_en <= 1'b1;
						`ifdef DEBUG
						RdReq_RespQ_wr_data <= { 1'b1 , 1'b0/*rd_req_err*/ , resp_tag, rd_req_cmd_id };
							`else
						RdReq_RespQ_wr_data <= { 1'b1 , 1'b0/*rd_req_err*/ , 14'b0 , rd_req_cmd_id };
						`endif
						
						rd_req_dma_state <= RD_REQ_WR_RESP_ACK;
					
					end
								
				end				
				
				RD_REQ_WR_RESP_ACK: begin
				
					RdReq_RespQ_wr_en <= 1'b0;
				
					if( !RdReq_RespQ_wr_ack_n )	begin
					
						rd_req_done_o <= 1'b1;
						rd_req_dma_state <= RD_REQ_DMA_RST;
						
					end
					else
						rd_req_dma_state <= RD_REQ_WR_RESP;					
					
				end

				default: begin
				
					rd_req_dma_state <= RD_REQ_DMA_RST;
				
				end
			
			endcase
		
		end
	
	end
	
	
endmodule
