#!/bin/sh

# --- 7. Download busybox ---
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar -vxf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
    make defconfig
    sed -i 's/.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/' .config
    make -j$(nproc)
cd ..

# --- 8. CREATE INITRD.IMG ---
echo "[+] Create initramfs.new.gz ..."
rm -rf rootfs rootfs.newc.gz
mkdir -p rootfs/bin rootfs/proc rootfs/sys rootfs/dev rootfs/tmp
cp /usr/bin/busybox rootfs/bin/
cd rootfs
    for prog in $(/usr/bin/busybox --list); do
        if test "$prog" = "busybox" || test "$prog" = "[" || test "$prog" = "[["
        then
            continue
        fi
        ln -s /bin/busybox ./bin/$prog
    done
    cat > init << EOF
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /tmp
sysctl -w kernel.printk="2 4 1 7"
sh
poweroff -f
EOF
    chmod -R 777 .
    find . | cpio --create --format=newc | gzip --best > ../rootfs.newc.gz
cd ..

sh debug_vm.sh
