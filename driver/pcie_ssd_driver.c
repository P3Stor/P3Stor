/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
** Version
** Author:chenxiang
** Date:2014.5.28
** Description:
** 
** 
** 
** 
** 
** 
** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
** Warning:Our driver do not support neither 64bit OS nor the device 
** whose capacity extends 16TB.In order to support you own device,you
** must do some modification about the request queue setup and so on.
** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*/
#include <linux/init.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/fs.h>
#include <asm/uaccess.h>
#include <linux/types.h>
#include <linux/genhd.h>
#include <linux/blkdev.h>
#include <linux/bio.h>
#include <linux/errno.h>
#include <linux/kernel.h>
#include <linux/hdreg.h>  //struct hd_geometry
#include <linux/blkpg.h>
#include <linux/bitops.h>
#include <linux/delay.h>
#include <linux/idr.h>
#include <linux/io.h>
#include <linux/kdev_t.h>
#include <linux/kthread.h>
#include <linux/mm.h>
#include <linux/poison.h>
#include <linux/ptrace.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <scsi/sg.h>

#include "pcie_ssd_driver.h"

#define	PDISK_Q_DEPTH	1024
#define	Q_SIZE(depth)	(depth*sizeof(struct pdisk_command))

#define CQ_SIZE(depth)  ((depth)*sizeof(u32))
#define QUEUE_COUNT     8 
//#define RQDBS           0x108
#define RQDBS           0x4c
#define RRSPQS          0x44

#define	PDISK_MINORS	64

#define	HW_SECTOR_SIZE		4096
#define HW_SECTOR_ORDER		3
#define KERNEL_SECTOR_SIZE	512
#define MAX_HW_SECTOR_SIZE	192 		//192*512 bytes = 96K bytes = 24*4K bytes
#define PDISK_SECTORS		120*1024*1024


//#define CANCEL_DEBUG

MODULE_AUTHOR("CHENXIANG");
MODULE_DESCRIPTION("PCIE Flash Card Driver");
MODULE_LICENSE("GPL");

static int pdisk_major = 0;
module_param(pdisk_major,int,0);
static int queue_depth = PDISK_Q_DEPTH;
module_param(queue_depth,int,0);

static DEFINE_SPINLOCK(dev_list_lock);
static LIST_HEAD(dev_list);
static struct task_struct *pdisk_thread;

/* Special values must be less than 0x1000 */
#define CMD_CTX_BASE		((void *)POISON_POINTER_DELTA)
#define CMD_CTX_CANCELLED	(0x30C + CMD_CTX_BASE)
#define CMD_CTX_COMPLETED	(0x310 + CMD_CTX_BASE)
#define CMD_CTX_INVALID		(0x314 + CMD_CTX_BASE)

static void special_completion(struct PD_Device_Extention *pdde, void *ctx,
						u32 response)
{
	int cmdid = (u16)response;

	int i;

	if (ctx == CMD_CTX_CANCELLED)
		return;
	if (ctx == CMD_CTX_COMPLETED) {
		dev_warn(&pdde->pci_dev->dev,
				"completed id %d twice on queue\n",
				cmdid);
		return;
	}
	if (ctx == CMD_CTX_INVALID) {
		dev_warn(&pdde->pci_dev->dev,
				"invalid id %d completed on queue\n",
				cmdid);
		return;
	}

	dev_warn(&pdde->pci_dev->dev, "Unknown special completion %p\n", ctx);
}

static void bio_completion(struct PD_Device_Extention *pdde, void *ctx,
						u32 response)
{
	struct pdisk_iod *iod = ctx;
	struct bio *bio = iod->private;
	u16 status = response&REPONSE_ERR;

	if (iod->nents) {
		dma_unmap_sg(&pdde->pci_dev->dev, iod->sg, iod->nents,
			bio_data_dir(bio) ? DMA_TO_DEVICE : DMA_FROM_DEVICE);
	}
	kfree(iod);
	if (status)
		bio_endio(bio, -EIO);
	else
		bio_endio(bio, 0);
}

static DEFINE_IDA(pdisk_index_ida);

typedef void (*pdisk_completion_fn)(struct PD_Device_Extention *, void *,u32 );

// Used for Timeout Check and Completion Process
//
struct pdisk_cmd_info{
	pdisk_completion_fn fn;
	void *ctx;
	unsigned long timeout;

#ifdef CANCEL_DEBUG
	u32 LBA;
#endif

};

static int pdisk_get_ns_idx(void)
{
	int index, error;

	do {
		if (!ida_pre_get(&pdisk_index_ida, GFP_KERNEL))
			return -1;

		spin_lock(&dev_list_lock);
		error = ida_get_new(&pdisk_index_ida, &index);
		spin_unlock(&dev_list_lock);
	} while (error == -EAGAIN);

	if (error)
		index = -1;
	return index;
}

static void pdisk_put_ns_idx(int index)
{
	spin_lock(&dev_list_lock);
	ida_remove(&pdisk_index_ida, index);
	spin_unlock(&dev_list_lock);
}

