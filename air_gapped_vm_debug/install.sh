# 5 - install.sh

cd linux-6.8.1
	sudo make modules_install -j$(nproc)
	#ls -l /lib/modules
	sudo make install
	#ls -l /boot
	sudo update-grub
	sudo reboot
