#!/bin/sh
KERNEL_VERSION="6.16.4"
KERNEL_DIR="linux-$KERNEL_VERSION"
MODULE_NAME="interceptor"

# --- 1. GET KERNEL SOURCE ---
echo "[+] Downloading Linux kernel $KERNEL_VERSION..."
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz
rm -rf $KERNEL_DIR
tar -xf $KERNEL_DIR.tar.xz

cd $KERNEL_DIR

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
    echo "$KERNEL_DIR/vmlinux"
cd ..

# --- 6. OUTPUT VMLINUX FOR DEBUGGING ---
cp $KERNEL_DIR/arch/x86_64/boot/bzImage ./

sh create_initrd_and_debug_vm.sh
