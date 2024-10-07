#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Clean the build directory
#make clean
#make mrproper

# Update configuration to new kernel version
# yes "" | make oldconfig
# cp /boot/config-$(uname -r) .config
#make menuconfig

# Build Debian packages
# CONFIG_DEBUG_INFO avoid using dbg packages, it takes long time
# change them to None in .config, remember to push .config into repo
make -j$(nproc) bindeb-pkg LOCALVERSION=-cxl-ksm 
# sudo make modules_install INSTALL_MOD_STRIP=1
# fakeroot make bindeb-pkg

# Install the kernel
# sudo dpkg -i linux-image-*.deb linux-headers-*.deb
# sudo update-grub
