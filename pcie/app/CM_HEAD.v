`define	PAGE_SIZE_ORDER			12
`define PAGE_SIZE				( 1 << `PAGE_SIZE_ORDER )
`define REQ_PRP_NUMS			24

`define DMA_CTRL_STA_REG		1
`define DMA_RD_SIZE_REG			4
`define DMA_WR_SIZE_REG			5
`define DMA_RD_ADDR_REG			6
`define DMA_RD_UPADDR_REG		8
`define DMA_WR_ADDR_REG			7
`define DMA_WR_UPADDR_REG		9

`define RD_REQ_BUF_TBSIZ_ORDER	4
`define	RD_REQ_BUF_TBSIZE		( 1 << `RD_REQ_BUF_TBSIZ_ORDER )

`define	REQUEST_SIZE_ORDER	7
`define	DEBUG	1