static struct pdisk_cmd_info *pdisk_cmd_info(struct pdisk_queue *pqueue)
{
	return (void *)&pqueue->cmdid_data[BITS_TO_LONGS(pqueue->q_depth)];
}

static DEFINE_IDA(pdisk_instance_ida);

static int pdisk_set_instance(struct PD_Device_Extention *pdde)
{
	int instance, error;

	do {
		if (!ida_pre_get(&pdisk_instance_ida, GFP_KERNEL))
			return -ENODEV;

		spin_lock(&dev_list_lock);
		error = ida_get_new(&pdisk_instance_ida, &instance);
		spin_unlock(&dev_list_lock);
	} while (error == -EAGAIN);

	if (error)
		return -ENODEV;

	pdde->instance = instance;
	return 0;
}


/**
 * alloc_cmdid() - Allocate a Command ID
 * @pqueue: The queue that will be used for this command
 * @ctx: A pointer that will be passed to the handler
 * @handler: The function to call on completion
 *
 * Allocate a Command ID for a queue.  The data passed in will
 * be passed to the completion handler.  This is implemented by using
 * the bottom two bits of the ctx pointer to store the handler ID.
 * Passing in a pointer that's not 4-byte aligned will cause a BUG.
 * We can change this if it becomes a problem.
 *
 * May be called with local interrupts disabled and the q_lock held,
 * or with interrupts enabled and no locks held.
 */
static int alloc_cmdid(struct pdisk_queue *pqueue, void *ctx,
				pdisk_completion_fn handler, unsigned timeout)
{
	int depth = pqueue->q_depth - 1;
	struct pdisk_cmd_info *info = pdisk_cmd_info(pqueue);
	int cmdid;

	do {
		cmdid = find_first_zero_bit(pqueue->cmdid_data, depth);
		if (cmdid >= depth)
			return -EBUSY;
	} while (test_and_set_bit(cmdid, pqueue->cmdid_data));

	info[cmdid].fn = handler;
	info[cmdid].ctx = ctx;
	info[cmdid].timeout = jiffies + timeout;

	return cmdid;
}


/*
 * Called with local interrupts disabled and the q_lock held.  May not sleep.
 */
static void *free_cmdid(struct pdisk_queue *pqueue, int cmdid,
						pdisk_completion_fn *fn)
{
	void *ctx;
	struct pdisk_cmd_info *info = pdisk_cmd_info(pqueue);

	if (cmdid >= pqueue->q_depth) {
		*fn = special_completion;
		return CMD_CTX_INVALID;
	}
	if (fn)
		*fn = info[cmdid].fn;
	ctx = info[cmdid].ctx;
	info[cmdid].fn = special_completion;
	info[cmdid].ctx = CMD_CTX_COMPLETED;
	clear_bit(cmdid, pqueue->cmdid_data);
	wake_up(&pqueue->q_full);
	return ctx;
}

static void *cancel_cmdid(struct pdisk_queue *pqueue, int cmdid,
						pdisk_completion_fn *fn)
{
	void *ctx;
	struct pdisk_cmd_info *info = pdisk_cmd_info(pqueue);
	if (fn)
		*fn = info[cmdid].fn;
	ctx = info[cmdid].ctx;
	info[cmdid].fn = special_completion;
	info[cmdid].ctx = CMD_CTX_CANCELLED;
	return ctx;
}

static struct pdisk_iod * pdisk_alloc_iod(unsigned nseg, unsigned nbytes, gfp_t gfp)
{
	struct pdisk_iod *iod = kmalloc(sizeof(struct pdisk_iod) +
				sizeof(struct scatterlist) * nseg, gfp);

	if (iod) {
		iod->length = nbytes;
		iod->nents = 0;
		iod->start_time = jiffies;
	}

	return iod;
}


/**
 * nvme_cancel_ios - Cancel outstanding I/Os
 * @queue: The queue to cancel I/Os on
 * @timeout: True to only cancel I/Os which have timed out
 */
static void pdisk_cancel_ios(struct pdisk_queue *pqueue, bool timeout)
{
	int depth = pqueue->q_depth - 1;
	struct pdisk_cmd_info *info = pdisk_cmd_info(pqueue);
	unsigned long now = jiffies;
	int cmdid;

	int i;

	for_each_set_bit(cmdid, pqueue->cmdid_data, depth) {
		void *ctx;
		pdisk_completion_fn fn;
		u32 resp = cmdid | RESPONSE_VALID | REPONSE_ERR;

		if (timeout && !time_after(now, info[cmdid].timeout))
			continue;
		if (info[cmdid].ctx == CMD_CTX_CANCELLED)
			continue;

		if (timeout){
		#ifdef CANCEL_DEBUG
	
			writel(0x01, (u32 __iomem*)(((void*)pqueue->pdde->bar) + 0x104));
			
			printk(KERN_NOTICE "the cancelled pqueue is the %dth queue\n", pqueue->qid);	
			printk(KERN_NOTICE "the cancelled cmdid is 0x%d\n", cmdid);

			printk(KERN_NOTICE "the cancelled cmdid's LBA is 0x%x\n", info[cmdid].LBA);
	
			writel(0x0, (u32 __iomem*)(((void*)pqueue->pdde->bar) + 0x104));
			
                        /*printk(KERN_NOTICE "In the %d# queue: ", pqueue->qid);

			for (i = 0; i < PDISK_Q_DEPTH; i++){
                             
                            printk(KERN_NOTICE "the cqes %d is 0x%x\n", i, pqueue->cqes[i]);
			  
			}

                        printk(KERN_NOTICE "the %d# queue end\n", pqueue->qid);
			*/
			
		#endif
		}
		
		dev_warn(pqueue->q_dmadev, "Cancelling I/O %d\n", cmdid);
		ctx = cancel_cmdid(pqueue, cmdid, &fn);
		fn(pqueue->pdde, ctx, resp);
		
	}
}

