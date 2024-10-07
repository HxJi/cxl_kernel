#!bin/bash
# try to set 2.2GHz but we may only get 2.1GHz
#sudo /home/yans3/linux_mn_il/tools/power/cpupower/cpupower --cpu all frequency-set --freq 2200MHz
#sudo /home/yans3/linux_mn_il/tools/power/cpupower/cpupower --cpu all frequency-info | grep "current CPU frequency"

#sudo /home/yans3/cpupower/cpupower --cpu all frequency-set --freq 2200MHz
#sudo /home/yans3/cpupower/cpupower --cpu all frequency-info | grep "current CPU frequency"
sudo cpupower --cpu all frequency-set --freq 2200MHz
sudo cpupower --cpu all frequency-info | grep "current CPU frequency"
sudo sh -c 'echo 0 > /sys/devices/system/cpu/cpufreq/boost'
echo "disable hyperthreading"
sudo sh -c "echo off > /sys/devices/system/cpu/smt/control"
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
