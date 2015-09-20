`timescale 1ns / 1ps
module ftl_top(
		reset,clk,clk_83X2M,clk_83M,clk_83M_reverse,phy_init_done,
	        pcie_data_rec_fifo_out,pcie_data_rec_fifo_out_en,pcie_command_rec_fifo_out,pcie_command_rec_fifo_empty_or_not,
                pcie_command_rec_fifo_out_en,pcie_data_send_fifo_in,pcie_data_send_fifo_in_en,pcie_data_send_fifo_out_prog_full,
                pcie_command_send_fifo_full_or_not,pcie_command_send_fifo_in,pcie_command_send_fifo_in_en,
		//dram
		dram_ready,rd_data_valid,data_from_dram,							
		dram_en,dram_read_or_write,addr_to_dram,data_to_dram,dram_data_mask,
		data_to_dram_en,data_to_dram_end,data_to_dram_ready,initial_dram_done,
		//flash_controller
		nand0Cle,nand0Ale,nand0Clk_We_n,nand0Wr_Re_n,nand0Wp_n,nand0Ce_n,nand0Rb_n,nand0DQX,nand0DQS,
		nand1Cle,nand1Ale,nand1Clk_We_n,nand1Wr_Re_n,nand1Wp_n,nand1Ce_n,nand1Rb_n,nand1DQX,nand1DQS,
		nand2Cle,nand2Ale,nand2Clk_We_n,nand2Wr_Re_n,nand2Wp_n,nand2Ce_n,nand2Rb_n,nand2DQX,nand2DQS,
		nand3Cle,nand3Ale,nand3Clk_We_n,nand3Wr_Re_n,nand3Wp_n,nand3Ce_n,nand3Rb_n,nand3DQX,nand3DQS,
		nand4Cle,nand4Ale,nand4Clk_We_n,nand4Wr_Re_n,nand4Wp_n,nand4Ce_n,nand4Rb_n,nand4DQX,nand4DQS,
		nand5Cle,nand5Ale,nand5Clk_We_n,nand5Wr_Re_n,nand5Wp_n,nand5Ce_n,nand5Rb_n,nand5DQX,nand5DQS,
		nand6Cle,nand6Ale,nand6Clk_We_n,nand6Wr_Re_n,nand6Wp_n,nand6Ce_n,nand6Rb_n,nand6DQX,nand6DQS,
		nand7Cle,nand7Ale,nand7Clk_We_n,nand7Wr_Re_n,nand7Wp_n,nand7Ce_n,nand7Rb_n,nand7DQX,nand7DQS
    );

	`include"ftl_define.v"
	input reset;
	input clk;
	input clk_83X2M;
	input clk_83M;
	input clk_83M_reverse;
	input phy_init_done;
	
/***************Instantiate the IDELAYCTRL primitive ***********/
// IDELAYCTRL: IDELAY Tap Delay Value Control
// Virtex-6
// Xilinx HDL Libraries Guide, version 12.4
 
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IDELAYCTRL IDELAYCTRL_inst (
	.RDY(), // 1-bit Indicates the validity of the reference clock input, REFCLK. When REFCLK
	// disappears (i.e., REFCLK is held High or Low for one clock period or more), the RDY
	// signal is deasserted.
	.REFCLK(clk), // 1-bit Provides a voltage bias, independent of process, voltage, and temperature
	// variations, to the tap-delay lines in the IOBs. The frequency of REFCLK must be 200
	// MHz to guarantee the tap-delay value specified in the applicable data sheet.
	.RST(reset) // 1-bit Resets the IDELAYCTRL circuitry. The RST signal is an active-high asynchronous
	// reset. To reset the IDELAYCTRL, assert it High for at least 50 ns.
	);