// Return: Number of responses processed
static int pdisk_process_cq(struct pdisk_queue *pqueue)
{
	int cmdid;
	int cnt = 0;
	u32 cqe;

	u16 write_tail = 0;
        u16 tail = pqueue->tail;

	for(;;){
		void *ctx;
		pdisk_completion_fn fn;		
		
                //u32 cqe = pqueue->cqes[tail];
	        int intr_pos = pqueue->cqes[pqueue->q_depth];		
		
		#ifdef DEBUG
		printk(KERN_NOTICE "req_cnt is %d, tail is %d, intr_pos is %d, cqe is 0x%x\n", pqueue->pdde->req_cnt, tail, intr_pos, pqueue->cqes[tail]);	
		#endif

		if(/*!(cqe & RESPONSE_VALID) || */(tail == intr_pos) || (tail == 0 && intr_pos == 1024))
			break;
                cqe = pqueue->cqes[tail];
		cmdid = (u16)cqe;
		cmdid &= 0x03FF;

		//write_tail = tail;
		cnt++;
	
	        if (++tail == pqueue->q_depth){
        	    tail = 0;
		}
		writel(tail-1, pqueue->q_resp);

		ctx = free_cmdid(pqueue,cmdid,&fn);
		fn(pqueue->pdde,ctx,cqe);

		#ifdef DEBUG
		printk(KERN_NOTICE "CMD %d done\n",cmdid);
	    	#endif
	}

        pqueue->tail = tail;

	return cnt;
}

static int pdisk_map_bio(struct pdisk_queue *pqueue, struct pdisk_iod *iod,
		struct bio *bio, enum dma_data_direction dma_dir, int psegs)
{
	struct bio_vec *bvec, *bvprv = NULL;
	struct scatterlist *sg = NULL;
	int i, length = 0, nsegs = 0;

	sg_init_table(iod->sg, psegs);
	bio_for_each_segment(bvec, bio, i) {
		if (bvprv && BIOVEC_PHYS_MERGEABLE(bvprv, bvec)) {
			sg->length += bvec->bv_len;
		} else {
			sg = sg ? sg + 1 : iod->sg;
			sg_set_page(sg, bvec->bv_page, bvec->bv_len,
							bvec->bv_offset);
			nsegs++;
		}

		length += bvec->bv_len;
		bvprv = bvec;
	}
	iod->nents = nsegs;
	sg_mark_end(sg);
	if (dma_map_sg(pqueue->q_dmadev, iod->sg, iod->nents, dma_dir) == 0)
		return -ENOMEM;

	BUG_ON(length != bio->bi_size);
	return length;
}

static void pdisk_setup_prps(struct pdisk_command *cmnd,struct pdisk_iod *iod,int total_len)
{
	int length = total_len;
	struct scatterlist *sg = iod->sg;
	int dma_len;
	u64 dma_addr;
	u32 dma_addr_up32,dma_addr_lw32;
	int i = 0,j;

	
	//#ifdef	DEBUG
	//printk(KERN_NOTICE "dma_len:%d\n", total_len);
	//#endif

	while(length){
		dma_len = sg_dma_len(sg);
		dma_addr = sg_dma_address(sg);
		#ifdef	DEBUG
		printk(KERN_NOTICE "dma_addr:0x%llx,dma_len:%d\n",dma_addr,dma_len);
		#endif
		BUG_ON(dma_addr&(~PAGE_MASK));
		BUG_ON(dma_len&(~PAGE_MASK));
		for(j = 0;j < (dma_len >> PAGE_SHIFT);j ++,i ++,dma_addr += PAGE_SIZE){
			dma_addr_lw32 = (u32)dma_addr;
			dma_addr_up32 = ((u32)(dma_addr >> 32))&0x3;
			cmnd->prp[i] = dma_addr | dma_addr_up32;
		}
		sg = sg_next(sg);
		length -= dma_len;
		BUG_ON(length < 0);
	}
}

/*
 * Called with local interrupts disabled and the q_lock held.  May not sleep.
 */
static int pdisk_submit_bio_queue(struct pdisk_queue *pqueue, struct pdisk_ns *pns,
								struct bio *bio)
{
	struct pdisk_command *cmnd;
	struct pdisk_iod *iod;
	enum dma_data_direction dma_dir;
	int cmdid, length, result;

#ifdef CANCEL_DEBUG
	struct pdisk_cmd_info *info = pdisk_cmd_info(pqueue);
#endif

