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
// File       : trn_rx_128.v
// Version    : 1.7
`timescale 1ps/1ps
`define FIFO_LIMIT 4 

module trn_rx_128 #(
   parameter TCQ = 100
)(

   input user_clk,
   input block_clk,
   input rst_n_250,
   input rst_n_500,

   output [6:0]     trn_rbar_hit_n_o,
   output[127:0]    trn_rd_o,
   output           trn_recrc_err_n_o,
   output           trn_rsof_n_o,
   output           trn_reof_n_o,
   output           trn_rerrfwd_n_o,
   output [1:0]     trn_rrem_n_o,
   output           trn_rsrc_dsc_n_o,
   output           trn_rsrc_rdy_n_o,
   input            trn_rdst_rdy_n_i,
   input            trn_rnpok_n_i,
   
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
   output           TRNRNPOKN_o

);

wire [(128+7+7)-1:0] srl_in;
wire [(128+7+7)-1:0] srl_out;

reg [6:0]  trn_rbar_hit_n_o_reg; 
reg        trn_recrc_err_n_o_reg;
reg        trn_rerrfwd_n_o_reg; 
reg [63:0] trn_rd_o_reg;     
reg        trn_rsof_n_o_reg;  
reg        trn_reof_n_o_reg;   
reg        trn_rrem_n_o_reg;    


//(* XIL_PAR_PATH = "*pcie_2_0_i.TRNRSRCRDYN.SR->D", XIL_PAR_IP_NAME = "PCIE", syn_keep = "1", keep = "TRUE" *)
reg        trn_rsrc_rdy_n_o_reg;
reg        trn_rsrc_dsc_n_o_reg;

reg [6:0]  trn_rbar_hit_n_o_reg_d; 
reg        trn_recrc_err_n_o_reg_d;
reg        trn_rerrfwd_n_o_reg_d; 
reg [63:0] trn_rd_o_reg_d;     
reg        trn_rsof_n_o_reg_d;  
reg        trn_reof_n_o_reg_d;   
reg        trn_rrem_n_o_reg_d;    
reg        trn_rsrc_rdy_n_o_reg_d;
reg        trn_rsrc_dsc_n_o_reg_d;

wire [6:0]  trn_rbar_hit_n_o_spry; 
wire        trn_recrc_err_n_o_spry;
wire        trn_rerrfwd_n_o_spry; 
wire [127:0] trn_rd_o_spry;     
wire        trn_rsof_n_o_spry;  
wire        trn_reof_n_o_spry;   
wire [1:0]  trn_rrem_n_o_spry;    
wire        trn_rsrc_rdy_n_o_spry;
wire        trn_rsrc_dsc_n_o_spry;

wire       empty;
reg        empty_plus_rdst_rdy_n_250;
wire [3:0] data_count;
reg        data_count_under_limit_n_500;
reg        data_count_under_limit_n_500_d;
reg        data_count_under_limit_n_250;
reg        data_count_under_limit_n_250_d;
reg        data_count_under_limit_n_250_d2;


//(* XIL_PAR_PATH = "*trn_rx_128_i.trn_rsrc_rdy_n_o_reg.Q->D", XIL_PAR_IP_NAME = "PCIE",  syn_keep = "1", keep = "TRUE" *)
reg        write_en;
reg        trn_rsof_n_o_reg_250;    
reg        trn_rsof_n_o_reg_d_250;    
reg        trn_reof_n_o_reg_250;
reg        trn_reof_n_o_reg_d_250;

reg        trn_rsrc_rdy_n_o_reg_250;
reg        trn_rsrc_rdy_n_o_reg_d_250;
reg        trn_rsrc_dsc_n_o_reg_250;
reg        trn_rsrc_dsc_n_o_reg_d_250;

reg        trn_recrc_err_n_o_reg_250;
reg        trn_recrc_err_n_o_reg_d_250;
reg        trn_rerrfwd_n_o_reg_250;
reg        trn_rerrfwd_n_o_reg_d_250;
reg [63:0] trn_rd_o_reg_250;
reg [63:0] trn_rd_o_reg_d_250;
reg [6:0]  trn_rbar_hit_n_o_reg_250;
reg [6:0]  trn_rbar_hit_n_o_reg_d_250;
reg        trn_rrem_n_o_reg_250;
reg        trn_rrem_n_o_reg_d_250;

