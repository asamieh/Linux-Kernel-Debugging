#!/bin/sh
MODULE_NAME="interceptor"

# --- 1. CLONE LINUX KERNEL SOURCE CODE ---
echo "[+] Clone linux kernel ..."
rm -rf linux
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

cd linux
    git checkout master
    git fetch
    git pull
    git checkout $(git tag | grep -v rc | awk -F'[v.]' '{ printf("%02d%02d%02d %s\n", $2, $3, $4, $0) }' | sort | tail -n 1 | awk '{ print $2 }')
    # --- 2. COPY MODULE CODE TO KERNEL SOURCE TREE ---
    echo "[+] Copy $MODULE_NAME code..."

    MODULE_DIR="drivers/$MODULE_NAME"
    mkdir -p "$MODULE_DIR"

    cat ../$MODULE_NAME.c > $MODULE_DIR/$MODULE_NAME.c
    cat ../$MODULE_NAME.h > $MODULE_DIR/$MODULE_NAME.h

    # --- 3. MODIFY KERNEL TO BUILD MODULE STATISTICALLY ---
    echo "[+] Adding Makefile and Kconfig..."

    # Add to drivers/Makefile
    echo "obj-y += $MODULE_NAME/" >> drivers/Makefile

    # Create drivers/$MODULE_NAME/Makefile
    echo "obj-y := $MODULE_NAME.o" > $MODULE_DIR/Makefile

    # Add to drivers/Kconfig
    echo "source \"drivers/$MODULE_NAME/Kconfig\"" >> drivers/Kconfig

    # Create drivers/$MODULE_NAME/Kconfig
    cat > $MODULE_DIR/Kconfig << EOF
config INTERCEPTOR
    bool "Include Interceptor Module"
    default y
    help
      Say Y here to include an interceptor module that logs insert/remove/open/close/read/write/ioctl.
EOF

    # --- 4. CONFIGURE THE KERNEL ---
    echo "[+] Configuring kernel with debug symbols..."

    make mrproper
    make defconfig

    # Enable debug info
    scripts/config --enable DEBUG_KERNEL
    scripts/config --enable DEBUG_INFO
    scripts/config --enable DEBUG_INFO_DWARF5
    scripts/config --disable DEBUG_INFO_REDUCED
    scripts/config --disable DEBUG_INFO_SPLIT
    scripts/config --enable FRAME_POINTER
    scripts/config --disable WATCHDOG
    scripts/config --disable RANDOMIZE_BASE
    scripts/config --disable RANDOMIZE_KSTACK_OFFSET
    scripts/config --enable GDB_SCRIPTS
    scripts/config --enable INTERCEPTOR

    make olddefconfig

    # --- 5. BUILD THE KERNEL ---
    echo "[+] Building kernel..."
    make -j$(nproc)
    echo "[+] Kernel build complete."
    nm ./vmlinux | grep $MODULE_NAME
    echo "[+] Debuggable vmlinux is located at:"
    echo "linux/vmlinux"
cd ..

# --- 6. OUTPUT VMLINUX FOR DEBUGGING ---
cp linux/arch/x86_64/boot/bzImage ./

sh create_rootfs_and_debug_vm.sh
