/********** MLC ***********
	MT29F256G08CUCBBH3
Page Size: 4320 bytes (4096 + 224 bytes)
Block Size: 256 pages (1MB + 56K bytes)
Device Size: 32,768 blocks( 256Gb, 32GB )
page_addr_num per target = 13(block) + 8(page) = 21
***************************/
/*******Flash Board*******
Package Num: 16
Block Num : 16*32768=2^(4+15)=2^19
Page Num: 2^19*256 = 2^27
Channel Num: 8
**************************/	
	`include "./Dynamic_Controller/code/Dynamic_Controller_Parameters.vh"
	`ifdef MLC
		parameter ADDR_PER_TARGET    = 21; 
	`elsif SLC
		parameter ADDR_WIDTH_PER_TARGET    = 20;
	`else
		parameter ADDR_WIDTH_PER_TARGET    = 21;
	`endif
	
	parameter TARGET_ADDR_WIDTH      = 3; // 8 targets per Channel
	parameter CHANNEL_ADDR_WIDTH     = 3; // 8 Channels
	parameter PHYSICAL_ADDR_WIDTH    = ADDR_PER_TARGET + TARGET_ADDR_WIDTH + CHANNEL_ADDR_WIDTH;
									// 21 + 3 + 3 = 27//
	
	parameter MIN_REQUEST_SIZE          = 4096; //支持的最小的请求大小为4KB(4096B)。        
	parameter PAGE_SIZE                 = 4096; //
    parameter DRAM_COUNT                = MIN_REQUEST_SIZE/64; //(512b==64B)
    parameter FLASH_COUNT               = MIN_REQUEST_SIZE/1;		
	
	parameter DRAM_IO_WIDTH   		= 256; //DRAM IO
//	parameter PHYSICAL_ADDR_WIDTH   = 27;  //flash capacity 4KB*2^27 = 2^39B = 512GB 
	parameter FLASH_IO_WIDTH		= 8;  // 8*4
	parameter DRAM_ADDR_WIDTH 		= 29;  //DRAM cacacity  64bits(2^3B)*2^29=2^32B = 4GB
	parameter DRAM_MASK_WIDTH 		= 32;  //8bits/mask bit  256/8 = 32
	parameter COMMAND_WIDTH 		= 128; //
	parameter GC_COMMAND_WIDTH 	= 29;  //
    parameter CACHE_ADDR_WIDTH 	= 19;  //cache space 4KB*2^19=2^31B=2GB
	
	// DRAM Capacity 4GB, addr width 29 bits, 8B(64bits)/addr
	// Cache Capacity 2GB, page size 4K, Cache entery num 512K=2^19
    parameter L2P_TABLE_BASE			= 29'b0_0000_00000000_00000000_00000000; //32bits*2^27=2^26*8B=512MB
	parameter P2L_TABLE_BASE			= 29'b0_0100_00000000_00000000_00000000; //32bits*2^27=2^26*8B=512MB // L2P table x4
	parameter FREE_BLOCK_FIFO_BASE		= 29'b0_1000_00000000_00000000_00000000; //32bits*2^19=2^18*8B=2MB
	parameter GARBAGE_TABLE_BASE		= 29'b0_1000_00000100_00000000_00000000; //32bits*2^19=2^18*8B=2MB
	parameter BAD_BLOCK_INFO_BASE       = 29'b0_1000_00001000_00000000_00000000; //4KB*2*8=64KB=2^13*8B=2^16B
	parameter BAD_BLOCK_INFO_BASE_END   = 29'b0_1000_00001000_00100000_00000000;
	
    parameter CACHE_ENTRY_BASE		    = 29'b0_1000_00010000_00000000_00000000; //32bits*2^19=2^18*8B=2MB
    parameter ADDITIONAL_CACHE_FIFO_BASE= 29'b0_1000_00010100_00000000_00000000; //additional_cache容量，4KB*2^8=2^17*8B=1MB 
	parameter CACHE_BASE			    = 29'b1_0000_00000000_00000000_00000000; //last 2GB space
	
	parameter L2P_TABLE_BASE_FLASH		= 22'b11_1111_00000000_00000000;		//512MB/4KB/8(# of channel)=16K=2^14
	parameter P2L_TABLE_BASE_FLASH		= 22'b11_1111_01000000_00000000; 	
	parameter FREE_BLOCK_FIFO_BASE_FLASH= 22'b11_1111_10000000_00000000; 	//2MB/4KB/8=64, 64pages/channel,512pages total
	parameter GARBAGE_TABLE_BASE_FLASH	= 22'b11_1111_10000000_01000000;
	parameter REGISTER_BASE_FLASH		= 22'b11_1111_10000000_10000000;
	parameter BADBLOCK_FLASH_ADDR1		= 24'b1_1111_11111111_00000000_000;	// first targert first two pages per channel, Bad block info stored by Channel. 
	parameter BADBLOCK_FLASH_ADDR2		= 24'b1_1111_11111111_00000001_000;	// first targert first two pages per channel, Bad block info stored by Channel. 
	
	parameter READ		    = 2'b00;
	parameter WRITE			= 2'b01;
	parameter MOVE		    = 2'b10;
	parameter ERASE			= 2'b11;