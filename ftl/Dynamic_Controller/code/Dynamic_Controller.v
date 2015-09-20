`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:40:03 12/18/2014 
// Design Name: 
// Module Name:    Dynamic_Controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Dynamic_Controller( //27 Ports
clk_200M,rst_n,clk_83X2M,clk_83M,clk_83M_reverse,
Cmd_In_En,Cmd_In,Finished_Cmd_Out_En,Data_In_En,Data_In,Cmd_Available,Finished_Cmd_FIFO_Empty,Finished_Cmd_Out,ControllerIdle,Data_2_host_en,Data_2_host,
Cle,Ale,Clk_We_n,Wr_Re_n,Wp_n,Ce_n,Rb_n,DQX,DQS);

`include"Dynamic_Controller_Parameters.vh"

//------------------------------------
// Ports declaration and assignment
//------------------------------------	
   input clk_200M;
	input rst_n;
	input clk_83X2M;
	input clk_83M;
	input clk_83M_reverse;
	//Ports with Host.
	input Cmd_In_En;
	input [127:0] Cmd_In;
	input Finished_Cmd_Out_En;
	input Data_In_En;
	input [255:0] Data_In;
	output  Cmd_Available;
	output  Finished_Cmd_FIFO_Empty;
	output  [127:0] Finished_Cmd_Out;
	output ControllerIdle;
    input Data_2_host_en;
   output [255:0] Data_2_host;
	//Ports with chips
	output  Cle;
	output  Ale;
	output  Clk_We_n;
	output  Wr_Re_n;
	output Wp_n;
	
	output  [7:0] Ce_n;
	input [7:0] Rb_n;

	inout [7:0] DQX;
	inout DQS;
///////////////////////////////////////////////////////////////////////

//wire CE_L_w;
//wire RB_L_w;


//Connection between Scheduler module and SynchronizeClkDomains.
wire  controller_rb_l_o_w;
wire  read_data_stall_o_w;
wire [2:0] Target_Addr_w;
wire [ADDR_WIDTH-4:0] page_offset_addr_w;
wire Operation_en_w;
wire [2:0] Operation_Type_w;
//Connection between SynchronizeClkDomains and flash_controller.
wire  controller_rb_l_w;
wire  read_data_stall_w;
wire [ADDR_WIDTH-4:0] page_offset_addr_o_w;
wire Operation_en_o_w;
wire [2:0] Operation_Type_o_w;
wire [2:0] Target_Addr_o_w;

//Connection between DDR_Interface module and flash_controller.
wire during_read_data_w;
wire clear_fifo_w;
wire read_en_w;
wire [15:0] data_into_fpga_w;
wire empty_w;
wire [7:0] data_outof_fpga_w;
wire DQS_Start_w;
//Connection between Cmd_Analysis module and Scheduler module.
wire         Set_Empty_w;
wire  [3:0]  Set_Empty_ID_w;
wire         FIFO_rd_en_w;
wire  [2:0]  FIFO_addr_w;
wire         FIFO_empty_w;
wire [127:0] Cmd_Out_w;

wire  [3:0]  RAM_Unit_ID_w;
wire Finished_cmd_wr_en_w;
wire Finished_cmd_FIFO_full_w;
wire Chips_Ready_w;
//Connection between flash_controller module and Cmd_Analysis module.
wire         Rd_RAM_Data_en_w;
wire [7:0]   Data_Out_w; 
wire DataFromFlash_en_w;
wire [15:0] DataFromFlash_w;
wire RD_data_FIFO_full_w;
Cmd_Analysis cmd_analysis_inst(
                                         .clk(clk_200M),
										 .fifo_rd_clk(clk_83X2M),
										 .clk_83M(clk_83M),
										 .rst_n(rst_n),
										 //Interface with Host
                                         .Cmd_In_En(Cmd_In_En),
										 .Cmd_In(Cmd_In),
										 .Finished_Cmd_FIFO_Empty(Finished_Cmd_FIFO_Empty),
										 .Finished_Cmd_Out_En(Finished_Cmd_Out_En),
										 .Finished_Cmd_Out(Finished_Cmd_Out),
										 .Data_In_En(Data_In_En),
										 .Data_In(Data_In),
										 .Cmd_Available(Cmd_Available),
										 .Data_2_host_en(Data_2_host_en),
										 .Data_2_host(Data_2_host),
										 .ControllerIdle(ControllerIdle),
										 //Interface with Scheduler module.
                                         .Set_Empty     (Set_Empty_w),
										 .Set_Empty_ID  (Set_Empty_ID_w),
										 .FIFO_rd_en    (FIFO_rd_en_w),
										 .FIFO_addr     (FIFO_addr_w),
										 .FIFO_empty    (FIFO_empty_w),
										 .Cmd_Out       (Cmd_Out_w),
										 .RAM_Unit_ID   (RAM_Unit_ID_w),
										 .Finished_cmd_wr_en(Finished_cmd_wr_en_w),
										 .Finished_cmd_FIFO_full(Finished_cmd_FIFO_full_w),
										 .Chips_Ready(Chips_Ready_w),
										 //Interface with flash_controller module.
										 .Rd_RAM_Data_en(Rd_RAM_Data_en_w),
										 .Data_Out      (Data_Out_w),
										 .DataFromFlash_en(DataFromFlash_en_w),
										 .DataFromFlash(DataFromFlash_w),
										 .RD_data_FIFO_full(RD_data_FIFO_full_w)
                             );