	int psegs = bio_phys_segments(pns->queue, bio);

	result = -ENOMEM;
	iod = pdisk_alloc_iod(psegs, bio->bi_size, GFP_ATOMIC);
	if (!iod)
		goto nomem;
	iod->private = bio;

	result = -EBUSY;
	cmdid = alloc_cmdid(pqueue, iod, bio_completion, PDISK_IO_TIMEOUT);
	if (unlikely(cmdid < 0))
		goto free_iod;

	cmnd = &pqueue->pcommands[pqueue->head];

	memset(cmnd, 0, sizeof(*cmnd));
	if (bio_data_dir(bio)) {
		cmnd->opcode = pdisk_cmd_write;
		dma_dir = DMA_TO_DEVICE;
	} else {
		cmnd->opcode = pdisk_cmd_read;
		dma_dir = DMA_FROM_DEVICE;
	}

	result = pdisk_map_bio(pqueue, iod, bio, dma_dir, psegs);
	if (result <= 0)
		goto free_cmdid;
	length = result;

	//cmdid = cmdid | (((pqueue->qid + 1) & 0xFF) << 10);
	cmdid = cmdid | (((pqueue->qid) & 0xFF) << 10);

	#ifdef DEBUG
	printk(KERN_NOTICE "cmdid is 0x%x", cmdid);
	#endif

	cmnd->cmd_id = cmdid;
	cmnd->LBA = cpu_to_le32(bio->bi_sector >> HW_SECTOR_ORDER);
	cmnd->length = cpu_to_le32(length);
	pdisk_setup_prps(cmnd, iod, length);

	if (++pqueue->head == pqueue->q_depth)
		pqueue->head = 0;
	#ifdef DEBUG
	printk(KERN_NOTICE "Write a new doorbell:%d,CMD ID:%d,pid:%i\n",pqueue->head,cmdid,current->pid);
	#endif

#ifdef CANCEL_DEBUG
	info[cmdid].LBA = cmnd->LBA; 
#endif	
	writel(pqueue->head, pqueue->q_db);

	return 0;

 free_cmdid:
	free_cmdid(pqueue, cmdid, NULL);
 free_iod:
	kfree(iod);
 nomem:
	return result;
}

struct pdisk_queue* get_pqueue(struct PD_Device_Extention* pdde)
{
        return pdde->pqueues[get_cpu() % pdde->queue_count];
        //return pdde->pqueues[];
}

void put_queue(struct pdisk_queue* queue)
{
        put_cpu();
}

static void pdisk_make_request(struct request_queue *q, struct bio *bio)
{
	struct pdisk_ns *pns = q->queuedata;
	struct pdisk_queue *pqueue = get_pqueue(pns->pdde);    
	int result = -EBUSY;

	if (!pqueue) {
		
		printk(KERN_NOTICE "not valid pqueue\n");
                put_queue(NULL);
		bio_endio(bio, -EIO);
		return;
	}

	#ifdef DEBUG
	printk(KERN_NOTICE "bio:sector address=0x%lx\t",(unsigned long)bio->bi_sector);
	printk(KERN_NOTICE "size=0x%x sectors\t",bio_sectors(bio));
	if(bio_data_dir(bio) == WRITE)
		printk(KERN_NOTICE "WRITE\t");
	else
		printk(KERN_NOTICE "READ\t");
	printk(KERN_NOTICE "pid:%i\n",current->pid);
	#endif

	spin_lock_irq(&pqueue->q_lock);
	if (!pqueue->q_suspended && bio_list_empty(&pqueue->q_cong))
		result = pdisk_submit_bio_queue(pqueue, pns, bio);
	if (unlikely(result)) {
		if (bio_list_empty(&pqueue->q_cong))
			add_wait_queue(&pqueue->q_full, &pqueue->q_cong_wait);
		bio_list_add(&pqueue->q_cong, bio);
	}

	pdisk_process_cq(pqueue);
	spin_unlock_irq(&pqueue->q_lock);
		
        put_queue(pqueue);

	pqueue->pdde->req_cnt++;
}


static irqreturn_t pdisk_irq(int irq, void *data)
{
	//printk(KERN_NOTICE "irq is %d\n", irq);
	irqreturn_t result;
	int res;
	struct pdisk_queue *pqueue = data;
	spin_lock(&pqueue->q_lock);
	res = pdisk_process_cq(pqueue);
	result = (res > 0) ? IRQ_HANDLED : IRQ_NONE;
	spin_unlock(&pqueue->q_lock);
	return result;
}

static void pdisk_resubmit_bios(struct pdisk_queue *pqueue)
{
	while (bio_list_peek(&pqueue->q_cong)) {
		struct bio *bio = bio_list_pop(&pqueue->q_cong);
		struct pdisk_ns *pns = bio->bi_bdev->bd_disk->private_data;

		if (bio_list_empty(&pqueue->q_cong))
			remove_wait_queue(&pqueue->q_full,
							&pqueue->q_cong_wait);
		if (pdisk_submit_bio_queue(pqueue, pns, bio)) {
			if (bio_list_empty(&pqueue->q_cong))
				add_wait_queue(&pqueue->q_full,
							&pqueue->q_cong_wait);
			bio_list_add_head(&pqueue->q_cong, bio);
			break;
		}
	}
}

