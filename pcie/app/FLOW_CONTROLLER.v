//--------------------------------------------------------------------------------
//-- Filename: FLOW_CONTROLLER.v
//--
//-- Description: FLOW CONTROLLER Module
//--              
//--              The module controls the TLP sending rates to ensure that the TLP
//-- TX buffer and RX buffer in the PCIE core do not overflow.
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module FLOW_CONTROLLER(
						clk,
						rst_n,
						init_rst_i,
						
						mrd_start_i,
						mrd_len_i,
						//mrd_cur_rd_count_i,
						mrd_tlp_sent_i,
						
						cpld_data_size_i,

						cfg_rd_comp_bound_i,
						rd_metering_i,
						
						mwr_start_i,
						trn_tbuf_av_i,
						
						mrd_start_fc_o,
						mwr_start_fc_o
    );
	
	// Set when the PCIe CORE was generated
	
	parameter			MAX_REQUEST_SIZE = 128;
	parameter			MAX_PAYLOAD_SIZE = 256;
	parameter			CPLH_CREDITS = 36;
	parameter			CPLD_CREDITS = 154;
	parameter			TRANSMIT_TLP_BUFFERD = 29;
	parameter			LIMIT_FC_MAX_NP = 18;

	input				clk;
	input				rst_n , init_rst_i;
	
	input				mrd_start_i;
	input [10:0]		mrd_len_i; // Memory Read Size Command (DWs)
	//input [15:0]		mrd_cur_rd_count_i;
	input [31:0]		mrd_tlp_sent_i;
	
	input				mwr_start_i;
	
	input [31:0]		cpld_data_size_i;
	input				cfg_rd_comp_bound_i; // Programmed RCB = 0=64B or 1=128B
	
	input				rd_metering_i; // enable send rate control
	
	input [5:0]			trn_tbuf_av_i;
	
	output				mrd_start_fc_o;
	output				mwr_start_fc_o;
	
	reg					mrd_start_fc_o;
	reg					mwr_start_fc_o;
	
	wire [31:0]			NPs_send = mrd_tlp_sent_i;
	wire [26:0]			NPs_recv = cpld_data_size_i >> 5;
	
	wire [26:0]			NPs_pending = NPs_send[26:0] - NPs_recv;

	always @ ( posedge clk ) begin
	
		if( !rst_n ) begin
		
			mrd_start_fc_o <= 1'b0;
			mwr_start_fc_o <= 1'b0;	
			
		end
		else begin
		
			if(init_rst_i) begin
			
				mrd_start_fc_o <= 1'b0;
				mwr_start_fc_o <= 1'b0;
			
			end
			
			if( rd_metering_i ) begin
			
`ifdef	SIMULATION

				if( NPs_pending > 0 )
					mrd_start_fc_o <= 1'b0;
				else
					mrd_start_fc_o <= mrd_start_i;
`else
				if ( ( NPs_pending < LIMIT_FC_MAX_NP + 5 ) && ( trn_tbuf_av_i > 1'b1 ) )
					mrd_start_fc_o <= mrd_start_i;
				else
					mrd_start_fc_o <= 1'b0;
`endif
			
			end
			else
				mrd_start_fc_o <= mrd_start_i;
				
			if( trn_tbuf_av_i > 1'b1  )
				mwr_start_fc_o <= mwr_start_i;
			else
				mwr_start_fc_o <= 1'b0;
		
		end
	
	end
	
endmodule
