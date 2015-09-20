//--------------------------------------------------------------------------------
//--
//-- This file is owned and controlled by Xilinx and must be used solely
//-- for design, simulation, implementation and creation of design files
//-- limited to Xilinx devices or technologies. Use with non-Xilinx
//-- devices or technologies is expressly prohibited and immediately
//-- terminates your license.
//--
//-- Xilinx products are not intended for use in life support
//-- appliances, devices, or systems. Use in such applications is
//-- expressly prohibited.
//--
//--            **************************************
//--            ** Copyright (C) 2009, Xilinx, Inc. **
//--            ** All Rights Reserved.             **
//--            **************************************
//--
//--------------------------------------------------------------------------------
//-- Filename: BMD_128_TX_ENGINE.v
//--
//-- Description: 128 bit Local-Link Transmit Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`include "CM_HEAD.v"

`define BMD_128_CPLD_FMT_TYPE   7'b10_01010
`define BMD_128_MWR_FMT_TYPE    7'b10_00000
`define BMD_128_MWR64_FMT_TYPE  7'b11_00000
`define BMD_128_MRD_FMT_TYPE    7'b00_00000
`define BMD_128_MRD64_FMT_TYPE  7'b01_00000

`define BMD_128_TX_RST_STATE    3'b001
`define BMD_128_TX_CPLD_WIT     3'b010
`define BMD_128_TX_MWR_QWN      3'b100
/*************ouyang***************/
`define BMD_128_TX_INTERRUPUT   3'b110 
`define CUR_RESPONSE_OFFSET     3'b101
`define RESPONSE_INFORMATION    3'b011
/**********************************/
module BMD_TX_ENGINE (

                        clk,
                        rst_n,

                        trn_td,
                        trn_trem_n,
                        trn_tsof_n,
                        trn_teof_n,
                        trn_tsrc_rdy_n,
                        trn_tsrc_dsc_n,
                        trn_tdst_rdy_n,
                        trn_tdst_dsc_n,
                        trn_tbuf_av,

                        req_compl_i,    
                        compl_done_o,  

                        req_tc_i,     
                        req_td_i,    
                        req_ep_i,   
                        req_attr_i,
                        req_len_i,         
                        req_rid_i,        
                        req_tag_i,       
                        req_be_i,
                        req_addr_i,     

                        // BMD Read Access

                        rd_addr_o,   
                        rd_be_o,    
                        rd_data_i,


                        // Initiator Reset
          
                        init_rst_i,

                        // Write Initiator

                        mwr_start_i,
                        mwr_len_i,
                        mwr_tag_i,
                        mwr_lbe_i,
                        mwr_fbe_i,
                        mwr_addr_i,
                        mwr_size_i,
                        mwr_done_o,
                        mwr_tlp_tc_i,
                        mwr_64b_en_i,
                        mwr_phant_func_dis1_i,
                        mwr_up_addr_i,
                        mwr_relaxed_order_i,
                        mwr_nosnoop_i,
                        mwr_wrr_cnt_i,
						mwr_done_clr,

                        // Read Initiator

                        mrd_start_i,
                        mrd_len_i,
                        mrd_tag_i,
                        mrd_lbe_i,
                        mrd_fbe_i,
                        mrd_addr_i,
                        mrd_size_i,
                        mrd_tlp_tc_i,
                        mrd_64b_en_i,
                        mrd_phant_func_dis1_i,
                        mrd_up_addr_i,
                        mrd_relaxed_order_i,
                        mrd_nosnoop_i,
                        mrd_wrr_cnt_i,
						mrd_done_clr,
						mrd_done,
						
						tdata_i,
						tdata_wr_en_i,
						tdata_fifo_full_o,

                        //cur_mrd_count_o,
						mrd_tlp_sent_o,
						// CN ADDED FOR CS
						cur_wr_count_o,

                        completer_id_i,
                        cfg_ext_tag_en_i,
                        cfg_bus_mstr_enable_i,
                        cfg_phant_func_en_i,
                        cfg_phant_func_supported_i,
                        
                        /*************ouyang***************/
                        //response queue interface
                        response_queue_empty_i,
                        response_queue_data_i,
    										response_queue_rd_en_o ,//read enable signal for response queue
    										//msix interface
            						msg_lower_addr_i,
            						msg_upper_addr_i,
            						msg_data_i,
            						// the base addr for response queue
            						response_queue_addr_i,
            						//count enable for response queue offset
            						response_queue_addr_offset_cnt_en_o,
            						interrupt_block_i,
            						response_queue_cur_offset_reg_i,
    										response_queue_addr_offset_i
    										/**********************************/

                        );


		/*************ouyang***************/
		//response queue interface
		input response_queue_empty_i;
		input [31:0] response_queue_data_i;
    output response_queue_rd_en_o ;//read enable signal for response queue
    reg response_queue_rd_en_o;
    //msix interface
    input [31:0] msg_lower_addr_i;
    input [31:0] msg_upper_addr_i;
    input [31:0] msg_data_i;
    // the base addr for response queue
    input [31:0] response_queue_addr_i;
    //count enable for response queue offset
    output response_queue_addr_offset_cnt_en_o;
    reg response_queue_addr_offset_cnt_en_o;
    input interrupt_block_i;
    input [31:0] response_queue_cur_offset_reg_i;
		input [10:0] response_queue_addr_offset_i;
		
		//reg		[31:0] 				addr_check;
    //wire  [11:0]				addr_check_w = addr_check[11:0] + 3'h4;
    /**********************************/
    
    input               clk;
    input               rst_n;
 
    output [127:0]      trn_td;
    output [1:0]        trn_trem_n;
    output              trn_tsof_n;
    output              trn_teof_n;
    output              trn_tsrc_rdy_n;
    output              trn_tsrc_dsc_n;
    input               trn_tdst_rdy_n;
    input               trn_tdst_dsc_n;
    input [5:0]         trn_tbuf_av;

    input               req_compl_i;
    output              compl_done_o;

    input [2:0]         req_tc_i;
    input               req_td_i;
    input               req_ep_i;
    input [1:0]         req_attr_i;
    input [9:0]         req_len_i;
    input [15:0]        req_rid_i;
    input [7:0]         req_tag_i;
    input [7:0]         req_be_i;
    input [10:0]        req_addr_i;
    
    output [6:0]        rd_addr_o;
    output [3:0]        rd_be_o;
    input  [31:0]       rd_data_i;

    input               init_rst_i;

    input               mwr_start_i;
    input  [15:0]       mwr_len_i;
    input  [7:0]        mwr_tag_i;
    input  [3:0]        mwr_lbe_i;
    input  [3:0]        mwr_fbe_i;
    input  [31:0]       mwr_addr_i;
    input  [31:0]       mwr_size_i;
    output              mwr_done_o;
    input  [2:0]        mwr_tlp_tc_i;
    input               mwr_64b_en_i;
    input               mwr_phant_func_dis1_i;
    input  [7:0]        mwr_up_addr_i;
    input               mwr_relaxed_order_i;
    input               mwr_nosnoop_i;
    input  [7:0]        mwr_wrr_cnt_i;
	input				mwr_done_clr;


    input               mrd_start_i;
    input  [15:0]       mrd_len_i;
    input  [7:0]        mrd_tag_i;
    input  [3:0]        mrd_lbe_i;
    input  [3:0]        mrd_fbe_i;
    input  [31:0]       mrd_addr_i;
    input  [31:0]       mrd_size_i;
    input  [2:0]        mrd_tlp_tc_i;
    input               mrd_64b_en_i;
    input               mrd_phant_func_dis1_i;
    input  [7:0]        mrd_up_addr_i;
    input               mrd_relaxed_order_i;
    input               mrd_nosnoop_i;
    input  [7:0]        mrd_wrr_cnt_i;
	input				mrd_done_clr;
	output				mrd_done;
	
	input [127:0]		tdata_i;
	input				tdata_wr_en_i;
	output				tdata_fifo_full_o;

    //output [15:0]       cur_mrd_count_o;
	output [31:0]		mrd_tlp_sent_o;
    			// CN ADDED FOR CS
    output [15:0]	cur_wr_count_o;

    input [15:0]        completer_id_i;
    input               cfg_ext_tag_en_i;
    input               cfg_bus_mstr_enable_i;

    input               cfg_phant_func_en_i;
    input [1:0]         cfg_phant_func_supported_i;


    // Local registers

    reg [127:0]          trn_td;
    reg [1:0]           trn_trem_n;
    reg                 trn_tsof_n;
    reg                 trn_teof_n;
    reg                 trn_tsrc_rdy_n;
    reg                 trn_tsrc_dsc_n;
 
    reg [11:0]          byte_count;
    reg [06:0]          lower_addr;

	reg					req_compl_p;
	reg					req_compl_d;
    reg                 req_compl_q;               

    reg [2:0]           bmd_128_tx_state;


    reg                 compl_done_o;
    reg                 mwr_done_o;

    reg                 mrd_done;
	reg [31:0]			mrd_tlp_sent_o;

    reg [15:0]          cur_wr_count;
    reg [15:0]          cur_rd_count;
	reg 				mrd_pending;
   
    reg [9:0]           cur_mwr_dw_count;
  
    reg [12:0]          mwr_len_byte;
    reg [12:0]          mrd_len_byte;

    reg [31:0]          pmwr_addr;
    reg [31:0]          pmrd_addr;

    reg [31:0]          tmwr_addr;
    reg [31:0]          tmrd_addr;

    reg [31:0]          mwr_send_size_dw;
    reg [31:0]          mrd_send_size_dw;

    reg                 serv_mwr;
    reg                 serv_mrd;

    reg  [7:0]          tmwr_wrr_cnt;
    reg  [7:0]          tmrd_wrr_cnt;
	
	wire [31:0]			fifo_dout[3:0];
	reg [3:0]			fifo_rd_en;
	wire [3:0]			fifo_full;
	
	wire [3:0]		fifo_empty;
	
	wire [5:0]		cpu_id;
	
	assign			cpu_id = response_queue_data_i[15:10];
	
	`ifdef DEBUG
	reg [31:0]		rd_data_cnt;
	
	always @(posedge clk) begin
		if(!rst_n || init_rst_i)
			rd_data_cnt <= 32'b0;
		else
			if(tdata_wr_en_i)
				rd_data_cnt <= rd_data_cnt + 1'b1;
	end
	`endif

    // Local wires
   
    //wire [15:0]         cur_mrd_count_o = cur_rd_count;
    			// CN ADDED FOR CS
    wire [15:0]		cur_wr_count_o = cur_wr_count; 
    
    wire                cfg_bm_en = cfg_bus_mstr_enable_i;
    wire [31:0]         mwr_addr  = mwr_addr_i;
    wire [31:0]         mrd_addr  = mrd_addr_i;

    wire  [2:0]         mwr_func_num = (!mwr_phant_func_dis1_i && cfg_phant_func_en_i) ? 
                                       ((cfg_phant_func_supported_i == 2'b00) ? 3'b000 : 
                                        (cfg_phant_func_supported_i == 2'b01) ? {cur_wr_count[8], 2'b00} : 
                                        (cfg_phant_func_supported_i == 2'b10) ? {cur_wr_count[9:8], 1'b0} : 
                                        (cfg_phant_func_supported_i == 2'b11) ? {cur_wr_count[10:8]} : 3'b000) : 3'b000;

    wire  [2:0]         mrd_func_num = (!mrd_phant_func_dis1_i && cfg_phant_func_en_i) ? 
                                       ((cfg_phant_func_supported_i == 2'b00) ? 3'b000 : 
                                        (cfg_phant_func_supported_i == 2'b01) ? {cur_rd_count[8], 2'b00} : 
                                        (cfg_phant_func_supported_i == 2'b10) ? {cur_rd_count[9:8], 1'b0} : 
                                        (cfg_phant_func_supported_i == 2'b11) ? {cur_rd_count[10:8]} : 3'b000) : 3'b000;

    /*
     * Present address and byte enable to memory module
     */

    assign rd_addr_o = req_addr_i[10:2];
    assign rd_be_o =   req_be_i[3:0];

    /*
     * Calculate byte count based on byte enable
     */

    always @ (rd_be_o) begin

      casex (rd_be_o[3:0])
      
        4'b1xx1 : byte_count = 12'h004;
        4'b01x1 : byte_count = 12'h003;
        4'b1x10 : byte_count = 12'h003;
        4'b0011 : byte_count = 12'h002;
        4'b0110 : byte_count = 12'h002;
        4'b1100 : byte_count = 12'h002;
        4'b0001 : byte_count = 12'h001;
        4'b0010 : byte_count = 12'h001;
        4'b0100 : byte_count = 12'h001;
        4'b1000 : byte_count = 12'h001;
        4'b0000 : byte_count = 12'h001;

      endcase

    end

    /*
     * Calculate lower address based on  byte enable
     */

    always @ (rd_be_o or req_addr_i) begin

      casex (rd_be_o[3:0])
      
        4'b0000 : lower_addr = {req_addr_i[4:0], 2'b00};
        4'bxxx1 : lower_addr = {req_addr_i[4:0], 2'b00};
        4'bxx10 : lower_addr = {req_addr_i[4:0], 2'b01};
        4'bx100 : lower_addr = {req_addr_i[4:0], 2'b10};
        4'b1000 : lower_addr = {req_addr_i[4:0], 2'b11};

      endcase

    end

	// Delay 2 clocks before data is ready
	//
    always @ ( posedge clk ) begin

        if (!rst_n ) begin

			req_compl_p <= 1'b0;
			req_compl_d <= 1'b0;
			req_compl_q <= 1'b0;

        end else begin 
		  
		   if(compl_done_o) begin
			
				req_compl_p <= 1'b0;
				req_compl_d <= 1'b0;
				req_compl_q <= 1'b0;	
				
			end else begin

				req_compl_p <= req_compl_i;
				req_compl_d <= req_compl_p;
				req_compl_q <= req_compl_d;
				
			end

        end

    end



    /*
     *  Tx State Machine 
     */

    always @ ( posedge clk ) begin

        if (!rst_n ) begin

          trn_tsof_n        <= 1'b1;
          trn_teof_n        <= 1'b1;
          trn_tsrc_rdy_n    <= 1'b1;
          trn_tsrc_dsc_n    <= 1'b1;
          trn_td            <= 127'b0;
          trn_trem_n        <= 2'b0;
 
          cur_mwr_dw_count  <= 10'b0;

          compl_done_o      <= 1'b0;
          mwr_done_o        <= 1'b0;

          mrd_done          <= 1'b0;
		  mrd_tlp_sent_o	<= 32'b0;

          cur_wr_count      <= 16'b0;
          cur_rd_count      <= 16'b0;
		  mrd_pending		<= 1'b0;

          mwr_len_byte      <= 13'b0;
          mrd_len_byte      <= 13'b0;

          pmwr_addr         <= 32'b0;
          pmrd_addr         <= 32'b0;

          mwr_send_size_dw  <= 32'b0;
          mrd_send_size_dw  <= 32'b0;

          serv_mwr          <= 1'b1;
          serv_mrd          <= 1'b1;

          tmwr_wrr_cnt      <= 8'h00;
          tmrd_wrr_cnt      <= 8'h00;

          bmd_128_tx_state   <= `BMD_128_TX_RST_STATE;
          
          /*************ouyang***************/
          response_queue_rd_en_o <= 1'b0;//read enable signal for response queue
          response_queue_addr_offset_cnt_en_o <= 1'b0;
          //addr_check <= 32'b0;
          /**********************************/

        end else begin 

         
          if (init_rst_i ) begin

            trn_tsof_n        <= 1'b1;
            trn_teof_n        <= 1'b1;
            trn_tsrc_rdy_n    <= 1'b1;
            trn_tsrc_dsc_n    <= 1'b1;
            trn_td            <= 127'b0;
            trn_trem_n        <= 2'b0;
   
            cur_mwr_dw_count  <= 10'b0;
  
            compl_done_o      <= 1'b0;
            mwr_done_o        <= 1'b0;

            mrd_done          <= 1'b0;
			mrd_tlp_sent_o	  <= 32'b0;
  
            cur_wr_count      <= 16'b0;
            cur_rd_count      <= 16'b0;
			mrd_pending		  <= 1'b0;

            mwr_len_byte      <= 13'b0;
            mrd_len_byte      <= 13'b0;

            pmwr_addr         <= 32'b0;
            pmrd_addr         <= 32'b0;

            mwr_send_size_dw  <= 32'b0;
            mrd_send_size_dw  <= 32'b0;

            serv_mwr          <= 1'b1;
            serv_mrd          <= 1'b1;

            tmwr_wrr_cnt      <= 8'h00;
            tmrd_wrr_cnt      <= 8'h00;

            bmd_128_tx_state   <= `BMD_128_TX_RST_STATE;
            /*************ouyang***************/
            response_queue_rd_en_o <= 1'b0;//read enable signal for response queue
            response_queue_addr_offset_cnt_en_o <= 1'b0;
            //addr_check <= 32'b0;
            /**********************************/

          end
			 
			if( mrd_done_clr == 1'b1 ) begin
				mrd_pending		<= 1'b0;
				mrd_done		<= 1'b0;
			end
			if( mwr_done_clr == 1'b1 ) begin
				mwr_done_o <= 1'b0;
			end

          mwr_len_byte        <= 4 * mwr_len_i[10:0];
          mrd_len_byte        <= 4 * mrd_len_i[10:0];

          case ( bmd_128_tx_state ) 

            `BMD_128_TX_RST_STATE : begin

              compl_done_o       <= 1'b0;

              // PIO read completions always get highest priority
	if (req_compl_q	&&
                  !compl_done_o &&
                  !trn_tdst_rdy_n ) begin

                trn_tsof_n       <= 1'b0;
                trn_teof_n       <= 1'b0; // CN - CplD w/ 1 DW payload - SOF and EOF in same beat
                trn_tsrc_rdy_n   <= 1'b0;
		// CN - Logic for upper QW
                trn_td           <= { {1'b0}, 
                                      `BMD_128_CPLD_FMT_TYPE, 
                                      {1'b0}, 
                                      req_tc_i, 
                                      {4'b0}, 
                                      req_td_i, 
                                      req_ep_i, 
                                      req_attr_i, 
                                      {2'b0}, 
                                      req_len_i,
                                      completer_id_i, 
                                      {3'b0}, 
                                      {1'b0}, 
                                      byte_count,
	 	// CN - Logic for lower QW
				      req_rid_i, 
                                      req_tag_i, 
                                      {1'b0}, 
                                      lower_addr,
                                      rd_data_i
				      }; 
		compl_done_o      <= 1'b1;
                trn_trem_n        <= 2'b00; //CN - H0H1H3D0

                bmd_128_tx_state   <= `BMD_128_TX_CPLD_WIT;

    	end 
    	/*************ouyang***************/
      else if(!interrupt_block_i && !response_queue_empty_i && !trn_tdst_rdy_n && (trn_tbuf_av > 4)) begin
      	bmd_128_tx_state <= `RESPONSE_INFORMATION;
      	trn_tsof_n        <= 1'b1;
        trn_teof_n        <= 1'b1;
        trn_tsrc_rdy_n    <= 1'b1;
        trn_tsrc_dsc_n    <= 1'b1;
        trn_td            <= 64'b0;
        trn_trem_n        <= 2'b0;					      
      end
      /**********************************/
    	else if (mwr_start_i && 
                           !mwr_done_o &&
                           serv_mwr &&
                           !trn_tdst_rdy_n && 
             		   cfg_bm_en) begin

                trn_tsof_n       <= 1'b0;
		trn_tsrc_rdy_n   <= 1'b0;
		
		if (mwr_64b_en_i) begin // CN - 64-bit MWr

			if (cur_wr_count == 0) begin
                  		tmwr_addr       = mwr_addr;
			end else begin
                  		tmwr_addr       = pmwr_addr + mwr_len_byte;
			end
			pmwr_addr        <= tmwr_addr;
			trn_teof_n       <= 1'b1;
			// CN - Logic for upper QW
                	trn_td           <= { {1'b0}, 
                                      	      {mwr_64b_en_i ? 
                                       	      `BMD_128_MWR64_FMT_TYPE :  
                                       	      `BMD_128_MWR_FMT_TYPE}, 
                                     	      {1'b0}, 
                                   	      mwr_tlp_tc_i, 
                                              {4'b0}, 
                                              1'b0, 
                                              1'b0, 
                                              {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00, 
                                              {2'b0}, 
                                              mwr_len_i[9:0],
                                      	      {completer_id_i[15:3], mwr_func_num}, 
                                      	      cfg_ext_tag_en_i ? cur_wr_count[7:0] : {3'b0, cur_wr_count[4:0]},
                                      	      (mwr_len_i[9:0] == 1'b1) ? 4'b0 : mwr_lbe_i,
                                      	      mwr_fbe_i,
			// CN - Logic for lower QW 
					      {24'b0},
					      mwr_up_addr_i,
					      tmwr_addr[31:2],
					      {2'b0}
					      };
                	trn_trem_n        <= 2'b00;  // CN - H0H1H2H3
					
            cur_mwr_dw_count  <= mwr_len_i[9:0];
					
			cur_wr_count <= cur_wr_count + 1'b1;
			mwr_send_size_dw <= mwr_send_size_dw + mwr_len_i[9:0];
			
			bmd_128_tx_state  <= `BMD_128_TX_MWR_QWN;

		end else begin // CN - 32-bit MWr

			if (cur_wr_count == 0) begin
                  		tmwr_addr       = mwr_addr;
			end else begin
                  		tmwr_addr       = pmwr_addr + mwr_len_byte;
			end

			pmwr_addr        <= tmwr_addr;

			// CN - Logic for upper QW
                	trn_td           <= { {1'b0}, 
                                      	      {mwr_64b_en_i ? 
                                       	      `BMD_128_MWR64_FMT_TYPE :  
                                       	      `BMD_128_MWR_FMT_TYPE}, 
                                     	      {1'b0}, 
                                   	      mwr_tlp_tc_i, 
                                              {4'b0}, 
                                              1'b0, 
                                              1'b0, 
                                              {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00, 
                                              {2'b0}, 
                                              mwr_len_i[9:0],
                                      	      {completer_id_i[15:3], mwr_func_num}, 
                                      	      cfg_ext_tag_en_i ? cur_wr_count[7:0] : {3'b0, cur_wr_count[4:0]},
                                      	      (mwr_len_i[9:0] == 1'b1) ? 4'b0 : mwr_lbe_i,
                                      	      mwr_fbe_i,
			// CN - Logic for lower QW 
					      tmwr_addr[31:2],
					      {2'b00}, 
					      fifo_dout[0]
					      };
                	trn_trem_n        <= 2'b00;

			cur_wr_count <= cur_wr_count + 1'b1;
			mwr_send_size_dw <= mwr_send_size_dw + mwr_len_i[9:0];

			if (mwr_len_i[9:0] == 1'h1) begin 
				trn_teof_n       <= 1'b0;
                cur_mwr_dw_count <= mwr_len_i[9:0] - 1'h1;
				bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;
				
				if (mwr_send_size_dw == (( mwr_size_i >> 2 ) - 1'b1)) begin
					mwr_send_size_dw <= 0;
					cur_wr_count <= 1'b0; 
					mwr_done_o <= 1'b1;
				end
			end else begin
				cur_mwr_dw_count <= mwr_len_i[9:0] - 1'h1; 
                bmd_128_tx_state  <= `BMD_128_TX_MWR_QWN;
				trn_teof_n       <= 1'b1;
			end
		end

                
                // Weighted Round Robin
                if (mwr_start_i && !mwr_done_o && (tmwr_wrr_cnt != mwr_wrr_cnt_i)) begin
                  serv_mwr        <= 1'b1;
                  serv_mrd        <= 1'b0;
                  tmwr_wrr_cnt    <= tmwr_wrr_cnt + 1'b1;
                end else if (mrd_start_i && !mrd_done) begin
                  serv_mwr        <= 1'b0;
                  serv_mrd        <= 1'b1;
                  tmwr_wrr_cnt    <= 8'h00;
                end else begin
                  serv_mwr        <= 1'b0;
                  serv_mrd        <= 1'b0;
                  tmwr_wrr_cnt    <= 8'h00;
                end		

              end else if (mrd_start_i && 
                           !mrd_done &&
                           serv_mrd &&
                           !trn_tdst_rdy_n &&
                           cfg_bm_en) begin
             
                trn_tsof_n       <= 1'b0;
                trn_teof_n       <= 1'b0;
                trn_tsrc_rdy_n   <= 1'b0;

		if ( mrd_pending == 1'b0 ) begin
            tmrd_addr       = mrd_addr;
	  	end else begin                  
		  tmrd_addr       = {pmrd_addr[31:24], pmrd_addr[23:0] + mrd_len_byte};
		end
		
		mrd_pending		 <= 1'b1;
		pmrd_addr        <= tmrd_addr;

		if (mrd_64b_en_i) begin

                	trn_td           <= { {1'b0}, 
                  	                    {mrd_64b_en_i ? 
                 	                    `BMD_128_MRD64_FMT_TYPE : 
                        	            `BMD_128_MRD_FMT_TYPE}, 
                                	    {1'b0}, 
                                	    mrd_tlp_tc_i, 
                                      	    {4'b0}, 
                                	    1'b0, 
                                      	    1'b0, 
                                      	    {mrd_relaxed_order_i, mrd_nosnoop_i}, // 2'b00, 
                                      	    {2'b0}, 
                                      	    mrd_len_i[9:0],
                                      	    {completer_id_i[15:3], mrd_func_num}, 
                                      	    cfg_ext_tag_en_i ? cur_rd_count[7:0] : {3'b0, cur_rd_count[4:0]},
                                      	    (mrd_len_i[9:0] == 1'b1) ? 4'b0 : mrd_lbe_i,
                                      	    mrd_fbe_i,
				      	    {24'b0},
				      	    {mrd_up_addr_i},
				      	    tmrd_addr[31:2],
				      	    {2'b0}
				      	    };
                	trn_trem_n        <= 2'b00;
		end else begin

			trn_td           <= { {1'b0}, 
                  	                    {mrd_64b_en_i ? 
                 	                    `BMD_128_MRD64_FMT_TYPE : 
                        	            `BMD_128_MRD_FMT_TYPE}, 
                                	    {1'b0}, 
                                	    mrd_tlp_tc_i, 
                                      	    {4'b0}, 
                                	    1'b0, 
                                      	    1'b0, 
                                      	    {mrd_relaxed_order_i, mrd_nosnoop_i}, // 2'b00, 
                                      	    {2'b0}, 
                                      	    mrd_len_i[9:0],
                                      	    {completer_id_i[15:3], mrd_func_num}, 
                                      	    cfg_ext_tag_en_i ? cur_rd_count[7:0] : {3'b0, cur_rd_count[4:0]},
                                      	    (mrd_len_i[9:0] == 1'b1) ? 4'b0 : mrd_lbe_i,
                                      	    mrd_fbe_i,
					    {tmrd_addr[31:2], 2'b00},
					    32'hd0_da_d0_da};

			trn_trem_n        <= 2'b01; // CN - H0H1H2--
		end
		
		cur_rd_count <= cur_rd_count + 1'b1;
		if( cur_rd_count[7:0] == 8'b1111_1111)
			cur_rd_count[7:0] <= 8'b0;
			
		mrd_tlp_sent_o <= mrd_tlp_sent_o + 1'b1;
	
		if (mrd_send_size_dw == ( mrd_size_i >> 2 ) - mrd_len_i[9:0] ) begin

				  mrd_send_size_dw <= 0;
                  mrd_done       <= 1'b1;				  
	  	end else begin 
                  
				  mrd_send_size_dw <= mrd_send_size_dw + mrd_len_i[9:0];
	  	end
		bmd_128_tx_state  <= `BMD_128_TX_RST_STATE; 


                // Weighted Round Robin
                if (mrd_start_i && !mrd_done && (tmrd_wrr_cnt != mrd_wrr_cnt_i)) begin
                  serv_mrd        <= 1'b1;
                  serv_mwr        <= 1'b0;
                  tmrd_wrr_cnt    <= tmrd_wrr_cnt + 1'b1;
                end else if (mwr_start_i && !mwr_done_o) begin
                  serv_mrd        <= 1'b0;
                  serv_mwr        <= 1'b1;
                  tmrd_wrr_cnt    <= 8'h00;
                end else begin
                  serv_mrd        <= 1'b0;
                  serv_mwr        <= 1'b0;
                  tmrd_wrr_cnt    <= 8'h00;
                end

                
           /*   end else if (!trn_tdst_dsc_n) begin

                bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;
                trn_tsrc_dsc_n   <= 1'b0;*/ //  CN - trn_tdst_dsc_n not used in xilinx_pcie_2_0_ep_v6.v

		end else begin

			if (!trn_tdst_rdy_n) begin
				trn_tsof_n        <= 1'b1;
                  		trn_teof_n        <= 1'b1;
                  		trn_tsrc_rdy_n    <= 1'b1;
                  		trn_tsrc_dsc_n    <= 1'b1;
                  		trn_td            <= 64'b0;
                  		trn_trem_n        <= 2'b0;

                  		serv_mwr          <= ~serv_mwr;
                  		serv_mrd          <= ~serv_mrd;
			end

		  	bmd_128_tx_state   <= `BMD_128_TX_RST_STATE;
		end
              end

            

            `BMD_128_TX_CPLD_WIT : begin

              if ( !trn_tdst_rdy_n  ) begin

                trn_tsof_n       <= 1'b1;
                trn_teof_n       <= 1'b1;
                trn_tsrc_rdy_n   <= 1'b1;
                trn_tsrc_dsc_n   <= 1'b1;

                bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;

              end else
                bmd_128_tx_state  <= `BMD_128_TX_CPLD_WIT;

            end

            `BMD_128_TX_MWR_QWN : begin


              if (!trn_tdst_rdy_n ) begin

                trn_tsrc_rdy_n   <= 1'b0;
				trn_tsof_n	<= 1'b1; 	    

                if (cur_mwr_dw_count == 1'h1) begin

                  //trn_td           <= {32'hd0_da_d0_da, 32'hd0_da_d0_da, 32'hd0_da_d0_da, 32'hd0_da_d0_da};
						trn_td           <= {32'hd0_da_d0_da, 32'hd0_da_d0_da, 28'b0, fifo_empty, rd_data_cnt};
					 trn_trem_n       <= 2'b11; // CN - D4------ 
                  trn_teof_n       <= 1'b0;
                  cur_mwr_dw_count <= cur_mwr_dw_count - 1'h1; 
                  bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;

                  if (mwr_send_size_dw == ( mwr_size_i >> 2 ) )  begin

                    cur_wr_count <= 0; 
					mwr_send_size_dw <= 0;
                    mwr_done_o   <= 1'b1;

                  end 

                end else if (cur_mwr_dw_count == 2'h2) begin

                  trn_td           <= {32'hd0_da_d0_da, 32'hd0_da_d0_da, 32'hd0_da_d0_da, 32'hd0_da_d0_da};
                  trn_trem_n       <= 2'b10;
                  trn_teof_n       <= 1'b0;
                  cur_mwr_dw_count <= cur_mwr_dw_count - 2'h2; 
                  bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;

                  if (mwr_send_size_dw == ( mwr_size_i >> 2 ))  begin

                    cur_wr_count <= 0;
					mwr_send_size_dw <= 0;
                    mwr_done_o   <= 1'b1;

                  end

		end else if (cur_mwr_dw_count == 3'h3) begin

                  trn_td           <= {fifo_dout[1], fifo_dout[2], fifo_dout[3], 32'hd0_da_d0_da};
                  trn_trem_n       <= 2'b01;
                  trn_teof_n       <= 1'b0;
                  cur_mwr_dw_count <= cur_mwr_dw_count - 3'h3; 
                  bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;

                  if (mwr_send_size_dw == ( mwr_size_i >> 2 ))  begin

                    cur_wr_count <= 0;
					mwr_send_size_dw <= 0;
                    mwr_done_o   <= 1'b1;

                  end

		end else if (cur_mwr_dw_count == 4'h4) begin

                  trn_td           <= {fifo_dout[0], fifo_dout[1], fifo_dout[2], fifo_dout[3]};
                  trn_trem_n       <= 2'b00;
                  trn_teof_n       <= 1'b0;
                  cur_mwr_dw_count <= cur_mwr_dw_count - 4'h4; 
                  bmd_128_tx_state  <= `BMD_128_TX_RST_STATE;

                  if (mwr_send_size_dw == ( mwr_size_i >> 2 ))  begin

                    cur_wr_count <= 0;
					mwr_send_size_dw <= 0;
                    mwr_done_o   <= 1'b1;

                  end

                end else begin
				  if(mwr_64b_en_i)
					trn_td           <= {fifo_dout[0], fifo_dout[1], fifo_dout[2], fifo_dout[3]};
				  else
					trn_td           <= {fifo_dout[1], fifo_dout[2], fifo_dout[3], fifo_dout[0]};
                  trn_trem_n       <= 2'b00;
                  cur_mwr_dw_count <= cur_mwr_dw_count - 4'h4; 
                  bmd_128_tx_state  <= `BMD_128_TX_MWR_QWN;

                end

          /*    end else if (!trn_tdst_dsc_n) begin

                bmd_128_tx_state    <= `BMD_128_TX_RST_STATE;
                trn_tsrc_dsc_n     <= 1'b0; */ // CN - trn_tdst_dsc_n not used in xilinx_pcie_2_0_ep_v6.v

              end else
                bmd_128_tx_state    <= `BMD_128_TX_MWR_QWN;

            end
            
            /***************ouyang*******************/
						`RESPONSE_INFORMATION: begin
							if (!trn_tdst_rdy_n ) begin
								trn_tsof_n       <= 1'b0;
			      	  trn_teof_n       <= 1'b0; // CN - CplD w/ 1 DW payload - SOF and EOF in same beat
			      	  trn_tsrc_rdy_n   <= 1'b0;
			      	  trn_trem_n        <= 2'b0;
			      		// CN - Logic for upper QW
			      	  trn_td <= { {1'b0}, 
			      	              {`BMD_128_MWR_FMT_TYPE}, 
			      	              {1'b0}, 
			      	              {3'b0},//mwr_tlp_tc_i, 
			      	              {4'b0}, 
			      	              1'b0, 
			      	              1'b0, 
			      	              {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00, 
			      	              {2'b0}, 
			      	              {10'b1},//mwr_len_i[9:0],
			      	              {completer_id_i[15:3], mwr_func_num}, 
			      	              {8'b0},//cfg_ext_tag_en_i ? cur_wr_count[7:0] : {3'b0, cur_wr_count[4:0]},
			      	              {4'b0},//(mwr_len_i[9:0] == 1'b1) ? 4'b0 : mwr_lbe_i,
			      	              mwr_fbe_i,
							  // CN - Logic for lower QW 
									          response_queue_addr_i[31:2],
									          {2'b00}, 
									          response_queue_data_i[7:0],response_queue_data_i[15:8],response_queue_data_i[23:16],response_queue_data_i[31:24]
									        };
							
								response_queue_rd_en_o <= 1'b0;
								response_queue_addr_offset_cnt_en_o <= 1'b0;
								//bmd_128_tx_state <= `BMD_128_TX_INTERRUPUT;	
								bmd_128_tx_state <= `CUR_RESPONSE_OFFSET;   
								
								/*   
								if( addr_check == 0 )
									addr_check <= response_queue_addr_i;
								else begin
									if ( {addr_check[31:12],addr_check_w[11:0]} == {response_queue_addr_i[31:12] ,response_queue_addr_i[11:0]}) 
											addr_check <= response_queue_addr_i;
									else
											trn_td[31:0]	<= 32'hababbaba;
								end*/
								
						end else
						   bmd_128_tx_state <= `RESPONSE_INFORMATION;
				end
				
				
            `CUR_RESPONSE_OFFSET: begin
            	         	
            	if (!trn_tdst_rdy_n ) begin
            		response_queue_addr_offset_cnt_en_o <= 1'b1;
            	  response_queue_rd_en_o <= 1'b1;
            	  // CN - Logic for upper QW
        				trn_td <= { {1'b0}, 
        				            {`BMD_128_MWR_FMT_TYPE}, 
        				            {1'b0}, 
        				            {3'b0},//mwr_tlp_tc_i, 
        				            {4'b0}, 
        				            1'b0, 
        				            1'b0, 
        				            {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00, 
        				            {2'b0}, 
        				            {10'b1},//mwr_len_i[9:0],
        				            {completer_id_i[15:3], mwr_func_num}, 
        				            {8'b0},//cfg_ext_tag_en_i ? cur_wr_count[7:0] : {3'b0, cur_wr_count[4:0]},
        				            {4'b0},//(mwr_len_i[9:0] == 1'b1) ? 4'b0 : mwr_lbe_i,
        				            mwr_fbe_i,
			  				// CN - Logic for lower QW 
									          response_queue_cur_offset_reg_i[31:2],    										
									          {2'b00}, 
									          response_queue_addr_offset_i[7:0],{5'b0},response_queue_addr_offset_i[10:8],{16'b0}
									        };
								bmd_128_tx_state <= `BMD_128_TX_INTERRUPUT;
								trn_tsof_n       <= 1'b0;
        				trn_teof_n       <= 1'b0; // CN - CplD w/ 1 DW payload - SOF and EOF in same beat
        				trn_tsrc_rdy_n   <= 1'b0;
        				trn_trem_n        <= 2'b0;
            	end else begin
            		bmd_128_tx_state <= `CUR_RESPONSE_OFFSET;
            	end
            end
            
            
            `BMD_128_TX_INTERRUPUT: begin
            	
            	response_queue_addr_offset_cnt_en_o <= 1'b0;
            	response_queue_rd_en_o <= 1'b0;
            	if (!trn_tdst_rdy_n ) begin
            	  // CN - Logic for upper QW
        				trn_td <= { {1'b0}, 
        				            {`BMD_128_MWR_FMT_TYPE}, 
        				            {1'b0}, 
        				            {3'b0},//mwr_tlp_tc_i, 
        				            {4'b0}, 
        				            1'b0, 
        				            1'b0, 
        				            {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00, 
        				            {2'b0}, 
        				            {10'b1},//mwr_len_i[9:0],
        				            {completer_id_i[15:3], mwr_func_num}, 
        				            {8'b0},//cfg_ext_tag_en_i ? cur_wr_count[7:0] : {3'b0, cur_wr_count[4:0]},
        				            {4'b0},//(mwr_len_i[9:0] == 1'b1) ? 4'b0 : mwr_lbe_i,
        				            mwr_fbe_i,
			  				// CN - Logic for lower QW 
									          msg_lower_addr_i[31:2],
												 //msg_lower_addr_i[31:20],{2'b0,cpu_id},msg_lower_addr_i[11:2],
									          {2'b00}, 
									          msg_data_i[7:0],msg_data_i[15:8],msg_data_i[23:16],msg_data_i[31:24]
									        };
								bmd_128_tx_state <= `BMD_128_TX_RST_STATE;
								trn_tsof_n       <= 1'b0;
        				trn_teof_n       <= 1'b0; // CN - CplD w/ 1 DW payload - SOF and EOF in same beat
        				trn_tsrc_rdy_n   <= 1'b0;
        				trn_trem_n        <= 2'b0;
            	end else begin
            		bmd_128_tx_state <= `BMD_128_TX_INTERRUPUT;
            	end
            end
            /**********************************/

          endcase

        end

    end
	
	
	/*
	* Read data from fifo in advance
	*/
	always @ ( * ) begin
	
		if( !rst_n ) begin
		
			fifo_rd_en = 4'b0000;
			
		end else begin
		
			if( init_rst_i )
			
				fifo_rd_en = 4'b0000;
				
			else begin
		
				case ( bmd_128_tx_state )
					
					`BMD_128_TX_RST_STATE: begin
					
						if (mwr_start_i && 
							   !mwr_done_o &&
							   serv_mwr &&
							   !trn_tdst_rdy_n && 
								cfg_bm_en &&
								!mwr_64b_en_i ) 
							fifo_rd_en = 4'b0001;
						else
							fifo_rd_en = 4'b0000;
					
					end
					
					`BMD_128_TX_MWR_QWN: begin
					
						if(!trn_tdst_rdy_n) begin
							
							if( cur_mwr_dw_count >= 4 )
								fifo_rd_en = 4'b1111;
							else
								fifo_rd_en = 4'b1110;
						
						end	else
							fifo_rd_en = 4'b0000;
							
					end
					
					default: fifo_rd_en = 4'b0000;
					
				endcase
				
			end //if( init_rst_i || mwr_done_clr )
		
		end //if( !rst_n )
	
	end
	
	
	
	wire		srst = !rst_n | init_rst_i;
	assign tdata_fifo_full_o = | fifo_full;
	
	// TX SEND FIFO 0
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM	
	TX_SEND_FIFO TX_SEND_FIFO0 (
	  .clk(clk), // input clk
	  .srst(srst), // input srst
	  .din(tdata_i[127:96]), // input [31 : 0] din
	  .wr_en(tdata_wr_en_i), // input wr_en
	  .rd_en(fifo_rd_en[0]), // input rd_en
	  .dout(fifo_dout[0]), // output [31 : 0] dout
	  .full(fifo_full[0]), // output full
	  .empty(fifo_empty[0]) // output empty
	);	
	
	// TX SEND FIFO 1
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM	
	TX_SEND_FIFO TX_SEND_FIFO1 (
	  .clk(clk), // input clk
	  .srst(srst), // input srst
	  .din(tdata_i[95:64]), // input [31 : 0] din
	  .wr_en(tdata_wr_en_i), // input wr_en
	  .rd_en(fifo_rd_en[1]), // input rd_en
	  .dout(fifo_dout[1]), // output [31 : 0] dout
	  .full(fifo_full[1]), // output full
	  .empty(fifo_empty[1]) // output empty
	);	

	// TX SEND FIFO 2
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM	
	TX_SEND_FIFO TX_SEND_FIFO2 (
	  .clk(clk), // input clk
	  .srst(srst), // input srst
	  .din(tdata_i[63:32]), // input [31 : 0] din
	  .wr_en(tdata_wr_en_i), // input wr_en
	  .rd_en(fifo_rd_en[2]), // input rd_en
	  .dout(fifo_dout[2]), // output [31 : 0] dout
	  .full(fifo_full[2]), // output full
	  .empty(fifo_empty[2]) // output empty
	);	

	// TX SEND FIFO 3
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM	
	TX_SEND_FIFO TX_SEND_FIFO3 (
	  .clk(clk), // input clk
	  .srst(srst), // input srst
	  .din(tdata_i[31:0]), // input [31 : 0] din
	  .wr_en(tdata_wr_en_i), // input wr_en
	  .rd_en(fifo_rd_en[3]), // input rd_en
	  .dout(fifo_dout[3]), // output [31 : 0] dout
	  .full(fifo_full[3]), // output full
	  .empty(fifo_empty[3]) // output empty
	);

endmodule // BMD_128_TX_ENGINE

