`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:28:27 11/21/2013 
// Design Name: 
// Module Name:    flash_controller 
// Project Name: 
// Target Devices: MT29F128G08AUCBB
// Tool versions: 
// Description: this flash_controller module is for the controlling of flash chip MT29F128G08AUCBB
//              with synchronous interface mode 4. Specifically, note that this module only involve half
//              targets which are shared the control signals(1th&3th or 2th&4th).  
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module flash_controller(
clk_data_transfer,clk_83M,clk_83M_reverse,rst,
Target_Addr,Operation_en,Operation_Type,page_offset_addr,controller_rb_l,read_data_stall,
data_from_host,data_to_flash_en,RD_data_FIFO_full,data_from_flash,data_from_flash_en,
DQX_In,flash_data_fifo_empty,rd_flash_datafifo_en,clear_flash_datafifo,during_read_data,DQX_Out,DQS_Start,
RB_L,CE_L,CLE_H,ALE_H,WP_L,WE_Lorclk,RE_LorWR_L
	);
	
`include"Dynamic_Controller_Parameters.vh"

//------------------------------------
// Ports declaration and assignment
//------------------------------------	
	 input clk_data_transfer;//166=83X2M
	 input clk_83M;//83M
	 input clk_83M_reverse;//83M reverse clk
     input rst;//低电平有效
    
	//Ports with SynchronizeClkDomains module.
	input [2:0] Target_Addr;
	input Operation_en;
	input [2:0] Operation_Type;
    input [ADDR_WIDTH-4:0] page_offset_addr;
    output reg controller_rb_l;
	output reg read_data_stall;
	//Ports with Cmd_Analysis module.
	input [7:0] data_from_host;
	output  reg  data_to_flash_en;
	
	input RD_data_FIFO_full;
	output [15:0] data_from_flash;
	output data_from_flash_en;
   
	 //Ports With DDR_Interface module 
	 input [15:0] DQX_In;
	 input      flash_data_fifo_empty;
	 output reg rd_flash_datafifo_en;
	 output reg clear_flash_datafifo;
   (*IOB="FALSE"*)output reg during_read_data;
	 output  reg [7:0] DQX_Out;
	// output reg DQS_Out;
	output reg DQS_Start;
     //Ports with Chips
	input [7:0] RB_L;
	output reg  [7:0] CE_L;
    output   CLE_H;
    output   ALE_H;
	output reg  WP_L;
	 //同步异步复用信号
	output  WE_Lorclk;//output WE_L(Asynchronous),clk(synchronous)
	output  RE_LorWR_L;//output RE_L（Asynchronous),W/R#(synchronous) 

//******Asynchornous interface reset all targets parameter definition
//reset the 4 targets
   parameter POWER_UP                  =  4'h0;
   parameter TARGET_SELECTION          =  4'h1;
	parameter PREPARE_RESET_TARGET		=	4'h2;
	parameter RESET_TARGET_COMMAND_1		=	4'h3;
	parameter RESET_WAIT_FOR_0				=	4'h4;
	parameter RESET_WAIT_FOR_1				=	4'h5;
		//end of reset the 4 targets
	parameter RESET_CHIP_END				=	4'h6;
	
	//Active synchronous interface
	parameter ACTIVESYN_CMD             =  4'h7;
	parameter ACTIVESYN_ADDR            =  4'h8;
	parameter ACTIVESYN_WAITTADL        =  4'h9;
	parameter ACTIVESYN_DATAMODE        =  4'ha;
	parameter ACTIVESYN_DATA00          =  4'hb;
	parameter ACTIVESYN_WAITRB0         =  4'hc;
	parameter ACTIVESYN_WAITRB1         =  4'hd;
	parameter ACTIVESYN_END             =  4'he;
	
	
	//define toggle states
	parameter TOGGLE_WAIT					=	'h0;
	parameter TOGGLECLR                 =  'h1;
	parameter TOGGLE_CE_EN              =  'h2;
	parameter TOGGLE1						   =	'h3;
	parameter TOGGLEADD                 =  'h4;
	parameter TOGGLE2						   =	'h5;
	
	parameter TOGGLE_DONE					=	'h6;
	
	
	
//**********************************Synchronous interfaces operation***//
  parameter SYN_WAIT4SYNACTIVE        		= 'h00;
	parameter SYN_STANDBY               	= 'h01;
	parameter SYN_BUSIDLE               	= 'h02;
	//read states                                   
	parameter READ_PAGE_COMMAND_1			= 'h03;//发送读页操作的第一个命令00h，一个周期	
	parameter READ_PAGE_ADDRESS_00		    = 'h04;//发送目标页地址的页内地址0000h，两个周期	
	parameter READ_PAGE_ADDRESS_3CYCLE	    = 'h05;//发送目标页地址的页偏移和块偏移，3个周期	
	parameter READ_PAGE_COMMAND_2			= 'h06;//发送读页操作的第二个命令30h，一个周期	
	parameter READ_PAGE_WAIT_FOR_0		    = 'h07;//等待flash的rb信号拉低		
		//write states
	parameter WRITE_PAGE_COMMAND_1			= 'h08;//									
	parameter WRITE_PAGE_ADDRESS_00			= 'h09;//									
	parameter WRITE_PAGE_ADDRESS_3CYCELE	= 'h0a;//		
    parameter WRITE_PAGE_DELAY70NS	   		= 'h0b;	
	parameter WRITE_PAGE_DATA				= 'h0c;//									
	parameter WRITE_PAGE_COMMAND_2			= 'h0d;//									
	parameter WRITE_PAGE_WAIT_FOR_0			= 'h0e;//	
	//erase states
	parameter ERASE_BLOCK_COMMAND_1			= 'h0f;//													
	parameter ERASE_BLOCK_ADDRESS_3CYCLES	= 'h10;//									
	parameter ERASE_BLOCK_COMMAND_2			= 'h11;//									
	parameter ERASE_BLOCK_WAIT_FOR_0		= 'h12;//	
	
	parameter READ_PAGE_WAIT                = 'h13;		
 	parameter READ_PAGE_DATA_OUT            = 'h14;							
	parameter READ_DELAY_TRHW120            = 'h15;
	parameter READ_PAGE_END					= 'h16;//读页操作完毕	

								

								


	
// Command and Address issure machine state definition
parameter CA_PREPARE        = 'd0;
parameter CA_WAIT           = 'd1;
parameter CA_ISSURE         = 'd2;
parameter CA_COMPLETE       = 'd3;
parameter CA_END            = 'd14;
//DDR dataout
parameter DDR_DATAOUT_EN    = 'd4;
parameter DDR_DATAOUT_PREPARE ='d5;
parameter DDR_MODE          = 'd6;
parameter DDR_DATAOUT_ALECLE_HOLD = 'd7;
parameter DDR_DATAOUT_END   = 'd8;


//DDR datain
parameter DDR_DATAIN_EN     = 'd9;
parameter DATAIN_PREPARE    = 'd10;
parameter DATAIN_MODE       = 'd11;
parameter DDR_DATAIN_LAST2  = 'd12;
parameter DDR_DATAIN_END    = 'd13;


	//define command
	parameter   RESET_COMMAND_1 = 'hff;
	parameter   SET_FEATURES    = 'hef;
	parameter   READ_MODE       = 'h00;
	parameter   READ_PAGE       = 'h30;
	parameter   PROGRAM_MODE    = 'h80;
	parameter   PROGRAM_PAGE    = 'h10;
	parameter   ERASE_BLOCK_CMD1 ='h60;
	parameter   ERASE_BLOCK_CMDQUEUE = 'hd1;
	parameter   ERASE_BLOCK_CMDEND   = 'hd0;	  


