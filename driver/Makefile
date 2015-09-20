obj-m := pcie_ssd_driver.o

path := $(shell uname -r)
PWD := $(shell pwd)
all:
	make -C /lib/modules/$(path)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(path)/build M=$(PWD) clean


