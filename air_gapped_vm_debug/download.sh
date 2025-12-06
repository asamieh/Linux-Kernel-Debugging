# 1 - download.sh (works for ubuntu server 24.04.3)
#
# run on identical twin VM (with internet)

sudo apt update
sudo apt install --download-only --reinstall \
	build-essential \
	libncurses-dev \
	bison \
	flex \
	libssl-dev \
	bc \
	libelf-dev \
	fakeroot \
	tmux \
	gdb \
	git \
	dwarves \
	libdw-dev \
	libunwind-dev \
	binutils \
	kmod \
	crash \
	makedumpfile \
	linux-buildinfo-$(uname -r)

tar -cJvf packages.tar.xz --transform='s|.*/|packages/|' /var/cache/apt/archives/*.deb

wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.1.tar.xz
