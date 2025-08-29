#include <linux/module.h>
#include <linux/init.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include "interceptor.h"

#define MODULE_NAME "interceptor"
#define TAG MODULE_NAME"_module"
#define NUMBER_OF_DEVICE_INSTANCES (2)

static dev_t dev;
static struct class *class;
static struct cdev cdev;
static uint32_t reg[NUMBER_OF_DEVICE_INSTANCES][NUMBER_OF_REGISTERS];

static int interceptor_open(struct inode *in, struct file *)
{
    pr_info(TAG ":%s  [%d.%d]\n", __func__, imajor(in), iminor(in));
    return 0;
}

static int interceptor_close(struct inode *in, struct file *)
{
    pr_info(TAG ":%s [%d.%d]\n", __func__, imajor(in), iminor(in));
    return 0;
}

static ssize_t interceptor_read(struct file *f, char __user *, size_t size, loff_t *)
{
    pr_info(TAG ":%s  [%d.%d] - read 0-%ld bytes\n", __func__, imajor(f->f_inode), iminor(f->f_inode), size);
    return 0;
}

static ssize_t interceptor_write(struct file *f, const char __user *, size_t size, loff_t *)
{
    pr_info(TAG ":%s [%d.%d] - write 0-%ld bytes\n", __func__, imajor(f->f_inode), iminor(f->f_inode), size);
    return size;
}

static long interceptor_ioctl(struct file *f, unsigned int cmd, unsigned long data)
{
    long error = 0;
    if (cmd == INTERCEPTOR_IOCTL_WRITE_REGISTER || cmd == INTERCEPTOR_IOCTL_READ_REGISTER)
    {
        reg_op *p = (reg_op *) kmalloc(sizeof(reg_op), GFP_KERNEL);
        if (p == NULL)
        {
            return -ENOMEM;
        }

        if (copy_from_user((char *)p, (char __user *)data, sizeof(reg_op)))
        {
            error = -EFAULT;
            pr_err(TAG ":%s [%d.%d] - cmd:0x%0X data:0x%0lX - copy_from_user failed\n",
                   __func__, imajor(f->f_inode), iminor(f->f_inode), cmd, data);
        }
        else
        {
            if (cmd == INTERCEPTOR_IOCTL_WRITE_REGISTER)
            {
                if (p->reg < NUMBER_OF_REGISTERS)
                {
                    reg[iminor(f->f_inode)][p->reg] = p->value;
                }
                pr_info(TAG ":%s [%d.%d] - cmd:0x%0X reg_op[reg:0x%0X, value:0x%0X] - copy_from_user\n",
                        __func__, imajor(f->f_inode), iminor(f->f_inode), cmd, p->reg, p->value);
            }
            else // if (cmd == INTERCEPTOR_IOCTL_READ_REGISTER)
            {
                if (p->reg < NUMBER_OF_REGISTERS)
                {
                    p->value = reg[iminor(f->f_inode)][p->reg];
                }
                if (copy_to_user((char __user *)data, (char *)p, sizeof(reg_op)))
                {
                    error = -EFAULT;
                    pr_err(TAG ":%s [%d.%d] - cmd:0x%0X data:0x%0lX - copy_to_user failed\n",
                           __func__, imajor(f->f_inode), iminor(f->f_inode), cmd, data);
                }
                else
                {
                    pr_info(TAG ":%s [%d.%d] - cmd:0x%0X reg_op[reg:0x%0X, value:0x%0X] - copy_to_user\n",
                            __func__, imajor(f->f_inode), iminor(f->f_inode), cmd, p->reg, p->value);
                }
            }
        }

        kfree(p);
    }
    else
    {
        error = ENOTTY;
        pr_err(TAG ":%s [%d.%d] - cmd:0x%0X data:0x%0lX - failed\n", __func__, imajor(f->f_inode), iminor(f->f_inode), cmd, data);
    }

    return error;
}

static struct file_operations fops = {
    .owner          = THIS_MODULE, // pointer to current module, used for ref count the module
    .open           = interceptor_open,
    .release        = interceptor_close,
    .read           = interceptor_read,
    .write          = interceptor_write,
    .unlocked_ioctl = interceptor_ioctl
};

static char *devnode(const struct device *, umode_t *mode)
{
    if (mode)
    {
        *mode = 0666;  // rw-rw-rw-
    }
    return NULL;
}

static int __init interceptor_insert(void)
{
    // Dynamically allocate device number
    int error = alloc_chrdev_region(&dev, 0, NUMBER_OF_DEVICE_INSTANCES, MODULE_NAME);
    if (error < 0)
    {
        pr_err(TAG ":%s alloc_chrdev_region failed, error: %d\n", __func__, error);
        return error;
    }

    // Initialize cdev with file ops
    cdev_init(&cdev, &fops);
    cdev.owner = THIS_MODULE;
    // Register devices with VFS
    error = cdev_add(&cdev, dev, NUMBER_OF_DEVICE_INSTANCES);
    if (error < 0)
    {
        pr_err(TAG ":%s cdev_add failed, error: %d\n", __func__, error);
        goto free_chrdev_region;
    }

    class = class_create(MODULE_NAME);
    if (IS_ERR(class))
    {
        error = PTR_ERR(class);
        pr_err(TAG ":%s class_create failed, error: %d\n", __func__, error);
        goto cdev_remove;
    }

    class->devnode = devnode;

    int i;
    for (i = 0; i < NUMBER_OF_DEVICE_INSTANCES; i++)
    {
        // Create device file
        struct device *device = device_create(
                class,
                NULL,
                MKDEV(MAJOR(dev), i),
                NULL,
                MODULE_NAME"%d", i);
        if (IS_ERR(device))
        {
            error = PTR_ERR(device);
            pr_err(TAG ":%s device_create failed to create %s%d, error: %d\n", __func__, MODULE_NAME, i, error);
            goto devices_destroy;
        }
        pr_info(TAG ":%s device_create %s%d\n", __func__, MODULE_NAME, i);

        for (int j = 0; j < NUMBER_OF_REGISTERS; j++)
        {
            // Initialize regs
            reg[i][j] = 0xCDCDCDCD;
        }
    }

    return 0;

devices_destroy:
    if (i != NUMBER_OF_DEVICE_INSTANCES)
    {
        while (i--)
        {
            pr_err(TAG ":%s device_destroy %s%d\n", __func__, MODULE_NAME, i);
            device_destroy(class, MKDEV(MAJOR(dev), i));
        }
    }
    class_destroy(class);
cdev_remove:
    cdev_del(&cdev);
free_chrdev_region:
    unregister_chrdev_region(dev, NUMBER_OF_DEVICE_INSTANCES);

    return error;
}

static void __exit interceptor_remove(void)
{
    for (int i = NUMBER_OF_DEVICE_INSTANCES - 1; i >= 0; i--)
    {
        pr_info(TAG ":%s device_destroy %s%d\n", __func__, MODULE_NAME, i);
        device_destroy(class, MKDEV(MAJOR(dev), i));
    }

    class_destroy(class);
    cdev_del(&cdev);
    unregister_chrdev_region(dev, NUMBER_OF_DEVICE_INSTANCES);
}

module_init(interceptor_insert);
module_exit(interceptor_remove);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ahmed Ibrahim <ahmed.samieh@gmail.com>");
MODULE_DESCRIPTION("Character device to intercept and trace how syscalls make it through the kernel!");
