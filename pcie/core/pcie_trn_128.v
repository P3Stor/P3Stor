//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Virtex-6 Integrated Block for PCI Express
// File       : pcie_trn_128.v
// Version    : 1.7
`timescale 1ps/1ps

module pcie_trn_128 #(
   parameter TCQ = 100
)(

   input            user_clk,
   input            block_clk,
   input            rst_n_250,
   input            rst_n_500,

   input  [1:0]     cfgpmcsrpowerstate,

//////////////////
// to/from user //
//////////////////
   output [6:0]     trn_rbar_hit_n_o,
   output [127:0]   trn_rd_o,
   output           trn_recrc_err_n_o,
   output           trn_rsof_n_o,
   output           trn_reof_n_o,
   output           trn_rerrfwd_n_o,
   output [1:0]     trn_rrem_n_o,
   output           trn_rsrc_dsc_n_o,
   output           trn_rsrc_rdy_n_o,
   input            trn_rdst_rdy_n_i,
   input            trn_rnpok_n_i,

   output [5:0]     trn_tbuf_av_o,
   output           trn_tdst_rdy_n_o,
   output           trn_terr_drop_n_o,
   input  [127:0]   trn_td_i,
   input            trn_tecrc_gen_n_i,
   input            trn_terr_fwd_n_i,
   input  [1:0]     trn_trem_n_i,
   input            trn_tsof_n_i,
   input            trn_teof_n_i,
   input            trn_tsrc_dsc_n_i,
   input            trn_tsrc_rdy_n_i,
   input            trn_tstr_n_i,

   output [11:0]    trn_fc_cpld_o,
   output [7:0]     trn_fc_cplh_o,
   output [11:0]    trn_fc_npd_o,
   output [7:0]     trn_fc_nph_o,
   output [11:0]    trn_fc_pd_o,
   output [7:0]     trn_fc_ph_o,
   input  [2:0]     trn_fc_sel_i,
 

////////////////
// to/from EP //
////////////////

   input [6:0]      TRNRBARHITN_i,
   input [63:0]     TRNRD_i,
   input            TRNRECRCERRN_i,
   input            TRNRSOFN_i,
   input            TRNREOFN_i,
   input            TRNRERRFWDN_i,
   input            TRNRREMN_i,
   input            TRNRSRCDSCN_i,
   input            TRNRSRCRDYN_i,
   output           TRNRDSTRDYN_o,
   output           TRNRNPOKN_o,

   input [5:0]      TRNTBUFAV_i,
   input            TRNTCFGREQN_i,
   input            TRNTDSTRDYN_i,
   input            TRNTERRDROPN_i,
   output           TRNTCFGGNTN_o,
   output  [63:0]   TRNTD_o,
   output           TRNTECRCGENN_o,
   output           TRNTERRFWDN_o,
   output           TRNTREMN_o,
   output           TRNTSOFN_o,
   output           TRNTEOFN_o,
   output           TRNTSRCDSCN_o,
   output           TRNTSRCRDYN_o,
   output           TRNTSTRN_o,

   input [11:0]     TRNFCCPLD_i,
   input [7:0]      TRNFCCPLH_i,
   input [11:0]     TRNFCNPD_i,
   input [7:0]      TRNFCNPH_i,
   input [11:0]     TRNFCPD_i,
   input [7:0]      TRNFCPH_i,
   output  [2:0]    TRNFCSEL_o
 

    );

reg [11:0]     TRNFCCPLD_i_250;
reg [7:0]      TRNFCCPLH_i_250;
reg [11:0]     TRNFCNPD_i_250;
reg [7:0]      TRNFCNPH_i_250;
reg [11:0]     TRNFCPD_i_250;
reg [7:0]      TRNFCPH_i_250;

reg [2:0]      trn_fc_sel_i_250;
reg [2:0]      trn_fc_sel_i_250_500;


assign trn_fc_cpld_o = TRNFCCPLD_i_250;
assign trn_fc_cplh_o = TRNFCCPLH_i_250;
assign trn_fc_npd_o  = TRNFCNPD_i_250;
assign trn_fc_nph_o  = TRNFCNPH_i_250;
assign trn_fc_pd_o   = TRNFCPD_i_250;
assign trn_fc_ph_o   = TRNFCPH_i_250;

assign TRNFCSEL_o   = trn_fc_sel_i_250_500;



// -------------------------------------------------------------------------
//                                500Mhz
// -------------------------------------------------------------------------

always @(posedge block_clk)
begin
   if (~rst_n_500)
      trn_fc_sel_i_250_500  <= #TCQ 3'd0;

   else 
      trn_fc_sel_i_250_500  <= #TCQ trn_fc_sel_i_250;

end



// -------------------------------------------------------------------------
//                                250Mhz
// -------------------------------------------------------------------------

always @(posedge user_clk)
begin
   if (~rst_n_250)
   begin
      TRNFCCPLD_i_250     <= #TCQ 12'd0;
      TRNFCCPLH_i_250     <= #TCQ  8'd0;
      TRNFCNPD_i_250      <= #TCQ 12'd0;
      TRNFCNPH_i_250      <= #TCQ  8'd0;
      TRNFCPD_i_250       <= #TCQ 12'd0;
      TRNFCPH_i_250       <= #TCQ  8'd0;

      trn_fc_sel_i_250    <= #TCQ trn_fc_sel_i;
   end else begin
      TRNFCCPLD_i_250     <= #TCQ TRNFCCPLD_i;
      TRNFCCPLH_i_250     <= #TCQ TRNFCCPLH_i;
      TRNFCNPD_i_250      <= #TCQ TRNFCNPD_i;
      TRNFCNPH_i_250      <= #TCQ TRNFCNPH_i;
      TRNFCPD_i_250       <= #TCQ TRNFCPD_i;
      TRNFCPH_i_250       <= #TCQ TRNFCPH_i;

      trn_fc_sel_i_250    <= #TCQ trn_fc_sel_i;
   end
end









//-------------------------------------------------------
// TX module
//-------------------------------------------------------

trn_tx_128 #(
   .TCQ( TCQ )

) trn_tx_128_i (

      .user_clk( user_clk ),
      .block_clk( block_clk ),

      .rst_n_250( rst_n_250 ),
      .rst_n_500( rst_n_500 ),
      .cfgpmcsrpowerstate( cfgpmcsrpowerstate ),

      .trn_tbuf_av_o( trn_tbuf_av_o ),
      .trn_tdst_rdy_n_o( trn_tdst_rdy_n_o ),
      .trn_terr_drop_n_o( trn_terr_drop_n_o ),
      .trn_td_i( trn_td_i ),
      .trn_tecrc_gen_n_i( trn_tecrc_gen_n_i ),
      .trn_terr_fwd_n_i( trn_terr_fwd_n_i ),
      .trn_trem_n_i( trn_trem_n_i ),
      .trn_tsof_n_i( trn_tsof_n_i ),
      .trn_teof_n_i( trn_teof_n_i ),
      .trn_tsrc_dsc_n_i( trn_tsrc_dsc_n_i ),
      .trn_tsrc_rdy_n_i( trn_tsrc_rdy_n_i  ),
      .trn_tstr_n_i( trn_tstr_n_i ),

      .TRNTBUFAV_i( TRNTBUFAV_i ),
      .TRNTCFGREQN_i( TRNTCFGREQN_i ),
      .TRNTDSTRDYN_i( TRNTDSTRDYN_i ),
      .TRNTERRDROPN_i( TRNTERRDROPN_i ),
      .TRNTCFGGNTN_o( TRNTCFGGNTN_o ),
      .TRNTD_o( TRNTD_o ),
      .TRNTECRCGENN_o( TRNTECRCGENN_o ),
      .TRNTERRFWDN_o( TRNTERRFWDN_o ),
      .TRNTREMN_o( TRNTREMN_o ),
      .TRNTSOFN_o( TRNTSOFN_o ),
      .TRNTEOFN_o( TRNTEOFN_o ),
      .TRNTSRCDSCN_o( TRNTSRCDSCN_o ),
      .TRNTSRCRDYN_o( TRNTSRCRDYN_o ),
      .TRNTSTRN_o( TRNTSTRN_o )

);


//-------------------------------------------------------
// RX module
//-------------------------------------------------------


trn_rx_128 #(
   .TCQ( TCQ )

) trn_rx_128_i (

      .user_clk( user_clk ),
      .block_clk( block_clk ),
      .rst_n_250( rst_n_250 ),
      .rst_n_500( rst_n_500 ),

      .trn_rbar_hit_n_o( trn_rbar_hit_n_o ),
      .trn_rd_o( trn_rd_o ),
      .trn_recrc_err_n_o( trn_recrc_err_n_o ),
      .trn_rsof_n_o( trn_rsof_n_o ),
      .trn_reof_n_o( trn_reof_n_o ),
      .trn_rerrfwd_n_o( trn_rerrfwd_n_o ),
      .trn_rrem_n_o( trn_rrem_n_o ),
      .trn_rsrc_dsc_n_o( trn_rsrc_dsc_n_o ),
      .trn_rsrc_rdy_n_o( trn_rsrc_rdy_n_o ),
      .trn_rdst_rdy_n_i( trn_rdst_rdy_n_i ),
      .trn_rnpok_n_i( trn_rnpok_n_i ),

      .TRNRBARHITN_i( TRNRBARHITN_i ),
      .TRNRD_i( TRNRD_i ),
      .TRNRECRCERRN_i( TRNRECRCERRN_i ),
      .TRNRSOFN_i( TRNRSOFN_i ),
      .TRNREOFN_i( TRNREOFN_i ),
      .TRNRERRFWDN_i( TRNRERRFWDN_i ),
      .TRNRREMN_i( TRNRREMN_i ),
      .TRNRSRCDSCN_i( TRNRSRCDSCN_i ),
      .TRNRSRCRDYN_i( TRNRSRCRDYN_i ),
      .TRNRDSTRDYN_o( TRNRDSTRDYN_o ),
      .TRNRNPOKN_o( TRNRNPOKN_o )

);


endmodule 
