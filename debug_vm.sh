#!/bin/sh
# --- 8. TIPS FOR DEBUGGING ---
cat << EOF
To debug with gdb:
  gdb -tui linux/vmlinux
  (gdb) target remote :1234

To set breakpoints:
  (gdb) b interceptor_insert
  (gdb) b interceptor_remove
  (gdb) b interceptor_open
  (gdb) b interceptor_close
  (gdb) b interceptor_read
  (gdb) b interceptor_write
  (gdb) b interceptor_ioctl

Then:
  (gdb) c
EOF

# --- 9. RUN QEMU ---
echo "Lunch minimal Linux busybox ..."
qemu-system-x86_64 \
    -kernel ./bzImage \
    -initrd ./rootfs.newc.gz \
    -nographic \
    -append "console=ttyS0" \
    -S \
    -s
