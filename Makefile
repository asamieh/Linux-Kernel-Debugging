MODULE_NAME=interceptor

# obj-<X> := <module_name>.o
# <X> = n, Don't compile the module
# <X> = y, Compile and link the module to kernel image
# <X> = m, Compile as dynamically lodable kernel module
obj-m := $(MODULE_NAME).o

LINUX_KERNEL_SOURCE=/lib/modules/$(shell uname -r)/build

all:
	gcc user_app.c -g -o user_app
	# trigger the top level make file of linux kernel headers and pass pwd as the module to build
	make -C $(LINUX_KERNEL_SOURCE) M=$(shell pwd) modules

clean:
	rm -rf user_app
	make -C $(LINUX_KERNEL_SOURCE) M=$(shell pwd) clean

insert:
	sudo insmod $(MODULE_NAME).ko
	ls -l /dev/$(MODULE_NAME)*

remove:
	sudo rmmod $(MODULE_NAME)
	ls -l /dev/$(MODULE_NAME)*

ls:
	lsmod | grep $(MODULE_NAME)

proc:
	cat /proc/devices | grep $(MODULE_NAME)

info:
	#objdump -d -j .modinfo $(MODULE_NAME).ko
	file $(MODULE_NAME).ko
	modinfo $(MODULE_NAME).ko

test:
	cat /dev/$(MODULE_NAME)0
	dd if=/dev/zero of=/dev/$(MODULE_NAME)1 bs=1k count=2
	./user_app /dev/$(MODULE_NAME)1
