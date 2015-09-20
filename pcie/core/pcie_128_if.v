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
// File       : pcie_128_if.v
// Version    : 1.7
`timescale 1ps/1ps

module pcie_128_if #(
   parameter TCQ = 100
)(

   input            rst_n_250,
   input            rst_n_500,

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
   output  [2:0]    TRNFCSEL_o,


//--------------------------------------

   input            BLOCKCLK,
   input            USERCLK,


   input          CFGCOMMANDBUSMASTERENABLE_i,
   input          CFGCOMMANDINTERRUPTDISABLE_i,
   input          CFGCOMMANDIOENABLE_i,
   input          CFGCOMMANDMEMENABLE_i,
   input          CFGCOMMANDSERREN_i,
   input          CFGDEVCONTROLAUXPOWEREN_i,
   input          CFGDEVCONTROLCORRERRREPORTINGEN_i,
   input          CFGDEVCONTROLENABLERO_i,
   input          CFGDEVCONTROLEXTTAGEN_i,
   input          CFGDEVCONTROLFATALERRREPORTINGEN_i,
   input  [2:0]   CFGDEVCONTROLMAXPAYLOAD_i,
   input  [2:0]   CFGDEVCONTROLMAXREADREQ_i,
   input          CFGDEVCONTROLNONFATALREPORTINGEN_i,
   input          CFGDEVCONTROLNOSNOOPEN_i,
   input          CFGDEVCONTROLPHANTOMEN_i,
   input          CFGDEVCONTROLURERRREPORTINGEN_i,
   input          CFGDEVCONTROL2CPLTIMEOUTDIS_i,
   input  [3:0]   CFGDEVCONTROL2CPLTIMEOUTVAL_i,
   input          CFGDEVSTATUSCORRERRDETECTED_i,
   input          CFGDEVSTATUSFATALERRDETECTED_i,
   input          CFGDEVSTATUSNONFATALERRDETECTED_i,
   input          CFGDEVSTATUSURDETECTED_i,
   input  [31:0]  CFGDO_i,
   input          CFGERRCPLRDYN_i,
   input  [7:0]   CFGINTERRUPTDO_i,
   input  [2:0]   CFGINTERRUPTMMENABLE_i,
   input          CFGINTERRUPTMSIENABLE_i,
   input          CFGINTERRUPTMSIXENABLE_i,
   input          CFGINTERRUPTMSIXFM_i,
   input          CFGINTERRUPTRDYN_i,
   input          CFGLINKCONTROLRCB_i,
   input  [1:0]   CFGLINKCONTROLASPMCONTROL_i,
   input          CFGLINKCONTROLAUTOBANDWIDTHINTEN_i,
   input          CFGLINKCONTROLBANDWIDTHINTEN_i,
   input          CFGLINKCONTROLCLOCKPMEN_i,
   input          CFGLINKCONTROLCOMMONCLOCK_i,
   input          CFGLINKCONTROLEXTENDEDSYNC_i,
   input          CFGLINKCONTROLHWAUTOWIDTHDIS_i,
   input          CFGLINKCONTROLLINKDISABLE_i,
   input          CFGLINKCONTROLRETRAINLINK_i,
   input          CFGLINKSTATUSAUTOBANDWIDTHSTATUS_i,
   input          CFGLINKSTATUSBANDWITHSTATUS_i,
   input  [1:0]   CFGLINKSTATUSCURRENTSPEED_i,
   input          CFGLINKSTATUSDLLACTIVE_i,
   input          CFGLINKSTATUSLINKTRAINING_i,
   input  [3:0]   CFGLINKSTATUSNEGOTIATEDWIDTH_i,
   input  [15:0]  CFGMSGDATA_i,
   input          CFGMSGRECEIVED_i,
   input          CFGMSGRECEIVEDPMETO_i,
   input  [2:0]   CFGPCIELINKSTATE_i,
   input          CFGPMCSRPMEEN_i,
   input          CFGPMCSRPMESTATUS_i,
   input  [1:0]   CFGPMCSRPOWERSTATE_i,
   input          CFGRDWRDONEN_i,
   input          CFGMSGRECEIVEDSETSLOTPOWERLIMIT_i,
   input          CFGMSGRECEIVEDUNLOCK_i,
   input          CFGMSGRECEIVEDPMASNAK_i,
   input          CFGPMRCVREQACKN_i,
   input          CFGTRANSACTION_i,
   input  [6:0]   CFGTRANSACTIONADDR_i,
   input          CFGTRANSACTIONTYPE_i,

   output [3:0]   CFGBYTEENN_o,  
   output [31:0]  CFGDI_o,
   output [63:0]  CFGDSN_o,
   output [9:0]   CFGDWADDR_o,
   output         CFGERRACSN_o,
   output         CFGERRCORN_o,
   output         CFGERRCPLABORTN_o,
   output         CFGERRCPLTIMEOUTN_o,
   output         CFGERRCPLUNEXPECTN_o,
   output         CFGERRECRCN_o,
   output         CFGERRLOCKEDN_o,
   output         CFGERRPOSTEDN_o,
   output [47:0]  CFGERRTLPCPLHEADER_o,
   output         CFGERRURN_o,
   output         CFGINTERRUPTASSERTN_o,
   output [7:0]   CFGINTERRUPTDI_o,
   output         CFGINTERRUPTN_o,
   output         CFGPMDIRECTASPML1N_o,
   output         CFGPMSENDPMACKN_o,
   output         CFGPMSENDPMETON_o,
   output         CFGPMSENDPMNAKN_o,
   output         CFGPMTURNOFFOKN_o,
   output         CFGPMWAKEN_o,
   output [7:0]   CFGPORTNUMBER_o,
   output         CFGRDENN_o,
   output         CFGTRNPENDINGN_o,
   output         CFGWRENN_o,
   output         CFGWRREADONLYN_o,
   output         CFGWRRW1CASRWN_o,

//--------------------------------------------------------

   output          CFGCOMMANDBUSMASTERENABLE_o, 
   output          CFGCOMMANDINTERRUPTDISABLE_o,
   output          CFGCOMMANDIOENABLE_o,
   output          CFGCOMMANDMEMENABLE_o,
   output          CFGCOMMANDSERREN_o,
   output          CFGDEVCONTROLAUXPOWEREN_o,
   output          CFGDEVCONTROLCORRERRREPORTINGEN_o,
   output          CFGDEVCONTROLENABLERO_o,
   output          CFGDEVCONTROLEXTTAGEN_o,
   output          CFGDEVCONTROLFATALERRREPORTINGEN_o,
   output  [2:0]   CFGDEVCONTROLMAXPAYLOAD_o,
   output  [2:0]   CFGDEVCONTROLMAXREADREQ_o,
   output          CFGDEVCONTROLNONFATALREPORTINGEN_o,
   output          CFGDEVCONTROLNOSNOOPEN_o,
   output          CFGDEVCONTROLPHANTOMEN_o,
   output          CFGDEVCONTROLURERRREPORTINGEN_o,
   output          CFGDEVCONTROL2CPLTIMEOUTDIS_o,
   output  [3:0]   CFGDEVCONTROL2CPLTIMEOUTVAL_o,
   output          CFGDEVSTATUSCORRERRDETECTED_o,
   output          CFGDEVSTATUSFATALERRDETECTED_o,
   output          CFGDEVSTATUSNONFATALERRDETECTED_o,
   output          CFGDEVSTATUSURDETECTED_o,
   output  [31:0]  CFGDO_o,
   output          CFGERRCPLRDYN_o,
   output  [7:0]   CFGINTERRUPTDO_o,
   output  [2:0]   CFGINTERRUPTMMENABLE_o,
   output          CFGINTERRUPTMSIENABLE_o,
   output          CFGINTERRUPTMSIXENABLE_o,
   output          CFGINTERRUPTMSIXFM_o,
   output          CFGINTERRUPTRDYN_o,
   output          CFGLINKCONTROLRCB_o,
   output  [1:0]   CFGLINKCONTROLASPMCONTROL_o,
   output          CFGLINKCONTROLAUTOBANDWIDTHINTEN_o,
   output          CFGLINKCONTROLBANDWIDTHINTEN_o,
   output          CFGLINKCONTROLCLOCKPMEN_o,
   output          CFGLINKCONTROLCOMMONCLOCK_o,
   output          CFGLINKCONTROLEXTENDEDSYNC_o,
   output          CFGLINKCONTROLHWAUTOWIDTHDIS_o,
   output          CFGLINKCONTROLLINKDISABLE_o,
   output          CFGLINKCONTROLRETRAINLINK_o,
   output          CFGLINKSTATUSAUTOBANDWIDTHSTATUS_o,
   output          CFGLINKSTATUSBANDWITHSTATUS_o,
   output  [1:0]   CFGLINKSTATUSCURRENTSPEED_o,
   output          CFGLINKSTATUSDLLACTIVE_o,
   output          CFGLINKSTATUSLINKTRAINING_o,
   output  [3:0]   CFGLINKSTATUSNEGOTIATEDWIDTH_o,
   output  [15:0]  CFGMSGDATA_o,
   output          CFGMSGRECEIVED_o,
   output          CFGMSGRECEIVEDPMETO_o,
   output  [2:0]   CFGPCIELINKSTATE_o,
   output          CFGPMCSRPMEEN_o,
   output          CFGPMCSRPMESTATUS_o,
   output  [1:0]   CFGPMCSRPOWERSTATE_o,
   output          CFGRDWRDONEN_o,
   output          CFGMSGRECEIVEDSETSLOTPOWERLIMIT_o,
   output          CFGMSGRECEIVEDUNLOCK_o,
   output          CFGMSGRECEIVEDPMASNAK_o,
   output          CFGPMRCVREQACKN_o,
   output          CFGTRANSACTION_o,
   output  [6:0]   CFGTRANSACTIONADDR_o,
   output          CFGTRANSACTIONTYPE_o,


   input   [3:0]   CFGBYTEENN_i,
   input   [31:0]  CFGDI_i,
   input   [63:0]  CFGDSN_i,
   input   [9:0]   CFGDWADDR_i,
   input           CFGERRACSN_i,
   input           CFGERRCORN_i,
   input           CFGERRCPLABORTN_i,
   input           CFGERRCPLTIMEOUTN_i,
   input           CFGERRCPLUNEXPECTN_i,
   input           CFGERRECRCN_i,
   input           CFGERRLOCKEDN_i,
   input           CFGERRPOSTEDN_i,
   input   [47:0]  CFGERRTLPCPLHEADER_i,
   input           CFGERRURN_i,
   input           CFGINTERRUPTASSERTN_i,
   input   [7:0]   CFGINTERRUPTDI_i,
   input           CFGINTERRUPTN_i,
   input           CFGPMDIRECTASPML1N_i,
   input           CFGPMSENDPMACKN_i,
   input           CFGPMSENDPMETON_i,
   input           CFGPMSENDPMNAKN_i,
   input           CFGPMTURNOFFOKN_i,
   input           CFGPMWAKEN_i,
   input   [7:0]   CFGPORTNUMBER_i,
   input           CFGRDENN_i,
   input           CFGTRNPENDINGN_i,
   input           CFGWRENN_i,
   input           CFGWRREADONLYN_i,
   input           CFGWRRW1CASRWN_i

    );




pcie_trn_128 #(
   .TCQ ( TCQ )

) pcie_trn_128_i (

              .user_clk      ( USERCLK ),
              .block_clk     ( BLOCKCLK  ),
              .rst_n_250     ( rst_n_250 ),
              .rst_n_500     ( rst_n_500 ),


`ifdef SILICON_1_0
              .cfgpmcsrpowerstate ( 2'h0 ),
`else
              .cfgpmcsrpowerstate ( CFGPMCSRPOWERSTATE_o ),
`endif


//////////////////
// to/from user //
//////////////////
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
              .trn_tsrc_rdy_n_i( trn_tsrc_rdy_n_i ),
              .trn_tstr_n_i( trn_tstr_n_i ),

              .trn_fc_cpld_o( trn_fc_cpld_o ),
              .trn_fc_cplh_o( trn_fc_cplh_o ),
              .trn_fc_npd_o( trn_fc_npd_o ),
              .trn_fc_nph_o( trn_fc_nph_o ),
              .trn_fc_pd_o( trn_fc_pd_o ),
              .trn_fc_ph_o( trn_fc_ph_o ),
              .trn_fc_sel_i( trn_fc_sel_i ),

////////////////
// to/from EP //
////////////////
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
              .TRNRNPOKN_o( TRNRNPOKN_o ),

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
              .TRNTSTRN_o( TRNTSTRN_o ),

              .TRNFCCPLD_i( TRNFCCPLD_i ),
              .TRNFCCPLH_i( TRNFCCPLH_i ),
              .TRNFCNPD_i( TRNFCNPD_i ),
              .TRNFCNPH_i( TRNFCNPH_i ),
              .TRNFCPD_i( TRNFCPD_i ),
              .TRNFCPH_i( TRNFCPH_i ),
              .TRNFCSEL_o( TRNFCSEL_o )

);













