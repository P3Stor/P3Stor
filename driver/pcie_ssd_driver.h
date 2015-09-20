
// Warning:This driver is Only valid for x86-32 system
//
#ifndef _PCIE_SSD_DRIVER_H
#define _PCIE_SSD_DRIVER_H

#include <linux/pci.h>
#include <linux/miscdevice.h>
#include <linux/kref.h>

#define PCI_VENDOR_ID_XILINX		0x10ee
#define PCI_DEVICE_ID_XILINX_PCIE	0x6028

// BAR0 SPACE
// 
#define		CAP					0
#define		VS					0x4
#define		CC					0x8
#define		RQDBL					0x18
#define		RQBADDR					0x1c
#define		RRESP					0x20
#define		STS					0x24
#define		RQDPH					0x28
#define		INTCNT					0x38
#define		REQCNT					0x3c

enum{
	PDISK_CC_ENABLE				= 1 << 0,
	PDISK_DEVICE_RDY			= 1 << 0,
	PDISK_INT_ENABLE			= 1 << 19,
	RESPONSE_VALID				= 1 << 31,
	REPONSE_ERR				= 1 << 30,
};

#define		PDISK_IO_TIMEOUT	(1 * HZ)
#define		PDISK_DEVICE_TIMEOUT	(200 * HZ)

#define SUCCESS 0
//#define CANCEL_DEBUG
//#define DEBUG
// Defined Command Structure Between HOST and Device 
//
struct pdisk_command{
	//u8	opcode;
	//u8	flag;
	u16	cmd_id;
	u8	flag;
	u8	opcode;
	u32	LBA;
	u32	length;
	u32	rsv[5];
	u32	prp[24];
};

// Represents an NVM Express device.  Each PD_Device_Extention is a PCI function.
//
struct PD_Device_Extention{
	struct list_head	node;
	struct pdisk_queue	*pqueue;

        struct pdisk_queue  **pqueues;       // the pdisk queues
        int    queue_count;                  // number of the queues
        u32    __iomem      *dbs;             // the doorbells of the queues
        u32    __iomem      *resps;           // response doorbell of the command
        struct msix_entry   *entry;          // msi-x interrupt entries   

	struct pdisk_bar __iomem *bar;
	struct pci_dev *pci_dev;
	u32 ctrl_config;
	char name[12];
	int instance;
	u32 capacity;
	struct kref	kref;
	struct miscdevice miscdevice;
	struct pdisk_ns *pns;
// for debug
	int req_cnt;
};

// Command Queue Structure for Device
//
struct pdisk_queue{
	struct device	*q_dmadev;
	struct PD_Device_Extention *pdde;
	spinlock_t	q_lock;
	struct pdisk_command *pcommands;      // command submission queue
	dma_addr_t	q_dma_addr;               // command submission queue dma address
	wait_queue_head_t q_full;
	wait_queue_t q_cong_wait;
	struct bio_list q_cong;               // bio list 

	u32 __iomem *q_db;                    // the doorbell of the submission queue
	u32 __iomem *q_resp;                  // the doorbell of the completion queue

        u32 __iomem *sq_reg;
        u32 __iomem *cq_reg;

        u32 __iomem *cqes;                    // completion queue
        dma_addr_t  cq_dma_addr;              // completion queue dma address
    
        u32 cq_vector;                        // interrupt vector
	u32 qid;

	u16	q_depth;                          // depth of the queue
	u16	head;
	u16	tail;
	u8	q_suspended;
	unsigned long cmdid_data[];	
};

// Request Description
//
struct pdisk_iod{
	void *private;
	int nents;
	int length;
	unsigned long start_time;
	struct scatterlist sg[0];
};


// Namespace
//
struct pdisk_ns{
	struct PD_Device_Extention *pdde;
	struct request_queue *queue;
	struct gendisk *disk;
};

// Host and Device Interface : Bar0
//
struct pdisk_bar{
	u32	cap;
	u32	vs;
	u32	cc;     // controller configuration
	u32	rsv1;
	u32 rsv2;
	u32 rsv3;
	u32	rqdbl;   // doorbell         To be modified   
	u32 rqbaddr; // command addr     To be modified
	u32 rresp;
	u32 sts;    // controller status 
	u32 rqdph;  // queue depth       To be modified
	u32 rsv4;
	u32 rsv5;
	u32 rsv6;
	u32 intcnt;
	u32 reqcnt;
};

enum {
	pdisk_cmd_read			= 0x01,
	pdisk_cmd_write			= 0x02,
};



#endif