// Kernel thread
static int pdisk_kthread(void *data)
{
	struct PD_Device_Extention *pdde;

	while (!kthread_should_stop()) {
		set_current_state(TASK_INTERRUPTIBLE);
		spin_lock(&dev_list_lock);
		list_for_each_entry(pdde, &dev_list, node) {

                    int i = 0;
             
                    for (i = 0; i < pdde->queue_count; i++){
    
			    struct pdisk_queue *pqueue = pdde->pqueues[i];
			    if (!pqueue)
				    continue;
			    spin_lock_irq(&pqueue->q_lock);
			    if (pqueue->q_suspended)
				    goto unlock;
			    pdisk_process_cq(pqueue);
			    pdisk_cancel_ios(pqueue, true);
			    pdisk_resubmit_bios(pqueue);
unlock:
			    spin_unlock_irq(&pqueue->q_lock);
                    }
  	        }
		spin_unlock(&dev_list_lock);
		schedule_timeout(round_jiffies_relative(HZ));
	}
	return 0;
}

static void pdisk_release_instance(struct PD_Device_Extention *pdde)
{
	spin_lock(&dev_list_lock);
	ida_remove(&pdisk_instance_ida, pdde->instance);
	spin_unlock(&dev_list_lock);
}

static int pdisk_dev_map(struct PD_Device_Extention *pdde)
{
	int bars, result = -ENOMEM;
	struct pci_dev *pdev = pdde->pci_dev;
	
	if (pci_enable_device_mem(pdev))
		return result;
	
	pci_set_master(pdev);
	bars = pci_select_bars(pdev, IORESOURCE_MEM);
	if (pci_request_selected_regions(pdev, bars, "pdisk"))
		goto disable_pci;
		
	if (!dma_set_mask(&pdev->dev, DMA_BIT_MASK(64)))
		dma_set_coherent_mask(&pdev->dev, DMA_BIT_MASK(64));
	else if (!dma_set_mask(&pdev->dev, DMA_BIT_MASK(32)))
		dma_set_coherent_mask(&pdev->dev, DMA_BIT_MASK(32));
	else
		goto disable_pci;
		
	pci_set_drvdata(pdev, pdde);
	pdde->bar = ioremap(pci_resource_start(pdev, 0), 1024);
	#ifdef DEBUG
	printk(KERN_NOTICE "pci_resource_start(pdev, 0):0x%llx,Bar 0 virt Address:0x%lx\n",pci_resource_start(pdev, 0),pdde->bar);
	#endif
	if (!pdde->bar)
		goto disable;
	
        pdde->resps = (u32 __iomem*)((void *)pdde->bar + RRSPQS); 
        pdde->dbs   = (u32 __iomem*)((void *)pdde->bar + RQDBS);

	return 0;
	
	disable:
		pci_release_regions(pdev);
	disable_pci:
		pci_disable_device(pdev);
		return result;
}

static void pdisk_dev_unmap(struct PD_Device_Extention *pdde)
{
	if(pdde->pci_dev->msi_enabled)
		pci_disable_msi(pdde->pci_dev);
        if (pdde->pci_dev->msix_enabled)
                pci_disable_msix(pdde->pci_dev);
	
	if(pdde->bar){
		iounmap(pdde->bar);
		pdde->bar = NULL;
	}
	
	pci_release_regions(pdde->pci_dev);
	if (pci_is_enabled(pdde->pci_dev))
		pci_disable_device(pdde->pci_dev);	
}


static int pdisk_wait_ready(struct PD_Device_Extention *pdde)
{
	unsigned long timeout;
	
	timeout = jiffies + PDISK_DEVICE_TIMEOUT;
	while((readl(&pdde->bar->sts) & PDISK_DEVICE_RDY) == 0){
		msleep(100);
		if (fatal_signal_pending(current))
			return -EINTR;
		if(time_after(jiffies,timeout)){
			dev_err(&pdde->pci_dev->dev,
				"Device not ready; aborting initialization\n");
			return -ENODEV;
		}
	}
	
	return 0;
}

static int pdisk_disable_ctrl(struct PD_Device_Extention *pdde)
{
	u32 cc = readl(&pdde->bar->cc);

	if (cc & PDISK_CC_ENABLE)
		writel(cc & ~PDISK_CC_ENABLE, &pdde->bar->cc);
	return pdisk_wait_ready(pdde);
}

static int pdisk_enable_ctrl(struct PD_Device_Extention *pdde)
{
	return pdisk_wait_ready(pdde);
}

static int queue_request_irq(struct PD_Device_Extention *pdde,struct pdisk_queue *pqueue,const char *name)
{
/*	
	int result;
	result = pci_enable_msi(pdde->pci_dev);
	if(result)
		return result;
*/
	return request_irq(pdde->entry[pqueue->qid].vector, pdisk_irq, IRQF_DISABLED | IRQF_SHARED, name, pqueue);
}

