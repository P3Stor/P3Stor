`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:24:21 12/18/2014 
// Design Name: 
// Module Name:    Scheduler 
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
module Scheduler(clk,rst_n,
   Set_Empty,Set_Empty_ID,FIFO_rd_en,FIFO_addr,FIFO_empty,Cmd_Out,RAM_Unit_ID,Finished_cmd_wr_en,Finished_cmd_FIFO_full,Chips_Ready,
   Target_Addr,Operation_en,Operation_Type,page_offset_addr,controller_rb_l,read_data_stall,
   RB_L
    );
	 
`include"Dynamic_Controller_Parameters.vh"

input clk;//200M
input rst_n;
//Interface with Cmd_Analysis.
output reg Set_Empty;
output reg [3:0] Set_Empty_ID;
output reg FIFO_rd_en;
output reg [2:0] FIFO_addr;
input FIFO_empty;
input [ 127: 0] Cmd_Out;
output reg [3:0] RAM_Unit_ID;
output reg Finished_cmd_wr_en;
input Finished_cmd_FIFO_full;
output Chips_Ready;
//Ports with SynchronizeClkDomains module.
output [2:0] Target_Addr;
output reg Operation_en;
output reg [2:0] Operation_Type;
output reg [ADDR_WIDTH-4:0] page_offset_addr;
input controller_rb_l;
input read_data_stall;
//Port with Chips
input [7:0] RB_L;
///////////////////////////////////////////////////////////////////////////////////////////////////

parameter  WAIT4RESET        = 3'h0;
parameter  TARGET_SELECTION  = 3'h1; 
parameter  BUSY_OR_NOT       = 3'h2;
parameter  FETCHING_COMMAND  = 3'h3;
parameter  COMPLETEED        = 3'h4;
parameter  POP_COMMAND       = 3'h5;
parameter  FIFO_COUNTER_ADD  = 3'h6;
parameter  QUERY_NEXT_FIFO   = 3'h7;

reg [2:0] Curr_State;
reg [2:0] Next_State;

//Counter for round query.
reg [2:0] FIFO_counter;
reg FIFO_counter_en;
//Delay counter
reg [3:0] delay_counter;
reg delay_counter_rst;
reg delay_counter_en;
//
reg Rb_l_reg;
//reg Rb_l_reg1;
assign Target_Addr=FIFO_addr;

/////时钟域同步逻辑：目标时钟域加入两级寄存器链�///////////////////////////////////
//RB_L Signal from 83M clk domain 
always@(posedge clk)
begin
   	   case(FIFO_addr)
	   3'h0:begin
	   	    Rb_l_reg <=RB_L[0];
	   end
	   3'h1:begin
	   	    Rb_l_reg <=RB_L[1];
	   end	 
	   3'h2:begin
	   	    Rb_l_reg <=RB_L[2];
	   end
	   3'h3:begin
	   	    Rb_l_reg <=RB_L[3];
	   end
	   3'h4:begin
	   	    Rb_l_reg <=RB_L[4];   
	   end
	   3'h5:begin
	   	    Rb_l_reg <=RB_L[5];
	  	   end
	   3'h6:begin
	   	    Rb_l_reg <=RB_L[6];
	   	   end
	   3'h7:begin
	   	    Rb_l_reg <=RB_L[7];
 	   end	   
       default:begin
	   	    Rb_l_reg <=1'b0;
	   end
	   endcase
end
////////////////////////END///////////////////////////////////////////////////////////

/////////////////ControllerBusy output ///////////////////////////////////////////
reg  Ready;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		Ready<=1'b0;
	else
	begin
	    Ready<=&RB_L;
    end
end
assign Chips_Ready= Ready & controller_rb_l ;
//////////////////////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		Curr_State<=WAIT4RESET;
	else
		Curr_State<=Next_State;
end

