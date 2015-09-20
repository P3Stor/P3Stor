`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:38:54 12/16/2014 
// Design Name: 
// Module Name:    Cmd_Analysis 
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
module Cmd_Analysis(
clk,fifo_rd_clk,clk_83M,rst_n,
Cmd_In_En,Cmd_In,Finished_Cmd_FIFO_Empty,Finished_Cmd_Out_En,Finished_Cmd_Out,Data_In_En,Data_In,Cmd_Available,Data_2_host_en,Data_2_host,ControllerIdle,
Set_Empty,Set_Empty_ID,FIFO_rd_en,FIFO_addr,FIFO_empty,Cmd_Out,RAM_Unit_ID,Finished_cmd_wr_en,Finished_cmd_FIFO_full,Chips_Ready,
Rd_RAM_Data_en,Data_Out,DataFromFlash_en,DataFromFlash,RD_data_FIFO_full
    );

`include"Dynamic_Controller_Parameters.vh"
	 
input clk;//200M
input fifo_rd_clk;//166M
input clk_83M;
input rst_n; 
//Interface with Host
input Cmd_In_En; // indicate the arrival of Command from host. positive is valid. 
input [ 127 : 0 ] Cmd_In; //Command from host
output Finished_Cmd_FIFO_Empty; // inform host the state of finished command FIFO, 
                                  // if not empty, host can read the finished command back.
input Finished_Cmd_Out_En; // reading finished command enable signal from host. positive is valid
output [ 127 : 0 ] Finished_Cmd_Out; // finished command 
input Data_In_En; // data input enable signal, positive  is valid.
input [ 255 : 0 ] Data_In; // data 
output reg Cmd_Available;   ////Only if the Cmd_Available pin is high can the sending command from host can be accepted.
input Data_2_host_en;
output [255:0] Data_2_host;
output reg ControllerIdle;
//Interface with Scheduler.
input Set_Empty;
input [3:0] Set_Empty_ID;
input FIFO_rd_en;
input [2:0] FIFO_addr;
output FIFO_empty;
output [ 127: 0] Cmd_Out;

input [3:0] RAM_Unit_ID;
input Finished_cmd_wr_en;
output Finished_cmd_FIFO_full;
input Chips_Ready;
//Interface with flash_controller module.
input Rd_RAM_Data_en;
output [7:0]  Data_Out;

input DataFromFlash_en;   //write enable, positive is valid
input [15:0] DataFromFlash; //16-bit data input bus
output RD_data_FIFO_full;
//////////////////////////////////////////////////////////////////////

parameter IDLE             = 3'h0;
parameter RD_FIRST_CMD     = 3'h1;
parameter RD_SECOND_CMD    = 3'h2;
parameter WR_FIRST_CMD     = 3'h3;
parameter WR_SECOND_CMD    = 3'h4;
parameter ER_FIRST_CMD     = 3'h5;
parameter ER_SECOND_CMD    = 3'h6;


 reg [6:0] wr_data_counter;
 reg during_wr_data;
//read and write addresses
reg [9:0] wr_address;
reg [14:0] rd_address;

reg [3:0] Current_ID;
wire [3:0] FE_ID_w;
wire Avaliable_w;
// RAM empty judgment logic
reg [7:0] empty;

reg cmd_arrived;
reg cmd_write_en;
reg cmd_read_en;
reg cmd_erase_en;
reg [127:0] Command_Temp;
reg [2:0] Target_Addr;

//Send micro commands into addressed FIFO
reg [2:0] cmd_curr_state;
reg [2:0] cmd_next_state;
reg cmd_fifo_wr_en;
reg [127:0] cmd_data_in;
reg cmd_write_en_clr;
reg cmd_read_en_clr;
reg cmd_erase_en_clr;
//MUX1_8
wire [7:0] wr_en_w;
wire [127:0] din0_w;
wire [127:0] din1_w;
wire [127:0] din2_w;
wire [127:0] din3_w;
wire [127:0] din4_w;
wire [127:0] din5_w;
wire [127:0] din6_w;
wire [127:0] din7_w;