static unsigned pdisk_queue_extra(int depth)
{
	return DIV_ROUND_UP(depth,8) + (depth*sizeof(struct pdisk_cmd_info));
}

static struct pdisk_queue * pdisk_alloc_queue(struct PD_Device_Extention *pdde, int qid, int depth, int vector)
{
	struct   device *dmadev = &pdde->pci_dev->dev;
	unsigned extra = pdisk_queue_extra(depth);
	struct   pdisk_queue *pqueue = kzalloc(sizeof(*pqueue) + extra, GFP_KERNEL);

	int i;	

	if(!pqueue)
		return NULL;
	
	pqueue->pcommands = dma_alloc_coherent(dmadev,Q_SIZE(depth),&pqueue->q_dma_addr,GFP_KERNEL);
	if(!pqueue->pcommands)
		goto free_queue;
	pqueue->cqes = dma_alloc_coherent(dmadev, (depth+1)*sizeof(u32), &pqueue->cq_dma_addr, GFP_KERNEL);
	if(!pqueue->cqes)
		goto free_queue;
		
        for (i = 0; i <= pqueue->q_depth; i++){
	    pqueue->cqes[i] = 0;
        }
	pqueue->q_dmadev = dmadev;
	pqueue->pdde = pdde;
	spin_lock_init(&pqueue->q_lock);
	pqueue->head = 0;
	pqueue->tail = 0;
	init_waitqueue_head(&pqueue->q_full);
	init_waitqueue_entry(&pqueue->q_cong_wait,pdisk_thread);
	bio_list_init(&pqueue->q_cong);
	pqueue->q_depth = depth;
    
	pqueue->q_db   = &pdde->dbs[qid << 2];          
        pqueue->sq_reg = &pdde->dbs[(qid << 2) + 1];
	pqueue->q_resp = &pdde->resps[(qid << 2) + 1];
        pqueue->cq_reg = &pdde->resps[qid << 2];

	pqueue->q_suspended = 1;

        pqueue->cq_vector = vector;
	pqueue->qid = qid;
   
        pdde->queue_count++;
	
	return pqueue;
		
	free_queue:
		kfree(pqueue);
		return NULL;
}

static void pdisk_disable_queue(struct PD_Device_Extention *pdde, int qid)
{
	struct pdisk_queue *pqueue = pdde->pqueues[qid];
        int vector = pdde->pqueues[qid]->cq_vector;
	
	spin_lock_irq(&pqueue->q_lock);
	if(pqueue->q_suspended){
		spin_unlock_irq(&pqueue->q_lock);
		return;
	}
	pqueue->q_suspended = 1;
	spin_unlock_irq(&pqueue->q_lock);

        irq_set_affinity_hint(vector, NULL);
	free_irq(vector, pqueue);
	
	spin_lock_irq(&pqueue->q_lock);
	pdisk_process_cq(pqueue);
	pdisk_cancel_ios(pqueue,false);
	spin_unlock_irq(&pqueue->q_lock);
}

static void pdisk_release_queue(struct pdisk_queue* pqueue)
{
	if(pqueue && pqueue->pcommands)
		dma_free_coherent(pqueue->q_dmadev,Q_SIZE(pqueue->q_depth),(void *)pqueue->pcommands,pqueue->q_dma_addr);
	if(pqueue && pqueue->cqes)
		dma_free_coherent(pqueue->q_dmadev, (pqueue->q_depth+1) * sizeof(u32),(void *)pqueue->cqes,pqueue->cq_dma_addr);
	if(pqueue)
		kfree(pqueue);
}

static void pdisk_release_queues(struct PD_Device_Extention *pdde)
{
    int i;

    for (i = pdde->queue_count - 1; i >= pdde->queue_count; i--){

        pdisk_release_queue(pdde->pqueues[i]);        
        pdde->queue_count--;
        pdde->pqueues[i] = NULL;
    }
}

static void pdisk_init_queue(struct pdisk_queue *pqueue)
{
    unsigned extra = pdisk_queue_extra(pqueue->q_depth); 
    int i;
    memset(pqueue->cmdid_data,0,extra);

    pdisk_cancel_ios(pqueue,false);
    pqueue->q_suspended = 0;

    writel(pqueue->cq_dma_addr, pqueue->cq_reg);
    writel(pqueue->q_dma_addr, pqueue->sq_reg);   
}

// request the irq and init the queue
static int pdisk_create_queue(struct pdisk_queue* pqueue, int qid)
{
    struct PD_Device_Extention *pdde = pqueue->pdde;

    spin_lock(&pqueue->q_lock);

    pdisk_init_queue(pqueue);

    spin_unlock(&pqueue->q_lock);

    return queue_request_irq(pdde, pqueue, "pqueue");
}

// determine the number of queues by query the device, to be modified
static int set_queue_count(struct PD_Device_Extention *dev, int count)
{
    //return count;
    return QUEUE_COUNT;
}