// Command and Address issure machine state regs declarison
reg [3:0]Syn_CA_currentstate,Syn_CA_nextstate;
reg [3:0]CA_Control_Signal0,CA_Control_Signal1,CA_Control_Signal2;
reg CA_Start;
reg CA_Done;

// DDR Dataout from chips
reg Dataout_Start;
reg Dataout_Done;

//DDR Datain
//reg DQS_Start;
reg Datain_Start;//start a writing operation
reg Datain_Done;
//reg Datain_ready;//implication for the FIFO outsides to allow datainput .
reg FIFO_Dataout_Valid;// synchoronization of FIFO dout and DQX_reg.

reg [7:0] Command;

reg Asyn_CE_L;
reg  Syn_CE_L;
reg Asyn_CLE_H;
reg  Syn_CLE_H;
reg Asyn_ALE_H;
reg  Syn_ALE_H;

reg Asyn_RB_L0;
reg Asyn_RB_L1;
reg  Syn_RB_L;
reg [7:0]Asyn_DQX_reg;
reg [7:0]Syn_DQX_reg;

reg [3:0] Asyn_current_state;
reg [3:0] Asyn_next_state;
reg [2:0] current_toggle_state;
reg [2:0] next_toggle_state;
reg [7:0] page_offset_addr_reg [3:0];
	
reg [4:0] flash_control_signals1;
reg [4:0] flash_control_signals2;
	
reg toggle_enable;
reg toggledone;
   
/**delay counter**/	
reg [7:0] delay_counter;
reg delay_counter_rst;
reg delay_counter_en;
	 
/****internal_counter0****/
reg [3:0] internal_counter0;//计数器
reg [1:0] internal_counter0_upto;//计数设置
reg internal_counter0_rst ;//计数清零
reg internal_counter0_en;
/****internal_counter2****/
reg  [1:0] internal_counter2;//计数器
reg  [1:0] internal_counter2_upto;//计数设置
reg internal_counter2_rst ;//计数清零
reg internal_counter2_en;
//Timer0
reg [7:0]Timer0;
reg Timer0En;
reg Timer0Start;
//Timer1
reg [12:0]Timer1;
reg Timer1En;
reg Timer1Start;
//Timer2
reg [7:0]Timer2;
reg Timer2En;
reg Timer2Start;

reg WE_L;
reg RE_L;
reg WR_L;	

reg SyncActive;

//**********Data output from NAND flash Chips*****************/
assign data_from_flash=DQX_In;
assign data_from_flash_en=rd_flash_datafifo_en;
	/************select output signals according to the output interface mode.***********************/