wire [7:0] rd_en_w;
wire [7:0] almost_full_w;
wire [7:0] FIFO_empty_w;
//MUX8_1
wire rd_en0_w;
wire rd_en1_w;
wire rd_en2_w;
wire rd_en3_w;
wire rd_en4_w;
wire rd_en5_w;
wire rd_en6_w;
wire rd_en7_w;

wire [127:0] dout0_w;
wire [127:0] dout1_w;
wire [127:0] dout2_w;
wire [127:0] dout3_w;
wire [127:0] dout4_w;
wire [127:0] dout5_w;
wire [127:0] dout6_w;
wire [127:0] dout7_w;

wire fifo_rst;
assign fifo_rst=~rst_n;	
//If all RAM units are full or micro command FIFOs are full or occurrence of sending micro commands to FIFO.
///assign Cmd_Available= (~|almost_full_w) & (|FE_ID_w) & (~cmd_arrived) &(~during_wr_data);
//assign ControllerIdle= ~((&FIFO_empty_w) & Chips_Ready);
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    ControllerIdle<=1'b0;
	Cmd_Available<=1'b0;
  end
  else
  begin
    ControllerIdle<=(&FIFO_empty_w) & Chips_Ready;
	Cmd_Available <= (~|almost_full_w) & (|FE_ID_w) & (~cmd_arrived) &(~during_wr_data);
  end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    cmd_write_en<=1'b0;
	cmd_read_en<=1'b0;
	cmd_erase_en<=1'b0;
	Target_Addr<=3'b0;
	Current_ID<=4'b0;
	cmd_arrived<=1'b0;
  end
  else
  begin
	 if(Cmd_In_En&Cmd_Available)
	 begin
	   Command_Temp<=Cmd_In;
	 
		cmd_arrived<=1'b1;
	   case(Cmd_In[127:126])
		2'b00:begin//read operaiton
		   cmd_write_en<=1'b0;
	       cmd_read_en<=1'b1;
	       cmd_erase_en<=1'b0;
		   Target_Addr<=Cmd_In[66:64];
		end
		2'b01:begin
		   Current_ID<=FE_ID_w;
		   cmd_write_en<=1'b1;
	       cmd_read_en<=1'b0;
	       cmd_erase_en<=1'b0;
		   Target_Addr<=Cmd_In[66:64];
		end
		2'b11:begin
		   cmd_write_en<=1'b0;
	       cmd_read_en<=1'b0;
	       cmd_erase_en<=1'b1;
		   Target_Addr<=Cmd_In[2:0];
		end
		default:begin
		   cmd_write_en<=1'b0;
	       cmd_read_en<=1'b0;
	       cmd_erase_en<=1'b0;
		   Target_Addr<=3'b0;
		end
	    endcase
     end 
    else if(cmd_write_en_clr)
	 begin
      cmd_write_en<=1'b0;
		cmd_arrived<=1'b0;
	 end
	else if (cmd_read_en_clr)
	begin
	  cmd_read_en<=1'b0;
	  cmd_arrived<=1'b0;
	end
	else if (cmd_erase_en_clr)
	begin
	   cmd_erase_en<=1'b0;
		cmd_arrived<=1'b0;
	end
  end
end

// Set empty=0 when host trnasfers data to the addressed RAM unit.
// Set empty=1 when controller retrieves all of data of specified RAM unit.
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    empty<=8'hff;
  end
  else
  begin
    if(Set_Empty)
	begin
		case(Set_Empty_ID)
	  	4'h1:empty[0]<=1'b1;
		4'h2:empty[1]<=1'b1;
		4'h3:empty[2]<=1'b1;
		4'h4:empty[3]<=1'b1;
		4'h5:empty[4]<=1'b1;
		4'h6:empty[5]<=1'b1;
		4'h7:empty[6]<=1'b1;
		4'h8:empty[7]<=1'b1;
		default:empty<=empty;
	   endcase
	end
    else if(cmd_write_en)
	begin
  		case(Current_ID)
		     4'h1:empty[0]<=1'b0;
		     4'h2:empty[1]<=1'b0;
		     4'h3:empty[2]<=1'b0;
		     4'h4:empty[3]<=1'b0;
		     4'h5:empty[4]<=1'b0;
		     4'h6:empty[5]<=1'b0;
		     4'h7:empty[6]<=1'b0;
		     4'h8:empty[7]<=1'b0;
			 default:empty<=empty;
		   endcase
    end
	
  end
