//--------------------------------------------------------------------------------
//-- Filename: BAR1_WRAPPER.v
//--
//-- Description: BAR1_WRAPPER Module
//--              
//--              The module is a simple warpper to BAR1 module. it provides write
//-- control and byte enable access on BAR1.
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module BAR1_WRAPPER#(

   parameter INTERFACE_TYPE = 4'b0010,
   parameter FPGA_FAMILY = 8'h14

)
(
						clk,                   // I
						rst_n,                 // I
						en,

						cfg_cap_max_lnk_width, // I [5:0]
						cfg_neg_max_lnk_width, // I [5:0]
						  
						cfg_cap_max_lnk_speed, // I [3:0]
						cfg_neg_max_lnk_speed, // I [3:0]

						cfg_cap_max_payload_size,  // I [2:0]
						cfg_prg_max_payload_size,  // I [2:0]
						cfg_max_rd_req_size,   // I [2:0]

						a_i,                   // I [6:0]
						wr_en_i,               // I
						wr_be_i,			   // I [7:0]
						wr_busy_o,			   // O
						rd_d_o,                // O [31:0]
						rd_be_i,			   // I [3:0]
						wr_d_i,                // I [31:0]

						init_rst_o,            // O
						
						mrd_start_o,           // O
						mrd_done_i,            // O
						mrd_addr_o,            // O [31:0]
						mrd_len_o,             // O [31:0]
						mrd_tlp_tc_o,          // O [2:0]
						mrd_64b_en_o,          // O
						mrd_phant_func_dis1_o,  // O
						mrd_up_addr_o,         // O [7:0]
						mrd_size_o,        // O [31:0]
						mrd_relaxed_order_o,   // O
						mrd_nosnoop_o,         // O
						mrd_wrr_cnt_o,         // O [7:0]
						mrd_done_clr,		   // O

						mwr_start_o,           // O
						mwr_done_i,            // I
						mwr_addr_o,            // O [31:0]
						mwr_len_o,             // O [31:0]
						mwr_tlp_tc_o,          // O [2:0]
						mwr_64b_en_o,          // O
						mwr_phant_func_dis1_o,  // O
						mwr_up_addr_o,         // O [7:0]
						mwr_size_o,        // O [31:0]
						mwr_relaxed_order_o,   // O
						mwr_nosnoop_o,         // O
						mwr_wrr_cnt_o,         // O [7:0]
						mwr_done_clr,

						cpl_ur_found_i,        // I [7:0] 
						cpl_ur_tag_i,          // I [7:0]

						cpld_found_i,          // I [31:0]
						cpld_data_size_i,      // I [31:0]
						cpld_malformed_i,      // I
						cpl_streaming_o,       // O
						rd_metering_o,         // O
						cfg_interrupt_di,      // O
						cfg_interrupt_do,      // I
						cfg_interrupt_mmenable,   // I
						cfg_interrupt_msienable,  // I
						cfg_interrupt_legacyclr,  // O
`ifdef PCIE2_0
						pl_directed_link_change,
						pl_ltssm_state,
						pl_directed_link_width,
						pl_directed_link_speed,
						pl_directed_link_auton,
						pl_upstream_preemph_src,
						pl_sel_link_width,
						pl_sel_link_rate,
						pl_link_gen2_capable,
						pl_link_partner_gen2_supported,
						pl_initial_link_width,
						pl_link_upcfg_capable,
						pl_lane_reversal_mode,
						pl_width_change_err_i,
						pl_speed_change_err_i,
						clr_pl_width_change_err,
						clr_pl_speed_change_err,
						clear_directed_speed_change_i,

`endif
						trn_rnp_ok_n_o,
						trn_tstr_n_o
                    );					
	
	parameter			BAR1_WR_RST =  5'b00001;
	parameter			BAR1_WR_WAIT = 5'b00010;
	parameter			BAR1_WR_READ = 5'b00100;
	parameter			BAR1_WR_WRITE= 5'b01000;
	parameter			BAR1_WR_DONE = 5'b10000;	

	input             	clk;
    input             	rst_n;
	input			  	en;
	
    input [5:0]       	cfg_cap_max_lnk_width;
    input [5:0]       	cfg_neg_max_lnk_width;
	
	input [3:0]		  	cfg_cap_max_lnk_speed;
	input [3:0]		  	cfg_neg_max_lnk_speed;

    input [2:0]      	cfg_cap_max_payload_size;
    input [2:0]       	cfg_prg_max_payload_size;
    input [2:0]       	cfg_max_rd_req_size;

	// read port
	//
    input [6:0]       	a_i;
	input [3:0]			rd_be_i;
    output [31:0]     	rd_d_o;
	
	// write port
	//
    input             	wr_en_i;
	input [7:0]			wr_be_i;
    input [31:0]     	wr_d_i;
	output				wr_busy_o;

    // CSR bits

    output            	init_rst_o;

    output            	mrd_start_o;
    input            	mrd_done_i;
    output [31:0]     	mrd_addr_o;
    output [15:0]     	mrd_len_o;
    output [2:0]     	mrd_tlp_tc_o;
    output            	mrd_64b_en_o;
    output            	mrd_phant_func_dis1_o;
    output [7:0]      	mrd_up_addr_o;
    output [31:0]     	mrd_size_o;
    output            	mrd_relaxed_order_o;
    output            	mrd_nosnoop_o;
    output [7:0]      	mrd_wrr_cnt_o;
	output				mrd_done_clr;

    output            	mwr_start_o;
    input             	mwr_done_i;
    output [31:0]     	mwr_addr_o;
    output [15:0]     	mwr_len_o;
    output [2:0]      	mwr_tlp_tc_o;
    output            	mwr_64b_en_o;
    output            	mwr_phant_func_dis1_o;
    output [7:0]      	mwr_up_addr_o;
    output [31:0]     	mwr_size_o;
    output            	mwr_relaxed_order_o;
    output            	mwr_nosnoop_o;
    output [7:0]      	mwr_wrr_cnt_o;
	
	output			  	mwr_done_clr;

    input  [7:0]      	cpl_ur_found_i;
    input  [7:0]      	cpl_ur_tag_i;

    input  [31:0]     	cpld_found_i;
    input  [31:0]     	cpld_data_size_i;
    input             	cpld_malformed_i;
    output            	cpl_streaming_o;
    output            	rd_metering_o;

    output            	trn_rnp_ok_n_o;
    output            	trn_tstr_n_o;
    output [7:0]      	cfg_interrupt_di;
    input  [7:0]      	cfg_interrupt_do;
    input  [2:0]      	cfg_interrupt_mmenable;
    input             	cfg_interrupt_msienable;
    output            	cfg_interrupt_legacyclr;

