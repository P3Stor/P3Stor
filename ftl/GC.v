module GC#(
		parameter PHYSICAL_ADDR_WIDTH		= 25,  //flash capacity 16KB*2^25 = 2^39B = 512GB
		parameter DRAM_IO_WIDTH   		= 256, //DRAM IO
		parameter DRAM_ADDR_WIDTH 		= 29,  //DRAM cacacity  64bits(2^3B)*2^29=2^32B = 4GB
		parameter DRAM_MASK_WIDTH 		= 32,  //8bits/mask bit  256/8 = 32
		parameter COMMAND_WIDTH 		= 128, //
		parameter GC_COMMAND_WIDTH 		= 29,  //
		parameter CACHE_ADDR_WIDTH 		= 17,  //cache space 16KB*2^17=2^31B=2GB
		
		parameter PAGE_PER_BLOCK		= 256,
		
		parameter L2P_TABLE_BASE		= 29'b00000_00000000_00000000_00000000, //32bits*2^25=2^27B=128MB
		parameter P2L_TABLE_BASE		= 29'b00000_00000000_10000000_00000000, //32bits*2^25=2^27B=128MB
		parameter FREE_BLOCK_FIFO_BASE		= 29'b00010_00000000_00000000_00000000, //32bits*2^17=2^ram_do=512KB
		parameter GARBAGE_TABLE_BASE		= 29'b00000_00000000_00000000_00000000, //32bits*2^17=2^ram_do=512KB
		parameter CACHE_ENTRY_BASE		= 29'b00100_00000000_00000000_00000000,
		parameter ADDITIONAL_CACHE_FIFO_BASE	= 29'b00101_00000000_00000000_00000000,
		parameter CACHE_BASE			= 29'b10000_00000000_00000000_00000000,	//last 2GB space
		parameter L2P_TABLE_BASE_FLASH		= 22'b111111_11110000_00000000,		//128MB/16KB/8(# of channel)=1K=2^10	
		parameter P2L_TABLE_BASE_FLASH		= 22'b111111_11110100_00000000, 	
		parameter FREE_BLOCK_FIFO_BASE_FLASH	= 22'b111111_11111000_00000000, 	//512KB/16KB/8=4, 4pages/channel,32pages total
		parameter GARBAGE_TABLE_BASE_FLASH	= 22'b111111_11111000_00000100,
		parameter REGISTER_BASE_FLASH		= 22'b111111_11111000_00001000,
		parameter READ				= 2'b00,
		parameter WRITE				= 2'b01,
		parameter MOVE				= 2'b10,
		parameter ERASE				= 2'b11
	)
	(
	clk,
	reset,
	left_capacity,
	init_dram_done,
	data_from_dram,
	dram_ready,	
	rd_data_valid,
	dram_permit,
	gc_command_fifo_prog_full,	
	
	dram_en,
	dram_read_or_write,
	addr_to_dram,
	data_to_dram,
	dram_data_mask,
	data_to_dram_en,
	data_to_dram_end,
	data_to_dram_ready,
	release_dram,
	dram_request,
	gc_command_fifo_in,
	gc_command_fifo_in_en
	);
	
	parameter GC_TRIGGER			=4*1024;    //剩余容量16GB   4K*(16KB*256)  =16GB
	parameter ERGENT_GC_TRIGGER		=2*1024;   //8GB	 2K*(16KB*256)  =8GB
	parameter VERY_ERGENT_GC_TRIGGER	=512;   //2GB	512*(16KB*256)  =2GB
	parameter MINIMUM_REQUIREMENT		=128*16;	
	
	parameter WAIT_FOR_INIT_DONE        =5'b00000;
	parameter IDLE                      =5'b00001;
	parameter NEED_TO_GC                =5'b00010;
	parameter APPLY_FOR_DRAM	    =5'b00011;
	parameter WAIT_FOR_DRAM             =5'b00100;
	parameter SCAN_GARBAGE_TABLE        =5'b00101;
	parameter RECEIVE_GARBAGE_FROM_DRAM0=5'b00110;
	parameter RECEIVE_GARBAGE_FROM_DRAM1=5'b00111;
	parameter CHOOSE_BLOCK              =5'b01000;
	parameter CHECK_GARBAGE             =5'b01001;
	parameter SCAN_P2L                  =5'b01010;
	parameter RECEIVE_DATA_FROM_DRAM0   =5'b01011;
	parameter RECEIVE_DATA_FROM_DRAM1   =5'b01100;
	parameter GET_LOGICAL_ADDR          =5'b01101;
	parameter CHECK_LOGICAL_ADDR        =5'b01110;
	parameter GENERATE_MOVE_COMMAND     =5'b01111;
	parameter SEND_MOVE_COMMAND         =5'b10000;
	parameter CHECK_OFFSET_IN_BLOCK     =5'b10001;
	parameter GENERATE_ERASE_COMMAND    =5'b10010;
	parameter SEND_ERASE_COMMAND        =5'b10011;
	parameter UNLOCK_DRAM               =5'b10100;
    parameter FINISH                    =5'b11111;
	
	input clk;
	input reset;
	input init_dram_done;
	input [16:0] left_capacity;//512GB flash有2的17次方个块
	input [DRAM_IO_WIDTH-1:0] data_from_dram;
	input dram_ready;	
	input rd_data_valid;
	input dram_permit;
	input gc_command_fifo_prog_full;	
	
	output dram_en;
	output dram_read_or_write;
	output [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	output [DRAM_IO_WIDTH-1:0] data_to_dram;
	output [DRAM_MASK_WIDTH-1:0] dram_data_mask;
	output release_dram;
	output dram_request;
	output [GC_COMMAND_WIDTH-1:0] gc_command_fifo_in;
	output gc_command_fifo_in_en;
	input	data_to_dram_ready;
	output	data_to_dram_en;
	output	data_to_dram_end;	
	
	reg dram_en;
	reg dram_read_or_write;
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	reg [DRAM_IO_WIDTH-1:0] data_to_dram;
	reg [DRAM_MASK_WIDTH-1:0] dram_data_mask;
	reg data_to_dram_en;
	reg data_to_dram_end;
	reg release_dram;
	reg dram_request;
	reg [GC_COMMAND_WIDTH-1:0] gc_command_fifo_in;
	reg gc_command_fifo_in_en;		

	//reg [16:0] gc_pointer;      //512GB容量有2的17次方个block
	reg [2:0]	channel_pointer;   //8个通道   将原来的gc_pointer分为channel_pointer和各个通道的gc_pointer
	reg [13:0] 	gc_pointer;      //每个通道有64GB容量，有2的14次方个block
	reg [111:0] 	gc_pointer_buf;      //每个通道即将要检查的偏移量   8*14=112
	reg [6:0] 	gc_threshold;			//进行垃圾回收的下限值，当该值大时flash空间的利用率高
	reg [31:0] 	logical_addr;
	reg [31:0] 	dram_addr;
	reg [4:0] 	state;
	reg [4:0] 	state_buf;	
	reg [511:0]	data_from_dram_buf;
	reg [7:0] 	garbage_in_a_block;
	reg [511:0]	p2l_entries;
	reg [7:0]	offset_in_block;//一个block有256个页
	reg [20:0]	count;

	always@(negedge reset or posedge clk)
	begin
		if(!reset)
		begin
			dram_en 			<= 0;
			dram_read_or_write 		<= 0;
			addr_to_dram 			<= 0;
			data_to_dram 			<= 0;
			dram_data_mask 			<= 0;
			release_dram 			<= 0;
			dram_request 			<= 0;
			gc_command_fifo_in 		<= 0;
			gc_command_fifo_in_en 		<= 0;	
			offset_in_block <= 0;
			
			channel_pointer 		<= 0;
			gc_pointer 			<= 0;      //the width of the register should be reconsidered
			gc_pointer_buf			<= 0;
			gc_threshold 			<= 64;
			logical_addr			<= 0;
			dram_addr 			<= 0;
			data_to_dram_en	                <= 0;
			data_to_dram_end                <= 0;
			state 				<= WAIT_FOR_INIT_DONE;
			count				<= 0;
		end
		else
		begin
			case (state)
				WAIT_FOR_INIT_DONE://0
				begin
					if(count[20])
					begin
						state<=WAIT_FOR_INIT_DONE;
						count<=0;
					end
					else
						count<=count+1;
				end
				IDLE://1
				begin
					if(left_capacity < VERY_ERGENT_GC_TRIGGER)
					begin
						gc_threshold <= 0;
						state <= NEED_TO_GC;
					end
					else if(left_capacity < ERGENT_GC_TRIGGER)
					begin
						gc_threshold <= 10;
						state <= NEED_TO_GC;
					end
					else if(left_capacity < GC_TRIGGER)
					begin
						gc_threshold <= 64;
						state <= NEED_TO_GC;
					end
					else
						state <= IDLE;
				end
				NEED_TO_GC://2
				begin
					case(channel_pointer)
						3'b000: 
						begin
							gc_pointer <= gc_pointer_buf[13:0];
							gc_pointer_buf[13:0]<=gc_pointer_buf[13:0]+16;
						end
						3'b001: 
						begin
							gc_pointer <= gc_pointer_buf[27:14];
							gc_pointer_buf[27:14]<=gc_pointer_buf[27:14]+16;
						end
						3'b010: 
						begin
							gc_pointer <= gc_pointer_buf[41:28];
							gc_pointer_buf[41:28]<=gc_pointer_buf[41:28]+16;
						end
						3'b011: 
						begin
							gc_pointer <= gc_pointer_buf[55:42];
							gc_pointer_buf[55:42]<=gc_pointer_buf[55:42]+16;
						end
						3'b100:
						begin
							gc_pointer <= gc_pointer_buf[69:56];
							gc_pointer_buf[69:56]<=gc_pointer_buf[69:56]+16;
						end
						3'b101:
						begin
							gc_pointer <= gc_pointer_buf[83:70];
							gc_pointer_buf[83:70]<=gc_pointer_buf[83:70]+16;
						end
						3'b110: 
						begin
							gc_pointer <= gc_pointer_buf[97:84];
							gc_pointer_buf[97:84]<=gc_pointer_buf[97:84]+16;
						end
						3'b111:
						begin
							gc_pointer <= gc_pointer_buf[111:98];
							gc_pointer_buf[111:98]<=gc_pointer_buf[111:98]+16;
						end
					endcase		
					state<=APPLY_FOR_DRAM;
				end
				APPLY_FOR_DRAM://3
				begin
					if(gc_command_fifo_prog_full == 1'b0)
					begin
						dram_request <= 1;
						state <= WAIT_FOR_DRAM;
					end	
					else state <= APPLY_FOR_DRAM;
				end
				WAIT_FOR_DRAM://4
				begin
					if(dram_permit==1)
					begin
						dram_request <= 0;
						dram_en <= 1;
						dram_read_or_write <= 1;//read dram
						dram_addr <= GARBAGE_TABLE_BASE + {channel_pointer,gc_pointer[13:4], 3'b000};
						state <= SCAN_GARBAGE_TABLE;
					end
					else state <= WAIT_FOR_DRAM;
				end
				SCAN_GARBAGE_TABLE://5
				begin
					if(dram_ready)
					begin
						dram_en <= 0;
						state <= RECEIVE_GARBAGE_FROM_DRAM0;
					end
					else 
                        state <= SCAN_GARBAGE_TABLE;
				end
				RECEIVE_GARBAGE_FROM_DRAM0://6
				begin
					if(rd_data_valid)
					begin
						data_from_dram_buf[DRAM_IO_WIDTH-1:0] <= data_from_dram;
						state <= RECEIVE_GARBAGE_FROM_DRAM1;
					end
					else 
                        state <= RECEIVE_GARBAGE_FROM_DRAM0;
				end
				RECEIVE_GARBAGE_FROM_DRAM1://7
				begin
					if(rd_data_valid)
					begin
						data_from_dram_buf[511:256] <= data_from_dram;
						state <= CHOOSE_BLOCK;
					end
					else 
						state <= RECEIVE_GARBAGE_FROM_DRAM1;
				end
				CHOOSE_BLOCK://8
				begin
					case (gc_pointer[3:0])
						4'b0000: garbage_in_a_block <= data_from_dram_buf[7:0];
						4'b0001: garbage_in_a_block <= data_from_dram_buf[39:32];
						4'b0010: garbage_in_a_block <= data_from_dram_buf[71:64];
						4'b0011: garbage_in_a_block <= data_from_dram_buf[103:96];
						4'b0100: garbage_in_a_block <= data_from_dram_buf[135:128];
						4'b0101: garbage_in_a_block <= data_from_dram_buf[167:160];
						4'b0110: garbage_in_a_block <= data_from_dram_buf[199:192];
						4'b0111: garbage_in_a_block <= data_from_dram_buf[231:224];	
						4'b1000: garbage_in_a_block <= data_from_dram_buf[263:256];
						4'b1001: garbage_in_a_block <= data_from_dram_buf[295:288];
						4'b1010: garbage_in_a_block <= data_from_dram_buf[327:320];
						4'b1011: garbage_in_a_block <= data_from_dram_buf[359:352];
						4'b1100: garbage_in_a_block <= data_from_dram_buf[391:384];
						4'b1101: garbage_in_a_block <= data_from_dram_buf[423:416];
						4'b1110: garbage_in_a_block <= data_from_dram_buf[455:448];
						4'b1111: garbage_in_a_block <= data_from_dram_buf[487:480];
					endcase
					state <= CHECK_GARBAGE;
				end
				CHECK_GARBAGE://9
				begin
					if(garbage_in_a_block > gc_threshold) // gc_threshold==64
					begin
						offset_in_block <= 0;
						dram_en <= 1;
						dram_read_or_write <= 1; //read
						addr_to_dram <= P2L_TABLE_BASE + {channel_pointer,gc_pointer[13:0], offset_in_block[7:4], 3'b000};
						state <= SCAN_P2L;
					end
					else if(gc_pointer[3:0]==4'b1111)
					begin
						gc_pointer<=gc_pointer+1;
						state <= UNLOCK_DRAM;
					end
					else
					begin
						gc_pointer<=gc_pointer+1;
						state <= CHOOSE_BLOCK;
					end					
				end				
				SCAN_P2L://0a
				begin
					if(dram_ready)
					begin
						dram_en <= 0;
						state <= RECEIVE_DATA_FROM_DRAM0;
					end
					else 
						state <= SCAN_P2L;
				end				
				RECEIVE_DATA_FROM_DRAM0://0b
				begin
					if(rd_data_valid)
					begin
						p2l_entries[DRAM_IO_WIDTH-1:0] <= data_from_dram;
						state <= RECEIVE_DATA_FROM_DRAM1;
					end
					else state <= RECEIVE_DATA_FROM_DRAM0;
				end
				RECEIVE_DATA_FROM_DRAM1://0c
				begin
					if(rd_data_valid)
					begin
						p2l_entries[511:256] <= data_from_dram;
						state <= GET_LOGICAL_ADDR;
					end
					else state <= RECEIVE_DATA_FROM_DRAM1;
				end
				GET_LOGICAL_ADDR://0d
				begin
					case (offset_in_block[3:0])
						4'b0000: logical_addr <= p2l_entries[31:0];
						4'b0001: logical_addr <= p2l_entries[63:32];
						4'b0010: logical_addr <= p2l_entries[95:64];
						4'b0011: logical_addr <= p2l_entries[127:96];
						4'b0100: logical_addr <= p2l_entries[159:128];
						4'b0101: logical_addr <= p2l_entries[191:160];
						4'b0110: logical_addr <= p2l_entries[223:192];
						4'b0111: logical_addr <= p2l_entries[255:224];
						4'b1000: logical_addr <= p2l_entries[287:256];
						4'b1001: logical_addr <= p2l_entries[319:288];
						4'b1010: logical_addr <= p2l_entries[351:320];
						4'b1011: logical_addr <= p2l_entries[383:352];
						4'b1100: logical_addr <= p2l_entries[415:384];
						4'b1101: logical_addr <= p2l_entries[447:416];
						4'b1110: logical_addr <= p2l_entries[479:448];
						4'b1111: logical_addr <= p2l_entries[511:480];
					endcase
					state <= CHECK_LOGICAL_ADDR;
				end
				CHECK_LOGICAL_ADDR://0e
				begin
					if(logical_addr==32'b11111111_11111111_11111111_11111111)  //invalid page
					begin
						if(offset_in_block>=PAGE_PER_BLOCK-1)			 //the last page in a block
							state <= GENERATE_ERASE_COMMAND;
						else
						begin
							offset_in_block <= offset_in_block + 1;
							state <= CHECK_OFFSET_IN_BLOCK;
						end
					end
					else
					begin	
						offset_in_block <= offset_in_block + 1;
						state <= GENERATE_MOVE_COMMAND;
					end
				end				
				GENERATE_MOVE_COMMAND://0f
				begin
					gc_command_fifo_in <= {1'b0, logical_addr[27:0]};
					gc_command_fifo_in_en <= 1;
					state <= SEND_MOVE_COMMAND;
				end
				SEND_MOVE_COMMAND://10
				begin
					gc_command_fifo_in_en <= 0;
					if(offset_in_block>=PAGE_PER_BLOCK-1)
						state <= GENERATE_ERASE_COMMAND;
					else
					begin						
						state <= CHECK_OFFSET_IN_BLOCK;
					end				
				end				
				CHECK_OFFSET_IN_BLOCK://11
				begin
					if(offset_in_block[3:0]==4'b0000)//当一次取回来的16个p2l表判断完毕，则取下16个表数据
					begin
						dram_en <= 1;
						dram_read_or_write <= 1; //read
						addr_to_dram <= P2L_TABLE_BASE + {channel_pointer,gc_pointer[13:0], offset_in_block[7:4], 3'b000};
						state <= SCAN_P2L;
					end
					else
						state <= GET_LOGICAL_ADDR;
				end				
				GENERATE_ERASE_COMMAND://12
				begin
					gc_command_fifo_in <= {1'b1, 3'b000,channel_pointer,gc_pointer[13:0], 8'b00000000};
					gc_command_fifo_in_en <= 1;
					state <= SEND_ERASE_COMMAND;
				end
				SEND_ERASE_COMMAND://13
				begin
					gc_command_fifo_in_en <= 0;
					if(gc_pointer[3:0]==4'b1111)
					begin
						gc_pointer<=gc_pointer+1;
						state <= UNLOCK_DRAM;						
					end
					else
					begin
						gc_pointer <= gc_pointer + 1;//查看下一block
						state <= CHOOSE_BLOCK;
					end
				end	
				UNLOCK_DRAM://14
				begin
					channel_pointer<=channel_pointer+1;//通道数加1，在8个通道循环产生的垃圾回收命令
					release_dram <= 1;
					state <= FINISH;
				end			
				FINISH://1f
				begin
					release_dram <= 0;
					state <= IDLE;
				end	
				default: 
					state <= IDLE;
			endcase
		end
	end
endmodule