Scheduler scheduler_inst(.clk(clk_200M),
                         .rst_n(rst_n),
						 //Interface with Cmd_Analysis module.
                         .Set_Empty     (Set_Empty_w),
						 .Set_Empty_ID  (Set_Empty_ID_w),
						 .FIFO_rd_en    (FIFO_rd_en_w),
						 .FIFO_addr     (FIFO_addr_w),
						 .FIFO_empty    (FIFO_empty_w),
						 .Cmd_Out       (Cmd_Out_w),
						 .RAM_Unit_ID   (RAM_Unit_ID_w),
						 .Finished_cmd_wr_en(Finished_cmd_wr_en_w),
						 .Finished_cmd_FIFO_full(Finished_cmd_FIFO_full_w),
						 .Chips_Ready(Chips_Ready_w),
                          //Ports with SynchronizeClkDomains module.
						 .Target_Addr       (Target_Addr_w),
						 .Operation_en(Operation_en_w),
						 .Operation_Type    (Operation_Type_w),
						 .page_offset_addr  (page_offset_addr_w),
						 .controller_rb_l   (controller_rb_l_o_w),	
                         .read_data_stall(read_data_stall_o_w),						 
						 //Port with  Target_Selection module
						 .RB_L              (Rb_n)
    );

SynchronizeClkDomains sync_clkdomains_inst(
                                           .clk_200M(clk_200M),
										   .clk_83M(clk_83M),
										   .rst_n(rst_n),
                                           //From flash controller module to Scheduler module
                                           .controller_rb_l(controller_rb_l_w),
										   .controller_rb_l_o(controller_rb_l_o_w),
										   .read_data_stall(read_data_stall_w),
										   .read_data_stall_o(read_data_stall_o_w),
                                           //From Scheduler module to flash controller module
                                           .Target_Addr(Target_Addr_w),  
										   .page_offset_addr(page_offset_addr_w),
                                           .Operation_en(Operation_en_w),										   
										   .Operation_Type(Operation_Type_w),  
                                           .Target_Addr_o(Target_Addr_o_w),
										   .page_offset_addr_o(page_offset_addr_o_w),
										   .Operation_en_o(Operation_en_o_w),
										   .Operation_Type_o(Operation_Type_o_w)
                                          );
flash_controller flash_ctrl_inst(
                                 .clk_data_transfer(clk_83X2M),
								 .clk_83M(clk_83M),
								 .clk_83M_reverse(clk_83M_reverse),
								 .rst(rst_n),
                                //Ports with SynchronizeClkDomains module.
								 .Target_Addr(Target_Addr_o_w),
								 .Operation_en(Operation_en_o_w),
								 .Operation_Type    (Operation_Type_o_w),
								 .page_offset_addr  (page_offset_addr_o_w),
								 .controller_rb_l   (controller_rb_l_w),
								 .read_data_stall(read_data_stall_w),
								 //Ports with Cmd_Analysis module.
								 .data_from_host    (Data_Out_w),
								 .data_to_flash_en  (Rd_RAM_Data_en_w),
								 .RD_data_FIFO_full(RD_data_FIFO_full_w),
								 .data_from_flash   (DataFromFlash_w),
								 .data_from_flash_en(DataFromFlash_en_w),
								 //Ports with MUX2_1
								// .SyncActive(SyncActive_w),
								// .reset_flag(reset_flag_w),
								 //Ports With DDR_Interface module 
                                 .DQX_In(data_into_fpga_w),
								 .flash_data_fifo_empty(empty_w),
								 .rd_flash_datafifo_en(read_en_w),
								 .clear_flash_datafifo(clear_fifo_w),
								 .during_read_data(during_read_data_w),
								 .DQX_Out(data_outof_fpga_w),
								 .DQS_Start(DQS_Start_w),
								 //Ports with Chips
                                 .RB_L(Rb_n),
								 .CE_L(Ce_n),
								 .CLE_H(Cle),
								 .ALE_H(Ale),
								 .WP_L(Wp_n),
								 .WE_Lorclk(Clk_We_n),
								 .RE_LorWR_L(Wr_Re_n)
	                           );
//Connection OK
DDR_Interface DDR_interface_inst(.clk(clk_200M),
                                 .fifo_rd_clk(clk_83M),
								 .clk_83M_reverse(clk_83M_reverse),
								 .rst_n(rst_n),
								 .during_read_data(during_read_data_w),
								 //DDR data into fpga
								 .clear_fifo(clear_fifo_w),//active high
								 .rd_en(read_en_w),
								 .data_into_fpga(data_into_fpga_w),
								 .empty(empty_w),
								 //DDR data out of fpga
								 .data_outof_fpga(data_outof_fpga_w),
								 .DQS_Start(DQS_Start_w),
								 //pins
								 .DQS(DQS),
								 .DQX(DQX)
                         );
/*
MUX2_1 mux2_1_inst(
                   .address(),
                   .a_1(Target_Addr_o_w),
                   .a_0(reset_flag_w),
                   .b_out(Target_Address_w)
                 );
				 */
// select a target to operate. 
/*
Target_Selection target_selection_inst(
                                       .Target_Addr(Target_Address_w),
                                       .CE_L(CE_L_w),
                                       .RB_L(RB_L_w),
                                       
                                       .CE_L0(Ce_n[0]),
                                       .CE_L1(Ce_n[1]),
                                       .CE_L2(Ce_n[2]),
                                       .CE_L3(Ce_n[3]),
                                       .CE_L4(Ce_n[4]),
                                       .CE_L5(Ce_n[5]),
                                       .CE_L6(Ce_n[6]),
                                       .CE_L7(Ce_n[7]),
                                       .RB_L0(Rb_n[0]),
                                       .RB_L1(Rb_n[1]),
                                       .RB_L2(Rb_n[2]),
                                       .RB_L3(Rb_n[3]),
                                       .RB_L4(Rb_n[4]),
                                       .RB_L5(Rb_n[5]),
                                       .RB_L6(Rb_n[6]),
                                       .RB_L7(Rb_n[7])
                                     );
									 */
endmodule