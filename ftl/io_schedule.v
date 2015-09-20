module io_schedule(
	reset,
	clk,
	ssd_command_fifo_empty_or_not,
	ssd_command_fifo_out,
	dram_permit,
	data_from_dram,
	dram_ready,	
	rd_data_valid,
	gc_command_fifo_out,
	gc_command_fifo_empty_or_not,
	////write_data_fifo0_prog_full,
	//command_fifo0_full,
	////write_data_fifo1_prog_full,
	//command_fifo1_full,
	////write_data_fifo2_prog_full,
	//command_fifo2_full,
	////write_data_fifo3_prog_full,
	//command_fifo3_full,
	////write_data_fifo4_prog_full,
	//command_fifo4_full,
	////write_data_fifo5_prog_full,
	//command_fifo5_full,
	////write_data_fifo6_prog_full,
	//command_fifo6_full,
	////write_data_fifo7_prog_full,
	//command_fifo7_full,
	command_available,
	
	ssd_command_fifo_out_en,
	controller_command_fifo_in,
	controller_command_fifo_in_en,
	write_data_fifo_in,
	write_data_fifo_in_en,
	dram_request,
	release_dram,
	addr_to_dram,
	data_to_dram,
	dram_data_mask,
	dram_en,
	dram_read_or_write,
	data_to_dram_en,
	data_to_dram_end,
	data_to_dram_ready,
	gc_command_fifo_out_en,
	flash_left_capacity,
	free_block_fifo_heads,
	free_block_fifo_tails,
	register_ready,
	state
	);	
	
	`include"ftl_define.v"
	input reset;
	input clk;
	input ssd_command_fifo_empty_or_not;
	input [COMMAND_WIDTH-1:0] ssd_command_fifo_out;
	input dram_permit;
	input [DRAM_IO_WIDTH-1:0] data_from_dram;	
	input dram_ready;	
	input rd_data_valid;
	input [GC_COMMAND_WIDTH-1:0] gc_command_fifo_out;
	input gc_command_fifo_empty_or_not;
	////input write_data_fifo0_prog_full;
	//input command_fifo0_full;
	////input write_data_fifo1_prog_full;
	//input command_fifo1_full;
	////input write_data_fifo2_prog_full;
	//input command_fifo2_full;
	////input write_data_fifo3_prog_full;
	//input command_fifo3_full;
	////input write_data_fifo4_prog_full;
	//input command_fifo4_full;
	////input write_data_fifo5_prog_full;
	//input command_fifo5_full;
	////input write_data_fifo6_prog_full;
	//input command_fifo6_full;
	////input write_data_fifo7_prog_full;
	//input command_fifo7_full;	
	input [7:0] command_available;
	input register_ready;
	
	output ssd_command_fifo_out_en;	
	output [COMMAND_WIDTH-1:0] controller_command_fifo_in;
	output [7:0] controller_command_fifo_in_en;	
	output [DRAM_IO_WIDTH-1:0] write_data_fifo_in;
	output [7:0] write_data_fifo_in_en;	
	output dram_request;
	output release_dram;
	output [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	output [DRAM_IO_WIDTH-1:0]data_to_dram;
	output [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	output dram_en;	
	output dram_read_or_write;	
	output data_to_dram_en;
	output data_to_dram_end;
	input  data_to_dram_ready;
	output gc_command_fifo_out_en;
	inout [18:0]flash_left_capacity;//512GB flash217η
	inout [127:0] free_block_fifo_tails;
	inout [127:0] free_block_fifo_heads;
	output [4:0] state;
	//output [5:0] state_addr;
	
	reg ssd_command_fifo_out_en;
	reg request_for_addr_management_en;
	reg [1:0] request_for_addr_management_op;
	reg [27:0] laddr_to_addr_management;
	reg [COMMAND_WIDTH-1:0] controller_command_fifo_in;
	reg [7:0] controller_command_fifo_in_en;	
	reg [DRAM_IO_WIDTH-1:0] write_data_fifo_in;
	reg [7:0] write_data_fifo_in_en;	
	reg dram_request;
	reg release_dram;
	reg gc_command_fifo_out_en;
	wire [18:0]flash_left_capacity;//512GB flash217η
	wire [127:0] free_block_fifo_tails;
	wire [127:0] free_block_fifo_heads;
	wire register_ready;
	
	//wire [5:0] state_addr;
	//add by qww
	wire [DRAM_ADDR_WIDTH-1:0] addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]data_to_dram;
	wire [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	wire dram_en;
	wire dram_read_or_write;
	
	
	wire [DRAM_ADDR_WIDTH-1:0] addr_to_dram_addr;
	wire [DRAM_IO_WIDTH-1:0]data_to_dram_addr;
	wire dram_en_addr;
	wire dram_read_or_write_addr;
	wire [DRAM_MASK_WIDTH-1:0]dram_data_mask_addr;
	wire data_to_dram_en_addr;
	wire data_to_dram_end_addr;
	
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram_io;
	reg [DRAM_IO_WIDTH-1:0]data_to_dram_io;
	reg dram_en_io;
	reg dram_read_or_write_io;	
	reg [DRAM_MASK_WIDTH-1:0]dram_data_mask_io;
	reg data_to_dram_en_io;
	reg data_to_dram_end_io;	
	
	//add by qww
	wire addr_manage_dram_busy;
	assign dram_en=(addr_manage_dram_busy)?dram_en_addr:dram_en_io;	
	assign dram_read_or_write=(addr_manage_dram_busy)?dram_read_or_write_addr:dram_read_or_write_io;
	assign addr_to_dram=(addr_manage_dram_busy)?addr_to_dram_addr:addr_to_dram_io;
	assign data_to_dram=(addr_manage_dram_busy)?data_to_dram_addr:data_to_dram_io;
	assign dram_data_mask=(addr_manage_dram_busy)?dram_data_mask_addr:dram_data_mask_io;
	assign data_to_dram_en=(addr_manage_dram_busy)?data_to_dram_en_addr:data_to_dram_en_io;
	assign data_to_dram_end=(addr_manage_dram_busy)?data_to_dram_end_addr:data_to_dram_end_io;
	//add by qww
	wire [PHYSICAL_ADDR_WIDTH-1:0] paddr0_from_addr_management;
	wire [PHYSICAL_ADDR_WIDTH-1:0] paddr1_from_addr_management;
	wire addr_management_ready;
	
	parameter IDLE                              =5'b00000;
	parameter WAIT_DRAM_FOR_IO                  =5'b00001;         
	parameter IO_COMMAND_INTERPRET              =5'b00010;          
	parameter GET_PHYSICAL_ADDRESS_FOR_READ     =5'b00011;          
	parameter WAIT_PADDR_FOR_READ               =5'b00100;          
	parameter GENERATE_READ_COMMAND             =5'b00101;          
	parameter GET_PHYSICAL_ADDRESS_FOR_WRITE    =5'b00110;          
	parameter WAIT_PADDR_FOR_WRITE              =5'b00111;          
	parameter GENERATE_WRITE_COMMAND            =5'b01000;
	parameter WAIT_DRAM_FOR_GC                  =5'b01001;
	parameter GC_COMMAND_INTERPRET              =5'b01010;
	parameter MOVE_COMMAND                      =5'b01011;
	parameter WAIT_PADDRS_FOR_MOVE              =5'b01100;
	parameter GENERATE_MOVE_COMMAND             =5'b01101;
	parameter ERASE_COMMAND                     =5'b01110;
	parameter WAIT_FOR_ERASE                    =5'b01111;
	parameter CHIP_SELECT                       =5'b10000;
	parameter CHECK_FULL_SIGNAL                 =5'b10001;
	parameter TRANSMIT_WRITE_DATA               =5'b10010;
	parameter GET_DATA_FROM_DRAM0               =5'b10011;
	parameter GET_DATA_FROM_DRAM1               =5'b10100;
	parameter GET_DATA_FROM_DRAM2               =5'b10101;
	parameter SEND_CONTROLLER_COMMAND           =5'b10110;
	parameter UNLOCK_DRAM_FOR_A_WHILE           =5'b10111;	
    parameter WAIT_DRAM_FOR_A_WHILE             =5'b11000;
    parameter CHANCG_TO_STATE_BUF               =5'b11001;
	parameter UNLOCK_DRAM                       =5'b11010;
	parameter FINISH                            =5'b11111;
	
	reg [COMMAND_WIDTH-1:0] ssd_command;
	reg [PHYSICAL_ADDR_WIDTH-1:0] paddr;//25b
	reg [4:0] state;
	reg [4:0] state_buf;
	reg [PHYSICAL_ADDR_WIDTH-1:0] target_paddr;
	
	reg [COMMAND_WIDTH-1:0] controller_command;
	
	//reg write_data_fifo_prog_full;
	reg command_fifo_available;
	reg [7:0] enable;	
	reg [31:0] count;
	reg [10:0] count_read;
	reg io_or_gc;
	reg [DRAM_ADDR_WIDTH-1:0] dram_addr;
	reg [GC_COMMAND_WIDTH-1:0] gc_command;	
	
	always@ (negedge reset or posedge clk)
	begin
		if(!reset)
		begin
			ssd_command_fifo_out_en       <=0;
			request_for_addr_management_en<=0;
			request_for_addr_management_op<=0;
			laddr_to_addr_management      <=0;
			controller_command_fifo_in    <=0;
			controller_command_fifo_in_en <=0;	
			write_data_fifo_in            <=0;
			write_data_fifo_in_en         <=0;	
			dram_request                  <=0;
			release_dram                  <=0;
			gc_command_fifo_out_en        <=0;		
			addr_to_dram_io               <=0;
			data_to_dram_io               <=0;
			dram_en_io                    <=0;
			dram_read_or_write_io         <=0;	
			dram_data_mask_io             <=0;		
			ssd_command                   <=0;
			paddr                         <=0;//25b
			state                         <=0;
			state_buf					  <=0;
			target_paddr                  <=0;			
			controller_command            <=0;			
			//write_data_fifo_prog_full     <=0;
			command_fifo_available             <=0;
			enable                        <=0;	
			count                         <=0;
			count_read                    <=0;
			io_or_gc                      <=0;
			dram_addr                     <=0;
			gc_command                    <=0;	
			data_to_dram_en_io            <=0;
			data_to_dram_end_io           <=0;			
		end
		else
		begin
			case (state)
				IDLE://00 
				begin
					if(ssd_command_fifo_empty_or_not==0 && (&(command_available)))
					begin
						ssd_command_fifo_out_en <= 1;
						ssd_command <= ssd_command_fifo_out;
						io_or_gc <= 1;
						dram_request <= 1;
						state <= WAIT_DRAM_FOR_IO;
					end
					else if(gc_command_fifo_empty_or_not==0)
					begin
						gc_command_fifo_out_en <= 1;
						gc_command <= gc_command_fifo_out;
						io_or_gc <= 0;
						dram_request <= 1;
						state <= WAIT_DRAM_FOR_GC;
					end
					else
						state <= IDLE;
				end
				/////////////////////////////////for IO
				WAIT_DRAM_FOR_IO://08
				begin
					ssd_command_fifo_out_en <= 0;  	
					if(dram_permit==1)			
					begin
						dram_request <= 0;		
						state <= IO_COMMAND_INTERPRET;
					end
					else state <= WAIT_DRAM_FOR_IO;
				end
				IO_COMMAND_INTERPRET://09
				begin
					case(ssd_command[127:126])
					1'b00:
						state <= GET_PHYSICAL_ADDRESS_FOR_READ;	
					1'b01:
						state <= GET_PHYSICAL_ADDRESS_FOR_WRITE;	
					default: state <= IDLE;
					endcase
				end
				////////////////////////////////read from flash memory
				GET_PHYSICAL_ADDRESS_FOR_READ://0a
				begin
					request_for_addr_management_en <= 1;
					request_for_addr_management_op <= READ;
					laddr_to_addr_management <= ssd_command[27:0];
					state <= WAIT_PADDR_FOR_READ;
				end
				WAIT_PADDR_FOR_READ://0b
				begin
					request_for_addr_management_en <= 0;
					if(addr_management_ready==1)
					begin
						paddr <= paddr0_from_addr_management;
						state <= GENERATE_READ_COMMAND;
					end
					else state <= WAIT_PADDR_FOR_READ;
				end
				GENERATE_READ_COMMAND://0c
				begin
					//2ͣ+370+25ַ+150+17cache_addr+32߼ַ=128
//					controller_command <= {READ, 37'b0, paddr,15'b0,ssd_command[48:32],ssd_command[31:0]};	
					//controller_command <= {READ, 37'b0, paddr,ssd_command[63:32],ssd_command[31:0]};
                    controller_command <= {ssd_command[127:89],1'b0,paddr[23:0],ssd_command[63:32],ssd_command[31:0]};					
					state <= CHIP_SELECT;
				end
				//////////////////////////////write
				GET_PHYSICAL_ADDRESS_FOR_WRITE://0d
				begin
					request_for_addr_management_en <= 1;
					request_for_addr_management_op <= WRITE;
					laddr_to_addr_management <= ssd_command[27:0];
					state <= WAIT_PADDR_FOR_WRITE;				
				end
				WAIT_PADDR_FOR_WRITE://0e
				begin
					request_for_addr_management_en <= 0;
					if(addr_management_ready==1)
					begin
						paddr <= paddr1_from_addr_management;
						state <= GENERATE_WRITE_COMMAND;
					end
					else state <= WAIT_PADDR_FOR_WRITE;
				end
				GENERATE_WRITE_COMMAND://0f
				begin
					//2ͣ+1Ƿadditional cacheϣ0ʾǣ+360+25ַ+150+17cache_addr+32߼ַ=128
					controller_command <= {WRITE,ssd_command[125], 36'b0,1'b0, paddr[23:0],ssd_command[63:32],ssd_command[31:0]};					
					state <= CHIP_SELECT;
				end
				WAIT_DRAM_FOR_GC://01
				begin
					gc_command_fifo_out_en <= 0;
					if(dram_permit==1)
					begin
						dram_request <= 0;
						state <= GC_COMMAND_INTERPRET;
					end
					else state <= WAIT_DRAM_FOR_GC ;
				end
				GC_COMMAND_INTERPRET://02
				begin
					if(gc_command[28]==0)
						state <= MOVE_COMMAND;
					else
						state <= ERASE_COMMAND;
				end
				MOVE_COMMAND://03
				begin
					request_for_addr_management_en <= 1;
					request_for_addr_management_op <= MOVE;
					laddr_to_addr_management <= gc_command[27:0];
					state <= WAIT_PADDRS_FOR_MOVE;
				end
				WAIT_PADDRS_FOR_MOVE://04
				begin
					request_for_addr_management_en <= 0;
					if(addr_management_ready==1)
					begin
						paddr <= paddr0_from_addr_management;
						target_paddr <= paddr1_from_addr_management;
						state <= GENERATE_MOVE_COMMAND;
					end
					else state <= WAIT_PADDRS_FOR_MOVE;
				end
				GENERATE_MOVE_COMMAND://05
				begin
					controller_command <= {MOVE, 62'b0,5'b0, target_paddr, 5'b0,paddr};//2+76+25+25=128
					state <= CHIP_SELECT;
				end
				////////erase
				ERASE_COMMAND://06
				begin
					request_for_addr_management_en <= 1;
					request_for_addr_management_op <= ERASE;
					laddr_to_addr_management <= gc_command[27:0];
					state <= WAIT_FOR_ERASE;
				end
				WAIT_FOR_ERASE://07
				begin
					request_for_addr_management_en <= 0;
					paddr <= gc_command[23:0];
					controller_command <= {ERASE,101'b0 , gc_command[24:0]};//2+101+25=128
					state <= CHIP_SELECT;
				end				
				CHIP_SELECT://10
				begin
					case (paddr[26:24])
						3'b000:
						begin
							//write_data_fifo_prog_full <= write_data_fifo0_prog_full;
							command_fifo_available <= command_available[0];
							enable <= 8'b00000001;
						end						
						3'b001:
						begin
							//write_data_fifo_prog_full <= write_data_fifo1_prog_full;
							command_fifo_available <= command_available[1];
							enable <= 8'b00000010;
						end
						3'b010:
						begin
							//write_data_fifo_prog_full <= write_data_fifo2_prog_full;
							command_fifo_available <= command_available[2];
							enable <= 8'b00000100;
						end
						3'b011:
						begin
							//write_data_fifo_prog_full <= write_data_fifo3_prog_full;
							command_fifo_available <= command_available[3];
							enable <= 8'b00001000;
						end
						3'b100:
						begin
							//write_data_fifo_prog_full <= write_data_fifo4_prog_full;
							command_fifo_available <= command_available[4];
							enable <= 8'b00010000;
						end
						3'b101:
						begin
							//write_data_fifo_prog_full <= write_data_fifo5_prog_full;
							command_fifo_available <= command_available[5];
							enable <= 8'b00100000;
						end
						3'b110:
						begin
							//write_data_fifo_prog_full <= write_data_fifo6_prog_full;
							command_fifo_available <= command_available[6];
							enable <= 8'b01000000;
						end
						3'b111:
						begin
							//write_data_fifo_prog_full <= write_data_fifo7_prog_full;
							command_fifo_available <= command_available[7];
							enable <= 8'b10000000;
						end
					endcase		
					state <= CHECK_FULL_SIGNAL;
				end
				CHECK_FULL_SIGNAL://11
				begin
					if(io_or_gc==1 && controller_command[127:126] !=WRITE && command_fifo_available)
						state <= SEND_CONTROLLER_COMMAND;
					else if(io_or_gc==1 && controller_command[127:126]==WRITE  && command_fifo_available)//WRITE 01 && !write_data_fifo_prog_full
					begin
						if(ssd_command[125])  
						//	dram_addr <= CACHE_BASE + {ssd_command[48:32],11'b000_00000000};
							dram_addr <= CACHE_BASE + {ssd_command[50:32],9'b0_00000000};	
						else                 //in additional cache
							dram_addr <= ADDITIONAL_CACHE_FIFO_BASE + {ssd_command[50:32],9'b0_00000000};							
						//state <= TRANSMIT_WRITE_DATA;
						state <= SEND_CONTROLLER_COMMAND;
					end					
					else
					begin				
						state <= UNLOCK_DRAM_FOR_A_WHILE;	
						state_buf <= CHIP_SELECT;
					end
				end
				TRANSMIT_WRITE_DATA://12
				begin
					controller_command_fifo_in_en <= 0;
					state <= GET_DATA_FROM_DRAM0;
					dram_en_io <= 1;
					dram_read_or_write_io <= 1; //read
					addr_to_dram_io <= dram_addr;	
					count<=0;
					count_read<=0;											
				end						
				GET_DATA_FROM_DRAM0://13
				begin
					write_data_fifo_in_en<=0;//
					if(rd_data_valid)
					begin
						write_data_fifo_in_en <= enable;
						write_data_fifo_in <= data_from_dram;
						count_read<=count_read+1;
					end
					if(dram_ready)
					begin
						dram_en_io <= 0;
						dram_addr <= dram_addr+8; 
						count <= count+1;
						state<=GET_DATA_FROM_DRAM1;
					end	
				end
				GET_DATA_FROM_DRAM1: //14 
				begin
					write_data_fifo_in_en<=0;
					if(rd_data_valid)
					begin
						write_data_fifo_in_en <= enable;
						write_data_fifo_in <= data_from_dram;
						count_read<=count_read+1;
					end
					if(count>=DRAM_COUNT)//256
					begin
						state <= GET_DATA_FROM_DRAM2;
					end
					else
					begin
						state <= GET_DATA_FROM_DRAM0;
						dram_en_io <= 1;
						dram_read_or_write_io <= 1; //read
						addr_to_dram_io <= dram_addr;	
					end
				end
				GET_DATA_FROM_DRAM2: //15 
				begin
					write_data_fifo_in_en<=0;
					if(rd_data_valid)
					begin
						write_data_fifo_in_en <= enable;
						write_data_fifo_in <= data_from_dram;
						count_read<=count_read+1;
					end
					else begin end
					if(count_read>=DRAM_COUNT*2)//512256b
					begin
						//state <= SEND_CONTROLLER_COMMAND;
						state <= UNLOCK_DRAM;
						count<=0;
						count_read<=0;
					end
				end					
				SEND_CONTROLLER_COMMAND://16
				begin
					controller_command_fifo_in <= controller_command;
					controller_command_fifo_in_en <= enable;
					if(controller_command[127:126]==WRITE)
						state <= TRANSMIT_WRITE_DATA;
					else 
						state <= UNLOCK_DRAM;					
				end				
				////////////////////////////////////////////////////above io
				////////////////////////////////////////////////////
				UNLOCK_DRAM_FOR_A_WHILE://17
				begin
					release_dram <= 1;
					count <= 0;
					controller_command_fifo_in_en <= 0;
					state <= WAIT_DRAM_FOR_A_WHILE;
				end
				WAIT_DRAM_FOR_A_WHILE://18
				begin
					release_dram <= 0;
					if(count>=63)
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
				CHANCG_TO_STATE_BUF://19
				begin
					if(dram_permit)
					begin
						dram_request <= 0;
						state <= state_buf;
					end
					else
						state<=CHANCG_TO_STATE_BUF;
				end				
				////////////////////////////////////////////////////
				UNLOCK_DRAM://17
				begin
					release_dram <= 1;
					controller_command_fifo_in_en <= 0;
					state <= FINISH;
				end
				FINISH://18
				begin
					release_dram <= 0;
					state <= IDLE;
				end		
				default: state <= IDLE;
			endcase	
		end
	end
	address_management addr_management_instance(
		.reset(reset),
		.clk(clk),
		.request_coming(request_for_addr_management_en),
		.request_op(request_for_addr_management_op),
		.addr_to_addr_management(laddr_to_addr_management),
		.data_from_dram(data_from_dram),
		.dram_ready(dram_ready),	
		.rd_data_valid(rd_data_valid),

		.paddr0_from_addr_management(paddr0_from_addr_management),
		.paddr1_from_addr_management(paddr1_from_addr_management),
		.addr_management_ready(addr_management_ready),
		.dram_en_o(dram_en_addr),
		.dram_read_or_write(dram_read_or_write_addr),
		.addr_to_dram_o(addr_to_dram_addr),
		.data_to_dram(data_to_dram_addr),
		.dram_data_mask(dram_data_mask_addr),
		.data_to_dram_en(data_to_dram_en_addr),
		.data_to_dram_end(data_to_dram_end_addr),
		.data_to_dram_ready(data_to_dram_ready),
		.addr_manage_dram_busy(addr_manage_dram_busy),
		.flash_left_capacity_io(flash_left_capacity),
		.free_block_fifo_heads_io(free_block_fifo_heads),
		.free_block_fifo_tails_io(free_block_fifo_tails),	
		.register_ready(register_ready)
		);
	

endmodule