end
/****************************Send micro commands into addressed FIFO**************/

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
     cmd_curr_state<='b0;
  end  
  else
  begin
    cmd_curr_state<=cmd_next_state;
  end
end  

always@(*)
begin
   //cmd_next_state=IDLE;
	case(cmd_curr_state) 
	IDLE:begin
	  if(cmd_write_en)
	    cmd_next_state=WR_FIRST_CMD;
	  else if (cmd_read_en)
	    cmd_next_state=RD_FIRST_CMD;
	  else if (cmd_erase_en)
	    cmd_next_state=ER_FIRST_CMD;
	  else
	    cmd_next_state=IDLE;
	end
	RD_FIRST_CMD:begin
	    cmd_next_state=RD_SECOND_CMD;
	end
	RD_SECOND_CMD:begin
	     cmd_next_state=IDLE;
	end
	WR_FIRST_CMD:begin
	   cmd_next_state=WR_SECOND_CMD;
	end
	WR_SECOND_CMD:begin
	   cmd_next_state=IDLE;
	end
	ER_FIRST_CMD:begin
	   cmd_next_state=ER_SECOND_CMD;
	end
	ER_SECOND_CMD:begin
	   cmd_next_state=IDLE;
	end
	default:begin
	  cmd_next_state=IDLE;
	end
	endcase
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
	  cmd_fifo_wr_en<=1'b0;
      cmd_data_in<=128'b0;
	  cmd_write_en_clr<=1'b0;
      cmd_read_en_clr<=1'b0;
      cmd_erase_en_clr<=1'b0;
	end
	else
	begin
	  case(cmd_next_state)
	  IDLE:begin
	     cmd_fifo_wr_en<=1'b0;
         cmd_data_in<=128'b0;
	     cmd_write_en_clr<=1'b0;
         cmd_read_en_clr<=1'b0;
         cmd_erase_en_clr<=1'b0;
	  end
	  
	  RD_FIRST_CMD:begin
	    cmd_read_en_clr<=1'b1;
	    cmd_fifo_wr_en<=1'b1;
        cmd_data_in<={Command_Temp[127:65+ADDR_WIDTH],1'b0,Command_Temp[63+ADDR_WIDTH:0]};
	  end
	  RD_SECOND_CMD:begin
	    cmd_read_en_clr<=1'b0;
	    cmd_fifo_wr_en<=1'b1;
        cmd_data_in<={Command_Temp[127:65+ADDR_WIDTH],1'b1,Command_Temp[63+ADDR_WIDTH:0]};
	  end
	  
	  WR_FIRST_CMD:begin
	    cmd_write_en_clr<=1'b1;
	    cmd_fifo_wr_en<=1'b1;
        cmd_data_in<={Command_Temp[127:123],Current_ID,Command_Temp[118:65+ADDR_WIDTH],1'b0,Command_Temp[63+ADDR_WIDTH:0]}; //122-120
	  end
	  WR_SECOND_CMD:begin
	  	  cmd_write_en_clr<=1'b0;
	     cmd_fifo_wr_en<=1'b1;
        cmd_data_in<={Command_Temp[127:123],Current_ID,Command_Temp[118:65+ADDR_WIDTH],1'b1,Command_Temp[63+ADDR_WIDTH:0]}; //122-120	     
	  end
	  ER_FIRST_CMD:begin
	     cmd_erase_en_clr<=1'b1;
		 cmd_fifo_wr_en<=1'b1;
         cmd_data_in<={Command_Temp[127:65+ADDR_WIDTH],1'b0,Command_Temp[63+ADDR_WIDTH:0]};
	  end
	  ER_SECOND_CMD:begin
		 cmd_erase_en_clr<=1'b0;
		 cmd_fifo_wr_en<=1'b1;
       cmd_data_in<={Command_Temp[127:65+ADDR_WIDTH],1'b1,Command_Temp[63+ADDR_WIDTH:0]};     
	  end 
	  default:begin
	    cmd_erase_en_clr<=1'b0;
		 cmd_fifo_wr_en<=1'b0;
       cmd_data_in<=128'b0;
	  end
	  endcase
	end
end
/////////////////////////////END///////////////////////////////////////////////////////////

/**************************WRITE DATA*****************************************************/
//write addresses set
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
		  wr_address<=10'b0;
  end  
  else
  begin
       if(Data_In_En)
		  wr_address<=wr_address+1'b1;//256x128 a unit
	   else if(wr_data_counter==0)
		  wr_address<=(Current_ID-1'b1)*'h80;
	   else
	      wr_address<=wr_address;
		  
  end
end
//Write data counter:0-'d127
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    wr_data_counter<=7'b0;
  end
  else
  begin
     if(Data_In_En)
	   wr_data_counter<=wr_data_counter+1'b1;
	 else
	    wr_data_counter<=wr_data_counter;
  end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    during_wr_data<=1'b0;
  end
  else
  begin
    if(cmd_write_en)
      during_wr_data<=1'b1;
    else if (wr_data_counter=='h7f)
      during_wr_data<=1'b0;
  end
end
//////////////////////////END///////////////////////////////////////////////////////////////

//read addresses set
always@(posedge fifo_rd_clk or negedge rst_n)
begin
  if(!rst_n)
  begin
     rd_address<=15'b0;
  end  
  else
  begin
       if(Rd_RAM_Data_en)
		    rd_address<=rd_address+1'b1;
		 else
		    rd_address<=(RAM_Unit_ID-1'b1)*'h1000;//8x4096 a unit
  end
end
////////////////////////////////////////////////////////////////////////
wire [255:0] data_in;
//reg data_in_en_o;
reg data_in_en;
reg [15:0] data0 ;
reg [15:0] data1 ;
reg [15:0] data2 ;
reg [15:0] data3 ;
reg [15:0] data4 ;
reg [15:0] data5 ;
reg [15:0] data6 ;
reg [15:0] data7 ;
reg [15:0] data8 ;
reg [15:0] data9 ;
reg [15:0] data10;
reg [15:0] data11;
reg [15:0] data12;
reg [15:0] data13;
reg [15:0] data14;
reg [15:0] data15;
reg [3:0] counter;

//assign data_in={data15,data14,data13,data12,data11,data10,data9,data8,data7,data6,data5,data4,data3,data2,data1,data0};
assign data_in={data0,data1,data2,data3,data4,data5,data6,data7,data8,data9,data10,data11,data12,data13,data14,data15};
RD_DATA_FIFO rd_data_fifo_inst1 (
  .rst(fifo_rst), // input rst
  .wr_clk(clk_83M), // input wr_clk=83M
  .rd_clk(clk), // input rd_clk =200M
  .din(data_in), // input [255 : 0] din
  .wr_en(data_in_en), // input wr_en
  .rd_en(Data_2_host_en), // input rd_en
  .dout(Data_2_host), // output [255 : 0] dout
  .full(), // output full
  .empty(), // output empty
  .prog_full(RD_data_FIFO_full) // output prog_full
);
reg [6:0] rd_data_in_counter;
always@(posedge clk_83M or negedge rst_n )
begin
  if(!rst_n)
  begin
     rd_data_in_counter<='b0;
  end
  else
  begin
     if(data_in_en)
	    rd_data_in_counter<=rd_data_in_counter+1'b1;
	  else
	    rd_data_in_counter<=rd_data_in_counter;
  end
end

always@(posedge clk_83M or negedge rst_n )
begin
  if(!rst_n)
  begin
   // data_in_en_o<=1'b0;
    data_in_en<=1'b0;
  end
  else
  begin
   //data_in_en_o<=data_in_en;
    if(counter=='hf)
	  data_in_en<=1'b1;
	else
	  data_in_en<=1'b0;
  end
end
always@(posedge clk_83M or negedge rst_n )
begin
  if(!rst_n)
  begin
     data0 <=16'b0;
     data1 <=16'b0;
     data2 <=16'b0;
     data3 <=16'b0;
     data4 <=16'b0;
     data5 <=16'b0;
     data6 <=16'b0;
     data7 <=16'b0;
     data8 <=16'b0;
     data9 <=16'b0;
     data10<=16'b0;
     data11<=16'b0;
     data12<=16'b0;
     data13<=16'b0;
     data14<=16'b0;
     data15<=16'b0;
  end  
  else
  begin
     if(DataFromFlash_en)
	 begin
        data0 <= DataFromFlash;
        data1 <= data0        ;
        data2 <= data1        ;
        data3 <= data2        ;
        data4 <= data3        ;
        data5 <= data4        ;
        data6 <= data5        ;
        data7 <= data6        ;
        data8 <= data7        ;
        data9 <= data8        ;
        data10<= data9        ;
        data11<= data10       ;
        data12<= data11       ;
        data13<= data12       ;
        data14<= data13       ;
        data15<= data14       ;
	 end
  end
end
//
always@(posedge clk_83M or negedge rst_n )
begin
  if(!rst_n)
  begin
     counter<=4'b0;
  end
  else
  begin       
    if(DataFromFlash_en)
	     counter<=counter+1'b1;
  end
end

/////////////////////////////////////////////////////////////////////////////

RAM_WRITE ram_write_inst (
  .clka(clk), // input clka
  .wea(Data_In_En), // input [0 : 0] wea
  .addra(wr_address), // input [9 : 0] addra
  .dina(Data_In), // input [255 : 0] dina
  .douta(), // output [255 : 0] douta
  .clkb(fifo_rd_clk), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(rd_address), // input [14 : 0] addrb
  .dinb(8'b0), // input [7 : 0] dinb
  .doutb(Data_Out) // output [7 : 0] doutb
);
Valid_Monitor  valid_monitor_inst(.clk(clk), 
                                  .rst_n(rst_n), 
											 .Valid(empty), 
											 .FE_ID(FE_ID_w)
											  );


MUX1_8 mux1_8_inst( .address(Target_Addr),
               .wr_en(cmd_fifo_wr_en),
			   .din(cmd_data_in),
               .wr_en0(wr_en_w[0]),
			   .wr_en1(wr_en_w[1]),
			   .wr_en2(wr_en_w[2]),
			   .wr_en3(wr_en_w[3]),
			   .wr_en4(wr_en_w[4]),
			   .wr_en5(wr_en_w[5]),
			   .wr_en6(wr_en_w[6]),
			   .wr_en7(wr_en_w[7]),
               .din0(din0_w)  ,
			   .din1(din1_w)  ,
			   .din2(din2_w)  ,
			   .din3(din3_w)  ,
			   .din4(din4_w)  ,
			   .din5(din5_w)  ,
			   .din6(din6_w)  ,
			   .din7(din7_w) 
    );

TargetCmdFIFO target_fifo_inst0 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din0_w), // input [127 : 0] din
  .wr_en(wr_en_w[0]), // input wr_en
  .rd_en(rd_en0_w), // input rd_en
  .dout(dout0_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[0]), // output almost_full
  .empty(FIFO_empty_w[0]) // output empty
);
TargetCmdFIFO target_fifo_inst1 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din1_w), // input [127 : 0] din
  .wr_en(wr_en_w[1]), // input wr_en
  .rd_en(rd_en1_w), // input rd_en
  .dout(dout1_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[1]), // output almost_full
  .empty(FIFO_empty_w[1]) // output empty
);
TargetCmdFIFO target_fifo_inst2 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din2_w), // input [127 : 0] din
  .wr_en(wr_en_w[2]), // input wr_en
  .rd_en(rd_en2_w), // input rd_en
  .dout(dout2_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[2]), // output almost_full
  .empty(FIFO_empty_w[2]) // output empty
);
TargetCmdFIFO target_fifo_inst3 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din3_w), // input [127 : 0] din
  .wr_en(wr_en_w[3]), // input wr_en
  .rd_en(rd_en3_w), // input rd_en
  .dout(dout3_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[3]), // output almost_full
  .empty(FIFO_empty_w[3]) // output empty
);
TargetCmdFIFO target_fifo_inst4 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din4_w), // input [127 : 0] din
  .wr_en(wr_en_w[4]), // input wr_en
  .rd_en(rd_en4_w), // input rd_en
  .dout(dout4_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[4]), // output almost_full
  .empty(FIFO_empty_w[4]) // output empty
);
TargetCmdFIFO target_fifo_inst5 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din5_w), // input [127 : 0] din
  .wr_en(wr_en_w[5]), // input wr_en
  .rd_en(rd_en5_w), // input rd_en
  .dout(dout5_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[5]), // output almost_full
  .empty(FIFO_empty_w[5]) // output empty
);
TargetCmdFIFO target_fifo_inst6 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din6_w), // input [127 : 0] din
  .wr_en(wr_en_w[6]), // input wr_en
  .rd_en(rd_en6_w), // input rd_en
  .dout(dout6_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[6]), // output almost_full
  .empty(FIFO_empty_w[6]) // output empty
);
TargetCmdFIFO target_fifo_inst7 (
  .clk(clk), // input clk
  .rst(fifo_rst), // input rst
  .din(din7_w), // input [127 : 0] din
  .wr_en(wr_en_w[7]), // input wr_en
  .rd_en(rd_en7_w), // input rd_en
  .dout(dout7_w), // output [127 : 0] dout
  .full(), // output full
  .almost_full(almost_full_w[7]), // output almost_full
  .empty(FIFO_empty_w[7]) // output empty
);

