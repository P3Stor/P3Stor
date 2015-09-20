
`timescale 1ns / 1ps

module pcie_2_0_ep #(
  parameter        PL_FAST_TRAIN	        = "FALSE"
    )

(
  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn,
  
  output									   fifo_clk,
  
  input										   CMGFTL_cmd_fifo_full_i,
  input										   CMGFTL_cmd_fifo_almost_full_i,
  output									   CMGFTL_cmd_fifo_wr_en_o,
  output [127:0]							   CMGFTL_cmd_fifo_data_o,
  
  input 									   FTLCMG_cmd_fifo_empty_i,
  input										   FTLCMG_cmd_fifo_almost_empty_i,
  output									   FTLCMG_cmd_fifo_rd_en_o,
  input [127:0]								   FTLCMG_cmd_fifo_data_i,
  
  input										   RX_data_fifo_full_i,
  input										   RX_data_fifo_almost_full_i,
  output									   RX_data_fifo_wr_en_o,
  output [127:0]							   RX_data_fifo_data_o,
  input										   RX_data_fifo_av_i,
  
  input 									   TX_data_fifo_empty_i,
  input										   TX_data_fifo_almost_empty_i,
  output									   TX_data_fifo_rd_en_o,
  input [127:0]								   TX_data_fifo_data_i,

`ifdef ENABLE_LEDS
  output                                       led_0,
  output                                       led_1,
  output                                       led_2,
`endif
  input                                        sys_clk_p,
  input                                        sys_clk_n,
  input                                        sys_reset_n
);	
  wire                                        trn_clk;
  wire                                        trn_reset_n;
  wire                                        trn_lnk_up_n;

  // Tx
  wire  [5:0]                                 trn_tbuf_av;
  wire                                        trn_tcfg_req_n;
  wire                                        trn_terr_drop_n;
  wire                                        trn_tdst_rdy_n;
  wire [127:0]                                trn_td;
  wire [1:0]                                  trn_trem_n;
  wire                                        trn_tsof_n;
  wire                                        trn_teof_n;
  wire                                        trn_tsrc_rdy_n;
  wire                                        trn_tsrc_dsc_n;
  wire                                        trn_terrfwd_n;
  wire                                        trn_tcfg_gnt_n;
  wire                                        trn_tstr_n;

  // Rx
  wire [127:0]                                trn_rd;
  wire [1:0]                                  trn_rrem_n;
  wire                                        trn_rsof_n;
  wire                                        trn_reof_n;
  wire                                        trn_rsrc_rdy_n;
  wire                                        trn_rsrc_dsc_n;
  wire                                        trn_rerrfwd_n;
  wire  [6:0]                                 trn_rbar_hit_n;
  wire                                        trn_rdst_rdy_n;
  wire                                        trn_rnp_ok_n;

  // Flow Control
  wire [11:0]                                 trn_fc_cpld;
  wire [7:0]                                  trn_fc_cplh;
  wire [11:0]                                 trn_fc_npd;
  wire [7:0]                                  trn_fc_nph;
  wire [11:0]                                 trn_fc_pd;
  wire [7:0]                                  trn_fc_ph;
  wire  [2:0]                                 trn_fc_sel;


  //-------------------------------------------------------
  // 3. Configuration (CFG) Interface
  //-------------------------------------------------------

  wire [31:0]                                 cfg_do;
  wire                                        cfg_rd_wr_done_n;
  wire  [31:0]                                cfg_di;
  wire   [3:0]                                cfg_byte_en_n;
  wire   [9:0]                                cfg_dwaddr;
  wire                                        cfg_wr_en_n;
  wire                                        cfg_rd_en_n;

  wire                                        cfg_err_cor_n;
  wire                                        cfg_err_ur_n;
  wire                                        cfg_err_ecrc_n;
  wire                                        cfg_err_cpl_timeout_n;
  wire                                        cfg_err_cpl_abort_n;
  wire                                        cfg_err_cpl_unexpect_n;
  wire                                        cfg_err_posted_n;
  wire                                        cfg_err_locked_n;
  wire  [47:0]                                cfg_err_tlp_cpl_header;
  wire                                        cfg_err_cpl_rdy_n;
  wire                                        cfg_interrupt_n;
  wire                                        cfg_interrupt_rdy_n;
  wire                                        cfg_interrupt_assert_n;
  wire  [7:0]                                 cfg_interrupt_di;
  wire [7:0]                                  cfg_interrupt_do;
  wire [2:0]                                  cfg_interrupt_mmenable;
  wire                                        cfg_interrupt_msienable;
  wire                                        cfg_interrupt_msixenable;
  wire                                        cfg_interrupt_msixfm;
  wire                                        cfg_turnoff_ok_n;
  wire                                        cfg_to_turnoff_n;
  wire                                        cfg_trn_pending_n;
  wire                                        cfg_pm_wake_n;
  wire  [7:0]                                 cfg_bus_number;
  wire  [4:0]                                 cfg_device_number;
  wire  [2:0]                                 cfg_function_number;
  wire [15:0]                                 cfg_status;
  wire [15:0]                                 cfg_command;
  wire [15:0]                                 cfg_dstatus;
  wire [15:0]                                 cfg_dcommand;
  wire [15:0]                                 cfg_lstatus;
  wire [15:0]                                 cfg_lcommand;
  wire [15:0]                                 cfg_dcommand2;
  wire  [2:0]                                 cfg_pcie_link_state_n;
  wire  [63:0]                                cfg_dsn;

  //-------------------------------------------------------
  // 4. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  wire [2:0]                                  pl_initial_link_width;
  wire [1:0]                                  pl_lane_reversal_mode;
  wire                                        pl_link_gen2_capable;
  wire                                        pl_link_partner_gen2_supported;
  wire                                        pl_link_upcfg_capable;
  wire [5:0]                                  pl_ltssm_state;
  wire                                        pl_received_hot_rst;
  wire                                        pl_sel_link_rate;
  wire [1:0]                                  pl_sel_link_width;
  wire                                        pl_directed_link_auton;
  wire  [1:0]                                 pl_directed_link_change;
  wire                                        pl_directed_link_speed;
  wire  [1:0]                                 pl_directed_link_width;
  wire                                        pl_upstream_prefer_deemph;

  wire                                        sys_clk_c;
  wire                                        sys_reset_n_c;
  
  
  assign fifo_clk = trn_clk;

  //-------------------------------------------------------

IBUFDS_GTXE1 refclk_ibuf (.O(sys_clk_c), .ODIV2(), .I(sys_clk_p), .IB(sys_clk_n), .CEB(1'b0));

IBUF   sys_reset_n_ibuf (.O(sys_reset_n_c), .I(sys_reset_n));
`ifdef ENABLE_LEDS
   OBUF   led_0_obuf (.O(led_0), .I(sys_reset_n_c));
   OBUF   led_1_obuf (.O(led_1), .I(trn_reset_n));
   OBUF   led_2_obuf (.O(led_2), .I(trn_lnk_up_n));
