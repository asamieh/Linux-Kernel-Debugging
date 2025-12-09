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
    -s