MUX8_1 mux8_1_inst(
                   .address(FIFO_addr),
				   //Ports inside
                   .rd_en0(rd_en0_w),
                   .rd_en1(rd_en1_w),
                   .rd_en2(rd_en2_w),
                   .rd_en3(rd_en3_w),
                   .rd_en4(rd_en4_w),
                   .rd_en5(rd_en5_w),
                   .rd_en6(rd_en6_w),
                   .rd_en7(rd_en7_w),
                   .dout0(dout0_w),
                   .dout1(dout1_w),
                   .dout2(dout2_w),
                   .dout3(dout3_w),
                   .dout4(dout4_w),
                   .dout5(dout5_w),
                   .dout6(dout6_w),
                   .dout7(dout7_w),
				       .empty0(FIFO_empty_w[0]),
                   .empty1(FIFO_empty_w[1]),
                   .empty2(FIFO_empty_w[2]),
                   .empty3(FIFO_empty_w[3]),
                   .empty4(FIFO_empty_w[4]),
                   .empty5(FIFO_empty_w[5]),
                   .empty6(FIFO_empty_w[6]),
                   .empty7(FIFO_empty_w[7]),
                   //Ports with scheduler module
                   .rd_en(FIFO_rd_en),
				   .empty(FIFO_empty),
                   .dout(Cmd_Out)
    );
	
//instantiation of Finished command FIFO, which is for storing finished command,Pop out from TargetCmdFIFOs.
Finished_Cmd_FIFO finished_cmd_fifo_inst1(.clk(clk),
                                          .rst(fifo_rst),
														.din(Cmd_Out),
														.wr_en(Finished_cmd_wr_en),
														.rd_en(Finished_Cmd_Out_En),
														.dout(Finished_Cmd_Out),
														.full(Finished_cmd_FIFO_full),
														.empty(Finished_Cmd_FIFO_Empty)
														);

endmodule
