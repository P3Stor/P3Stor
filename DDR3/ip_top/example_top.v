//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 3.92
//  \   \         Application        : MIG
//  /   /         Filename           : example_top.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:00 $
// \   \  /  \    Date Created       : Mon Jun 23 2008
//  \___\/\___\
//
// Device           : Virtex-6
// Design Name      : DDR3 SDRAM
// Purpose          :
//                   Top-level  module. This module serves both as an example,
//                   and allows the user to synthesize a self-contained design,
//                   which they can use to test their hardware. In addition to
//                   the memory controller.
//                   instantiates:
//                     1. Clock generation/distribution, reset logic
//                     2. IDELAY control block
//                     3. Synthesizable testbench - used to model user's backend
//                        logic
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module example_top #
  (
   parameter REFCLK_FREQ             = 200,
                                       // # = 200 for all design frequencies of
                                       //         -1 speed grade devices
                                       //   = 200 when design frequency < 480 MHz
                                       //         for -2 and -3 speed grade devices.
                                       //   = 300 when design frequency >= 480 MHz
                                       //         for -2 and -3 speed grade devices.
   parameter IODELAY_GRP             = "IODELAY_MIG",
                                       // It is associated to a set of IODELAYs with
                                       // an IDELAYCTRL that have same IODELAY CONTROLLER
                                       // clock frequency.
   parameter MMCM_ADV_BANDWIDTH      = "OPTIMIZED",
                                       // MMCM programming algorithm
   parameter CLKFBOUT_MULT_F         = 8,
                                       // write PLL VCO multiplier.
   parameter DIVCLK_DIVIDE           = 2,
                                       // write PLL VCO divisor.
   parameter CLKOUT_DIVIDE           = 4,
                                       // VCO output divisor for fast (memory) clocks.
   parameter nCK_PER_CLK             = 2,
                                       // # of memory CKs per fabric clock.
                                       // # = 2, 1.
   parameter tCK                     = 2500,
                                       // memory tCK paramter.
                                       // # = Clock Period.
   parameter DEBUG_PORT              = "ON",
                                       // # = "ON" Enable debug signals/controls.
                                       //   = "OFF" Disable debug signals/controls.
   parameter SIM_BYPASS_INIT_CAL     = "OFF",
                                       // # = "OFF" -  Complete memory init &
                                       //              calibration sequence
                                       // # = "SKIP" - Skip memory init &
                                       //              calibration sequence
                                       // # = "FAST" - Skip memory init & use
                                       //              abbreviated calib sequence
   parameter nCS_PER_RANK            = 1,
                                       // # of unique CS outputs per Rank for
                                       // phy.
   parameter DQS_CNT_WIDTH           = 3,
                                       // # = ceil(log2(DQS_WIDTH)).
   parameter RANK_WIDTH              = 1,
                                       // # = ceil(log2(RANKS)).
   parameter BANK_WIDTH              = 3,
                                       // # of memory Bank Address bits.
   parameter CK_WIDTH                = 2,
                                       // # of CK/CK# outputs to memory.
   parameter CKE_WIDTH               = 2,
                                       // # of CKE outputs to memory.
   parameter COL_WIDTH               = 10,
                                       // # of memory Column Address bits.
   parameter CS_WIDTH                = 2,
                                       // # of unique CS outputs to memory.
   parameter DM_WIDTH                = 8,
                                       // # of Data Mask bits.
   parameter DQ_WIDTH                = 64,
                                       // # of Data (DQ) bits.
   parameter DQS_WIDTH               = 8,
                                       // # of DQS/DQS# bits.
   parameter ROW_WIDTH               = 15,
                                       // # of memory Row Address bits.
   parameter BURST_MODE              = "8",
                                       // Burst Length (Mode Register 0).
                                       // # = "8", "4", "OTF".
   parameter BM_CNT_WIDTH            = 2,
                                       // # = ceil(log2(nBANK_MACHS)).
   parameter ADDR_CMD_MODE           = "1T" ,
                                       // # = "2T", "1T".
   parameter ORDERING                = "NORM",
                                       // # = "NORM", "STRICT".
   parameter WRLVL                   = "ON",
                                       // # = "ON" - DDR3 SDRAM
                                       //   = "OFF" - DDR2 SDRAM.
   parameter PHASE_DETECT            = "ON",
                                       // # = "ON", "OFF".
   parameter RTT_NOM                 = "40",
                                       // RTT_NOM (ODT) (Mode Register 1).
                                       // # = "DISABLED" - RTT_NOM disabled,
                                       //   = "120" - RZQ/2,
                                       //   = "60"  - RZQ/4,
                                       //   = "40"  - RZQ/6.
   parameter RTT_WR                  = "120",
                                       // RTT_WR (ODT) (Mode Register 2).
                                       // # = "OFF" - Dynamic ODT off,
                                       //   = "120" - RZQ/2,
                                       //   = "60"  - RZQ/4,
   parameter OUTPUT_DRV              = "HIGH",
                                       // Output Driver Impedance Control (Mode Register 1).
                                       // # = "HIGH" - RZQ/7,
                                       //   = "LOW" - RZQ/6.
   parameter REG_CTRL                = "OFF",
                                       // # = "ON" - RDIMMs,
                                       //   = "OFF" - Components, SODIMMs, UDIMMs.
   parameter nDQS_COL0               = 3,
                                       // Number of DQS groups in I/O column #1.
   parameter nDQS_COL1               = 5,
                                       // Number of DQS groups in I/O column #2.
   parameter nDQS_COL2               = 0,
                                       // Number of DQS groups in I/O column #3.
   parameter nDQS_COL3               = 0,
                                       // Number of DQS groups in I/O column #4.
   parameter DQS_LOC_COL0            = 24'h020100,
                                       // DQS groups in column #1.
   parameter DQS_LOC_COL1            = 40'h0706050403,
                                       // DQS groups in column #2.
   parameter DQS_LOC_COL2            = 0,
                                       // DQS groups in column #3.
   parameter DQS_LOC_COL3            = 0,
                                       // DQS groups in column #4.
   parameter tPRDI                   = 1_000_000,
                                       // memory tPRDI paramter.
   parameter tREFI                   = 7800000,
                                       // memory tREFI paramter.
   parameter tZQI                    = 128_000_000,
                                       // memory tZQI paramter.
   parameter ADDR_WIDTH              = 29,
                                       // # = RANK_WIDTH + BANK_WIDTH
                                       //     + ROW_WIDTH + COL_WIDTH;
   parameter ECC                     = "OFF",
   parameter ECC_TEST                = "OFF",
   parameter TCQ                     = 100,
   // Traffic Gen related parameters
   parameter EYE_TEST                = "FALSE",
                                       // set EYE_TEST = "TRUE" to probe memory
                                       // signals. Traffic Generator will only
                                       // write to one single location and no
                                       // read transactions will be generated.

   parameter SIMULATION              = "FALSE",
   parameter DATA_MODE               = 2,
   parameter ADDR_MODE               = 3,
   parameter TST_MEM_INSTR_MODE      = "R_W_INSTR_MODE",
   parameter DATA_PATTERN            = "DGEN_ALL",
                                        // DATA_PATTERN shoule be set to "DGEN_ALL"
                                        // unless it is targeted for S6 small device.
                                        // "DGEN_HAMMER", "DGEN_WALKING1",
                                        // "DGEN_WALKING0","DGEN_ADDR","
                                        // "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
   parameter CMD_PATTERN             = "CGEN_ALL",
                                        // CMD_PATTERN shoule be set to "CGEN_ALL"
                                        // unless it is targeted for S6 small device.
                                        // "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
                                        // "CGEN_SEQUENTIAL", "CGEN_ALL"

   parameter BEGIN_ADDRESS           = 32'h00000000,
   parameter PRBS_SADDR_MASK_POS     = 32'h00000000,
   parameter END_ADDRESS             = 32'h00ffffff,
   parameter PRBS_EADDR_MASK_POS     = 32'hff000000,
   parameter SEL_VICTIM_LINE         = 11,
   parameter RST_ACT_LOW             = 1,
                                       // =1 for active low reset,
                                       // =0 for active high.
   parameter INPUT_CLK_TYPE          = "SINGLE_ENDED",
                                       // input clock type DIFFERENTIAL or SINGLE_ENDED
   parameter STARVE_LIMIT            = 2,
                                       // # = 2,3,4.
	//ftl parameter
	parameter DRAM_IO_WIDTH   		= 256,//DRAM IO욱똑
	parameter COMMAND_WIDTH 		= 128, //츱즈욱똑	
	parameter FLASH_IO_WIDTH 			= 8 //flash욱똑
   )
  (

 	input                             sys_clk,    //single ended system clocks
  input                             clk_ref,     //single ended iodelayctrl clk
   inout  [DQ_WIDTH-1:0]                ddr3_dq,
   output [ROW_WIDTH-1:0]               ddr3_addr,
   output [BANK_WIDTH-1:0]              ddr3_ba,
   output                               ddr3_ras_n,
   output                               ddr3_cas_n,
   output                               ddr3_we_n,
   output                               ddr3_reset_n,
   output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n,
   output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt,
   output [CKE_WIDTH-1:0]               ddr3_cke,
   output [DM_WIDTH-1:0]                 ddr3_dm,
   inout  [DQS_WIDTH-1:0]               ddr3_dqs_p,
   inout  [DQS_WIDTH-1:0]               ddr3_dqs_n,
   output [CK_WIDTH-1:0]                ddr3_ck_p,
   output [CK_WIDTH-1:0]                ddr3_ck_n,
   inout                                sda,
   output                               scl,
   output                               heartbeat,
   output                               phy_init_done,
   
   //PCIE interface
		output  [7:0]    		    pci_exp_txp,
		output  [7:0]    		    pci_exp_txn,
		input   [7:0]    		    pci_exp_rxp,
		input   [7:0]    		    pci_exp_rxn,
		
		input                       pcie_clk_p,
		input                       pcie_clk_n,
		input		    	  		pcie_rst_n,

		input                                sys_rst,   // System reset
   
   output nand0Cle,
	output nand0Ale,
	output nand0Clk_We_n,
	output nand0Wr_Re_n,
	output nand0Wp_n,
	output [7:0] nand0Ce_n,
	input [7:0] nand0Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand0DQX,
	inout nand0DQS,
	
	output nand1Cle,
	output nand1Ale,
	output nand1Clk_We_n,
	output nand1Wr_Re_n,
	output nand1Wp_n,
	output [7:0] nand1Ce_n,
	input [7:0] nand1Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand1DQX,
	inout nand1DQS,
	
	output nand2Cle,
	output nand2Ale,
	output nand2Clk_We_n,
	output nand2Wr_Re_n,
	output nand2Wp_n,
	output [7:0] nand2Ce_n,
	input [7:0] nand2Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand2DQX,
	inout nand2DQS,
	
	output nand3Cle,
	output nand3Ale,
	output nand3Clk_We_n,
	output nand3Wr_Re_n,
	output nand3Wp_n,
	output [7:0] nand3Ce_n,
	input [7:0] nand3Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand3DQX,
	inout nand3DQS,
	
	output nand4Cle,
	output nand4Ale,
	output nand4Clk_We_n,
	output nand4Wr_Re_n,
	output nand4Wp_n,
	output [7:0] nand4Ce_n,
	input [7:0] nand4Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand4DQX,
	inout nand4DQS,
	
	output nand5Cle,
	output nand5Ale,
	output nand5Clk_We_n,
	output nand5Wr_Re_n,
	output nand5Wp_n,
	output [7:0] nand5Ce_n,
	input [7:0] nand5Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand5DQX,
	inout nand5DQS,
	
	output nand6Cle,
	output nand6Ale,
	output nand6Clk_We_n,
	output nand6Wr_Re_n,
	output nand6Wp_n,
	output [7:0] nand6Ce_n,
	input [7:0] nand6Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand6DQX,
	inout nand6DQS,
	
	output nand7Cle,
	output nand7Ale,
	output nand7Clk_We_n,
	output nand7Wr_Re_n,
	output nand7Wp_n,
	output [7:0] nand7Ce_n,
	input [7:0] nand7Rb_n,
	inout [FLASH_IO_WIDTH-1:0] nand7DQX,
	inout nand7DQS
   );
  // Add ML605 heartbeat counter and LED assignments
  reg   [28:0] led_counter;
	always @( posedge clk or posedge rst)
  	begin
    	if (rst)
      	led_counter <= 0;
    	else
      	led_counter <= led_counter + 1;
  	end
	assign heartbeat = led_counter[27];

  function integer STR_TO_INT;
    input [7:0] in;
    begin
      if(in == "8")
        STR_TO_INT = 8;
      else if(in == "4")
        STR_TO_INT = 4;
      else
        STR_TO_INT = 0;
    end
  endfunction

  localparam SYSCLK_PERIOD          = tCK * nCK_PER_CLK;

  localparam DATA_WIDTH          = 64;
  localparam PAYLOAD_WIDTH       = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
  localparam BURST_LENGTH        = STR_TO_INT(BURST_MODE);
  localparam APP_DATA_WIDTH      = PAYLOAD_WIDTH * 4;
  localparam APP_MASK_WIDTH      = APP_DATA_WIDTH / 8;

  wire                                clk_ref_p;
  wire                                clk_ref_n;
  wire                                sys_clk_p;
  wire                                sys_clk_n;
  wire                                mmcm_clk;
  wire                                iodelay_ctrl_rdy;
      
  (* KEEP = "TRUE" *) wire            sda_i;
  (* KEEP = "TRUE" *) wire            scl_i;
  wire                                rst;
  wire                                clk;
  wire                                clk_mem;
  wire                                clk_rd_base;
  wire                                pd_PSDONE;
  wire                                pd_PSEN;
  wire                                pd_PSINCDEC;
  wire  [(BM_CNT_WIDTH)-1:0]          bank_mach_next;
  wire                                ddr3_parity;
  wire                                app_hi_pri;
  wire [APP_MASK_WIDTH-1:0]           app_wdf_mask;
  wire [3:0]                          app_ecc_multiple_err_i;
  wire [47:0]                         traffic_wr_data_counts;
  wire [47:0]                         traffic_rd_data_counts;
  wire [ADDR_WIDTH-1:0]               app_addr;
  wire [2:0]                          app_cmd;
  wire                                app_en;
  wire                                app_sz;
  wire                                app_rdy;
  wire [APP_DATA_WIDTH-1:0]           app_rd_data;
  wire                                app_rd_data_valid;
  wire [APP_DATA_WIDTH-1:0]           app_wdf_data;
  wire                                app_wdf_end;
  wire                                app_wdf_rdy;
  wire                                app_wdf_wren;
  
  
  wire fifo_pcie_clk;
	
	//pcie2ftl data fifo
	//
	//wire [COMMAND_WIDTH-1:0]pcie_data_rec_fifo_in;// input [127 : 0] din
	//wire pcie_data_rec_fifo_in_en; // input wr_en
	wire pcie_data_rec_fifo_out_en; // input rd_en
	wire [DRAM_IO_WIDTH-1:0]pcie_data_rec_fifo_out; // output [255 : 0] dout
	wire pcie_data_rec_fifo_prog_full; // output full
	//wire pcie_data_rec_fifo_out_full;
	//wire pcie_data_rec_fifo_out_almost_full;
	wire RX_data_fifo_full;
	wire RX_data_fifo_almost_full;
	wire RX_data_fifo_wr_en;
	wire [COMMAND_WIDTH-1:0] RX_data_fifo_data;
	wire RX_data_fifo_av = !pcie_data_rec_fifo_prog_full;
	
	//pcie2ftl command fifo
	//
	//wire [COMMAND_WIDTH-1:0]pcie_command_rec_fifo_in; // input [127 : 0] din
	//wire pcie_command_rec_fifo_in_en; // input wr_en
	wire pcie_command_rec_fifo_out_en; // input rd_en
	wire [COMMAND_WIDTH-1:0]pcie_command_rec_fifo_out; // output [127 : 0] dout
	//wire pcie_command_rec_fifo_out_full; // output full
	//wire pcie_command_rec_fifo_out_almost_full;
	wire pcie_command_rec_fifo_empty_or_not; // output empty
	wire CMGFTL_cmd_fifo_full;
	wire CMGFTL_cmd_fifo_almost_full;
	wire CMGFTL_cmd_fifo_wr_en;
	wire [COMMAND_WIDTH-1:0] CMGFTL_cmd_fifo_data;
	
	//ftl2pcie data fifo
	//
	wire [DRAM_IO_WIDTH-1:0]pcie_data_send_fifo_in; // input [255 : 0] din
	wire pcie_data_send_fifo_in_en; // input wr_en
	//wire [COMMAND_WIDTH-1:0]pcie_data_send_fifo_out; // input rd_en
	//wire pcie_data_send_fifo_out_en; // output [127 : 0] dout
	//wire pcie_data_send_fifo_out_empty;
	//wire pcie_data_send_fifo_out_almost_empty;
	wire pcie_data_send_fifo_out_prog_full;
	wire TX_data_fifo_empty;
	wire TX_data_fifo_almost_empty;
	wire TX_data_fifo_rd_en;
	wire [COMMAND_WIDTH-1:0] TX_data_fifo_data;
	
	//ftl2pcie cmd fifo
	//
	wire [COMMAND_WIDTH-1:0]pcie_command_send_fifo_in; // input [127 : 0] din
	wire pcie_command_send_fifo_in_en; // input wr_en
	//wire [COMMAND_WIDTH-1:0]pcie_command_send_fifo_out; // input rd_en
	//wire pcie_command_send_fifo_out_en; // output [127 : 0] dout
	wire pcie_command_send_fifo_full_or_not; // output full
	//wire pcie_command_send_fifo_out_empty;
	//wire pcie_command_send_fifo_out_almost_empty;	
	wire FTLCMG_cmd_fifo_empty;
	wire FTLCMG_cmd_fifo_almost_empty;
	wire FTLCMG_cmd_fifo_rd_en;
	wire [COMMAND_WIDTH-1:0] FTLCMG_cmd_fifo_data;
  //***************************************************************************


  assign app_hi_pri = 1'b0;
  //assign app_wdf_mask = {APP_MASK_WIDTH{1'b0}};

  assign manual_clear_error     = 1'b0;
      
  MUXCY scl_inst
    (
     .O  (scl),
     .CI (scl_i),
     .DI (1'b0),
     .S  (1'b1)
     );

  MUXCY sda_inst
    (
     .O  (sda),
     .CI (sda_i),
     .DI (1'b0),
     .S  (1'b1)
     );
  assign clk_ref_p = 1'b0;
  assign clk_ref_n = 1'b0;
  assign sys_clk_p = 1'b0;
  assign sys_clk_n = 1'b0;



  clk_wiz_v3_6 clknetwork
   (// Clock in ports
    .CLK_IN1            (clk_ref),
    // Clock out ports
    .CLK_OUT1           (sys_clk_pll),
    .CLK_OUT2           (clk_ref_pll),
    // Status and control signals
    .LOCKED             (LOCKED));   
	clk_gen_83M clk_generaor_83M
   (// Clock in ports
    .CLK_IN1(sys_clk),      // IN
    // Clock out ports
    .CLK_OUT1(clk_83X2M),     // OUT
    .CLK_OUT2(clk_83M),     // OUT
    .CLK_OUT3(clk_83M_reverse),     // OUT
	//.CLKFB_IN(CLKFB),
	//.CLKFB_OUT(CLKFB),
    // Status and control signals
    .RESET(RESET),// IN
    .LOCKED(LOCKED));      // OUT  
  iodelay_ctrl #
    (
     .TCQ            (TCQ),
     .IODELAY_GRP    (IODELAY_GRP),
     .INPUT_CLK_TYPE (INPUT_CLK_TYPE),
     .RST_ACT_LOW    (RST_ACT_LOW)
     )
    u_iodelay_ctrl
      (
       .clk_ref_p        (clk_ref_p),
       .clk_ref_n        (clk_ref_n),
       .clk_ref          (clk_ref_pll),
       .sys_rst          (sys_rst),
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy)
       );
  clk_ibuf #
    (
     .INPUT_CLK_TYPE (INPUT_CLK_TYPE)
     )
    u_clk_ibuf
      (
       .sys_clk_p         (sys_clk_p),
       .sys_clk_n         (sys_clk_n),
       .sys_clk           (sys_clk_pll),
       .mmcm_clk          (mmcm_clk)
       );
  infrastructure #
    (
     .TCQ                (TCQ),
     .CLK_PERIOD         (SYSCLK_PERIOD),
     .nCK_PER_CLK        (nCK_PER_CLK),
     .MMCM_ADV_BANDWIDTH (MMCM_ADV_BANDWIDTH),
     .CLKFBOUT_MULT_F    (CLKFBOUT_MULT_F),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKOUT_DIVIDE      (CLKOUT_DIVIDE),
     .RST_ACT_LOW        (RST_ACT_LOW)
     )
    u_infrastructure
      (
       .clk_mem          (clk_mem),
       .clk              (clk),
       .clk_rd_base      (clk_rd_base),
       .rstdiv0          (rst),
       .mmcm_clk         (mmcm_clk),
       .sys_rst          (sys_rst),
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
       .PSDONE           (pd_PSDONE),
       .PSEN             (pd_PSEN),
       .PSINCDEC         (pd_PSINCDEC)
       );


  memc_ui_top #
  (
   .ADDR_CMD_MODE        (ADDR_CMD_MODE),
   .BANK_WIDTH           (BANK_WIDTH),
   .CK_WIDTH             (CK_WIDTH),
   .CKE_WIDTH            (CKE_WIDTH),
   .nCK_PER_CLK          (nCK_PER_CLK),
   .COL_WIDTH            (COL_WIDTH),
   .CS_WIDTH             (CS_WIDTH),
   .DM_WIDTH             (DM_WIDTH),
   .nCS_PER_RANK         (nCS_PER_RANK),
   .DEBUG_PORT           (DEBUG_PORT),
   .IODELAY_GRP          (IODELAY_GRP),
   .DQ_WIDTH             (DQ_WIDTH),
   .DQS_WIDTH            (DQS_WIDTH),
   .DQS_CNT_WIDTH        (DQS_CNT_WIDTH),
   .ORDERING             (ORDERING),
   .OUTPUT_DRV           (OUTPUT_DRV),
   .PHASE_DETECT         (PHASE_DETECT),
   .RANK_WIDTH           (RANK_WIDTH),
   .REFCLK_FREQ          (REFCLK_FREQ),
   .REG_CTRL             (REG_CTRL),
   .ROW_WIDTH            (ROW_WIDTH),
   .RTT_NOM              (RTT_NOM),
   .RTT_WR               (RTT_WR),
   .SIM_BYPASS_INIT_CAL  (SIM_BYPASS_INIT_CAL),
   .WRLVL                (WRLVL),
   .nDQS_COL0            (nDQS_COL0),
   .nDQS_COL1            (nDQS_COL1),
   .nDQS_COL2            (nDQS_COL2),
   .nDQS_COL3            (nDQS_COL3),
   .DQS_LOC_COL0         (DQS_LOC_COL0),
   .DQS_LOC_COL1         (DQS_LOC_COL1),
   .DQS_LOC_COL2         (DQS_LOC_COL2),
   .DQS_LOC_COL3         (DQS_LOC_COL3),
   .tPRDI                (tPRDI),
   .tREFI                (tREFI),
   .tZQI                 (tZQI),
   .BURST_MODE           (BURST_MODE),
   .BM_CNT_WIDTH         (BM_CNT_WIDTH),
   .tCK                  (tCK),
   .ADDR_WIDTH           (ADDR_WIDTH),
   .TCQ                  (TCQ),
   .ECC                  (ECC),
   .ECC_TEST             (ECC_TEST),
   .PAYLOAD_WIDTH        (PAYLOAD_WIDTH),
   .APP_DATA_WIDTH       (APP_DATA_WIDTH),
   .APP_MASK_WIDTH       (APP_MASK_WIDTH)
   )
  u_memc_ui_top
  (
   .clk                              (clk),
   .clk_mem                          (clk_mem),
   .clk_rd_base                      (clk_rd_base),
   .rst                              (rst),
   .ddr_addr                         (ddr3_addr),
   .ddr_ba                           (ddr3_ba),
   .ddr_cas_n                        (ddr3_cas_n),
   .ddr_ck_n                         (ddr3_ck_n),
   .ddr_ck                           (ddr3_ck_p),
   .ddr_cke                          (ddr3_cke),
   .ddr_cs_n                         (ddr3_cs_n),
   .ddr_dm                           (ddr3_dm),
   .ddr_odt                          (ddr3_odt),
   .ddr_ras_n                        (ddr3_ras_n),
   .ddr_reset_n                      (ddr3_reset_n),
   .ddr_parity                       (ddr3_parity),
   .ddr_we_n                         (ddr3_we_n),
   .ddr_dq                           (ddr3_dq),
   .ddr_dqs_n                        (ddr3_dqs_n),
   .ddr_dqs                          (ddr3_dqs_p),
   .pd_PSEN                          (pd_PSEN),
   .pd_PSINCDEC                      (pd_PSINCDEC),
   .pd_PSDONE                        (pd_PSDONE),
   .phy_init_done                    (phy_init_done),
   .bank_mach_next                   (bank_mach_next),
   .app_ecc_multiple_err             (app_ecc_multiple_err_i),
   .app_rd_data                      (app_rd_data),
   .app_rd_data_end                  (app_rd_data_end),
   .app_rd_data_valid                (app_rd_data_valid),
   .app_rdy                          (app_rdy),
   .app_wdf_rdy                      (app_wdf_rdy),
   .app_addr                         (app_addr),
   .app_cmd                          (app_cmd),
   .app_en                           (app_en),
   .app_hi_pri                       (app_hi_pri),
   .app_sz                           (1'b1),
   .app_wdf_data                     (app_wdf_data),
   .app_wdf_end                      (app_wdf_end),
   .app_wdf_mask                     (app_wdf_mask),
   .app_wdf_wren                     (app_wdf_wren),
   .app_correct_en                   (1'b1),
   .dbg_wr_dqs_tap_set               (dbg_wr_dqs_tap_set),
   .dbg_wr_dq_tap_set                (dbg_wr_dq_tap_set),
   .dbg_wr_tap_set_en                (dbg_wr_tap_set_en),
   .dbg_wrlvl_start                  (dbg_wrlvl_start),
   .dbg_wrlvl_done                   (dbg_wrlvl_done),
   .dbg_wrlvl_err                    (dbg_wrlvl_err),
   .dbg_wl_dqs_inverted              (dbg_wl_dqs_inverted),
   .dbg_wr_calib_clk_delay           (dbg_wr_calib_clk_delay),
   .dbg_wl_odelay_dqs_tap_cnt        (dbg_wl_odelay_dqs_tap_cnt),
   .dbg_wl_odelay_dq_tap_cnt         (dbg_wl_odelay_dq_tap_cnt),
   .dbg_rdlvl_start                  (dbg_rdlvl_start),
   .dbg_rdlvl_done                   (dbg_rdlvl_done),
   .dbg_rdlvl_err                    (dbg_rdlvl_err),
   .dbg_cpt_tap_cnt                  (dbg_cpt_tap_cnt),
   .dbg_cpt_first_edge_cnt           (dbg_cpt_first_edge_cnt),
   .dbg_cpt_second_edge_cnt          (dbg_cpt_second_edge_cnt),
   .dbg_rd_bitslip_cnt               (dbg_rd_bitslip_cnt),
   .dbg_rd_clkdly_cnt                (dbg_rd_clkdly_cnt),
   .dbg_rd_active_dly                (dbg_rd_active_dly),
   .dbg_pd_off                       (dbg_pd_off),
   .dbg_pd_maintain_off              (dbg_pd_maintain_off),
   .dbg_pd_maintain_0_only           (dbg_pd_maintain_0_only),
   .dbg_inc_cpt                      (dbg_inc_cpt),
   .dbg_dec_cpt                      (dbg_dec_cpt),
   .dbg_inc_rd_dqs                   (dbg_inc_rd_dqs),
   .dbg_dec_rd_dqs                   (dbg_dec_rd_dqs),
   .dbg_inc_dec_sel                  (dbg_inc_dec_sel),
   .dbg_inc_rd_fps                   (dbg_inc_rd_fps),
   .dbg_dec_rd_fps                   (dbg_dec_rd_fps),
   .dbg_dqs_tap_cnt                  (dbg_dqs_tap_cnt),
   .dbg_dq_tap_cnt                   (dbg_dq_tap_cnt),
   .dbg_rddata                       (dbg_rddata)
   );
   
	/*ftl_top ftl_top_instance(
		.reset(rst),
		.clk(clk),
		.phy_init_done(phy_init_done),
		//dram
		.dram_ready_i(app_rdy),
		.rd_data_valid_i(app_rd_data_valid),
		.data_from_dram_i(app_rd_data),							
		.dram_en_o(app_en),
		.dram_rd_wr_o(app_cmd[0]),
		.addr_to_dram_o(app_addr),
		.data_to_dram_o(app_wdf_data),
		.dram_data_mask_o(app_wdf_mask),
		.data_to_dram_en(app_wdf_wren), 
		.data_to_dram_end(app_wdf_end),
		.data_to_dram_ready(app_wdf_rdy)
		//.initial_dram_done(initial_dram_done)
    );*/
	
	pcie_2_0_ep pcie_module(
	// system interface
		.sys_clk_p(pcie_clk_p),
		.sys_clk_n(pcie_clk_n),
		.sys_reset_n(pcie_rst_n),
	
	//pcie tx and rx bus
		.pci_exp_txp(pci_exp_txp),
		.pci_exp_txn(pci_exp_txn),
		.pci_exp_rxp(pci_exp_rxp),
		.pci_exp_rxn(pci_exp_rxn),
		
	//pcie-ftl-fifo interface 
	//fifo clk from pcie
		.fifo_clk(fifo_pcie_clk),
	
	//ftl2pcie cmd fifo
		//.cmd_fifo_empty_i(pcie_command_send_fifo_out_empty),
		//.cmd_fifo_almost_empty_i(pcie_command_send_fifo_out_almost_empty),
		//.cmd_fifo_rd_en_o(pcie_command_send_fifo_out_en),
		//.cmd_fifo_dout_i(pcie_command_send_fifo_out),
		
		.FTLCMG_cmd_fifo_empty_i(FTLCMG_cmd_fifo_empty),
		.FTLCMG_cmd_fifo_almost_empty_i(FTLCMG_cmd_fifo_almost_empty),
		.FTLCMG_cmd_fifo_rd_en_o(FTLCMG_cmd_fifo_rd_en),
		.FTLCMG_cmd_fifo_data_i(FTLCMG_cmd_fifo_data),
	//ftl2pcie data fifo
		//.data_fifo_empty_i(pcie_data_send_fifo_out_empty),
		//.data_fifo_almost_empty_i(pcie_data_send_fifo_out_almost_empty),
		//.data_fifo_rd_en_o(pcie_data_send_fifo_out_en),
		//.data_fifo_dout_i(pcie_data_send_fifo_out),
		.TX_data_fifo_empty_i(TX_data_fifo_empty),
		.TX_data_fifo_almost_empty_i(TX_data_fifo_almost_empty),
		.TX_data_fifo_rd_en_o(TX_data_fifo_rd_en),
		.TX_data_fifo_data_i(TX_data_fifo_data),
	//pcie2ftl cmd fifo
		//.cmd_fifo_full_i(pcie_command_rec_fifo_out_full),
		//.cmd_fifo_almost_full_i(pcie_command_rec_fifo_out_almost_full),
		//.cmd_fifo_wr_en_o(pcie_command_rec_fifo_in_en),
		//.cmd_fifo_din_o(pcie_command_rec_fifo_in),
		.CMGFTL_cmd_fifo_full_i(CMGFTL_cmd_fifo_full),
		.CMGFTL_cmd_fifo_almost_full_i(CMGFTL_cmd_fifo_almost_full),
		.CMGFTL_cmd_fifo_wr_en_o(CMGFTL_cmd_fifo_wr_en),
		.CMGFTL_cmd_fifo_data_o(CMGFTL_cmd_fifo_data),
		
	//pcie2ftl data fifo
		//.data_fifo_full_i(pcie_data_rec_fifo_out_full),
		//.data_fifo_almost_full_i(pcie_data_rec_fifo_out_almost_full),
		//.data_fifo_wr_en_o(pcie_data_rec_fifo_in_en),
		//.data_fifo_din_o(pcie_data_rec_fifo_in)
		.RX_data_fifo_full_i(RX_data_fifo_full),
		.RX_data_fifo_almost_full_i(RX_data_fifo_almost_full),
		.RX_data_fifo_wr_en_o(RX_data_fifo_wr_en),
		.RX_data_fifo_data_o(RX_data_fifo_data),
		.RX_data_fifo_av_i(RX_data_fifo_av)
	
	);	
	pcie_data_rec_fifo pcie2ftl_data_rec_fifo ( //data_fifo  write_depth 16384 read_depth 8192 
	  .rst(rst), // input rst
	  .wr_clk(fifo_pcie_clk), // input wr_clk
	  .rd_clk(clk), // input rd_clk
	  .din(RX_data_fifo_data), // input [127 : 0] din
	  .wr_en(RX_data_fifo_wr_en), // input wr_en
	  .rd_en(pcie_data_rec_fifo_out_en), // input rd_en
	  .dout(pcie_data_rec_fifo_out), // output [255 : 0] dout
	  .full(RX_data_fifo_full), // output full
	  .almost_full(RX_data_fifo_almost_full), // output almost_full
	  .empty(), // output empty
	  .almost_empty(), // output almost_empty
	  .rd_data_count(), // output [12 : 0] rd_data_count
	  .wr_data_count(), // output [13 : 0] wr_data_count
	  .prog_full(pcie_data_rec_fifo_prog_full) // output prog_full
	);	
	
	pcie_command_rec_fifo pcie2ftl_command_rec_fifo (//depth 64
	  .rst(rst), // input rst
	  .wr_clk(fifo_pcie_clk), // input wr_clk
	  .rd_clk(clk), // input rd_clk
	  .din(CMGFTL_cmd_fifo_data), // input [127 : 0] din
	  .wr_en(CMGFTL_cmd_fifo_wr_en), // input wr_en
	  .rd_en(pcie_command_rec_fifo_out_en), // input rd_en
	  .dout(pcie_command_rec_fifo_out), // output [127 : 0] dout
	  .full(CMGFTL_cmd_fifo_full), // output full
	  .almost_full(CMGFTL_cmd_fifo_almost_full), // output almost_full
	  .empty(pcie_command_rec_fifo_empty_or_not), // output empty
	  .almost_empty(), // output almost_empty
	  .rd_data_count(), // output [5 : 0] rd_data_count
	  .wr_data_count() // output [5 : 0] wr_data_count
	);

	
	pcie_data_send_fifo ftl2pcie_data_send_fifo (
	  .rst(rst), // input rst
	  .wr_clk(clk), // input wr_clk
	  .rd_clk(fifo_pcie_clk), // input rd_clk
	  .din(pcie_data_send_fifo_in), // input [255 : 0] din
	  .wr_en(pcie_data_send_fifo_in_en), // input wr_en
	  .rd_en(TX_data_fifo_rd_en), // input rd_en
	  .dout(TX_data_fifo_data), // output [127 : 0] dout
	  .full(), // output full
	  .almost_full(), // output almost_full
	  .empty(TX_data_fifo_empty), // output empty
	  .almost_empty(TX_data_fifo_almost_empty), // output almost_empty
	  .rd_data_count(), // output [13 : 0] rd_data_count
	  .wr_data_count(), // output [12 : 0] wr_data_count
	  .prog_full(pcie_data_send_fifo_out_prog_full) // output prog_full
	);

	pcie_command_send_fifo ftl2pcie_command_send_fifo (//depth 16
	  .rst(rst), // input rst
	  .wr_clk(clk), // input wr_clk
	  .rd_clk(fifo_pcie_clk), // input rd_clk
	  .din(pcie_command_send_fifo_in), // input [127 : 0] din
	  .wr_en(pcie_command_send_fifo_in_en), // input wr_en
	  .rd_en(FTLCMG_cmd_fifo_rd_en), // input rd_en
	  .dout(FTLCMG_cmd_fifo_data), // output [127 : 0] dout
	  .full(pcie_command_send_fifo_full_or_not), // output full
	  .almost_full(), // output almost_full
	  .empty(FTLCMG_cmd_fifo_empty), // output empty
	  .almost_empty(FTLCMG_cmd_fifo_almost_empty), // output almost_empty
	  .rd_data_count(), // output [3 : 0] rd_data_count
	  .wr_data_count() // output [3: 0] wr_data_count
	);

	ftl_top ftl_top_instance(
		.reset(rst),
		.clk(clk),
		.clk_83X2M(clk_83X2M),     
		.clk_83M(clk_83M),     
		.clk_83M_reverse(clk_83M_reverse),     
		.phy_init_done(phy_init_done),
		//pcie 
		.pcie_data_rec_fifo_out(pcie_data_rec_fifo_out),
		.pcie_data_rec_fifo_out_en(pcie_data_rec_fifo_out_en),
		.pcie_command_rec_fifo_out(pcie_command_rec_fifo_out),
		.pcie_command_rec_fifo_empty_or_not(pcie_command_rec_fifo_empty_or_not),
		.pcie_command_rec_fifo_out_en(pcie_command_rec_fifo_out_en),
		.pcie_data_send_fifo_in(pcie_data_send_fifo_in),
		.pcie_data_send_fifo_in_en(pcie_data_send_fifo_in_en),
		.pcie_data_send_fifo_out_prog_full(pcie_data_send_fifo_out_prog_full),
		.pcie_command_send_fifo_full_or_not(pcie_command_send_fifo_full_or_not),
		.pcie_command_send_fifo_in(pcie_command_send_fifo_in),
		.pcie_command_send_fifo_in_en(pcie_command_send_fifo_in_en),

		//dram
		.dram_ready(app_rdy),
		.rd_data_valid(app_rd_data_valid),
		.data_from_dram(app_rd_data),							
		.dram_en(app_en),
		.dram_read_or_write(app_cmd[0]),
		.addr_to_dram(app_addr),
		.data_to_dram(app_wdf_data),
		.dram_data_mask(app_wdf_mask),
		.data_to_dram_en(app_wdf_wren), 
		.data_to_dram_end(app_wdf_end),
		.data_to_dram_ready(app_wdf_rdy),
		.initial_dram_done(initial_dram_done),
	
		//flash_controller
		.nand0Cle(nand0Cle),
		.nand0Ale(nand0Ale),
		.nand0Clk_We_n(nand0Clk_We_n),
		.nand0Wr_Re_n(nand0Wr_Re_n),
		.nand0Wp_n(nand0Wp_n),
		.nand0Ce_n(nand0Ce_n),
		.nand0Rb_n(nand0Rb_n),
		.nand0DQX(nand0DQX),
		.nand0DQS(nand0DQS),
		
		.nand1Cle(nand1Cle),
		.nand1Ale(nand1Ale),
		.nand1Clk_We_n(nand1Clk_We_n),
		.nand1Wr_Re_n(nand1Wr_Re_n),
		.nand1Wp_n(nand1Wp_n),
		.nand1Ce_n(nand1Ce_n),
		.nand1Rb_n(nand1Rb_n),
		.nand1DQX(nand1DQX),
		.nand1DQS(nand1DQS),
		
		.nand2Cle(nand2Cle),
		.nand2Ale(nand2Ale),
		.nand2Clk_We_n(nand2Clk_We_n),
		.nand2Wr_Re_n(nand2Wr_Re_n),
		.nand2Wp_n(nand2Wp_n),
		.nand2Ce_n(nand2Ce_n),
		.nand2Rb_n(nand2Rb_n),
		.nand2DQX(nand2DQX),
		.nand2DQS(nand2DQS),
		
		.nand3Cle(nand3Cle),
		.nand3Ale(nand3Ale),
		.nand3Clk_We_n(nand3Clk_We_n),
		.nand3Wr_Re_n(nand3Wr_Re_n),
		.nand3Wp_n(nand3Wp_n),
		.nand3Ce_n(nand3Ce_n),
		.nand3Rb_n(nand3Rb_n),
		.nand3DQX(nand3DQX),
		.nand3DQS(nand3DQS),
		
		.nand4Cle(nand4Cle),
		.nand4Ale(nand4Ale),
		.nand4Clk_We_n(nand4Clk_We_n),
		.nand4Wr_Re_n(nand4Wr_Re_n),
		.nand4Wp_n(nand4Wp_n),
		.nand4Ce_n(nand4Ce_n),
		.nand4Rb_n(nand4Rb_n),
		.nand4DQX(nand4DQX),
		.nand4DQS(nand4DQS),
		
		.nand5Cle(nand5Cle),
		.nand5Ale(nand5Ale),
		.nand5Clk_We_n(nand5Clk_We_n),
		.nand5Wr_Re_n(nand5Wr_Re_n),
		.nand5Wp_n(nand5Wp_n),
		.nand5Ce_n(nand5Ce_n),
		.nand5Rb_n(nand5Rb_n),
		.nand5DQX(nand5DQX),
		.nand5DQS(nand5DQS),
		
		.nand6Cle(nand6Cle),
		.nand6Ale(nand6Ale),
		.nand6Clk_We_n(nand6Clk_We_n),
		.nand6Wr_Re_n(nand6Wr_Re_n),
		.nand6Wp_n(nand6Wp_n),
		.nand6Ce_n(nand6Ce_n),
		.nand6Rb_n(nand6Rb_n),
		.nand6DQX(nand6DQX),
		.nand6DQS(nand6DQS),
		
		.nand7Cle(nand7Cle),
		.nand7Ale(nand7Ale),
		.nand7Clk_We_n(nand7Clk_We_n),
		.nand7Wr_Re_n(nand7Wr_Re_n),
		.nand7Wp_n(nand7Wp_n),
		.nand7Ce_n(nand7Ce_n),
		.nand7Rb_n(nand7Rb_n),
		.nand7DQX(nand7DQX),
		.nand7DQS(nand7DQS)
    );
	
	

endmodule
