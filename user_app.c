#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include "interceptor.h"

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        printf("usage: %s <devfile>\n", argv[0]);
        return 0;
    }

    int fd = open(argv[1], O_RDWR);

    if (fd < 0)
    {
        perror("open");
        return fd;
    }

    int status;

    printf("calling ioctl:INTERCEPTOR_IOCTL_WRITE_REGISTER:0x%0lX\n", INTERCEPTOR_IOCTL_WRITE_REGISTER);
    for (int i = 0; i < NUMBER_OF_REGISTERS - 1; i++)
    {
        reg_op wr = {.reg = i, .value = 0x1982 + i};
        status = ioctl(fd, INTERCEPTOR_IOCTL_WRITE_REGISTER, &wr);
        printf("ioctl status: %d\n", status);
    }

    printf("calling ioctl:INTERCEPTOR_IOCTL_READ_REGISTER:0x%0lX\n", INTERCEPTOR_IOCTL_READ_REGISTER);
    for (int i = 0; i < NUMBER_OF_REGISTERS; i++)
    {
        reg_op rd = {.reg = i, .value = 0};
        status = ioctl(fd, INTERCEPTOR_IOCTL_READ_REGISTER, &rd);
        printf("ioctl status: %d, rd.value: 0x%0X\n", status, rd.value);
    }

    close(fd);
    return 0;
}
