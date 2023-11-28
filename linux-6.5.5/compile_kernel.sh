#!bin/bash

sudo make -j 65
sudo make INSTALL_MOD_STRIP=1 modules_install &&
sudo make install &&
echo "check kernel real name"
sudo update-initramfs -c -k 6.5.5 &&
sudo update-grub &&
echo "wait for reboot"
