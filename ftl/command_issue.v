module command_issue(
	clk,
	rst,
	controller_rb_l_o,
	read_data_fifo_prog_full,
	data_from_flash_en_o,
	data_to_flash_en_o,
	data_from_flash_o,
	data_from_write_fifo,
	data_from_gc_fifo,
	command_in,
	controller_command_fifo_empty_or_not,
	finish_command_fifo_full,
	
	controller_command_fifo_out_en,		
	read_page_en,
	write_page_en,
	erase_block_en,
	addr,
	data_to_flash,
	data_to_read_fifo,
	data_to_gc_fifo,
	read_ready,
	write_fifo_out_en,
	read_fifo_in_en,
	gc_fifo_out_en,
	gc_fifo_in_en,
	controller_command_fifo_in,   //此处的controller_command_fifo实际上指的是finish_command_fifo
	controller_command_fifo_in_en,
	state
	);
	
	`include"ftl_define.v"
	input clk;
	input rst;
	input controller_rb_l_o;
	input read_data_fifo_prog_full;
	
	input data_from_flash_en_o;
	input data_to_flash_en_o;
	input [FLASH_IO_WIDTH*4-1:0] data_from_flash_o;
	input [FLASH_IO_WIDTH*4-1:0] data_from_write_fifo;
	
	input [COMMAND_WIDTH-1:0] command_in;
	input controller_command_fifo_empty_or_not;
	input [FLASH_IO_WIDTH*4-1:0] data_from_gc_fifo;
	input finish_command_fifo_full;
	
	
	output controller_command_fifo_out_en;
	output read_page_en;
	output write_page_en;
	output erase_block_en;
	output [23:0] addr;
	output [FLASH_IO_WIDTH*4-1:0] data_to_flash;	
	output [FLASH_IO_WIDTH*4-1:0] data_to_read_fifo;
	output read_ready;
	output write_fifo_out_en;
	output read_fifo_in_en;
	output [FLASH_IO_WIDTH*4-1:0] data_to_gc_fifo;
	output gc_fifo_out_en;
	output gc_fifo_in_en;
	output [COMMAND_WIDTH-1:0]controller_command_fifo_in;
	output controller_command_fifo_in_en;
	output [4:0] state;

	reg controller_command_fifo_out_en;
	reg [COMMAND_WIDTH-1:0] command;
	reg read_page_en;
	reg write_page_en;
	reg erase_block_en;
	reg [23:0] addr;
	wire [FLASH_IO_WIDTH*4-1:0] data_to_flash;	
	wire [FLASH_IO_WIDTH*4-1:0] data_to_read_fifo;
	wire [FLASH_IO_WIDTH*4-1:0] data_to_gc_fifo;
	reg read_ready;
	wire write_fifo_out_en;
	wire read_fifo_in_en;
	wire gc_fifo_out_en;
	wire gc_fifo_in_en;	
	reg [COMMAND_WIDTH-1:0]controller_command_fifo_in;
	reg controller_command_fifo_in_en;	
	reg [4:0] state;
	
	parameter IDLE                        =5'b00000;
	parameter COMMAND_INTERPRET           =5'b00001;
	parameter ISSUE_READ                  =5'b00010;
	parameter WAIT_A_CYCLE_FOR_READ       =5'b00011;
	parameter RECEIVE_READ_DATA           =5'b00100;
	parameter READ_END                    =5'b00101;
	parameter ISSUE_WRITE                 =5'b00110;
	parameter WAIT_A_CYCLE_FOR_WRITE      =5'b00111;
	parameter WAIT_WRITE                  =5'b01000;
	parameter WRITE_END                   =5'b01001;
	parameter ISSUE_MOVE                  =5'b01010;
	parameter WAIT_A_CYCLE_FOR_MOVE_READ  =5'b01011;
	parameter RECEIVE_READ_DATA_FOR_MOVE  =5'b01100;
	parameter ISSUE_WRITE_FOR_MOVE        =5'b01101;
	parameter WAIT_A_CYCLE_FOR_MOVE_WRITE =5'b01110;
	parameter WAIT_WRITE_FOR_MOVE         =5'b01111;
	parameter MOVE_END                    =5'b10000;
	parameter ISSUE_ERASE                 =5'b10001;
	parameter WAIT_A_CYCLE_FOR_ERASE      =5'b10010;
	parameter WAIT_ERASE                  =5'b10011;
	parameter ERASE_END                   =5'b10100;
	parameter FINISH                      =5'b10101;
	
	
	
	reg io_or_gc;
	reg [4:0] cycles;
	
	assign write_fifo_out_en  = (io_or_gc==1)? data_to_flash_en_o    :1'b0;
	assign gc_fifo_out_en     = (io_or_gc==0)? data_to_flash_en_o    :1'b0;
	assign read_fifo_in_en    = (io_or_gc==1)? data_from_flash_en_o  :1'b0;
	assign gc_fifo_in_en      = (io_or_gc==0)? data_from_flash_en_o  :1'b0;

	assign data_to_flash     = (io_or_gc==1)? data_from_write_fifo   :  data_from_gc_fifo;
//	assign data_to_flash[0]     = (io_or_gc==1)? data_from_write_fifo[7:0]   :data_from_gc_fifo[7:0];
//	assign data_to_flash[1]     = (io_or_gc==1)? data_from_write_fifo[15:8]  :data_from_gc_fifo[15:8];
//	assign data_to_flash[2]     = (io_or_gc==1)? data_from_write_fifo[23:16] :data_from_gc_fifo[23:16];
//	assign data_to_flash[3]     = (io_or_gc==1)? data_from_write_fifo[31:24] :data_from_gc_fifo[31:24];
	
	assign data_to_read_fifo  = (io_or_gc==1)? data_from_flash_o     :32'b00000000_00000000_00000000_00000000;
	assign data_to_gc_fifo    = (io_or_gc==0)? data_from_flash_o     :32'b00000000_00000000_00000000_00000000;

	
	always@ (posedge clk or negedge rst)
	begin
		if(!rst)
		begin
			controller_command_fifo_out_en <= 0;
			command			       <= 0;
			read_page_en	               <= 0;
			write_page_en	               <= 0;
			erase_block_en	               <= 0;
			addr			<= 0;
			read_ready		<= 0;
			state			<= IDLE;
			io_or_gc		<= 1;
			cycles			<= 0;
		end
		else
		begin
			case (state)
				IDLE://00
				begin
					if(controller_command_fifo_empty_or_not==0)
					begin
						command <= command_in;
						controller_command_fifo_out_en<=1;
						state <= COMMAND_INTERPRET;
					end
					else
						state<=IDLE;
				end
				COMMAND_INTERPRET://01
				begin
					controller_command_fifo_out_en<=0;
					case (command[127:126])
						READ:
							state <= ISSUE_READ;
						WRITE:
							state <= ISSUE_WRITE;
						MOVE:
							state <= ISSUE_MOVE;
						ERASE:
							state <= ISSUE_ERASE;						
					endcase
				end
				//////////////////////////////////////////////////////////////////////////////////////////read
				ISSUE_READ://02
				begin
					if(controller_rb_l_o==1 && read_data_fifo_prog_full==0)
					begin
						io_or_gc <= 1;
						read_page_en <= 1;
						addr <= command[87:64];
						read_ready <= 1;
						cycles <= 0;
						state <= WAIT_A_CYCLE_FOR_READ;	
					end
					else
						state<=ISSUE_READ;
				end
				WAIT_A_CYCLE_FOR_READ://03
				begin
					read_page_en <= 0;
					if(cycles==2)
						state <= RECEIVE_READ_DATA;
					else
					begin
						cycles <= cycles+1;
						state <= WAIT_A_CYCLE_FOR_READ;	
					end
				end
				RECEIVE_READ_DATA://04
				begin					
					if(controller_rb_l_o==1 && finish_command_fifo_full==0)
					begin
						controller_command_fifo_in<=command;
						controller_command_fifo_in_en<=1;
						state <= READ_END;
					end
					else
						state <= RECEIVE_READ_DATA;
				end
				READ_END://05
				begin
					controller_command_fifo_in_en<=0;
					state <= FINISH;
				end
				////////////////////////////////////////////////////////////////////////////////////////////////write
				ISSUE_WRITE://06
				begin
					if(controller_rb_l_o==1)
					begin
						io_or_gc <= 1;
						write_page_en <= 1;
						addr <= command[87:64];//物理地址
						cycles <= 0;
						state <= WAIT_A_CYCLE_FOR_WRITE;
					end
					else
						state<=ISSUE_WRITE;
				end
				WAIT_A_CYCLE_FOR_WRITE://07
				begin
					write_page_en <= 0;
					if(cycles==2)
						state <= WAIT_WRITE;
					else
					begin
						cycles <= cycles+1;
						state <= WAIT_A_CYCLE_FOR_WRITE;
					end
				end					
				WAIT_WRITE://08
				begin					
					if(controller_rb_l_o==1 && finish_command_fifo_full==0)
					begin
						if(command[125])
						begin
							controller_command_fifo_in<=command;
							controller_command_fifo_in_en<=1;
						end
						else  begin end 
						state <= WRITE_END;
					end
					else
						state <= WAIT_WRITE;
				end
				WRITE_END://09
				begin
					controller_command_fifo_in_en<=0;
					state <= FINISH;
				end
				////////////////////////////////////////////////////////////////////////////////////////////////move
				ISSUE_MOVE://0a
				begin
					if(controller_rb_l_o == 1 & read_data_fifo_prog_full==0 )
					begin
						io_or_gc <= 0;
						read_page_en <= 1;
						addr <= command[24:0];
						read_ready <= 1;
						cycles <= 0;
						state <= WAIT_A_CYCLE_FOR_MOVE_READ;
					end
					else
						state<=ISSUE_MOVE;
				end
				WAIT_A_CYCLE_FOR_MOVE_READ://0b
				begin
					read_page_en <= 0;
					if(cycles==2)
						state <= RECEIVE_READ_DATA_FOR_MOVE;
					else
					begin
						cycles <= cycles+1;
						state <= WAIT_A_CYCLE_FOR_MOVE_READ;
					end
				end
				RECEIVE_READ_DATA_FOR_MOVE://0c
				begin					
					if(controller_rb_l_o)
					begin
						state <= ISSUE_WRITE_FOR_MOVE;
					end
					else
						state <= WAIT_A_CYCLE_FOR_MOVE_READ;
				end				
				ISSUE_WRITE_FOR_MOVE://0d
				begin
					write_page_en <= 1;
					addr <= command[56:32];
					cycles <= 0;
					state <= WAIT_A_CYCLE_FOR_MOVE_WRITE;
				end
				WAIT_A_CYCLE_FOR_MOVE_WRITE://0e
				begin
					write_page_en <= 0;
					if(cycles==2)
						state <= WAIT_WRITE_FOR_MOVE;
					else
					begin
						cycles <= cycles+1;
						state <= WAIT_A_CYCLE_FOR_MOVE_WRITE;
					end
				end
				WAIT_WRITE_FOR_MOVE://0f
				begin					
					if(controller_rb_l_o)
					begin
						state <= MOVE_END;
					end
					else
						state <= WAIT_WRITE_FOR_MOVE;
				end
				MOVE_END://10
				begin
					state <= FINISH;
				end
				/////////////////////////////////////////////////////////////////////////////////////////////////erase
				ISSUE_ERASE://11
				begin
					if(controller_rb_l_o ==1 )
					begin
						erase_block_en <= 1;
						addr <= command[24:0];
						cycles <= 0;
						state <=  WAIT_A_CYCLE_FOR_ERASE;
					end
					else
						state<=ISSUE_ERASE;
				end
				WAIT_A_CYCLE_FOR_ERASE://12
				begin
					erase_block_en <= 0;
					if(cycles==2)
					begin
						state <= WAIT_ERASE;
						cycles<=0;
					end
					else
					begin
						cycles <= cycles+1;
						state<=WAIT_A_CYCLE_FOR_ERASE;
					end
				end
				WAIT_ERASE://13
				begin					
					if(controller_rb_l_o==1)
					begin
						cycles <= 0;
						state <= ERASE_END;
					end
					else
						state<=WAIT_ERASE;
				end
				ERASE_END://14
				begin
					if(cycles==8)
					begin
						state <= FINISH;
						cycles<=0;
					end
					else
					begin
						state<=ERASE_END;
						cycles <= cycles+1;
					end					
				end
				/////////////////////////////////////////////////////////////////////////////////////////////finish
				FINISH://15
				begin
					state <= IDLE;
				end			
				default: state <= IDLE;
			endcase
		end
	
	end
endmodule