static int pdisk_setup_queue(struct PD_Device_Extention *pdde)
{
	struct pci_dev *pdev = pdde->pci_dev;
        int result, nr_queues, vecs, cpu, i;

	//struct pdisk_queue *pqueue;

        pdde->queue_count = 0;
        // set the number of the queues
        nr_queues = num_online_cpus();
        result = set_queue_count(pdde, nr_queues);
	if (result < 0)
             return result;
        if (result < nr_queues)
        nr_queues = result;
        
	result = pdisk_disable_ctrl(pdde);
	if (result < 0)
		return result;

        vecs = nr_queues;
        for (i = 0; i < nr_queues; i++)
            pdde->entry[i].entry = i;
        for (;;){
            result = pci_enable_msix(pdev, pdde->entry, vecs);
            if (result <= 0)
                break;   
            vecs = result;
        }

        if (result < 0){
        // to be handled if the request is failed        
             return result;
        }
        nr_queues = vecs;

        // set cpu affinity ?
        cpu = cpumask_first(cpu_online_mask);
        for (i = 0; i < nr_queues; i++){
            irq_set_affinity_hint(pdde->entry[i].vector, get_cpu_mask(cpu));
            cpu = cpumask_next(cpu, cpu_online_mask);
        }

        // allocates pdisk queues, the depth is default 1024
        // ensure that one cpu has a queue ,no more or no less
        for (i = 0; i < nr_queues; i++){

             pdde->pqueues[i] = pdisk_alloc_queue(pdde, i, queue_depth, pdde->entry[i].vector);
             if (!pdde->pqueues[i]){
                 result = -ENOMEM;
                 goto release_queue;
             }
             result = pdisk_create_queue(pdde->pqueues[i], i);
             if (result){
                  for (--i; i > 0; i--){
                      pdisk_disable_queue(pdde, i);
                  }
                  goto release_queue;
             }
        }
	
	pdde->ctrl_config = PDISK_CC_ENABLE;
	pdde->ctrl_config |= PDISK_INT_ENABLE;
//	pdde->ctrl_config &= ~PDISK_INT_ENABLE;
	
//	writel(pdde->pqueues[0]->q_dma_addr,&pdde->bar->rqbaddr);
//	pdde->pqueues[0]->q_db = (u32 __iomem*)((void *)pdde->bar + RQDBL);
	
	writel(queue_depth,&pdde->bar->rqdph);
	writel(pdde->ctrl_config,&pdde->bar->cc);
	
	result = pdisk_enable_ctrl(pdde);
	if(result)
		goto release_queue;

        return result;

	release_queue:
		pdisk_release_queues(pdde);
		return result;
}

static int pdisk_dev_start(struct PD_Device_Extention *pdde)
{
	int result;
	
	result = pdisk_dev_map(pdde);
	if(result)
		return result;
		
	spin_lock(&dev_list_lock);
	list_add(&pdde->node, &dev_list);
	spin_unlock(&dev_list_lock);
	
	result = pdisk_setup_queue(pdde);
	if(result)
		goto disable;

	return result;
	
	disable:
		spin_lock(&dev_list_lock);
		list_del_init(&pdde->node);
		spin_unlock(&dev_list_lock);
		pdisk_dev_unmap(pdde);
		return result;
}

//Open PDISK
static int pdisk_open(struct block_device *bdev,fmode_t mode){
	//struct pdisk_ns *pns = bdev->bd_disk->private_data;

	#ifdef PSD_DEBUG
	printk(KERN_NOTICE "process %i opened pdisk!\n",current->pid);
	#endif

	return SUCCESS;
}

//Release PDISK
static void pdisk_release(struct gendisk *disk,fmode_t mode){
	//struct pdisk_ns *pns = bdev->bd_disk->private_data;
	
	#ifdef PSD_DEBUG
	printk(KERN_NOTICE "process %i closed pdisk!\n",current->pid);
	#endif
}

static const struct block_device_operations pdisk_fops = {
	
	.open = pdisk_open,
	.release = pdisk_release,
	.owner = THIS_MODULE,
};

static struct pdisk_ns * pdisk_dev_add(struct PD_Device_Extention *pdde)
{
	struct pdisk_ns *pns;
	struct gendisk *disk;
	
	pns = kzalloc(sizeof(*pns),GFP_KERNEL);
	if(!pns)
		return NULL;
	pns->queue = blk_alloc_queue(GFP_KERNEL);
	if(!pns->queue)
		goto out_free_pns;
	
	pns->queue->queue_flags = QUEUE_FLAG_DEFAULT;
	queue_flag_set_unlocked(QUEUE_FLAG_NOMERGES, pns->queue);
	queue_flag_set_unlocked(QUEUE_FLAG_NONROT, pns->queue);
	blk_queue_make_request(pns->queue, pdisk_make_request);	
	pns->pdde = pdde;
	pns->queue->queuedata = pns;
	
	disk = alloc_disk(PDISK_MINORS);
	if(!disk)
		goto out_free_queue;
	pns->disk = disk;
	blk_queue_logical_block_size(pns->queue,HW_SECTOR_SIZE);
	blk_queue_physical_block_size(pns->queue,HW_SECTOR_SIZE);
	blk_queue_max_hw_sectors(pns->queue,MAX_HW_SECTOR_SIZE);
	