reg        pkt_ended;
reg        in_a_pkt;

reg        trn_rnp_ok_n_250;
reg        TRNRNPOKN_500;
reg        NP_b_detect;
reg [2:0]  u_cnt = 0;
reg [2:0]  b_cnt = 0;



// -------------------------------------------------------------------------
//                                500Mhz
// -------------------------------------------------------------------------
always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      data_count_under_limit_n_500    <= #TCQ 1'b1; 
      data_count_under_limit_n_500_d  <= #TCQ 1'b1; 
   end else begin
      data_count_under_limit_n_500    <= #TCQ ~(data_count < `FIFO_LIMIT);
      data_count_under_limit_n_500_d  <= #TCQ data_count_under_limit_n_500;
   end
end


// Block directly to flops
always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      trn_rbar_hit_n_o_reg    <= #TCQ 7'h7f;   // 7
      trn_recrc_err_n_o_reg   <= #TCQ 1'b1;
      trn_rerrfwd_n_o_reg     <= #TCQ 1'b1;
      trn_rd_o_reg            <= #TCQ 64'd0;  // 64
      trn_rsof_n_o_reg        <= #TCQ 1'b1;
      trn_reof_n_o_reg        <= #TCQ 1'b1;
      trn_rrem_n_o_reg        <= #TCQ 1'b1;
      trn_rsrc_rdy_n_o_reg    <= #TCQ 1'b1;
      trn_rsrc_dsc_n_o_reg    <= #TCQ 1'b1;

      trn_rbar_hit_n_o_reg_d    <= #TCQ 7'h7f;   // 7
      trn_recrc_err_n_o_reg_d   <= #TCQ 1'b1;
      trn_rerrfwd_n_o_reg_d     <= #TCQ 1'b1;
      trn_rd_o_reg_d            <= #TCQ 64'd0;  // 64
      trn_rsof_n_o_reg_d        <= #TCQ 1'b1;
      trn_reof_n_o_reg_d        <= #TCQ 1'b1;
      trn_rrem_n_o_reg_d        <= #TCQ 1'b1;
      trn_rsrc_rdy_n_o_reg_d    <= #TCQ 1'b1;
      trn_rsrc_dsc_n_o_reg_d    <= #TCQ 1'b1;

      in_a_pkt                  <= #TCQ 1'b0;
   end else begin
      trn_rbar_hit_n_o_reg    <= #TCQ TRNRBARHITN_i;	// 7
      trn_recrc_err_n_o_reg   <= #TCQ TRNRECRCERRN_i;
      trn_rerrfwd_n_o_reg     <= #TCQ TRNRERRFWDN_i;
      trn_rd_o_reg            <= #TCQ TRNRD_i;		// 64
      trn_rsof_n_o_reg        <= #TCQ TRNRSOFN_i;
      trn_reof_n_o_reg        <= #TCQ TRNREOFN_i;
      trn_rrem_n_o_reg        <= #TCQ TRNRREMN_i;
      trn_rsrc_rdy_n_o_reg    <= #TCQ (TRNRSRCRDYN_i |
                                       data_count_under_limit_n_500_d);
      trn_rsrc_dsc_n_o_reg    <= #TCQ TRNRSRCDSCN_i;

      trn_rbar_hit_n_o_reg_d    <= #TCQ trn_rbar_hit_n_o_reg;	// 7
      trn_recrc_err_n_o_reg_d   <= #TCQ trn_recrc_err_n_o_reg;
      trn_rerrfwd_n_o_reg_d     <= #TCQ trn_rerrfwd_n_o_reg;
      trn_rd_o_reg_d            <= #TCQ trn_rd_o_reg;		// 64
      trn_rsof_n_o_reg_d        <= #TCQ trn_rsof_n_o_reg;
      trn_reof_n_o_reg_d        <= #TCQ trn_reof_n_o_reg;
      trn_rrem_n_o_reg_d        <= #TCQ trn_rrem_n_o_reg;
      trn_rsrc_rdy_n_o_reg_d    <= #TCQ trn_rsrc_rdy_n_o_reg;
      trn_rsrc_dsc_n_o_reg_d    <= #TCQ trn_rsrc_dsc_n_o_reg;



      if (~trn_reof_n_o_reg & ~trn_rsrc_rdy_n_o_reg)
         in_a_pkt <= #TCQ 1'b0;
      else if (~trn_rsof_n_o_reg & ~trn_rsrc_rdy_n_o_reg) 
         in_a_pkt <= #TCQ 1'b1;

   end
