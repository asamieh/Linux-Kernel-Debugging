# 3 - cleanup.sh

cd linux-6.18
	make mrproper
	cp /boot/config-$(uname -r) .config
	sed -i "s|debian|/usr/lib/linux/$(uname -r)|g" .config

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

	make olddefconfig
