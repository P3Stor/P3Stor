`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:01:54 12/16/2014 
// Design Name: 
// Module Name:    MUX1_8 
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
module MUX1_8( address,
wr_en,din,
wr_en0,wr_en1,wr_en2,wr_en3,wr_en4,wr_en5,wr_en6,wr_en7,
din0  ,din1  ,din2  ,din3  ,din4  ,din5  ,din6  ,din7 
    );
input [2:0] address;
input wr_en;
input [127:0] din;
output reg wr_en0;
output reg wr_en1;
output reg wr_en2;
output reg wr_en3;
output reg wr_en4;
output reg wr_en5;
output reg wr_en6;
output reg wr_en7;
output reg [127:0] din0;
output reg [127:0] din1;
output reg [127:0] din2;
output reg [127:0] din3;
output reg [127:0] din4;
output reg [127:0] din5;
output reg [127:0] din6;
output reg [127:0] din7;
always@(*)
begin
  case(address)
  3'd0:begin
    wr_en0=wr_en;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=din;
	din1=128'b0;
	din2=128'b0;
	din3=128'b0;
	din4=128'b0;
	din5=128'b0;
	din6=128'b0;
	din7=128'b0;
  end
  3'd1:begin
    wr_en0=1'b0;
	wr_en1=wr_en;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=128'b0;
	din1=din;
	din2=128'b0;
	din3=128'b0;
	din4=128'b0;
	din5=128'b0;
	din6=128'b0;
	din7=128'b0;
  end
  3'd2:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=wr_en;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=128'b0;
	din1=128'b0;
	din2=din;
	din3=128'b0;
	din4=128'b0;
	din5=128'b0;
	din6=128'b0;
	din7=128'b0;
  end
  3'd3:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=wr_en;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=128'b0;
	din1=128'b0;
	din2=128'b0;
	din3=din;
	din4=128'b0;
	din5=128'b0;
	din6=128'b0;
	din7=128'b0;
  end
  3'd4:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=wr_en;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=128'b0;
	din1=128'b0;
	din2=128'b0;
	din3=128'b0;
	din4=din;
	din5=128'b0;
	din6=128'b0;
	din7=128'b0;
  end
  3'd5:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=wr_en;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=128'b0;
	din1=128'b0;
	din2=128'b0;
	din3=128'b0;
	din4=128'b0;
	din5=din;
	din6=128'b0;
	din7=128'b0;
  end
  3'd6:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=wr_en;
	wr_en7=1'b0;
	din0=128'b0;
	din1=128'b0;
	din2=128'b0;
	din3=128'b0;
	din4=128'b0;
	din5=128'b0;
	din6=din;
	din7=128'b0;
  end
  3'd7:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=wr_en;
	din0=128'b0;
	din1=128'b0;
	din2=128'b0;
	din3=128'b0;
	din4=128'b0;
	din5=128'b0;
	din6=128'b0;
	din7=din;
  end
  default:begin
    wr_en0=1'b0;
	wr_en1=1'b0;
	wr_en2=1'b0;
	wr_en3=1'b0;
	wr_en4=1'b0;
	wr_en5=1'b0;
	wr_en6=1'b0;
	wr_en7=1'b0;
	din0=128'b0;
	din1=128'b0;
	din2=128'b0;
	din3=128'b0;
	din4=128'b0;
	din5=128'b0;
	din6=128'b0;
	din7=128'b0;
  end
  endcase
end

endmodule