always@(*)
begin
  // Next_State=WAIT4RESET;
	case(Curr_State)
	//This is the initial state after system power up.
	//This state is the reset and active sync mode( through async mode) time.
	WAIT4RESET : begin//0
       if(controller_rb_l)// indicate that reset is over 
			Next_State=TARGET_SELECTION;
		 else
			Next_State=WAIT4RESET;
	end
	// IDLE State : snooping whether a valid command is coming or not.
	//If there is a valid command, transitions to REQ_BUS_OCCUPATION state. 
	TARGET_SELECTION : begin//1
	  if(Finished_cmd_FIFO_full)
	     Next_State=TARGET_SELECTION;
      else if('h8==delay_counter)
		  Next_State=BUSY_OR_NOT;
		else
		  Next_State=TARGET_SELECTION;
	end
	BUSY_OR_NOT:begin//2
	   if(Rb_l_reg & (~FIFO_empty) )//ready=1 and FIFO has valid command.
		  Next_State=FETCHING_COMMAND;
		else
		  Next_State=FIFO_COUNTER_ADD;
	end

	FETCHING_COMMAND:begin//3
	   if('h8==delay_counter) 
		    Next_State=COMPLETEED;
		else
		   Next_State=FETCHING_COMMAND;
	end
	COMPLETEED:begin//4
	  if(controller_rb_l)
	     Next_State=POP_COMMAND;
	  else
	     Next_State=COMPLETEED;
	end 
	POP_COMMAND:begin//5
	     Next_State=FIFO_COUNTER_ADD;
	end
	//
	FIFO_COUNTER_ADD:begin//6
		Next_State=QUERY_NEXT_FIFO;
	end
	QUERY_NEXT_FIFO:begin//7
	   Next_State=TARGET_SELECTION;
	end	
	endcase
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
	  FIFO_rd_en<=1'b0;
	  FIFO_addr<=3'b0;
	  FIFO_counter_en<=1'b0;
	  delay_counter_rst<=1'b0;
	  delay_counter_en<=1'b0;
	  Operation_en<=1'b0;
	  Operation_Type<=3'b0;
	  Finished_cmd_wr_en<=1'b0;
	  RAM_Unit_ID<=4'b0;
	  page_offset_addr<='b0;
	  Set_Empty<=1'b0;
	  Set_Empty_ID<=4'b0;
	end
	else
	begin
	  	case(Next_State)
	    //This is the initial state after system power up.
	    //This state is the reset and active sync mode( through async mode) time.
		WAIT4RESET : begin
			FIFO_rd_en<=1'b0;
	      FIFO_addr<=3'b0;   
			FIFO_counter_en<=1'b0;
			delay_counter_rst<=1'b1;
	      delay_counter_en<=1'b0;
		    Operation_en<=1'b0;
			Operation_Type<=3'b0;
			Finished_cmd_wr_en<=1'b0;
			RAM_Unit_ID<=4'b0;
			page_offset_addr<='b0;
		   Set_Empty<=1'b0;
	       Set_Empty_ID<=4'b0;
		end
		TARGET_SELECTION : begin
		    FIFO_rd_en<=1'b0;
	    	FIFO_addr<=FIFO_counter;
		   FIFO_counter_en<=1'b0;
		   delay_counter_rst<=1'b1;
		   delay_counter_en<=1'b1;
			Finished_cmd_wr_en<=1'b0;
			RAM_Unit_ID<=4'b0;
			page_offset_addr<='b0;
		    Set_Empty<=1'b0;
	        Set_Empty_ID<=4'b0;
			Operation_en<=1'b0;
			Operation_Type<=3'b0;
		end
		//
		BUSY_OR_NOT:begin
			delay_counter_rst<=1'b0;
		   delay_counter_en<=1'b0;
          Operation_en<=1'b0;		   
		end
		//
	   FETCHING_COMMAND:begin
	  		delay_counter_rst<=1'b1;
		   delay_counter_en<=1'b1;
		   Operation_en<=1'b1;
			Operation_Type<= {Cmd_Out[64+ADDR_WIDTH],Cmd_Out[127:126]}+1'b1;
			RAM_Unit_ID<=Cmd_Out[122:119];
			case(Cmd_Out[127:126])
			2'b00:begin
			  page_offset_addr<=Cmd_Out[63+ADDR_WIDTH:67];
			end
			2'b01:begin
			  page_offset_addr<=Cmd_Out[63+ADDR_WIDTH:67];
			end
			2'b11:begin
			  page_offset_addr<=Cmd_Out[ADDR_WIDTH-1:3];
			end
			default:begin
			  page_offset_addr<='b0;
			end
			endcase
			
	  end	
	  
	  COMPLETEED:begin
	  		delay_counter_rst<=1'b0;
		   delay_counter_en<=1'b0;
		   Operation_en<=1'b0;
		   Operation_Type<=Operation_Type;
	  end 
     POP_COMMAND:begin
	     if(Cmd_Out[64+ADDR_WIDTH])//If the second Micro command.
		  begin
		     if(read_data_stall) 
			 begin
			     FIFO_rd_en<=1'b0;
				 Finished_cmd_wr_en<=1'b0;
				 Set_Empty<=1'b0;
				 Set_Empty_ID<=4'b0;
			 end
			 else
			 begin
			   FIFO_rd_en<=1'b1;
		       Finished_cmd_wr_en<=1'b1;
				 Set_Empty<=1'b0;
				 Set_Empty_ID<=4'b0;
			 end
		  end
		 else if(Cmd_Out[127:126]==2'b01)//If THE first micro command is write command.
		 begin
		   FIFO_rd_en<=1'b1;
		   Finished_cmd_wr_en<=1'b0;
		   Set_Empty<=1'b1;
	       Set_Empty_ID<=RAM_Unit_ID;
		 end
		 else
		 begin
		   FIFO_rd_en<=1'b1;
		   Finished_cmd_wr_en<=1'b0;
		   Set_Empty<=1'b0;
		   Set_Empty_ID<=4'b0;   
		 end
	  end
	 FIFO_COUNTER_ADD:begin
	    Operation_Type<=3'b0;
	    FIFO_rd_en<=1'b0;
	    Finished_cmd_wr_en<=1'b0;
	   FIFO_counter_en<=1'b1;
	    Set_Empty<=1'b0;
	    Set_Empty_ID<=4'b0;
	end
	QUERY_NEXT_FIFO:begin
	    FIFO_counter_en<=1'b0;
    end
	 endcase
  end
end
/**delay counter**/
always@(posedge clk or negedge rst_n)
begin
	   if(!rst_n)
	   begin
			delay_counter <= 'h0;
		end
		else begin
			if(!delay_counter_rst)
				delay_counter <= 'h0;
			else if(delay_counter_en)
				delay_counter <= delay_counter + 1'b1;
			else 
				delay_counter <= delay_counter;
		end
	end
	
// FIFO Counter for implimentation of round query of Command FIFOs.
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		FIFO_counter <= 3'b0;
    end 
	else begin
	 if(FIFO_counter_en)
		FIFO_counter <= FIFO_counter + 1'b1;
	 else 
		FIFO_counter <= FIFO_counter;
	end
end
endmodule
