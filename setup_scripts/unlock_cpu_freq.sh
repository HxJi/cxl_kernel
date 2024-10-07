#!bin/bash

sudo cpupower --cpu all frequency-set --governor ondemand
sudo sh -c 'echo 0 > /sys/devices/system/cpu/cpufreq/boost'
echo "enable hyperthreading"
sudo sh -c "echo off > /sys/devices/system/cpu/smt/control"
# sudo sh -c "echo on > /sys/devices/system/cpu/smt/control"