#ifndef _INTERCEPTOR_H_
#define _INTERCEPTOR_H_

#include <linux/ioctl.h>

#define MAGIC_NUMBER 'I'  // Unique magic number

#define NUMBER_OF_REGISTERS (4)


// Structure to read/write to a register
typedef struct reg_op {
    unsigned int reg;
    unsigned int value;
} reg_op;

// Write to register: Pass struct reg_op from user space
#define INTERCEPTOR_IOCTL_WRITE_REGISTER _IOW(MAGIC_NUMBER, 1, reg_op)

// Read from register: User sets reg and kernel writes the value back
#define INTERCEPTOR_IOCTL_READ_REGISTER  _IOR(MAGIC_NUMBER, 2, reg_op)

#endif // _INTERCEPTOR_H_
