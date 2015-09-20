//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:49:40 05/27/2013 
// Design Name: 
// Module Name:    initial_dram 
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
//	从Flash读表到DRAM中，读寄存器值到FPGA寄存器�
//	作为ftl-top的一个模块，地位与io_schedule相当，可类比io-schedule编写�
//	交互模块：dram,controller_command_fifo
//////////////////////////////////////////////////////////////////////////////////
module initial_dram(
	reset,
	clk,
	trigger_initial_dram,
	//input
	all_Cmd_Available_flag, // 
	//output
	controller_command_fifo_in, //  din
	controller_command_fifo_in_en // wr_en
	);
	
	`include "ftl_define.v"
	
	input reset;
	input clk;
	input trigger_initial_dram;
	input all_Cmd_Available_flag;
	
	output 	[COMMAND_WIDTH-1:0] controller_command_fifo_in;
	output 	[7:0] controller_command_fifo_in_en;
	reg 	[COMMAND_WIDTH-1:0] controller_command_fifo_in;
	reg 	[7:0] controller_command_fifo_in_en;
	reg 	[2:0]state;
	reg 	[CHANNEL_ADDR_WIDTH-1:0]channel_index;
	reg 	[7:0] enable;
	reg 	[23:0] page_addr;
	reg 	[DRAM_ADDR_WIDTH-1:0] dram_addr;
	
	parameter PREPARE_FOR_READ	=3'b000;
	parameter SEND_READ_COMMAND	=3'b001;
	parameter CHANGE_PAGE_ADDR	=3'b010;
	parameter READ_REGISTER		=3'b011;
	parameter DONE				=3'b100;


always@(posedge clk or negedge reset )
begin
	if(!reset)
	begin
		state		    <= PREPARE_FOR_READ;
		page_addr	    <= BADBLOCK_FLASH_ADDR1;
		dram_addr	    <= BAD_BLOCK_INFO_BASE;
		channel_index	<= 3'b0;
	end
	else 
	begin
	case(state)
		PREPARE_FOR_READ:
		begin
			if(trigger_initial_dram)
			begin
				case(channel_index)
					3'b000:enable<=8'b00000001;
					3'b001:enable<=8'b00000010;
					3'b010:enable<=8'b00000100;
					3'b011:enable<=8'b00001000;
					3'b100:enable<=8'b00010000;
					3'b101:enable<=8'b00100000;
					3'b110:enable<=8'b01000000;
					3'b111:enable<=8'b10000000;
				endcase
					state	<= SEND_READ_COMMAND;
			end
			else 
				state <= PREPARE_FOR_READ;
		end
		SEND_READ_COMMAND:
		begin
			if(all_Cmd_Available_flag==1'b1)
			begin
				controller_command_fifo_in <= {{READ, 1'b0,2'b10,27'b0},{5'b0,channel_index[2:0],page_addr[23:0]},{12'b0,dram_addr[28:12],channel_index[2:0]}, {5'b0,page_addr[23:0],channel_index[2:0]}}; //32+(7+25)+(14+18)+32
				controller_command_fifo_in_en<=enable;                                  
				channel_index <=channel_index + 1'b1;
				state <=CHANGE_PAGE_ADDR;
			end 
			else 
				state <= SEND_READ_COMMAND;
		end
		CHANGE_PAGE_ADDR:
		begin
			controller_command_fifo_in_en<=8'b00000000;
			if(channel_index ==3'b000)
			begin
				if(page_addr == (BADBLOCK_FLASH_ADDR2))
				begin
					controller_command_fifo_in	<= {READ,1'b0,2'b01,27'b0,10'b0,REGISTER_BASE_FLASH,64'hffff_ffff_ffff_ffff}; 
					state <= READ_REGISTER;
				end
				else
				begin
					page_addr <= page_addr+4'b1_000;
					dram_addr <= dram_addr+13'b1_0000_0000_0000;
					state <= PREPARE_FOR_READ;
				end
			end	
			else 
				state <= PREPARE_FOR_READ;
		end
		READ_REGISTER:
		begin
			if(all_Cmd_Available_flag==1'b1)
			begin
				controller_command_fifo_in	<= {READ,1'b0,2'b01,27'b0,10'b0,REGISTER_BASE_FLASH,64'hffff_ffff_ffff_ffff}; 
				controller_command_fifo_in_en	<=8'b00000001;
				state <=DONE;
			end
			else 
				state <= READ_REGISTER;
		end
		DONE:
		begin
			controller_command_fifo_in_en<=8'b00000000;
			state <=DONE;
		end
		default: 
			state<= PREPARE_FOR_READ;
	endcase
	end
end	
endmodule
