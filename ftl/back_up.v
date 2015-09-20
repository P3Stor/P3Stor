module backup#(
		parameter PHYSICAL_ADDR_WIDTH		= 25,  //flash capacity 16KB*2^25 = 2^39B = 512GB
		parameter DRAM_IO_WIDTH   		= 256, //DRAM IO
		parameter DRAM_ADDR_WIDTH 		= 29,  //DRAM cacacity  64bits(2^3B)*2^29=2^32B = 4GB
		parameter DRAM_MASK_WIDTH 		= 32,  //8bits/mask bit  256/8 = 32
		parameter COMMAND_WIDTH 		= 128, //
		parameter GC_COMMAND_WIDTH 		= 29,  //
		parameter CACHE_ADDR_WIDTH 		= 17,  //cache space 16KB*2^17=2^31B=2GB
		parameter L2P_TABLE_BASE		= 29'b00000_00000000_00000000_00000000, //32bits*2^25=2^27B=128MB
		parameter P2L_TABLE_BASE		= 29'b00001_00000000_00000000_00000000, //32bits*2^25=2^27B=128MB
		parameter FREE_BLOCK_FIFO_BASE		= 29'b00010_00000000_00000000_00000000, //32bits*2^17=2^ram_do=512KB
		parameter GARBAGE_TABLE_BASE		= 29'b00010_00000001_00000000_00000000, //32bits*2^17=2^ram_do=512KB
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
	)(
	reset,
	clk,	
	dram_backup_en,	
	backup_op,
	fifo_enpty_flag,
	state_check,
	//与DRAM的交互接口
	dram_permit,
	data_from_dram,
	dram_ready,	
	rd_data_valid,	
	
	//需要备份的寄存器
	left_capacity_final,
	free_block_fifo_tails,
	free_block_fifo_heads,
	
	ssd_command_fifo_full,
	controller_command_fifo_full_or_not,
	write_data_fifo_prog_full,//8 bit
	write_data_fifo_full,
	 
	 //Output 
	dram_request,
	release_dram,
	addr_to_dram,
	data_to_dram,
	dram_data_mask,
	dram_en,
	dram_read_or_write,
	
	ssd_command_fifo_in,
	ssd_command_fifo_in_en,
	controller_command_fifo_in_en,
	controller_command_fifo_in,
	write_data_fifo_in,
	write_data_fifo_in_en,//8 bit
	backup_or_checkcache,
	backup_or_io
	//state
	);	
	input reset;
	input clk;
	input dram_backup_en;
	input [1:0]backup_op;// 1)flush 2'b10    2)backup dram 2'b11
	input fifo_enpty_flag;
	input state_check;
	input dram_permit;
	input [DRAM_IO_WIDTH-1:0] data_from_dram;	
	input dram_ready;	
	input rd_data_valid;
	input [18:0]left_capacity_final;//512GB flash有2的17次方个块
	input [127:0] free_block_fifo_tails;
	input [127:0] free_block_fifo_heads;
	input ssd_command_fifo_full;
	input controller_command_fifo_full_or_not;
	input write_data_fifo_prog_full;//8 bit
	input write_data_fifo_full;
	
	output dram_request;
	output release_dram;
	output [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	output [DRAM_IO_WIDTH-1:0]data_to_dram;
	output [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	output dram_en;	
	output dram_read_or_write;	
	output [COMMAND_WIDTH-1:0]ssd_command_fifo_in;
	output ssd_command_fifo_in_en;
	output [7:0]controller_command_fifo_in_en;
	output [COMMAND_WIDTH-1:0]controller_command_fifo_in;
	output [DRAM_IO_WIDTH-1:0]write_data_fifo_in;
	output [7:0]write_data_fifo_in_en;//8 bit	
	output	backup_or_checkcache;
	output backup_or_io;
	//output [5:0] state;
	
	reg dram_request;
	reg release_dram;
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	reg [DRAM_IO_WIDTH-1:0]data_to_dram;
	reg [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	reg dram_en;
	reg dram_read_or_write;
	
	reg [COMMAND_WIDTH-1:0]ssd_command_fifo_in;
	reg ssd_command_fifo_in_en;
	reg [7:0]controller_command_fifo_in_en;
	reg [COMMAND_WIDTH-1:0]controller_command_fifo_in;
	reg [DRAM_IO_WIDTH-1:0]write_data_fifo_in;
	reg [7:0]write_data_fifo_in_en;//8 bit	
	reg	backup_or_checkcache;
	reg backup_or_io;
	
	
	parameter IDLE					=6'b000000;
	parameter WAIT_FOR_A_WHILE			=6'b000001;
	parameter APPLY_DRAM				=6'b000010;
	parameter WAIT_FOR_DRAM				=6'b000011;
	parameter GET_ENTRY				=6'b000100;
	parameter RECEIVE_ENTRY0			=6'b000101;
	parameter RECEIVE_ENTRY1			=6'b000110;
	parameter CHECK_DIRTY0				=6'b000111;
	parameter CHECK_DIRTY1				=6'b001000;	
	parameter SEND_SSD_COMMAND			=6'b001001;
	parameter CHECK_INDEX				=6'b001010;	
	parameter WRITE_ENTRY_BACK0			=6'b001011;
	parameter WRITE_ENTRY_BACK1			=6'b001100;	
	parameter WRITE_ENTRY_BACK2			=6'b001101;
	parameter CHECK_CACHE_ENTRY_ADDR		=6'b001110;
	parameter ERASE_FLASH0				=6'b001111;
	parameter ERASE_FLASH1				=6'b010000;
	parameter ERASE_FLASH2				=6'b010001;
	parameter ERASE_FLASH3				=6'b010010;
	parameter ERASE_FLASH4				=6'b010011;
	parameter READY_FOR_WRITE_L2P			=6'b010100;
	parameter WRITE_BACK_L2P0			=6'b010101;
	parameter WRITE_BACK_L2P1			=6'b010110;
	parameter WRITE_BACK_L2P2			=6'b010111;
	parameter WRITE_BACK_L2P3			=6'b011000;
	parameter CHECK_L2P_CACHE_ADDR			=6'b011001;
	parameter READY_FOR_WRITE_P2L			=6'b011010;
	parameter WRITE_BACK_P2L0			=6'b011011;
	parameter WRITE_BACK_P2L1			=6'b011100;
	parameter WRITE_BACK_P2L2			=6'b011101;
	parameter WRITE_BACK_P2L3			=6'b011110;
	parameter CHECK_P2L_CACHE_ADDR			=6'b011111;
	parameter READY_FOR_FREE_BLOCK_FIFO		=6'b100000;
	parameter WRITE_BACK_FREE_BLOCK_FIFO0		=6'b100001;
	parameter WRITE_BACK_FREE_BLOCK_FIFO1		=6'b100010;
	parameter WRITE_BACK_FREE_BLOCK_FIFO2		=6'b100011;
	parameter WRITE_BACK_FREE_BLOCK_FIFO3		=6'b100100;
	parameter CHECK_FREE_BLOCK_CACHE_ADDR		=6'b100101;
	parameter READY_FOR_GARBAGE_TABLE		=6'b100110;
	parameter WRITE_BACK_GARBAGE_TABLE0		=6'b100111;
	parameter WRITE_BACK_GARBAGE_TABLE1		=6'b101000;
	parameter WRITE_BACK_GARBAGE_TABLE2		=6'b101001;
	parameter WRITE_BACK_GARBAGE_TABLE3		=6'b101010;
	parameter CHECK_FREE_GARBAGE_ADDR		=6'b101011;
	parameter UNLOCK_DRAM_FOR_A_WHILE		=6'b101100;
	parameter WAIT_DRAM_FOR_A_WHILE			=6'b101101;
	parameter CHANCG_TO_STATE_BUF			=6'b101110;
	parameter UNLOCK_DRAM				=6'b101111;
	parameter CHECK_ENPTY_FLAG0			=6'b110000;
	parameter CHECK_ENPTY_FLAG1			=6'b110001;
	parameter CHECK_ENPTY_FLAG2			=6'b110010;
	parameter READY_FOR_WRITE_REG			=6'b110011;
	parameter WRITE_BACK_REG0			=6'b110100;
	parameter WRITE_BACK_REG1			=6'b110101;
	parameter WRITE_BACK_REG2			=6'b110110;
	parameter WRITE_BACK_REG3			=6'b110111;
	parameter CHECK_REG_ENTRY			=6'b111000;
	parameter FINISH				=6'b111111; 	

	reg [5:0]state;
	reg [5:0]state_buf;
	reg [11:0]count;
	reg [9:0]count_read;
	reg [3:0]index;
	reg [2:0]channel_index;
	reg [7:0]enable;
	reg [DRAM_ADDR_WIDTH-1:0]dram_addr;
	reg [21:0]paddr;
	reg [511:0]data_from_dram_buf;
	reg [27:0]logical_addr;
	
	reg [15:0]cache_entry_addr;//2GB/16KB= 2的17次方个16Kb dram一个地址可以记录两个cache_entry，用16位地址就可以表示cache_entry
	
	always@ (negedge reset or posedge clk)
	begin
		if(!reset)
		begin
			dram_request<=0;
			release_dram<=0;
			addr_to_dram<=0;
			data_to_dram<=0;
			dram_data_mask<=0;
			dram_en<=0;
			dram_read_or_write<=0;
			ssd_command_fifo_in<=0;
			ssd_command_fifo_in_en<=0;
			controller_command_fifo_in_en<=0;
			controller_command_fifo_in<=0;
			write_data_fifo_in<=0;
			write_data_fifo_in_en<=0;//8 bit
			backup_or_checkcache<=0;
			backup_or_io<=0;
			state<=IDLE;
			state_buf<=0;
			count<=0;
			count_read<=0;
			index<=0;
			channel_index<=0;
			enable<=0;
			dram_addr<=0;
			paddr<=0;
			data_from_dram_buf<=0;
			logical_addr<=0;
			cache_entry_addr<=0;
			
		end
		else
		begin
			case (state)
				IDLE://00
				begin
					if(dram_backup_en)
					begin
						state_buf<=ERASE_FLASH0;
						state<=CHECK_ENPTY_FLAG0;
					end
					else
						state<=IDLE;
				end
				//step 2 erase flash
				ERASE_FLASH0://0f
				begin	
					channel_index<=0;
					paddr<=22'b000000_00000000_00000000;//22'b111111_11110000_00000000;
					state<=ERASE_FLASH1;
				end
				ERASE_FLASH1://10
				begin
					case(channel_index)
						3'b000:
							enable<=8'b00000001;
						3'b001:
							enable<=8'b00000010;
						3'b010:
							enable<=8'b00000100;
						3'b011:
							enable<=8'b00001000;
						3'b100:
							enable<=8'b00010000;
						3'b101:
							enable<=8'b00100000;
						3'b110:
							enable<=8'b01000000;
						3'b111:
							enable<=8'b10000000;
					endcase
					state<=ERASE_FLASH2;
				end
				ERASE_FLASH2://11
				begin
					if(channel_index==3'b111)
					begin
						if(controller_command_fifo_full_or_not == 1'b0)
						begin
							controller_command_fifo_in<= {ERASE, 101'b0,channel_index,paddr};//2+104+22=128
							controller_command_fifo_in_en<=enable;
							channel_index<=channel_index+1;			
							state<=ERASE_FLASH3;
							paddr<=paddr+256;//one block have 256 pages	
						end
					end
					else
					begin
						if(controller_command_fifo_full_or_not == 1'b0)
						begin
							controller_command_fifo_in<= {ERASE, 101'b0,channel_index,paddr};//2+104+22=128
							controller_command_fifo_in_en<=enable;
							channel_index<=channel_index+1;			
							state<=ERASE_FLASH1;
						end
						//paddr<=22'b111111_11110000_00000000;
					end	

				end
				ERASE_FLASH3://12 check channel_index
				begin	
					controller_command_fifo_in_en<=8'b00000000;
					if(paddr==22'b0)//每个通道发送16个erase命令，共擦除128个block
					begin
						state<=CHECK_ENPTY_FLAG0;
						state_buf<=APPLY_DRAM;
					end
					else
					begin						
						state<=ERASE_FLASH1;
					end					
				end
				APPLY_DRAM://02
				begin
					dram_request <= 1;
					state<=WAIT_FOR_DRAM;
				end
				WAIT_FOR_DRAM://03
				begin
					if(dram_permit==1)
					begin
						dram_request <= 0;
						state <= GET_ENTRY;
						dram_en <= 1;
						dram_read_or_write <= 1;//read
						cache_entry_addr<=0;
					end
					else
						state<=WAIT_FOR_DRAM;
				end
				//step1 write back dirty data
				GET_ENTRY://04
				begin	
					if(dram_ready)
					begin
						addr_to_dram <= cache_entry_addr + CACHE_ENTRY_BASE; 
						dram_en <= 0;
						dram_read_or_write <= 1;//read						
						state <= RECEIVE_ENTRY0;		
					end
					else
					begin
						state <= GET_ENTRY;
					end
				end
				RECEIVE_ENTRY0: //05 
				begin
					dram_en <= 0;
					if(rd_data_valid)
					begin
						state <= RECEIVE_ENTRY1;
						data_from_dram_buf[255:0]<=data_from_dram;						
					end
					else
						state <= RECEIVE_ENTRY0;	
				end
				RECEIVE_ENTRY1: //06  
				begin					
					if(rd_data_valid)
					begin	
						state <= CHECK_DIRTY0;
						index<=0;
						data_from_dram_buf[511:256]<=data_from_dram;	
					end
					else
						state <= RECEIVE_ENTRY1;	
				end
				CHECK_DIRTY0://7
				begin
					if(data_from_dram_buf[30] | data_from_dram_buf[62] | data_from_dram_buf[94] | data_from_dram_buf[126] | 
					   data_from_dram_buf[158] | data_from_dram_buf[190] | data_from_dram_buf[222] | data_from_dram_buf[254] | 
					   data_from_dram_buf[286] | data_from_dram_buf[318] | data_from_dram_buf[350] | data_from_dram_buf[382] | 
					   data_from_dram_buf[414] | data_from_dram_buf[446] | data_from_dram_buf[478] | data_from_dram_buf[510])
					begin
						state<=CHECK_DIRTY1;//有脏数据，需要替换
					end
					else//无脏数据，取下一组表
					begin
						cache_entry_addr<=cache_entry_addr+8;//每次可以取512bit，对应8个dram偏移地址
						state<=CHECK_CACHE_ENTRY_ADDR;
					end
				end
				CHECK_DIRTY1://08
				begin
					case(index)
						4'b0000:
						begin
							if(data_from_dram_buf[30])//dirty
							begin
								data_from_dram_buf[29] <= 1;//locked ,等待数据写回flash，避免数据丢失
								data_from_dram_buf[30] <= 0;
								logical_addr <= data_from_dram_buf[27:0];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0001:
						begin
							if(data_from_dram_buf[62])
							begin
								data_from_dram_buf[61] <= 1;
								data_from_dram_buf[62] <= 0;
								logical_addr <= data_from_dram_buf[59:32];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0010:
						begin
							if(data_from_dram_buf[94])
							begin
								data_from_dram_buf[93] <= 1;
								data_from_dram_buf[94] <= 0;
								logical_addr <= data_from_dram_buf[91:64];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0011:
						begin
							if(data_from_dram_buf[126])
							begin
								data_from_dram_buf[125] <= 1;
								data_from_dram_buf[126] <= 0;
								logical_addr <= data_from_dram_buf[123:96];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0100:
						begin
							if(data_from_dram_buf[158])
							begin
								data_from_dram_buf[157] <= 1;
								data_from_dram_buf[158] <= 0;
								logical_addr <= data_from_dram_buf[155:128];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0101:
						begin
							if(data_from_dram_buf[190])
							begin
								data_from_dram_buf[189] <= 1;
								data_from_dram_buf[190] <= 0;
								logical_addr <= data_from_dram_buf[187:160];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0110:
						begin
							if(data_from_dram_buf[222])
							begin
								data_from_dram_buf[221] <= 1;
								data_from_dram_buf[222] <= 0;
								logical_addr <= data_from_dram_buf[219:192];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b0111:
						begin
							if(data_from_dram_buf[254])
							begin
								data_from_dram_buf[253] <= 1;
								data_from_dram_buf[254] <= 0;
								logical_addr <= data_from_dram_buf[251:224];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1000:
						begin
							if(data_from_dram_buf[286])
							begin
								data_from_dram_buf[285] <= 1;
								data_from_dram_buf[286] <= 0;
								logical_addr <= data_from_dram_buf[283:256];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1001:
						begin
							if(data_from_dram_buf[318])
							begin
								data_from_dram_buf[317] <= 1;
								data_from_dram_buf[318] <= 0;
								logical_addr <= data_from_dram_buf[315:288];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1010:
						begin
							if(data_from_dram_buf[350])
							begin
								data_from_dram_buf[349] <= 1;
								data_from_dram_buf[350] <= 0;
								logical_addr <= data_from_dram_buf[347:320];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1011:
						begin
							if(data_from_dram_buf[382])
							begin
								data_from_dram_buf[381] <= 1;
								data_from_dram_buf[382] <= 0;
								logical_addr <= data_from_dram_buf[379:352];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1100:
						begin
							if(data_from_dram_buf[414])
							begin
								data_from_dram_buf[413] <= 1;
								data_from_dram_buf[414] <= 0;
								logical_addr <= data_from_dram_buf[411:384];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1101:
						begin
							if(data_from_dram_buf[446])
							begin
								data_from_dram_buf[445] <= 1;
								data_from_dram_buf[446] <= 0;
								logical_addr <= data_from_dram_buf[443:416];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1110:
						begin
							if(data_from_dram_buf[478])
							begin
								data_from_dram_buf[477] <= 1;
								data_from_dram_buf[478] <= 0;
								logical_addr <= data_from_dram_buf[475:448];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin
								state<=CHECK_DIRTY1;
							end
						end
						4'b1111:
						begin
							if(data_from_dram_buf[510])
							begin
								data_from_dram_buf[509] <= 1;
								data_from_dram_buf[510] <= 0;
								logical_addr <= data_from_dram_buf[507:480];
								state<=SEND_SSD_COMMAND;
							end
							else
							begin	
								state<=WRITE_ENTRY_BACK0;//last one
								dram_en<= 1;
								dram_read_or_write <= 0;//write
							end
						end
					endcase
					index<=index+1;
				end
				SEND_SSD_COMMAND://09
				begin
					if(ssd_command_fifo_full==1'b0)
					begin
						ssd_command_fifo_in_en <= 1;
						ssd_command_fifo_in <= {2'b01,1'b1,93'b0,4'b0000,logical_addr};
						state<=CHECK_INDEX;
					end
					else
					begin
						state<=UNLOCK_DRAM_FOR_A_WHILE;
						state_buf<=SEND_SSD_COMMAND;
					end
				end
				CHECK_INDEX://a
				begin
					ssd_command_fifo_in_en <= 0;
					if(index==4'b0000)
					begin
						state<=WRITE_ENTRY_BACK0;
						dram_en<= 1;
						dram_read_or_write <= 0;//write
					end
					else
						state<=CHECK_DIRTY1;
				end
				WRITE_ENTRY_BACK0://b  unlock
				begin
					index<=0;
					if(dram_ready)
					begin
						dram_en<= 0;
						dram_read_or_write <= 0;//write
						addr_to_dram <= cache_entry_addr + CACHE_ENTRY_BASE;
						data_to_dram <= data_from_dram_buf[255:0];
						dram_data_mask<=0;//mask
						state <= WRITE_ENTRY_BACK1;
					end
					else
						state <= WRITE_ENTRY_BACK0;
				end
				WRITE_ENTRY_BACK1:  //c
				begin
					data_to_dram <=data_from_dram_buf[511:256];
					dram_data_mask<=0;
					if(count>=2)
					begin
						count<=0;
						state <= CHECK_CACHE_ENTRY_ADDR;
					end
					else
					begin
						count<=count+1;	
						state<=WRITE_ENTRY_BACK1;
					end
				end
				CHECK_CACHE_ENTRY_ADDR://0e
				begin
					if(cache_entry_addr==16'h0000)
					begin
						state_buf<=READY_FOR_WRITE_L2P;
						state<=CHECK_ENPTY_FLAG0;
						release_dram <= 1;
					end
					else
					begin
						state <= GET_ENTRY;
						dram_en <= 1;
						dram_read_or_write <= 1;//read
					end
				end	
				//step3 write back L2P table
				READY_FOR_WRITE_L2P://14 等待擦除操作全部完成，再写回table
				begin						
					dram_addr<=L2P_TABLE_BASE;
					channel_index<=0;
					count <= 0;
					count_read <= 0;
					paddr<=L2P_TABLE_BASE_FLASH;//l2p flash base address
					state<=WRITE_BACK_L2P0;
				end				
				WRITE_BACK_L2P0://15
				begin					
					if(!write_data_fifo_prog_full & !controller_command_fifo_full_or_not)
					begin
						state <= WRITE_BACK_L2P1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
					end
					else
					begin
						backup_or_io<=0;
						state<=UNLOCK_DRAM_FOR_A_WHILE;
						state_buf<=WRITE_BACK_L2P0;
					end
					case(channel_index)
						3'b000:
							enable<=8'b00000001;
						3'b001:
							enable<=8'b00000010;
						3'b010:
							enable<=8'b00000100;
						3'b011:
							enable<=8'b00001000;
						3'b100:
							enable<=8'b00010000;
						3'b101:
							enable<=8'b00100000;
						3'b110:
							enable<=8'b01000000;
						3'b111:
							enable<=8'b10000000;
					endcase
				end
				WRITE_BACK_L2P1://16 
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据	
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end
					if(dram_ready)
					begin						
						addr_to_dram <=dram_addr; 						
						dram_en <=0;
						count<=count+1;//计数发送多少个读命令
						dram_read_or_write <= 1;//read						
						state <= WRITE_BACK_L2P2;
					end
					else
					begin
						state<=WRITE_BACK_L2P1;
					end
				end
				WRITE_BACK_L2P2://17  
				begin
					dram_en <= 0;					
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					dram_addr<=dram_addr+8;//8个64位数据等于512位数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end
					if(count>=256)//发送256次读命令，256*512b=16KB，为一页大小
					begin
						state <= WRITE_BACK_L2P3;
						count<=0;
					end
					else
					begin
						state <= WRITE_BACK_L2P1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
					end
				end
				WRITE_BACK_L2P3: //18 
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count_read>=512)//读512次256b的数据
					begin							
						count_read<=0;
						controller_command_fifo_in<= {WRITE, 37'b0, channel_index,paddr,64'b0};
						controller_command_fifo_in_en<=enable;
						channel_index<=channel_index+1;//send to next channel
						state <= CHECK_L2P_CACHE_ADDR;//
					end
					else
					begin
						state<=WRITE_BACK_L2P3;
					end
				end
				CHECK_L2P_CACHE_ADDR://19
				begin
					controller_command_fifo_in_en<=0;					
					if(channel_index==3'b0)
						paddr<=paddr+1; //512*256b=16KB(一页)
					else begin end
					if(dram_addr[23:0]==24'h000000)//L2P table write back done
					begin
						state_buf<=READY_FOR_WRITE_P2L;
						state<=CHECK_ENPTY_FLAG0;
					end
					else
						state<=WRITE_BACK_L2P0;
				end
				//step4 write back P2L table
				READY_FOR_WRITE_P2L://1a 等待擦除操作全部完成，再写回table
				begin						
					dram_addr<=P2L_TABLE_BASE;
					channel_index<=0;
					count <= 0;
					count_read <= 0;
					paddr<=P2L_TABLE_BASE_FLASH;//p2l flash base address  128M=8k pages,平均每个通道1k，即2^10
					state<=WRITE_BACK_P2L0;
				end	
				WRITE_BACK_P2L0://1b
				begin
					if(!write_data_fifo_prog_full & !controller_command_fifo_full_or_not)
					begin
						state <= WRITE_BACK_P2L1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read
					end
					else
					begin
						state<=UNLOCK_DRAM_FOR_A_WHILE;
						state_buf<=WRITE_BACK_P2L0;
					end
					case(channel_index)
						3'b000:
							enable<=8'b00000001;
						3'b001:
							enable<=8'b00000010;
						3'b010:
							enable<=8'b00000100;
						3'b011:
							enable<=8'b00001000;
						3'b100:
							enable<=8'b00010000;
						3'b101:
							enable<=8'b00100000;
						3'b110:
							enable<=8'b01000000;
						3'b111:
							enable<=8'b10000000;
					endcase
				end
				WRITE_BACK_P2L1://1c
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据	
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(dram_ready)
					begin						
						addr_to_dram <=dram_addr; 						
						dram_en <=0;
						count<=count+1;//计数发送多少个读命令
						dram_read_or_write <= 1;//read						
						state <= WRITE_BACK_P2L2;
					end
					else
					begin
						state<=WRITE_BACK_P2L1;
					end
				end
				WRITE_BACK_P2L2://1d  
				begin
					dram_en <= 0;					
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					dram_addr<=dram_addr+8;//8个64位数据等于512位数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count>=256)//发送256次读命令，256*512b=16KB，为一页大小
					begin
						state <= WRITE_BACK_P2L3;
						count<=0;
					end
					else
					begin
						state <= WRITE_BACK_P2L1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
					end
				end
				WRITE_BACK_P2L3: //1e
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count_read>=512)//读512次256b的数据
					begin										
						state <= CHECK_P2L_CACHE_ADDR;//修改映射表
						count_read<=0;
						controller_command_fifo_in<= {WRITE, 37'b0, channel_index,paddr,64'b0};
						controller_command_fifo_in_en<=enable;
						channel_index<=channel_index+1;//send to next channel
					end
					else
					begin
						state<=WRITE_BACK_P2L3;
					end
				end
				CHECK_P2L_CACHE_ADDR://1f
				begin
					controller_command_fifo_in_en<=8'b0;					
					if(channel_index==3'b0)
						paddr<=paddr+1;
					if(dram_addr[23:0]==24'h000000)//P2L table write back done
					begin
						state<=READY_FOR_FREE_BLOCK_FIFO;
					end
					else
						state<=WRITE_BACK_P2L0;
				end
				//step 5 write back FREE_BLOCK_FIFO table
				READY_FOR_FREE_BLOCK_FIFO://20
				begin
					dram_addr<=FREE_BLOCK_FIFO_BASE;					
					paddr<=FREE_BLOCK_FIFO_BASE_FLASH;//FREE_BLOCK_FIFO flash base address
					count <= 0;
					count_read <= 0;
					channel_index<=0;
					state<=WRITE_BACK_FREE_BLOCK_FIFO0;
				end
				WRITE_BACK_FREE_BLOCK_FIFO0://21
				begin					
					if(!write_data_fifo_prog_full & !controller_command_fifo_full_or_not)
					begin
						state <= WRITE_BACK_FREE_BLOCK_FIFO1;
						dram_read_or_write <= 1;//read
						dram_en <=1;
					end
					else
					begin
						backup_or_io<=0;
						state<=UNLOCK_DRAM_FOR_A_WHILE;
						state_buf<=WRITE_BACK_FREE_BLOCK_FIFO0;
					end
					case(channel_index)
						3'b000:
							enable<=8'b00000001;
						3'b001:
							enable<=8'b00000010;
						3'b010:
							enable<=8'b00000100;
						3'b011:
							enable<=8'b00001000;
						3'b100:
							enable<=8'b00010000;
						3'b101:
							enable<=8'b00100000;
						3'b110:
							enable<=8'b01000000;
						3'b111:
							enable<=8'b10000000;
					endcase
				end
				WRITE_BACK_FREE_BLOCK_FIFO1://22
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据	
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(dram_ready)
					begin						
						addr_to_dram <=dram_addr; 						
						dram_en <=0;
						count<=count+1;//计数发送多少个读命令
						dram_read_or_write <= 1;//read						
						state <= WRITE_BACK_FREE_BLOCK_FIFO2;
					end
					else
					begin
						state<=WRITE_BACK_FREE_BLOCK_FIFO1;
					end
				end
				WRITE_BACK_FREE_BLOCK_FIFO2://23
				begin
					dram_en <= 0;					
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					dram_addr<=dram_addr+8;//8个64位数据等于512位数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count>=256)//发送256次读命令，256*512b=16KB，为一页大小
					begin
						state <= WRITE_BACK_FREE_BLOCK_FIFO3;
						count<=0;
					end
					else
					begin
						state <= WRITE_BACK_FREE_BLOCK_FIFO1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
					end
				end
				WRITE_BACK_FREE_BLOCK_FIFO3: //24 
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count_read>=512)//读512次256b的数据
					begin										
						state <= CHECK_FREE_BLOCK_CACHE_ADDR;//修改映射表
						count_read<=0;
						controller_command_fifo_in<= {WRITE, 37'b0, channel_index,paddr,64'b0};
						controller_command_fifo_in_en<=enable;
						channel_index<=channel_index+1;//send to next channel
					end
					else
					begin
						state<=WRITE_BACK_FREE_BLOCK_FIFO3;
					end
				end
				CHECK_FREE_BLOCK_CACHE_ADDR://25
				begin
					controller_command_fifo_in_en<=8'b0;					
					if(channel_index==3'b0)
						paddr<=paddr+1;
					if(dram_addr[15:0]==16'h000000)//FREE_BLOCK table write back done
					begin
						state<=READY_FOR_GARBAGE_TABLE;
					end
					else
						state<=WRITE_BACK_FREE_BLOCK_FIFO0;
				end
				//step 6 write garbage table
				READY_FOR_GARBAGE_TABLE://26
				begin
					dram_addr<=GARBAGE_TABLE_BASE;					
					paddr<=GARBAGE_TABLE_BASE_FLASH;//garbage table flash base address
					channel_index<=0;
					count <= 0;
					count_read <= 0;
					state<=WRITE_BACK_GARBAGE_TABLE0;
				end				
				WRITE_BACK_GARBAGE_TABLE0://27
				begin					
					if(!write_data_fifo_prog_full & !controller_command_fifo_full_or_not)
					begin
						state <= WRITE_BACK_GARBAGE_TABLE1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
					end
					else
					begin
						state<=UNLOCK_DRAM_FOR_A_WHILE;
						state_buf<=WRITE_BACK_GARBAGE_TABLE0;
					end
					case(channel_index)
						3'b000:
							enable<=8'b00000001;
						3'b001:
							enable<=8'b00000010;
						3'b010:
							enable<=8'b00000100;
						3'b011:
							enable<=8'b00001000;
						3'b100:
							enable<=8'b00010000;
						3'b101:
							enable<=8'b00100000;
						3'b110:
							enable<=8'b01000000;
						3'b111:
							enable<=8'b10000000;
					endcase
				end
				WRITE_BACK_GARBAGE_TABLE1://28 
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据	
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(dram_ready)
					begin						
						addr_to_dram <=dram_addr; 						
						dram_en <=0;
						count<=count+1;//计数发送多少个读命令
						dram_read_or_write <= 1;//read						
						state <= WRITE_BACK_GARBAGE_TABLE2;
					end
					else
					begin
						state<=WRITE_BACK_GARBAGE_TABLE1;
					end
				end
				WRITE_BACK_GARBAGE_TABLE2://29
				begin
					dram_en <= 0;					
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					dram_addr<=dram_addr+8;//8个64位数据等于512位数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count>=256)//发送256次读命令，256*512b=16KB，为一页大小
					begin
						state <= WRITE_BACK_GARBAGE_TABLE3;
						count<=0;
					end
					else
					begin
						state <= WRITE_BACK_GARBAGE_TABLE1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
					end
				end
				WRITE_BACK_GARBAGE_TABLE3: //2a
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					if(rd_data_valid & !write_data_fifo_full)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=data_from_dram;
						count_read<=count_read+1;//计数接收多少个数据
					end
					else begin end 
					if(count_read>=512)//读512次256b的数据
					begin										
						state <= CHECK_FREE_GARBAGE_ADDR;//修改映射表
						count_read<=0;
						controller_command_fifo_in<= {WRITE, 37'b0, channel_index,paddr,64'b0};
						controller_command_fifo_in_en<=enable;
						channel_index<=channel_index+1;//send to next channel
					end
					else
					begin
						state<=WRITE_BACK_GARBAGE_TABLE3;
					end
				end
				CHECK_FREE_GARBAGE_ADDR://2b
				begin
					controller_command_fifo_in_en<=8'b0;					
					if(channel_index==3'b0)
						paddr<=paddr+1;
					if(dram_addr[15:0]==16'h000000)//FREE_BLOCK table write back done
					begin
						state<=READY_FOR_WRITE_REG;
					end
					else
						state<=WRITE_BACK_GARBAGE_TABLE0;
				end				
				// step 7 write back registers
	            		READY_FOR_WRITE_REG	: //33
				begin
					count <=0;
					enable <=8'b00000001;
					paddr <=REGISTER_BASE_FLASH;//register flash base address
					state <=WRITE_BACK_REG0;
				end
	           		WRITE_BACK_REG0:
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据	
					if( !write_data_fifo_full & !controller_command_fifo_full_or_not)
					begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<={left_capacity_final[16:0],free_block_fifo_heads[111:0],free_block_fifo_tails[111:0],15'b111_1111_1111_1111};
						count <=count+1;
						state <=WRITE_BACK_REG1;
					end
					else
					begin
						state<=UNLOCK_DRAM_FOR_A_WHILE;
						state_buf<=WRITE_BACK_REG0;
					end
				end
	           		WRITE_BACK_REG1:
				begin
					write_data_fifo_in_en<=8'b0;//默认不往pcie_data_send_fifo发送数据
					if(count>=512)//读512次256b的数据
					begin										
						state <= UNLOCK_DRAM;
						count<=0;
						controller_command_fifo_in<= {WRITE, 37'b0, 3'b000,paddr,64'b0};
						controller_command_fifo_in_en<=enable;
					end
					else begin
					if(!write_data_fifo_full)begin
						write_data_fifo_in_en<=enable;
						write_data_fifo_in<=0;
						count<=count+1;//计数接收多少个数据
						state<=WRITE_BACK_REG1;
						end
					else state <= WRITE_BACK_REG1;
					end
				end
				UNLOCK_DRAM_FOR_A_WHILE://2c
				begin
					release_dram <= 1;
					count <= 0;
					backup_or_checkcache<=0;
					backup_or_io<=0;
					state <= WAIT_DRAM_FOR_A_WHILE;
				end
				WAIT_DRAM_FOR_A_WHILE://2d
				begin
					release_dram <= 0;
					if(count>=1023)
					begin
						dram_request <= 1;
						count<=0;
						state <= CHANCG_TO_STATE_BUF;						
					end
					else
					begin
						count <= count+1;
						state<=WAIT_DRAM_FOR_A_WHILE;
					end
				end	
				CHANCG_TO_STATE_BUF://2e
				begin
					if(dram_permit)
					begin
						dram_request <= 0;
						backup_or_checkcache<=1;
						backup_or_io<=1;
						state <= state_buf;
					end
					else
						state<=CHANCG_TO_STATE_BUF;
				end
				UNLOCK_DRAM://2f
				begin
					release_dram <= 1;
					controller_command_fifo_in_en <= 0;
					state <= FINISH;
				end
				CHECK_ENPTY_FLAG0://30
				begin
					backup_or_checkcache<=0;
					backup_or_io<=0;
					release_dram <= 0;
					if(fifo_enpty_flag & state_check<=9)
						state<=CHECK_ENPTY_FLAG1;
					else
						state<=CHECK_ENPTY_FLAG0;
				end
				CHECK_ENPTY_FLAG1://31
				begin
					if(count>=8)
					begin
						count<=0;
						if(fifo_enpty_flag & state_check<=9)
						begin
							state<=CHECK_ENPTY_FLAG2;
							
							dram_request <= 1;
						end
						else
						begin
							state<=CHECK_ENPTY_FLAG0;
						end
					end
					else
					begin
						count<=count+1;
						state<=CHECK_ENPTY_FLAG1;
					end
				end
				CHECK_ENPTY_FLAG2://32
				begin
					if(dram_permit)
					begin
						backup_or_checkcache<=1;
						backup_or_io<=1;
						dram_request <= 0;
						state<=state_buf;
					end
					else state <= CHECK_ENPTY_FLAG2;
				end
				FINISH://3f
				begin
					release_dram <= 0;
					backup_or_checkcache<=0;
					backup_or_io<=0;
					state <= IDLE;
				end		
				default: state <= IDLE;
			endcase	
		end
	end

endmodule