`endif

FDCP #(

  .INIT(1'b1)

) trn_lnk_up_n_int_i (

  .Q (trn_lnk_up_n),
  .D (trn_lnk_up_n_int1),
  .C (trn_clk),
  .CLR (1'b0),
  .PRE (1'b0)

);

FDCP #(

  .INIT(1'b1)

) trn_reset_n_i (

  .Q (trn_reset_n),
  .D (trn_reset_n_int1),
  .C (trn_clk),
  .CLR (1'b0),
  .PRE (1'b0)

);

v6_pcie_v1_7 #( 

  .PL_FAST_TRAIN			( PL_FAST_TRAIN )
)
core (

  //-------------------------------------------------------
  // 1. PCI Express (pci_exp) Interface
  //-------------------------------------------------------

  // Tx
  .pci_exp_txp( pci_exp_txp ),
  .pci_exp_txn( pci_exp_txn ),

  // Rx
  .pci_exp_rxp( pci_exp_rxp ),
  .pci_exp_rxn( pci_exp_rxn ),

  //-------------------------------------------------------
  // 2. Transaction (TRN) Interface
  //-------------------------------------------------------

  // Common
  .trn_clk( trn_clk ),
  .trn_reset_n( trn_reset_n_int1 ),
  .trn_lnk_up_n( trn_lnk_up_n_int1 ),

  // Tx
  .trn_tbuf_av( trn_tbuf_av ),
  .trn_terr_drop_n( trn_terr_drop_n ),
  .trn_tdst_rdy_n( trn_tdst_rdy_n ),
  .trn_td( trn_td ),
  .trn_trem_n( trn_trem_n ),
  .trn_tsof_n( trn_tsof_n ),
  .trn_teof_n( trn_teof_n ),
  .trn_tsrc_rdy_n( trn_tsrc_rdy_n ),
  .trn_tsrc_dsc_n( trn_tsrc_dsc_n ),
  .trn_terrfwd_n( trn_terrfwd_n ),
  .trn_tstr_n( trn_tstr_n ),

  // Rx
  .trn_rd( trn_rd ),
  .trn_rrem_n( trn_rrem_n ),
  .trn_rsof_n( trn_rsof_n ),
  .trn_reof_n( trn_reof_n ),
  .trn_rsrc_rdy_n( trn_rsrc_rdy_n ),
  .trn_rsrc_dsc_n( trn_rsrc_dsc_n ),
  .trn_rerrfwd_n( trn_rerrfwd_n ),
  .trn_rbar_hit_n( trn_rbar_hit_n ),
  .trn_rdst_rdy_n( trn_rdst_rdy_n ),
  .trn_rnp_ok_n( trn_rnp_ok_n ),

  // Flow Control
  .trn_fc_cpld( trn_fc_cpld ),
  .trn_fc_cplh( trn_fc_cplh ),
  .trn_fc_npd( trn_fc_npd ),
  .trn_fc_nph( trn_fc_nph ),
  .trn_fc_pd( trn_fc_pd ),
  .trn_fc_ph( trn_fc_ph ),
  .trn_fc_sel( trn_fc_sel ),


  //-------------------------------------------------------
  // 3. Configuration (CFG) Interface
  //-------------------------------------------------------

  .cfg_do( cfg_do ),
  .cfg_rd_wr_done_n( cfg_rd_wr_done_n),
  .cfg_di( cfg_di ),
  .cfg_byte_en_n( cfg_byte_en_n ),
  .cfg_dwaddr( cfg_dwaddr ),
  .cfg_wr_en_n( cfg_wr_en_n ),
  .cfg_rd_en_n( cfg_rd_en_n ),

  .cfg_err_cor_n( cfg_err_cor_n ),
  .cfg_err_ur_n( cfg_err_ur_n ),
  .cfg_err_ecrc_n( cfg_err_ecrc_n ),
  .cfg_err_cpl_timeout_n( cfg_err_cpl_timeout_n ),
  .cfg_err_cpl_abort_n( cfg_err_cpl_abort_n ),
  .cfg_err_cpl_unexpect_n( cfg_err_cpl_unexpect_n ),
  .cfg_err_posted_n( cfg_err_posted_n ),
  .cfg_err_locked_n( cfg_err_locked_n ),
  .cfg_err_tlp_cpl_header( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy_n( cfg_err_cpl_rdy_n ),
  .cfg_interrupt_n( cfg_interrupt_n ),
  .cfg_interrupt_rdy_n( cfg_interrupt_rdy_n ),
  .cfg_interrupt_assert_n( cfg_interrupt_assert_n ),
  .cfg_interrupt_di( cfg_interrupt_di ),
  .cfg_interrupt_do( cfg_interrupt_do ),
  .cfg_interrupt_mmenable( cfg_interrupt_mmenable ),
  .cfg_interrupt_msienable( cfg_interrupt_msienable ),
  .cfg_interrupt_msixenable( cfg_interrupt_msixenable ),
  .cfg_interrupt_msixfm( cfg_interrupt_msixfm ),
  .cfg_turnoff_ok_n( cfg_turnoff_ok_n ),
  .cfg_to_turnoff_n( cfg_to_turnoff_n ),
  .cfg_trn_pending_n( cfg_trn_pending_n ),
  .cfg_pm_wake_n( cfg_pm_wake_n ),
  .cfg_bus_number( cfg_bus_number ),
  .cfg_device_number( cfg_device_number ),
  .cfg_function_number( cfg_function_number ),
  .cfg_status( cfg_status ),
  .cfg_command( cfg_command ),
  .cfg_dstatus( cfg_dstatus ),
  .cfg_dcommand( cfg_dcommand ),
  .cfg_lstatus( cfg_lstatus ),
  .cfg_lcommand( cfg_lcommand ),
  .cfg_dcommand2( cfg_dcommand2 ),
  .cfg_pcie_link_state_n( cfg_pcie_link_state_n ),
  .cfg_dsn( cfg_dsn ),

  //-------------------------------------------------------
  // 4. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  .pl_initial_link_width( pl_initial_link_width ),
  .pl_lane_reversal_mode( pl_lane_reversal_mode ),
  .pl_link_gen2_capable( pl_link_gen2_capable ),
  .pl_link_partner_gen2_supported( pl_link_partner_gen2_supported ),
  .pl_link_upcfg_capable( pl_link_upcfg_capable ),
  .pl_ltssm_state( pl_ltssm_state ),
  .pl_received_hot_rst( pl_received_hot_rst ),
  .pl_sel_link_rate( pl_sel_link_rate ),
  .pl_sel_link_width( pl_sel_link_width ),
  .pl_directed_link_auton( pl_directed_link_auton ),
  .pl_directed_link_change( pl_directed_link_change ),
  .pl_directed_link_speed( pl_directed_link_speed ),
  .pl_directed_link_width( pl_directed_link_width ),
  .pl_upstream_prefer_deemph( pl_upstream_prefer_deemph ),

  //-------------------------------------------------------
  // 5. System  (SYS) Interface
  //-------------------------------------------------------

  .sys_clk( sys_clk_c ),
  .sys_reset_n( sys_reset_n_c )

);


pcie_app_v6 app (

  //-------------------------------------------------------
  // 1. Transaction (TRN) Interface
  //-------------------------------------------------------

  // Common
  .trn_clk( trn_clk ),
  .trn_reset_n( trn_reset_n_int1 ),
  .trn_lnk_up_n( trn_lnk_up_n_int1 ),

  // Tx
  .trn_tbuf_av( trn_tbuf_av ),
  .trn_tcfg_req_n( trn_tcfg_req_n ),
  .trn_terr_drop_n( trn_terr_drop_n ),
  .trn_tdst_rdy_n( trn_tdst_rdy_n ),
  .trn_td( trn_td ),
  .trn_trem_n( trn_trem_n ),
  .trn_tsof_n( trn_tsof_n ),
  .trn_teof_n( trn_teof_n ),
  .trn_tsrc_rdy_n( trn_tsrc_rdy_n ),
  .trn_tsrc_dsc_n( trn_tsrc_dsc_n ),
  .trn_terrfwd_n( trn_terrfwd_n ),
  .trn_tcfg_gnt_n( trn_tcfg_gnt_n ),
  .trn_tstr_n( trn_tstr_n ),

  // Rx
  .trn_rd( trn_rd ),
  .trn_rrem_n( trn_rrem_n ),
  .trn_rsof_n( trn_rsof_n ),
  .trn_reof_n( trn_reof_n ),
  .trn_rsrc_rdy_n( trn_rsrc_rdy_n ),
  .trn_rsrc_dsc_n( trn_rsrc_dsc_n ),
  .trn_rerrfwd_n( trn_rerrfwd_n ),
  .trn_rbar_hit_n( trn_rbar_hit_n ),
  .trn_rdst_rdy_n( trn_rdst_rdy_n ),
  .trn_rnp_ok_n( trn_rnp_ok_n ),

  // Flow Control
  .trn_fc_cpld( trn_fc_cpld ),
  .trn_fc_cplh( trn_fc_cplh ),
  .trn_fc_npd( trn_fc_npd ),
  .trn_fc_nph( trn_fc_nph ),
  .trn_fc_pd( trn_fc_pd ),
  .trn_fc_ph( trn_fc_ph ),
  .trn_fc_sel( trn_fc_sel ),
  
  .CMGFTL_cmd_fifo_full_i(CMGFTL_cmd_fifo_full_i),
  .CMGFTL_cmd_fifo_almost_full_i(CMGFTL_cmd_fifo_almost_full_i),
  .CMGFTL_cmd_fifo_wr_en_o(CMGFTL_cmd_fifo_wr_en_o),
  .CMGFTL_cmd_fifo_data_o(CMGFTL_cmd_fifo_data_o),
  
  .FTLCMG_cmd_fifo_empty_i(FTLCMG_cmd_fifo_empty_i),  
  .FTLCMG_cmd_fifo_almost_empty_i(FTLCMG_cmd_fifo_almost_empty_i),
  .FTLCMG_cmd_fifo_rd_en_o(FTLCMG_cmd_fifo_rd_en_o),
  .FTLCMG_cmd_fifo_data_i(FTLCMG_cmd_fifo_data_i),
  
  .RX_data_fifo_full_i(RX_data_fifo_full_i),
  .RX_data_fifo_almost_full_i(RX_data_fifo_almost_full_i),  
  .RX_data_fifo_wr_en_o(RX_data_fifo_wr_en_o),
  .RX_data_fifo_data_o(RX_data_fifo_data_o),
  .RX_data_fifo_av_i(RX_data_fifo_av_i),    

  .TX_data_fifo_empty_i(TX_data_fifo_empty_i),  
  .TX_data_fifo_almost_empty_i(TX_data_fifo_almost_empty_i),
  .TX_data_fifo_rd_en_o(TX_data_fifo_rd_en_o),
  .TX_data_fifo_data_i(TX_data_fifo_data_i),
  
  //-------------------------------------------------------
  // 2. Configuration (CFG) Interface
  //-------------------------------------------------------

  .cfg_do( cfg_do ),
  .cfg_rd_wr_done_n( cfg_rd_wr_done_n),
  .cfg_di( cfg_di ),
  .cfg_byte_en_n( cfg_byte_en_n ),
  .cfg_dwaddr( cfg_dwaddr ),
  .cfg_wr_en_n( cfg_wr_en_n ),
  .cfg_rd_en_n( cfg_rd_en_n ),

  .cfg_err_cor_n( cfg_err_cor_n ),
  .cfg_err_ur_n( cfg_err_ur_n ),
  .cfg_err_ecrc_n( cfg_err_ecrc_n ),
  .cfg_err_cpl_timeout_n( cfg_err_cpl_timeout_n ),
  .cfg_err_cpl_abort_n( cfg_err_cpl_abort_n ),
  .cfg_err_cpl_unexpect_n( cfg_err_cpl_unexpect_n ),
  .cfg_err_posted_n( cfg_err_posted_n ),
  .cfg_err_locked_n( cfg_err_locked_n ),
  .cfg_err_tlp_cpl_header( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy_n( cfg_err_cpl_rdy_n ),
  .cfg_interrupt_n( cfg_interrupt_n ),
  .cfg_interrupt_rdy_n( cfg_interrupt_rdy_n ),
  .cfg_interrupt_assert_n( cfg_interrupt_assert_n ),
  .cfg_interrupt_di( cfg_interrupt_di ),
  .cfg_interrupt_do( cfg_interrupt_do ),
  .cfg_interrupt_mmenable( cfg_interrupt_mmenable ),
  .cfg_interrupt_msienable( cfg_interrupt_msienable ),
  .cfg_interrupt_msixenable( cfg_interrupt_msixenable ),
  .cfg_interrupt_msixfm( cfg_interrupt_msixfm ),
  .cfg_turnoff_ok_n( cfg_turnoff_ok_n ),
  .cfg_to_turnoff_n( cfg_to_turnoff_n ),
  .cfg_trn_pending_n( cfg_trn_pending_n ),
  .cfg_pm_wake_n( cfg_pm_wake_n ),
  .cfg_bus_number( cfg_bus_number ),
  .cfg_device_number( cfg_device_number ),
  .cfg_function_number( cfg_function_number ),
  .cfg_status( cfg_status ),
  .cfg_command( cfg_command ),
  .cfg_dstatus( cfg_dstatus ),
  .cfg_dcommand( cfg_dcommand ),
  .cfg_lstatus( cfg_lstatus ),
  .cfg_lcommand( cfg_lcommand ),
  .cfg_dcommand2( cfg_dcommand2 ),
  .cfg_pcie_link_state_n( cfg_pcie_link_state_n ),
  .cfg_dsn( cfg_dsn ),

  //-------------------------------------------------------
  // 3. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  .pl_initial_link_width( pl_initial_link_width ),
  .pl_lane_reversal_mode( pl_lane_reversal_mode ),
  .pl_link_gen2_capable( pl_link_gen2_capable ),
  .pl_link_partner_gen2_supported( pl_link_partner_gen2_supported ),
  .pl_link_upcfg_capable( pl_link_upcfg_capable ),
  .pl_ltssm_state( pl_ltssm_state ),
  .pl_received_hot_rst( pl_received_hot_rst ),
  .pl_sel_link_rate( pl_sel_link_rate ),
  .pl_sel_link_width( pl_sel_link_width ),
  .pl_directed_link_auton( pl_directed_link_auton ),
  .pl_directed_link_change( pl_directed_link_change ),
  .pl_directed_link_speed( pl_directed_link_speed ),
  .pl_directed_link_width( pl_directed_link_width ),
  .pl_upstream_prefer_deemph( pl_upstream_prefer_deemph )

);

endmodule