pcie_cfg_128 #(
   .TCQ( TCQ )
) pcie_cfg_128_i (

   .user_clk      ( USERCLK ),
   .block_clk     ( BLOCKCLK ),
   .rst_n_500     ( rst_n_500 ),

   .CFGCOMMANDBUSMASTERENABLE_i( CFGCOMMANDBUSMASTERENABLE_i ),
   .CFGCOMMANDINTERRUPTDISABLE_i( CFGCOMMANDINTERRUPTDISABLE_i ),
   .CFGCOMMANDIOENABLE_i( CFGCOMMANDIOENABLE_i ),
   .CFGCOMMANDMEMENABLE_i( CFGCOMMANDMEMENABLE_i ),
   .CFGCOMMANDSERREN_i( CFGCOMMANDSERREN_i ),
   .CFGDEVCONTROLAUXPOWEREN_i( CFGDEVCONTROLAUXPOWEREN_i ),
   .CFGDEVCONTROLCORRERRREPORTINGEN_i( CFGDEVCONTROLCORRERRREPORTINGEN_i ),
   .CFGDEVCONTROLENABLERO_i( CFGDEVCONTROLENABLERO_i ),
   .CFGDEVCONTROLEXTTAGEN_i( CFGDEVCONTROLEXTTAGEN_i ),
   .CFGDEVCONTROLFATALERRREPORTINGEN_i( CFGDEVCONTROLFATALERRREPORTINGEN_i ),
   .CFGDEVCONTROLMAXPAYLOAD_i( CFGDEVCONTROLMAXPAYLOAD_i ),
   .CFGDEVCONTROLMAXREADREQ_i( CFGDEVCONTROLMAXREADREQ_i ),
   .CFGDEVCONTROLNONFATALREPORTINGEN_i( CFGDEVCONTROLNONFATALREPORTINGEN_i ),
   .CFGDEVCONTROLNOSNOOPEN_i( CFGDEVCONTROLNOSNOOPEN_i ),
   .CFGDEVCONTROLPHANTOMEN_i( CFGDEVCONTROLPHANTOMEN_i ),
   .CFGDEVCONTROLURERRREPORTINGEN_i( CFGDEVCONTROLURERRREPORTINGEN_i ),
   .CFGDEVCONTROL2CPLTIMEOUTDIS_i( CFGDEVCONTROL2CPLTIMEOUTDIS_i ),
   .CFGDEVCONTROL2CPLTIMEOUTVAL_i( CFGDEVCONTROL2CPLTIMEOUTVAL_i ),
   .CFGDEVSTATUSCORRERRDETECTED_i( CFGDEVSTATUSCORRERRDETECTED_i ),
   .CFGDEVSTATUSFATALERRDETECTED_i( CFGDEVSTATUSFATALERRDETECTED_i ),
   .CFGDEVSTATUSNONFATALERRDETECTED_i( CFGDEVSTATUSNONFATALERRDETECTED_i ),
   .CFGDEVSTATUSURDETECTED_i( CFGDEVSTATUSURDETECTED_i ),
   .CFGDO_i( CFGDO_i ),
   .CFGERRCPLRDYN_i( CFGERRCPLRDYN_i ),
   .CFGINTERRUPTDO_i( CFGINTERRUPTDO_i ),
   .CFGINTERRUPTMMENABLE_i( CFGINTERRUPTMMENABLE_i ),
   .CFGINTERRUPTMSIENABLE_i( CFGINTERRUPTMSIENABLE_i ),
   .CFGINTERRUPTMSIXENABLE_i( CFGINTERRUPTMSIXENABLE_i ),
   .CFGINTERRUPTMSIXFM_i( CFGINTERRUPTMSIXFM_i ),
   .CFGINTERRUPTRDYN_i( CFGINTERRUPTRDYN_i ),
   .CFGLINKCONTROLRCB_i( CFGLINKCONTROLRCB_i ),
   .CFGLINKCONTROLASPMCONTROL_i( CFGLINKCONTROLASPMCONTROL_i ),
   .CFGLINKCONTROLAUTOBANDWIDTHINTEN_i( CFGLINKCONTROLAUTOBANDWIDTHINTEN_i ),
   .CFGLINKCONTROLBANDWIDTHINTEN_i( CFGLINKCONTROLBANDWIDTHINTEN_i ),
   .CFGLINKCONTROLCLOCKPMEN_i( CFGLINKCONTROLCLOCKPMEN_i ),
   .CFGLINKCONTROLCOMMONCLOCK_i( CFGLINKCONTROLCOMMONCLOCK_i ),
   .CFGLINKCONTROLEXTENDEDSYNC_i( CFGLINKCONTROLEXTENDEDSYNC_i ),
   .CFGLINKCONTROLHWAUTOWIDTHDIS_i( CFGLINKCONTROLHWAUTOWIDTHDIS_i ),
   .CFGLINKCONTROLLINKDISABLE_i( CFGLINKCONTROLLINKDISABLE_i ),
   .CFGLINKCONTROLRETRAINLINK_i( CFGLINKCONTROLRETRAINLINK_i ),
   .CFGLINKSTATUSAUTOBANDWIDTHSTATUS_i( CFGLINKSTATUSAUTOBANDWIDTHSTATUS_i ),
   .CFGLINKSTATUSBANDWITHSTATUS_i( CFGLINKSTATUSBANDWITHSTATUS_i ),
   .CFGLINKSTATUSCURRENTSPEED_i( CFGLINKSTATUSCURRENTSPEED_i ),
   .CFGLINKSTATUSDLLACTIVE_i( CFGLINKSTATUSDLLACTIVE_i ),
   .CFGLINKSTATUSLINKTRAINING_i( CFGLINKSTATUSLINKTRAINING_i ),
   .CFGLINKSTATUSNEGOTIATEDWIDTH_i( CFGLINKSTATUSNEGOTIATEDWIDTH_i ),
   .CFGMSGDATA_i( CFGMSGDATA_i ),
   .CFGMSGRECEIVED_i( CFGMSGRECEIVED_i ),
   .CFGMSGRECEIVEDPMETO_i( CFGMSGRECEIVEDPMETO_i ),
   .CFGPCIELINKSTATE_i( CFGPCIELINKSTATE_i ),
   .CFGPMCSRPMEEN_i( CFGPMCSRPMEEN_i ),
   .CFGPMCSRPMESTATUS_i( CFGPMCSRPMESTATUS_i ),
   .CFGPMCSRPOWERSTATE_i( CFGPMCSRPOWERSTATE_i ),
   .CFGRDWRDONEN_i( CFGRDWRDONEN_i ),
   .CFGMSGRECEIVEDSETSLOTPOWERLIMIT_i( CFGMSGRECEIVEDSETSLOTPOWERLIMIT_i ),
   .CFGMSGRECEIVEDUNLOCK_i( CFGMSGRECEIVEDUNLOCK_i ),
   .CFGMSGRECEIVEDPMASNAK_i( CFGMSGRECEIVEDPMASNAK_i ),
   .CFGPMRCVREQACKN_i( CFGPMRCVREQACKN_i ),
   .CFGTRANSACTION_i( CFGTRANSACTION_i ),
   .CFGTRANSACTIONADDR_i( CFGTRANSACTIONADDR_i ),
   .CFGTRANSACTIONTYPE_i( CFGTRANSACTIONTYPE_i ),

   .CFGBYTEENN_o( CFGBYTEENN_o ),
   .CFGDI_o( CFGDI_o ),
   .CFGDSN_o( CFGDSN_o ),
   .CFGDWADDR_o( CFGDWADDR_o ),
   .CFGERRACSN_o( CFGERRACSN_o ),
   .CFGERRCORN_o( CFGERRCORN_o ),
   .CFGERRCPLABORTN_o( CFGERRCPLABORTN_o ),
   .CFGERRCPLTIMEOUTN_o( CFGERRCPLTIMEOUTN_o ),
   .CFGERRCPLUNEXPECTN_o( CFGERRCPLUNEXPECTN_o ),
   .CFGERRECRCN_o( CFGERRECRCN_o ),
   .CFGERRLOCKEDN_o( CFGERRLOCKEDN_o ),
   .CFGERRPOSTEDN_o( CFGERRPOSTEDN_o ),
   .CFGERRTLPCPLHEADER_o( CFGERRTLPCPLHEADER_o ),
   .CFGERRURN_o( CFGERRURN_o ),
   .CFGINTERRUPTASSERTN_o( CFGINTERRUPTASSERTN_o ),
   .CFGINTERRUPTDI_o( CFGINTERRUPTDI_o ),
   .CFGINTERRUPTN_o( CFGINTERRUPTN_o ),
   .CFGPMDIRECTASPML1N_o( CFGPMDIRECTASPML1N_o ),
   .CFGPMSENDPMACKN_o( CFGPMSENDPMACKN_o ),
   .CFGPMSENDPMETON_o( CFGPMSENDPMETON_o ),
   .CFGPMSENDPMNAKN_o( CFGPMSENDPMNAKN_o ),
   .CFGPMTURNOFFOKN_o( CFGPMTURNOFFOKN_o ),
   .CFGPMWAKEN_o( CFGPMWAKEN_o ),
   .CFGPORTNUMBER_o( CFGPORTNUMBER_o ),
   .CFGRDENN_o( CFGRDENN_o ),
   .CFGTRNPENDINGN_o( CFGTRNPENDINGN_o ),
   .CFGWRENN_o( CFGWRENN_o ),
   .CFGWRREADONLYN_o( CFGWRREADONLYN_o ),
   .CFGWRRW1CASRWN_o( CFGWRRW1CASRWN_o ),

//------------------

   .CFGCOMMANDBUSMASTERENABLE_o( CFGCOMMANDBUSMASTERENABLE_o ),
   .CFGCOMMANDINTERRUPTDISABLE_o( CFGCOMMANDINTERRUPTDISABLE_o ),
   .CFGCOMMANDIOENABLE_o( CFGCOMMANDIOENABLE_o ),
   .CFGCOMMANDMEMENABLE_o( CFGCOMMANDMEMENABLE_o ),
   .CFGCOMMANDSERREN_o( CFGCOMMANDSERREN_o ),
   .CFGDEVCONTROLAUXPOWEREN_o( CFGDEVCONTROLAUXPOWEREN_o ),
   .CFGDEVCONTROLCORRERRREPORTINGEN_o( CFGDEVCONTROLCORRERRREPORTINGEN_o ),
   .CFGDEVCONTROLENABLERO_o( CFGDEVCONTROLENABLERO_o ),
   .CFGDEVCONTROLEXTTAGEN_o( CFGDEVCONTROLEXTTAGEN_o ),
   .CFGDEVCONTROLFATALERRREPORTINGEN_o( CFGDEVCONTROLFATALERRREPORTINGEN_o ),
   .CFGDEVCONTROLMAXPAYLOAD_o( CFGDEVCONTROLMAXPAYLOAD_o ),
   .CFGDEVCONTROLMAXREADREQ_o( CFGDEVCONTROLMAXREADREQ_o ),
   .CFGDEVCONTROLNONFATALREPORTINGEN_o( CFGDEVCONTROLNONFATALREPORTINGEN_o ),
   .CFGDEVCONTROLNOSNOOPEN_o( CFGDEVCONTROLNOSNOOPEN_o ),
   .CFGDEVCONTROLPHANTOMEN_o( CFGDEVCONTROLPHANTOMEN_o ),
   .CFGDEVCONTROLURERRREPORTINGEN_o( CFGDEVCONTROLURERRREPORTINGEN_o ),
   .CFGDEVCONTROL2CPLTIMEOUTDIS_o( CFGDEVCONTROL2CPLTIMEOUTDIS_o ),
   .CFGDEVCONTROL2CPLTIMEOUTVAL_o( CFGDEVCONTROL2CPLTIMEOUTVAL_o ),
   .CFGDEVSTATUSCORRERRDETECTED_o( CFGDEVSTATUSCORRERRDETECTED_o ),
   .CFGDEVSTATUSFATALERRDETECTED_o( CFGDEVSTATUSFATALERRDETECTED_o ),
   .CFGDEVSTATUSNONFATALERRDETECTED_o( CFGDEVSTATUSNONFATALERRDETECTED_o ),
   .CFGDEVSTATUSURDETECTED_o( CFGDEVSTATUSURDETECTED_o ),
   .CFGDO_o( CFGDO_o ),
   .CFGERRCPLRDYN_o( CFGERRCPLRDYN_o ),
   .CFGINTERRUPTDO_o( CFGINTERRUPTDO_o ),
   .CFGINTERRUPTMMENABLE_o( CFGINTERRUPTMMENABLE_o ),
   .CFGINTERRUPTMSIENABLE_o( CFGINTERRUPTMSIENABLE_o ),
   .CFGINTERRUPTMSIXENABLE_o( CFGINTERRUPTMSIXENABLE_o ),
   .CFGINTERRUPTMSIXFM_o( CFGINTERRUPTMSIXFM_o ),
   .CFGINTERRUPTRDYN_o( CFGINTERRUPTRDYN_o ),
   .CFGLINKCONTROLRCB_o( CFGLINKCONTROLRCB_o ),
   .CFGLINKCONTROLASPMCONTROL_o( CFGLINKCONTROLASPMCONTROL_o ),
   .CFGLINKCONTROLAUTOBANDWIDTHINTEN_o( CFGLINKCONTROLAUTOBANDWIDTHINTEN_o ),
   .CFGLINKCONTROLBANDWIDTHINTEN_o( CFGLINKCONTROLBANDWIDTHINTEN_o ),
   .CFGLINKCONTROLCLOCKPMEN_o( CFGLINKCONTROLCLOCKPMEN_o ),
   .CFGLINKCONTROLCOMMONCLOCK_o( CFGLINKCONTROLCOMMONCLOCK_o ),
   .CFGLINKCONTROLEXTENDEDSYNC_o( CFGLINKCONTROLEXTENDEDSYNC_o ),
   .CFGLINKCONTROLHWAUTOWIDTHDIS_o( CFGLINKCONTROLHWAUTOWIDTHDIS_o ),
   .CFGLINKCONTROLLINKDISABLE_o( CFGLINKCONTROLLINKDISABLE_o ),
   .CFGLINKCONTROLRETRAINLINK_o( CFGLINKCONTROLRETRAINLINK_o ),
   .CFGLINKSTATUSAUTOBANDWIDTHSTATUS_o( CFGLINKSTATUSAUTOBANDWIDTHSTATUS_o ),
   .CFGLINKSTATUSBANDWITHSTATUS_o( CFGLINKSTATUSBANDWITHSTATUS_o ),
   .CFGLINKSTATUSCURRENTSPEED_o( CFGLINKSTATUSCURRENTSPEED_o ),
   .CFGLINKSTATUSDLLACTIVE_o( CFGLINKSTATUSDLLACTIVE_o ),
   .CFGLINKSTATUSLINKTRAINING_o( CFGLINKSTATUSLINKTRAINING_o ),
   .CFGLINKSTATUSNEGOTIATEDWIDTH_o( CFGLINKSTATUSNEGOTIATEDWIDTH_o ),
   .CFGMSGDATA_o( CFGMSGDATA_o ),
   .CFGMSGRECEIVED_o( CFGMSGRECEIVED_o ),
   .CFGMSGRECEIVEDPMETO_o( CFGMSGRECEIVEDPMETO_o ),
   .CFGPCIELINKSTATE_o( CFGPCIELINKSTATE_o ),
   .CFGPMCSRPMEEN_o( CFGPMCSRPMEEN_o ),
   .CFGPMCSRPMESTATUS_o( CFGPMCSRPMESTATUS_o ),
   .CFGPMCSRPOWERSTATE_o( CFGPMCSRPOWERSTATE_o ),
   .CFGRDWRDONEN_o( CFGRDWRDONEN_o ),
   .CFGMSGRECEIVEDSETSLOTPOWERLIMIT_o( CFGMSGRECEIVEDSETSLOTPOWERLIMIT_o ),
   .CFGMSGRECEIVEDUNLOCK_o( CFGMSGRECEIVEDUNLOCK_o ),
   .CFGMSGRECEIVEDPMASNAK_o( CFGMSGRECEIVEDPMASNAK_o ),
   .CFGPMRCVREQACKN_o( CFGPMRCVREQACKN_o ),
   .CFGTRANSACTION_o( CFGTRANSACTION_o ),
   .CFGTRANSACTIONADDR_o( CFGTRANSACTIONADDR_o ),
   .CFGTRANSACTIONTYPE_o( CFGTRANSACTIONTYPE_o ),

   .CFGBYTEENN_i( CFGBYTEENN_i ),
   .CFGDI_i( CFGDI_i ),
   .CFGDSN_i( CFGDSN_i ),
   .CFGDWADDR_i( CFGDWADDR_i ),
   .CFGERRACSN_i( CFGERRACSN_i ),
   .CFGERRCORN_i( CFGERRCORN_i ),
   .CFGERRCPLABORTN_i( CFGERRCPLABORTN_i ),
   .CFGERRCPLTIMEOUTN_i( CFGERRCPLTIMEOUTN_i ),
   .CFGERRCPLUNEXPECTN_i( CFGERRCPLUNEXPECTN_i ),
   .CFGERRECRCN_i( CFGERRECRCN_i ),
   .CFGERRLOCKEDN_i( CFGERRLOCKEDN_i ),
   .CFGERRPOSTEDN_i( CFGERRPOSTEDN_i ),
   .CFGERRTLPCPLHEADER_i( CFGERRTLPCPLHEADER_i ),
   .CFGERRURN_i( CFGERRURN_i ),
   .CFGINTERRUPTASSERTN_i( CFGINTERRUPTASSERTN_i ),
   .CFGINTERRUPTDI_i( CFGINTERRUPTDI_i ),
   .CFGINTERRUPTN_i( CFGINTERRUPTN_i ),
   .CFGPMDIRECTASPML1N_i( CFGPMDIRECTASPML1N_i ),
   .CFGPMSENDPMACKN_i( CFGPMSENDPMACKN_i ),
   .CFGPMSENDPMETON_i( CFGPMSENDPMETON_i ),
   .CFGPMSENDPMNAKN_i( CFGPMSENDPMNAKN_i ),
   .CFGPMTURNOFFOKN_i( CFGPMTURNOFFOKN_i ),
   .CFGPMWAKEN_i( CFGPMWAKEN_i ),
   .CFGPORTNUMBER_i( CFGPORTNUMBER_i ),
   .CFGRDENN_i( CFGRDENN_i ),
   .CFGTRNPENDINGN_i( CFGTRNPENDINGN_i ),
   .CFGWRENN_i( CFGWRENN_i ),
   .CFGWRREADONLYN_i( CFGWRREADONLYN_i ),
   .CFGWRRW1CASRWN_i( CFGWRRW1CASRWN_i )

);














































endmodule 
