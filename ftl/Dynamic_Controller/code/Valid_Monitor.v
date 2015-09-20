`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:24:03 06/11/2014 
// Design Name: 
// Module Name:    Valid_Monitor 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 1. Snooping the state of valid bits of every entry in Reserve station.
//              2. Output the first free entry ID(i.e.,FE_ID) of the RS.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module Valid_Monitor(clk, rst_n, Valid, FE_ID);
    input clk;
    input rst_n;
    input [7:0] Valid;

    output reg [3:0] FE_ID;			//the first empty RS

always @(posedge clk or negedge rst_n)
begin
		if(!rst_n)
		begin
			FE_ID <= 4'h0;
		end
		else
		begin
          casex(Valid)
		    8'bxxxx_xxx1:begin
			    FE_ID <= 4'h1;
			 end
			 8'bxxxx_xx10:begin
			    FE_ID <= 4'h2;
			 end
			 8'bxxxx_x100:begin
			    FE_ID <= 4'h3;
			 end
			 8'bxxxx_1000:begin
			    FE_ID <= 4'h4;
			 end
			 8'bxxx1_0000:begin
			    FE_ID <= 4'h5;
			 end
			 8'bxx10_0000:begin
			    FE_ID <= 4'h6;
			 end
			 8'bx100_0000:begin
			    FE_ID <= 4'h7;
			 end
			 8'b1000_0000:begin
			    FE_ID <= 4'h8;
			 end
          default:begin
                FE_ID <= 4'h0;
          end			
		   endcase
		end
end 

endmodule
