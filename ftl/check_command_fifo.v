module check_command_fifo(	
	reset,
	clk,
	init_dram_done,
	all_controller_command_fifo_empty,
	finish_command_fifo0_empty_or_not,
	finish_command_fifo1_empty_or_not,	
	finish_command_fifo2_empty_or_not,	
	finish_command_fifo3_empty_or_not,
	finish_command_fifo4_empty_or_not,	
	finish_command_fifo5_empty_or_not,
	finish_command_fifo6_empty_or_not,	
	finish_command_fifo7_empty_or_not,
	finish_command_fifo8_empty_or_not,
	finish_command_fifo0_out,
	finish_command_fifo1_out,	
	finish_command_fifo2_out,	
	finish_command_fifo3_out,
	finish_command_fifo4_out,	
	finish_command_fifo5_out,
	finish_command_fifo6_out,	
	finish_command_fifo7_out,
	finish_command_fifo8_out,
	read_data_fifo0_out,
	read_data_fifo1_out,
	read_data_fifo2_out,
	read_data_fifo3_out,
	read_data_fifo4_out,
	read_data_fifo5_out,
	read_data_fifo6_out,
	read_data_fifo7_out,
	data_from_dram,
	dram_ready,	
	rd_data_valid,
	dram_permit,
	pcie_data_send_fifo_out_prog_full,
	pcie_command_send_fifo_full_or_not,	//pcie_command_send_fifopcie_data_send_fifoǶԳƵģֻһfifoǷ
	//output
	finish_command_fifo0_out_en,
	finish_command_fifo1_out_en,	
	finish_command_fifo2_out_en,	
	finish_command_fifo3_out_en,
	finish_command_fifo4_out_en,	
	finish_command_fifo5_out_en,
	finish_command_fifo6_out_en,	
	finish_command_fifo7_out_en,
	finish_command_fifo8_out_en,
	read_data_fifo0_out_en,
	read_data_fifo1_out_en,
	read_data_fifo2_out_en,
	read_data_fifo3_out_en,
	read_data_fifo4_out_en,
	read_data_fifo5_out_en,
	read_data_fifo6_out_en,
	read_data_fifo7_out_en,
	dram_request,
	release_dram,
	addr_to_dram_o,
	data_to_dram,
	dram_data_mask, 
	dram_en_o,
	dram_read_or_write,
	data_to_dram_en,
	data_to_dram_end,
	data_to_dram_ready,	
	
	pcie_data_send_fifo_in,
	pcie_data_send_fifo_in_en,
	pcie_command_send_fifo_in,
	pcie_command_send_fifo_in_en,
	
	left_capacity_final,//512GB flash有2的17次方个块
	free_block_fifo_tails,
	free_block_fifo_heads,
	register_ready,
	initial_dram_done,
	state
	);
	
	`include"ftl_define.v"
	input reset;
	input clk;
	input init_dram_done;
	input all_controller_command_fifo_empty;
	input finish_command_fifo0_empty_or_not;
	input finish_command_fifo1_empty_or_not	;
	input finish_command_fifo2_empty_or_not	;
	input finish_command_fifo3_empty_or_not;
	input finish_command_fifo4_empty_or_not	;
	input finish_command_fifo5_empty_or_not;
	input finish_command_fifo6_empty_or_not	;
	input finish_command_fifo7_empty_or_not;
	input finish_command_fifo8_empty_or_not;
	input [COMMAND_WIDTH-1:0]finish_command_fifo0_out;
	input [COMMAND_WIDTH-1:0]finish_command_fifo1_out;
	input [COMMAND_WIDTH-1:0]finish_command_fifo2_out;	
	input [COMMAND_WIDTH-1:0]finish_command_fifo3_out;
	input [COMMAND_WIDTH-1:0]finish_command_fifo4_out;	
	input [COMMAND_WIDTH-1:0]finish_command_fifo5_out;
	input [COMMAND_WIDTH-1:0]finish_command_fifo6_out;	
	input [COMMAND_WIDTH-1:0]finish_command_fifo7_out;
	input [COMMAND_WIDTH-1:0]finish_command_fifo8_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo0_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo1_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo2_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo3_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo4_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo5_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo6_out;
	input [DRAM_IO_WIDTH-1:0]read_data_fifo7_out;
	input [DRAM_IO_WIDTH-1:0]data_from_dram;
	input dram_ready;	
	input rd_data_valid;
	input dram_permit;
	input pcie_data_send_fifo_out_prog_full;
	input pcie_command_send_fifo_full_or_not;	//pcie_command_send_fifopcie_data_send_fifoǶԳƵģֻһfifoǷ
	//output
	input	data_to_dram_ready;
	output	data_to_dram_en;
	output	data_to_dram_end;	
	
	output finish_command_fifo0_out_en;
	output finish_command_fifo1_out_en;
	output finish_command_fifo2_out_en;	
	output finish_command_fifo3_out_en;
	output finish_command_fifo4_out_en;	
	output finish_command_fifo5_out_en;
	output finish_command_fifo6_out_en;
	output finish_command_fifo7_out_en;
	output finish_command_fifo8_out_en;
	output read_data_fifo0_out_en;
	output read_data_fifo1_out_en;
	output read_data_fifo2_out_en;
	output read_data_fifo3_out_en;
	output read_data_fifo4_out_en;
	output read_data_fifo5_out_en;
	output read_data_fifo6_out_en;
	output read_data_fifo7_out_en;
	output dram_request;
	output release_dram;
	output [DRAM_ADDR_WIDTH-1:0]addr_to_dram_o;
	output [DRAM_IO_WIDTH-1:0]data_to_dram;
	output [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	output dram_en_o;
	output dram_read_or_write;
	output [DRAM_IO_WIDTH-1:0]pcie_data_send_fifo_in;
	output pcie_data_send_fifo_in_en;
	output [COMMAND_WIDTH-1:0]pcie_command_send_fifo_in;
	output pcie_command_send_fifo_in_en;
	output [18:0]left_capacity_final;//512GB flash有2的17次方个块
	output [127:0] free_block_fifo_tails;
	output [127:0] free_block_fifo_heads;
	output register_ready;
	output initial_dram_done;
	output [5:0] state;
	
	reg finish_command_fifo0_out_en;
	reg finish_command_fifo1_out_en;
	reg finish_command_fifo2_out_en;	
	reg finish_command_fifo3_out_en;
	reg finish_command_fifo4_out_en;	
	reg finish_command_fifo5_out_en;
	reg finish_command_fifo6_out_en;
	reg finish_command_fifo7_out_en;
	reg finish_command_fifo8_out_en;
	reg read_data_fifo0_out_en;
	reg read_data_fifo1_out_en;
	reg read_data_fifo2_out_en;
	reg read_data_fifo3_out_en;
	reg read_data_fifo4_out_en;
	reg read_data_fifo5_out_en;
	reg read_data_fifo6_out_en;
	reg read_data_fifo7_out_en;
	reg dram_request;
	reg release_dram;
	reg [DRAM_ADDR_WIDTH-1:0]addr_to_dram;
	reg [DRAM_IO_WIDTH-1:0]data_to_dram;
	reg [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	reg dram_en;
	reg dram_read_or_write;

	reg [DRAM_IO_WIDTH-1:0]pcie_data_send_fifo_in;
	reg pcie_data_send_fifo_in_en;
	reg [COMMAND_WIDTH-1:0]pcie_command_send_fifo_in;
	reg pcie_command_send_fifo_in_en;
	reg [DRAM_IO_WIDTH-1:0]data_tmp;
	
	reg [18:0]left_capacity_final;//512GB flash有2的17次方个块
	reg [127:0] free_block_fifo_tails;
	reg [127:0] free_block_fifo_heads;
	wire finish_command_fifo_empty_or_not;
	assign finish_command_fifo_empty_or_not=finish_command_fifo0_empty_or_not & finish_command_fifo1_empty_or_not & finish_command_fifo2_empty_or_not & finish_command_fifo3_empty_or_not & 						finish_command_fifo4_empty_or_not & finish_command_fifo5_empty_or_not & finish_command_fifo6_empty_or_not & finish_command_fifo7_empty_or_not ;
	
	parameter CHECK_COMMAND_FIFO0		=6'b000000;
	parameter CHECK_COMMAND_FIFO1		=6'b000001;
	parameter CHECK_COMMAND_FIFO2		=6'b000010;
	parameter CHECK_COMMAND_FIFO3		=6'b000011;
	parameter CHECK_COMMAND_FIFO4		=6'b000100;
	parameter CHECK_COMMAND_FIFO5		=6'b000101;
	parameter CHECK_COMMAND_FIFO6		=6'b000110;
	parameter CHECK_COMMAND_FIFO7		=6'b000111;
	parameter CHECK_COMMAND_FIFO8		=6'b001000;	
	parameter COMMAND_INTERPRET		    =6'b001001;
	parameter INITIAL_DRAM_READ_COMMAND =6'b001010;
	parameter REGISTER_READ_COMMAND	=6'b001011;		
	parameter WAIT_DRAM			    =6'b001100;
	parameter DATA_FIFO0_WRITE0		=6'b001101;	
	parameter DATA_FIFO0_WRITE1		=6'b001110;
	parameter DATA_FIFO0_WRITE2		=6'b001111;
	parameter DATA_FIFO0_WRITE3		=6'b010000;
	parameter DATA_FIFO1_WRITE0		=6'b010001;
	parameter DATA_FIFO1_WRITE1		=6'b010010;
	parameter DATA_FIFO1_WRITE2		=6'b010011;
	parameter DATA_FIFO1_WRITE3		=6'b010100;
	parameter DATA_FIFO2_WRITE0		=6'b010101;
	parameter DATA_FIFO2_WRITE1		=6'b010110;
	parameter DATA_FIFO2_WRITE2		=6'b010111;
	parameter DATA_FIFO2_WRITE3		=6'b011000;
	parameter DATA_FIFO3_WRITE0		=6'b011001;
	parameter DATA_FIFO3_WRITE1		=6'b011010;
	parameter DATA_FIFO3_WRITE2		=6'b011011;
	parameter DATA_FIFO3_WRITE3		=6'b011100;
	parameter DATA_FIFO4_WRITE0		=6'b011101;
	parameter DATA_FIFO4_WRITE1		=6'b011110;
	parameter DATA_FIFO4_WRITE2		=6'b011111;
	parameter DATA_FIFO4_WRITE3		=6'b100000;
	parameter DATA_FIFO5_WRITE0		=6'b100001;
	parameter DATA_FIFO5_WRITE1		=6'b100010;
	parameter DATA_FIFO5_WRITE2		=6'b100011;
	parameter DATA_FIFO5_WRITE3		=6'b100100;
	parameter DATA_FIFO6_WRITE0		=6'b100101;
	parameter DATA_FIFO6_WRITE1		=6'b100110;
	parameter DATA_FIFO6_WRITE2		=6'b100111;
	parameter DATA_FIFO6_WRITE3		=6'b101000;
	parameter DATA_FIFO7_WRITE0		=6'b101001;	
	parameter DATA_FIFO7_WRITE1		=6'b101010;
	parameter DATA_FIFO7_WRITE2		=6'b101011;	
	parameter DATA_FIFO7_WRITE3		=6'b101100;
	parameter READ_FROM_CACHE0		=6'b101101;	
	parameter READ_FROM_CACHE1		=6'b101110;
	parameter READ_FROM_CACHE2		=6'b101111;
	parameter READ_FROM_CACHE3		=6'b110000;
	parameter PCIE_COMMAND_SEND		=6'b110001;
	parameter GET_ENTRY0			=6'b110010;
	parameter GET_ENTRY1			=6'b110011;
	parameter RECEIVE_ENTRY0		=6'b110100;
	parameter RECEIVE_ENTRY1		=6'b110101;	          
	parameter RECEIVE_ENTRY2		=6'b110110;	
	parameter READY_FOR_CHECK_HIT	=6'b110111;
	parameter CHECK_HIT			    =6'b111000;
	parameter WAIT_FOR_TWO_CYCLE    =6'b111001;
	parameter WRITE_ENTRY_BACK0		=6'b111010;
	parameter WRITE_ENTRY_BACK1		=6'b111011;
	parameter UNLOCK_DRAM			=6'b111100;		
	parameter FINISH			    =6'b111101;	
	parameter CHECK_INIT_DRAM_DONE  =6'b111110;
	
	reg [COMMAND_WIDTH-1:0]controller_command;
	reg [DRAM_ADDR_WIDTH-1:0] dram_addr;
	reg [5:0] state;
	reg [5:0] state_buf;	//0~8 command fifoת
	reg [5:0] state_buf1;	//read:8read_data_fifo_out  write:ֱ޸ӳlockλ
	reg [9:0]count;
	reg [9:0]count_read;
	reg [511:0]data_from_dram_buf;
	reg [63:0]dram_data_mask_buf;
	reg [7:0]hit_flag;
	reg [DRAM_IO_WIDTH-1:0] entries;
	reg register_ready;
	reg initial_dram_done;
	reg read_or_initial;

	parameter COMMANDS_ISSUE0    	=2'b00; 
	parameter COMMANDS_ISSUE1	=2'b01;
	parameter COMMANDS_ISSUE2   	=2'b10;
	parameter COMMANDS_ISSUE3   	=2'b11;

	reg	data_to_dram_en;
	reg	data_to_dram_end;
	reg	ci_en;
	reg	[DRAM_ADDR_WIDTH-1:0] ci_addr;
	reg	[31:0] ci_num;
	reg	[9:0]  ci_cmd_cnt;
	reg     [9:0]  ci_data_cnt;
	reg  	ci_done;
	reg 	[1:0] ci_state;
	reg 	flag; 
	reg 	dram_en_ci;
	reg 	[DRAM_ADDR_WIDTH-1:0] addr_to_dram_ci;	

	assign dram_en_o=dram_en_ci|dram_en;
	assign addr_to_dram_o=(dram_en_ci)? addr_to_dram_ci:addr_to_dram;	 
	
	always@ (posedge clk or negedge reset)
	begin
		if(!reset)
		begin
			finish_command_fifo0_out_en<= 0;
			finish_command_fifo1_out_en<= 0;
			finish_command_fifo2_out_en<= 0;	
			finish_command_fifo3_out_en<= 0;
			finish_command_fifo4_out_en<= 0;	
			finish_command_fifo5_out_en<= 0;
			finish_command_fifo6_out_en<= 0;
			finish_command_fifo7_out_en<= 0;
			finish_command_fifo8_out_en<= 0;
			read_data_fifo0_out_en     <= 0;
			read_data_fifo1_out_en     <= 0;
			read_data_fifo2_out_en     <= 0;
			read_data_fifo3_out_en     <= 0;
			read_data_fifo4_out_en     <= 0;
			read_data_fifo5_out_en     <= 0;
			read_data_fifo6_out_en     <= 0;
			read_data_fifo7_out_en     <= 0;
			dram_request               <= 0;
			release_dram               <= 0;
			addr_to_dram               <= 0;
			data_to_dram               <= 0;
			dram_data_mask             <= 0;
			dram_en                    <= 0;
			dram_read_or_write         <= 0;
			pcie_data_send_fifo_in     <= 0;
			pcie_data_send_fifo_in_en  <= 0;
			pcie_command_send_fifo_in  <= 0;
			pcie_command_send_fifo_in_en<= 0;
			
			dram_addr              <= 0;
			state 	               <= CHECK_COMMAND_FIFO0;//CHECK_INIT_DRAM_DONE
			state_buf              <= 0;
			state_buf1             <= 0;
			count                  <= 0;
			count_read             <= 0;
			data_from_dram_buf     <= 0;
			dram_data_mask_buf     <= 0;
			hit_flag               <= 0;
			entries                <= 0;
			left_capacity_final    <= 0; //512GB flash有2的19次方个块
			free_block_fifo_tails  <= 0;
			free_block_fifo_heads  <= 0;
			register_ready         <= 0;
			read_or_initial        <= 0;
			initial_dram_done      <= 0; //debug: ignore initial dram
			ci_en 		       <= 0;
			ci_addr 	       <= 0;
			ci_num		       <= 0;
			ci_data_cnt	       <= 0;
			data_to_dram_en	       <= 0;
			data_to_dram_end       <= 0;
			flag		       <= 0;
		end
		else
		begin
			case (state) 
				/*CHECK_INIT_DRAM_DONE:
				begin
					if(init_dram_done &&  all_controller_command_fifo_empty == 1'b1)
					begin
						//register_ready <= 1'b1;
						initial_dram_done <=1'b1;
						left_capacity_final <= 19'b111_11111000_00000000;
						free_block_fifo_heads <= 0;
						free_block_fifo_tails <= 128'b0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001;
						state <= CHECK_COMMAND_FIFO0;
					end
					else
						state <= CHECK_INIT_DRAM_DONE;
				end*/
				CHECK_COMMAND_FIFO0://00
				begin
					if(register_ready == 1'b1 &&  all_controller_command_fifo_empty == 1'b1)
					begin
						initial_dram_done <=1'b1;
					end
					if(finish_command_fifo0_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo0_out_en <= 1;							
						controller_command<=finish_command_fifo0_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO1;		//ָһfifoת
						state_buf1<=DATA_FIFO0_WRITE0;		
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO1;
					end
				end
				CHECK_COMMAND_FIFO1://01
				begin
					if(finish_command_fifo1_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo1_out_en <= 1;
						controller_command<=finish_command_fifo1_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO2;		//ָһfifoת
						state_buf1<=DATA_FIFO1_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO2;
					end
				end
				CHECK_COMMAND_FIFO2://02
				begin
					if(finish_command_fifo2_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo2_out_en <= 1;
						controller_command<=finish_command_fifo2_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO3;		//ָһfifoת
						state_buf1<=DATA_FIFO2_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO3;
					end
				end
				CHECK_COMMAND_FIFO3://03
				begin
					if(finish_command_fifo3_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo3_out_en <= 1;
						controller_command<=finish_command_fifo3_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO4;		//ָһfifoת
						state_buf1<=DATA_FIFO3_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO4;
					end
				end
				CHECK_COMMAND_FIFO4://04
				begin
					if(finish_command_fifo4_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo4_out_en <= 1;
						controller_command<=finish_command_fifo4_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO5;		//ָһfifoת
						state_buf1<=DATA_FIFO4_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO5;
					end
				end
				CHECK_COMMAND_FIFO5://05
				begin
					if(finish_command_fifo5_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo5_out_en <= 1;
						controller_command<=finish_command_fifo5_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO6;		//ָһfifoת
						state_buf1<=DATA_FIFO5_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO6;
					end
				end
				CHECK_COMMAND_FIFO6://06
				begin
					if(finish_command_fifo6_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo6_out_en <= 1;
						controller_command<=finish_command_fifo6_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO7;		//ָһfifoת
						state_buf1<=DATA_FIFO6_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO7;
					end
				end
				CHECK_COMMAND_FIFO7://07
				begin
					if(finish_command_fifo7_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo7_out_en <= 1;
						controller_command<=finish_command_fifo7_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO8;		//ָһfifoת
						state_buf1<=DATA_FIFO7_WRITE0;
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO8;
					end
				end				
				CHECK_COMMAND_FIFO8://08
				begin
					if(finish_command_fifo8_empty_or_not==0)//finish_command_fifo0
					begin
						finish_command_fifo8_out_en <= 1;
						controller_command<=finish_command_fifo8_out;
						state <= COMMAND_INTERPRET;	
						state_buf <= CHECK_COMMAND_FIFO0;		//ָһfifoת
						state_buf1<=READ_FROM_CACHE0;	//cache
					end
					else
					begin
						state <= CHECK_COMMAND_FIFO0;
					end
				end
				COMMAND_INTERPRET://09
				begin	
					finish_command_fifo0_out_en <= 0;//λ
					finish_command_fifo1_out_en <= 0;//λ
					finish_command_fifo2_out_en <= 0;//λ
					finish_command_fifo3_out_en <= 0;//λ
					finish_command_fifo4_out_en <= 0;//λ
					finish_command_fifo5_out_en <= 0;//λ
					finish_command_fifo6_out_en <= 0;//λ
					finish_command_fifo7_out_en <= 0;//λ
					finish_command_fifo8_out_en <= 0;//λ
					case(controller_command[127:126]) //125位标识flush与否
						READ:
						begin
							case(controller_command[124:123])
							2'b00:
							begin
								read_or_initial <= 1;
//								dram_addr<=CACHE_BASE+{controller_command[49:32], 11'b0}; 
								dram_addr<=CACHE_BASE+{controller_command[50:32], 9'b0}; //cache_address 19+9=28 
								if(pcie_data_send_fifo_out_prog_full==1'b0)
									state<=WAIT_DRAM;//8 read_data_fifo_out
								else
									state<=COMMAND_INTERPRET;//wait until pcie_command_send_fifo not full									
							end
							2'b10:
							begin
								state <= INITIAL_DRAM_READ_COMMAND;
								read_or_initial <= 0;
							end
							2'b01:
							begin
								count<=0;
								state <= REGISTER_READ_COMMAND;
							end
							default:state <= CHECK_COMMAND_FIFO0;
							endcase
						end
						WRITE:
						begin
							state <= WAIT_DRAM;   
							count<=0;
							state_buf1<=GET_ENTRY0;//дcache滻ֱ޸ӳ
						end
						default: state <= CHECK_COMMAND_FIFO0;
					endcase
				end		
				INITIAL_DRAM_READ_COMMAND: //001010
				begin
				//	dram_addr<={controller_command[49:32],11'b0};
					dram_addr<={controller_command[51:32],9'b0};
					state<=WAIT_DRAM;//8read_data_fifo_out
				end
				WAIT_DRAM:		//001100
				begin
					if(dram_permit)
					begin
						dram_request <= 0;
						state <= state_buf1;
					end
					else
					begin
						dram_request<=1;//dram
						state<=WAIT_DRAM;
					end
				end		
				REGISTER_READ_COMMAND: //001011
				begin
					if(count==0)
					begin
						register_ready <=1;
						read_data_fifo0_out_en<=1;
						//left_capacity_final<=read_data_fifo0_out[255:239];	
						//free_block_fifo_heads <=read_data_fifo0_out[238:127];
						//free_block_fifo_tails <=read_data_fifo0_out[126:15];
						left_capacity_final <= 19'b111_11111000_00000000;
						free_block_fifo_heads <= 0;
						free_block_fifo_tails <= 128'b0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001_0000000000000001;		
						count <=count+1;
						
					end
					else if(count<DRAM_COUNT*2)
					begin
						read_data_fifo0_out_en<=1;
						count <=count+1;
					end
					else 
					begin
						count <=0;
						read_data_fifo0_out_en<=0;
						state <=FINISH;
					end					
				end
		///////////////00000000000000000000000///////////////	
				DATA_FIFO0_WRITE0://001101
				begin
					read_data_fifo0_out_en<=1;	
					state<=DATA_FIFO0_WRITE1;					
				end
				DATA_FIFO0_WRITE1://001110
				begin
					read_data_fifo0_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo0_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;						

						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo0_out;
						read_data_fifo0_out_en<=1;						
						state <= DATA_FIFO0_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO0_WRITE1;
					end
				end
				DATA_FIFO0_WRITE2://001111
				begin
				   	ci_en <=0;
				    	read_data_fifo0_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo0_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo0_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo0_out_en<=1;
						state <= DATA_FIFO0_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo0_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo0_out_en<=1;
						flag <=0;
						state <= DATA_FIFO0_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO0_WRITE2;
			
				end
				DATA_FIFO0_WRITE3://010000
				begin
					read_data_fifo0_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo0_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo0_out;

							read_data_fifo0_out_en	<= 1;
							state <= DATA_FIFO0_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo0_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo0_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO0_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO0_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo0_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo0_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo0_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO0_WRITE3;
					end		
				end
		////////////////////11111111111111111111111111///////////
				DATA_FIFO1_WRITE0://010010
				begin
					read_data_fifo1_out_en<=1;	
					state<=DATA_FIFO1_WRITE1;					
				end
				DATA_FIFO1_WRITE1://010011
				begin
					read_data_fifo1_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo1_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo1_out;
						read_data_fifo1_out_en<=1;						
						state <= DATA_FIFO1_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO1_WRITE1;
					end
				end
				DATA_FIFO1_WRITE2://010011
				begin
				   	ci_en <=0;
				    	read_data_fifo1_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo1_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo1_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo1_out_en<=1;
						state <= DATA_FIFO1_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo1_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)						
							read_data_fifo1_out_en<=1;
						flag <=0;
						state <= DATA_FIFO1_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO1_WRITE2;
			
				end
				DATA_FIFO1_WRITE3://010100
				begin
					read_data_fifo1_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo1_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo1_out;

							read_data_fifo1_out_en	<= 1;
							state <= DATA_FIFO1_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo1_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo1_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO1_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO1_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo1_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo1_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo1_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO1_WRITE3;
					end		
				end
		///////////////////22222222222222222222222222222222222222/////////////
				DATA_FIFO2_WRITE0://0c read_data_fifo2
				begin
					read_data_fifo2_out_en<=1;	
					state<=DATA_FIFO2_WRITE1;					
				end
				DATA_FIFO2_WRITE1://0d
				begin
					read_data_fifo2_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo2_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo2_out;
						read_data_fifo2_out_en<=1;						
						state <= DATA_FIFO2_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO2_WRITE1;
					end
				end
				DATA_FIFO2_WRITE2://0e
				begin
				   	ci_en <=0;
				    	read_data_fifo2_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo2_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo2_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo2_out_en<=1;
						state <= DATA_FIFO2_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo2_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)						
							read_data_fifo2_out_en<=1;
						flag <=0;
						state <= DATA_FIFO2_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO2_WRITE2;
			
				end
				DATA_FIFO2_WRITE3://0f
				begin
					read_data_fifo2_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo2_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo2_out;

							read_data_fifo2_out_en	<= 1;
							state <= DATA_FIFO2_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo2_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo2_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO2_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO2_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo2_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo2_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo2_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO2_WRITE3;
					end		
				end
				///////////33333333333333333333333333333/////////
				DATA_FIFO3_WRITE0://0c read_data_fifo3
				begin
					read_data_fifo3_out_en<=1;	
					state<=DATA_FIFO3_WRITE1;					
				end
				DATA_FIFO3_WRITE1://0d
				begin
					read_data_fifo3_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo3_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo3_out;
						read_data_fifo3_out_en<=1;						
						state <= DATA_FIFO3_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO3_WRITE1;
					end
				end
				DATA_FIFO3_WRITE2://0e
				begin
				   	ci_en <=0;
				    read_data_fifo3_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo3_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo3_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo3_out_en<=1;
						state <= DATA_FIFO3_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo3_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo3_out_en<=1;
						flag <=0;
						state <= DATA_FIFO3_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO3_WRITE2;
			
				end
				DATA_FIFO3_WRITE3://0f
				begin
					read_data_fifo3_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo3_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo3_out;

							read_data_fifo3_out_en	<= 1;
							state <= DATA_FIFO3_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo3_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo3_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO3_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO3_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo3_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo3_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo3_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO3_WRITE3;
					end		
				end
				////////////////444444444444444444//////////////////
				DATA_FIFO4_WRITE0://0c read_data_fifo4
				begin
					read_data_fifo4_out_en<=1;	
					state<=DATA_FIFO4_WRITE1;					
				end
				DATA_FIFO4_WRITE1://0d
				begin
					read_data_fifo4_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo4_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo4_out;
						read_data_fifo4_out_en<=1;						
						state <= DATA_FIFO4_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO4_WRITE1;
					end
				end
				DATA_FIFO4_WRITE2://0e
				begin
				   	ci_en <=0;
				    	read_data_fifo4_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo4_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo4_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)							
							read_data_fifo4_out_en<=1;
						state <= DATA_FIFO4_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo4_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)						
							read_data_fifo4_out_en<=1;
						flag <=0;
						state <= DATA_FIFO4_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO4_WRITE2;
			
				end
				DATA_FIFO4_WRITE3://0f
				begin
					read_data_fifo4_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo4_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo4_out;

							read_data_fifo4_out_en	<= 1;
							state <= DATA_FIFO4_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo4_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo4_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO4_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO4_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo4_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo4_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo4_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO4_WRITE3;
					end		
				end
				//////55555555555555555////////////
				DATA_FIFO5_WRITE0://0c read_data_fifo5
				begin
					read_data_fifo5_out_en<=1;	
					state<=DATA_FIFO5_WRITE1;					
				end
				DATA_FIFO5_WRITE1://0d
				begin
					read_data_fifo5_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo5_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo5_out;
						read_data_fifo5_out_en<=1;						
						state <= DATA_FIFO5_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO5_WRITE1;
					end
				end
				DATA_FIFO5_WRITE2://0e
				begin
				   	ci_en <=0;
				    	read_data_fifo5_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo5_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo5_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo5_out_en<=1;
						state <= DATA_FIFO5_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo5_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo5_out_en<=1;
						flag <=0;
						state <= DATA_FIFO5_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO5_WRITE2;
			
				end
				DATA_FIFO5_WRITE3://0f
				begin
					read_data_fifo5_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo5_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo5_out;

							read_data_fifo5_out_en	<= 1;
							state <= DATA_FIFO5_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo5_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo5_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO5_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO5_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo5_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo5_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo5_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO5_WRITE3;
					end		
				end
				/////////6666666666666666/////////////////
				DATA_FIFO6_WRITE0://0c read_data_fifo6
				begin
					read_data_fifo6_out_en<=1;	
					state<=DATA_FIFO6_WRITE1;					
				end
				DATA_FIFO6_WRITE1://0d
				begin
					read_data_fifo6_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo6_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo6_out;
						read_data_fifo6_out_en<=1;						
						state <= DATA_FIFO6_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO6_WRITE1;
					end
				end
				DATA_FIFO6_WRITE2://0e
				begin
				   	ci_en <=0;
				    	read_data_fifo6_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo6_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo6_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)						
							read_data_fifo6_out_en<=1;
						state <= DATA_FIFO6_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo6_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)						
							read_data_fifo6_out_en<=1;
						flag <=0;
						state <= DATA_FIFO6_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO6_WRITE2;
			
				end
				DATA_FIFO6_WRITE3://0f
				begin
					read_data_fifo6_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo6_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo6_out;

							read_data_fifo6_out_en	<= 1;
							state <= DATA_FIFO6_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo6_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo6_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO6_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO6_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo6_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo6_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo6_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO6_WRITE3;
					end		
				end
				////////////7777777777777777777/////////////
				DATA_FIFO7_WRITE0://0c read_data_fifo7
				begin
					read_data_fifo7_out_en<=1;	
					state<=DATA_FIFO7_WRITE1;					
				end
				DATA_FIFO7_WRITE1://0d
				begin
					read_data_fifo7_out_en<=0;
					if(ci_done)
					begin
						
						ci_en <=1;
						dram_read_or_write <= 0;//write
						ci_addr <=dram_addr;
						ci_num<=DRAM_COUNT; //256*512b=16KB	

						data_to_dram_en <= 1'b1;
						data_to_dram <= read_data_fifo7_out;						
						dram_data_mask<=32'h0;//no mask						
						ci_data_cnt <= 0;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo7_out;
						read_data_fifo7_out_en<=1;						
						state <= DATA_FIFO7_WRITE2;		
					end
					else
					begin
						state<=DATA_FIFO7_WRITE1;
					end
				end
				DATA_FIFO7_WRITE2://0e
				begin
				   	ci_en <=0;
				    	read_data_fifo7_out_en<=0;//
					pcie_data_send_fifo_in_en<=0;
					if (data_to_dram_ready & !flag) 
					begin
	       			  		dram_data_mask<=32'h0;
				  		data_to_dram <= read_data_fifo7_out;
				  		data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=read_data_fifo7_out;

				    		ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo7_out_en<=1;
						state <= DATA_FIFO7_WRITE3;
					end
					else if (!flag)  //if !data_to_dram_ready, pcie_data_rec_fifo_i needs to be stored.
					begin
						data_tmp <= read_data_fifo7_out;	
						flag <=1;			
					end				
					else if(data_to_dram_ready)
					begin
						dram_data_mask<=32'h0;
						data_to_dram <= data_tmp;
						data_to_dram_end <= 1'b1;
						pcie_data_send_fifo_in_en<=read_or_initial;
						pcie_data_send_fifo_in<=data_tmp;

						ci_data_cnt <= ci_data_cnt+1;
						if(ci_data_cnt<ci_num-1)
							read_data_fifo7_out_en<=1;
						flag <=0;
						state <= DATA_FIFO7_WRITE3;				    				
					end
					else 
						state <= DATA_FIFO7_WRITE2;
			
				end
				DATA_FIFO7_WRITE3://0f
				begin
					read_data_fifo7_out_en<=0;
					pcie_data_send_fifo_in_en<=0;
					if(ci_data_cnt<ci_num)
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <=read_data_fifo7_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=read_data_fifo7_out;

							read_data_fifo7_out_en	<= 1;
							state <= DATA_FIFO7_WRITE2;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo7_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b1;
							pcie_data_send_fifo_in_en<=read_or_initial;
							pcie_data_send_fifo_in<=data_tmp;

							read_data_fifo7_out_en <= 1;
							flag <=0;
							state <= DATA_FIFO7_WRITE2;				    				
						end
						else 
							state <= DATA_FIFO7_WRITE3;
					end
					else 
					begin
						if (data_to_dram_ready & !flag) 
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= read_data_fifo7_out;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=read_data_fifo7_out;
							state <= PCIE_COMMAND_SEND;
						end
						else if (!flag)
						begin
							data_tmp <= read_data_fifo7_out;	
							flag <=1;			
						end				
						else if(data_to_dram_ready)
						begin
							dram_data_mask<=32'h0;
							data_to_dram <= data_tmp;
							data_to_dram_end <= 1'b0;
							data_to_dram_en <= 1'b0;
							//pcie_data_send_fifo_in_en<=read_or_initial;
							//pcie_data_send_fifo_in<=data_tmp;
							flag <=0;
							state <= PCIE_COMMAND_SEND;			    				
						end
						else 
							state <= DATA_FIFO7_WRITE3;
					end		
				end
				READ_FROM_CACHE0://101101
				begin
					pcie_data_send_fifo_in_en<=0;//Ĭϲpcie_data_send_fifo	
					if(rd_data_valid)
					begin
						pcie_data_send_fifo_in_en<=1;
						pcie_data_send_fifo_in<=data_from_dram;
						count_read<=count_read+1;//նٸ
					end
					dram_en <= 1;
					dram_read_or_write <= 1;//read	
					addr_to_dram <=dram_addr; 	
					state<=READ_FROM_CACHE1;
				end
				READ_FROM_CACHE1://101110
				begin
					pcie_data_send_fifo_in_en<=0;//Ĭϲpcie_data_send_fifo	
					if(rd_data_valid)
					begin
						pcie_data_send_fifo_in_en<=1;
						pcie_data_send_fifo_in<=data_from_dram;
						count_read<=count_read+1;//նٸ
					end
					if(dram_ready)
					begin											
						dram_en <=0;
						count <= count + 1; 
						dram_addr<=dram_addr+8;						
						state <= READ_FROM_CACHE2;
					end
				end
				READ_FROM_CACHE2://101111 
				begin				
					pcie_data_send_fifo_in_en<=0;//Ĭϲpcie_data_send_fifo
					if(rd_data_valid)
					begin
						pcie_data_send_fifo_in_en<=1;
						pcie_data_send_fifo_in<=data_from_dram;
						count_read<=count_read+1;//նٸ
					end
					if(count>=DRAM_COUNT)//256ζ256*512b=16KBΪһҳС
					begin
						state <= READ_FROM_CACHE3;
						count<=0;
					end
					else
					begin
						state <= READ_FROM_CACHE1;
						dram_en <= 1;
						dram_read_or_write <= 1;//read	
						addr_to_dram <=dram_addr; 
					end
				end
				READ_FROM_CACHE3: //110000
				begin
					pcie_data_send_fifo_in_en<=0;//Ĭϲpcie_data_send_fifo
					if(rd_data_valid)
					begin
						pcie_data_send_fifo_in_en<=1;
						pcie_data_send_fifo_in<=data_from_dram;
						count_read<=count_read+1;//նٸ
					end
					if(count_read>=DRAM_COUNT*2)//512256b
					begin										
						state <= PCIE_COMMAND_SEND;//޸ӳ
						count_read<=0;
					end
					else
					begin
						state<=READ_FROM_CACHE3;
					end
				end
				PCIE_COMMAND_SEND://110001
				begin			
					pcie_data_send_fifo_in_en<=0;
					if(read_or_initial==1'b1)
					begin
						if(pcie_command_send_fifo_full_or_not==1'b0)
						begin
							pcie_command_send_fifo_in_en<=read_or_initial;//pcie_command_send_fifo
							pcie_command_send_fifo_in<=controller_command;
							state<=GET_ENTRY0;//8read_data_fifo_out
						end
					end	
					else
						if(ci_done == 1'b1)
						begin
							release_dram <= 1;				
							state<=FINISH;
						end								
				end				
				GET_ENTRY0://110010
				begin	
					pcie_command_send_fifo_in_en<=1'b0;									
					if(ci_done == 1'b1)
					begin
						dram_en <= 1;
						dram_read_or_write <= 1;//read
					//	addr_to_dram <= {controller_command[13:1], 3'b000} + CACHE_ENTRY_BASE;
						addr_to_dram <= {controller_command[15:1], 3'b000} + CACHE_ENTRY_BASE; 
						state<=GET_ENTRY1;
					end

				end
				GET_ENTRY1://110011
				begin
					if(dram_ready)
					begin
						dram_en <= 0;
						state <= RECEIVE_ENTRY0;		
					end
					else
					begin
						state<=GET_ENTRY1;
					end
				end
				RECEIVE_ENTRY0: //110100
				begin
					if(rd_data_valid)
					begin
						state <= RECEIVE_ENTRY1;
						data_from_dram_buf[255:0]<=data_from_dram;						
					end
					else
						state<=RECEIVE_ENTRY0;
				end
				RECEIVE_ENTRY1: //110101
				begin
					if(rd_data_valid)
					begin	
						state <= RECEIVE_ENTRY2;
						data_from_dram_buf[511:256]<=data_from_dram;	
					end
					else
						state<=RECEIVE_ENTRY1;
				end
				RECEIVE_ENTRY2://110110
				begin
					if(controller_command[0]==0)
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
				READY_FOR_CHECK_HIT://110111
				begin
					hit_flag[0] <= |(entries[28:0]    ^ {1'b1, controller_command[27:0]});
					hit_flag[1] <= |(entries[60:32]   ^ {1'b1, controller_command[27:0]});
					hit_flag[2] <= |(entries[92:64]   ^ {1'b1, controller_command[27:0]});
					hit_flag[3] <= |(entries[124:96]  ^ {1'b1, controller_command[27:0]});
					hit_flag[4] <= |(entries[156:128] ^ {1'b1, controller_command[27:0]});
					hit_flag[5] <= |(entries[188:160] ^ {1'b1, controller_command[27:0]});
					hit_flag[6] <= |(entries[220:192] ^ {1'b1, controller_command[27:0]});
					hit_flag[7] <= |(entries[252:224] ^ {1'b1, controller_command[27:0]});
					state <= CHECK_HIT;
				end
				CHECK_HIT://111000
				begin
					casex(hit_flag)// synthesis parallel_case
						8'bxxxxxxx0:
						begin
							entries[29] <= 0; //unlock
						end
						8'bxxxxxx0x:
						begin
							entries[61] <= 0; //unlock
						end
						8'bxxxxx0xx:
						begin
							entries[93] <= 0; //unlock
						end
						8'bxxxx0xxx:
						begin
							entries[125] <= 0; //unlock
						end
						8'bxxx0xxxx:
						begin
							entries[157] <= 0; //unlock
						end
						8'bxx0xxxxx:
						begin
							entries[189] <= 0; //unlock
						end
						8'bx0xxxxxx:
						begin
							entries[221] <= 0; //unlock
						end
						8'b0xxxxxxx:
						begin
							entries[253] <= 0; //unlock
						end			
					endcase
					state<=WAIT_FOR_TWO_CYCLE;
				end
				WAIT_FOR_TWO_CYCLE://111001
				begin
					if(count>=8)
					begin
						count<=0;
						state<=WRITE_ENTRY_BACK0;
						data_to_dram_en <= 1'b1;
						dram_data_mask<=dram_data_mask_buf[31:0];//mask
						data_to_dram <= entries;
					end
					else
						count<=count+1;
				end
				WRITE_ENTRY_BACK0://111010
				begin
					if(data_to_dram_ready) 
					begin
						dram_en <= 1;
						dram_read_or_write <= 0;//write
						addr_to_dram <= {controller_command[15:1], 3'b000} + CACHE_ENTRY_BASE;
						data_to_dram_end<= 1'b1;
						data_to_dram <= entries;
						dram_data_mask<=dram_data_mask_buf[63:32];						
						state	<= WRITE_ENTRY_BACK1;
					end
				end
				WRITE_ENTRY_BACK1:  //111011
				begin 
					if(dram_ready & data_to_dram_ready ) 
					begin
						dram_en <= 0;			
						data_to_dram_en <= 1'b0;
						data_to_dram_end<= 1'b0;
						state <= UNLOCK_DRAM;
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
						state <= WRITE_ENTRY_BACK1;
				end
				UNLOCK_DRAM://111100
				begin
					release_dram <= 1;
					state <= FINISH;
				end
				FINISH:	//111101
				begin					
					release_dram <= 0;
					state <= state_buf;
				end
				default: 
					state <= CHECK_COMMAND_FIFO0;
			endcase
		end
	end
	
always@(posedge clk or negedge reset) // issue ci_num dram write commands
	begin
		if(!reset) 
		begin
			ci_done  	<= 1;  //done==1, not busy
			ci_state 	<= COMMANDS_ISSUE0;
			ci_cmd_cnt 	<= 0;
			dram_en_ci 	<= 0;
			addr_to_dram_ci <= 0;
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
						addr_to_dram_ci <= ci_addr+{ci_cmd_cnt[9:0],3'b000};
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
