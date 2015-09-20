//2013.09.14 considering  every channels' high blocks(from 0x3ff0 to 0x3fff) used for storing metadata,
//            modify free_block_heads/tails' varing range
//2015.1.06  add check bad block states.
module address_management(
	reset,
	clk,
	request_coming,
	request_op,
	addr_to_addr_management,
	data_from_dram,
	dram_ready,	
	rd_data_valid,

	paddr0_from_addr_management,
	paddr1_from_addr_management,
	addr_management_ready,
	dram_en_o,
	dram_read_or_write,
	addr_to_dram_o,
	data_to_dram,
	dram_data_mask,
	addr_manage_dram_busy,
	data_to_dram_en,
	data_to_dram_end,
	data_to_dram_ready,
	flash_left_capacity_io,
	free_block_fifo_heads_io,
	free_block_fifo_tails_io,
	register_ready
	);

	`include"ftl_define.v"
	input reset;
	input clk;
	input request_coming;
	input [1:0] request_op;
	input [27:0] addr_to_addr_management;
	input [DRAM_IO_WIDTH-1:0] data_from_dram;
	input dram_ready;	
	input rd_data_valid;	
	input register_ready;

	output [PHYSICAL_ADDR_WIDTH-1:0] paddr0_from_addr_management;
	output [PHYSICAL_ADDR_WIDTH-1:0] paddr1_from_addr_management;
	output addr_management_ready;
	output dram_en_o;
	output dram_read_or_write;
	output [DRAM_ADDR_WIDTH-1:0] addr_to_dram_o;
	output [DRAM_IO_WIDTH-1:0] data_to_dram;
	output [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	input	data_to_dram_ready;
	output	data_to_dram_en;
	output	data_to_dram_end;	
	output addr_manage_dram_busy;
	inout [18:0]flash_left_capacity_io;//512GB flash217η
	inout [127:0] free_block_fifo_heads_io;
	inout [127:0] free_block_fifo_tails_io;

	assign  flash_left_capacity_io 	 = register_ready? 	19'bz:flash_left_capacity;
	assign  free_block_fifo_heads_io = register_ready? 	128'bz:free_block_fifo_heads;
	assign  free_block_fifo_tails_io = register_ready? 	128'bz:free_block_fifo_tails;
	
	reg [PHYSICAL_ADDR_WIDTH-1:0] paddr0_from_addr_management;
	reg [PHYSICAL_ADDR_WIDTH-1:0] paddr1_from_addr_management;
	reg	[31:0] page_table_entry;
	reg addr_management_ready;
	reg dram_en;
	reg dram_read_or_write;
	reg data_to_dram_en;
	reg data_to_dram_end;
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	reg [DRAM_IO_WIDTH-1:0] data_to_dram;
	reg [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	reg addr_manage_dram_busy;
	reg [18:0]flash_left_capacity;//512GB flash217η
	
	
	parameter INITIAL_REGISTER				=6'b000000;
	parameter IDLE							=6'b000001;
	parameter COMMAND_INTERPRET				=6'b000010;
	parameter READ_COMMAND			     	=6'b000011;
	parameter GET_MAPPING_ENTRY_FOR_READ	=6'b000100;
	parameter GET_PADDR0_FOR_READ			=6'b000101;
	parameter WRITE_COMMAND					=6'b000110;
	parameter GET_PADDR0_FOR_WRITE0		 	=6'b000111;
	parameter GET_PADDR0_FOR_WRITE1		 	=6'b001000;
	parameter CHECK_PADDR0	    			=6'b001001;
	parameter READY_FOR_INVALIDATE_P2L	 	=6'b001010;
	parameter INVALIDATE_P2L_MAPPING_TABLE0	=6'b001011;
	parameter INVALIDATE_P2L_MAPPING_TABLE1	=6'b001100;
	parameter INVALIDATE_P2L_MAPPING_TABLE2	=6'b001101;
	parameter GET_GARBAGE_IN_BLOCK		 	=6'b001110;
	parameter RECEIVE_GARBAGE_IN_BLOCK	 	=6'b001111;
	parameter INCREAMENT_GARBAGE		   	=6'b010000;
	parameter READY_FOR_WRITE_BACK_GARBAGE 	=6'b010001;
	parameter WRITE_BACK_GARBAGE_IN_BLOCK0 	=6'b010010;
	parameter WRITE_BACK_GARBAGE_IN_BLOCK1 	=6'b010011;
	parameter WRITE_BACK_GARBAGE_IN_BLOCK2 	=6'b010100;
	parameter ALLOCATE_NEW_PAGE            	=6'b010101;
	parameter READY_FOR_REFRESH_L2P	     	=6'b010110;
	parameter WRITE_BACK_L2P_MAPPING_TABLE0	=6'b010111;
	parameter WRITE_BACK_L2P_MAPPING_TABLE1	=6'b011000;
	parameter WRITE_BACK_L2P_MAPPING_TABLE2	=6'b011001;
	parameter READY_FOR_REFRESH_P2L	     	=6'b011010;
	parameter REFRESH_P2L_MAPPING_TABLE0	=6'b011011;
	parameter REFRESH_P2L_MAPPING_TABLE1	=6'b011100;
	parameter REFRESH_P2L_MAPPING_TABLE2	=6'b011101;
	parameter CHECK_NEXT_PAGE              	=6'b011110;
	parameter ALLOCATE_NEW_BLOCK		   	=6'b011111;
	parameter GET_A_FREE_BLOCK0		     	=6'b100000;
	parameter GET_A_FREE_BLOCK1            	=6'b100001;
	
	parameter WRITE_END                    	=6'b100010;
	parameter MOVE_COMMAND		         	=6'b100011;
	parameter GET_MAPPING_ENTRY_FOR_MOVE	=6'b100100;
	parameter GET_PADDR0_FOR_MOVE			=6'b100101;
	parameter ERASE_COMMAND			     	=6'b100110;
	parameter ERASE_COMMAND1				=6'b100111;
	parameter ERASE_COMMAND2				=6'b101000;
	parameter ADD_FREE_BLOCK_TO_FIFO		=6'b101001;
	parameter GET_DATA_FROM_DRAM		    =6'b101010;
	parameter RECEIVE_DATA_FROM_DRAM	   	=6'b101011;
	parameter MODIFY_FREE_BLOCKS		   	=6'b101100;
	parameter WRITE_BACK_FREE_BLOCKS0	    =6'b101101;
	parameter WRITE_BACK_FREE_BLOCKS1	    =6'b101110;
	parameter WRITE_BACK_FREE_BLOCKS2	    =6'b101111;
	parameter WRITE_BACK_FREE_BLOCKS3	    =6'b110000;
	
	parameter CHECK_BAD_BLOCK0		     	=6'b110001;
	parameter CHECK_BAD_BLOCK1            	=6'b110010;	
	parameter CHECK_BAD_BLOCK2		     	=6'b110011;
	parameter CHECK_BAD_BLOCK3            	=6'b110100;		
	
	parameter FINISH			     		=6'b111111;
	
	

	reg [1:0] op;
	reg [27:0] addr;	
	reg [DRAM_IO_WIDTH-1:0] free_blocks;
	reg [DRAM_IO_WIDTH-1:0] l2p_mapping_entries;
	reg [DRAM_IO_WIDTH-1:0] p2l_mapping_entries;
	
	reg [23:0] allocating_page;//24bit
	reg [7:0] bad_block_flag;
	
	reg [2:0] channel_pointer;
	reg [DRAM_IO_WIDTH-1:0] prepare_for_allocation;
	reg [DRAM_ADDR_WIDTH-1:0] dram_addr;
	reg [127:0] free_block_fifo_heads;
	reg [127:0] free_block_fifo_tails;
	reg [15:0] free_block_pointer;
	reg [2:0] index;
	//reg [6:0] count;
	reg [5:0] state;
	reg [31:0] garbage_in_a_block;
	reg [DRAM_IO_WIDTH-1:0]garbage_entries;
	
	reg [511:0] data_from_dram_buf;
	reg [63:0]dram_data_mask_buf;	

	parameter COMMANDS_ISSUE0   =2'b00; 
	parameter COMMANDS_ISSUE1   =2'b01;
	parameter COMMANDS_ISSUE2   =2'b10;
	parameter COMMANDS_ISSUE3   =2'b11;
	
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

	
	always@ (negedge reset or posedge clk)
	begin
		if(!reset)
		begin
			paddr0_from_addr_management <= 0;
			paddr1_from_addr_management <= 0;
			page_table_entry            <= 0;
			addr_management_ready       <= 0;
			dram_en                     <= 0;
			data_to_dram_en             <= 0;
			data_to_dram_end            <= 0;
			dram_read_or_write          <= 0;
			addr_to_dram                <= 0;
			data_to_dram                <= 0;
			dram_data_mask              <= 0;
			addr_manage_dram_busy       <= 0;
			op                          <= 0;
			addr                        <= 0;	
			free_blocks                 <= 0;
			l2p_mapping_entries         <= 0;
			p2l_mapping_entries         <= 0;
			allocating_page	            <= 0;
			channel_pointer             <= 0;
			prepare_for_allocation      <= 0;
			dram_addr                   <= 0;
			free_block_fifo_heads       <= 0;
			free_block_fifo_tails       <= 128'b0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001;
			free_block_pointer          <= 0;
			index                       <= 0;
			//count                       <= 0;
			ci_data_cnt					<= 0;
			state                       <= INITIAL_REGISTER;
			garbage_in_a_block          <= 0;
			garbage_entries             <= 0;
			data_from_dram_buf          <= 0;
			dram_data_mask_buf          <= 0;	
			flash_left_capacity         <= 19'b100_00000000_00000000; //17'b1_11111111_10000000;
										    //back_up 8*5'b10000 blocks,所以减11_1111.
			bad_block_flag              <= 8'h0;

		end
		else
		begin
			case (state)
				INITIAL_REGISTER:
				begin
					if(register_ready)
				    begin
					    flash_left_capacity 	<=	flash_left_capacity_io;
						free_block_fifo_heads	<=	free_block_fifo_heads_io;
						free_block_fifo_tails	<=	free_block_fifo_tails_io;
						state <=IDLE;
					end
				end
				IDLE://00
				begin
					if(request_coming==1)
					begin
						addr_manage_dram_busy<=1;
						op <= request_op;
						addr <= addr_to_addr_management;
						state <= COMMAND_INTERPRET;
					end
				end
				COMMAND_INTERPRET:  //01//ָ
				begin
					case (op)
						READ:
							state <= READ_COMMAND;
						WRITE:
							state <= WRITE_COMMAND;
						MOVE:
							state <= MOVE_COMMAND;
						ERASE:
							state <= ERASE_COMMAND;	
					endcase
				end
				///////////////////////////////////////////////read
				READ_COMMAND://02
				begin
					dram_en <= 1;
					dram_read_or_write <= 1; //read
					addr_to_dram <= L2P_TABLE_BASE + addr[27:1];
					state <= GET_MAPPING_ENTRY_FOR_READ;
				end				
				GET_MAPPING_ENTRY_FOR_READ://03 //߼ַl2pϻַ
				begin	
					if(dram_ready)
					begin
						dram_en <= 0;	
					end
					if(rd_data_valid)
					begin
						data_from_dram_buf[255:0]<=data_from_dram;
						state<=GET_PADDR0_FOR_READ;
					end
				end
				GET_PADDR0_FOR_READ://04
				begin
					addr_management_ready <= 1;
					case (addr[0])
						1'b0:
							paddr0_from_addr_management <= data_from_dram_buf[26:0];//25λַ
						1'b1:
							paddr0_from_addr_management <= data_from_dram_buf[58:32];			
					endcase
					state <= FINISH;
				end
				///////////////////////////////////////////////write
				//////////write step 1 L2P
				WRITE_COMMAND://05
				begin
					dram_en <= 1;
					dram_read_or_write <= 1; //read
					addr_to_dram <= L2P_TABLE_BASE + addr[27:1];
					state <= GET_PADDR0_FOR_WRITE0;
				end
				GET_PADDR0_FOR_WRITE0: //06
				begin
					if(dram_ready)
					begin
						dram_en <= 0;
					end
					if(rd_data_valid)
					begin
						data_from_dram_buf[255:0]<=data_from_dram;
						state<=GET_PADDR0_FOR_WRITE1;												
					end
				end	
				GET_PADDR0_FOR_WRITE1://07
				begin
					case (addr[0])
						1'b0:begin
							paddr0_from_addr_management <= data_from_dram_buf[26:0];//25λַ
							page_table_entry	<=	data_from_dram_buf[31:0];
						end
						1'b1:begin
							paddr0_from_addr_management <= data_from_dram_buf[58:32];	
							page_table_entry	<=	data_from_dram_buf[63:32];
						end
					endcase
					state <= CHECK_PADDR0;
				end
				CHECK_PADDR0:
				begin
					//if(page_table_entry==32'b11111111_11111111_11111111_111111111) //该页无效，已经out-of-place更新，这种情况一般不会出现，因为p2l应该已经指向新的
					if(page_table_entry==32'b01111111_11111111_11111111_11111111)
						state<=ALLOCATE_NEW_PAGE;
					else
						state <= READY_FOR_INVALIDATE_P2L;
				end
				//////////write step2 P2L
				READY_FOR_INVALIDATE_P2L://08
				begin
					case(paddr0_from_addr_management[3:0])
						4'b0000:
						begin
							dram_data_mask_buf	<=64'hffffffff_fffffff0;
							p2l_mapping_entries <= {224'h0,32'hffffffff};	
						end
						4'b0001:
						begin
							dram_data_mask_buf	<=64'hffffffff_ffffff0f;
							p2l_mapping_entries <= {192'h0,32'hffffffff,32'h0};	
						end
						4'b0010:
						begin
							dram_data_mask_buf<=64'hffffffff_fffff0ff;
							p2l_mapping_entries <= {160'h0,32'hffffffff,64'h0};	
						end
						4'b0011:
						begin
							dram_data_mask_buf<=64'hffffffff_ffff0fff;
							p2l_mapping_entries <= {128'h0,32'hffffffff,96'h0};	
						end
						4'b0100:
						begin
							dram_data_mask_buf<=64'hffffffff_fff0ffff;
							p2l_mapping_entries <={96'h0,32'hffffffff,128'h0};	
						end
						4'b0101:
						begin
							dram_data_mask_buf<=64'hffffffff_ff0fffff;
							p2l_mapping_entries <= {64'h0,32'hffffffff,160'h0};	
						end
						4'b0110:
						begin
							dram_data_mask_buf<=64'hffffffff_f0ffffff;
							p2l_mapping_entries <= {32'h0,32'hffffffff,192'h0};	
						end
						4'b0111:
						begin
							dram_data_mask_buf<=64'hffffffff_0fffffff;
							p2l_mapping_entries <= {32'hffffffff,224'h0};	
						end
						4'b1000:
						begin
							dram_data_mask_buf<=64'hfffffff0_ffffffff;
							p2l_mapping_entries <= {224'h0,32'hffffffff};	
						end
						4'b1001:
						begin
							dram_data_mask_buf<=64'hffffff0f_ffffffff;
							p2l_mapping_entries <= {192'h0,32'hffffffff,32'h0};	
						end
						4'b1010:
						begin
							dram_data_mask_buf<=64'hfffff0ff_ffffffff;
							p2l_mapping_entries <= {160'h0,32'hffffffff,64'h0};
						end
						4'b1011:
						begin
							dram_data_mask_buf<=64'hffff0fff_ffffffff;
							p2l_mapping_entries <= {128'h0,32'hffffffff,96'h0};
						end
						4'b1100:
						begin
							dram_data_mask_buf<=64'hfff0ffff_ffffffff;
							p2l_mapping_entries <= {96'h0,32'hffffffff,128'h0};	
						end
						4'b1101:
						begin
							dram_data_mask_buf<=64'hff0fffff_ffffffff;
							p2l_mapping_entries <= {64'h0,32'hffffffff,160'h0};	
						end
						4'b1110:
						begin
							dram_data_mask_buf<=64'hf0ffffff_ffffffff;
							p2l_mapping_entries <= {32'h0,32'hffffffff,192'h0};	
						end
						4'b1111:
						begin
							dram_data_mask_buf<=64'h0fffffff_ffffffff;
							p2l_mapping_entries <=  {32'hffffffff,224'h0};	
						end
					endcase
					state <= INVALIDATE_P2L_MAPPING_TABLE0;
				end		
				INVALIDATE_P2L_MAPPING_TABLE0://0a	
				begin
					data_to_dram_en <= 1'b1;
					dram_data_mask <= dram_data_mask_buf[31:0]; 
					data_to_dram <=p2l_mapping_entries;
					state <= INVALIDATE_P2L_MAPPING_TABLE1;
				end	
				INVALIDATE_P2L_MAPPING_TABLE1://0b
				begin
					if(data_to_dram_ready)
					begin
						data_to_dram_end<= 1'b1;
						data_to_dram <=p2l_mapping_entries;
						dram_data_mask<=dram_data_mask_buf[63:32];

						dram_en <= 1;
						dram_read_or_write <= 0;//write
						addr_to_dram <= P2L_TABLE_BASE + {paddr0_from_addr_management[26:4],3'b000};
						state <= INVALIDATE_P2L_MAPPING_TABLE2;
					end
				end
				INVALIDATE_P2L_MAPPING_TABLE2://0c
				begin 
					if(dram_ready & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						state <= GET_GARBAGE_IN_BLOCK;

					end 
					else if (dram_ready)
					begin
						dram_en <= 0;
					end 
					else if (data_to_dram_ready) 
					begin
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;	
					end 
					else 
						state <= INVALIDATE_P2L_MAPPING_TABLE2;
				end
				//////////write step3 
				GET_GARBAGE_IN_BLOCK://0b  
				begin
					dram_en <=1;
					dram_read_or_write <= 1;//read
					addr_to_dram <= GARBAGE_TABLE_BASE + paddr0_from_addr_management[26:9];
					state <= RECEIVE_GARBAGE_IN_BLOCK; 
				end
				RECEIVE_GARBAGE_IN_BLOCK://0c
				begin
					if(dram_ready)
					begin
						dram_en <=0;	
					end
					if(rd_data_valid)
					begin						
						data_from_dram_buf[255:0] <= data_from_dram;
						state <= INCREAMENT_GARBAGE;
					end
				end
				INCREAMENT_GARBAGE://0d
				begin
					case (paddr0_from_addr_management[8])
						1'b0: 
							garbage_in_a_block <= data_from_dram_buf[7:0]+1;//1
						1'b1: 
							garbage_in_a_block <= data_from_dram_buf[39:32]+1;				
					endcase
					state <= READY_FOR_WRITE_BACK_GARBAGE;
				end
				READY_FOR_WRITE_BACK_GARBAGE://0e
				begin
					case(paddr0_from_addr_management[11:8])
						4'b0000:
						begin
							dram_data_mask_buf	<=64'hffffffff_fffffff0;
							garbage_entries <= {224'h0,garbage_in_a_block};	
						end
						4'b0001:
						begin
							dram_data_mask_buf	<=64'hffffffff_ffffff0f;
							garbage_entries <= {192'h0,garbage_in_a_block,32'h0};	
						end
						4'b0010:
						begin
							dram_data_mask_buf<=64'hffffffff_fffff0ff;
							garbage_entries <= {160'h0,garbage_in_a_block,64'h0};	
						end
						4'b0011:
						begin
							dram_data_mask_buf<=64'hffffffff_ffff0fff;
							garbage_entries <= {128'h0,garbage_in_a_block,96'h0};	
						end
						4'b0100:
						begin
							dram_data_mask_buf<=64'hffffffff_fff0ffff;
							garbage_entries <={96'h0,garbage_in_a_block,128'h0};	
						end
						4'b0101:
						begin
							dram_data_mask_buf<=64'hffffffff_ff0fffff;
							garbage_entries <= {64'h0,garbage_in_a_block,160'h0};	
						end
						4'b0110:
						begin
							dram_data_mask_buf<=64'hffffffff_f0ffffff;
							garbage_entries <= {32'h0,garbage_in_a_block,192'h0};	
						end
						4'b0111:
						begin
							dram_data_mask_buf<=64'hffffffff_0fffffff;
							garbage_entries <= {garbage_in_a_block,224'h0};	
						end
						4'b1000:
						begin
							dram_data_mask_buf<=64'hfffffff0_ffffffff;
							garbage_entries <= {224'h0,garbage_in_a_block};	
						end
						4'b1001:
						begin
							dram_data_mask_buf<=64'hffffff0f_ffffffff;
							garbage_entries <= {192'h0,garbage_in_a_block,32'h0};	
						end
						4'b1010:
						begin
							dram_data_mask_buf<=64'hfffff0ff_ffffffff;
							garbage_entries <= {160'h0,garbage_in_a_block,64'h0};
						end
						4'b1011:
						begin
							dram_data_mask_buf<=64'hffff0fff_ffffffff;
							garbage_entries <= {128'h0,garbage_in_a_block,96'h0};
						end
						4'b1100:
						begin
							dram_data_mask_buf<=64'hfff0ffff_ffffffff;
							garbage_entries <= {96'h0,garbage_in_a_block,128'h0};	
						end
						4'b1101:
						begin
							dram_data_mask_buf<=64'hff0fffff_ffffffff;
							garbage_entries <= {64'h0,garbage_in_a_block,160'h0};	
						end
						4'b1110:
						begin
							dram_data_mask_buf<=64'hf0ffffff_ffffffff;
							garbage_entries <= {32'h0,garbage_in_a_block,192'h0};	
						end
						4'b1111:
						begin
							dram_data_mask_buf<=64'h0fffffff_ffffffff;
							garbage_entries <=  {garbage_in_a_block,224'h0};	
						end
					endcase
					state <= WRITE_BACK_GARBAGE_IN_BLOCK0;
				end				
				WRITE_BACK_GARBAGE_IN_BLOCK0://11
				begin
					data_to_dram_en <= 1'b1;
					dram_data_mask<=dram_data_mask_buf[31:0];//mask
					data_to_dram <= garbage_entries;
					state <= WRITE_BACK_GARBAGE_IN_BLOCK1;					
				end
				WRITE_BACK_GARBAGE_IN_BLOCK1://12
				begin
					if(data_to_dram_ready)
					begin
						data_to_dram_end<= 1'b1;
						dram_data_mask <= dram_data_mask_buf[63:32]; //mask					
						data_to_dram <= garbage_entries;

						dram_en <= 1;
						dram_read_or_write <= 0; //write
						addr_to_dram <= GARBAGE_TABLE_BASE + {paddr0_from_addr_management[26:12], 3'b000};
						state <= WRITE_BACK_GARBAGE_IN_BLOCK2;
					end
				end		
				WRITE_BACK_GARBAGE_IN_BLOCK2://13
				begin
					if(dram_ready & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						state<=ALLOCATE_NEW_PAGE;
					end 
					else if (dram_ready)
					begin
						dram_en <= 0;
					end 
					else if (data_to_dram_ready) 
					begin
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;	
					end 
					else 
						state <= WRITE_BACK_GARBAGE_IN_BLOCK2;
				end
				////////////////////write step4
				ALLOCATE_NEW_PAGE://11
				begin
					case (channel_pointer)
						3'b000: allocating_page <= prepare_for_allocation[23:0];
						3'b001: allocating_page <= prepare_for_allocation[55:32];
						3'b010: allocating_page <= prepare_for_allocation[87:64];
						3'b011: allocating_page <= prepare_for_allocation[117:96];
						3'b100: allocating_page <= prepare_for_allocation[151:128];
						3'b101: allocating_page <= prepare_for_allocation[183:160];
						3'b110: allocating_page <= prepare_for_allocation[215:192];
						3'b111: allocating_page <= prepare_for_allocation[247:224];
					endcase	
					state<=READY_FOR_REFRESH_L2P;
				end				
				////////////////////write step 5 
				READY_FOR_REFRESH_L2P://12
				begin
					case (addr[3:0])//
						4'b0000:
						begin
							dram_data_mask_buf	<=64'hffffffff_fffffff0;
							l2p_mapping_entries <= {224'h0,5'b0,channel_pointer,allocating_page};	
						end
						4'b0001:
						begin
							dram_data_mask_buf	<=64'hffffffff_ffffff0f;
							l2p_mapping_entries <= {192'h0,5'b0,channel_pointer,allocating_page,32'h0};	
						end
						4'b0010:
						begin
							dram_data_mask_buf<=64'hffffffff_fffff0ff;
							l2p_mapping_entries <= {160'h0,5'b0,channel_pointer,allocating_page,64'h0};	
						end
						4'b0011:
						begin
							dram_data_mask_buf<=64'hffffffff_ffff0fff;
							l2p_mapping_entries <= {128'h0,5'b0,channel_pointer,allocating_page,96'h0};	
						end
						4'b0100:
						begin
							dram_data_mask_buf<=64'hffffffff_fff0ffff;
							l2p_mapping_entries <={96'h0,5'b0,channel_pointer,allocating_page,128'h0};	
						end
						4'b0101:
						begin
							dram_data_mask_buf<=64'hffffffff_ff0fffff;
							l2p_mapping_entries <= {64'h0,5'b0,channel_pointer,allocating_page,160'h0};	
						end
						4'b0110:
						begin
							dram_data_mask_buf<=64'hffffffff_f0ffffff;
							l2p_mapping_entries <= {32'h0,5'b0,channel_pointer,allocating_page,192'h0};	
						end
						4'b0111:
						begin
							dram_data_mask_buf<=64'hffffffff_0fffffff;
							l2p_mapping_entries <= {5'b0,channel_pointer,allocating_page,224'h0};	
						end
						4'b1000:
						begin
							dram_data_mask_buf<=64'hfffffff0_ffffffff;
							l2p_mapping_entries <= {224'h0,5'b0,channel_pointer,allocating_page};	
						end
						4'b1001:
						begin
							dram_data_mask_buf<=64'hffffff0f_ffffffff;
							l2p_mapping_entries <= {192'h0,5'b0,channel_pointer,allocating_page,32'h0};	
						end
						4'b1010:
						begin
							dram_data_mask_buf<=64'hfffff0ff_ffffffff;
							l2p_mapping_entries <= {160'h0,5'b0,channel_pointer,allocating_page,64'h0};
						end
						4'b1011:
						begin
							dram_data_mask_buf<=64'hffff0fff_ffffffff;
							l2p_mapping_entries <= {128'h0,5'b0,channel_pointer,allocating_page,96'h0};
						end
						4'b1100:
						begin
							dram_data_mask_buf<=64'hfff0ffff_ffffffff;
							l2p_mapping_entries <= {96'h0,5'b0,channel_pointer,allocating_page,128'h0};	
						end
						4'b1101:
						begin
							dram_data_mask_buf<=64'hff0fffff_ffffffff;
							l2p_mapping_entries <= {64'h0,5'b0,channel_pointer,allocating_page,160'h0};	
						end
						4'b1110:
						begin
							dram_data_mask_buf<=64'hf0ffffff_ffffffff;
							l2p_mapping_entries <= {32'h0,5'b0,channel_pointer,allocating_page,192'h0};	
						end
						4'b1111:
						begin
							dram_data_mask_buf<=64'h0fffffff_ffffffff;
							l2p_mapping_entries <=  {5'b0,channel_pointer,allocating_page,224'h0};	
						end		
					endcase
					state <= WRITE_BACK_L2P_MAPPING_TABLE0;
				end
				WRITE_BACK_L2P_MAPPING_TABLE0://16
				begin
					data_to_dram_en <= 1'b1;
					dram_data_mask<=dram_data_mask_buf[31:0];//mask
					data_to_dram <= l2p_mapping_entries;
					state <= WRITE_BACK_L2P_MAPPING_TABLE1;					
					
				end
				WRITE_BACK_L2P_MAPPING_TABLE1://17
				begin
					if(data_to_dram_ready)
					begin
						data_to_dram_end<= 1'b1;
						data_to_dram <= l2p_mapping_entries;
						dram_data_mask <= dram_data_mask_buf[63:32]; //mask

						dram_en <= 1;
						dram_read_or_write <= 0;//write
						addr_to_dram <= L2P_TABLE_BASE + {2'b00, addr[27:4],3'b000};					
						state <= WRITE_BACK_L2P_MAPPING_TABLE2;
					end
				end	
				WRITE_BACK_L2P_MAPPING_TABLE2:	//18
				begin
					if(dram_ready & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						state <= READY_FOR_REFRESH_P2L;
					end 
					else if (dram_ready)
					begin
						dram_en <= 0;
					end 
					else if (data_to_dram_ready) 
					begin
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;	
					end 
					else 
						state <= WRITE_BACK_L2P_MAPPING_TABLE2;
					
				end
				////////////////////write step 6 P2L			
				READY_FOR_REFRESH_P2L: //15
				begin
					case (allocating_page[3:0])
						4'b0000:
						begin
							dram_data_mask_buf	<=64'hffffffff_fffffff0;
							p2l_mapping_entries <= {224'h0,4'b0000,addr};	
						end
						4'b0001:
						begin
							dram_data_mask_buf	<=64'hffffffff_ffffff0f;
							p2l_mapping_entries <= {192'h0,4'b0000,addr,32'h0};	
						end
						4'b0010:
						begin
							dram_data_mask_buf<=64'hffffffff_fffff0ff;
							p2l_mapping_entries <= {160'h0,4'b0000,addr,64'h0};	
						end
						4'b0011:
						begin
							dram_data_mask_buf<=64'hffffffff_ffff0fff;
							p2l_mapping_entries <= {128'h0,4'b0000,addr,96'h0};	
						end
						4'b0100:
						begin
							dram_data_mask_buf<=64'hffffffff_fff0ffff;
							p2l_mapping_entries <={96'h0,4'b0000,addr,128'h0};	
						end
						4'b0101:
						begin
							dram_data_mask_buf<=64'hffffffff_ff0fffff;
							p2l_mapping_entries <= {64'h0,4'b0000,addr,160'h0};	
						end
						4'b0110:
						begin
							dram_data_mask_buf<=64'hffffffff_f0ffffff;
							p2l_mapping_entries <= {32'h0,4'b0000,addr,192'h0};	
						end
						4'b0111:
						begin
							dram_data_mask_buf<=64'hffffffff_0fffffff;
							p2l_mapping_entries <= {4'b0000,addr,224'h0};	
						end
						4'b1000:
						begin
							dram_data_mask_buf<=64'hfffffff0_ffffffff;
							p2l_mapping_entries <= {224'h0,4'b0000,addr};	
						end
						4'b1001:
						begin
							dram_data_mask_buf<=64'hffffff0f_ffffffff;
							p2l_mapping_entries <= {192'h0,4'b0000,addr,32'h0};	
						end
						4'b1010:
						begin
							dram_data_mask_buf<=64'hfffff0ff_ffffffff;
							p2l_mapping_entries <= {160'h0,4'b0000,addr,64'h0};
						end
						4'b1011:
						begin
							dram_data_mask_buf<=64'hffff0fff_ffffffff;
							p2l_mapping_entries <= {128'h0,4'b0000,addr,96'h0};
						end
						4'b1100:
						begin
							dram_data_mask_buf<=64'hfff0ffff_ffffffff;
							p2l_mapping_entries <= {96'h0,4'b0000,addr,128'h0};	
						end
						4'b1101:
						begin
							dram_data_mask_buf<=64'hff0fffff_ffffffff;
							p2l_mapping_entries <= {64'h0,4'b0000,addr,160'h0};	
						end
						4'b1110:
						begin
							dram_data_mask_buf<=64'hf0ffffff_ffffffff;
							p2l_mapping_entries <= {32'h0,4'b0000,addr,192'h0};	
						end
						4'b1111:
						begin
							dram_data_mask_buf<=64'h0fffffff_ffffffff;
							p2l_mapping_entries <=  {4'b0000,addr,224'h0};	
						end		
					endcase
					state <= REFRESH_P2L_MAPPING_TABLE0;
				end
				REFRESH_P2L_MAPPING_TABLE0://1a
				begin
					data_to_dram_en <= 1'b1;
					dram_data_mask<=dram_data_mask_buf[31:0];//mask
					data_to_dram <= p2l_mapping_entries;
					state <= REFRESH_P2L_MAPPING_TABLE1;					
					
				end
				REFRESH_P2L_MAPPING_TABLE1://1b
				begin
					if(data_to_dram_ready)
					begin
						data_to_dram_end<= 1'b1;
						data_to_dram <= p2l_mapping_entries;
						dram_data_mask <= dram_data_mask_buf[63:32]; //mask

						dram_en <= 1;
						dram_read_or_write <= 0;//write
						addr_to_dram <= P2L_TABLE_BASE + {3'b000, channel_pointer,allocating_page[23:4],3'b000};
						state <= REFRESH_P2L_MAPPING_TABLE2;
					end
				end	
				REFRESH_P2L_MAPPING_TABLE2:	//1c
				begin
					if(dram_ready & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						paddr1_from_addr_management <= {channel_pointer,allocating_page};
						allocating_page<=allocating_page+1;
						state <= CHECK_NEXT_PAGE;
					end 
					else if (dram_ready)
					begin
						dram_en <= 0;
					end 
					else if (data_to_dram_ready) 
					begin
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;	
					end 
					else 
						state <= REFRESH_P2L_MAPPING_TABLE2;
					
				end					
				CHECK_NEXT_PAGE://18
				begin
					if(allocating_page[10:0]==0)   //all pages of the the block are allocated
					begin
						case (channel_pointer)
							3'b000:
							begin
								free_block_pointer <=  free_block_fifo_tails[15:0];
								if(free_block_fifo_tails[15:0]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[15:0] <= 0; 
								else free_block_fifo_tails[15:0] <= free_block_fifo_tails[15:0] + 1;
							end
							3'b001:
							begin
								free_block_pointer <=  free_block_fifo_tails[31:16];
								if(free_block_fifo_tails[31:16]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[31:16] <= 0; 
								else free_block_fifo_tails[31:16] <= free_block_fifo_tails[31:16] + 1;
							end
							3'b010:
							begin
								free_block_pointer <=  free_block_fifo_tails[47:32];
								if(free_block_fifo_tails[47:32]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[47:32] <= 0; 
								else free_block_fifo_tails[47:32] <= free_block_fifo_tails[47:32] + 1;
							end
							3'b011:
							begin
								free_block_pointer <=  free_block_fifo_tails[63:48];
								if(free_block_fifo_tails[63:48]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[63:48] <= 0; 
								else free_block_fifo_tails[63:48] <= free_block_fifo_tails[63:48] + 1;
							end
							3'b100:
							begin
								free_block_pointer <=  free_block_fifo_tails[79:64];
								if(free_block_fifo_tails[79:64]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[79:64] <= 0; 
								else 	free_block_fifo_tails[79:64] <= free_block_fifo_tails[79:64] + 1;
							end
							3'b101:
							begin
								free_block_pointer <=  free_block_fifo_tails[95:80];
								if(free_block_fifo_tails[95:80]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[95:80] <= 0; 
								else free_block_fifo_tails[95:80] <= free_block_fifo_tails[95:80] + 1;
							end
							3'b110:
							begin
								free_block_pointer <=  free_block_fifo_tails[111:96];
								if(free_block_fifo_tails[111:96]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[111:96] <= 0; 
								else  free_block_fifo_tails[111:96] <= free_block_fifo_tails[111:96] + 1;
							end
							3'b111:
							begin
								free_block_pointer <=  free_block_fifo_tails[127:112];
								if(free_block_fifo_tails[127:112]==16'b1111_1111_1110_1111)
									free_block_fifo_tails[127:112] <= 0; 
								else free_block_fifo_tails[127:112] <= free_block_fifo_tails[127:112] + 1;
							end
						endcase
						state <= ALLOCATE_NEW_BLOCK;//WRITE_BACK_GARBAGE_IN_BLOCK

					end
					else
						state<=WRITE_END;
				end
				ALLOCATE_NEW_BLOCK://19
				begin
					dram_en <= 1;
					dram_read_or_write <= 1;//read
					addr_to_dram <= FREE_BLOCK_FIFO_BASE + {channel_pointer, free_block_pointer[15:1]};   //should be modified
					state <= GET_A_FREE_BLOCK0;
				end				
				GET_A_FREE_BLOCK0://1a
				begin
					if(dram_ready)
					begin
						dram_en <= 0;				
					end
					if(rd_data_valid)
					begin
						data_from_dram_buf[255:0]<=data_from_dram;	
						state<=GET_A_FREE_BLOCK1;
					end
					else 
						state <= GET_A_FREE_BLOCK0;
				end
				GET_A_FREE_BLOCK1://1b
				begin
					case (free_block_pointer[0])
						1'b0:
							allocating_page <= data_from_dram_buf[23:0];//һblockָ0ҳ
						1'b1:
							allocating_page <= data_from_dram_buf[55:32];			
					endcase
					flash_left_capacity<=flash_left_capacity-1;//flash1
					state <= CHECK_BAD_BLOCK0;	
				end
				CHECK_BAD_BLOCK0:
				begin
					dram_en <= 1;
					dram_read_or_write <= 1;//read
					addr_to_dram <= BAD_BLOCK_INFO_BASE + {allocating_page[23],channel_pointer, allocating_page[22:14]}; // the addr decided by the bad block info distribution
					state <= CHECK_BAD_BLOCK1;								
				end
				CHECK_BAD_BLOCK1:
				begin
					if(dram_ready)
					begin
						dram_en <= 0;				
					end
					if(rd_data_valid)
					begin
						data_from_dram_buf[63:0] <=data_from_dram[63:0];	
						state<=CHECK_BAD_BLOCK2;
					end
					else 
						state <= CHECK_BAD_BLOCK1;
				end
				CHECK_BAD_BLOCK2:
				begin
					case(allocating_page[13:11])
						3'h0:bad_block_flag <= data_from_dram_buf[8*1-1:0];
						3'h1:bad_block_flag <= data_from_dram_buf[8*2-1:8*1];
						3'h2:bad_block_flag <= data_from_dram_buf[8*3-1:8*2];
						3'h3:bad_block_flag <= data_from_dram_buf[8*4-1:8*3];
						3'h4:bad_block_flag <= data_from_dram_buf[8*5-1:8*4];
						3'h5:bad_block_flag <= data_from_dram_buf[8*6-1:8*5];
						3'h6:bad_block_flag <= data_from_dram_buf[8*7-1:8*6];
						3'h7:bad_block_flag <= data_from_dram_buf[8*8-1:8*7];
					endcase
					state <= CHECK_BAD_BLOCK3;
				end
				CHECK_BAD_BLOCK3:
				begin
					if(bad_block_flag == 8'hff)
					begin
						state <= WRITE_END;
					end
					else
					begin
						allocating_page[10:0] <= 11'h0;
						state <= CHECK_NEXT_PAGE;
					end
				end
				WRITE_END://1c
				begin		
					case (channel_pointer)
						3'b000: prepare_for_allocation[23:0]    <= allocating_page;
						3'b001: prepare_for_allocation[55:32]   <= allocating_page;
						3'b010: prepare_for_allocation[87:64]   <= allocating_page;
						3'b011: prepare_for_allocation[119:96]  <= allocating_page;
						3'b100: prepare_for_allocation[151:128] <= allocating_page;
						3'b101: prepare_for_allocation[183:160] <= allocating_page;
						3'b110: prepare_for_allocation[215:192] <= allocating_page;
						3'b111: prepare_for_allocation[247:224] <= allocating_page;
					endcase
					channel_pointer <= channel_pointer + 1;					
					addr_management_ready <= 1;
					state <= FINISH;				
				end	
				////////////////////////////////////////////////////////////////MOVE
				MOVE_COMMAND://1d
				begin
					dram_en <= 1;
					dram_read_or_write <= 1; //read
					addr_to_dram <= L2P_TABLE_BASE + addr[27:1];
					state <= GET_MAPPING_ENTRY_FOR_MOVE;
				end
				GET_MAPPING_ENTRY_FOR_MOVE://1e
				begin
					if(dram_ready)
					begin
						dram_en <= 0;
					end
					if(rd_data_valid)
					begin
						data_from_dram_buf[255:0]<=data_from_dram;
						state <= GET_PADDR0_FOR_MOVE;
					end
				end
				GET_PADDR0_FOR_MOVE://1f
				begin
					case (addr[0])
						1'b0:
						begin
							paddr0_from_addr_management <= data_from_dram_buf[26:0];
							channel_pointer<=data_from_dram_buf[26:24];
						end
						1'b1:
						begin
							paddr0_from_addr_management <= data_from_dram_buf[58:32];
							channel_pointer<=data_from_dram_buf[58:56];
						end
					endcase
					state <= INVALIDATE_P2L_MAPPING_TABLE0;//move
				end
				//////////////////////////////////////////////////////////////////////////////ERASE
				ERASE_COMMAND://20
				begin
					if(ci_done)
					begin
						ci_en <= 1;
						dram_read_or_write <= 0; //write
						ci_addr <=P2L_TABLE_BASE + {2'b00,addr[27:3], 3'b000};
						ci_num	<= 16;
						dram_data_mask <= 0; //no mask
						data_to_dram <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;
						data_to_dram_en <= 1'b1;
						ci_data_cnt <= 0;
						state <= ERASE_COMMAND1;
					end
				end
				ERASE_COMMAND1://21
				begin
					ci_en <= 0;
					if (data_to_dram_ready) 
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;//һҳ32b01111111_11111111_11111111_11111111ʾ
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						state <= ERASE_COMMAND2;
					end		
				end
				ERASE_COMMAND2://22
				begin
				if(ci_data_cnt<ci_num)
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;//һҳ32b01111111_11111111_11111111_11111111ʾ
						data_to_dram_end <= 1'b0;
						data_to_dram_en <= 1'b1;
						state <= ERASE_COMMAND1;
					end
				end
				else 
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;//һҳ32b01111111_11111111_11111111_11111111ʾ
						data_to_dram_end <= 1'b0;
						data_to_dram_en <=  1'b0;
						
						index <= addr[26:24];
						state <= ADD_FREE_BLOCK_TO_FIFO;
					end
				end
				end
				ADD_FREE_BLOCK_TO_FIFO://23
				begin
					case (index)
						3'b000: dram_addr <= {index, free_block_fifo_heads[15:0]};
						3'b001: dram_addr <= {index, free_block_fifo_heads[31:16]};
						3'b010: dram_addr <= {index, free_block_fifo_heads[47:32]};
						3'b011: dram_addr <= {index, free_block_fifo_heads[63:48]};
						3'b100: dram_addr <= {index, free_block_fifo_heads[79:64]};
						3'b101: dram_addr <= {index, free_block_fifo_heads[95:80]};
						3'b110: dram_addr <= {index, free_block_fifo_heads[111:96]};
						3'b111: dram_addr <= {index, free_block_fifo_heads[127:112]};
					endcase
					dram_en <= 1;
					dram_read_or_write <= 1;//read
					addr_to_dram <= FREE_BLOCK_FIFO_BASE + {dram_addr[28:1]};
					state <= GET_DATA_FROM_DRAM;
				end
				GET_DATA_FROM_DRAM://24
				begin
					if(dram_ready)
					begin
						dram_en <= 0;						
						state <= RECEIVE_DATA_FROM_DRAM;
					end
				end
				RECEIVE_DATA_FROM_DRAM://25
				begin
					if(rd_data_valid)
					begin
						free_blocks <= data_from_dram;
						state <= MODIFY_FREE_BLOCKS;
					end
				end
				MODIFY_FREE_BLOCKS://26
				begin
					case (dram_addr[3:0])
						4'b0000:
						begin
							dram_data_mask_buf	<=64'hffffffff_fffffff0;
							free_blocks <= {224'h0,4'b0000,addr};	
						end
						4'b0001:
						begin
							dram_data_mask_buf	<=64'hffffffff_ffffff0f;
							free_blocks <= {192'h0,4'b0000,addr,32'h0};	
						end
						4'b0010:
						begin
							dram_data_mask_buf<=64'hffffffff_fffff0ff;
							free_blocks <= {160'h0,4'b0000,addr,64'h0};	
						end
						4'b0011:
						begin
							dram_data_mask_buf<=64'hffffffff_ffff0fff;
							free_blocks <= {128'h0,4'b0000,addr,96'h0};	
						end
						4'b0100:
						begin
							dram_data_mask_buf<=64'hffffffff_fff0ffff;
							free_blocks <={96'h0,4'b0000,addr,128'h0};	
						end
						4'b0101:
						begin
							dram_data_mask_buf<=64'hffffffff_ff0fffff;
							free_blocks <= {64'h0,4'b0000,addr,160'h0};	
						end
						4'b0110:
						begin
							dram_data_mask_buf<=64'hffffffff_f0ffffff;
							free_blocks <= {32'h0,4'b0000,addr,192'h0};	
						end
						4'b0111:
						begin
							dram_data_mask_buf<=64'hffffffff_0fffffff;
							free_blocks <= {4'b0000,addr,224'h0};	
						end
						4'b1000:
						begin
							dram_data_mask_buf<=64'hfffffff0_ffffffff;
							free_blocks <= {224'h0,4'b0000,addr};	
						end
						4'b1001:
						begin
							dram_data_mask_buf<=64'hffffff0f_ffffffff;
							free_blocks <= {192'h0,4'b0000,addr,32'h0};	
						end
						4'b1010:
						begin
							dram_data_mask_buf<=64'hfffff0ff_ffffffff;
							free_blocks <= {160'h0,4'b0000,addr,64'h0};
						end
						4'b1011:
						begin
							dram_data_mask_buf<=64'hffff0fff_ffffffff;
							free_blocks <= {128'h0,4'b0000,addr,96'h0};
						end
						4'b1100:
						begin
							dram_data_mask_buf<=64'hfff0ffff_ffffffff;
							free_blocks <= {96'h0,4'b0000,addr,128'h0};	
						end
						4'b1101:
						begin
							dram_data_mask_buf<=64'hff0fffff_ffffffff;
							free_blocks <= {64'h0,4'b0000,addr,160'h0};	
						end
						4'b1110:
						begin
							dram_data_mask_buf<=64'hf0ffffff_ffffffff;
							free_blocks <= {32'h0,4'b0000,addr,192'h0};	
						end
						4'b1111:
						begin
							dram_data_mask_buf<=64'h0fffffff_ffffffff;
							free_blocks <=  {4'b0000,addr,224'h0};	
						end		
					endcase
						state <= WRITE_BACK_FREE_BLOCKS0;
				end
				WRITE_BACK_FREE_BLOCKS0://27
				begin
				if(ci_done)
					begin					
					    data_to_dram_en <= 1'b1;
						data_to_dram <= free_blocks;						
						dram_data_mask <= dram_data_mask_buf[31:0]; //mask
						state <= WRITE_BACK_FREE_BLOCKS1;
					end
				end
				WRITE_BACK_FREE_BLOCKS1:			
				begin
					if(data_to_dram_ready) 
						begin
						dram_en <= 1;
						dram_read_or_write <= 0;//write
						addr_to_dram <= FREE_BLOCK_FIFO_BASE + dram_addr[28:1];
						data_to_dram_end<= 1'b1;
						data_to_dram <= free_blocks;						
						dram_data_mask <= dram_data_mask_buf[63:32]; //mask
						state	<= WRITE_BACK_FREE_BLOCKS2;
						end		
				end				
				WRITE_BACK_FREE_BLOCKS2://3b
				begin 
					if(dram_ready & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						state <= WRITE_BACK_FREE_BLOCKS3;	
					end 
					else if (dram_ready)
					begin
						dram_en <= 0;
					end 
					else if (data_to_dram_ready) 
					begin
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;	
					end 
					else 
						state <= WRITE_BACK_FREE_BLOCKS2;
				end	
				WRITE_BACK_FREE_BLOCKS3://28
				begin
					case (index)
						3'b000:begin
								if(free_block_fifo_heads[15:0]==16'b1111_1111_1110_1111) 
									free_block_fifo_heads[15:0] <= 0;  //every channel space from 14'h3ff0 to 14'h3fff preserved for metadata store
								else free_block_fifo_heads[15:0]  <= free_block_fifo_heads[15:0] + 1;
						end
						3'b001: begin
								if(free_block_fifo_heads[31:16]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[31:16] <= 0; 
								else free_block_fifo_heads[31:16] <= free_block_fifo_heads[31:16] + 1;
						end
						3'b010: begin
								if(free_block_fifo_heads[47:32]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[47:32] <= 0; 
								else free_block_fifo_heads[47:32] <= free_block_fifo_heads[47:32] + 1;
						end
						3'b011: begin
								if(free_block_fifo_heads[63:48]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[63:48] <= 0; 
								else free_block_fifo_heads[63:48] <= free_block_fifo_heads[63:48]  + 1;
						end
						3'b100: begin
								if(free_block_fifo_heads[79:64]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[79:64] <= 0; 
								else free_block_fifo_heads[79:64] <= free_block_fifo_heads[79:64] + 1;
						end
						3'b101: begin
								if(free_block_fifo_heads[95:80]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[95:80] <= 0; 
								else free_block_fifo_heads[95:80] <= free_block_fifo_heads[95:80] + 1;
						end
						3'b110: begin
								if(free_block_fifo_heads[111:96]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[111:96] <= 0; 
								else free_block_fifo_heads[111:96] <= free_block_fifo_heads[111:96] + 1;
						end
						3'b111: begin
								if(free_block_fifo_heads[127:112]==16'b1111_1111_1110_1111)
									free_block_fifo_heads[127:112] <= 0; 
								else free_block_fifo_heads[127:112]<= free_block_fifo_heads[127:112] + 1;
						end
					endcase
					flash_left_capacity<=flash_left_capacity+1;//flash1
					addr_management_ready <= 1;  // erase operation done! 
					state <= FINISH;
				end
				FINISH://3f
				begin
					//if(count>=4)
					//begin
						addr_manage_dram_busy <=0;
						addr_management_ready <= 0;
						//count<=0;
						state <= IDLE;
					//end
					//else
					//	count<=count+1;
				end
				default: state <= IDLE;
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
					if(dram_ready)
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
