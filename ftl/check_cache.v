module check_cache
	(	
	reset,
	clk,
	initial_dram_done,
	//pcie_command_fifo
	pcie_cmd_rec_fifo_empty_i,
	pcie_cmd_rec_fifo_i,
	pcie_cmd_rec_fifo_en_o,	
	//pcie_data_fifo
	pcie_data_rec_fifo_en_o,
	pcie_data_rec_fifo_i,		
	//dram
	data_from_dram_i,
	dram_ready_i,	
	rd_data_valid_i,
	addr_to_dram_o,
	data_to_dram_o,
	dram_data_mask_o, 
	dram_en_o,
	dram_rd_wr_o,	
	data_to_dram_en,
	data_to_dram_end,
	data_to_dram_ready,
	
	//arbitrator
	dram_permit_i,
	dram_request_o,
	release_dram_o,	
	//ssd_command_fifo
	ssd_cmd_fifo_full_i,		
	ssd_cmd_fifo_en_o,
	ssd_cmd_fifo_in_o,		
	//finish_command_fifo8
	finish_cmd_fifo8_full_i,
	finish_cmd_fifo8_in_o,
	finish_cmd_fifo8_en_o,	
	dram_backup_en
	);	
	
	`include"ftl_define.v"
	input reset;
	input clk;
	input initial_dram_done;
	input pcie_cmd_rec_fifo_empty_i;
	input [COMMAND_WIDTH-1:0] pcie_cmd_rec_fifo_i;
	output pcie_cmd_rec_fifo_en_o;
	
	output pcie_data_rec_fifo_en_o;
	input [DRAM_IO_WIDTH-1:0] pcie_data_rec_fifo_i;	
	
	
	input [DRAM_IO_WIDTH-1:0] data_from_dram_i;
	input dram_ready_i;	
	input rd_data_valid_i;
	output [DRAM_ADDR_WIDTH-1:0] addr_to_dram_o;
	output [DRAM_IO_WIDTH-1:0] data_to_dram_o;
	output [DRAM_MASK_WIDTH-1:0]dram_data_mask_o;
	output dram_en_o;
	output dram_rd_wr_o;
	
	input dram_permit_i;
	output dram_request_o;
	output release_dram_o;	
	
	input	data_to_dram_ready;
	output	data_to_dram_en;
	output	data_to_dram_end;	
	
	
	input ssd_cmd_fifo_full_i;
	output ssd_cmd_fifo_en_o;
	output [COMMAND_WIDTH-1:0] ssd_cmd_fifo_in_o;
	
	input finish_cmd_fifo8_full_i;		
	output [COMMAND_WIDTH-1:0] finish_cmd_fifo8_in_o;
	output finish_cmd_fifo8_en_o;
	output dram_backup_en;
	
	reg pcie_cmd_rec_fifo_en_o;
	reg dram_request_o;
	reg release_dram_o;
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	reg [DRAM_IO_WIDTH-1:0] data_to_dram_o;
	reg [DRAM_MASK_WIDTH-1:0]dram_data_mask_o;
	reg dram_en;
	reg dram_rd_wr_o;
	reg pcie_data_rec_fifo_en_o;
	reg ssd_cmd_fifo_en_o;
	reg [COMMAND_WIDTH-1:0] ssd_cmd_fifo_in_o;
	reg [COMMAND_WIDTH-1:0] finish_cmd_fifo8_in_o;
	reg finish_cmd_fifo8_en_o;
	reg dram_backup_en;
	reg [DRAM_IO_WIDTH-1:0]data_tmp;
	
	
	parameter IDLE                    =7'b0000000;
	parameter WAIT_DRAM           	  =7'b0000001;
	parameter GET_ENTRY               =7'b0000010;
	parameter RECEIVE_ENTRY0          =7'b0000011;
	parameter RECEIVE_ENTRY1          =7'b0000100;
	parameter RECEIVE_ENTRY2	      =7'b0000101;
	parameter READY_FOR_CHECK_HIT     =7'b0000110;
	parameter CHECK_HIT               =7'b0000111;
	parameter HIT0                    =7'b0001000;	
	parameter HIT1                    =7'b0001001;
	parameter HIT2                    =7'b0001010;	
	parameter HIT3                    =7'b0001011;
	parameter HIT4                    =7'b0001100;	
	parameter HIT5                    =7'b0001101;
	parameter HIT6                    =7'b0001110;
	parameter HIT7                    =7'b0001111;
	parameter MISS                    =7'b0010000;
	parameter FREE_ENTRY_EXIST0       =7'b0010001;
	parameter FREE_ENTRY_EXIST1       =7'b0010010;
	parameter FREE_ENTRY_EXIST2       =7'b0010011;
	parameter FREE_ENTRY_EXIST3       =7'b0010100;
	parameter FREE_ENTRY_EXIST4       =7'b0010101;
	parameter FREE_ENTRY_EXIST5       =7'b0010110;
	parameter FREE_ENTRY_EXIST6       =7'b0010111;
	parameter FREE_ENTRY_EXIST7       =7'b0011000;
	parameter READY_FOR_CLEAN_ENTRY   =7'b0011001;
	parameter CLEAN_ENTRY_EXIST       =7'b0011010;
	parameter READY_FOR_ALLOCATE0     =7'b0011011;
	parameter READY_FOR_ALLOCATE1     =7'b0011100;
	parameter ALLOCATE_CLEAN_ENTRY0   =7'b0011101;
	parameter ALLOCATE_CLEAN_ENTRY1   =7'b0011110;
	parameter ALLOCATE_CLEAN_ENTRY2   =7'b0011111;
	parameter ALLOCATE_CLEAN_ENTRY3   =7'b0100000;
	parameter ALLOCATE_CLEAN_ENTRY4   =7'b0100001;
	parameter ALLOCATE_CLEAN_ENTRY5   =7'b0100010;
	parameter ALLOCATE_CLEAN_ENTRY6   =7'b0100011;
	parameter ALLOCATE_CLEAN_ENTRY7   =7'b0100100;
	parameter ALLOCATION_FAILED       =7'b0100101;
	parameter COMMAND_INTERPRET       =7'b0100110;
	parameter READ_COMMAND_INTERPRET  =7'b0100111;
	parameter WRITE_COMMAND_INTERPRET =7'b0101000;	
	parameter TRANSMIT_WRITE_DATA0    =7'b0101001;
	parameter TRANSMIT_WRITE_DATA1    =7'b0101010;	
	parameter TRANSMIT_WRITE_DATA2    =7'b0101011;
	parameter ISSUE_SSD_COMMAND       =7'b0101100;	
	parameter CACHE_REPLACE           =7'b0101101;
	parameter READY_FOR_SELECT_VICTIM =7'b0101110;
	parameter SELECT_VICTIM0          =7'b0101111;
	parameter SELECT_VICTIM1          =7'b0110000;
	parameter SELECT_VICTIM2          =7'b0110001;
	parameter SELECT_VICTIM3          =7'b0110010;
	parameter SELECT_VICTIM4          =7'b0110011;
	parameter SELECT_VICTIM5          =7'b0110100;
	parameter SELECT_VICTIM6          =7'b0110101;
	parameter SELECT_VICTIM7          =7'b0110110;
	parameter SELECT_VICTIM8          =7'b0110111;
	parameter FLUSH_DIRTY_DATA        =7'b0111000;
	parameter WRITE_ENTRY_BACK0       =7'b0111001;
	parameter WRITE_ENTRY_BACK1       =7'b0111010;
	parameter WRITE_ENTRY_BACK2       =7'b0111011;
	parameter UNLOCK_DRAM_FOR_A_WHILE =7'b0111100;
	parameter WAIT_DRAM_FOR_A_WHILE   =7'b0111101;
	parameter CHANCG_TO_STATE_BUF     =7'b0111110;
	parameter FINISH                  =7'b0111111;
	parameter INITIAL_CACHE_ENTRY0	  =7'b1000000;
	parameter INITIAL_CACHE_ENTRY1	  =7'b1000001;
	parameter INITIAL_CACHE_ENTRY2	  =7'b1000010;
	parameter INITIAL_CACHE_ENTRY3	  =7'b1000011;	
	parameter INITIAL_CACHE_ENTRY4	  =7'b1000100;
//	parameter                   =7'b1111111; 
	
	
	reg [6:0] state;
	reg [6:0] state_buf;
	reg [COMMAND_WIDTH-1:0] command;
	reg [511:0] data_from_dram_buf;
	reg [63:0]dram_data_mask_buf;
	reg [DRAM_IO_WIDTH-1:0] entries;
	reg [CACHE_ADDR_WIDTH-1:0] cache_addr;
	reg [COMMAND_WIDTH-1:0] ssd_command;
	reg whether_in_cache;
	reg hit_or_not;
	
	reg [7:0] additional_cache_fifo_head;//additional_cache的容量，4KB*256（2的8次方）=1MB
	
	reg [16:0] count;
	reg [DRAM_ADDR_WIDTH-1:0] dram_addr;
	reg [27:0] logical_addr;
	//dubug
	reg [7:0]hit_flag;	
	reg [7:0]clean_flag;
	reg [7:0]victim_flag;
	
	parameter COMMANDS_ISSUE0   =2'b00; 
	parameter COMMANDS_ISSUE1   =2'b01;
	parameter COMMANDS_ISSUE2   =2'b10;
	parameter COMMANDS_ISSUE3   =2'b11;

	reg	data_to_dram_en;
	reg	data_to_dram_end;
	reg	ci_en;
	reg	[DRAM_ADDR_WIDTH-1:0] ci_addr;
	reg	[31:0] ci_num;
	reg	[31:0] ci_cmd_cnt;
	reg	[31:0] ci_data_cnt;
	reg ci_done;
	reg [1:0] ci_state;
	reg flag; 
	reg dram_en_ci;
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram_ci;	
	assign dram_en_o=dram_en_ci|dram_en;
	assign addr_to_dram_o=(ci_done)? addr_to_dram:addr_to_dram_ci;	 
	
	always@ (posedge clk or negedge reset)
	begin
		if(!reset)
		begin
			pcie_cmd_rec_fifo_en_o           <= 0;
			dram_request_o                   <= 0;
			addr_to_dram                     <= 0;
			data_to_dram_o                   <= 0;
			dram_data_mask_o                 <= 0;
			dram_en                          <= 0;
			dram_rd_wr_o                     <= 0;
			pcie_data_rec_fifo_en_o          <= 0;
			ssd_cmd_fifo_en_o                <= 0;
			ssd_cmd_fifo_in_o                <= 0;
			release_dram_o                   <= 0;
			state                            <= INITIAL_CACHE_ENTRY0;
			command                          <= 0;
			entries                          <= 0;
			cache_addr                       <= 0;
			ssd_command                      <= 0;
			whether_in_cache                 <= 0;
			hit_or_not                       <= 0;
			
			additional_cache_fifo_head       <= 0;
			
			count                            <= 0;
			dram_addr                        <= 0;
			logical_addr                     <= 0;
			
			hit_flag                         <= 0;
			clean_flag                       <= 0;
			victim_flag                      <= 0;
			data_from_dram_buf               <= 0;
			dram_data_mask_buf               <= 0;
			dram_backup_en                   <= 0;
			ci_en 			         <= 0;
			ci_addr 		         <= 0;
			ci_num			         <= 0;
			ci_data_cnt			 <= 0;
			data_to_dram_en	                 <= 0;
			data_to_dram_end                 <= 0;
			data_tmp                         <= 0;
			flag 	                         <= 0;
		end
		else
		begin
			case (state)
				INITIAL_CACHE_ENTRY0:
				begin
					if(initial_dram_done)
					begin
						dram_request_o<=1;
						state<=INITIAL_CACHE_ENTRY1;
					end
					else state <= INITIAL_CACHE_ENTRY0;
				end
				INITIAL_CACHE_ENTRY1:
				begin
					if(dram_permit_i)
					begin
						dram_request_o<=0;
						if(ci_done) 
						begin
							ci_en <=1;
							dram_rd_wr_o <= 0;//write
							ci_addr <=CACHE_ENTRY_BASE;
						//	ci_num<=15'b10000_00000_00000;//2^14*2^6b=2^20b   4b*0x4000*2^3=2^(5+14)=2^19
							ci_num<=17'b1000000_00000_00000;//2^15*2^6b=2^21b   4*4b*0x4000*2^3=2^(5+14)=2^21
						dram_data_mask_o<=32'h0;
							data_to_dram_o <= 0;
							data_to_dram_en <= 1'b1;
							ci_data_cnt<=0;				
							state <=INITIAL_CACHE_ENTRY2;
						end					
					end
					else state <= INITIAL_CACHE_ENTRY1;
				end
				INITIAL_CACHE_ENTRY2:
				begin
					ci_en <=0;
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 0;
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						state <= INITIAL_CACHE_ENTRY3;
					end			
				end
				INITIAL_CACHE_ENTRY3:
				begin
				if(ci_data_cnt<ci_num)
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 0;
						data_to_dram_end <= 1'b0;
						data_to_dram_en <= 1'b1;
						state <= INITIAL_CACHE_ENTRY2;
					end
				end
				else 
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 0;
						data_to_dram_end <= 1'b0;
						data_to_dram_en <=  1'b0;
						state <= INITIAL_CACHE_ENTRY4;
					end
				end
				end
				INITIAL_CACHE_ENTRY4:
				begin
					if(ci_done)
					begin
						release_dram_o <= 1'b1;	
						state_buf<=IDLE;
						state <= FINISH;
					end					
				end
				IDLE://00
				begin
					release_dram_o <= 0;	
					if(pcie_cmd_rec_fifo_empty_i == 1'b0 && ssd_cmd_fifo_full_i == 1'b0 && finish_cmd_fifo8_full_i == 1'b0)//not empty
					begin
						pcie_cmd_rec_fifo_en_o <= 1;
						if(pcie_cmd_rec_fifo_i[127:96]==32'hffff_ffff)
						begin
							dram_backup_en<=1;
							state<=FINISH;
						end
						else
						begin
							command <= pcie_cmd_rec_fifo_i;							
							dram_request_o <= 1;
							state <= WAIT_DRAM;
						end
					end
					else
						state<=IDLE;
				end
				WAIT_DRAM://01
				begin
					pcie_cmd_rec_fifo_en_o <= 0;
					if(dram_permit_i)
					begin
						dram_request_o <= 0;
					    if(ci_done)
					    begin
							dram_en <= 1;
							dram_rd_wr_o <= 1;//read
						//	addr_to_dram <= {command[13:1], 3'b000} + CACHE_ENTRY_BASE;//2的16次方乘以4字节=256KB，CACHE_ENTRY占用DRAM的容量是256KB
							addr_to_dram <= {command[15:1], 3'b000} + CACHE_ENTRY_BASE;//2^18*4bytes=1MB，CACHE_ENTRY占用DRAM的容量是1MB.
						state <= GET_ENTRY;
					    end
					end
					else
						state<=WAIT_DRAM;
				end
				GET_ENTRY://02
				begin	
					if(dram_ready_i)
					begin
						dram_en <= 0;
						state <= RECEIVE_ENTRY0;		
					end
					else
					begin
						state <= GET_ENTRY;
					end
				end
				RECEIVE_ENTRY0: //03 
				begin
					if(rd_data_valid_i)
					begin
						state <= RECEIVE_ENTRY1;
						data_from_dram_buf[255:0]<=data_from_dram_i;						
					end
					else
						state <= RECEIVE_ENTRY0;	
				end
				RECEIVE_ENTRY1: //04  
				begin
					if(rd_data_valid_i)
					begin	
						state <= RECEIVE_ENTRY2;
						data_from_dram_buf[511:256]<=data_from_dram_i;	
					end
					else
						state <= RECEIVE_ENTRY1;	
				end
				RECEIVE_ENTRY2://05
				begin
					if(command[0]==0)
					begin
						entries<=data_from_dram_buf[255:0];
						dram_data_mask_buf<=64'hffffffff_00000000;					
					end
					else
					begin
						entries<=data_from_dram_buf[511:256];
						dram_data_mask_buf<=64'h00000000_ffffffff;
					end
					state <= READY_FOR_CHECK_HIT;
				end
				READY_FOR_CHECK_HIT://06
				begin
					hit_flag[0] <= |(entries[28:0]    ^ {1'b1, command[27:0]});
					hit_flag[1] <= |(entries[60:32]   ^ {1'b1, command[27:0]});
					hit_flag[2] <= |(entries[92:64]   ^ {1'b1, command[27:0]});
					hit_flag[3] <= |(entries[124:96]  ^ {1'b1, command[27:0]});
					hit_flag[4] <= |(entries[156:128] ^ {1'b1, command[27:0]});
					hit_flag[5] <= |(entries[188:160] ^ {1'b1, command[27:0]});
					hit_flag[6] <= |(entries[220:192] ^ {1'b1, command[27:0]});
					hit_flag[7] <= |(entries[252:224] ^ {1'b1, command[27:0]});
					state <= CHECK_HIT;
				end
				CHECK_HIT://07
				begin
					casex(hit_flag)// synthesis parallel_case
						8'bxxxxxxx0:
							state <= HIT0;
						8'bxxxxxx0x:
							state <= HIT1;
						8'bxxxxx0xx:
							state <= HIT2;
						8'bxxxx0xxx:
							state <= HIT3;
						8'bxxx0xxxx:
							state <= HIT4;
						8'bxx0xxxxx:
							state <= HIT5;
						8'bx0xxxxxx:
							state <= HIT6;
						8'b0xxxxxxx:
							state <= HIT7;
						default:
							state <= MISS;
					endcase	
				end
				/////////////////////////////////////cache hit
				HIT0://08
				begin
					if(entries[29])	
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end				
					else
					begin
						entries[31] <= 1;  //reused
						if(command[126])
							entries[30] <= 1; //if this is a write command, the entry should be marked to be dirty
						else
							entries[29] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					//	cache_addr <= {command[13:0], 3'b000};
						cache_addr <= {command[15:0], 3'b000};					
					    hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;
					end					
				end
				HIT1://09
				begin
					if(entries[61])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin
						entries[63] <= 1;  //reused
						if(command[126])
							entries[62] <= 1; //dirty or not
						else
							entries[61] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b001};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;
					end						
				end
				HIT2://0a
				begin
					if(entries[93])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin
						entries[95] <= 1;  //reused
						if(command[126])
							entries[94] <= 1; //dirty or not
						else
							entries[93] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b010};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;
					end			
				end				
				HIT3://0b
				begin
					if(entries[125])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin					
						entries[127] <= 1;  //reused
						if(command[126])
							entries[126] <= 1; //dirty or not
						else
							entries[125] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b011};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;					
					end
				end
				HIT4://0c
				begin
					if(entries[157])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin
						entries[159] <= 1;  //reused
						if(command[126])
							entries[158] <= 1; //dirty or not
						else
							entries[157] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b100};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;
					end					
				end
				HIT5://0d
				begin
					if(entries[189])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin
						entries[191] <= 1;  //reused
						if(command[126])
							entries[190] <= 1; //dirty or not
						else
							entries[189] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b101};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;
					end				
				end
				HIT6://0e
				begin
					if(entries[221])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin					
						entries[223] <= 1;  //reused
						if(command[126])
							entries[222] <= 1; //dirty or not
						else
							entries[221] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b110};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;					
					end				
				end					
				HIT7://0f
				begin
					if(entries[253])
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf<=WAIT_DRAM;
					end
					else
					begin					
						entries[255] <= 1;  //reused
						if(command[126])
							entries[254] <= 1; //dirty or not
						else
							entries[253] <= 1; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
						cache_addr <= {command[15:0], 3'b111};
						hit_or_not <= 1;
						whether_in_cache <= 1;
						state <= COMMAND_INTERPRET;					
					end			
				end				
				/////////////////////////////////////////////cache miss
				MISS://10
				begin
					hit_or_not <= 0;
					casex({entries[252],entries[220],entries[188],entries[156],entries[124],entries[92],entries[60],entries[28]})
						8'bxxxxxxx0:
							state <= FREE_ENTRY_EXIST0;
						8'bxxxxxx01:
							state <= FREE_ENTRY_EXIST1;
						8'bxxxxx011:
							state <= FREE_ENTRY_EXIST2;
						8'bxxxx0111:
							state <= FREE_ENTRY_EXIST3;
						8'bxxx01111:
							state <= FREE_ENTRY_EXIST4;
						8'bxx011111:
							state <= FREE_ENTRY_EXIST5;
						8'bx0111111:
							state <= FREE_ENTRY_EXIST6;
						8'b01111111:
							state <= FREE_ENTRY_EXIST7;
						default:
							state <= READY_FOR_CLEAN_ENTRY;
					endcase			
				end
				FREE_ENTRY_EXIST0://11
				begin					
					entries[27:0] <=command[27:0];
					entries[28] <= 1; //not free
					entries[29] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[30] <= command[126]; //dirty or not
					entries[31] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b000};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;			
				end
				FREE_ENTRY_EXIST1://12
				begin
					entries[59:32] <=command[27:0];
					entries[60] <= 1; //not free
					entries[61] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[62] <= command[126]; //dirty or not
					entries[63] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b001};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end
				FREE_ENTRY_EXIST2://13  
				begin
					entries[91:64] <=command[27:0];
					entries[92] <= 1; //not free
					entries[93] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[94] <= command[126]; //dirty or not
					entries[95] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b010};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end			
				FREE_ENTRY_EXIST3://14
				begin	
					entries[123:96] <=command[27:0];
					entries[124] <= 1; //not free
					entries[125] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[126] <= command[126]; //dirty or not
					entries[127] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b011};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end
				FREE_ENTRY_EXIST4://15
				begin					
					entries[155:128] <=command[27:0];
					entries[156] <= 1; //not free
					entries[157] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[158] <= command[126]; //dirty or not
					entries[159] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b100};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;			
				end
				FREE_ENTRY_EXIST5://16
				begin
					entries[187:160] <=command[27:0];
					entries[188] <= 1; //not free
					entries[189] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[190] <= command[126]; //dirty or not
					entries[191] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b101};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end
				FREE_ENTRY_EXIST6://17
				begin
					entries[219:192] <=command[27:0];
					entries[220] <= 1; //not free
					entries[221] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[222] <= command[126]; //dirty or not
					entries[223] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b110};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end			
				FREE_ENTRY_EXIST7://18
				begin	
					entries[251:224] <=command[27:0];
					entries[252] <= 1; //not free
					entries[253] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[254] <= command[126]; //dirty or not
					entries[255] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b111};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end
				READY_FOR_CLEAN_ENTRY://19
				begin
					if((entries[30]==0 && entries[29]==0) || (entries[62]==0 && entries[61]==0) || (entries[94]==0 && entries[93]==0) || 
					   (entries[126]==0 && entries[125]==0) || (entries[158]==0 && entries[157]==0) || 
					   (entries[190]==0 && entries[189]==0) || (entries[222]==0 && entries[221]==0) || 
					   (entries[254]==0 && entries[253]==0))					
						state <= CLEAN_ENTRY_EXIST;				
					else					
						state <= ALLOCATION_FAILED;	
				end
				CLEAN_ENTRY_EXIST://1a
				begin
					if(entries[31]==0 || entries[63]==0 || entries[95]==0 || entries[127]==0 || entries[159]==0 || 
					   entries[191]==0 || entries[223]==0 || entries[255]==0) //some entries haven't been reused
					begin
						state <= READY_FOR_ALLOCATE0;
					end
					else
					begin
						entries[31]  <= 0;
						entries[63]  <= 0;
						entries[95]  <= 0;
						entries[127] <= 0;
						entries[159] <= 0;
						entries[191] <= 0;
						entries[223] <= 0;
						entries[255] <= 0;
						state <= READY_FOR_ALLOCATE0;
					end
				end	
				READY_FOR_ALLOCATE0://1b
				begin
					clean_flag[0] <= entries[31] ==0 && entries[30] ==0 && entries[29]  ==0;
					clean_flag[1] <= entries[63] ==0 && entries[62] ==0 && entries[61]  ==0;
					clean_flag[2] <= entries[95] ==0 && entries[94] ==0 && entries[93]  ==0;
					clean_flag[3] <= entries[127]==0 && entries[126]==0 && entries[125] ==0;
					clean_flag[4] <= entries[159]==0 && entries[158]==0 && entries[157] ==0;
					clean_flag[5] <= entries[191]==0 && entries[190]==0 && entries[189] ==0;
					clean_flag[6] <= entries[223]==0 && entries[222]==0 && entries[221] ==0;
					clean_flag[7] <= entries[255]==0 && entries[254]==0 && entries[253] ==0;	
					state <= READY_FOR_ALLOCATE1;
				end
				READY_FOR_ALLOCATE1://1c
				begin
					casex(clean_flag)
						8'bxxxxxxx1:
							state <= ALLOCATE_CLEAN_ENTRY0;
						8'bxxxxxx10:
							state <= ALLOCATE_CLEAN_ENTRY1;
						8'bxxxxx100:
							state <= ALLOCATE_CLEAN_ENTRY2;
						8'bxxxx1000:
							state <= ALLOCATE_CLEAN_ENTRY3;
						8'bxxx10000:
							state <= ALLOCATE_CLEAN_ENTRY4;
						8'bxx100000:
							state <= ALLOCATE_CLEAN_ENTRY5;
						8'bx1000000:
							state <= ALLOCATE_CLEAN_ENTRY6;
						8'b10000000:
							state <= ALLOCATE_CLEAN_ENTRY7;
						default:
							state <= ALLOCATION_FAILED;
					endcase			
				end
				ALLOCATE_CLEAN_ENTRY0://1d
				begin					
					entries[27:0] <=command[27:0];
					entries[28] <= 1; //not free
					entries[29] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[30] <= command[126]; //dirty or not
					entries[31] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b000};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;									
				end
				ALLOCATE_CLEAN_ENTRY1://1e
				begin
					entries[59:32] <=command[27:0];
					entries[60] <= 1; //not free
					entries[61] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[62] <= command[126]; //dirty or not
					entries[63] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b001};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end
				ALLOCATE_CLEAN_ENTRY2://1f
				begin
					entries[93:64] <=command[27:0];
					entries[92] <= 1; //not free
					entries[93] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[94] <= command[126]; //dirty or not
					entries[95] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b010};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;				
				end
				ALLOCATE_CLEAN_ENTRY3://20
				begin
					entries[123:96] <=command[27:0];
					entries[124] <= 1; //not free
					entries[125] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[126] <= command[126]; //dirty or not
					entries[127] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b011};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end	
				ALLOCATE_CLEAN_ENTRY4://21
				begin					
					entries[155:128] <=command[27:0];
					entries[156] <= 1; //not free
					entries[157] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[158] <= command[126]; //dirty or not
					entries[159] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b100};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;									
				end
				ALLOCATE_CLEAN_ENTRY5://22
				begin
					entries[187:160] <=command[27:0];
					entries[188] <= 1; //not free
					entries[189] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[190] <= command[126]; //dirty or not
					entries[191] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b101};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end
				ALLOCATE_CLEAN_ENTRY6://23
				begin
					entries[219:192] <=command[27:0];
					entries[220] <= 1; //not free
					entries[221] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[222] <= command[126]; //dirty or not
					entries[223] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b110};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;			
				end
				ALLOCATE_CLEAN_ENTRY7://24
				begin
					entries[251:224] <=command[27:0];
					entries[252] <= 1; //not free
					entries[253] <= ~command[126]; //if this is a read command,  it needs to lock the entry to provent the entry from being replaced
					entries[254] <= command[126]; //dirty or not
					entries[255] <= 1;  //reused
					cache_addr <= {command[15:0], 3'b111};
					whether_in_cache <= 1;
					state <= COMMAND_INTERPRET;
				end	
				ALLOCATION_FAILED://25
				begin
					cache_addr <= additional_cache_fifo_head;//round robin
					additional_cache_fifo_head <= additional_cache_fifo_head+1;
					whether_in_cache <= 0;
					state <= COMMAND_INTERPRET;
				end
				COMMAND_INTERPRET://26
				begin
					case (command[127:126])
						2'b00:
						begin
							state <= READ_COMMAND_INTERPRET;
						end
						2'b01:
						begin
							state <= WRITE_COMMAND_INTERPRET;							
						end
						default:state <= FINISH;
					endcase
				end
				READ_COMMAND_INTERPRET://27
				begin
					if(!hit_or_not)//读是否命中cache
					begin
//						ssd_command <= {2'b00, 77'b0, cache_addr, command[31:0]};//2+77+17+32=128
						//ssd_command <= {2'b00, 75'b0, cache_addr, command[31:0]};//2+75+19+32=128
						ssd_command <= {command[127:51], cache_addr, command[31:0]};//2+75+19+32=128
						state <= ISSUE_SSD_COMMAND;
					end
					else if(!finish_cmd_fifo8_full_i)
					begin
						finish_cmd_fifo8_in_o<={command[127:51], cache_addr, command[31:0]};//
						finish_cmd_fifo8_en_o<=1;
						state <= CACHE_REPLACE;//读命中，不往下(IO调度器)发送命令							
					end
					else
					begin
						state<=UNLOCK_DRAM_FOR_A_WHILE;//finish_command_fifo8_full满，释放dram一段时间
						state_buf<=READ_COMMAND_INTERPRET;
					end
				end
				WRITE_COMMAND_INTERPRET://28
				begin					
					if(whether_in_cache)//写是否在cache上，还是在additional cache上
					begin
//						dram_addr <= CACHE_BASE + {cache_addr, 11'b000_00000000};//2的11次方乘以8字节=16KB，一页大小为16KB
						dram_addr <= CACHE_BASE + {cache_addr, 9'b0_00000000};//2的9次方乘以8字节=4KB，一页大小为4KB

						state_buf<=CACHE_REPLACE;//写命中，不往下(IO调度器)发送命令	
					end
					else
					begin
						ssd_command <= {2'b01,1'b0,74'b0, cache_addr, command[31:0]};
						dram_addr <= ADDITIONAL_CACHE_FIFO_BASE + {cache_addr, 9'b0_00000000};//additional_cache容量较小
						state_buf <= ISSUE_SSD_COMMAND;
					end
					state <= TRANSMIT_WRITE_DATA0;
					pcie_data_rec_fifo_en_o <= 1;
					//data_tmp<=pcie_data_rec_fifo_i;
					//dram_en <= 1;
					//dram_rd_wr_o <= 0;//write
				end
				TRANSMIT_WRITE_DATA0://29
				begin	
					pcie_data_rec_fifo_en_o <= 0;
					if(ci_done) 
					begin
						ci_en <=1;
						dram_rd_wr_o <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT;//256; //256*512b=16KB
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= pcie_data_rec_fifo_i;
						data_to_dram_en <= 1'b1;
						ci_data_cnt<=0;
						pcie_data_rec_fifo_en_o <= 1;
						state <= TRANSMIT_WRITE_DATA1;	
					end
				end				
				TRANSMIT_WRITE_DATA1://2a
				begin 
				ci_en <=0;
				pcie_data_rec_fifo_en_o <= 0;
				if (data_to_dram_ready & !flag) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= pcie_data_rec_fifo_i;
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							pcie_data_rec_fifo_en_o <= 1;
						state <= TRANSMIT_WRITE_DATA2;
					end
				else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
				begin
					data_tmp <= pcie_data_rec_fifo_i;	
					flag <=1;			
				end				
				else if(data_to_dram_ready)
				begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= data_tmp;
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							pcie_data_rec_fifo_en_o <= 1;
						flag <=0;
						state <= TRANSMIT_WRITE_DATA2;				    				
				end
				else 
					state <= TRANSMIT_WRITE_DATA1;
				end				
				TRANSMIT_WRITE_DATA2://2b
				begin
					pcie_data_rec_fifo_en_o <= 0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask_o<=32'h0;
							data_to_dram_o <= pcie_data_rec_fifo_i;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_rec_fifo_en_o <= 1;
							state <= TRANSMIT_WRITE_DATA1;
						end
						else if (!flag)
						begin
							data_tmp <= pcie_data_rec_fifo_i;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask_o<=32'h0;
							data_to_dram_o <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_rec_fifo_en_o <= 1;
							flag <=0;
							state <= TRANSMIT_WRITE_DATA1;				    				
						end
						else 
							state <= TRANSMIT_WRITE_DATA2;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask_o<=32'h0;
							data_to_dram_o <= pcie_data_rec_fifo_i;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							state <= state_buf;
						end
						else if (!flag)
						begin
							data_tmp <= pcie_data_rec_fifo_i;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask_o<=32'h0;
							data_to_dram_o <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							flag <=0;
							state <= state_buf;			    				
						end
						else 
							state <= TRANSMIT_WRITE_DATA2;
					end
				end
				ISSUE_SSD_COMMAND://2c
				begin
					if(!ssd_cmd_fifo_full_i)
					begin
						ssd_cmd_fifo_en_o <= 1;
						ssd_cmd_fifo_in_o <= ssd_command;
						state <= CACHE_REPLACE;
					end
					else 
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;
						state_buf <= ISSUE_SSD_COMMAND;
					end
				end
				CACHE_REPLACE://2d
				begin
					ssd_cmd_fifo_en_o <= 0;
					finish_cmd_fifo8_en_o<=0;
					if(entries[28]==0 || entries[60]==0 || entries[92]==0 || entries[124]==0 || entries[156]==0 || 
					   entries[188]==0 || entries[220]==0 || entries[252]==0)  // there are some free entries, no need to replace
					begin
						state <= WRITE_ENTRY_BACK0;
						//dram_en <= 1;
						//dram_rd_wr_o <= 0;//write
					end	
					else if((entries[31]==0 && entries[30]==0)||(entries[63]==0 && entries[62]==0)||(entries[95]==0 && entries[94]==0)||
					        (entries[127]==0&&entries[126]==0)||(entries[159]==0&&entries[158]==0)||(entries[191]==0&&entries[190]==0)||
					        (entries[223]==0&&entries[222]==0)||(entries[255]==0&&entries[254]==0))
					begin
						state <= WRITE_ENTRY_BACK0;//no need to replace, because these exist an entry that is clean and non-reused					
						//dram_en <= 1;
						//dram_rd_wr_o <= 0;//write
					end
					else                                                         //it needs to evict an entry 
					begin
						victim_flag[0] <= entries[31] ==0 && entries[30] ==1 && entries[29]  ==0;//31==0 no resued;  30==1dirty; 29==0 no lock
						victim_flag[1] <= entries[63] ==0 && entries[62] ==1 && entries[61]  ==0;
						victim_flag[2] <= entries[95] ==0 && entries[94] ==1 && entries[93]  ==0;
						victim_flag[3] <= entries[127]==0 && entries[126]==1 && entries[125] ==0;
						victim_flag[4] <= entries[159]==0 && entries[158]==1 && entries[157] ==0;
						victim_flag[5] <= entries[191]==0 && entries[190]==1 && entries[189] ==0;
						victim_flag[6] <= entries[223]==0 && entries[222]==1 && entries[221] ==0;
						victim_flag[7] <= entries[255]==0 && entries[254]==1 && entries[253] ==0;	
						state <= READY_FOR_SELECT_VICTIM;
					end				
				end
				READY_FOR_SELECT_VICTIM://2e
				begin
					casex(victim_flag)
						8'bxxxxxxx1:
							state <= SELECT_VICTIM0;
						8'bxxxxxx10:
							state <= SELECT_VICTIM1;
						8'bxxxxx100:
							state <= SELECT_VICTIM2;
						8'bxxxx1000:
							state <= SELECT_VICTIM3;
						8'bxxx10000:
							state <= SELECT_VICTIM4;
						8'bxx100000:
							state <= SELECT_VICTIM5;
						8'bx1000000:
							state <= SELECT_VICTIM6;
						8'b10000000:
							state <= SELECT_VICTIM7;
						default:
							state <= SELECT_VICTIM8;
					endcase	
				end
				SELECT_VICTIM0://2f
				begin
					cache_addr <= {command[15:0], 3'b000};
					entries[29] <= 1;//locked ,等待数据写回flash，避免数据丢失
					entries[30] <= 0;
					logical_addr <= entries[27:0];
					state <= FLUSH_DIRTY_DATA;
				end				
				SELECT_VICTIM1://30
				begin
					cache_addr <= {command[15:0], 3'b001};
					entries[61] <= 1;
					entries[62] <= 0;
					logical_addr <= entries[59:32];
					state <= FLUSH_DIRTY_DATA;
				end
				SELECT_VICTIM2://31
				begin
					cache_addr <= {command[15:0], 3'b010};
					entries[93] <= 1;
					entries[94] <= 0;
					logical_addr <= entries[91:64];
					state <= FLUSH_DIRTY_DATA;
				end
				SELECT_VICTIM3://32
				begin
					cache_addr <= {command[15:0], 3'b011};
					entries[125] <= 1;
					entries[126] <= 0;
					logical_addr <= entries[123:96];
					state <= FLUSH_DIRTY_DATA;
				end
				SELECT_VICTIM4://33
				begin
					cache_addr <= {command[15:0], 3'b100};
					entries[157] <= 1;//////////////////////////rethink
					entries[158] <= 0;
					logical_addr <= entries[155:128];
					state <= FLUSH_DIRTY_DATA;
				end				
				SELECT_VICTIM5://34
				begin
					cache_addr <= {command[15:0], 3'b101};
					entries[189] <= 1;
					entries[190] <= 0;
					logical_addr <= entries[187:160];
					state <= FLUSH_DIRTY_DATA;
				end
				SELECT_VICTIM6://35
				begin
					cache_addr <= {command[15:0], 3'b110};
					entries[221] <= 1;
					entries[222] <= 0;
					logical_addr <= entries[219:192];
					state <= FLUSH_DIRTY_DATA;
				end
				SELECT_VICTIM7://36
				begin
					cache_addr <= {command[15:0], 3'b111};
					entries[253] <= 1;
					entries[254] <= 0;
					logical_addr <= entries[251:224];
					state <= FLUSH_DIRTY_DATA;
				end
				SELECT_VICTIM8://37
				begin
					if(entries[29]==0 || entries[61]==0 || entries[93]==0 || entries[125]==0 || entries[157]==0 || 
					   entries[189]==0 || entries[221]==0 || entries[253]==0)					
					begin
						entries[31]  <= 0;//resued置位
						entries[63]  <= 0;
						entries[95]  <= 0;
						entries[127] <= 0;
						entries[159] <= 0;
						entries[191] <= 0;
						entries[223] <= 0;
						entries[255] <= 0;
						state <= CACHE_REPLACE;
					end
					else
					begin
						state <= WRITE_ENTRY_BACK0;						
						//dram_en <= 1;
						//dram_rd_wr_o <= 0;//write
					end
				end				
				FLUSH_DIRTY_DATA://38  //send a ssd write command to evict the dirty data
				begin
					if(!ssd_cmd_fifo_full_i)
					begin
						ssd_cmd_fifo_en_o <= 1;
//						ssd_cmd_fifo_in_o <= {2'b01,1'b1,76'b0,cache_addr,4'b0,logical_addr};
						ssd_cmd_fifo_in_o <= {2'b01,1'b1,74'b0,cache_addr,4'b0,logical_addr};
						state <= WRITE_ENTRY_BACK0;
					end
					else
					begin
						state <= UNLOCK_DRAM_FOR_A_WHILE;
						state_buf <= FLUSH_DIRTY_DATA;
					end	
				end
				WRITE_ENTRY_BACK0://39
				begin
					ssd_cmd_fifo_en_o <= 0;
					if(ci_done)
					begin					
					   data_to_dram_en <= 1'b1;
					   data_to_dram_o <= entries;
					   dram_data_mask_o<=dram_data_mask_buf[31:0];//mask	
					   state <=WRITE_ENTRY_BACK1;
                    end
				end
				WRITE_ENTRY_BACK1:  //3a
				begin
					if(data_to_dram_ready) 
						begin
						dram_en <= 1;
						dram_rd_wr_o <= 0;//write
						addr_to_dram <= {command[15:1], 3'b000} + CACHE_ENTRY_BASE;
						data_to_dram_end<= 1'b1;
						data_to_dram_o <= entries;
						dram_data_mask_o<=dram_data_mask_buf[63:32];					
						state	<= WRITE_ENTRY_BACK2;
						end		
				end
				WRITE_ENTRY_BACK2://3b
				begin 
					if(dram_ready_i & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						state <= FINISH;	
					end 
					else if (dram_ready_i)
					begin
						dram_en <= 0;
					end 
					else if (data_to_dram_ready) 
					begin
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;	
					end 
					else 
						state <= WRITE_ENTRY_BACK2;
				end	
				UNLOCK_DRAM_FOR_A_WHILE://3c
				begin
					if(ci_done)
					begin
						release_dram_o <= 1;
						count <= 0;
						state <= WAIT_DRAM_FOR_A_WHILE;
					end
					else
						state <= UNLOCK_DRAM_FOR_A_WHILE;
				end
				WAIT_DRAM_FOR_A_WHILE://3d
				begin
					release_dram_o <= 0;
					if(count>=63)
					begin
						dram_request_o <= 1;
						count<=0;
						state <= CHANCG_TO_STATE_BUF;						
					end
					else
						count <= count+1;			
				end
				CHANCG_TO_STATE_BUF://3e
				begin
					if(dram_permit_i)
					begin
						dram_request_o <= 0;
						state <= state_buf;
					end
					else state <= CHANCG_TO_STATE_BUF;
				end
				FINISH://3f
				begin
					pcie_cmd_rec_fifo_en_o <= 0;
					dram_backup_en<=0;
					release_dram_o <= 1;				
					state <= IDLE;			
				end
				default: state <= FINISH;
			endcase
		end
	end	
always@(posedge clk or negedge reset) // back2back write/read command
	begin
		if(!reset) 
		begin
			ci_done  <=1;  //done==1, not busy
			ci_state <=COMMANDS_ISSUE0;
			ci_cmd_cnt	 <=0;
			dram_en_ci <= 0;
			addr_to_dram_ci <=0;
		end 
		else 
		begin
			case(ci_state)
				COMMANDS_ISSUE0:    //0
				begin
					if(ci_en)
					begin
						ci_done <= 0;
						ci_cmd_cnt <= 0;
						ci_state <= COMMANDS_ISSUE1;
					end
				end
				COMMANDS_ISSUE1:	//1
				begin
					if  (ci_cmd_cnt < ci_data_cnt)
					begin
						dram_en_ci <= 1;
						addr_to_dram_ci <= ci_addr+{ci_cmd_cnt[25:0],3'b000};
						ci_state <= COMMANDS_ISSUE2;
					end
				end
				COMMANDS_ISSUE2:	//2
				begin	 		
					if(dram_ready_i)
					begin
						dram_en_ci <= 0; 
						ci_cmd_cnt<=ci_cmd_cnt+1;  //successive command number +1 
						ci_state <= COMMANDS_ISSUE1;						
						if(ci_cmd_cnt == (ci_num-1))
							ci_state <= COMMANDS_ISSUE3;					
					end					
				end	
				COMMANDS_ISSUE3:	//3
				begin
					ci_done <= 1;
					ci_state<=COMMANDS_ISSUE0;		
				end
			endcase
		end
	end		
endmodule
