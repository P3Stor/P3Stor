`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:37:20 09/24/2014 
// Design Name: 
// Module Name:    SynchronizeClkDomains 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This module is for synchronization of signals between 200M( System workspace)clk domain and 
//              83M(flash controller moduler) clk domain.
//  Method: Adding two FFs betwwn the two specified clk domains to mitigate the damage cased by metastability.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SynchronizeClkDomains(
  clk_200M,clk_83M,rst_n,
  //From flash controller module to Scheduler module
  controller_rb_l,controller_rb_l_o,  read_data_stall  ,read_data_stall_o,
  //From Scheduler module to flash controller module
  Target_Addr,  page_offset_addr,  Operation_en,Operation_Type,  
  Target_Addr_o,page_offset_addr_o,Operation_en_o,Operation_Type_o
    );
	 
`include"Dynamic_Controller_Parameters.vh"	
 
//clk and reset 
input clk_200M;
input clk_83M;
input rst_n;

//From flash controller module to Scheduler module
input controller_rb_l;
input read_data_stall;
output reg controller_rb_l_o;
output reg read_data_stall_o;
//From Scheduler module to flash controller module
input [2:0] Target_Addr;
input [ADDR_WIDTH-4:0] page_offset_addr;
input Operation_en;
input [2:0] Operation_Type;
output reg [2:0] Target_Addr_o;
output reg [ADDR_WIDTH-4:0] page_offset_addr_o;
output reg Operation_en_o;
output reg [2:0] Operation_Type_o;
////////////////////////////////////////////////////////////////



  reg  controller_rb_l_sync;
  reg  read_data_stall_sync;
  //From flash controller module to Scheduler module
always@(posedge clk_200M or negedge rst_n)
begin
 if(!rst_n)
   begin
     controller_rb_l_sync<=1'b0;  
	 read_data_stall_sync<=1'b0;
     controller_rb_l_o<=1'b0;
	 read_data_stall_o<=1'b0;
	end
 else
 begin
     controller_rb_l_sync<=controller_rb_l;
     controller_rb_l_o<=controller_rb_l_sync;
	 read_data_stall_sync<=read_data_stall;
	 read_data_stall_o<=read_data_stall_sync;
 end
end


//sync FFs
reg [2:0] Target_Addr_sync;
reg [ADDR_WIDTH-4:0] page_offset_addr_sync;
reg Operation_en_sync;
reg [2:0] Operation_Type_sync;

  //From Scheduler module to flash controller module.
always@(posedge clk_83M or negedge rst_n)
begin
 if(!rst_n)
   begin
     Target_Addr_sync<=3'b0;
     page_offset_addr_sync<='b0;
	 
     Operation_Type_sync<=3'b0;
	  Operation_en_sync<=1'b0;
	 Target_Addr_o<=3'b0;
     page_offset_addr_o<='b0;	
	 Operation_en_o<=1'b0;
	 Operation_Type_o<=3'b0;
	end
 else
 begin
     Target_Addr_sync<=Target_Addr;
     page_offset_addr_sync<=page_offset_addr;
	 Operation_en_sync<=Operation_en;
     Operation_Type_sync<=Operation_Type;
	  
     Target_Addr_o<=Target_Addr_sync;
     page_offset_addr_o<=page_offset_addr_sync;
	 Operation_en_o<=Operation_en_sync;
     Operation_Type_o<=Operation_Type_sync;
 end
end
endmodule
