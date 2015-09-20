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
// File       : pcie_cfg_128.v
// Version    : 1.7
`timescale 1ps/1ps 


module pcie_cfg_128 #(
   parameter TCQ = 100
)(

   input           user_clk,
   input           block_clk,
   input           rst_n_500,

   input          CFGCOMMANDBUSMASTERENABLE_i, // Block output to input of here
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

   output [3:0]   CFGBYTEENN_o,  //  output of here to Block input
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


   output          CFGCOMMANDBUSMASTERENABLE_o, // output of here to input of user
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


   input   [3:0]   CFGBYTEENN_i, // output of user to input of here 
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

   wire   [6:0]        user_250_sp;
   reg    [6:0]        user_250_sp_d;        // clk@250
   reg    [6:0]        user_250_sp_d_toggle; // 1cycle @500

   wire   [69:0]       block_500_sp;
   reg    [69:0]       block_500_sp_d;       // clk@500
   reg    [69:0]       block_500_sp_d_held;  // held @250


   wire   [189:0]      user_250;       // user         to block input
   reg    [189:0]      user_250_d;     // clk @250
   reg    [189:0]      user_250_d_500; // clk @250

   wire   [49:0]       block_500;       // block output to user
   reg    [49:0]       block_500_d;     // clk @500
   reg    [49:0]       block_500_d_250; // clk @250

   reg    [16:0]       block_500_msg_d;
   reg    [16:0]       block_500_msg_d_held;

   reg ignore_rdwr;
   reg ignore_rdwr_d;
   reg ignore_rdwr_d2;
   reg ignore_rdwr_d3;
   reg ignore_rdwr_d4;
   reg ignore_rdwr_d5;

   reg ignore_int;
   reg ignore_int_d;
   reg ignore_int_d2;
   reg ignore_int_d3;
   reg ignore_int_d4;
   reg ignore_int_d5;


///////////////////////////////////////////////////////////////////////
// a - inputs to Block = 198
//////////////////////////////////////////////////////////////////////////
assign #TCQ user_250 = {
      CFGDI_i, CFGDSN_i,                       // 32 + 64
      CFGDWADDR_i,  			       // 10 
      CFGERRPOSTEDN_i, CFGERRTLPCPLHEADER_i,   // 1 + 48
      CFGINTERRUPTASSERTN_i, CFGINTERRUPTDI_i, // 1 + 8
      CFGPORTNUMBER_i,                         // 8
      CFGBYTEENN_i, CFGERRACSN_i,              // 4 + 1
      CFGERRLOCKEDN_i, CFGINTERRUPTN_i,
      CFGPMDIRECTASPML1N_i, CFGPMSENDPMACKN_i,
      CFGPMSENDPMETON_i, CFGPMSENDPMNAKN_i,
      CFGPMTURNOFFOKN_i, CFGTRNPENDINGN_i, 
      CFGWRREADONLYN_i, CFGWRRW1CASRWN_i,
      CFGRDENN_i, CFGWRENN_i

};


   always @(posedge user_clk)
   begin
      user_250_d <= #TCQ user_250;
   end


   always @(posedge block_clk)
   begin
      user_250_d_500 <= #TCQ user_250_d;
   end

   assign CFGDI_o                    = user_250_d_500[188:157]; // 32
   assign CFGDSN_o                   = user_250_d_500[156:93]; // 64
   assign CFGDWADDR_o                = user_250_d_500[92:83]; // 10
   assign CFGERRPOSTEDN_o            = user_250_d_500[82];
   assign CFGERRTLPCPLHEADER_o       = user_250_d_500[81:34];   // 48
   assign CFGINTERRUPTASSERTN_o      = user_250_d_500[33];
   assign CFGINTERRUPTDI_o           = user_250_d_500[32:25];   // 8
   assign CFGPORTNUMBER_o            = user_250_d_500[24:17];   // 8
   assign CFGBYTEENN_o               = user_250_d_500[16:13];   // 4
   assign CFGERRACSN_o               = user_250_d_500[12];
   assign CFGERRLOCKEDN_o            = user_250_d_500[11];
//   assign CFGINTERRUPTN_o            = user_250_d_500[10];
   assign CFGPMDIRECTASPML1N_o       = user_250_d_500[9];
   assign CFGPMSENDPMACKN_o          = user_250_d_500[8];
   assign CFGPMSENDPMETON_o          = user_250_d_500[7];
   assign CFGPMSENDPMNAKN_o          = user_250_d_500[6];
   assign CFGPMTURNOFFOKN_o          = user_250_d_500[5];
   assign CFGTRNPENDINGN_o           = user_250_d_500[4];
   assign CFGWRREADONLYN_o           = user_250_d_500[3];
   assign CFGWRRW1CASRWN_o           = user_250_d_500[2];
//   assign CFGRDENN_o                 = user_250_d_500[1];
//   assign CFGWRENN_o                 = user_250_d_500[0];

   assign CFGINTERRUPTN_o            = user_250_d_500[10] | ignore_int | ignore_int_d | ignore_int_d2 | ignore_int_d3 | ignore_int_d4 | ignore_int_d5;

   assign CFGRDENN_o                 = user_250_d_500[1] | ignore_rdwr | ignore_rdwr_d | ignore_rdwr_d2 | ignore_rdwr_d3 | ignore_rdwr_d4 | ignore_rdwr_d5;
   assign CFGWRENN_o                 = user_250_d_500[0] | ignore_rdwr | ignore_rdwr_d | ignore_rdwr_d2 | ignore_rdwr_d3 | ignore_rdwr_d4 | ignore_rdwr_d5;




always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      ignore_rdwr    <= #TCQ 0;
      ignore_rdwr_d  <= #TCQ 0;
      ignore_rdwr_d2 <= #TCQ 0;
      ignore_rdwr_d3 <= #TCQ 0;
      ignore_rdwr_d4 <= #TCQ 0;
      ignore_rdwr_d5 <= #TCQ 0;
   end else begin
      if (~CFGRDWRDONEN_i & (~CFGRDENN_o | ~CFGWRENN_o) )
         ignore_rdwr   <= #TCQ 1;
      else 
         ignore_rdwr   <= #TCQ 0;

      ignore_rdwr_d    <= #TCQ ignore_rdwr;
      ignore_rdwr_d2   <= #TCQ ignore_rdwr_d;
      ignore_rdwr_d3   <= #TCQ ignore_rdwr_d2;
      ignore_rdwr_d4   <= #TCQ ignore_rdwr_d3;
      ignore_rdwr_d5   <= #TCQ ignore_rdwr_d4;
   end
end


always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      ignore_int      <= #TCQ 0;
      ignore_int_d    <= #TCQ 0;
      ignore_int_d2   <= #TCQ 0;
      ignore_int_d3   <= #TCQ 0;
      ignore_int_d4   <= #TCQ 0;
      ignore_int_d5   <= #TCQ 0;

   end else begin
      if (~CFGINTERRUPTN_o & ~CFGINTERRUPTRDYN_i) 
         ignore_int   <= #TCQ 1;
      else
         ignore_int   <= #TCQ 0;

      ignore_int_d    <= #TCQ ignore_int;
      ignore_int_d2   <= #TCQ ignore_int_d;
      ignore_int_d3   <= #TCQ ignore_int_d2;
      ignore_int_d4   <= #TCQ ignore_int_d3;
      ignore_int_d5   <= #TCQ ignore_int_d4;
   end
end






//////////////////////////////////////////////////////////////////////////
// c - output from Block = 121
//////////////////////////////////////////////////////////////////////////

assign #TCQ block_500 = {

    CFGCOMMANDBUSMASTERENABLE_i,       
    CFGCOMMANDINTERRUPTDISABLE_i,      
    CFGCOMMANDIOENABLE_i,              
    CFGCOMMANDMEMENABLE_i,             
    CFGCOMMANDSERREN_i,                
    CFGDEVCONTROLAUXPOWEREN_i,         
    CFGDEVCONTROLCORRERRREPORTINGEN_i, 
    CFGDEVCONTROLEXTTAGEN_i,           
    CFGDEVCONTROLFATALERRREPORTINGEN_i,
    CFGDEVCONTROLMAXPAYLOAD_i,           // 3
    CFGDEVCONTROLMAXREADREQ_i,           // 3
    CFGDEVCONTROLPHANTOMEN_i,          
    CFGDEVCONTROLURERRREPORTINGEN_i,  
    CFGDEVCONTROL2CPLTIMEOUTDIS_i,     
    CFGDEVCONTROL2CPLTIMEOUTVAL_i,       // 4
    CFGDEVSTATUSCORRERRDETECTED_i,     
    CFGDEVSTATUSFATALERRDETECTED_i,    
    CFGDEVSTATUSNONFATALERRDETECTED_i, 
    CFGDEVSTATUSURDETECTED_i,          
    CFGDEVCONTROLNONFATALREPORTINGEN_i,
    CFGLINKCONTROLRCB_i,               
    CFGLINKCONTROLASPMCONTROL_i,         // 2
    CFGLINKCONTROLAUTOBANDWIDTHINTEN_i,
    CFGLINKCONTROLBANDWIDTHINTEN_i,    
    CFGLINKCONTROLCLOCKPMEN_i,         
    CFGLINKCONTROLCOMMONCLOCK_i,       
    CFGLINKCONTROLEXTENDEDSYNC_i,      
    CFGLINKCONTROLHWAUTOWIDTHDIS_i,    
    CFGLINKCONTROLLINKDISABLE_i,      
    CFGLINKCONTROLRETRAINLINK_i,      
    CFGLINKSTATUSAUTOBANDWIDTHSTATUS_i,
    CFGLINKSTATUSBANDWITHSTATUS_i,     
    CFGLINKSTATUSCURRENTSPEED_i,        // 2
    CFGLINKSTATUSDLLACTIVE_i,          
    CFGLINKSTATUSLINKTRAINING_i,       
    CFGLINKSTATUSNEGOTIATEDWIDTH_i,     // 4
    CFGDEVCONTROLNOSNOOPEN_i,          
    CFGDEVCONTROLENABLERO_i            

  };


   always @(posedge block_clk)
   begin
      block_500_d     <= #TCQ block_500;
   end

   always @(posedge user_clk)
   begin
      block_500_d_250 <= #TCQ block_500_d;
   end


   assign CFGCOMMANDBUSMASTERENABLE_o        = block_500_d_250[49];
   assign CFGCOMMANDINTERRUPTDISABLE_o       = block_500_d_250[48];
   assign CFGCOMMANDIOENABLE_o               = block_500_d_250[47];
   assign CFGCOMMANDMEMENABLE_o              = block_500_d_250[46];
   assign CFGCOMMANDSERREN_o                 = block_500_d_250[45];
   assign CFGDEVCONTROLAUXPOWEREN_o          = block_500_d_250[44];
   assign CFGDEVCONTROLCORRERRREPORTINGEN_o  = block_500_d_250[43];
   assign CFGDEVCONTROLEXTTAGEN_o            = block_500_d_250[42];
   assign CFGDEVCONTROLFATALERRREPORTINGEN_o = block_500_d_250[41];
   assign CFGDEVCONTROLMAXPAYLOAD_o          = block_500_d_250[40:38];// 3
   assign CFGDEVCONTROLMAXREADREQ_o          = block_500_d_250[37:35];// 3
   assign CFGDEVCONTROLPHANTOMEN_o           = block_500_d_250[34];
   assign CFGDEVCONTROLURERRREPORTINGEN_o    = block_500_d_250[33];
   assign CFGDEVCONTROL2CPLTIMEOUTDIS_o      = block_500_d_250[32];
   assign CFGDEVCONTROL2CPLTIMEOUTVAL_o      = block_500_d_250[31:28];// 4
   assign CFGDEVSTATUSCORRERRDETECTED_o      = block_500_d_250[27];
   assign CFGDEVSTATUSFATALERRDETECTED_o     = block_500_d_250[26];
   assign CFGDEVSTATUSNONFATALERRDETECTED_o  = block_500_d_250[25];
   assign CFGDEVSTATUSURDETECTED_o           = block_500_d_250[24];
   assign CFGDEVCONTROLNONFATALREPORTINGEN_o = block_500_d_250[23];

   assign CFGLINKCONTROLRCB_o                = block_500_d_250[22];
   assign CFGLINKCONTROLASPMCONTROL_o        = block_500_d_250[21:20];  // 2
   assign CFGLINKCONTROLAUTOBANDWIDTHINTEN_o = block_500_d_250[19];
   assign CFGLINKCONTROLBANDWIDTHINTEN_o     = block_500_d_250[18];
   assign CFGLINKCONTROLCLOCKPMEN_o          = block_500_d_250[17];
   assign CFGLINKCONTROLCOMMONCLOCK_o        = block_500_d_250[16];
   assign CFGLINKCONTROLEXTENDEDSYNC_o       = block_500_d_250[15];
   assign CFGLINKCONTROLHWAUTOWIDTHDIS_o     = block_500_d_250[14];
   assign CFGLINKCONTROLLINKDISABLE_o        = block_500_d_250[13];
   assign CFGLINKCONTROLRETRAINLINK_o        = block_500_d_250[12];
   assign CFGLINKSTATUSAUTOBANDWIDTHSTATUS_o = block_500_d_250[11];
   assign CFGLINKSTATUSBANDWITHSTATUS_o      = block_500_d_250[10];
   assign CFGLINKSTATUSCURRENTSPEED_o        = block_500_d_250[9:8];  // 2
   assign CFGLINKSTATUSDLLACTIVE_o           = block_500_d_250[7];
   assign CFGLINKSTATUSLINKTRAINING_o        = block_500_d_250[6];
   assign CFGLINKSTATUSNEGOTIATEDWIDTH_o     = block_500_d_250[5:2];  // 4
   assign CFGDEVCONTROLNOSNOOPEN_o           = block_500_d_250[1];
   assign CFGDEVCONTROLENABLERO_o            = block_500_d_250[0];








//////////////////////////////////////////////////////////////////////////
// b = 7bit input where 1 cycle assertion @250 = 1 cycle assertion @500
//////////////////////////////////////////////////////////////////////////
assign #TCQ user_250_sp = {
       CFGPMWAKEN_i, CFGERRURN_i,
       CFGERRCORN_i, CFGERRECRCN_i, 
       CFGERRCPLTIMEOUTN_i, CFGERRCPLABORTN_i,
       CFGERRCPLUNEXPECTN_i
};


   always @(posedge user_clk)
   begin
      user_250_sp_d <= #TCQ user_250_sp;
   end


   always @(posedge block_clk)
   begin
      user_250_sp_d_toggle[0] <= #TCQ ~(~user_250_sp_d[0] &
                                         user_250_sp_d_toggle[0]);
      user_250_sp_d_toggle[1] <= #TCQ ~(~user_250_sp_d[1] &
                                         user_250_sp_d_toggle[1]);
      user_250_sp_d_toggle[2] <= #TCQ ~(~user_250_sp_d[2] &
                                         user_250_sp_d_toggle[2]);
      user_250_sp_d_toggle[3] <= #TCQ ~(~user_250_sp_d[3] &
                                         user_250_sp_d_toggle[3]);
      user_250_sp_d_toggle[4] <= #TCQ ~(~user_250_sp_d[4] &
                                         user_250_sp_d_toggle[4]);
      user_250_sp_d_toggle[5] <= #TCQ ~(~user_250_sp_d[5] &
                                         user_250_sp_d_toggle[5]);
      user_250_sp_d_toggle[6] <= #TCQ ~(~user_250_sp_d[6] &
                                         user_250_sp_d_toggle[6]);
   end





   assign CFGPMWAKEN_o         = user_250_sp_d_toggle[6];
   assign CFGERRURN_o          = user_250_sp_d_toggle[5];
   assign CFGERRCORN_o         = user_250_sp_d_toggle[4];
   assign CFGERRECRCN_o        = user_250_sp_d_toggle[3];
   assign CFGERRCPLTIMEOUTN_o  = user_250_sp_d_toggle[2];
   assign CFGERRCPLABORTN_o    = user_250_sp_d_toggle[1];
   assign CFGERRCPLUNEXPECTN_o = user_250_sp_d_toggle[0];



//////////////////////////////////////////////////////////////////////////
// d = 16bit output where 1 cycle assertion @500 = 1 cycle assertion @250
// This category is for signals that can pulse for 1 cycle @500
//////////////////////////////////////////////////////////////////////////
assign #TCQ block_500_sp = {

    CFGPMCSRPMEEN_i,                   
    CFGPMCSRPMESTATUS_i,               
    CFGPMCSRPOWERSTATE_i,                // 2
    CFGDO_i,                             // 32
    CFGINTERRUPTDO_i,                    // 8
    CFGINTERRUPTMMENABLE_i,              // 3
    CFGINTERRUPTMSIENABLE_i,          
    CFGINTERRUPTMSIXENABLE_i,         
    CFGINTERRUPTMSIXFM_i,             
    CFGPCIELINKSTATE_i,                  // 3
    CFGMSGRECEIVEDSETSLOTPOWERLIMIT_i,
    CFGMSGRECEIVEDUNLOCK_i,          
    CFGMSGRECEIVEDPMASNAK_i,           
    CFGTRANSACTION_i,                   
    CFGTRANSACTIONADDR_i,                // 7
    CFGTRANSACTIONTYPE_i,              
    CFGMSGRECEIVEDPMETO_i,            

    CFGERRCPLRDYN_i,                   
    CFGPMRCVREQACKN_i,               
    CFGRDWRDONEN_i,                    
    CFGINTERRUPTRDYN_i                

};


   always @(posedge block_clk)
   begin
      block_500_sp_d <= #TCQ block_500_sp;
   end

   always @(posedge user_clk)
   begin

     block_500_sp_d_held[69:66] <= #TCQ (block_500_sp_d[69:66] | block_500_sp[69:66]);

     block_500_sp_d_held[65:34] <= #TCQ (block_500_sp[65:34]); // CFGDO

     block_500_sp_d_held[33:4] <= #TCQ (block_500_sp_d[33:4] | block_500_sp[33:4]);
     block_500_sp_d_held[3:0] <= #TCQ ~(~block_500_sp_d[3:0] | ~block_500_sp[3:0]);
   end


   assign CFGPMCSRPMEEN_o                    = block_500_sp_d_held[69];
   assign CFGPMCSRPMESTATUS_o                = block_500_sp_d_held[68];
   assign CFGPMCSRPOWERSTATE_o               = block_500_sp_d_held[67:66]; // 2
   assign CFGDO_o                            = block_500_sp_d_held[65:34]; // 32
   assign CFGINTERRUPTDO_o                   = block_500_sp_d_held[33:26]; // 8
   assign CFGINTERRUPTMMENABLE_o             = block_500_sp_d_held[25:23]; // 3
   assign CFGINTERRUPTMSIENABLE_o            = block_500_sp_d_held[22];
   assign CFGINTERRUPTMSIXENABLE_o           = block_500_sp_d_held[21];
   assign CFGINTERRUPTMSIXFM_o               = block_500_sp_d_held[20];
   assign CFGPCIELINKSTATE_o                 = block_500_sp_d_held[19:17]; // 3
   assign CFGMSGRECEIVEDSETSLOTPOWERLIMIT_o  = block_500_sp_d_held[16];
   assign CFGMSGRECEIVEDUNLOCK_o             = block_500_sp_d_held[15];
   assign CFGMSGRECEIVEDPMASNAK_o            = block_500_sp_d_held[14];
   assign CFGTRANSACTION_o                   = block_500_sp_d_held[13]; 
   assign CFGTRANSACTIONADDR_o               = block_500_sp_d_held[12:6]; // 7
   assign CFGTRANSACTIONTYPE_o               = block_500_sp_d_held[5];
   assign CFGMSGRECEIVEDPMETO_o              = block_500_sp_d_held[4];

   assign CFGERRCPLRDYN_o                    = block_500_sp_d_held[3];
   assign CFGPMRCVREQACKN_o                  = block_500_sp_d_held[2];
   assign CFGRDWRDONEN_o                     = block_500_sp_d_held[1];
   assign CFGINTERRUPTRDYN_o                 = block_500_sp_d_held[0];



   always @(posedge block_clk)
   begin
      block_500_msg_d[16:1] <= #TCQ CFGMSGDATA_i;
      block_500_msg_d[0] <= #TCQ CFGMSGRECEIVED_i;
   end

   always @(posedge user_clk)
   begin
      block_500_msg_d_held[16:1] <= #TCQ
          (block_500_msg_d[0] ? block_500_msg_d[16:1] : CFGMSGDATA_i);

      block_500_msg_d_held[0] <= #TCQ (block_500_msg_d[0] | CFGMSGRECEIVED_i);
   end

   assign CFGMSGDATA_o                     = block_500_msg_d_held[16:1]; // 16
   assign CFGMSGRECEIVED_o                 = block_500_msg_d_held[0]; 









endmodule