// End of IDELAYCTRL_inst instantiation

	//pcie_data_rec_fifo
	input [DRAM_IO_WIDTH-1:0]pcie_data_rec_fifo_out; // output [255 : 0] dout
	output pcie_data_rec_fifo_out_en; // input rd_en
	wire pcie_data_rec_fifo_out_en; // input rd_en
	//pcie_command_rec_fifo
	input [COMMAND_WIDTH-1:0]pcie_command_rec_fifo_out; // output [127 : 0] dout
	input pcie_command_rec_fifo_empty_or_not; // output empty
	output pcie_command_rec_fifo_out_en; // input rd_en
	wire pcie_command_rec_fifo_out_en; // input rd_en
	//pcie_data_send_fifo
	input pcie_data_send_fifo_out_prog_full;
	output [DRAM_IO_WIDTH-1:0]pcie_data_send_fifo_in;
	output pcie_data_send_fifo_in_en;
	wire [DRAM_IO_WIDTH-1:0]pcie_data_send_fifo_in;
	wire pcie_data_send_fifo_in_en;
	//pcie_command_send_fifo
	input 	pcie_command_send_fifo_full_or_not;
	output [COMMAND_WIDTH-1:0]pcie_command_send_fifo_in;
	output pcie_command_send_fifo_in_en;
	wire [COMMAND_WIDTH-1:0]pcie_command_send_fifo_in;
	wire pcie_command_send_fifo_in_en;
	
	//dram
	input dram_ready;
	input rd_data_valid;
	input [DRAM_IO_WIDTH-1:0]data_from_dram;			

	input	data_to_dram_ready;
	output	data_to_dram_en;
	output	data_to_dram_end;	
	output dram_en;
	output dram_read_or_write;
	output [DRAM_ADDR_WIDTH-1:0]addr_to_dram;
	output [DRAM_IO_WIDTH-1:0]data_to_dram;
	output [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	output initial_dram_done;
	reg dram_en;
	reg dram_read_or_write;
	reg [DRAM_ADDR_WIDTH-1:0]addr_to_dram;
	reg [DRAM_IO_WIDTH-1:0]data_to_dram;
	reg [DRAM_MASK_WIDTH-1:0]dram_data_mask;
	reg data_to_dram_en;
	reg data_to_dram_end;
	
	wire cache_dram_en;
	wire cache_dram_read_or_write;
	wire [DRAM_ADDR_WIDTH-1:0]cache_addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]cache_data_to_dram;	
	wire [DRAM_MASK_WIDTH-1:0]cache_dram_data_mask;
	wire cache_data_to_dram_en;
	wire cache_data_to_dram_end;
	
	wire io_dram_en;
	wire io_dram_read_or_write;
	wire [DRAM_ADDR_WIDTH-1:0]io_addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]io_data_to_dram;
	wire [DRAM_MASK_WIDTH-1:0]io_dram_data_mask;	
	wire io_data_to_dram_en;
	wire io_data_to_dram_end;
	
	wire gc_dram_en;
	wire gc_dram_read_or_write;
	wire [DRAM_ADDR_WIDTH-1:0]gc_addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]gc_data_to_dram;
	wire [DRAM_MASK_WIDTH-1:0]gc_dram_data_mask;
	wire gc_data_to_dram_en;
	wire gc_data_to_dram_end;
	
	wire check_dram_en;
	wire check_dram_read_or_write;
	wire [DRAM_ADDR_WIDTH-1:0]check_addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]check_data_to_dram;
	wire [DRAM_MASK_WIDTH-1:0]check_dram_data_mask;
	wire check_data_to_dram_en;
	wire check_data_to_dram_end;
	
	wire test_dram_en;
	wire test_dram_read_or_write;
	wire [DRAM_ADDR_WIDTH-1:0]test_addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]test_data_to_dram;
	wire [DRAM_MASK_WIDTH-1:0]test_dram_data_mask;
	wire test_dram_data_to_dram_en;
	wire test_dram_data_to_dram_end;
	
	wire backup_dram_en;
	wire backup_dram_read_or_write;
	wire [DRAM_ADDR_WIDTH-1:0]backup_addr_to_dram;
	wire [DRAM_IO_WIDTH-1:0]backup_data_to_dram;
	wire [DRAM_MASK_WIDTH-1:0]backup_dram_data_mask;
	wire backup_data_to_dram_en;
	wire backup_data_to_dram_end;
	
	//dram arbitrator
	//dram arbitrator input
	wire cache_dram_request;
	wire cache_release_dram;
	wire io_dram_request;
	wire io_release_dram;
	wire gc_dram_request;
	wire gc_release_dram;
	wire check_dram_request;	
	wire check_release_dram;
	wire test_dram_request;	
	wire test_release_dram;
	wire backup_dram_request;	
	wire backup_release_dram;
	//dram arbitrator output
	wire cache_dram_permit;
	wire io_dram_permit;
	wire gc_dram_permit;
	wire check_dram_permit;
	wire test_dram_permit;
	wire backup_dram_permit;
	//ssd_command_fifo
	wire [COMMAND_WIDTH-1:0]ssd_command_fifo_in; // input [127 : 0] din
	wire ssd_command_fifo_in_en; // input wr_en
	wire ssd_command_fifo_out_en; // input rd_en
	wire [COMMAND_WIDTH-1:0]ssd_command_fifo_out; // output [127: 0] dout
	wire ssd_command_fifo_full; // output full
	wire ssd_command_fifo_empty_or_not;// output empty
	//gc_command_fifo
	wire [GC_COMMAND_WIDTH-1:0]gc_command_fifo_in; // input [28 : 0] din
	wire gc_command_fifo_in_en;// input wr_en
	wire gc_command_fifo_out_en; // input rd_en
	wire [GC_COMMAND_WIDTH-1:0]gc_command_fifo_out; // output [28 : 0] dout
	wire gc_command_fifo_empty_or_not; // output empty
	wire gc_command_fifo_prog_full; // output prog_full
	//controller_command_fifo 	
	wire [COMMAND_WIDTH-1:0]controller_command_fifo_in; // input [127 : 0] din
	wire [7:0]controller_command_fifo_in_en; // input wr_en 
	  //wire controller_command_fifo_out_en[0:7]; // input rd_en
	  //wire [COMMAND_WIDTH-1:0]controller_command_fifo_out[0:7]; // output [127 : 0] dout
	  //wire controller_command_fifo_full[0:7];
	  //wire controller_command_fifo_empty_or_not[0:7]; // output empty	
	//write_data_fifo
	wire [DRAM_IO_WIDTH-1:0]write_data_fifo_in; // input [255 : 0] din
	wire [7:0]write_data_fifo_in_en; // input wr_en
	  //wire write_fifo_out_en[0:7]; // input rd_en
	  //wire [FLASH_IO_WIDTH*4-1:0]data_from_ftl[0:7]; // output [31 : 0] dout
	  //wire write_data_fifo_prog_full[0:7];
	  //wire write_data_fifo_full[0:7];
	//read_data_fifo
	  //wire [FLASH_IO_WIDTH*4-1:0]data_to_ftl[0:7]; // input [31 : 0] din
	  //wire read_fifo_in_en[0:7]; // input wr_en
	  //wire read_data_fifo_prog_full[0:7]; // output prog_full
	  //wire read_data_fifo_full [0:7];
	wire read_data_fifo_out_en[0:7]; // input rd_en
	wire [DRAM_IO_WIDTH-1:0]read_data_fifo_out[0:7]; // output [255 : 0] dout
	//gc_fifo
	  //wire [FLASH_IO_WIDTH*4-1:0]data_to_gc_fifo[0:7]; // input [31 : 0] din
	  //wire gc_fifo_in_en[0:7]; // input wr_en
	  //wire gc_fifo_out_en[0:7]; // input rd_en
	  //wire [FLASH_IO_WIDTH*4-1:0]data_from_gc_fifo[0:7]; // output [31 : 0] dout
	  //wire GC_fifo_full[0:7];
	//finish_command_fifo
	wire [COMMAND_WIDTH-1:0]finish_command_fifo8_in; // input [127 : 0] din
	wire finish_command_fifo8_in_en;
	  //wire [COMMAND_WIDTH-1:0]finish_command_fifo_in[0:7]; // input [127 : 0] din
	  //wire finish_command_fifo_in_en[0:7]; // input wr_en 
	wire finish_command_fifo_out_en[0:8]; // input rd_en
	wire [COMMAND_WIDTH-1:0]finish_command_fifo_out[0:8]; // output [127 : 0] dout
	wire finish_command_fifo_full[0:8];
	wire finish_command_fifo_empty_or_not[0:8]; // output empty	
	
	
	
	//flash_controller
	//input
	  //wire read_page_en[0:7];
	  //wire write_page_en[0:7];
	  //wire erase_block_en[0:7];
	  //wire read_ready[0:7];
	  //wire [FLASH_IO_WIDTH*4-1:0]data_from_host[0:7];
	  //wire [21:0]addr[0:7];	
	//output
	  //wire [FLASH_IO_WIDTH*4-1:0]data_from_flash_o[0:7];
	  //wire controller_rb_l[0:7];
	  //wire data_from_flash_en[0:7];
	  //wire data_to_flash_en[0:7];	
	
	wire dram_backup_en;
	wire [5:0] state_check;
	//wire [4:0] state_gc;
	wire [4:0] state_io;
	//wire [3:0] initial_dram_state;
	
	wire [7:0] idle_flag;
	wire all_idle_flag;
	assign all_idle_flag =  idle_flag[0] & idle_flag[1] & idle_flag[2] & idle_flag[3] & idle_flag[4] & idle_flag[5] & idle_flag[6] & idle_flag[7];	
	wire [7:0] Cmd_Available;
	wire all_Cmd_Available_flag;
	assign all_Cmd_Available_flag = Cmd_Available[0] & Cmd_Available[1] & Cmd_Available[2] & Cmd_Available[3] & Cmd_Available[4] & Cmd_Available[5] & Cmd_Available[6] & Cmd_Available[7];

	
	wire [COMMAND_WIDTH-1:0]checkcache_ssd_command_fifo_in; // input [127 : 0] din
	wire checkcache_ssd_command_fifo_in_en; // input wr_en
	wire [COMMAND_WIDTH-1:0]backup_ssd_command_fifo_in; // input [127 : 0] din
	wire backup_ssd_command_fifo_in_en; // input wr_en
	wire [COMMAND_WIDTH-1:0]io_controller_command_fifo_in; // input [127 : 0] din
	wire [7:0]io_controller_command_fifo_in_en; // input wr_en 
	wire [COMMAND_WIDTH-1:0]backup_controller_command_fifo_in; // input [127 : 0] din
	wire [7:0]backup_controller_command_fifo_in_en; // input wr_en 
	wire [DRAM_IO_WIDTH-1:0]io_write_data_fifo_in; // input [255 : 0] din
	wire [7:0]io_write_data_fifo_in_en; // input wr_en
	wire [DRAM_IO_WIDTH-1:0]backup_write_data_fifo_in; // input [255 : 0] din
	wire [7:0]backup_write_data_fifo_in_en; // input wr_en
	wire backup_or_checkcache;
	wire backup_or_io;
	wire initial_dram_done;
	wire init_dram_done;
	wire register_ready;
	wire [7:0] initialdram_controller_command_fifo_in_en;
	wire [COMMAND_WIDTH-1:0] initialdram_controller_command_fifo_in;
		//wire [16:0]flash_left_capacity;//512GB flash217η
	wire [127:0] free_block_fifo_tails;
	wire [127:0] free_block_fifo_heads;
		//GC
	wire [18:0]left_capacity;//512GB flash��7次方个块
		//wire [16:0]flash_left_capacity;//512GB flash217η
	wire [127:0] free_block_fifo_tails_initial;
	wire [127:0] free_block_fifo_heads_initial;
		//GC
	wire [18:0]left_capacity_initial;//512GB flash��7次方个块
			//wire [16:0]flash_left_capacity;//512GB flash217η
	wire [127:0] free_block_fifo_tails_io;
	wire [127:0] free_block_fifo_heads_io;
		//GC
	wire [18:0]left_capacity_io;//512GB flash��7次方个块
	
	assign ssd_command_fifo_in=(backup_or_checkcache)?backup_ssd_command_fifo_in:checkcache_ssd_command_fifo_in;
	assign ssd_command_fifo_in_en=(backup_or_checkcache)?backup_ssd_command_fifo_in_en:checkcache_ssd_command_fifo_in_en;
	assign controller_command_fifo_in=(initial_dram_done)?((backup_or_io)?backup_controller_command_fifo_in:io_controller_command_fifo_in):initialdram_controller_command_fifo_in;
	assign controller_command_fifo_in_en=(initial_dram_done)?((backup_or_io)?backup_controller_command_fifo_in_en:io_controller_command_fifo_in_en):initialdram_controller_command_fifo_in_en;
	assign write_data_fifo_in=(backup_or_io)?backup_write_data_fifo_in:io_write_data_fifo_in;
	assign write_data_fifo_in_en=(backup_or_io)?backup_write_data_fifo_in_en:io_write_data_fifo_in_en;
	assign left_capacity_io= register_ready? left_capacity_initial :19'bz;
	assign free_block_fifo_heads_io= register_ready? free_block_fifo_heads_initial : 128'bz;
	assign free_block_fifo_tails_io= register_ready? free_block_fifo_tails_initial : 128'bz;
	assign left_capacity= left_capacity_io ;
	assign free_block_fifo_heads=  free_block_fifo_heads_io;
	assign free_block_fifo_tails=  free_block_fifo_tails_io;


	output nand0Cle;
	output nand0Ale;
	output nand0Clk_We_n;
	output nand0Wr_Re_n;
	output nand0Wp_n;
	output [7:0] nand0Ce_n;
	input [7:0] nand0Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand0DQX;
	inout nand0DQS;
	
	output nand1Cle;
	output nand1Ale;
	output nand1Clk_We_n;
	output nand1Wr_Re_n;
	output nand1Wp_n;
	output [7:0] nand1Ce_n;
	input [7:0] nand1Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand1DQX;
	inout nand1DQS;
	
	output nand2Cle;
	output nand2Ale;
	output nand2Clk_We_n;
	output nand2Wr_Re_n;
	output nand2Wp_n;
	output [7:0] nand2Ce_n;
	input [7:0] nand2Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand2DQX;
	inout nand2DQS;
	
	output nand3Cle;
	output nand3Ale;
	output nand3Clk_We_n;
	output nand3Wr_Re_n;
	output nand3Wp_n;
	output [7:0] nand3Ce_n;
	input [7:0] nand3Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand3DQX;
	inout nand3DQS;
	
	output nand4Cle;
	output nand4Ale;
	output nand4Clk_We_n;
	output nand4Wr_Re_n;
	output nand4Wp_n;
	output [7:0] nand4Ce_n;
	input [7:0] nand4Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand4DQX;
	inout nand4DQS;
	
	output nand5Cle;
	output nand5Ale;
	output nand5Clk_We_n;
	output nand5Wr_Re_n;
	output nand5Wp_n;
	output [7:0] nand5Ce_n;
	input [7:0] nand5Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand5DQX;
	inout nand5DQS;
	
	output nand6Cle;
	output nand6Ale;
	output nand6Clk_We_n;
	output nand6Wr_Re_n;
	output nand6Wp_n;
	output [7:0] nand6Ce_n;
	input [7:0] nand6Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand6DQX;
	inout nand6DQS;
	
	output nand7Cle;
	output nand7Ale;
	output nand7Clk_We_n;
	output nand7Wr_Re_n;
	output nand7Wp_n;
	output [7:0] nand7Ce_n;
	input [7:0] nand7Rb_n;
	inout [FLASH_IO_WIDTH-1:0] nand7DQX;
	inout nand7DQS;

	always @(*)
	begin
		case({cache_dram_permit,io_dram_permit,gc_dram_permit,check_dram_permit,test_dram_permit,backup_dram_permit})
			6'b100000:
			begin
				dram_en            = cache_dram_en;
				dram_read_or_write = cache_dram_read_or_write;
				addr_to_dram       = cache_addr_to_dram;
				data_to_dram       = cache_data_to_dram;
				dram_data_mask     = cache_dram_data_mask;
				data_to_dram_en    = cache_data_to_dram_en;
				data_to_dram_end   = cache_data_to_dram_end;
			end
			6'b010000:
			begin
				dram_en            = io_dram_en;
				dram_read_or_write = io_dram_read_or_write;
				addr_to_dram       = io_addr_to_dram;
				data_to_dram       = io_data_to_dram;
				dram_data_mask     = io_dram_data_mask;
				data_to_dram_en	   = io_data_to_dram_en;
				data_to_dram_end   = io_data_to_dram_end;
				end
			6'b001000:
			begin
				dram_en            = gc_dram_en;
				dram_read_or_write = gc_dram_read_or_write;
				addr_to_dram       = gc_addr_to_dram;
				data_to_dram       = gc_data_to_dram;
				dram_data_mask     = gc_dram_data_mask;
				data_to_dram_en	   = gc_data_to_dram_en;
				data_to_dram_end   = gc_data_to_dram_end;	
				end
			6'b000100:
			begin
				dram_en            = check_dram_en;
				dram_read_or_write = check_dram_read_or_write;
				addr_to_dram       = check_addr_to_dram;
				data_to_dram       = check_data_to_dram;
				dram_data_mask     = check_dram_data_mask;
				data_to_dram_en    = check_data_to_dram_en;
				data_to_dram_end   = check_data_to_dram_end;				
			end
			6'b000010:
			begin
				dram_en            = test_dram_en;
				dram_read_or_write = test_dram_read_or_write;
				addr_to_dram       = test_addr_to_dram;
				data_to_dram       = test_data_to_dram;
				dram_data_mask     = test_dram_data_mask;
				data_to_dram_en	   = test_dram_data_to_dram_en;
				data_to_dram_end   = test_dram_data_to_dram_end;
			end
			6'b000001:
			begin
				dram_en            = backup_dram_en;
				dram_read_or_write = backup_dram_read_or_write;
				addr_to_dram       = backup_addr_to_dram;
				data_to_dram       = backup_data_to_dram;
				dram_data_mask     = backup_dram_data_mask;
				data_to_dram_en	   = backup_data_to_dram_en;
				data_to_dram_end   = backup_data_to_dram_end;
			end
			default:
			begin
				dram_en            = cache_dram_en;
				dram_read_or_write = cache_dram_read_or_write;
				addr_to_dram       = cache_addr_to_dram;
				data_to_dram       = cache_data_to_dram;
				dram_data_mask     = cache_dram_data_mask;
				data_to_dram_en	   = cache_data_to_dram_en;
				data_to_dram_end   = cache_data_to_dram_end;
			end
		endcase
	end
	
	arbitrator arbitrator_instance(	
		.reset(!reset),
		.clk(clk),	
		.request0(cache_dram_request),
		.release0(cache_release_dram),	
		.request1(io_dram_request),	
		.release1(io_release_dram),
		.request2(1'b0),	
		.release2(gc_release_dram),
		.request3(check_dram_request),	
		.release3(check_release_dram),	
		.request4(test_dram_request),	
		.release4(test_release_dram),	
		.request5(backup_dram_request),	
		.release5(backup_release_dram),
		
		.permit0(cache_dram_permit),
		.permit1(io_dram_permit),
		.permit2(gc_dram_permit),
		.permit3(check_dram_permit),
		.permit4(test_dram_permit),
		.permit5(backup_dram_permit)
		//.state(state_arbitrator)
	);

	dram_test dram_test_instance(
		.reset(!reset),
		.clk(clk),		
		.phy_init_done(phy_init_done),
		.dram_ready_i(dram_ready),
		.rd_data_valid_i(rd_data_valid),     
		.data_from_dram_i(data_from_dram),  
		.dram_permit_i(test_dram_permit),
		
		.dram_request_o(test_dram_request),
		.release_dram_o(test_release_dram),
		.dram_en_o(test_dram_en),           
		.dram_rd_wr_o(test_dram_read_or_write),
		.data_to_dram_en(test_dram_data_to_dram_en),
		.data_to_dram_end(test_dram_data_to_dram_end),
		.data_to_dram_ready(data_to_dram_ready),
		.addr_to_dram_o(test_addr_to_dram),      
		.data_to_dram_o(test_data_to_dram),      
		.dram_data_mask_o(test_dram_data_mask),
		//.state(state_test),
		.init_dram_done(init_dram_done)		
	);
	
	initial_dram initial_dram_inst (
    .reset(!reset), 
    .clk(clk), 
    .trigger_initial_dram(init_dram_done), 
    .all_Cmd_Available_flag(all_Cmd_Available_flag), 
    .controller_command_fifo_in(initialdram_controller_command_fifo_in), 
    .controller_command_fifo_in_en(initialdram_controller_command_fifo_in_en)
    );

	
	check_cache check_cache_instance(
		//input
		.reset(!reset),
		.clk(clk),
		.initial_dram_done(initial_dram_done),
		//pcie_command_fifo
		.pcie_cmd_rec_fifo_empty_i(pcie_command_rec_fifo_empty_or_not),
		.pcie_cmd_rec_fifo_i(pcie_command_rec_fifo_out),
		.pcie_cmd_rec_fifo_en_o(pcie_command_rec_fifo_out_en),
		//pcie_data_fifo
		.pcie_data_rec_fifo_en_o(pcie_data_rec_fifo_out_en),
		.pcie_data_rec_fifo_i(pcie_data_rec_fifo_out),	
		//dram
		.data_from_dram_i(data_from_dram),
		.dram_ready_i(dram_ready),	
		.rd_data_valid_i(rd_data_valid),
		.addr_to_dram_o(cache_addr_to_dram),
		.data_to_dram_o(cache_data_to_dram),
		.dram_data_mask_o(cache_dram_data_mask), 
		.dram_en_o(cache_dram_en),
		.dram_rd_wr_o(cache_dram_read_or_write),
		.data_to_dram_en(cache_data_to_dram_en),
		.data_to_dram_end(cache_data_to_dram_end),
		.data_to_dram_ready(data_to_dram_ready),
		
		//arbitrator
		.dram_permit_i(cache_dram_permit),
		.dram_request_o(cache_dram_request),
		.release_dram_o(cache_release_dram),
		//ssd_command_fifo
		.ssd_cmd_fifo_full_i(ssd_command_fifo_full),		
		.ssd_cmd_fifo_en_o(checkcache_ssd_command_fifo_in_en),
		.ssd_cmd_fifo_in_o(checkcache_ssd_command_fifo_in),	
		//finish_command_fifo8
		.finish_cmd_fifo8_full_i(finish_command_fifo_full[8]),
		.finish_cmd_fifo8_in_o(finish_command_fifo8_in),
		.finish_cmd_fifo8_en_o(finish_command_fifo8_in_en),
		//debug
		//.state(state_cache),
		//.step(cache_step),
		.dram_backup_en(dram_backup_en)
	);		

	
	ssd_command_fifo ssd_command_fifo_instance (//depth 1024
	  .clk(clk), // input clk
	  .rst(reset), // input rst
	  .din(ssd_command_fifo_in), // input [127 : 0] din
	  .wr_en(ssd_command_fifo_in_en), // input wr_en
	  .rd_en(ssd_command_fifo_out_en), // input rd_en
	  .dout(ssd_command_fifo_out), // output [127: 0] dout
	  .full(ssd_command_fifo_full), // output full
	  .empty(ssd_command_fifo_empty_or_not), // output empty
	  .data_count() // output [6 : 0] data_count 
	);
	
	controller_command_fifo finish_command_fifo8 (//write_depth 128
	  .clk(clk), // input clk
	  .rst(reset), // input rst
	  .din(finish_command_fifo8_in), // input [127 : 0] din
	  .wr_en(finish_command_fifo8_in_en), // input wr_en
	  .rd_en(finish_command_fifo_out_en[8]), // input rd_en
	  .dout(finish_command_fifo_out[8]), // output [127 : 0] dout
	  .full(finish_command_fifo_full[8]), // output full
	  .empty(finish_command_fifo_empty_or_not[8]), // output empty
	  .data_count() // output [4 : 0] data_count
	);
	
/*	GC gc_instance(
		.clk(clk),
		.reset(!reset),
		.left_capacity(left_capacity),    //need input
		.data_from_dram(data_from_dram),
		.dram_ready(dram_ready),	
		.rd_data_valid(rd_data_valid),
		.dram_permit(gc_dram_permit),
		.gc_command_fifo_prog_full(gc_command_fifo_prog_full),	
		
		.dram_en(gc_dram_en),
		.dram_read_or_write(gc_dram_read_or_write),
		.addr_to_dram(gc_addr_to_dram),
		.data_to_dram(gc_data_to_dram),
		.dram_data_mask(gc_dram_data_mask),
		.data_to_dram_en(gc_data_to_dram_en),
		.data_to_dram_end(gc_data_to_dram_end),
		.data_to_dram_ready(data_to_dram_ready),
		.release_dram(gc_release_dram),
		.dram_request(gc_dram_request),
		.gc_command_fifo_in(gc_command_fifo_in),
		.gc_command_fifo_in_en(gc_command_fifo_in_en)
		//.state(state_gc)
	);*/		
	
/*	gc_command_fifo gc_command_fifo_instance (//fifo depth 1024
	  .clk(clk), // input clk
	  .rst(reset), // input rst
	  .din(gc_command_fifo_in), // input [28 : 0] din
	  .wr_en(gc_command_fifo_in_en), // input wr_en
	  .rd_en(gc_command_fifo_out_en), // input rd_en
	  .dout(gc_command_fifo_out), // output [28 : 0] dout
	  .full(), // output full
	  .empty(gc_command_fifo_empty_or_not), // output empty
	  .data_count(), // output [10 : 0] data_count  
	  .prog_full(gc_command_fifo_prog_full) // output prog_full
	);*/
	
	io_schedule io_schedule_instance(
		.reset(!reset),
		.clk(clk),
		.ssd_command_fifo_empty_or_not(ssd_command_fifo_empty_or_not),
		.ssd_command_fifo_out(ssd_command_fifo_out),
		.dram_permit(io_dram_permit),
		.data_from_dram(data_from_dram),
		.dram_ready(dram_ready),	
		.rd_data_valid(rd_data_valid),
		.gc_command_fifo_out(gc_command_fifo_out),
		.gc_command_fifo_empty_or_not(1),		
		//.write_data_fifo0_prog_full(!Cmd_Available[0]),
		//.command_fifo0_full(!Cmd_Available[0]),
		//.write_data_fifo1_prog_full(!Cmd_Available[1]),
		//.command_fifo1_full(!Cmd_Available[1]),
		//.write_data_fifo2_prog_full(!Cmd_Available[2]),
		//.command_fifo2_full(!Cmd_Available[2]),
		//.write_data_fifo3_prog_full(!Cmd_Available[3]),
		//.command_fifo3_full(!Cmd_Available[3]),
		//.write_data_fifo4_prog_full(!Cmd_Available[4]),
		//.command_fifo4_full(!Cmd_Available[4]),
		//.write_data_fifo5_prog_full(!Cmd_Available[5]),
		//.command_fifo5_full(!Cmd_Available[5]),
		//.write_data_fifo6_prog_full(!Cmd_Available[6]),
		//.command_fifo6_full(!Cmd_Available[6]),
		//.write_data_fifo7_prog_full(!Cmd_Available[7]),
		//.command_fifo7_full(!Cmd_Available[7]),
		.command_available(Cmd_Available),

		.ssd_command_fifo_out_en(ssd_command_fifo_out_en),
		.controller_command_fifo_in(io_controller_command_fifo_in),
		.controller_command_fifo_in_en(io_controller_command_fifo_in_en),
		.write_data_fifo_in(io_write_data_fifo_in),
		.write_data_fifo_in_en(io_write_data_fifo_in_en),
		.dram_request(io_dram_request),
		.release_dram(io_release_dram),
		.addr_to_dram(io_addr_to_dram),
		.data_to_dram(io_data_to_dram),
		.dram_data_mask(io_dram_data_mask),
		.dram_en(io_dram_en),
		.dram_read_or_write(io_dram_read_or_write),
		.data_to_dram_en(io_data_to_dram_en),
		.data_to_dram_end(io_data_to_dram_end),
		.data_to_dram_ready(data_to_dram_ready),
		.gc_command_fifo_out_en(gc_command_fifo_out_en),
		.flash_left_capacity(left_capacity_io),
		.free_block_fifo_heads(free_block_fifo_heads_io),
		.free_block_fifo_tails(free_block_fifo_tails_io),
		.register_ready(register_ready),
		.state(state_io)
		//.state_addr(state_addr)
	);
	//channel 0
	Dynamic_Controller flash_controller_instance0 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		 //Ports with Host
		.Cmd_In_En(controller_command_fifo_in_en[0]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[0]), 
		.Data_In_En(write_data_fifo_in_en[0]), 
		.Data_In(write_data_fifo_in), 
		.Cmd_Available(Cmd_Available[0]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[0]), 
		.Finished_Cmd_Out(finish_command_fifo_out[0]),
		.ControllerIdle(idle_flag[0]),
		.Data_2_host_en(read_data_fifo_out_en[0]),
		.Data_2_host(read_data_fifo_out[0]),
		//.Data_Out_En(read_data_fifo_out_en[0]), 
		//.Data_Out(read_data_fifo_out[0]), 
	//	.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
	//	.Post_Data_Valid(), //use for check
	   //Ports with Chips
		.Cle(nand0Cle), 
		.Ale(nand0Ale), 
		.Clk_We_n(nand0Clk_We_n), 
		.Wr_Re_n(nand0Wr_Re_n), 
		.Wp_n(nand0Wp_n), 
		.Ce_n(nand0Ce_n), 
		.Rb_n(nand0Rb_n), 
		.DQX(nand0DQX), 
		.DQS(nand0DQS)
	);
	
	//channel 1
	Dynamic_Controller flash_controller_instance1 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[1]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[1]), 
		.Data_In_En(write_data_fifo_in_en[1]), 
		.Data_In(write_data_fifo_in), 
		
		.Cmd_Available(Cmd_Available[1]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[1]), 
		.Finished_Cmd_Out(finish_command_fifo_out[1]), 
		.ControllerIdle(idle_flag[1]),
		.Data_2_host_en(read_data_fifo_out_en[1]), 
		.Data_2_host(read_data_fifo_out[1]), 
		//.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand1Cle), 
		.Ale(nand1Ale), 
		.Clk_We_n(nand1Clk_We_n), 
		.Wr_Re_n(nand1Wr_Re_n), 
		.Wp_n(nand1Wp_n), 
		.Ce_n(nand1Ce_n), 
		.Rb_n(nand1Rb_n), 
		.DQX(nand1DQX), 
		.DQS(nand1DQS)
	);
	
	//channel 2
	Dynamic_Controller flash_controller_instance2 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[2]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[2]), 
		.Data_In_En(write_data_fifo_in_en[2]), 
		.Data_In(write_data_fifo_in), 
		
		.Cmd_Available(Cmd_Available[2]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[2]), 
		.Finished_Cmd_Out(finish_command_fifo_out[2]), 
		.ControllerIdle(idle_flag[2]),
		.Data_2_host_en(read_data_fifo_out_en[2]), 
		.Data_2_host(read_data_fifo_out[2]), 
		//.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand2Cle), 
		.Ale(nand2Ale), 
		.Clk_We_n(nand2Clk_We_n), 
		.Wr_Re_n(nand2Wr_Re_n), 
		.Wp_n(nand2Wp_n), 
		.Ce_n(nand2Ce_n), 
		.Rb_n(nand2Rb_n), 
		.DQX(nand2DQX), 
		.DQS(nand2DQS)
	);
	
	//channel 3
	Dynamic_Controller flash_controller_instance3 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[3]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[3]), 
		.Data_In_En(write_data_fifo_in_en[3]), 
		.Data_In(write_data_fifo_in), 
		.ControllerIdle(idle_flag[3]),
		.Cmd_Available(Cmd_Available[3]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[3]), 
		.Finished_Cmd_Out(finish_command_fifo_out[3]), 
		.Data_2_host_en(read_data_fifo_out_en[3]), 
		.Data_2_host(read_data_fifo_out[3]), 
		//.Post_Data_Empty(), //use for check
	//	.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand3Cle), 
		.Ale(nand3Ale), 
		.Clk_We_n(nand3Clk_We_n), 
		.Wr_Re_n(nand3Wr_Re_n), 
		.Wp_n(nand3Wp_n), 
		.Ce_n(nand3Ce_n), 
		.Rb_n(nand3Rb_n), 
		.DQX(nand3DQX), 
		.DQS(nand3DQS)
	);
	
	//channel 4
	Dynamic_Controller flash_controller_instance4 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[4]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[4]), 
		.Data_In_En(write_data_fifo_in_en[4]), 
		.Data_In(write_data_fifo_in), 
		.ControllerIdle(idle_flag[4]),
		.Cmd_Available(Cmd_Available[4]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[4]), 
		.Finished_Cmd_Out(finish_command_fifo_out[4]), 
		.Data_2_host_en(read_data_fifo_out_en[4]), 
		.Data_2_host(read_data_fifo_out[4]), 
		//.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand4Cle), 
		.Ale(nand4Ale), 
		.Clk_We_n(nand4Clk_We_n), 
		.Wr_Re_n(nand4Wr_Re_n), 
		.Wp_n(nand4Wp_n), 
		.Ce_n(nand4Ce_n), 
		.Rb_n(nand4Rb_n), 
		.DQX(nand4DQX), 
		.DQS(nand4DQS)
	);
	
	//channel 5
	Dynamic_Controller flash_controller_instance5 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[5]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[5]), 
		.Data_In_En(write_data_fifo_in_en[5]), 
		.Data_In(write_data_fifo_in), 
		.ControllerIdle(idle_flag[5]),
		.Cmd_Available(Cmd_Available[5]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[5]), 
		.Finished_Cmd_Out(finish_command_fifo_out[5]), 
		.Data_2_host_en(read_data_fifo_out_en[5]), 
		.Data_2_host(read_data_fifo_out[5]), 
		//.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand5Cle), 
		.Ale(nand5Ale), 
		.Clk_We_n(nand5Clk_We_n), 
		.Wr_Re_n(nand5Wr_Re_n), 
		.Wp_n(nand5Wp_n), 
		.Ce_n(nand5Ce_n), 
		.Rb_n(nand5Rb_n), 
		.DQX(nand5DQX), 
		.DQS(nand5DQS)
	);
	
	//channel 6
	Dynamic_Controller flash_controller_instance6 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[6]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[6]), 
		.Data_In_En(write_data_fifo_in_en[6]), 
		.Data_In(write_data_fifo_in), 
		.ControllerIdle(idle_flag[6]),
		.Cmd_Available(Cmd_Available[6]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[6]), 
		.Finished_Cmd_Out(finish_command_fifo_out[6]), 
		.Data_2_host_en(read_data_fifo_out_en[6]), 
		.Data_2_host(read_data_fifo_out[6]), 
		//.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand6Cle), 
		.Ale(nand6Ale), 
		.Clk_We_n(nand6Clk_We_n), 
		.Wr_Re_n(nand6Wr_Re_n), 
		.Wp_n(nand6Wp_n), 
		.Ce_n(nand6Ce_n), 
		.Rb_n(nand6Rb_n), 
		.DQX(nand6DQX), 
		.DQS(nand6DQS)
	);
	
	//channel 7
	Dynamic_Controller flash_controller_instance7 (
		.clk_200M(clk), //??????????czg
		.rst_n(!reset), //????????????czg
		.clk_83X2M(clk_83X2M), //????????czg
		.clk_83M(clk_83M),
		.clk_83M_reverse(clk_83M_reverse),
		.Cmd_In_En(controller_command_fifo_in_en[7]), 
		.Cmd_In(controller_command_fifo_in), 
		.Finished_Cmd_Out_En(finish_command_fifo_out_en[7]), 
		.Data_In_En(write_data_fifo_in_en[7]), 
		.Data_In(write_data_fifo_in), 
		.ControllerIdle(idle_flag[7]),
		.Cmd_Available(Cmd_Available[7]), //czg??????
		.Finished_Cmd_FIFO_Empty(finish_command_fifo_empty_or_not[7]), 
		.Finished_Cmd_Out(finish_command_fifo_out[7]), 
		.Data_2_host_en(read_data_fifo_out_en[7]), 
		.Data_2_host(read_data_fifo_out[7]), 
		//.Post_Data_Empty(), //use for check
		//.Post_Data_Full(), //use for check
		//.Post_Data_Valid(), //use for check
		.Cle(nand7Cle), 
		.Ale(nand7Ale), 
		.Clk_We_n(nand7Clk_We_n), 
		.Wr_Re_n(nand7Wr_Re_n), 
		.Wp_n(nand7Wp_n), 
		.Ce_n(nand7Ce_n), 
		.Rb_n(nand7Rb_n), 
		.DQX(nand7DQX), 
		.DQS(nand7DQS)
	);
	
	check_command_fifo check_command_fifo_instance(	
		//input
		.reset(!reset),
		.clk(clk),
		//.init_dram_done(init_dram_done),
		.all_controller_command_fifo_empty(all_idle_flag),
		.finish_command_fifo0_empty_or_not(finish_command_fifo_empty_or_not[0]),
		.finish_command_fifo1_empty_or_not(finish_command_fifo_empty_or_not[1]),	
		.finish_command_fifo2_empty_or_not(finish_command_fifo_empty_or_not[2]),	
		.finish_command_fifo3_empty_or_not(finish_command_fifo_empty_or_not[3]),
		.finish_command_fifo4_empty_or_not(finish_command_fifo_empty_or_not[4]),	
		.finish_command_fifo5_empty_or_not(finish_command_fifo_empty_or_not[5]),
		.finish_command_fifo6_empty_or_not(finish_command_fifo_empty_or_not[6]),	
		.finish_command_fifo7_empty_or_not(finish_command_fifo_empty_or_not[7]),
		.finish_command_fifo8_empty_or_not(finish_command_fifo_empty_or_not[8]),
		.finish_command_fifo0_out(finish_command_fifo_out[0]),
		.finish_command_fifo1_out(finish_command_fifo_out[1]),	
		.finish_command_fifo2_out(finish_command_fifo_out[2]),	
		.finish_command_fifo3_out(finish_command_fifo_out[3]),
		.finish_command_fifo4_out(finish_command_fifo_out[4]),	
		.finish_command_fifo5_out(finish_command_fifo_out[5]),
		.finish_command_fifo6_out(finish_command_fifo_out[6]),	
		.finish_command_fifo7_out(finish_command_fifo_out[7]),
		.finish_command_fifo8_out(finish_command_fifo_out[8]),
		.read_data_fifo0_out(read_data_fifo_out[0]),
		.read_data_fifo1_out(read_data_fifo_out[1]),
		.read_data_fifo2_out(read_data_fifo_out[2]),
		.read_data_fifo3_out(read_data_fifo_out[3]),
		.read_data_fifo4_out(read_data_fifo_out[4]),
		.read_data_fifo5_out(read_data_fifo_out[5]),
		.read_data_fifo6_out(read_data_fifo_out[6]),
		.read_data_fifo7_out(read_data_fifo_out[7]),
		.data_from_dram(data_from_dram),
		.dram_ready(dram_ready),	
		.rd_data_valid(rd_data_valid),
		.dram_permit(check_dram_permit),
		.pcie_data_send_fifo_out_prog_full(pcie_data_send_fifo_out_prog_full),
		.pcie_command_send_fifo_full_or_not(pcie_command_send_fifo_full_or_not),
		//output
		.finish_command_fifo0_out_en(finish_command_fifo_out_en[0]),
		.finish_command_fifo1_out_en(finish_command_fifo_out_en[1]),	
		.finish_command_fifo2_out_en(finish_command_fifo_out_en[2]),	
		.finish_command_fifo3_out_en(finish_command_fifo_out_en[3]),
		.finish_command_fifo4_out_en(finish_command_fifo_out_en[4]),	
		.finish_command_fifo5_out_en(finish_command_fifo_out_en[5]),
		.finish_command_fifo6_out_en(finish_command_fifo_out_en[6]),	
		.finish_command_fifo7_out_en(finish_command_fifo_out_en[7]),
		.finish_command_fifo8_out_en(finish_command_fifo_out_en[8]),
		.read_data_fifo0_out_en(read_data_fifo_out_en[0]),
		.read_data_fifo1_out_en(read_data_fifo_out_en[1]),
		.read_data_fifo2_out_en(read_data_fifo_out_en[2]),
		.read_data_fifo3_out_en(read_data_fifo_out_en[3]),
		.read_data_fifo4_out_en(read_data_fifo_out_en[4]),
		.read_data_fifo5_out_en(read_data_fifo_out_en[5]),
		.read_data_fifo6_out_en(read_data_fifo_out_en[6]),
		.read_data_fifo7_out_en(read_data_fifo_out_en[7]),
		.dram_request(check_dram_request),
		.release_dram(check_release_dram),
		.addr_to_dram_o(check_addr_to_dram),
		.data_to_dram(check_data_to_dram),
		.dram_data_mask(check_dram_data_mask), 
		.dram_en_o(check_dram_en),
		.dram_read_or_write(check_dram_read_or_write),
		.data_to_dram_en(check_data_to_dram_en),
		.data_to_dram_end(check_data_to_dram_end),
		.data_to_dram_ready(data_to_dram_ready),	
		
		.pcie_data_send_fifo_in(pcie_data_send_fifo_in),
		.pcie_data_send_fifo_in_en(pcie_data_send_fifo_in_en),
		.pcie_command_send_fifo_in(pcie_command_send_fifo_in),
		.pcie_command_send_fifo_in_en(pcie_command_send_fifo_in_en),
		.left_capacity_final(left_capacity_initial),//512GB flash��9次方个块
		.free_block_fifo_tails(free_block_fifo_tails_initial),
		.free_block_fifo_heads(free_block_fifo_heads_initial),
		.register_ready(register_ready),
		.initial_dram_done(initial_dram_done),
		.state(state_check) 
	);
	backup backup_instance(
		.reset(!reset),
		.clk(clk),	
		.dram_backup_en(1'b0),	
		.backup_op(),
		.fifo_enpty_flag(!all_idle_flag),
		.state_check(state_check),
		.dram_permit(backup_dram_permit),
		.data_from_dram(data_from_dram),
		.dram_ready(dram_ready),	
		.rd_data_valid(rd_data_valid),	
		.left_capacity_final(left_capacity),
		.free_block_fifo_heads(free_block_fifo_heads),
		.free_block_fifo_tails(free_block_fifo_tails),	
		.ssd_command_fifo_full(ssd_command_fifo_full),
		.controller_command_fifo_full_or_not(!all_Cmd_Available_flag),
		.write_data_fifo_prog_full(!all_Cmd_Available_flag),//8 bit
		.write_data_fifo_full(!all_Cmd_Available_flag),
		
		.dram_request(backup_dram_request),
		.release_dram(backup_release_dram),
		.addr_to_dram(backup_addr_to_dram),
		.data_to_dram(backup_data_to_dram),
		.dram_data_mask(backup_dram_data_mask),
		.dram_en(backup_dram_en),
		.dram_read_or_write(backup_dram_read_or_write),
		
		.ssd_command_fifo_in(backup_ssd_command_fifo_in),
		.ssd_command_fifo_in_en(backup_ssd_command_fifo_in_en),
		.controller_command_fifo_in_en(backup_controller_command_fifo_in_en),
		.controller_command_fifo_in(backup_controller_command_fifo_in),
		.write_data_fifo_in(backup_write_data_fifo_in),
		.write_data_fifo_in_en(backup_write_data_fifo_in_en),//8 bit
		.backup_or_checkcache(backup_or_checkcache),
		.backup_or_io(backup_or_io)
	);	

endmodule