//reg  WE_Lorclk_bufin;
reg RE_LorWR_L_temp;
reg CLE_H_temp;
reg ALE_H_temp;
reg DQS_Start_temp;
reg WE_Lorclk_delay;
always @(*)
begin
  if(!rst)
    begin
	    RE_LorWR_L_temp=RE_L;
		CLE_H_temp =Asyn_CLE_H;
	    ALE_H_temp =Asyn_ALE_H;
		WE_Lorclk_delay  =WE_L;
	 end
  else if(1'b0==SyncActive)
       begin
	    RE_LorWR_L_temp=RE_L;
		CLE_H_temp =Asyn_CLE_H;
		ALE_H_temp =Asyn_ALE_H;
		WE_Lorclk_delay  =WE_L;
	    end
  else
    begin
	    RE_LorWR_L_temp=WR_L;
	    CLE_H_temp =Syn_CLE_H;
		ALE_H_temp =Syn_ALE_H;
		WE_Lorclk_delay  =clk_83M_reverse;
	 end
end

reg RE_LorWR_L_delay;
reg CLE_H_delay;
reg ALE_H_delay;
always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
    begin
      RE_LorWR_L_delay<=1'b0;
	  CLE_H_delay<=1'b0;
	  ALE_H_delay<=1'b0;
	end
  else
  begin
      RE_LorWR_L_delay<=RE_LorWR_L_temp;
	  CLE_H_delay<=CLE_H_temp;
	  ALE_H_delay<=ALE_H_temp;
  end
end
always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
    begin
	   DQS_Start<=1'b0;
	end
  else
  begin
     DQS_Start<= DQS_Start_temp;
  end
end

//delay 31 taps for RE_LorWR_L.
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IODELAYE1 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("O"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("FIXED"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(), // Input delay tap setting (0-32) 
	.ODELAY_TYPE("FIXED"), // "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.ODELAY_VALUE(31), // Output delay tap setting (0-32)
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IODELAYE1_inst_RE_LorWR_L (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(RE_LorWR_L), // 1-bit output - Delayed data output
	.C(), // 1-bit input - Clock input
	.CE(1'b0), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CLKIN(), // 1-bit input - Clock Access into the IODELAY
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(), // 1-bit input - Delay data input
	.INC(), // 1-bit input - Increment / Decrement tap delay
	.ODATAIN(RE_LorWR_L_delay), // 1-bit input - Data input for the output datapath from the device
	.RST(), // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	// ODELAY_VALUE tap. If no value is specified, the default is 0.
	.T() // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
	// tie low for output only.
	);
	
//delay 31 taps for CLE_H.
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IODELAYE1 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("O"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("FIXED"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(), // Input delay tap setting (0-32) 
	.ODELAY_TYPE("FIXED"), // "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.ODELAY_VALUE(31), // Output delay tap setting (0-32)
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IODELAYE1_inst_CLE_H(
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(CLE_H), // 1-bit output - Delayed data output
	.C(), // 1-bit input - Clock input
	.CE(1'b0), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CLKIN(), // 1-bit input - Clock Access into the IODELAY
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(), // 1-bit input - Delay data input
	.INC(), // 1-bit input - Increment / Decrement tap delay
	.ODATAIN(CLE_H_delay), // 1-bit input - Data input for the output datapath from the device
	.RST(), // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	// ODELAY_VALUE tap. If no value is specified, the default is 0.
	.T() // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
	// tie low for output only.
	);
	
	//delay 31 taps for ALE_H.
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IODELAYE1 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("O"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("FIXED"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(), // Input delay tap setting (0-32) 
	.ODELAY_TYPE("FIXED"), // "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.ODELAY_VALUE(31), // Output delay tap setting (0-32)
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IODELAYE1_inst_ALE_H (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(ALE_H), // 1-bit output - Delayed data output
	.C(), // 1-bit input - Clock input
	.CE(1'b0), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CLKIN(), // 1-bit input - Clock Access into the IODELAY
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(), // 1-bit input - Delay data input
	.INC(), // 1-bit input - Increment / Decrement tap delay
	.ODATAIN(ALE_H_delay), // 1-bit input - Data input for the output datapath from the device
	.RST(), // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	// ODELAY_VALUE tap. If no value is specified, the default is 0.
	.T() // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
	// tie low for output only.
	);
	
		//delay 31 taps for WE_Lorclk.
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IODELAYE1 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("O"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("FIXED"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(), // Input delay tap setting (0-32) 
	.ODELAY_TYPE("FIXED"), // "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.ODELAY_VALUE(23), // Output delay tap setting (0-32)
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IODELAYE1_inst_WE_Lorclk (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(WE_Lorclk), // 1-bit output - Delayed data output
	.C(), // 1-bit input - Clock input
	.CE(1'b0), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CLKIN(), // 1-bit input - Clock Access into the IODELAY
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(), // 1-bit input - Delay data input
	.INC(), // 1-bit input - Increment / Decrement tap delay
	.ODATAIN(WE_Lorclk_delay), // 1-bit input - Data input for the output datapath from the device
	.RST(), // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	// ODELAY_VALUE tap. If no value is specified, the default is 0.
	.T() // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
	// tie low for output only.
	);
/*
always@(*)
begin
  if(DQS_Start)
    DQS_Out=clk_83M_reverse;
  else
    DQS_Out=1'b0;
end
*/
/****************************FIFO controll signal output***************************
*****************************data_to_flash_en and data_from_flash_en**************/

//implication for the FIFO outsides for trigger data output, as to FIFO

//DQX bus output the FIFO,outside the controller, data to the chip.

//(*IOB="FORCE"*)reg  [7:0] DQX_Out;
reg [7:0] DQX_Out_reg ;
always @(*)
begin
    if(!rst)
    begin
     DQX_Out_reg=Asyn_DQX_reg;
	  //data_to_flash_en=1'b0;
    end 
  else if(1'b0==SyncActive)   
    begin
      DQX_Out_reg=Asyn_DQX_reg;
    end
  else
    begin
       if(FIFO_Dataout_Valid)
         begin
         DQX_Out_reg=data_from_host;
         end
       else
         begin
         DQX_Out_reg=Command;
         end
    end 

end
always @(posedge clk_data_transfer or negedge rst)
begin
    if(!rst)
    begin
     DQX_Out<=8'b0;
    end 
	 else
	 begin
	   DQX_Out<=DQX_Out_reg;
	 end
end
//*************************select the operation target from 0 to 7****************************//
always@(posedge clk_83M or negedge rst)
	begin
		if(!rst) 
		begin
		  Asyn_RB_L0<=1'b0;
		  Asyn_RB_L1<=1'b0;
		end
		else
		begin
		  Asyn_RB_L0<=|RB_L;
		  Asyn_RB_L1<=&RB_L;
		end
end

reg [7:0] CE_L_temp;
reg Syn_RB_L_temp;
always@(*)
begin
	if(!rst) 
	begin
		CE_L_temp=8'hff;//target is non-active after power on
		Syn_RB_L_temp =1'b0;
	end
	else if (1'b0==SyncActive) 
	begin
	   Syn_RB_L_temp =1'b0;
	   CE_L_temp[0]=Asyn_CE_L;
	   CE_L_temp[1]=Asyn_CE_L;
	   CE_L_temp[2]=Asyn_CE_L;
	   CE_L_temp[3]=Asyn_CE_L;
	   CE_L_temp[4]=Asyn_CE_L;
	   CE_L_temp[5]=Asyn_CE_L;
	   CE_L_temp[6]=Asyn_CE_L;
	   CE_L_temp[7]=Asyn_CE_L;
	end
	else
	begin 
	   case(Target_Addr)
	   3'h0:begin
	   	    Syn_RB_L_temp =RB_L[0];
	        CE_L_temp[0]=Syn_CE_L;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1;
	   end
	   3'h1:begin
	   	    Syn_RB_L_temp =RB_L[1];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=Syn_CE_L;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1;  
	   end	 
	   3'h2:begin
	   	    Syn_RB_L_temp =RB_L[2];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=Syn_CE_L;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1; 	   
	   end
	   3'h3:begin
	   	    Syn_RB_L_temp =RB_L[3];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=Syn_CE_L;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1; 	   
	   end
	   3'h4:begin
	   	    Syn_RB_L_temp =RB_L[4];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=Syn_CE_L;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1; 		   
	   end
	   3'h5:begin
	   	    Syn_RB_L_temp =RB_L[5];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=Syn_CE_L;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1; 	   
	   end
	   3'h6:begin
	   	    Syn_RB_L_temp =RB_L[6];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=Syn_CE_L;
			CE_L_temp[7]=1'b1; 	   
	   end
	   3'h7:begin
	   	    Syn_RB_L_temp =RB_L[7];
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=Syn_CE_L;   
	   end	   
       default:begin
	   	    Syn_RB_L_temp =1'b0;
	        CE_L_temp[0]=1'b1;
			CE_L_temp[1]=1'b1;
			CE_L_temp[2]=1'b1;
			CE_L_temp[3]=1'b1;
			CE_L_temp[4]=1'b1;
			CE_L_temp[5]=1'b1;
			CE_L_temp[6]=1'b1;
			CE_L_temp[7]=1'b1;
	   end
	   endcase
	end
end
always@(posedge clk_83M or negedge rst)
begin
   if(!rst)
   begin
     CE_L<=8'hff;
	 Syn_RB_L<=1'b0;
   end
   else
   begin
     CE_L<=CE_L_temp;
	 Syn_RB_L<=Syn_RB_L_temp;
   end
end
//****************************************************************************************//

//***********************Asychronous interface reset main Asyn_current_state machine***************************************//
always@(posedge clk_83M or negedge rst)
	begin
		if(!rst) begin
			Asyn_current_state <= POWER_UP;//
			current_toggle_state <= TOGGLE_WAIT;
		end
		else begin	 
			Asyn_current_state <= Asyn_next_state; 
			current_toggle_state <= next_toggle_state;
		end
	end

	always@(*)
	begin
	 // Asyn_next_state = POWER_UP;
		case(Asyn_current_state)
			 //Chip power up and wait for command to reset chip.
		   POWER_UP : begin
					Asyn_next_state=TARGET_SELECTION;
			end
			/**chip reset**/
			TARGET_SELECTION:begin
			   if(Timer0=='d10)
			     Asyn_next_state=PREPARE_RESET_TARGET;
			   else
			     Asyn_next_state=TARGET_SELECTION;
			end
			PREPARE_RESET_TARGET:begin//'h17
				if(Asyn_RB_L1)
						Asyn_next_state = RESET_TARGET_COMMAND_1;
					else 
					begin
						Asyn_next_state = PREPARE_RESET_TARGET;						
					end 
			end
 
			RESET_TARGET_COMMAND_1:begin//'h18
				if(toggledone)
						Asyn_next_state = RESET_WAIT_FOR_0;
					else 
						Asyn_next_state = RESET_TARGET_COMMAND_1;
			end			
			RESET_WAIT_FOR_0: begin//'h19
				if(Asyn_RB_L0)
				    Asyn_next_state = RESET_WAIT_FOR_0;	
				else 
						Asyn_next_state = RESET_WAIT_FOR_1;
			end			
			RESET_WAIT_FOR_1: begin//'h1a
				if(Asyn_RB_L1)
				    Asyn_next_state = RESET_CHIP_END;	
				else
				   Asyn_next_state = RESET_WAIT_FOR_1;
			end
		RESET_CHIP_END:begin
		  Asyn_next_state =ACTIVESYN_CMD;	
		end
			
//********Active Synchronous Interface***************//
			ACTIVESYN_CMD:begin
				if(toggledone)
						Asyn_next_state =ACTIVESYN_ADDR;
					else 
						Asyn_next_state =ACTIVESYN_CMD;			
			end
			ACTIVESYN_ADDR:begin
				if(toggledone)
						Asyn_next_state =ACTIVESYN_WAITTADL;
					else 
						Asyn_next_state =ACTIVESYN_ADDR;
			end
			
			ACTIVESYN_WAITTADL:begin
			  if(Timer0>='d42)
			    begin
						Asyn_next_state =ACTIVESYN_DATAMODE;
				 end
			  else 
						Asyn_next_state =ACTIVESYN_WAITTADL;
			end
			
			ACTIVESYN_DATAMODE:begin//data 14h,selection of DDR and timing mode4
			  if(toggledone)
						Asyn_next_state = ACTIVESYN_DATA00;
					else 
						Asyn_next_state = ACTIVESYN_DATAMODE;
			end
			
			ACTIVESYN_DATA00:begin//data 00h,00h,00h
			  if(toggledone)
						Asyn_next_state = ACTIVESYN_WAITRB0;
					else 
						Asyn_next_state = ACTIVESYN_DATA00;
			end
			ACTIVESYN_WAITRB0:begin
			if(Asyn_RB_L0)
			  begin
			    Asyn_next_state =ACTIVESYN_WAITRB0;
			  end
			else 
				  Asyn_next_state = ACTIVESYN_WAITRB1;
			end
			
			ACTIVESYN_WAITRB1:begin
			 if(Asyn_RB_L1)
    		     Asyn_next_state = ACTIVESYN_END;	
			 else 
				Asyn_next_state =ACTIVESYN_WAITRB1;
			end
			
			ACTIVESYN_END:begin
			    Asyn_next_state =ACTIVESYN_END;
			end			
			
			default:begin
			   Asyn_next_state=POWER_UP;
			end
		endcase
end			
always@(posedge clk_83M or negedge rst)
	begin
		if(!rst) begin	
         SyncActive<=1'b0;		
		   Timer0Start<=1'b0;
		   Timer0En<=1'b0;
			toggle_enable <= 'b0;
			Asyn_DQX_reg<=8'b0;
			flash_control_signals1<=5'b11001;
			flash_control_signals2<=5'b11001;
			//active sync interface mode
			internal_counter0_upto<='b0;
      end
		else begin
		case(Asyn_next_state)
		   //Chip power up and wait for command to reset chip.
		   POWER_UP : begin	
		   		   Timer0En<=1'b0;
			       Timer0Start<=1'b0;
                   SyncActive<=1'b0;		
					internal_counter0_upto <= 'h0;
			end
			TARGET_SELECTION:begin
			  SyncActive<=1'b0;
			  Timer0En<=1'b1;
			  Timer0Start<=1'b1;
			end
			/**chip reset**/
			PREPARE_RESET_TARGET:begin//'h17
				  Timer0En<=1'b0;
			      Timer0Start<=1'b0;
                  SyncActive<=1'b0;									
			end

			RESET_TARGET_COMMAND_1:begin//'h18
				
				Asyn_DQX_reg<= RESET_COMMAND_1; 
				toggle_enable <= 'b1;
				flash_control_signals1 <= 5'b10010;
				flash_control_signals2 <= 5'b11010;
			end			
			RESET_WAIT_FOR_0: begin//'h19
			    toggle_enable <= 'b0;
			end			
			RESET_WAIT_FOR_1: begin//'h1a
			end
			RESET_CHIP_END:begin
			end
			//********Active Synchronous Interface***************//
			ACTIVESYN_CMD:begin
			   internal_counter0_upto <= 'h0;
			   Asyn_DQX_reg<=SET_FEATURES;
				toggle_enable <= 'b1;
				flash_control_signals1 <= 'b10010;
				flash_control_signals2 <= 'b11010;		
			end
			ACTIVESYN_ADDR:begin
			   Asyn_DQX_reg<='h01;
				toggle_enable <= 'b1;
				internal_counter0_upto <= 'h0;
				flash_control_signals1 <= 'b10100;
				flash_control_signals2 <= 'b11100;
			end
			
			ACTIVESYN_WAITTADL:begin
			  toggle_enable <= 'b0;
			  Timer0En<=1'b1;
			  Timer0Start<=1'b1;
			end
			
			ACTIVESYN_DATAMODE:begin//data 14h,selection of DDR and timing mode4
			  Timer0Start<=1'b0;
			  Timer0En<=1'b0;
			  
			  toggle_enable <= 'b1;
			  Asyn_DQX_reg<='h14;
			  flash_control_signals1 <= 'b10000;
			  flash_control_signals2 <= 'b11000;
			end
			
			ACTIVESYN_DATA00:begin//data 00h,00h,00h
			  internal_counter0_upto <= 'h3;
			  toggle_enable <= 'b1;
			  Asyn_DQX_reg<='h00;
			  flash_control_signals1 <= 'b10000;
			  flash_control_signals2 <= 'b11000;
			end

			ACTIVESYN_WAITRB0:begin
			    toggle_enable <= 'b0;
			    internal_counter0_upto <= 'h0;
			end
			
			ACTIVESYN_WAITRB1:begin
			end
						
			ACTIVESYN_END:begin
				   SyncActive<=1'b1;//switch to synchoronous mode WE_Lorclk <=WE_L;RE_LorWR_L<=RE_L; 
			end
			default:begin 
			end
     endcase
	 end
end	 

 
always@(*)
begin
		case(current_toggle_state)

		TOGGLE_WAIT: begin
				if(toggle_enable == 'b1) 
						next_toggle_state = TOGGLECLR;
				else 
						next_toggle_state = TOGGLE_WAIT;
			end
			
		TOGGLECLR:begin
			  next_toggle_state = TOGGLE_CE_EN;
			end
			
		TOGGLE_CE_EN : begin
		  	if(delay_counter >= 'd7) begin//??WE_N??? ??16?clk.??>=70ns(tCS)
					next_toggle_state = TOGGLE1;	
			end
			else begin
					next_toggle_state = TOGGLE_CE_EN;
			end 
		end
			TOGGLE1: begin
				if(delay_counter >= 'd14) begin//??WE_N??? ??16?clk.??>=70ns(tCS)
						next_toggle_state = TOGGLEADD;	
					end
					else begin
						next_toggle_state = TOGGLE1;
					end
			end
			
			TOGGLEADD:begin
		    next_toggle_state =TOGGLE2;
		  end
		  
			TOGGLE2: begin 
				if (delay_counter == 'd19) 
						if(internal_counter0 >= internal_counter0_upto) 
							next_toggle_state = TOGGLE_DONE;
						else
						  begin
							 next_toggle_state = TOGGLECLR;
							end
				else
						next_toggle_state = TOGGLE2;
			end
			TOGGLE_DONE: begin
					next_toggle_state = TOGGLE_WAIT;
			end
		
			default: begin
				next_toggle_state = TOGGLE_WAIT;
			end
		
	
		endcase
end

  always@(posedge clk_83M or negedge rst)
  begin
		if(!rst) begin
			delay_counter_rst 	 <= 'b0;
			delay_counter_en <= 'b0;
			internal_counter0_rst <= 'b0;
			internal_counter0_en <= 'b0;
			Asyn_CE_L  <= 1'b1;
			Asyn_CLE_H <= 1'b0;
			Asyn_ALE_H <= 1'b0;
			WE_L  <= 1'b1;
			RE_L  <= 1'b1;
			toggledone <= 'b0;
		end
		else begin
			case(next_toggle_state)
				TOGGLE_WAIT: begin
		    	delay_counter_rst 	 <= 'b0;
		    	delay_counter_en <= 'b0;
		    	internal_counter0_rst <= 'b0;
		    	internal_counter0_en <= 'b0;
		    	{RE_L,WE_L,Asyn_ALE_H,Asyn_CLE_H,Asyn_CE_L}<=5'b11000;
			  	toggledone <= 'b0;
				end
				
				TOGGLECLR:begin
				  delay_counter_rst <= 'b0;
				end	
				TOGGLE_CE_EN : begin
				   delay_counter_rst 	 <= 'b1;
					delay_counter_en <= 'b1;
					internal_counter0_rst <= 'b1;
				  {RE_L,WE_L,Asyn_ALE_H,Asyn_CLE_H,Asyn_CE_L}<=5'b11000;
				end
				TOGGLE1: begin
				   delay_counter_rst 	 <= 'b1;
					delay_counter_en <= 'b1;
					internal_counter0_rst <= 'b1;
					{RE_L,WE_L,Asyn_ALE_H,Asyn_CLE_H,Asyn_CE_L}<=flash_control_signals1;
				end
				TOGGLEADD:begin
				  internal_counter0_en <= 'b1;
				end
				TOGGLE2: begin 
					delay_counter_en <= 'b1;
               internal_counter0_en <= 'b0;
					{RE_L,WE_L,Asyn_ALE_H,Asyn_CLE_H,Asyn_CE_L}<=flash_control_signals2;
				end

				TOGGLE_DONE: begin
						toggledone <= 'b1;
						{RE_L,WE_L,Asyn_ALE_H,Asyn_CLE_H,Asyn_CE_L}<=5'b11000;
				end
				
				default: begin
				end
			
			endcase
		 end
	end	
	
/**delay counter**/
	always@(posedge clk_83M or negedge rst)
	begin
		if(!rst) begin
			delay_counter <= 'h0;
		end
		else begin
			if(!delay_counter_rst)
				delay_counter <= 'h0;
			else if(delay_counter == 'hff)
				delay_counter <= 'h0;
			else if(delay_counter_en)
				delay_counter <= delay_counter + 1'b1;
			else 
				delay_counter <= delay_counter;
		end
	end
	
//internal_counter0 is for account of the No. of commands or addresses needed to send in asynchronous interface.
/****internal_counter0****/
	always@(posedge clk_83M or negedge rst)
	begin
		if(!rst) begin
			internal_counter0 <= 'h0;
		end 
		else begin
			if(!internal_counter0_rst)
				internal_counter0 <= 'h0;
			else if(internal_counter0_en)
				internal_counter0 <= internal_counter0 + 1'b1;
			else 
				internal_counter0 <= internal_counter0;
		end
	end

always@(posedge clk_83M or negedge rst)
begin
   if(!rst)
     begin 
     Timer0<='h00;
   end
 else if(1'b1==Timer0En)
   begin
       if(1'b1==Timer0Start)
         Timer0<=Timer0+1'b1;
       else
         Timer0<=Timer0;
   end
 else
   Timer0<='h00;
end






//***************************Synchronous Interface operation part*******************************************//

reg [4:0] Syn_current_state;
reg [4:0] Syn_next_state;


always@(posedge clk_83M or negedge rst)
begin
	if(!rst)
	 begin
	  Syn_current_state<=SYN_WAIT4SYNACTIVE;
	  Syn_CA_currentstate<=CA_PREPARE;

	  page_offset_addr_reg[0] <= 'h00;
	  page_offset_addr_reg[1] <= 'h00;
	  page_offset_addr_reg[2] <= 'h00;
	  page_offset_addr_reg[3] <= 'h00;

	  WP_L=1'b1;
	 end
	else 
	 begin
	      page_offset_addr_reg[0] <= page_offset_addr[7:0];
			page_offset_addr_reg[1] <= page_offset_addr[15:8];
			page_offset_addr_reg[2] <= {3'b000,page_offset_addr[ADDR_WIDTH-4:16]};//modified by qww
			page_offset_addr_reg[3] <= 'h00;
			
			Syn_current_state<=Syn_next_state;
			
			Syn_CA_currentstate<=Syn_CA_nextstate;
	 end 
end

always@(*)
begin
   case(Syn_current_state)
	      SYN_WAIT4SYNACTIVE:begin
			  if(SyncActive)
			    begin
			     Syn_next_state=SYN_STANDBY;
				 end
			  else
			     begin
			       Syn_next_state=SYN_WAIT4SYNACTIVE;
				  end
			end
			SYN_STANDBY:begin
			  if(Operation_en)
				 begin
				  Syn_next_state=SYN_BUSIDLE;
				 end
				else
				  begin
				  Syn_next_state=SYN_STANDBY;
				  end
			end
			
			SYN_BUSIDLE: begin
			      case(Operation_Type)
					3'h1:begin
					   Syn_next_state = READ_PAGE_COMMAND_1;
					end
					3'h2:begin
					   Syn_next_state = WRITE_PAGE_COMMAND_1;
					end
					3'h4:begin
					   Syn_next_state = ERASE_BLOCK_COMMAND_1;
					end
					3'h5:begin
					  Syn_next_state = READ_PAGE_WAIT;
					end
					default:begin
					  Syn_next_state =SYN_STANDBY;
					end
					
					endcase
			end

	// read page from flash operation
	    READ_PAGE_COMMAND_1:begin
			  if(CA_Done)
			      Syn_next_state=READ_PAGE_ADDRESS_00;
			  else
			      Syn_next_state=READ_PAGE_COMMAND_1;
		 end
		 READ_PAGE_ADDRESS_00:begin
			  if(CA_Done)
			    Syn_next_state=READ_PAGE_ADDRESS_3CYCLE;
			  else
			    Syn_next_state=READ_PAGE_ADDRESS_00;
		 end
		
		 READ_PAGE_ADDRESS_3CYCLE:begin
			  if(CA_Done)
			     Syn_next_state=READ_PAGE_COMMAND_2;
			  else
			    Syn_next_state=READ_PAGE_ADDRESS_3CYCLE;
			  
		end
      READ_PAGE_COMMAND_2:begin
			 if(CA_Done)
			    Syn_next_state=READ_PAGE_WAIT_FOR_0;
			  else
			    Syn_next_state=READ_PAGE_COMMAND_2;
	  end
	  
	  READ_PAGE_WAIT_FOR_0: begin
	     if(!Syn_RB_L)
	     begin
				Syn_next_state= SYN_STANDBY;
			 end
			else begin
				Syn_next_state = READ_PAGE_WAIT_FOR_0;
			end
	  end
	  /*
	  READ_PAGE_WAIT_FOR_1: begin
	     if(Syn_RB_L)
	     begin
				  Syn_next_state= READ_PAGE_WAIT;
			 end
	     else
				Syn_next_state= READ_PAGE_WAIT_FOR_1;
	  end
	   */
	  READ_PAGE_WAIT: begin
	    if('d3==Timer2)
		begin
	       if(RD_data_FIFO_full)//Data-reading from flash will not start until host inform is coming.
	         Syn_next_state=SYN_STANDBY;
          else
            Syn_next_state=READ_PAGE_DATA_OUT;
	    end
		else
		begin
		  Syn_next_state=READ_PAGE_WAIT;
		end
	  end   
	  READ_PAGE_DATA_OUT:begin     
		 if(Dataout_Done)
		   Syn_next_state=READ_DELAY_TRHW120;
		 else
		  Syn_next_state=READ_PAGE_DATA_OUT;
	  end 
	  READ_DELAY_TRHW120:begin
	        if('d10==Timer2)//Timer2: Tclk ns a count
		        Syn_next_state=READ_PAGE_END;
	        else
		        Syn_next_state=READ_DELAY_TRHW120;	   	    
	  end
	  
 	  READ_PAGE_END: begin
 	    Syn_next_state=SYN_STANDBY;
	  end
	  
    //programming page operation procedure   
    WRITE_PAGE_COMMAND_1:begin
		   if(CA_Done)
		 	    Syn_next_state=WRITE_PAGE_ADDRESS_00;
	     else
			    Syn_next_state=WRITE_PAGE_COMMAND_1;
      end
     WRITE_PAGE_ADDRESS_00:begin
			  if(CA_Done)
			    Syn_next_state=WRITE_PAGE_ADDRESS_3CYCELE;
			  else
			    Syn_next_state=WRITE_PAGE_ADDRESS_00;  
     end
     WRITE_PAGE_ADDRESS_3CYCELE:begin
			  if(CA_Done)
			     Syn_next_state=WRITE_PAGE_DELAY70NS;
			  else
			    Syn_next_state=WRITE_PAGE_ADDRESS_3CYCELE;	  
	  end
	  WRITE_PAGE_DELAY70NS:begin
	        if('d5==Timer2)//Timer2: Tclk a count
		      begin
		        Syn_next_state=WRITE_PAGE_DATA;
		      end
	        else
		        Syn_next_state=WRITE_PAGE_DELAY70NS;	     
	  end
	  
	  WRITE_PAGE_DATA:begin
		 if(Datain_Done)
		   Syn_next_state=WRITE_PAGE_COMMAND_2;
		 else
		  Syn_next_state=WRITE_PAGE_DATA;
	  end
	  WRITE_PAGE_COMMAND_2:begin
		   if(CA_Done)
		 	    Syn_next_state=WRITE_PAGE_WAIT_FOR_0;
	     else
			    Syn_next_state=WRITE_PAGE_COMMAND_2;
     end	  
	
	  WRITE_PAGE_WAIT_FOR_0:begin
	     if(!Syn_RB_L)
				  Syn_next_state = SYN_STANDBY;
			else 
				Syn_next_state = WRITE_PAGE_WAIT_FOR_0;
     end	 
/*	  
	  WRITE_PAGE_WAIT_FOR_1:begin
 	     if(Syn_RB_L)
				Syn_next_state = SYN_STANDBY;
		  else 
				Syn_next_state = WRITE_PAGE_WAIT_FOR_1;   
     end	
	  */
	  
//  erase block operation 	procedure
     ERASE_BLOCK_COMMAND_1:begin 
			  if(CA_Done)
			    Syn_next_state=ERASE_BLOCK_ADDRESS_3CYCLES;
			  else
			    Syn_next_state=ERASE_BLOCK_COMMAND_1;
	  end
	  ERASE_BLOCK_ADDRESS_3CYCLES:begin//writing three address cycles containing the row address
			  if(CA_Done)
			     Syn_next_state=ERASE_BLOCK_COMMAND_2;
			  else
			    Syn_next_state=ERASE_BLOCK_ADDRESS_3CYCLES;
	  end
	  ERASE_BLOCK_COMMAND_2:begin//the ERASE BLOCK(60h-D0h) operation. 
			  if(CA_Done)
			    Syn_next_state=ERASE_BLOCK_WAIT_FOR_0;
			  else
			    Syn_next_state=ERASE_BLOCK_COMMAND_2;
	  end
	  ERASE_BLOCK_WAIT_FOR_0:begin
	  	     if(!Syn_RB_L)
				Syn_next_state = SYN_STANDBY;
		     else 
				Syn_next_state = ERASE_BLOCK_WAIT_FOR_0; 
	 end
	 /*
	 ERASE_BLOCK_WAIT_FOR_1:begin
	 	  	  if(Syn_RB_L)
				  Syn_next_state = ERASE_BLOCK_END;
		     else 
				Syn_next_state = 	 ERASE_BLOCK_WAIT_FOR_1;
	 end
	 ERASE_BLOCK_END:begin
	    Syn_next_state = SYN_STANDBY;
	 end
	 */
    default: Syn_next_state = SYN_STANDBY;
     endcase
 end
 
always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
  begin
    Command<='b0;
	 during_read_data <= 'b0;
	 controller_rb_l <= 'b0;
	 CA_Control_Signal0<=4'b0;
	 CA_Control_Signal1<=4'b0;
	 CA_Control_Signal2<=4'b0;
	 internal_counter2_upto<='b0;
	 CA_Start<=1'b0;
	 Dataout_Start<=1'b0;
    Datain_Start <=1'b0;
	 
	 Timer2En<=1'b0;
	 Timer2Start<=1'b0;
	 read_data_stall<=1'b0;
  end
  else begin
   case(Syn_next_state)
	      SYN_WAIT4SYNACTIVE:begin
			    Command<='b0;
			    during_read_data <= 'b0;
			    controller_rb_l <= 'b0;
			    CA_Control_Signal0<=4'b1001;
				 internal_counter2_upto<='b0;
				 CA_Start<=1'b0;
		       Dataout_Start<=1'b0;
             Datain_Start <=1'b0;
				 Timer2En<=1'b0;
	          Timer2Start<=1'b0;
			  read_data_stall<=1'b0;
	      end
			SYN_STANDBY:begin
			   controller_rb_l <= 'b1;//until now the controller can be operated 
			  	CA_Start<=1'b0;
				Dataout_Start<=1'b0;
				Datain_Start <=1'b0;

			  CA_Control_Signal0<=4'b1001;
				 Timer2En<=1'b0;
	          Timer2Start<=1'b0;
			end
			
			SYN_BUSIDLE: begin
				controller_rb_l <= 'b0;

				CA_Start<=1'b0;
				Dataout_Start<=1'b0;
				Datain_Start <=1'b0;
				CA_Control_Signal0<=4'b0001;
				Timer2En<=1'b0;
	         Timer2Start<=1'b0;
			end
	
	// read page from flash operation
	     READ_PAGE_COMMAND_1:begin
	        controller_rb_l<=1'b0;
			  internal_counter2_upto<='d0;//send one command.
		     CA_Start<=1'b1;
		     CA_Control_Signal1<=4'b0101;
		     CA_Control_Signal2<=4'b0001;
		     Command<=READ_MODE;//00h: read operation first command
		  end
		  READ_PAGE_ADDRESS_00:begin
			  internal_counter2_upto<='d1;//send 2 commands(0,1).
		     CA_Start<=1'b1;
		     CA_Control_Signal1<=4'b0011;
		     CA_Control_Signal2<=4'b0001;
		     Command<=00;//00h: read from colum 0 in a page.
		  end
		
		  READ_PAGE_ADDRESS_3CYCLE:begin
			  internal_counter2_upto<='d2;
		     CA_Start<=1'b1;
		     CA_Control_Signal1<=4'b0011;
		     CA_Control_Signal2<=4'b0001;
			  Command<=page_offset_addr_reg[internal_counter2[1:0]]; 
		  end
        READ_PAGE_COMMAND_2:begin
			 internal_counter2_upto<='d0;
			 CA_Start<=1'b1;
		    CA_Control_Signal1<=4'b0101;
		    CA_Control_Signal2<=4'b0001;
			 Command<=READ_PAGE; //'h30 
	     end
	 
	  READ_PAGE_WAIT_FOR_0: begin
	       CA_Start<=1'b0;	
			 CA_Control_Signal0<=4'b1001;// transition to STANDBY mode.
	  end
	  /*
	  READ_PAGE_WAIT_FOR_1: begin
	  end
	    */
	  READ_PAGE_WAIT: begin
        controller_rb_l<=1'b0;
		read_data_stall<=1'b1;
	    Timer2En<=1'b1;
	    Timer2Start<=1'b1;
	  end
	
	  READ_PAGE_DATA_OUT:begin 
	  	    Timer2En<=1'b0;
	       Timer2Start<=1'b0;
	       read_data_stall<=1'b0;
	       controller_rb_l<=1'b0;
	       during_read_data<=1'b1;
	       CA_Control_Signal0<=4'b0001;// transition to IDLE mode.
			 CA_Control_Signal1<=4'b0000;
			 CA_Control_Signal2<=4'b0110;
		    Dataout_Start<=1'b1; 
	  end 
	  READ_DELAY_TRHW120:begin
	    Dataout_Start<=1'b0;
	      Timer2En<=1'b1;
	      Timer2Start<=1'b1;		  
	  end	
	  
	  READ_PAGE_END: begin
	     Timer2En<=1'b0;
	     Timer2Start<=1'b0;
	    	during_read_data<=1'b0;
	  end
	 
  //programming page operation procedure   
    WRITE_PAGE_COMMAND_1:begin
         controller_rb_l <= 'b0;
		   during_read_data<=1'b0;
         internal_counter2_upto<='d0;
		   CA_Start<=1'b1;
		   CA_Control_Signal1<=4'b0101;
		   CA_Control_Signal2<=4'b0001;
		   Command<=PROGRAM_MODE;//80h: program operation first command
      end
     WRITE_PAGE_ADDRESS_00:begin
		     internal_counter2_upto<='d1;
		     CA_Start<=1'b1;
		     CA_Control_Signal1<=4'b0011;
		     CA_Control_Signal2<=4'b0001;
		     Command<=00;//00h: read from colum 0 in a page. 
     end
     WRITE_PAGE_ADDRESS_3CYCELE:begin
		     internal_counter2_upto<='d2;
		     CA_Start<=1'b1; 
		     CA_Control_Signal1<=4'b0011;
		     CA_Control_Signal2<=4'b0001;
			  Command<=page_offset_addr_reg[internal_counter2[1:0]];  
	  end
	  WRITE_PAGE_DELAY70NS:begin
	      CA_Start<=1'b0;
	      Timer2En<=1'b1;
	      Timer2Start<=1'b1;
    
	  end
	  WRITE_PAGE_DATA:begin
	      Timer2En<=1'b0;
	      Timer2Start<=1'b0;
         Datain_Start<=1'b1;
		   CA_Control_Signal1<=4'b0001;
			CA_Control_Signal2<=4'b0111;
	  end
	  WRITE_PAGE_COMMAND_2:begin
	      Datain_Start<=1'b0;
         internal_counter2_upto<='d0;
		   CA_Start<=1'b1;
		   CA_Control_Signal1<=4'b0101;
		   CA_Control_Signal2<=4'b0001;
		   Command<=PROGRAM_PAGE;//10h Program second command
     end	  
	  
	  WRITE_PAGE_WAIT_FOR_0:begin
	   	 Timer2En<=1'b1;
	     Timer2Start<=1'b1;  
	     CA_Start<=1'b0;
     end	
/*	 
	  WRITE_PAGE_WAIT_FOR_1:begin
	    	CA_Control_Signal0<=4'b1001;// transition to STANDBY mode.
	     Release<=1'b1;
     end
	 */ 
//  erase block operation 	procedure
     ERASE_BLOCK_COMMAND_1:begin
	   controller_rb_l <= 'b0;
		internal_counter2_upto<='d0;
		CA_Start<=1'b1;
		CA_Control_Signal1<=4'b0101;
	   CA_Control_Signal2<=4'b0001;
	   Command<=ERASE_BLOCK_CMD1;//60h:the first Erase OPerations command,before three addresses 
	  end
	  ERASE_BLOCK_ADDRESS_3CYCLES:begin//writing three address cycles containing the row address
	  	  internal_counter2_upto<='d2;
		  CA_Start<=1'b1;
		  CA_Control_Signal1<=4'b0011;
		  CA_Control_Signal2<=4'b0001;
		  Command<=page_offset_addr_reg[internal_counter2[1:0]];
	  end
	  ERASE_BLOCK_COMMAND_2:begin//the ERASE BLOCK(60h-D0h) operation. 
	    internal_counter2_upto<='d0;
		 CA_Start<=1'b1;
		 CA_Control_Signal1<=4'b0101;
	    CA_Control_Signal2<=4'b0001;
	    Command<=ERASE_BLOCK_CMDEND;//the concluded command of ERASE BLOCK(60h-D0h) operation
	  end
	 ERASE_BLOCK_WAIT_FOR_0:begin
	   CA_Start<=1'b0;
	 end
	 /*
	 ERASE_BLOCK_WAIT_FOR_1:begin
	    CA_Control_Signal0<=4'b1001;// transition to STANDBY mode.
	    Release<=1'b1;
	 end
	 ERASE_BLOCK_END:begin
	     Release<=1'b0;
	 end
	 */
     default: begin
	  end
	  
     endcase
	end
end

	//**********************Synchoronus Command or Address Issure procedure************//

always@(*)
begin
 case(Syn_CA_currentstate )
   CA_PREPARE:begin
	   if(CA_Start)
			Syn_CA_nextstate=CA_WAIT;
		else if (Dataout_Start)
		   Syn_CA_nextstate=DDR_DATAOUT_PREPARE;
		else if (Datain_Start)
		   Syn_CA_nextstate=DDR_DATAIN_EN;
		else 
			Syn_CA_nextstate=CA_PREPARE;
	end
	
	CA_WAIT :begin
	   if(Timer1>='h2)
		 begin
		   Syn_CA_nextstate=CA_ISSURE;
		 end
	   else
		 Syn_CA_nextstate=CA_WAIT;
	end
	
	CA_ISSURE:begin
		 Syn_CA_nextstate=CA_COMPLETE;   
	end
	
	CA_COMPLETE:begin
		 if(internal_counter2>=internal_counter2_upto)// 先判断后加1
		    Syn_CA_nextstate=CA_END;
		 else
		    Syn_CA_nextstate=CA_WAIT;
	end
	CA_END: begin
		  Syn_CA_nextstate=CA_PREPARE;
   end
	
  // DDR Data out 
  DDR_DATAOUT_PREPARE:begin
	  if(Timer1=='d3)
		   Syn_CA_nextstate=DDR_MODE;
	   else
		   Syn_CA_nextstate=DDR_DATAOUT_PREPARE;
  end
  
  DDR_MODE:begin
    if(Timer1=='d2056)
        Syn_CA_nextstate=DDR_DATAOUT_END;
	 else
	     Syn_CA_nextstate=DDR_MODE;
  end
  
  DDR_DATAOUT_END:begin  
	  if(Timer1=='d2060)
		  Syn_CA_nextstate=CA_PREPARE;
		 else
		 Syn_CA_nextstate=DDR_DATAOUT_END;
  end	
  
//DDR data in part
  DDR_DATAIN_EN:begin
	  if(Timer1=='d3)
		   Syn_CA_nextstate=DATAIN_PREPARE;
	  else
		   Syn_CA_nextstate=DDR_DATAIN_EN;
  end
  DATAIN_PREPARE:begin // a clk period
		   Syn_CA_nextstate=DATAIN_MODE;	 
  end
  DATAIN_MODE:begin
	 if(Timer1=='d2051)
	   Syn_CA_nextstate=DDR_DATAIN_LAST2;
	 else
	   Syn_CA_nextstate=DATAIN_MODE;
  end
 DDR_DATAIN_LAST2:begin
	   if(Timer1=='d2052)
		  Syn_CA_nextstate=DDR_DATAIN_END;
		 else
		 Syn_CA_nextstate=DDR_DATAIN_LAST2;   
 end
 DDR_DATAIN_END:begin
		  Syn_CA_nextstate=CA_PREPARE;
 end 
 
   default:Syn_CA_nextstate=CA_PREPARE;
  endcase
end

always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
  begin
      FIFO_Dataout_Valid<=1'b0;
      Timer1En<=1'b0;
	   Timer1Start<=1'b0;
     	internal_counter2_rst<=1'b0;
		internal_counter2_en<=1'b0;
		CA_Done<=1'b0;
		Dataout_Done<=1'b0;
		 data_to_flash_en<='b0;
		 Datain_Done <=1'b0;
	  {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=4'b0;
	  	clear_flash_datafifo<=1'b0;
	  	DQS_Start_temp<='b0;
  end
  else
  begin
      case(Syn_CA_nextstate )
      CA_PREPARE:begin
	      //DQS_Start_temp<='b0;
	         data_to_flash_en<='b0;
		  		  Datain_Done <=1'b0;
		      CA_Done<=1'b0;
			   Dataout_Done<=1'b0;
	
			  FIFO_Dataout_Valid<=1'b0;
	        Timer1En<=1'b0;
	        Timer1Start<=1'b0;
			  internal_counter2_rst<=1'b0;
		     internal_counter2_en<=1'b0;
		     {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal0;
		     
			  clear_flash_datafifo<=1'b0;
		  end
	CA_WAIT :begin
	  internal_counter2_rst<=1'b1;
	  Timer1En<=1'b1;
	  Timer1Start<=1'b1;
	  internal_counter2_en<=1'b0;  
	  {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal0;
	end
	CA_ISSURE:begin
	  Timer1En<=1'b0;
	  Timer1Start<=1'b0;
	  internal_counter2_en<=1'b0; 
	 {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal1;  
	end
	CA_COMPLETE:begin
		internal_counter2_en<=1'b1;	   
	  {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal2;
	end
	CA_END: begin
	  internal_counter2_rst<=1'b0;
	  internal_counter2_en<=1'b0;
	  {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal0;
	  CA_Done<=1'b1;
	end
	
  // DDR Data out 
  DDR_DATAOUT_PREPARE:begin
    {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal1; 
	  Timer1En<=1'b1;
	  Timer1Start<=1'b1;
	  clear_flash_datafifo<=1'b1;
  end
  
  DDR_MODE:begin
  	   clear_flash_datafifo<=1'b0;
     {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal2; 
  end
    
  DDR_DATAOUT_END:begin
      Dataout_Done<=1'b1;
     {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal0;
  end	
  
  
//DDR data in part
  DDR_DATAIN_EN:begin
     {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal1; 
	  Timer1En<=1'b1;
	  Timer1Start<=1'b1;

  end
  DATAIN_PREPARE:begin
     {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal2;
	   FIFO_Dataout_Valid<=1'b1;
		data_to_flash_en<=1'b0;
  end
  DATAIN_MODE:begin
    {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal2;
 	  DQS_Start_temp<=1'b1;
	  data_to_flash_en<=1'b1;
  end
 DDR_DATAIN_LAST2:begin
     {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal1;  
 end
 
 DDR_DATAIN_END:begin
      {Syn_CE_L,Syn_CLE_H,Syn_ALE_H,WR_L}<=CA_Control_Signal1; 
		  DQS_Start_temp<=1'b0;
	    // FIFO_Dataout_Valid<=1'b0;
		  data_to_flash_en<=1'b0;
		  Timer1En<=1'b0;
	     Timer1Start<=1'b0;
		  Datain_Done<=1'b1;
 end 
   default:begin
	end
  endcase
  end
end

//internal_counter2 is for account of the No. of commands or addresses needed to send in synchronous interface.
/****internal_counter2****/
	always@(posedge clk_83M or negedge rst)
	begin
		if(!rst) begin
			internal_counter2 <= 2'b0;
		end 
		else begin
			if(!internal_counter2_rst)
				internal_counter2 <= 'h0;
			else if(internal_counter2_en)
				internal_counter2 <= internal_counter2 + 1'b1;
			else 
				internal_counter2 <= internal_counter2;
		end
	end
//Time1 for Synchoronus Command or Address Issure procedure
//T=5ns
always@(posedge clk_83M or negedge rst)
begin
   if(!rst)
     begin
     Timer1<='h00;
   end
 else if(1'b1==Timer1En)
   begin
       if(1'b1==Timer1Start)
         Timer1<=Timer1+1'b1;
       else
         Timer1<=Timer1;
   end
 else
   Timer1<='h00;
end
	
//Time2 for Synchoronus main machine state
always@(posedge clk_83M or negedge rst)
begin
   if(!rst)
     begin
     Timer2<='h00;
   end
 else if(1'b1==Timer2En)
   begin
       if(1'b1==Timer2Start)
         Timer2<=Timer2+1'b1;
       else
         Timer2<=Timer2;
   end
 else
   Timer2<='h00;
end

/*


reg curr_en_state;
reg next_en_state;

parameter RD_FLASH_EN_0 =1'b0;
parameter RD_FLASH_EN_1 =1'b1;
always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
  begin
    curr_en_state<=RD_FLASH_EN_0;
  end
else
  curr_en_state<=next_en_state;
end

always@(*)
begin
   case(curr_en_state)
   RD_FLASH_EN_0:begin   
     if( flash_data_fifo_empty==1'b0 )
       next_en_state=RD_FLASH_EN_1;
	 else
	   next_en_state=RD_FLASH_EN_0;
   end
   RD_FLASH_EN_1:begin
      next_en_state=RD_FLASH_EN_0;
   end
 endcase
end

always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
  begin
      rd_flash_datafifo_en<=1'b0;
  end
  else
  begin
     case(next_en_state)
	   RD_FLASH_EN_0:begin   
	      rd_flash_datafifo_en<=1'b0;
        end
       RD_FLASH_EN_1:begin
          rd_flash_datafifo_en<=1'b1;
       end 
     endcase
  end
end
*/
reg [11:0] ddr_datain_counter;
always@( posedge clk_83M or negedge rst)
begin
  if(!rst)
     ddr_datain_counter<=12'b0;
  else
  begin
     if(clear_flash_datafifo)
        ddr_datain_counter<=12'b0;
     else if(rd_flash_datafifo_en)
		    ddr_datain_counter<=ddr_datain_counter+1'b1;
     else
        ddr_datain_counter<=ddr_datain_counter;
  end
end

always@(posedge clk_83M or negedge rst)
begin
  if(!rst)
  begin
      rd_flash_datafifo_en<=1'b0;
  end
  else
  begin
     if(ddr_datain_counter>='h7ff)
        rd_flash_datafifo_en<=1'b0;
     else if( flash_data_fifo_empty==1'b0 )
	      rd_flash_datafifo_en<=1'b1;
     else
	     rd_flash_datafifo_en<=1'b0;
  end
end
/*
// FIFO Write operation:Data output from FIFO, to flash chips.
always@( posedge clk_data_transfer or negedge rst)
begin
  if(!rst)
     data_to_flash_en<=1'b0;
  else
     data_to_flash_en<=Datain_ready;
end
//assign data_to_flash_en=Datain_ready;
*/
endmodule

