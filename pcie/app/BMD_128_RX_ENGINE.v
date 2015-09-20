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
//-- Filename: BMD_128_RX_ENGINE.v
//--
//-- Description: 128 bit Local-Link Receive Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`define BMD_128_RX_RST              8'b00000001
`define BMD_128_RX_MEM_RD32_STRAD   8'b00000010
`define BMD_128_RX_MEM_RD32_WT      8'b00000100
`define BMD_128_RX_MEM_WR32_STRAD   8'b00001000
`define BMD_128_RX_MEM_WR32_WT      8'b00010000
`define BMD_128_RX_CPL_STRAD        8'b00100000
`define BMD_128_RX_CPLD_STRAD       8'b01000000
`define BMD_128_RX_CPLD_QWN         8'b10000000

`define BMD_MEM_RD32_FMT_TYPE    7'b00_00000
`define BMD_MEM_WR32_FMT_TYPE    7'b10_00000
`define BMD_CPL_FMT_TYPE         7'b00_01010
`define BMD_CPLD_FMT_TYPE        7'b10_01010

module BMD_RX_ENGINE (

                        clk,
                        rst_n,

                        /*
                         * Initiator reset
                         */

                        init_rst_i,

                        /*
                         * Receive local link interface from PCIe core
                         */
                    
                        trn_rd,  
                        trn_rrem_n,
                        trn_rsof_n,
                        trn_reof_n,
                        trn_rsrc_rdy_n,
                        trn_rsrc_dsc_n,
                        trn_rdst_rdy_n,
                        trn_rbar_hit_n,

                        /*
                         * Memory Read data handshake with Completion 
                         * transmit unit. Transmit unit reponds to 
                         * req_compl assertion and responds with compl_done
                         * assertion when a Completion w/ data is transmitted. 
                         */

                        req_compl_o,
                        compl_done_i,

                        addr_o,                    // Memory Read Address

                        req_tc_o,                  // Memory Read TC
                        req_td_o,                  // Memory Read TD
                        req_ep_o,                  // Memory Read EP
                        req_attr_o,                // Memory Read Attribute
                        req_len_o,                 // Memory Read Length (1DW)
                        req_rid_o,                 // Memory Read Requestor ID
                        req_tag_o,                 // Memory Read Tag
                        req_be_o,                  // Memory Read Byte Enables

                        /* 
                         * Memory interface used to save 1 DW data received 
                         * on Memory Write 32 TLP. Data extracted from
                         * inbound TLP is presented to the Endpoint memory
                         * unit. Endpoint memory unit reacts to wr_en_o
                         * assertion and asserts wr_busy_i when it is 
                         * processing written information.
                         */

                        wr_be_o,                   // Memory Write Byte Enable
                        wr_data_o,                 // Memory Write Data
                        wr_en_o,                   // Memory Write Enable
                        wr_busy_i,                  // Memory Write Busy
						
						rdata_o,
						rdata_rd_en_i,
						rdata_fifo_empty_o,
						
                        /*
                         * Completion no Data
                         */

                        cpl_ur_found_o,
                        cpl_ur_tag_o,
						
						/*
						* Check for MRd completion and done clear
						*/
						mrd_size_i,
						mrd_done_o,
						mrd_done_clr,

                        /*
                         * Completion with Data
                         */
                        
                        cpld_found_o,
                        cpld_data_size_o,
                        cpld_malformed_o

						);

    input              clk;
    input              rst_n;

    input              init_rst_i;

    input [127:0]       trn_rd;
    input [1:0]        trn_rrem_n;
    input              trn_rsof_n;
    input              trn_reof_n;
    input              trn_rsrc_rdy_n;
    input              trn_rsrc_dsc_n;
    output             trn_rdst_rdy_n;
    input [6:0]        trn_rbar_hit_n;
 
    output             req_compl_o;
    input              compl_done_i;

    output [10:0]      addr_o;

    output [2:0]       req_tc_o;
    output             req_td_o;
    output             req_ep_o;
    output [1:0]       req_attr_o;
    output [9:0]       req_len_o;
    output [15:0]      req_rid_o;
    output [7:0]       req_tag_o;
    output [7:0]       req_be_o;

    output [7:0]       wr_be_o;
    output [31:0]      wr_data_o;
    output             wr_en_o;
    input              wr_busy_i;
	
	output [127:0]	   rdata_o;
	output			   rdata_fifo_empty_o;
	input			   rdata_rd_en_i;
	
	input [31:0]	   mrd_size_i;
	output			   mrd_done_o;
	input			   mrd_done_clr;

    output [7:0]       cpl_ur_found_o;
    output [7:0]       cpl_ur_tag_o;

    output [31:0]      cpld_found_o;
    output [31:0]      cpld_data_size_o;
    output             cpld_malformed_o;

    // Local wire

    // Local Registers

    reg [7:0]          bmd_128_rx_state;
    reg [7:0]          prev_bmd_128_rx_state;
    reg [7:0]          strad_bmd_128_rx_state;

    reg                trn_rdst_rdy_n;

    reg                req_compl_o;

    reg [2:0]          req_tc_o;
    reg                req_td_o;
    reg                req_ep_o;
    reg [1:0]          req_attr_o;
    reg [9:0]          req_len_o;
    reg [15:0]         req_rid_o;
    reg [7:0]          req_tag_o;
    reg [7:0]          req_be_o;

    reg [10:0]         addr_o;
    reg [7:0]          wr_be_o;
    reg [31:0]         wr_data_o;
    reg                wr_en_o;
	
	reg				   mrd_done_o;
	
    reg [7:0]          cpl_ur_found_o;
    reg [7:0]          cpl_ur_tag_o;

    reg [31:0]         cpld_found_o;
    reg                cpld_malformed_o;
    //reg                cpld_data_err_o;
	
	reg	[127:0]		   rx_data;
	reg				   rx_data_av;
	reg [1:0]		   rx_data_sel;
	
	reg [1:0]		   tail;
	
	reg [31:0]		   fifo_din[3:0];
	reg [3:0]		   fifo_wr_en;
	wire [3:0]		   fifo_empty;
	wire [3:0]			fifo_full;
	wire						rcv_fifo_full;
	
	reg				   cpld_done;

    //reg [9:0]          cpld_real_size;
    //reg [9:0]          cpld_tlp_size;
	reg [31:0]		   cpld_data_size_o;
    reg [6:0]          cpld_real_size;
    reg [6:0]          cpld_tlp_size;

    reg [7:0]          bmd_128_rx_state_q;
    reg [127:0]         trn_rd_q;
    reg [1:0]          trn_rrem_n_q;
    reg                trn_reof_n_q;
    reg                trn_rsof_n_q;
    reg                trn_rsrc_rdy_n_q;
	

    always @ ( posedge clk ) begin
              
        if (!rst_n ) begin

          bmd_128_rx_state   <= `BMD_128_RX_RST;
	  prev_bmd_128_rx_state   <= `BMD_128_RX_RST;
	  strad_bmd_128_rx_state   <= `BMD_128_RX_RST;
          trn_rdst_rdy_n <= 1'b0;

          req_compl_o    <= 1'b0;

          req_tc_o       <= 2'b0;
          req_td_o       <= 1'b0;
          req_ep_o       <= 1'b0;
          req_attr_o     <= 2'b0;
          req_len_o      <= 10'b0;
          req_rid_o      <= 16'b0;
          req_tag_o      <= 8'b0;
          req_be_o       <= 8'b0;
          addr_o         <= 31'b0;

          wr_be_o        <= 8'b0;
          wr_data_o      <= 31'b0;
          wr_en_o        <= 1'b0;
          
          cpl_ur_found_o   <= 8'b0;
          cpl_ur_tag_o     <= 8'b0;

          cpld_found_o     <= 32'b0;
          cpld_data_size_o <= 32'b0;
          cpld_malformed_o <= 1'b0;

          cpld_real_size   <= 7'b0;
          cpld_tlp_size    <= 7'b0;
		  
		  rx_data		   <= 128'b0;
		  rx_data_av	   <= 1'b0;
		  rx_data_sel	   <= 2'b0;
		  
		  cpld_done 	   <= 1'b1;

          bmd_128_rx_state_q <= `BMD_128_RX_RST;
          trn_rd_q          <= 127'b0;
          trn_rrem_n_q      <= 2'b0;
          trn_reof_n_q      <= 1'b1;
          trn_rsrc_rdy_n_q  <= 1'b1;

        end else begin

          //wr_en_o        <= 1'b0;
          req_compl_o    <= 1'b0;
          trn_rdst_rdy_n <= 1'b0;
		  
		  rx_data		 <= 128'b0;
		  rx_data_av	 <= 1'b0;
		  rx_data_sel	 <= 2'b00;
		  
		  if( mrd_done_clr ) begin		  
			
			cpld_data_size_o <= 32'b0;
		  
		  end
 
          if (init_rst_i) begin

            bmd_128_rx_state  <= `BMD_128_RX_RST;

            cpl_ur_found_o   <= 8'b0;
            cpl_ur_tag_o     <= 8'b0;
   
            cpld_found_o     <= 32'b0;
            cpld_data_size_o <= 32'b0;
            cpld_malformed_o <= 1'b0;
			
			cpld_done 		 <= 1'b1;

            cpld_real_size   <= 7'b0;
            cpld_tlp_size    <= 7'b0;

            bmd_128_rx_state_q <= `BMD_128_RX_RST;
			prev_bmd_128_rx_state   <= `BMD_128_RX_RST;
			strad_bmd_128_rx_state   <= `BMD_128_RX_RST;
            trn_rd_q          <= 127'b0;
            trn_rrem_n_q      <= 2'b0;
            trn_reof_n_q      <= 1'b1;
			trn_reof_n_q      <= 1'b0;
            trn_rsrc_rdy_n_q  <= 1'b1;

         end

         bmd_128_rx_state_q <= `BMD_128_RX_RST;
         trn_rd_q          <= 127'b0;
         trn_rrem_n_q      <= 2'b0;
         trn_reof_n_q      <= 1'b1;
		 trn_rsof_n_q      <= 1'b1;
         trn_rsrc_rdy_n_q  <= 1'b1;

         case (bmd_128_rx_state)

           `BMD_128_RX_RST : begin    

             	if ((!trn_rsrc_rdy_n) &&
		(!trn_rdst_rdy_n) &&
		(!trn_rsof_n) && 
		(trn_reof_n) && 
		(trn_rrem_n[1]))  begin // CN - ----H0H1 - Straddled TLP

             	case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];

                     		bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD;   
    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD ;
                    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
    
                   		end else
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;
                   		bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase

		end else if ((!trn_rsrc_rdy_n) &&
			    (!trn_rdst_rdy_n) &&
			    (!trn_rsof_n) && 
		            (trn_reof_n) && 
			    (trn_rrem_n == 2'b00))  begin // CN - H0H1H2D0 - CplD w/ > 1 DW payload 
			  
	   	             if ( trn_rd[126:120] == `BMD_CPLD_FMT_TYPE ) begin 
	   	                // CN = Logic for upper QW
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[105:96];
                   		cpld_tlp_size    <= trn_rd[102:96];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								
								cpld_done		  <= 1'b0;
						
						rx_data[127:96]	 <= trn_rd[31:0];
						rx_data_av	 <= 1'b1;
						rx_data_sel	 <= 2'b00;
				
						//CN - Logic for lower QW
						bmd_128_rx_state_q <= bmd_128_rx_state;
						trn_rd_q          <= trn_rd;
						trn_rrem_n_q      <= trn_rrem_n;
						trn_reof_n_q	 <= trn_reof_n; 
						trn_rsof_n_q     <= trn_rsof_n;
						cpld_real_size   <= 1'b1;  
						bmd_128_rx_state  <= `BMD_128_RX_CPLD_QWN;
			     end else begin
				     bmd_128_rx_state <= `BMD_128_RX_RST;
			     end

		end else if ((!trn_rsrc_rdy_n) &&
			    (!trn_rdst_rdy_n) &&
			    (!trn_rsof_n) && 
		            (!trn_reof_n) && 
			    (trn_rrem_n == 2'b00)) begin // CN - H0H1H2D0 Mwr(32) or CplD(32) w/ 1 DW payload		  
		
      		case (trn_rd[126:120])   

                 	`BMD_MEM_WR32_FMT_TYPE : begin
    				
				// CN - Logic for upper QW
                   		if (trn_rd[105:96] == 10'b0000000001) begin  // Length = 1 DW 
                     		wr_be_o      <= trn_rd[71:64];   //  7:4 = Last DW BE  3:0 = 1st DW BE

				// CN - Logic for lower QW
				addr_o           <= trn_rd[44:34];
              			wr_data_o        <= trn_rd[31:00];
               			wr_en_o          <= 1'b1;
               			trn_rdst_rdy_n   <= 1'b1;
               			bmd_128_rx_state  <= `BMD_128_RX_MEM_WR32_WT;
			        prev_bmd_128_rx_state <= `BMD_128_RX_RST;	
                    
				end else begin
                     		bmd_128_rx_state <= `BMD_128_RX_RST;  
				end
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin   
				// CN - Logic for upper QW
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[105:96];
                   		cpld_tlp_size    <= trn_rd[102:96];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								
						rx_data[127:96]	 <= trn_rd[31:0];
						rx_data_av	 <= 1'b1;
						rx_data_sel	 <= 2'b00;
						
						cpld_done	 <= 1'b1;

						// CN - Logic for lower QW
						bmd_128_rx_state_q <= bmd_128_rx_state;
						trn_rd_q          <= trn_rd;
						trn_rrem_n_q      <= trn_rrem_n;
						trn_reof_n_q	 <= trn_reof_n;
						trn_rsof_n_q     <= trn_rsof_n;	
						cpld_real_size   <= 7'b1;  
                   		bmd_128_rx_state  <= `BMD_128_RX_RST;  
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               	endcase

		end else if ((!trn_rsrc_rdy_n) &&
			    (!trn_rdst_rdy_n) &&
			    (!trn_rsof_n) && 
		            (!trn_reof_n) && 
			    (trn_rrem_n == 2'b01)) begin // CN - H0H1H2-- - MRd(32) or Cpl(32)

	   	case (trn_rd[126:120])

              		`BMD_MEM_RD32_FMT_TYPE : begin
				// CN - Logic for upper QW
                   		if (trn_rd[105:96] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[118:116];  
                     		req_td_o     <= trn_rd[111];
                     		req_ep_o     <= trn_rd[110]; 
                     		req_attr_o   <= trn_rd[109:108]; 
                     		req_len_o    <= trn_rd[105:96]; 
                     		req_rid_o    <= trn_rd[95:80]; 
                     		req_tag_o    <= trn_rd[79:72]; 
                     		req_be_o     <= trn_rd[71:64];

				// CN - Logic for lower QW
						addr_o <= trn_rd[63:34];
               			req_compl_o       <= 1'b1;
               			trn_rdst_rdy_n    <= 1'b1;
              			bmd_128_rx_state   <= `BMD_128_RX_MEM_RD32_WT;
			        prev_bmd_128_rx_state <= `BMD_128_RX_RST; 

				end else begin
                     		bmd_128_rx_state <= `BMD_128_RX_RST;
				end
                 	end

                 	`BMD_CPL_FMT_TYPE : begin
    				// CN - Logic for upper QW
                   		if (trn_rd[79:76] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;

				// CN - Logic for lower QW
				cpl_ur_tag_o     <= trn_rd[47:40];
               			bmd_128_rx_state  <= `BMD_128_RX_RST;
				
				end else begin
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
				end
    
                 	end

                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase

		end else if ((!trn_rsrc_rdy_n) &&
			    (!trn_rdst_rdy_n) &&
			    (!trn_rsof_n) && 
		            (!trn_reof_n) && 
			    (trn_rrem_n[1] == 1'b1 )) begin // CN - D2-H0H1 or D2D3H0H1 - Handles straddled TLPs that were discarded

			case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];

                     		bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD;   
    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD ;
                    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
    
                   		end else
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								
								cpld_done		  <= 1'b0;
								
                   		cpld_real_size   <= 7'b0;
                   		bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase

		end else begin
               			bmd_128_rx_state   <= `BMD_128_RX_RST;

           	end
		end	

           `BMD_128_RX_MEM_RD32_STRAD : begin  
		
	       prev_bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD; 

             if ((!trn_reof_n) && 
                 (!trn_rsrc_rdy_n) && 
		 (!trn_rsof_n) &&  // CN - Straddled TLPs
                 (!trn_rdst_rdy_n)) begin  // CN - H2--H0H1

               addr_o            <= trn_rd[127:98];
               req_compl_o       <= 1'b1;
               trn_rdst_rdy_n    <= 1'b1;
	       bmd_128_rx_state   <= `BMD_128_RX_MEM_RD32_WT;
	       
	       
	       case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];
				strad_bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD; 
    
                   		end else
                     		strad_bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		strad_bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD;
                    
                   		end else
                     		strad_bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	strad_bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
                   		end else
                     		strad_bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;
                   		strad_bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		strad_bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase

	     end else if ((!trn_reof_n) && 
                 (!trn_rsrc_rdy_n) && 
		 (trn_rsof_n) &&  // CN - Non-straddled TLPs
                 (!trn_rdst_rdy_n)) begin  // CN - H2------

	       			addr_o            <= trn_rd[127:98];
               			req_compl_o       <= 1'b1;
               			trn_rdst_rdy_n    <= 1'b1;
	       			bmd_128_rx_state   <= `BMD_128_RX_MEM_RD32_WT;
				strad_bmd_128_rx_state   <= `BMD_128_RX_RST;

             end else
               bmd_128_rx_state   <= `BMD_128_RX_MEM_RD32_STRAD;

           end

           `BMD_128_RX_MEM_RD32_WT: begin 

             trn_rdst_rdy_n <= 1'b1;
	     
	     if (prev_bmd_128_rx_state == `BMD_128_RX_RST) begin  // CN - Previous beat had non-straddled MRd return to RST state

             	if (compl_done_i)
              	 	bmd_128_rx_state   <= `BMD_128_RX_RST;
            	 else begin

               		req_compl_o       <= 1'b1;
               		trn_rdst_rdy_n    <= 1'b1;
              		bmd_128_rx_state   <= `BMD_128_RX_MEM_RD32_WT;
		end

		end else if (prev_bmd_128_rx_state == `BMD_128_RX_MEM_RD32_STRAD) begin // CN - Previous beat had straddled MRd go to next state
									                // for straddle TLP	
		if (compl_done_i)
              	 	bmd_128_rx_state   <= strad_bmd_128_rx_state;
            	 else begin

               		req_compl_o       <= 1'b1;
               		trn_rdst_rdy_n    <= 1'b1;
              		bmd_128_rx_state   <= `BMD_128_RX_MEM_RD32_WT;
		end
		end else begin
			bmd_128_rx_state   <= `BMD_128_RX_RST;
		end

           end

           `BMD_128_RX_MEM_WR32_STRAD : begin 

	       prev_bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD; 
		
             if ((!trn_reof_n) && 
                 (!trn_rsrc_rdy_n) && 
		 (!trn_rsof_n) &&  // CN - Straddled TLPs
                 (!trn_rdst_rdy_n)) begin // CN - H2D0H0H1

               addr_o           <= trn_rd[108:98];
               wr_data_o        <= trn_rd[95:64];
               wr_en_o          <= 1'b1;
               trn_rdst_rdy_n   <= 1'b1;
               bmd_128_rx_state  <= `BMD_128_RX_MEM_WR32_WT;

		case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];
				strad_bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD; 
    
                   		end else
                     		strad_bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		strad_bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD;
                    
                   		end else
                     		strad_bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	strad_bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
                   		end else
                     		strad_bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;
                   		strad_bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		strad_bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase
		
           end else if  ((!trn_rsrc_rdy_n) && 
		 	(trn_rsof_n) &&  // CN - non-straddled TLPs
                 	(!trn_rdst_rdy_n)) begin
	       
		 		addr_o           <= trn_rd[108:98];
               			wr_data_o        <= trn_rd[95:64];
               			wr_en_o          <= 1'b1;
               			trn_rdst_rdy_n   <= 1'b1;
               			bmd_128_rx_state  <= `BMD_128_RX_MEM_WR32_WT;
				strad_bmd_128_rx_state   <= `BMD_128_RX_RST;

             end else
               bmd_128_rx_state  <= `BMD_128_RX_MEM_WR32_STRAD;


           end

           `BMD_128_RX_MEM_WR32_WT: begin

             trn_rdst_rdy_n <= 1'b1;
 		if (prev_bmd_128_rx_state == `BMD_128_RX_RST) begin  // CN - Previous beat had non-straddled MWr return to RST state
             		if (!wr_busy_i) begin
						wr_en_o <= 1'b0;
               			bmd_128_rx_state  <= `BMD_128_RX_RST;
					end
             		else
              			bmd_128_rx_state  <= `BMD_128_RX_MEM_WR32_WT;
		end else if (prev_bmd_128_rx_state == `BMD_128_RX_MEM_WR32_STRAD) begin // CN - Previous beat had straddled MWr go to next state
									     // for straddle TLP	
					if (!wr_busy_i) begin
						wr_en_o <= 1'b0;
               			bmd_128_rx_state  <= strad_bmd_128_rx_state;
					end
             		else
              			bmd_128_rx_state  <= `BMD_128_RX_MEM_WR32_WT;
		end else 
				bmd_128_rx_state  <= `BMD_128_RX_RST;   

           end

           `BMD_128_RX_CPL_STRAD : begin //H3--H0H1

             if ((!trn_reof_n) && 
                 (!trn_rsrc_rdy_n) &&
		 (trn_rsof_n) &&  // Non-straddled TLPs
                 (!trn_rdst_rdy_n)) begin

               cpl_ur_tag_o     <= trn_rd[111:104];
               bmd_128_rx_state  <= `BMD_128_RX_RST;

             end else if ((!trn_reof_n) && 
                 (!trn_rsrc_rdy_n) &&
		 (!trn_rsof_n) && //CN - Straddled TLPs
                 (!trn_rdst_rdy_n)) begin

		cpl_ur_tag_o     <= trn_rd[111:104];

             		case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];

                     		bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD;   
    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD;
                    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
    
                   		end else
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;
                   		bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
               		endcase
      	     end else
               bmd_128_rx_state  <= `BMD_128_RX_CPL_STRAD;
             

           end

           `BMD_128_RX_CPLD_STRAD : begin

             bmd_128_rx_state_q <= bmd_128_rx_state;
             trn_rd_q          <= trn_rd;
	     trn_rrem_n_q      <= trn_rrem_n;
             trn_reof_n_q      <= trn_reof_n;
	     trn_rsof_n_q      <= trn_rsof_n;
             trn_rsrc_rdy_n_q  <= trn_rsrc_rdy_n;

             if ((!trn_reof_n) &&
		 (trn_rsof_n) &&
		 (!trn_rsrc_rdy_n) && 
                 (!trn_rdst_rdy_n)) begin

                 if ( trn_rrem_n == 2'b10 ) begin // CN - H2D0----

				 	rx_data[127:96]	 <= trn_rd[95:64];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b00;
					
					cpld_done 	 <= 1'b1;
					
					cpld_real_size   <= cpld_real_size  + 1'h1;
                 	if (cpld_tlp_size  != cpld_real_size  + 1'h1)
                   		cpld_malformed_o <= 1'b1;
	         
	    	 end else if ( trn_rrem_n == 2'b01 ) begin // CN - H2D0D1--

				 	rx_data[127:64]	 <= trn_rd[95:32];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b01;
					
					cpld_done 	 <= 1'b1;		  		
				
					cpld_real_size   <= cpld_real_size  + 2'h2;
                 	if (cpld_tlp_size  != cpld_real_size  + 2'h2)
                   		cpld_malformed_o <= 1'b1;

		 end else if ( trn_rrem_n == 2'b11 ) begin // CN - H2D0D1D2

				 	rx_data[127:32]	 <= trn_rd[95:0];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b10;
					
					cpld_done 	 <= 1'b1; 
		  		
					cpld_real_size   <= cpld_real_size  + 3'h3;
                 	if (cpld_tlp_size  != cpld_real_size  + 3'h3)
                   		cpld_malformed_o <= 1'b1;
	         end

		 bmd_128_rx_state   <= `BMD_128_RX_RST;

             end else if ((!trn_rsrc_rdy_n) && 
		     	 (!trn_rsof_n) && // CN - Straddled CplD w/ 1 DW payload
		     	 (!trn_reof_n) && 
                         (!trn_rdst_rdy_n)) begin // CN - H2D0H0H1

             		case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];

                     		bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD;   
    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD;
                    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
    
                   		end else
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;  // CN - Need to look at how this is counted
                   		bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase

				 	rx_data[127:96]	 <= trn_rd[95:64];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b00;
					
					cpld_done 	 <= 1'b1;
					
					cpld_real_size   <= cpld_real_size  + 1'h1;
                 	if (cpld_tlp_size  != cpld_real_size  + 1'h1)
                   		cpld_malformed_o <= 1'b1;
			 
	   end else if ((!trn_rsrc_rdy_n) && 
		       (!trn_rdst_rdy_n) &&
	       	       (trn_reof_n) && // CN - CplD with > 3 DW payload
	       	       (trn_rsof_n)) begin // CN - H2D0D1D2
				   
				 	rx_data[127:32]	 <= trn_rd[95:0];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b10;
					
               		cpld_real_size   <= cpld_real_size  + 3'h3;
               		bmd_128_rx_state  <= `BMD_128_RX_CPLD_QWN;

             end else
               bmd_128_rx_state   <= `BMD_128_RX_CPLD_STRAD;

           end

           `BMD_128_RX_CPLD_QWN : begin 

             bmd_128_rx_state_q <= bmd_128_rx_state;
             trn_rd_q          <= trn_rd;
             trn_rrem_n_q      <= trn_rrem_n;
             trn_reof_n_q      <= trn_reof_n;
	     trn_rsof_n_q      <= trn_rsof_n;
             trn_rsrc_rdy_n_q  <= trn_rsrc_rdy_n;

             if ((!trn_reof_n) && 
                 (!trn_rsrc_rdy_n) && 
		 (!trn_rsof_n) && // CN - Straddled TLPs
                 (!trn_rdst_rdy_n)) begin 

               if ( trn_rrem_n == 2'b11 ) begin // CN - D0--H0H1
					
						cpld_done 	 <= 1'b1;

             		case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];

                     		bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD;   
    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD;
                    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
    
                   		end else
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;
                   		bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase
		       
				 	rx_data[127:96]	 <= trn_rd[127:96];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b00;
					
					//cpld_done 	 <= 1'b1;
			   
					cpld_real_size   <= cpld_real_size  + 1'h1;
					if (cpld_tlp_size  != cpld_real_size  + 1'h1)
						cpld_malformed_o <= 1'b1;

               end else if (trn_rrem_n[0] == 1'b0 && trn_rrem_n[1] == 1'b1) begin // CN - D0D1H0H1

						cpld_done 	 <= 1'b1;
						
             		case (trn_rd[62:56])   

              		`BMD_MEM_RD32_FMT_TYPE : begin

                   		if (trn_rd[41:32] == 10'b1) begin
    
                    		req_tc_o     <= trn_rd[54:52];  
                     		req_td_o     <= trn_rd[47];
                     		req_ep_o     <= trn_rd[46]; 
                     		req_attr_o   <= trn_rd[45:44]; 
                     		req_len_o    <= trn_rd[41:32]; 
                     		req_rid_o    <= trn_rd[31:16]; 
                     		req_tag_o    <= trn_rd[15:08]; 
                     		req_be_o     <= trn_rd[07:00];

                     		bmd_128_rx_state <= `BMD_128_RX_MEM_RD32_STRAD;   
    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

                 	end
             
                 	`BMD_MEM_WR32_FMT_TYPE : begin
    
                   		if (trn_rd[41:32] == 10'b1) begin  // Length = 1 DW 
    
                     		wr_be_o      <= trn_rd[07:00];   //  7:4 = Last DW BE  3:0 = 1st DW BE
                     		bmd_128_rx_state <= `BMD_128_RX_MEM_WR32_STRAD;
                    
                   		end else
                     		bmd_128_rx_state <= `BMD_128_RX_RST;

    
                 	end
    
                 	`BMD_CPL_FMT_TYPE : begin
    
                   		if (trn_rd[15:12] != 3'b000) begin
    
                     		cpl_ur_found_o <= cpl_ur_found_o + 1'b1;
                    	 	bmd_128_rx_state   <= `BMD_128_RX_CPL_STRAD;
    
                   		end else
                     		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
    
                 	`BMD_CPLD_FMT_TYPE : begin
                   
                   		cpld_data_size_o <= cpld_data_size_o + trn_rd[41:32];
                   		cpld_tlp_size    <= trn_rd[38:32];
                   		cpld_found_o     <= cpld_found_o  + 1'b1;
								cpld_done		  <= 1'b0;
                   		cpld_real_size   <= 7'b0;
                   		bmd_128_rx_state  <= `BMD_128_RX_CPLD_STRAD;
                   
                 	end
                 
                 	default : begin
    
                   		bmd_128_rx_state   <= `BMD_128_RX_RST;
    
                 	end
              
               		endcase
		        
				 	rx_data[127:64]	 <= trn_rd[127:64];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b01;
					
					//cpld_done 	 <= 1'b1;

					cpld_real_size   <= cpld_real_size  + 2'h2;
					if (cpld_tlp_size  != cpld_real_size  + 2'h2)
						cpld_malformed_o <= 1'b1;
	   	end 

             end else if ((!trn_reof_n) && 
                 	 (!trn_rsrc_rdy_n) && 
			 (trn_rsof_n) && // CN - non-straddled TLPs
                	 (!trn_rdst_rdy_n)) begin

		 if (trn_rrem_n[0] == 1'b0 && trn_rrem_n[1] == 1'b1) begin // CN - D0D1----

				 	rx_data[127:64]	 <= trn_rd[127:64];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b01;
					
					cpld_done 	 <= 1'b1;
		 
					cpld_real_size   <= cpld_real_size  + 2'h2;
					if (cpld_tlp_size  != cpld_real_size  + 2'h2)
						cpld_malformed_o <= 1'b1;
	         
  		 end else if (trn_rrem_n[0] == 1'b1 && trn_rrem_n[1] == 1'b1) begin // CN - D0------
		 
				 	rx_data[127:96]	 <= trn_rd[127:96];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b00;
					
					cpld_done 	 <= 1'b1;
		 
					cpld_real_size   <= cpld_real_size  + 1'h1;
					if (cpld_tlp_size  != cpld_real_size  + 1'h1)
						cpld_malformed_o <= 1'b1;

	    	 end else if (trn_rrem_n[0] == 1'b1 && trn_rrem_n[1] == 1'b0) begin // CN - D0D1D2--
			 
				 	rx_data[127:32]	 <= trn_rd[127:32];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b10;
					
					cpld_done 	 <= 1'b1;
			 
					cpld_real_size   <= cpld_real_size  + 3'h3;
					if (cpld_tlp_size  != cpld_real_size  + 3'h3)
						cpld_malformed_o <= 1'b1;

		 end else if (trn_rrem_n[0] == 1'b1 && trn_rrem_n[1] == 1'b1) begin // CN - D0D1D2D3
		 
		 
				 	rx_data[127:0]	 <= trn_rd[127:0];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b11;
					
					cpld_done 	 <= 1'b1;
					
					cpld_real_size   <= cpld_real_size  + 4'h4;
					if (cpld_tlp_size  != cpld_real_size  + 4'h4)
						cpld_malformed_o <= 1'b1;
	         end
		 bmd_128_rx_state   <= `BMD_128_RX_RST;
		
	     end else if ((trn_reof_n) && // CN - Current CplD TLP not finished
                  	 (!trn_rsrc_rdy_n) && 
			 (trn_rsof_n) && // CN - non-straddled TLPs
               		 (!trn_rdst_rdy_n)) begin
					 
					 
				 	rx_data[127:0]	 <= trn_rd[127:0];
					rx_data_av	 <= 1'b1;
					rx_data_sel	 <= 2'b11;

					bmd_128_rx_state   <= `BMD_128_RX_CPLD_QWN;
					cpld_real_size   <= cpld_real_size  + 4'h4;

	     end else begin
               bmd_128_rx_state   <= `BMD_128_RX_CPLD_QWN;
	     end
     end
	
	     default : begin
		bmd_128_rx_state <= `BMD_128_RX_RST;
		end
	    
	endcase
      end   

    end
	
	
	wire	srst = !rst_n | init_rst_i;
	assign	rdata_fifo_empty_o = | fifo_empty;
	assign rcv_fifo_full = | fifo_full;


	// RX RECEIVE FIFO 0
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM
	RX_RECV_FIFO RX_RECV_FIFO0(
		  .clk(clk), // input clk
		  .srst(srst), // input srst
		  .din(fifo_din[0]), // input [31 : 0] din
		  .wr_en(fifo_wr_en[0]), // input wr_en
		  .rd_en(rdata_rd_en_i), // input rd_en
		  .dout(rdata_o[127:96]), // output [31 : 0] dout
		  .full(fifo_full[0]), // output full
		  .empty(fifo_empty[0]) // output empty
	);	
	
	// RX RECEIVE FIFO 1
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM
	RX_RECV_FIFO RX_RECV_FIFO1(
		  .clk(clk), // input clk
		  .srst(srst), // input srst
		  .din(fifo_din[1]), // input [31 : 0] din
		  .wr_en(fifo_wr_en[1]), // input wr_en
		  .rd_en(rdata_rd_en_i), // input rd_en
		  .dout(rdata_o[95:64]), // output [31 : 0] dout
		  .full(fifo_full[1]), // output full
		  .empty(fifo_empty[1]) // output empty
	);

	// RX RECEIVE FIFO 2
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM
	RX_RECV_FIFO RX_RECV_FIFO2(
		  .clk(clk), // input clk
		  .srst(srst), // input srst
		  .din(fifo_din[2]), // input [31 : 0] din
		  .wr_en(fifo_wr_en[2]), // input wr_en
		  .rd_en(rdata_rd_en_i), // input rd_en
		  .dout(rdata_o[63:32]), // output [31 : 0] dout
		  .full(fifo_full[2]), // output full
		  .empty(fifo_empty[2]) // output empty
	);

	// RX RECEIVE FIFO
	// WIDTH = 32
	// DEPTH = 16
	// FWFT,DISTRIBUTE RAM
	RX_RECV_FIFO RX_RECV_FIFO3(
		  .clk(clk), // input clk
		  .srst(srst), // input srst
		  .din(fifo_din[3]), // input [31 : 0] din
		  .wr_en(fifo_wr_en[3]), // input wr_en
		  .rd_en(rdata_rd_en_i), // input rd_en
		  .dout(rdata_o[31:0]), // output [31 : 0] dout
		  .full(fifo_full[3]), // output full
		  .empty(fifo_empty[3]) // output empty
	);		

	// Select proper received data to receive fifo
	//	
	always @ ( posedge clk ) begin
	
		if( !rst_n ) begin
			
			fifo_wr_en <= 4'b0;
			
			fifo_din[0] <= 32'b0;
			fifo_din[1] <= 32'b0;
			fifo_din[2] <= 32'b0;
			fifo_din[3] <= 32'b0;
			
			tail <= 2'b00;
			
		end else begin
		
			if( init_rst_i ) begin
						
				fifo_wr_en <= 4'b0;
				
				fifo_din[0] <= 32'b0;
				fifo_din[1] <= 32'b0;
				fifo_din[2] <= 32'b0;
				fifo_din[3] <= 32'b0;
				
				tail <= 2'b00;
			
			end
			
			fifo_wr_en <= 4'b0;
			
			if( rx_data_av  && !rcv_fifo_full ) begin
			
				case ( rx_data_sel )
				
					2'b00: begin
					
						fifo_wr_en[tail] <= 1'b1;
						fifo_din[tail] <= rx_data[127:96];
						
						tail <= tail +2'h1;
						
					end
					
					2'b01: begin
					
						fifo_wr_en[tail] <= 1'b1;
						fifo_din[tail] <= rx_data[127:96];
						
						fifo_wr_en[tail + 2'h1] <= 1'b1;
						fifo_din[tail + 2'h1] <= rx_data[95:64];
						
						tail <= tail +2'h2;					
						
					end
					
					2'b10: begin
					
						fifo_wr_en[tail] <= 1'b1;
						fifo_din[tail] <= rx_data[127:96];
						
						fifo_wr_en[tail+2'h1] <= 1'b1;
						fifo_din[tail+2'h1] <= rx_data[95:64];
						
						fifo_wr_en[tail+2'h2] <= 1'b1;
						fifo_din[tail+2'h2] <= rx_data[63:32];
						
						tail <= tail +2'h3;	
						
					end
					
					2'b11: begin
					
						fifo_wr_en[tail] <= 1'b1;
						fifo_din[tail] <= rx_data[127:96];
						
						fifo_wr_en[tail+2'h1] <= 1'b1;
						fifo_din[tail+2'h1] <= rx_data[95:64];
						
						fifo_wr_en[tail+2'h2] <= 1'b1;
						fifo_din[tail+2'h2] <= rx_data[63:32];
						
						fifo_wr_en[tail+2'h3] <= 1'b1;
						fifo_din[tail+2'h3] <= rx_data[31:0];
						
					end
				
				endcase
				
			end //if( rx_data_av ) 
			
		end //if( !rst_n )
		
	end
	
	/*
	*  Check for CPLD done
	*/
	/*
	always @ ( posedge clk ) begin
	
		if( !rst_n ) begin
		
			mrd_done_o <= 1'b0;
		
		end
		else begin
		
			if( init_rst_i | mrd_done_clr ) begin
			
				mrd_done_o <= 1'b0;
			
			end else begin

				if( ( mrd_size_i != 0) && ( cpld_data_size_o == ( mrd_size_i >> 2 ) )
										&& cpld_done && rdata_fifo_empty_o 
										&& !rx_data_av && ( !( |fifo_wr_en ) ) ) begin //DW
				
					mrd_done_o <= 1'b1;
					
				end
			
			end //if( init_rst_i | mrd_done_clr )
		
		end //if( !rst_n )
	
	end
	*/
	
endmodule // BMD_128_RX_ENGINE
