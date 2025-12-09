# Download arm gnu cross platform toolchain
wget https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz
tar -vxf arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz

# Download linux kernel source code
wget https://git.kernel.org/torvalds/t/linux-6.18.tar.gz
tar -vxf linux-6.18.tar.gz
cd linux-6.18
    make ARCH=arm CROSS_COMPILE=../arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- defconfig
    sed -i 's/CONFIG_WATCHDOG=y/CONFIG_WATCHDOG=n/' .config
    sed -i 's/.*CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT.*$/# CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT is not set/' .config
    sed -i 's/.*CONFIG_DEBUG_INFO_DWARF5.*$/CONFIG_DEBUG_INFO_DWARF5=y/' .config
    sed -i 's/.*CONFIG_GDB_SCRIPTS.*$/CONFIG_GDB_SCRIPTS=y/' .config
    #sed -i 's/CONFIG_RANDOMIZE_BASE=y/CONFIG_RANDOMIZE_BASE=n/' .config
    make ARCH=arm CROSS_COMPILE=../arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- -j$(nproc)
    file vmlinux
cd ..

# Download busybox
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar -vxf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
    make ARCH=arm CROSS_COMPILE=../arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- defconfig
    sed -i 's/.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/' .config
    make ARCH=arm CROSS_COMPILE=../arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- -j$(nproc)
cd ..

# Create initrd.img
rm -rf initrd.img initrd
mkdir -p initrd/bin initrd/dev initrd/proc initrd/sys
cp busybox-1.36.1/busybox initrd/bin/
cd initrd
    for prog in $(busybox --list); do
        ln -s /bin/busybox ./bin/$prog
    done
    echo '#!/bin/sh'                    > init
    echo 'mount -t devtmpfs udev /dev' >> init
    echo 'mount -t proc proc /proc'    >> init
    echo 'mount -t sysfs sysfs /sys'   >> init
    echo 'sh'                          >> init
    echo 'poweroff -f'                 >> init
    chmod -R 777 .
    find . | cpio -o -H newc > ../initrd.img
cd ..

# Lunch minimal Linux busybox
qemu-system-arm \
    -M virt \
    -m 256M \
    -kernel linux-6.18/arch/arm/boot/zImage \
    -initrd initrd.img \
    -append "root=/dev/mem" \
    -nographic \
    -s \
    -S

# Connect from another session
# arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-gdb linux-6.18/vmlinux
# target remote :1234

