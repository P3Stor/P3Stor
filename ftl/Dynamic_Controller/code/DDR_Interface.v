`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:13:06 10/01/2014 
// Design Name: 
// Module Name:    DDR_Interface 
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
  module DDR_Interface ( input clk,
			                input fifo_rd_clk,//83M
							input clk_83M_reverse,
                         input rst_n,
								 input during_read_data,
								 //DDR data into fpga
								 input clear_fifo,//active high
								 input rd_en,
								 output [15:0] data_into_fpga,
								 output empty,
								 //DDR data out of fpga
								 input [7:0] data_outof_fpga,
								 input DQS_Start,
								 //pins
								 inout DQS,
								 inout [7:0] DQX
			 
			 );

   wire DQS_Out;

   wire rst;// active high	  
	wire DQS_In_BUFIO;
    wire DQS_from_IODELAYE1_InBuf;
	// IDDR  
	wire [7:0] Data_to_fpga_rising;
	wire [7:0] Data_to_fpga_falling;
	
	//IODELAYE1
	wire DQS_from_IODELAYE1;
	//IOBUF
  // wire T;
   wire DQS_In;
	wire [7:0] DQX_In;
	
	//FIFO ddr data in
	wire rst_fifo;
	wire [15:0] read_data_in;
   reg wr_en;
	
	//delay regs
	reg [15:0] delay_clk1;
	reg [15:0] delay_clk2;
	//reg [15:0] 
	
	//assign DQX=(during_read_data == 1'b0)?DQX_Out:'hzz;
	assign rst=~rst_n;
  // assign T=during_read_data;// T=0, output T=1, input.		
   assign read_data_in={Data_to_fpga_falling,Data_to_fpga_rising};
	assign rst_fifo=rst|clear_fifo;
	
// BUFR: Regional Clock Buffer /w Enable, Clear and Division Capabilities
// Virtex-4/5, Virtex-6
// Xilinx HDL Libraries Guide, version 11.2
BUFR #(
.BUFR_DIVIDE("BYPASS"), // "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8"
.SIM_DEVICE("VIRTEX6") // Specify target device, "VIRTEX4", "VIRTEX5", "VIRTEX6"
) BUFR_inst0 (
.O(DQS_from_IODELAYE1), // Clock buffer output
.CE(1'b1), // Clock enable input
.CLR(1'b0), // Clock buffer reset input
.I(DQS_from_IODELAYE1_InBuf) // Clock buffer input
);

BUFR #(
.BUFR_DIVIDE("1"), // "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8"
.SIM_DEVICE("VIRTEX6") // Specify target device, "VIRTEX4", "VIRTEX5", "VIRTEX6"
) BUFR_inst1 (
.O(DQS_Out), // Clock buffer output
.CE(DQS_Start), // Clock enable input
.CLR(1'b0), // Clock buffer reset input
.I(clk_83M_reverse) // Clock buffer input
);
// End of BUFR_inst instantiation
// BUFIO: Local Clock Buffer
// Virtex-4/5/6
// Xilinx HDL Libraries Guide, version 11.2
/*
BUFIO BUFIO_inst (
.O(DQS_BUFIO), // Clock buffer output
.I(DQS_from_IODELAYE1_InBuf) // Clock buffer input
);
*/
// End of BUFIO_inst instantiatio
/********Instantiate the IOBUF primitive**********/
// IOBUF: Single-ended Bi-directional Buffer
// All devices
// Xilinx HDL Libraries Guide, version 12.4

////////////////////INOUT DQS ////////////////////////////////////

		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQS (
		.O(DQS_In), // Buffer output
		.IO(DQS), // Buffer inout port (connect directly to top-level port)
		.I(DQS_from_IODELAYE1_InBuf), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);
   //assign DQX=(during_read_data==0)? data_outof_fpga:8'hzz;
		////////////////////INOUT DQX ////////////////////////////////////

		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX0 (
		.O(DQX_In[0]), // Buffer output
		.IO(DQX[0]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[0]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);
		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX1 (
		.O(DQX_In[1]), // Buffer output
		.IO(DQX[1]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[1]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);
		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX2 (
		.O(DQX_In[2]), // Buffer output
		.IO(DQX[2]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[2]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);

		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX3 (
		.O(DQX_In[3]), // Buffer output
		.IO(DQX[3]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[3]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);

		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX4 (
		.O(DQX_In[4]), // Buffer output
		.IO(DQX[4]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[4]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);

		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX5 (
		.O(DQX_In[5]), // Buffer output
		.IO(DQX[5]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[5]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);
		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX6 (
		.O(DQX_In[6]), // Buffer output
		.IO(DQX[6]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[6]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);
		IOBUF #(
		.DRIVE(12), // Specify the output drive strength
		.IOSTANDARD("DEFAULT"), // Specify the I/O standard
		.SLEW("SLOW") // Specify the output slew rate
		) IOBUF_instDQX7 (
		.O(DQX_In[7]), // Buffer output
		.IO(DQX[7]), // Buffer inout port (connect directly to top-level port)
		.I(data_outof_fpga[7]), // Buffer input
		.T(during_read_data) // 3-state enable input, high=input, low=output
		);
// End of IOBUF_inst instantiation
	
	
/***************Instantiate the IDELAYCTRL primitive ***********/
// IDELAYCTRL: IDELAY Tap Delay Value Control
// Virtex-6
// Xilinx HDL Libraries Guide, version 12.4
 /*
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IDELAYCTRL IDELAYCTRL_inst (
	.RDY(), // 1-bit Indicates the validity of the reference clock input, REFCLK. When REFCLK
	// disappears (i.e., REFCLK is held High or Low for one clock period or more), the RDY
	// signal is deasserted.
	.REFCLK(clk), // 1-bit Provides a voltage bias, independent of process, voltage, and temperature
	// variations, to the tap-delay lines in the IOBs. The frequency of REFCLK must be 200
	// MHz to guarantee the tap-delay value specified in the applicable data sheet.
	.RST(rst) // 1-bit Resets the IDELAYCTRL circuitry. The RST signal is an active-high asynchronous
	// reset. To reset the IDELAYCTRL, assert it High for at least 50 ns.
	);
// End of IDELAYCTRL_inst instantiation
*/


/*************Instantiate the IODELAYE1 primitive**************/
// The specified function here: to shift the bidirectional signal DQS(source synchronous interface signal,with NAND Flash outside).
// We need delay the DQS for 3 ns( about 19 taps as for a 31-tap IODELAYE1 calibrated by refclk 200M IODELAYCTRL),
//   to make DQS and DQX center-aligned for both read and write.
// IODELAYE1: Input / Output Fixed or Variable Delay Element
// Virtex-6
// Xilinx HDL Libraries Guide, version 12.4

	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IODELAYE1 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IO"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("FIXED"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(17), // Input delay tap setting (0-32) 
	.ODELAY_TYPE("FIXED"), // "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.ODELAY_VALUE(15), // Output delay tap setting (0-32)
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("CLOCK") // "DATA" or "CLOCK" input signal
	)
	IODELAYE1_inst (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(DQS_from_IODELAYE1_InBuf), // 1-bit output - Delayed data output
	.C(), // 1-bit input - Clock input
	.CE(1'b0), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CLKIN(), // 1-bit input - Clock Access into the IODELAY
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(DQS_In), // 1-bit input - Delay data input
	.INC(), // 1-bit input - Increment / Decrement tap delay
	.ODATAIN(DQS_Out), // 1-bit input - Data input for the output datapath from the device
	.RST(), // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	// ODELAY_VALUE tap. If no value is specified, the default is 0.
	.T(during_read_data) // 1-bit input - 3-state input control. Tie high for input-only or internal delay or
	// tie low for output only.
	);
// End of IODELAYE1_inst instantiation

/********Instaniate the IDDR primitive ************************/
// IDDR: Input Double Data Rate Input Register with Set, Reset
// and Clock Enable.
// Virtex-6
// Xilinx HDL Libraries Guide, version 12.4
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst0 (
	.Q1(Data_to_fpga_rising[0]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[0]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[0]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst1 (
	.Q1(Data_to_fpga_rising[1]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[1]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[1]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst2 (
	.Q1(Data_to_fpga_rising[2]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[2]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[2]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst3 (
	.Q1(Data_to_fpga_rising[3]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[3]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[3]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst4 (
	.Q1(Data_to_fpga_rising[4]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[4]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[4]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst5 (
	.Q1(Data_to_fpga_rising[5]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[5]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[5]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst6 (
	.Q1(Data_to_fpga_rising[6]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[6]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[6]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);
	IDDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE","SAME_EDGE_PIPELINED"
	// or "SAME_EDGE_PIPELINED"
	.INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	.INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	.SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) IDDR_inst7 (
	.Q1(Data_to_fpga_rising[7]), // 1-bit output for positive edge of clock
	.Q2(Data_to_fpga_falling[7]), // 1-bit output for negative edge of clock
	.C(DQS_from_IODELAYE1), // 1-bit clock input
	.CE(during_read_data), // 1-bit clock enable input active high
	.D(DQX_In[7]), // 1-bit DDR data input
	.R(rst), // 1-bit reset initial q1 q2 0
	.S() // 1-bit set initial q1 q2 1(can be ignored).
	);

// End of IDDR_inst instantiation

 FIFO_DDR_DATA_IN ddr_data_in_fifo1(
                                    .rst(rst_fifo),  // input rst
                                    .wr_clk(DQS_from_IODELAYE1),// // input wr_clk, 83M From  IODELAYE1 output
                                    .rd_clk(fifo_rd_clk),// input rd_clk 166M
                                    .din(delay_clk2), // input [15 : 0] din
                                    .wr_en(wr_en),// input wr_en
                                    .rd_en(rd_en), // input rd_en
                                    .dout(data_into_fpga),// output [15 : 0] dout
                                    .full(),// output full
                                    .empty(empty) // output empty
                                    );

   										
always@(posedge DQS_from_IODELAYE1 or posedge rst_fifo)
begin
   if(rst_fifo)
	begin
       delay_clk1<=16'b0;
		 delay_clk2<=16'b0;
	end
   else
	begin
		 delay_clk1<=read_data_in;
		 delay_clk2<=delay_clk1;
   end
end		
always@(posedge DQS_from_IODELAYE1 or posedge rst_fifo)
begin
   if(rst_fifo)
       wr_en<=1'b0;
   else if(during_read_data)
		 wr_en<=1'b1;
   else
       wr_en<=1'b0;
end

/*
/////////////////////////////////test////////
reg [13:0] counter;
always@(posedge DQS_from_IODELAYE1 or posedge rst_fifo)
begin
   if(rst_fifo)
       counter<='b0;
   else 
     if(wr_en)
		   counter<=counter+1'b1;
		 else
		   counter<=counter;
end
*/
endmodule