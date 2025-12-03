# 5 - install.sh

cd linux-6.18
	sudo make modules_install -j$(nproc)
	#ls -l /lib/modules
	sudo make install
	#ls -l /boot
	sudo update-grup
	#sudo reboot