`ifdef PCIE2_0

    output [1:0]      	pl_directed_link_change;
    input  [5:0]      	pl_ltssm_state;
    output [1:0]      	pl_directed_link_width;
    output            	pl_directed_link_speed;
    output            	pl_directed_link_auton;
    output            	pl_upstream_preemph_src;
    input  [1:0]      	pl_sel_link_width;
    input             	pl_sel_link_rate;
    input             	pl_link_gen2_capable;
    input             	pl_link_partner_gen2_supported;
    input  [2:0]      	pl_initial_link_width;
    input             	pl_link_upcfg_capable;
    input  [1:0]      	pl_lane_reversal_mode;

    input             	pl_width_change_err_i;
    input             	pl_speed_change_err_i;
    output            	clr_pl_width_change_err;
    output            	lr_pl_speed_change_err;
    input             	clear_directed_speed_change_i;
	
`endif

	wire [31:0]			bar1_rd_data;
	
	reg [6:0]			addr_q;
	reg [3:0]			wr_be_q;
	reg [31:0]			wr_d_q;
	
	reg					wr_busy_o;
	
	reg					bar1_wr_en;
	reg [31:0]			pre_wr_data;
	reg [31:0]			bar1_wr_data;
	
	reg [4:0]			bar1_wr_state;
	
	// BAR1 write control state machine
	//
	always @ ( posedge clk ) begin
	
		if( !rst_n ) begin
		
			bar1_wr_en <= 1'b0;
			wr_busy_o <= 1'b0;
			
			addr_q <= 7'b0;
			wr_be_q <= 4'b0;
			wr_d_q <= 32'b0;
			
			pre_wr_data <= 32'b0;
			bar1_wr_data <= 32'b0;
		
			bar1_wr_state <= BAR1_WR_RST;
		
		end
		else begin
		
			case ( bar1_wr_state )
			
				BAR1_WR_RST: begin
				
					bar1_wr_en <= 1'b0;
					wr_busy_o <= 1'b0;
				
					addr_q <= a_i;
					
					if( wr_en_i ) begin					

						wr_be_q <= wr_be_i[3:0];
						wr_d_q <= wr_d_i;
						
						wr_busy_o <= 1'b1;
						
						bar1_wr_state <= BAR1_WR_WAIT;
					
					end
				
				end
				
				BAR1_WR_WAIT: begin
				
					bar1_wr_state <= BAR1_WR_READ;
				
				end
				
				BAR1_WR_READ: begin
				
					pre_wr_data <= bar1_rd_data;
					
					bar1_wr_state <= BAR1_WR_WRITE;
				
				end
				
				BAR1_WR_WRITE: begin
				
					bar1_wr_en <= 1'b1;
					bar1_wr_data <= { { wr_be_q[3] ? wr_d_q[31:24] : pre_wr_data[31:24] } ,
									  { wr_be_q[2] ? wr_d_q[23:16] : pre_wr_data[23:16] } ,
									  { wr_be_q[1] ? wr_d_q[15:8] : pre_wr_data[15:8] } ,
									  { wr_be_q[0] ? wr_d_q[7:0] : pre_wr_data[7:0] }
									};					
					
					bar1_wr_state <= BAR1_WR_DONE;
				
				end
				
				BAR1_WR_DONE: begin
				
					wr_busy_o <= 1'b0;
					bar1_wr_state <= BAR1_WR_RST;
				
				end
				
				default: bar1_wr_state <= BAR1_WR_RST;
			
			endcase
		
		end
	
	end
	
    /*
     *  BAR1 Read Controller
     */

    /* Handle Read byte enables */

    assign rd_d_o = {{rd_be_i[0] ? bar1_rd_data[07:00] : 8'h0},
                     {rd_be_i[1] ? bar1_rd_data[15:08] : 8'h0}, 
                     {rd_be_i[2] ? bar1_rd_data[23:16] : 8'h0}, 
                     {rd_be_i[3] ? bar1_rd_data[31:24] : 8'h0}};
					 
	
	BAR1# (
        .INTERFACE_TYPE(INTERFACE_TYPE),
        .FPGA_FAMILY(FPGA_FAMILY)
    
    ) bar1(
                      .clk(clk),                   // I
                      .rst_n(rst_n),                 // I
					  .en(en),

                      .cfg_cap_max_lnk_width(cfg_cap_max_lnk_width), // I [5:0]
                      .cfg_neg_max_lnk_width(cfg_neg_max_lnk_width), // I [5:0]
					  
					  .cfg_cap_max_lnk_speed(cfg_cap_max_lnk_speed),
					  .cfg_neg_max_lnk_speed(cfg_neg_max_lnk_speed),

                      .cfg_cap_max_payload_size(cfg_cap_max_payload_size),  // I [2:0]
                      .cfg_prg_max_payload_size(cfg_prg_max_payload_size),  // I [2:0]
                      .cfg_max_rd_req_size(cfg_max_rd_req_size),   // I [2:0]

                      .a_i(addr_q),                   // I [8:0]
                      .wr_en_i(bar1_wr_en),               // I 
                      .rd_d_o(bar1_rd_data),                // O [31:0]
                      .wr_d_i(bar1_wr_data),                // I [31:0]

                      .init_rst_o(init_rst_o),            // O

                      .mrd_start_o(mrd_start_o),           // O
                      .mrd_done_i(mrd_done_i),            // I
                      .mrd_addr_o(mrd_addr_o),            // O [31:0]
                      .mrd_len_o(mrd_len_o),             // O [31:0]
                      .mrd_tlp_tc_o(mrd_tlp_tc_o),          // O [2:0]
                      .mrd_64b_en_o(mrd_64b_en_o),          // O
                      .mrd_phant_func_dis1_o(mrd_phant_func_dis1_o),  // O
                      .mrd_up_addr_o(mrd_up_addr_o),         // O [7:0]
                      .mrd_size_o(mrd_size_o),        // O [31:0]
                      .mrd_relaxed_order_o(mrd_relaxed_order_o),   // O
                      .mrd_nosnoop_o(mrd_nosnoop_o),         // O
                      .mrd_wrr_cnt_o(mrd_wrr_cnt_o),         // O [7:0]
					  .mrd_done_clr(mrd_done_clr),			// O

                      .mwr_start_o(mwr_start_o),           // O
                      .mwr_done_i(mwr_done_i),            // I
                      .mwr_addr_o(mwr_addr_o),            // O [31:0]
                      .mwr_len_o(mwr_len_o),             // O [31:0]
                      .mwr_tlp_tc_o(mwr_tlp_tc_o),          // O [2:0]
                      .mwr_64b_en_o(mwr_64b_en_o),          // O
                      .mwr_phant_func_dis1_o(mwr_phant_func_dis1_o),  // O
                      .mwr_up_addr_o(mwr_up_addr_o),         // O [7:0]
                      .mwr_size_o(mwr_size_o),        // O [31:0]
                      .mwr_relaxed_order_o(mwr_relaxed_order_o),   // O
                      .mwr_nosnoop_o(mwr_nosnoop_o),         // O
                      .mwr_wrr_cnt_o(mwr_wrr_cnt_o),         // O [7:0]
					  .mwr_done_clr(mwr_done_clr),

                      .cpl_ur_found_i(cpl_ur_found_i),        // I [7:0] 
                      .cpl_ur_tag_i(cpl_ur_tag_i),          // I [7:0]

                      .cpld_found_i(cpld_found_i),          // I [31:0]
                      .cpld_data_size_i(cpld_data_size_i),      // I [31:0]
                      .cpld_malformed_i(cpld_malformed_i),      // I
                      .cpl_streaming_o(cpl_streaming_o),       // O
                      .rd_metering_o(rd_metering_o),         // O
                      .cfg_interrupt_di(cfg_interrupt_di),      // O
                      .cfg_interrupt_do(cfg_interrupt_do),      // I
                      .cfg_interrupt_mmenable(cfg_interrupt_mmenable),   // I
                      .cfg_interrupt_msienable(cfg_interrupt_msienable),  // I
                      .cfg_interrupt_legacyclr(cfg_interrupt_legacyclr),  // O
`ifdef PCIE2_0
                      .pl_directed_link_change(pl_directed_link_change),
                      .pl_ltssm_state(pl_ltssm_state),
                      .pl_directed_link_width(pl_directed_link_width),
                      .pl_directed_link_speed(pl_directed_link_speed),
                      .pl_directed_link_auton(pl_directed_link_auton),
                      .pl_upstream_preemph_src(pl_upstream_preemph_src),
                      .pl_sel_link_width(pl_sel_link_width),
                      .pl_sel_link_rate(pl_sel_link_rate),
                      .pl_link_gen2_capable(pl_link_gen2_capable),
                      .pl_link_partner_gen2_supported(pl_link_partner_gen2_supported),
                      .pl_initial_link_width(pl_initial_link_width),
                      .pl_link_upcfg_capable(pl_link_upcfg_capable),
                      .pl_lane_reversal_mode(pl_lane_reversal_mode),
                      .pl_width_change_err_i(pl_width_change_err_i),
                      .pl_speed_change_err_i(pl_speed_change_err_i),
                      .clr_pl_width_change_err(clr_pl_width_change_err),
                      .clr_pl_speed_change_err(clr_pl_speed_change_err),
                      .clear_directed_speed_change_i(clear_directed_speed_change_i),

`endif
                      .trn_rnp_ok_n_o(trn_rnp_ok_n_o),
                      .trn_tstr_n_o(trn_tstr_n_o)
                      );
	
endmodule
