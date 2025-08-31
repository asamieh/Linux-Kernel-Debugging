#!/bin/sh
# --- 7. CREATE INITRD.IMG ---
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
