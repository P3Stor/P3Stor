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
// File       : trn_tx_128.v
// Version    : 1.7
`timescale 1ps/1ps


// TRNTCFGREQN asserts to when user is throttled.  # pipeline stages needed
// to buffer data so single cycle tlps do not overflow transmitter

//-time it takes from detecting indicated TRNTBUFAV limit to when
// trn_tdst_rdy_n_o
//   deasserts for the user is 2 4ns cycles
//-2 4ns cycles = 4 2ns cycles, which is how many cycles of data are in flight
//-TRNTDSTRDYN deasserts when TRNBUFAV reaches 1
//-we cannot have TRNTBUFAV reach 1 before trn_tdst_rdy_n_o deasserts, so the
//   TRNTBUFAV value limit should be 5

`define TBUF_LIMIT 5
`define TBUF_LIMIT_REG 6
`define FIFO_DLY 1

module trn_tx_128 #(
   parameter TCQ = 100
) (

   input            user_clk,   // 125mhz div2
   input            block_clk,  // 250 to Block
   input            rst_n_250,
   input            rst_n_500,
   input  [1:0]     cfgpmcsrpowerstate,

   output [5:0]     trn_tbuf_av_o,
   output           trn_tdst_rdy_n_o,
   output           trn_terr_drop_n_o,
   input            trn_tecrc_gen_n_i,
   input  [127:0]    trn_td_i,
   input            trn_terr_fwd_n_i,
   input  [1:0]     trn_trem_n_i,
   input            trn_tsof_n_i,
   input            trn_teof_n_i,
   input            trn_tsrc_dsc_n_i,
   input            trn_tsrc_rdy_n_i,
   input            trn_tstr_n_i,

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
   output           TRNTSTRN_o


);

parameter [1:0] USER_TLP = 0;
parameter [1:0] INT_TLP  = 1;


wire  [63:0]  trn_td_i_spry_new;
wire          trn_tecrc_gen_n_i_spry_new;
wire          trn_terr_fwd_n_i_spry_new;
wire          trn_trem_n_i_spry_new;
wire          trn_tsof_n_i_spry_new;
wire          trn_teof_n_i_spry_new;
wire          trn_tsrc_dsc_n_i_spry_new;
wire          trn_tsrc_rdy_n_i_spry_new;
wire          trn_tstr_n_i_spry_new;



wire          TRNTCFGGNTN_o_srl;
wire  [63:0]  trn_td_i_srl;
wire          trn_tecrc_gen_n_i_srl;
wire          trn_terr_fwd_n_i_srl;
wire          trn_trem_n_i_srl;
wire          trn_tsof_n_i_srl;
wire          trn_teof_n_i_srl;
wire          trn_tsrc_dsc_n_i_srl;
wire          trn_tsrc_rdy_n_i_srl;
wire          trn_tstr_n_i_srl;

wire          TRNTERRDROPN_i_250;


reg   [1:0]  reg_state;
wire  [1:0]  state;
wire         conditions_met;
reg          conditions_met_reg;
reg          conditions_met_reg_d;
wire [(64+9-1):0] srl_input;
wire [(64+9-1):0] srl_output;

reg          in_a_pkt;
reg          in_a_pkt_500;
wire         in_a_pkt_wire_250;
wire         in_a_pkt_wire_500;


reg          in_a_multi_pkt;
reg          in_a_multi_pkt_reg_500;
reg          in_a_multi_pkt_reg_500_d;
reg          in_a_multi_pkt_reg_250;

reg          one_cycle_pkt;
reg          toggle;
reg          toggle_500;

reg   [127:0] trn_td_i_reg;
reg          trn_tsof_n_i_reg;
reg          trn_teof_n_i_reg;
reg          trn_tsrc_dsc_n_i_reg;
reg          trn_tsrc_rdy_n_i_reg;
reg   [1:0]  trn_trem_n_i_reg;
reg          trn_tstr_n_i_reg;
reg          trn_tecrc_gen_n_i_reg = 1;
reg          trn_terr_fwd_n_i_reg;

reg   [127:0] trn_td_i_reg_500;
reg          trn_tsof_n_i_reg_500;
reg          trn_teof_n_i_reg_500;
reg          trn_tsrc_dsc_n_i_reg_500;
reg          trn_tsrc_rdy_n_i_reg_500;
reg   [1:0]  trn_trem_n_i_reg_500;
reg          trn_tstr_n_i_reg_500;
reg          trn_tecrc_gen_n_i_reg_500;
reg          trn_terr_fwd_n_i_reg_500;
reg          trn_tdst_rdy_n_int_reg_500;