end


// -------------------------------------------------------------------------
//                                250Mhz
// -------------------------------------------------------------------------

assign #TCQ srl_in = {
                  trn_rsof_n_o_spry,
                  trn_reof_n_o_spry,
                  trn_rd_o_spry,             // 128
                  trn_rbar_hit_n_o_spry,     // 7
                  trn_recrc_err_n_o_spry,
                  trn_rerrfwd_n_o_spry,
                  trn_rrem_n_o_spry,         // 2
                  trn_rsrc_dsc_n_o_spry
};



//assign #TCQ trn_rsof_n_o_spry      =
//                ~(~trn_rsof_n_o_reg_250 | ~trn_rsof_n_o_reg_d_250);

// 3462
// to allow creation of <!eof sof> generation when throttled at end of pkt
assign #TCQ trn_rsof_n_o_spry =  (trn_rsof_n_o_reg_d_250 & 
                                      data_count_under_limit_n_250_d) ? 1 : 
                ~(~trn_rsof_n_o_reg_250 | ~trn_rsof_n_o_reg_d_250);




assign #TCQ trn_reof_n_o_spry      =
                ~(~trn_reof_n_o_reg_250 | ~trn_reof_n_o_reg_d_250);

assign #TCQ trn_rd_o_spry          = 
                 {trn_rd_o_reg_d_250, trn_rd_o_reg_250};

assign #TCQ trn_rbar_hit_n_o_spry  =
                 (trn_rsof_n_o_reg_250 ^ trn_reof_n_o_reg_d_250) ?
                   ~(~trn_rbar_hit_n_o_reg_250 | ~trn_rbar_hit_n_o_reg_d_250) : 
                      trn_rbar_hit_n_o_reg_250;


assign #TCQ trn_recrc_err_n_o_spry = 
                ~(~trn_recrc_err_n_o_reg_250 | ~trn_recrc_err_n_o_reg_d_250);

assign #TCQ trn_rerrfwd_n_o_spry   = 
                ~(~trn_rerrfwd_n_o_reg_250 | ~trn_rerrfwd_n_o_reg_d_250);

assign #TCQ trn_rrem_n_o_spry[1]   = 
                 (~trn_reof_n_o_reg_d_250 | ~trn_rsof_n_o_reg_250);

