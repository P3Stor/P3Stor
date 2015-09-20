//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:57:31 07/31/2014 
// Design Name: 
// Module Name:    Dynamic_Controller 
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
`define MLC;
`ifdef MLC
		parameter ADDR_WIDTH=24;
`elsif SLC
      parameter ADDR_WIDTH=23;
`else
      parameter ADDR_WIDTH=23;
`endif