reg          TRNTCFGGNTN_int;
reg          trn_tdst_rdy_n_int;
reg          trn_tdst_rdy_n_int_reg;


reg          TRNTCFGGNTN_o_reg;
reg          TRNTCFGGNTN_o_reg_d;
reg [5:0]    TRNTBUFAV_i_reg;
reg          TRNTCFGREQN_i_reg;
reg          TRNTDSTRDYN_i_reg;
reg          TRNTERRDROPN_i_reg;
reg          TRNTERRDROPN_i_reg_d;

reg          GNT_set;
integer      i;

reg [(64+9-1):0] shift [(`FIFO_DLY-1):0]; // pipeline `FIFO_DLY-1


assign TRNTCFGGNTN_o  = TRNTCFGGNTN_o_srl;
assign TRNTECRCGENN_o = trn_tecrc_gen_n_i_srl;
assign TRNTERRFWDN_o  = trn_terr_fwd_n_i_srl;
assign TRNTD_o        = trn_td_i_srl;
assign TRNTSOFN_o     = trn_tsof_n_i_srl;
assign TRNTEOFN_o     = trn_teof_n_i_srl;
assign TRNTSRCDSCN_o  = trn_tsrc_dsc_n_i_srl | trn_teof_n_i_srl;

assign TRNTSRCRDYN_o  = trn_tsrc_rdy_n_i_srl;


assign TRNTREMN_o     = trn_trem_n_i_srl;
assign TRNTSTRN_o     = trn_tstr_n_i_srl;


assign trn_tbuf_av_o     = TRNTBUFAV_i_reg;
assign TRNTERRDROPN_i_250 = TRNTERRDROPN_i_reg & TRNTERRDROPN_i;
assign trn_terr_drop_n_o = TRNTERRDROPN_i_reg_d;



//------------------------------------------------------------------
// register mostly inputs @ 250
//------------------------------------------------------------------

always @(posedge user_clk)
begin
   if (~rst_n_250)
   begin
      trn_td_i_reg               <= #TCQ 128'b0;
      trn_tsof_n_i_reg           <= #TCQ 1'b1;
      trn_teof_n_i_reg           <= #TCQ 1'b1;
      trn_tsrc_dsc_n_i_reg       <= #TCQ 1'b1;
      trn_tsrc_rdy_n_i_reg       <= #TCQ 1'b1;
      trn_trem_n_i_reg           <= #TCQ 2'h3;
      trn_tstr_n_i_reg           <= #TCQ 1'b1;
      trn_tecrc_gen_n_i_reg      <= #TCQ 1'b1;
      trn_terr_fwd_n_i_reg       <= #TCQ 1'b1;

      TRNTBUFAV_i_reg            <= #TCQ 6'b0;  // convert 500-250
      TRNTCFGREQN_i_reg          <= #TCQ 1'b1;  // convert 500-250
      TRNTDSTRDYN_i_reg          <= #TCQ 1'b1;  // convert 500-250

      in_a_multi_pkt_reg_250     <= #TCQ 0;
      trn_tdst_rdy_n_int_reg     <= #TCQ 1;

      TRNTERRDROPN_i_reg_d       <= #TCQ 1;

   end else begin

      if (~trn_tdst_rdy_n_o)
      begin
         trn_tsof_n_i_reg           <= #TCQ trn_tsof_n_i;
         trn_teof_n_i_reg           <= #TCQ trn_teof_n_i;
         trn_tsrc_rdy_n_i_reg       <= #TCQ trn_tsrc_rdy_n_i;
      end else begin
         trn_tsof_n_i_reg           <= #TCQ 1'b1;
         trn_teof_n_i_reg           <= #TCQ 1'b1;
         trn_tsrc_rdy_n_i_reg       <= #TCQ 1'b1;
      end

      trn_td_i_reg               <= #TCQ trn_td_i;
      trn_trem_n_i_reg           <= #TCQ trn_trem_n_i;
      trn_tstr_n_i_reg           <= #TCQ trn_tstr_n_i;
      trn_tecrc_gen_n_i_reg      <= #TCQ trn_tecrc_gen_n_i;
      trn_terr_fwd_n_i_reg       <= #TCQ trn_terr_fwd_n_i;
      trn_tsrc_dsc_n_i_reg       <= #TCQ trn_tsrc_dsc_n_i;


      TRNTBUFAV_i_reg            <= #TCQ TRNTBUFAV_i;
      TRNTCFGREQN_i_reg          <= #TCQ TRNTCFGREQN_i;
      TRNTDSTRDYN_i_reg          <= #TCQ TRNTDSTRDYN_i;

      in_a_multi_pkt_reg_250     <= #TCQ in_a_multi_pkt;
      trn_tdst_rdy_n_int_reg     <= #TCQ trn_tdst_rdy_n_int;
      TRNTERRDROPN_i_reg_d       <= #TCQ TRNTERRDROPN_i_250;

   end

end



//------------------------------------------------------------------
// register signals to SRL @ 500
//------------------------------------------------------------------

always @(posedge block_clk)
begin
   if(~rst_n_500)
   begin
      trn_td_i_reg_500           <= #TCQ 128'b0;
      trn_tsof_n_i_reg_500       <= #TCQ 1'b1;
      trn_teof_n_i_reg_500       <= #TCQ 1'b1;
      trn_tsrc_dsc_n_i_reg_500   <= #TCQ 1'b1;
      trn_tsrc_rdy_n_i_reg_500   <= #TCQ 1'b1;
      trn_trem_n_i_reg_500       <= #TCQ 1'b1;
      trn_tstr_n_i_reg_500       <= #TCQ 1'b1;
      trn_tecrc_gen_n_i_reg_500  <= #TCQ 1'b1;
      trn_terr_fwd_n_i_reg_500   <= #TCQ 1'b1;
      trn_tdst_rdy_n_int_reg_500 <= #TCQ 1'b1;

      in_a_multi_pkt_reg_500     <= #TCQ 1'b0;
      in_a_multi_pkt_reg_500_d   <= #TCQ 1'b0;

      TRNTCFGGNTN_o_reg          <= #TCQ 1'b1;  // convert 250-500
      TRNTCFGGNTN_o_reg_d        <= #TCQ 1'b1;  // convert 250-500

      TRNTERRDROPN_i_reg         <= #TCQ 1'b1;

      in_a_pkt_500               <= #TCQ 1'b0;
   end else begin
      trn_td_i_reg_500           <= #TCQ trn_td_i_reg;
      trn_tsof_n_i_reg_500       <= #TCQ trn_tsof_n_i_reg;
      trn_teof_n_i_reg_500       <= #TCQ trn_teof_n_i_reg;
      trn_tsrc_dsc_n_i_reg_500   <= #TCQ trn_tsrc_dsc_n_i_reg;
      trn_tsrc_rdy_n_i_reg_500   <= #TCQ trn_tsrc_rdy_n_i_reg;
      trn_trem_n_i_reg_500       <= #TCQ trn_trem_n_i_reg;
      trn_tstr_n_i_reg_500       <= #TCQ trn_tstr_n_i_reg;
      trn_tecrc_gen_n_i_reg_500  <= #TCQ trn_tecrc_gen_n_i_reg;
      trn_terr_fwd_n_i_reg_500   <= #TCQ trn_terr_fwd_n_i_reg;
      trn_tdst_rdy_n_int_reg_500 <= #TCQ trn_tdst_rdy_n_int_reg;

      in_a_multi_pkt_reg_500     <= #TCQ in_a_multi_pkt;
      in_a_multi_pkt_reg_500_d   <= #TCQ in_a_multi_pkt_reg_500;

      TRNTCFGGNTN_o_reg          <= #TCQ TRNTCFGGNTN_int;
      TRNTCFGGNTN_o_reg_d        <= #TCQ TRNTCFGGNTN_o_reg;

      TRNTERRDROPN_i_reg         <= #TCQ TRNTERRDROPN_i;

      in_a_pkt_500               <= #TCQ in_a_pkt_wire_500;
   end
end


assign #TCQ conditions_met = ((TRNTBUFAV_i_reg > `TBUF_LIMIT) &     // 250
                         TRNTCFGREQN_i_reg & ~TRNTDSTRDYN_i_reg  &  // 250 250
                         (cfgpmcsrpowerstate == 2'd0) );            // 250




always @(posedge user_clk)
begin
   if (~rst_n_250) begin
      conditions_met_reg <= #TCQ 1'b0;
      conditions_met_reg_d <= #TCQ 1'b0;
   end else begin
      conditions_met_reg <= #TCQ (TRNTBUFAV_i > `TBUF_LIMIT_REG);   // 250

      conditions_met_reg_d <= ((conditions_met_reg) &
                         TRNTCFGREQN_i & ~TRNTDSTRDYN_i  &          // 250 250
                         (cfgpmcsrpowerstate == 2'd0) );            // 250
   end
end

//------------------------------------------------------------------
//                            250
//------------------------------------------------------------------
always @(posedge user_clk)
begin
   if (~rst_n_250) begin
      one_cycle_pkt            <= #TCQ 0;
      in_a_multi_pkt           <= #TCQ 0;
      in_a_pkt                 <= #TCQ 0;
   end else begin
      if ( ~trn_tsof_n_i & ~trn_tsrc_rdy_n_i & ~trn_tdst_rdy_n_o)
      begin
         if (~trn_teof_n_i)
         begin
            one_cycle_pkt  <= #TCQ 1;
            in_a_multi_pkt <= #TCQ 0;
         end else begin
            one_cycle_pkt  <= #TCQ 0;
            in_a_multi_pkt <= #TCQ 1;
         end

         in_a_pkt     <= #TCQ 1;

      end else if (~trn_teof_n_i & ~trn_tsrc_rdy_n_i & ~trn_tdst_rdy_n_o)
      begin

         one_cycle_pkt  <= #TCQ 0;
         in_a_multi_pkt <= #TCQ 0;
         in_a_pkt       <= #TCQ 0;

      end
      else if (one_cycle_pkt)
      begin

         one_cycle_pkt  <= #TCQ 0;
         in_a_pkt       <= #TCQ 0;

      end
   end
end


assign in_a_pkt_wire_250 = in_a_pkt | in_a_multi_pkt_reg_250 |
    ~trn_tsof_n_i & ~trn_tsrc_rdy_n_i & ~trn_tdst_rdy_n_int;

assign in_a_pkt_wire_500 = in_a_pkt |
    (trn_trem_n_i_reg[1] ? in_a_multi_pkt_reg_500 : in_a_multi_pkt_reg_500_d);








//---------------------------------------------------------------------
// FSM to throttle user for TRNTCFGREQN and assert TRNTCFGGNTN
//---------------------------------------------------------------------

always @(posedge user_clk)
begin
   if (~rst_n_250)
   begin
      reg_state = 0;
   end else begin

      case (state)

         USER_TLP: begin // 0

            if (in_a_pkt_wire_250) begin
               if (!TRNTCFGREQN_i_reg && !trn_teof_n_i && !trn_tsrc_rdy_n_i)
                  reg_state = INT_TLP;
               else if (!conditions_met && !trn_teof_n_i && !trn_tsrc_rdy_n_i)
                  reg_state = USER_TLP;
               else
                  reg_state = USER_TLP;
            end else begin
               if (!TRNTCFGREQN_i_reg)
                  reg_state = INT_TLP;
               else
                  reg_state = USER_TLP;
            end
         end

         INT_TLP: begin // 1
           if (TRNTCFGREQN_i_reg)
               reg_state = USER_TLP;
            else
               reg_state = INT_TLP;
         end

      endcase

   end
end


//---------------------------------------------------------------------
// output(tdst_rdy) logic
//---------------------------------------------------------------------

always @(posedge user_clk)
begin
   if (~rst_n_250) begin
      TRNTCFGGNTN_int    <= #TCQ 1;
      trn_tdst_rdy_n_int <= #TCQ 1;
   end else begin

      case (state)


         USER_TLP: begin // 0

            TRNTCFGGNTN_int    <= #TCQ 1;
            GNT_set            <= #TCQ 0;

            if (in_a_pkt_wire_250) begin
               if (!TRNTCFGREQN_i_reg && !trn_teof_n_i && !trn_tsrc_rdy_n_i)
                  trn_tdst_rdy_n_int <= #TCQ 1;

               else if ((!conditions_met && !trn_teof_n_i && !trn_tsrc_rdy_n_i) ||
                        (!conditions_met && trn_tdst_rdy_n_int))
                  trn_tdst_rdy_n_int <= #TCQ 1;

               else
                  trn_tdst_rdy_n_int <= #TCQ 0;

            end else begin
               if (!TRNTCFGREQN_i_reg)
                  trn_tdst_rdy_n_int <= #TCQ 1;

               else if (!conditions_met)
                  trn_tdst_rdy_n_int <= #TCQ 1;

               else
                  trn_tdst_rdy_n_int <= #TCQ 0;

            end
         end

         INT_TLP: begin  // 1

            if (~GNT_set) begin
               TRNTCFGGNTN_int     <= #TCQ 0;
               GNT_set             <= #TCQ 1;
            end else begin
               TRNTCFGGNTN_int     <= #TCQ 1;
            end

            trn_tdst_rdy_n_int  <= #TCQ 1;
         end

      endcase
   end
end


assign #TCQ state = reg_state;


// this is so trn_tdst_rdy_n_o does not deasserts in middle of a packet
assign trn_tdst_rdy_n_o = trn_tdst_rdy_n_int |
                 (~conditions_met_reg_d & ~in_a_pkt_wire_250);




//----------------------------------------------------------------------
// Sprayer @ 500
//----------------------------------------------------------------------

always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin

      toggle            <= #TCQ 1;
      toggle_500        <= #TCQ 1;

   end else begin

      if (in_a_pkt_wire_500)
         toggle         <= #TCQ ~toggle;
      else
         toggle         <= #TCQ 1;

      toggle_500        <= #TCQ toggle;
   end
end




assign trn_td_i_spry_new = toggle_500 ? trn_td_i_reg_500[127:64] : trn_td_i_reg_500[63:0];

assign trn_tsof_n_i_spry_new = toggle_500 ? trn_tsof_n_i_reg_500 : 1'b1;

// toggle   upper upper lower lower
// remn[1]  upper lower upper lower
// remn[0]  upper lower upper lower
//          eof   1     1     eof
assign trn_teof_n_i_spry_new = (toggle_500 ^~ trn_trem_n_i_reg_500[1]) ? trn_teof_n_i_reg_500 : 1'b1;

assign trn_tsrc_rdy_n_i_spry_new =   ~in_a_pkt_500 | trn_tdst_rdy_n_int_reg_500 |
                                  trn_tsrc_rdy_n_i_reg_500;

assign trn_tsrc_dsc_n_i_spry_new =  trn_tsrc_dsc_n_i_reg_500;

assign trn_trem_n_i_spry_new =  trn_trem_n_i_reg_500[0];
assign trn_tstr_n_i_spry_new = trn_tstr_n_i_reg_500;
assign trn_tecrc_gen_n_i_spry_new = trn_tecrc_gen_n_i_reg_500;
assign trn_terr_fwd_n_i_spry_new = trn_terr_fwd_n_i_reg_500;


assign #TCQ srl_input = {
                       TRNTCFGGNTN_o_reg_d,        trn_td_i_spry_new,
                       trn_tsof_n_i_spry_new,      trn_teof_n_i_spry_new,
                       trn_tsrc_dsc_n_i_spry_new,  trn_tsrc_rdy_n_i_spry_new,
                       trn_trem_n_i_spry_new,      trn_tstr_n_i_spry_new,
                       trn_tecrc_gen_n_i_spry_new, trn_terr_fwd_n_i_spry_new};




//----------------------------------------------------------------------
// SRL Pipeline

generate
   always @(posedge block_clk)
   begin
      for (i=(`FIFO_DLY-1); i>0; i=i-1)
         shift[i] <= #TCQ shift[i-1];
         shift[0] <= #TCQ srl_input;
   end
endgenerate

assign  srl_output = shift[(`FIFO_DLY-1)]; // `FIFO_DLY-1

assign TRNTCFGGNTN_o_srl     = TRNTCFGGNTN_o_reg_d;
assign trn_td_i_srl          = srl_output[71:8];
assign trn_tsof_n_i_srl      = srl_output[7];
assign trn_teof_n_i_srl      = srl_output[6];
assign trn_tsrc_dsc_n_i_srl  = srl_output[5];
assign trn_tsrc_rdy_n_i_srl  = srl_output[4];
assign trn_trem_n_i_srl      = srl_output[3];
assign trn_tstr_n_i_srl      = srl_output[2];
assign trn_tecrc_gen_n_i_srl = srl_output[1];
assign trn_terr_fwd_n_i_srl  = srl_output[0];


endmodule
