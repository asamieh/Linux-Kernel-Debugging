qemu-system-arm -M virt -m 256M -kernel linux-6.18/arch/arm/boot/zImage -initrd initrd.img -append "root=/dev/mem" -nographic -s -S