	disk->major = pdisk_major;
	disk->minors = PDISK_MINORS;
	disk->first_minor = PDISK_MINORS*pdisk_get_ns_idx();
	disk->fops = &pdisk_fops;
	disk->private_data = pns;
	disk->queue = pns->queue;
	disk->driverfs_dev = &pdde->pci_dev->dev;
	sprintf(disk->disk_name,"pdisk%c",pdde->instance+'a');
	set_capacity(disk,PDISK_SECTORS*(HW_SECTOR_SIZE/KERNEL_SECTOR_SIZE));
	
	add_disk(disk);
	
	return pns;
	
	out_free_queue:
		blk_cleanup_queue(pns->queue);
	out_free_pns:
		kfree(pns);
		return NULL;
}

static void pdisk_dev_shutdown(struct PD_Device_Extention *pdde)
{

        int i;

	pdisk_disable_ctrl(pdde);
        for (i = 0; i < pdde->queue_count; i++){
    	    pdisk_release_queue(pdde->pqueues[i]);
	    pdisk_disable_queue(pdde, i);
        }   

	spin_lock(&dev_list_lock);
	list_del_init(&pdde->node);
	spin_unlock(&dev_list_lock);
	pdisk_dev_unmap(pdde);
}

static int psd_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
	int result = -ENOMEM;
	struct PD_Device_Extention *pdde;
	int i;
	
	pdde = kzalloc(sizeof(*pdde),GFP_KERNEL);
	if(!pdde)
		return -ENOMEM;

        // allocate the msix entries and queues
        pdde->entry = kcalloc(num_possible_cpus(), sizeof(*pdde->entry), GFP_KERNEL);
        if (!pdde->entry)
            goto free;
        pdde->pqueues = kcalloc(num_possible_cpus(), sizeof(void *), GFP_KERNEL);
        if (!pdde->pqueues)
            goto free;


	pdde->pci_dev = pdev;	
	result = pdisk_set_instance(pdde);
	if(result)
		goto free;
	
	result = pdisk_dev_start(pdde);
	if(result)
		goto release;
	pdde->pns = pdisk_dev_add(pdde);
	if(!pdde->pns)
		goto shutdown;

	pdde->req_cnt = 0;

	kref_init(&pdde->kref);
	
	return 0;
		
	shutdown:
		pdisk_dev_shutdown(pdde);
	release:
		pdisk_release_instance(pdde);
	free:
		kfree(pdde);
		return result;
		
}

static void pdisk_dev_remove(struct PD_Device_Extention *pdde)
{
	int index;	
	struct pdisk_ns *pns = pdde->pns;
	del_gendisk(pns->disk);
	index = pns->disk->first_minor / PDISK_MINORS;
	put_disk(pns->disk);
	pdisk_put_ns_idx(index);
	blk_cleanup_queue(pns->queue);
	kfree(pns);
}

static void pdisk_free_dev(struct kref *kref)
{
	struct PD_Device_Extention *pdde = container_of(kref,struct PD_Device_Extention,kref);
	pdisk_dev_remove(pdde);
	pdisk_dev_shutdown(pdde);
	pdisk_release_instance(pdde);
	kfree(pdde);
}

static void psd_remove(struct pci_dev *pdev)
{
	struct PD_Device_Extention *pdde = pci_get_drvdata(pdev);
	kref_put(&pdde->kref,pdisk_free_dev);
}

//Supported devices
static struct pci_device_id psd_ids[] = {
	{PCI_DEVICE(PCI_VENDOR_ID_XILINX,PCI_DEVICE_ID_XILINX_PCIE)},
	{0,}
};

MODULE_DEVICE_TABLE(pci,psd_ids);

/*pci_driver initializer*/
static struct pci_driver pdisk_driver = {
	.name		= "NUDT PSD Driver",
	.id_table	= psd_ids,
	.probe		= psd_probe,
	.remove		= psd_remove,
};

static int __init psd_init(void)
{
	int result;
	
	printk(KERN_WARNING "LOAD PCIE SSD DRIVER.\n");	
	
	pdisk_thread = kthread_run(pdisk_kthread,NULL,"pdisk");
	if(IS_ERR(pdisk_thread))
		return PTR_ERR(pdisk_thread);
	
	result = register_blkdev(pdisk_major,"pdisk");
	if(result < 0)
		goto kill_kthread;
	else if(result > 0)
		pdisk_major = result;
	
	result = pci_register_driver(&pdisk_driver);
	if(result)
		goto unregister_blkdev;
	return 0;
	
	unregister_blkdev:
		unregister_blkdev(pdisk_major,"pdisk");
	
	kill_kthread:
		kthread_stop(pdisk_thread);
		return result;
}

static void __exit psd_exit(void)
{		
	pci_unregister_driver(&pdisk_driver);
	unregister_blkdev(pdisk_major,"pdisk");	
	kthread_stop(pdisk_thread);
	
	printk(KERN_WARNING "PCIE SSD DRIVER REMOVED.\n");
}

module_init(psd_init);
module_exit(psd_exit);