assign #TCQ trn_rrem_n_o_spry[0]   =
                ((trn_reof_n_o_reg_d_250 ? 1'b0 : trn_rrem_n_o_reg_d_250) |
                 (trn_reof_n_o_reg_250 ? 1'b0 : trn_rrem_n_o_reg_250)) ;


assign #TCQ trn_rsrc_rdy_n_o_spry  =
                ~(~trn_rsrc_rdy_n_o_reg_250 | ~trn_rsrc_rdy_n_o_reg_d_250);

assign #TCQ trn_rsrc_dsc_n_o_spry  = 
                ~(~trn_rsrc_dsc_n_o_reg_250 | ~trn_rsrc_dsc_n_o_reg_d_250);






sync_fifo #(

   .WIDTH(128+7+7),
   .DEPTH(8),
//   .STYLE("SRL")
   .STYLE("REG")

) sync_fifo_128 (

   .clk       ( user_clk ),
   .rst_n     ( rst_n_250 ),
   .din       ( srl_in ),
   .dout      ( srl_out ),

   .wr_en     ( write_en ),
   .rd_en     ( ~trn_rdst_rdy_n_i ),

   .data_count( data_count ),

   .empty     ( empty ),
   .afull     ( ),
   .aempty    ( ),
   .full      ( )

);


always @(posedge user_clk)
begin
   if (~rst_n_250)
   begin
      data_count_under_limit_n_250    <= #TCQ 1'b1;
      empty_plus_rdst_rdy_n_250       <= #TCQ 1'b1;

      data_count_under_limit_n_250_d  <= #TCQ 1'b1;
      data_count_under_limit_n_250_d2 <= #TCQ 1'b1;

      write_en                        <= #TCQ 1'b0;
      trn_rsof_n_o_reg_250            <= #TCQ 1'b1;
      trn_rsof_n_o_reg_d_250          <= #TCQ 1'b1;
      trn_reof_n_o_reg_250            <= #TCQ 1'b1;
      trn_reof_n_o_reg_d_250          <= #TCQ 1'b1;

      trn_rsrc_rdy_n_o_reg_250        <= #TCQ 1'b1;
      trn_rsrc_rdy_n_o_reg_d_250      <= #TCQ 1'b1;
      trn_rsrc_dsc_n_o_reg_250        <= #TCQ 1'b1;
      trn_rsrc_dsc_n_o_reg_d_250      <= #TCQ 1'b1;
 
      trn_recrc_err_n_o_reg_250       <= #TCQ 1'b1;
      trn_recrc_err_n_o_reg_d_250     <= #TCQ 1'b1;
      trn_rerrfwd_n_o_reg_250         <= #TCQ 1'b1;
      trn_rerrfwd_n_o_reg_d_250       <= #TCQ 1'b1;

      trn_rd_o_reg_d_250              <= #TCQ 64'd0;
      trn_rd_o_reg_250                <= #TCQ 64'd0;

      trn_rbar_hit_n_o_reg_250        <= #TCQ 7'h7f;
      trn_rbar_hit_n_o_reg_d_250      <= #TCQ 7'h7f;

      trn_rrem_n_o_reg_250            <= #TCQ 1'b1;
      trn_rrem_n_o_reg_d_250          <= #TCQ 1'b1;
      pkt_ended                       <= #TCQ 1'b0;

   end else begin

      data_count_under_limit_n_250    <= #TCQ ~(data_count < `FIFO_LIMIT); 
      if (~trn_rdst_rdy_n_i)
         empty_plus_rdst_rdy_n_250  <= #TCQ empty;

      data_count_under_limit_n_250_d  <= #TCQ data_count_under_limit_n_250;
      data_count_under_limit_n_250_d2 <= #TCQ data_count_under_limit_n_250_d;

      // when to reduce write_en by one after a rdst_rdy throttle



      if (write_en)
      begin
            // eof --
         if ((trn_rsof_n_o_spry & ~trn_reof_n_o_spry &  trn_rrem_n_o_spry[1]) | 
            // xx eof
            (                    ~trn_reof_n_o_spry & ~trn_rrem_n_o_spry[1])) 
               pkt_ended <= #TCQ 1'b1;
            else 
               pkt_ended <= #TCQ 1'b0;
      end


         write_en <= #TCQ (~trn_rsrc_rdy_n_o_reg_d | 
                          (~trn_rsrc_rdy_n_o_reg & ~in_a_pkt));




      trn_rsof_n_o_reg_250            <= #TCQ trn_rsof_n_o_reg;
      trn_rsof_n_o_reg_d_250          <= #TCQ trn_rsof_n_o_reg_d;
      trn_reof_n_o_reg_250            <= #TCQ trn_reof_n_o_reg;
      trn_reof_n_o_reg_d_250          <= #TCQ trn_reof_n_o_reg_d;

      trn_rsrc_rdy_n_o_reg_250        <= #TCQ trn_rsrc_rdy_n_o_reg;
      trn_rsrc_rdy_n_o_reg_d_250      <= #TCQ trn_rsrc_rdy_n_o_reg_d;
      trn_rsrc_dsc_n_o_reg_250        <= #TCQ trn_rsrc_dsc_n_o_reg;
      trn_rsrc_dsc_n_o_reg_d_250      <= #TCQ trn_rsrc_dsc_n_o_reg_d;

      trn_recrc_err_n_o_reg_250       <= #TCQ trn_recrc_err_n_o_reg;
      trn_recrc_err_n_o_reg_d_250     <= #TCQ trn_recrc_err_n_o_reg_d;
      trn_rerrfwd_n_o_reg_250         <= #TCQ trn_rerrfwd_n_o_reg;
      trn_rerrfwd_n_o_reg_d_250       <= #TCQ trn_rerrfwd_n_o_reg_d;

      trn_rd_o_reg_250                <= #TCQ trn_rd_o_reg;
      trn_rd_o_reg_d_250              <= #TCQ trn_rd_o_reg_d;

      trn_rbar_hit_n_o_reg_250        <= #TCQ trn_rbar_hit_n_o_reg;
      trn_rbar_hit_n_o_reg_d_250      <= #TCQ trn_rbar_hit_n_o_reg_d;

      trn_rrem_n_o_reg_250            <= #TCQ trn_rrem_n_o_reg;
      trn_rrem_n_o_reg_d_250          <= #TCQ trn_rrem_n_o_reg_d;

   end
end




assign #TCQ trn_rsof_n_o        = srl_out[141];
assign #TCQ trn_reof_n_o        = srl_out[140];
assign #TCQ trn_rd_o            = srl_out[139:12];	// 128
assign #TCQ trn_rbar_hit_n_o    = srl_out[11:5];	// 7
assign #TCQ trn_recrc_err_n_o   = srl_out[4];
assign #TCQ trn_rerrfwd_n_o     = srl_out[3];
assign #TCQ trn_rrem_n_o        = srl_out[2:1];         // 2
assign #TCQ trn_rsrc_rdy_n_o    = empty_plus_rdst_rdy_n_250;
assign #TCQ trn_rsrc_dsc_n_o    = srl_out[0];


assign #TCQ TRNRDSTRDYN_o = data_count_under_limit_n_500_d;




//////////////////////////////////////////////////////////////////////////
// trn_rnp_ok_n enhancement
//////////////////////////////////////////////////////////////////////////
always @(posedge user_clk)
begin
   if (~rst_n_250)
   begin
      trn_rnp_ok_n_250 <= #TCQ 0;
   end else begin
      trn_rnp_ok_n_250 <= #TCQ trn_rnpok_n_i;
   end
end

always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      TRNRNPOKN_500 <= #TCQ 0;
   end else begin
      if (~trn_rnp_ok_n_250 & (u_cnt == (b_cnt + NP_b_detect) ))
         TRNRNPOKN_500 <= #TCQ 0;
      else
         TRNRNPOKN_500 <= #TCQ 1;
   end
end

assign TRNRNPOKN_o = TRNRNPOKN_500 | NP_b_detect;

// counters
always @(posedge user_clk)
begin
   if (~rst_n_250)
   begin
      u_cnt <= #TCQ 0;
   end else begin

      if( ( (  ((trn_rd_o[60:56] == 5'b00001) |
                (trn_rd_o[60:56] == 5'b00010) |
                (trn_rd_o[60:56] == 5'b00100) |
                ~trn_rd_o[62] & (trn_rd_o[60:56] == 5'b00000)) & trn_rrem_n_o[1]) |
             ( ((trn_rd_o[124:120] == 5'b00001) |
                (trn_rd_o[124:120] == 5'b00010) |
                (trn_rd_o[124:120] == 5'b00100) |
                ~trn_rd_o[126] & (trn_rd_o[124:120] == 5'b00000)) & ~trn_rrem_n_o[1])) &

                ~trn_rsof_n_o & ~trn_rsrc_rdy_n_o & ~trn_rdst_rdy_n_i )
         begin
            u_cnt <= #TCQ u_cnt + 1;
         end

   end
end


always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      NP_b_detect <= #TCQ 0;
   end else begin

   if ( ( (TRNRD_i[60:56] == 5'b00001) |
          (TRNRD_i[60:56] == 5'b00010) |
          (TRNRD_i[60:56] == 5'b00100) |
         (~TRNRD_i[62] & (TRNRD_i[60:56] == 5'b00000)) ) &
            ~TRNRSOFN_i & ~TRNRSRCRDYN_i & ~TRNRDSTRDYN_o )
         begin
            NP_b_detect <= #TCQ 1;
         end else
            NP_b_detect <= #TCQ 0;
   end
end



always @(posedge block_clk)
begin
   if (~rst_n_500)
   begin
      b_cnt <= #TCQ 0;
   end else begin
      b_cnt <= #TCQ b_cnt + NP_b_detect;
   end
end



endmodule

