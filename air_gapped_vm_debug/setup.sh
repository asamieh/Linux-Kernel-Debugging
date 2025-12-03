# 2 - setup.sh
#
# run on the air-gapped VM

tar -vxf packages.tar.xz

sudo dpkg -i packages/*.deb
sudo apt install -f

tar -vxf linux-6.18.tar.xz

./cleanup.sh
