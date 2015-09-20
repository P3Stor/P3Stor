`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:22:07 01/21/2011 
// Design Name: 
// Module Name:    test 
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
module dram_test /*#(
		parameter PHYSICAL_ADDR_WIDTH		= 25,  //flash capacity 16KB*2^25 = 2^39B = 512GB
		parameter DRAM_IO_WIDTH   		= 256, //DRAM IO
		parameter DRAM_ADDR_WIDTH 		= 29,  //DRAM cacacity  64bits(2^3B)*2^29=2^32B = 4GB
		parameter DRAM_MASK_WIDTH 		= 32,  //8bits/mask bit  256/8 = 32
		parameter COMMAND_WIDTH 		= 128, //
		parameter GC_COMMAND_WIDTH 		= 29,  //
		parameter CACHE_ADDR_WIDTH 		= 17,  //cache space 16KB*2^17=2^31B=2G
		parameter L2P_TABLE_BASE		= 29'b00000_00000000_00000000_00000000, //32bits*2^25=2^27B=128MB
		parameter P2L_TABLE_BASE		= 29'b00001_00000000_00000000_00000000, //32bits*2^25=2^27B=128MB
		parameter FREE_BLOCK_FIFO_BASE		= 29'b00010_00000000_00000000_00000000, //32bits*2^17=2^19B=512KB
		parameter GARBAGE_TABLE_BASE		= 29'b00010_00000001_00000000_00000000, //32bits*2^17=2^19B=512KB
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
	)*/
	(
		reset,
		clk,
		phy_init_done,
		dram_ready_i,
		rd_data_valid_i,
		data_from_dram_i,
		dram_permit_i,
		
		dram_request_o,
		release_dram_o,		
		dram_en_o,
		dram_rd_wr_o,
		data_to_dram_en,
		data_to_dram_end,
		data_to_dram_ready,
		addr_to_dram_o,
		data_to_dram_o,
		dram_data_mask_o,
		//state,
		init_dram_done
    );
	
	`include"ftl_define.v"
	input reset;
	input clk;
	input phy_init_done;
	input dram_ready_i;
	input rd_data_valid_i;
	input [DRAM_IO_WIDTH-1:0]data_from_dram_i;
	input dram_permit_i;
		
	output  dram_request_o;
	output  release_dram_o;	 
	output  dram_en_o;							     //command enable, 1--dram_rd_wr valid
	output  dram_rd_wr_o;				     //read/write command, 1--write, 0--read
	output  [DRAM_ADDR_WIDTH-1:0] addr_to_dram_o;			  //write address
	output  [DRAM_IO_WIDTH-1:0] data_to_dram_o;  //write data
	output  [DRAM_MASK_WIDTH-1:0] dram_data_mask_o;
	
	input   data_to_dram_ready;
	output	data_to_dram_en;
	output	data_to_dram_end;
	//output  [4:0] state;
	output init_dram_done;
	 
	parameter IDLE							=5'b0000;
	parameter WRITE_L2P_P2L_TABLE			=5'b0001;
	parameter WRITE_L2P_P2L_TABLE2			=5'b0010;
	parameter WRITE_L2P_P2L_TABLE3			=5'b0011;
	parameter WRITE_FREE_BLOCK_FIFO0		=5'b0100;
	parameter WRITE_FREE_BLOCK_FIFO1		=5'b0101;
	parameter WRITE_FREE_BLOCK_FIFO2		=5'b0110;
	parameter WAIT_CI_DONE					=5'b0111;
	parameter READ_DRAM_TABLE0				=5'b1000;
	parameter READ_DRAM_TABLE1				=5'b1001;
	parameter READ_DRAM_TABLE2				=5'b1010;
	parameter RELASE_DRAM					=5'b1011;
	parameter FINISH						=5'b1100;
	parameter WRITE_GABBAGE_TABLE			=5'b1101;
	parameter WRITE_GABBAGE_TABLE2			=5'b1110;
	parameter WRITE_GABBAGE_TABLE3			=5'b1111;
	
	reg  dram_request_o;
	reg  release_dram_o;
	reg dram_en;							     //command enable, 1--dram_rd_wr valid
	reg dram_rd_wr_o;				     //read/write command, 1--write, 0--read
	reg [DRAM_ADDR_WIDTH-1:0] addr_to_dram;			  //write address
	reg [DRAM_IO_WIDTH-1:0] data_to_dram_o;  //write data
	reg [DRAM_MASK_WIDTH-1:0] dram_data_mask_o;
	reg init_dram_done;
	reg [DRAM_ADDR_WIDTH-1:0]dram_addr;
	
	reg [3:0] state;
	reg [4:0] state_buf;
	reg [31:0]count;
	reg [DRAM_IO_WIDTH-1:0]data_from_dram_tmp;
	reg [DRAM_ADDR_WIDTH-1:0] address_index;
	
	
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
	assign addr_to_dram_o=(ci_done)? addr_to_dram:addr_to_dram_ci;//czg
	
	parameter COMMANDS_ISSUE0   =2'b00; 
	parameter COMMANDS_ISSUE1   =2'b01;
	parameter COMMANDS_ISSUE2   =2'b10;
	parameter COMMANDS_ISSUE3   =2'b11;
	
	 
	always@ (posedge clk or negedge reset)
	begin
		if(!reset)
		begin
			dram_en            <= 0;							    
			dram_rd_wr_o <= 0;							     
			addr_to_dram       <= 0;			  
			data_to_dram_o       <= 0; 
			dram_data_mask_o     <= 0;
			state              <= IDLE;
			count              <= 0;
			data_from_dram_tmp <= 0;
			state_buf		   <= 0;
			init_dram_done	   <=0;
			dram_request_o 	   <=0;
			release_dram_o 	   <=0;
			dram_addr		   <=0;
			address_index      <=0;
			ci_en 			         <= 0;
			ci_addr 		         <= 0;
			ci_num			         <= 0;
			ci_data_cnt			 <= 0;
			data_to_dram_en	                 <= 0;
			data_to_dram_end                 <= 0;
		end
		else
		begin
		case (state)
			IDLE://00
			begin
				if(phy_init_done)
				begin
				init_dram_done <=0;
				dram_request_o<=1; 
				state<=WRITE_L2P_P2L_TABLE;		
				end
			end	
			
				
				WRITE_L2P_P2L_TABLE:
				begin
					if(dram_permit_i)
					begin
						dram_request_o<=0;
						if(ci_done) 
						begin
							ci_en <=1;
							dram_rd_wr_o <= 0;//write
							ci_addr <=L2P_TABLE_BASE;
						//	ci_num<=15'b10000_00000_00000;//2^14*2^6b=2^20b   4b*0x4000*2^3=2^(5+14)=2^19
							ci_num<=25'b1_00000000_00000000_00000000;//l2p+p2l=2^25DRAM=2^22 * 8DRAM
							dram_data_mask_o<=32'h0;
							data_to_dram_o <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;
							data_to_dram_en <= 1'b1;
							ci_data_cnt<=0;				
							state <=WRITE_L2P_P2L_TABLE2;
						end					
					end
					else state <= WRITE_L2P_P2L_TABLE;
				end
				WRITE_L2P_P2L_TABLE2:
				begin
					ci_en <=0;
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						state <= WRITE_L2P_P2L_TABLE3;
					end			
				end
				WRITE_L2P_P2L_TABLE3:
				begin
				if(ci_data_cnt<ci_num)
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 256'h7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff_7fffffff;
						data_to_dram_end <= 1'b0;
						data_to_dram_en <= 1'b1;
						state <= WRITE_L2P_P2L_TABLE2;
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
						state <= WRITE_FREE_BLOCK_FIFO0;
					end
				end
				end		
			
			WRITE_FREE_BLOCK_FIFO0:
				begin
					if(ci_done) 
					begin
						ci_en <=1;
						dram_rd_wr_o <= 0;//write
						ci_addr <=FREE_BLOCK_FIFO_BASE;
						ci_num<=16'b10000000_00000000;
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= {count+16'h3800,count+16'h3000,count+16'h2800,count+16'h2000,count+16'h1800,count+16'h1000,count+16'h0800,count};
						count<=count+16'h4000;
						data_to_dram_en <= 1'b1;
						ci_data_cnt<=0;
						state <=WRITE_FREE_BLOCK_FIFO1;
					end
				end
				WRITE_FREE_BLOCK_FIFO1:
				begin
					ci_en <=0;
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= {count+16'h3800,count+16'h3000,count+16'h2800,count+16'h2000,count+16'h1800,count+16'h1000,count+16'h0800,count};
						count<=count+16'h4000;
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						state <= WRITE_FREE_BLOCK_FIFO2;
					end
				end
				WRITE_FREE_BLOCK_FIFO2:
				begin
				if(ci_data_cnt<ci_num)
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o <=32'h0;
						data_to_dram_o <= {count+16'h3800,count+16'h3000,count+16'h2800,count+16'h2000,count+16'h1800,count+16'h1000,count+16'h0800,count};
						count<=count+16'h4000;
						data_to_dram_end <= 1'b0;
						data_to_dram_en <= 1'b1;
						state <= WRITE_FREE_BLOCK_FIFO1;
					end
				end
				else 
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 0;
						data_to_dram_end <= 1'b0;
						data_to_dram_en <= 	1'b0;
						state <= WRITE_GABBAGE_TABLE;
					end
				end				
				end
				
				WRITE_GABBAGE_TABLE:
				begin
					if(dram_permit_i)
					begin
						dram_request_o<=0;
						if(ci_done) 
						begin
							ci_en <=1;
							dram_rd_wr_o <= 0;//write
							ci_addr <=GARBAGE_TABLE_BASE;
						//	ci_num<=15'b10000_00000_00000;//2^14*2^6b=2^20b   4b*0x4000*2^3=2^(5+14)=2^19
							ci_num<=16'b10000000_00000000;//l2p+p2l=2^25DRAM=2^22 * 8DRAM
							dram_data_mask_o<=32'h0;
							data_to_dram_o <= 0;
							data_to_dram_en <= 1'b1;
							ci_data_cnt<=0;				
							state <=WRITE_GABBAGE_TABLE2;
						end					
					end
					else state <= WRITE_GABBAGE_TABLE;
				end
				WRITE_GABBAGE_TABLE2:
				begin
					ci_en <=0;
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 0;
						data_to_dram_end <= 1'b1;
						ci_data_cnt <= ci_data_cnt+1;
						state <= WRITE_GABBAGE_TABLE3;
					end			
				end
				WRITE_GABBAGE_TABLE3:
				begin
				if(ci_data_cnt<ci_num)
				begin
					if (data_to_dram_ready) 
					begin
						dram_data_mask_o<=32'h0;
						data_to_dram_o <= 0;
						data_to_dram_end <= 1'b0;
						data_to_dram_en <= 1'b1;
						state <= WRITE_GABBAGE_TABLE2;
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
						state <= WAIT_CI_DONE;
					end
				end
				end
				
				
				
				WAIT_CI_DONE:
				begin
					if(ci_done)
					begin
						dram_en <= 1'b1;
						addr_to_dram <= address_index; //4个64b为256b
						dram_rd_wr_o <= 1;//read	
						state <= READ_DRAM_TABLE0;
					end					
				end
			
			READ_DRAM_TABLE0: //11
			begin
			if(dram_ready_i)
			  begin
			   dram_en <= 0;
			   state <= READ_DRAM_TABLE1;		
			  end
			end
			READ_DRAM_TABLE1: //12
			begin
				if(rd_data_valid_i)
				begin
					data_from_dram_tmp<=data_from_dram_i;
					state<=READ_DRAM_TABLE2;
				end
			end
			READ_DRAM_TABLE2:  //13
			begin
				if(rd_data_valid_i)
				begin
					data_from_dram_tmp<=data_from_dram_i;
					//state <= FINISH;
				end					
				
				if(address_index == CACHE_ENTRY_BASE + 18'b10_0000_0000_0000_0000)//256*512b=16KB     一次dram_en进行两次IO操作，共512b
				   begin
					    dram_en <= 0;
					    address_index <=0;			
					    //state_buf<=;  //修改跳转状态，对READ，WRITE，MOVE和ERASE进行测试！
					    state <= RELASE_DRAM;
				   end
				   
				else if(address_index == CACHE_ENTRY_BASE  + 5'b10000)
					begin
						address_index <= CACHE_ENTRY_BASE + 18'b01_1111_1111_1111_0000;
						state <= WAIT_CI_DONE;	
				    end					 
				else if(address_index == GARBAGE_TABLE_BASE + 17'b1_0000_0000_0000_0000)
					begin
						address_index <= CACHE_ENTRY_BASE;
						state <= WAIT_CI_DONE;	
				    end			

				else if(address_index == GARBAGE_TABLE_BASE + 5'b10000)
					begin
						address_index <= GARBAGE_TABLE_BASE + 17'b0_1111_1111_1111_0000;
						state <= WAIT_CI_DONE;	
				    end
				//else if(address_index == FREE_BLOCK_FIFO_BASE + 17'b1_0000_0000_0000_0000)
				//	begin
				//		address_index <= GARBAGE_TABLE_BASE ;
				//		state <= READ_DRAM_TABLE0;	
				//    end
				else if(address_index == FREE_BLOCK_FIFO_BASE + 5'b10000)
					begin
						address_index <= GARBAGE_TABLE_BASE -5'b10000;
						state <= WAIT_CI_DONE;	
						end	
				else if( address_index == P2L_TABLE_BASE + 5'b10000)	
					begin
						address_index <= FREE_BLOCK_FIFO_BASE - 5'b10000;
						state <= WAIT_CI_DONE;	
					end	
				else if(address_index == 5'b10000) 
					begin
						address_index <= P2L_TABLE_BASE - 5'b10000;
						state <= WAIT_CI_DONE;	
					end
				else 
					begin
					     state <= WAIT_CI_DONE;	
						 address_index <= address_index +4'h8;
					end
			end					
			
			RELASE_DRAM://1E
			begin
				release_dram_o <=1;
				init_dram_done	<=1;
				state<=FINISH;
			end
			FINISH: //1f
			begin
				state <= FINISH;
				release_dram_o <=0;			
			end
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
