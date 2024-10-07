#!bin/bash
python3 cpu_online.py -s 17 -e 63
python3 cpu_online.py -s 48 -e 63
sudo sh -c 'echo 1 > /sys/devices/system/cpu/cpufreq/boost'
# bash lock_cpu_freq.sh
python3 mem_online.py -n 0 -s 64
python3 mem_online.py -n 1 -s 64
# sudo setpci -s 98:00.1 COMMAND=0x02
echo "turn off ksm"
sudo service ksm stop
sudo service ksmtuned stop
grep . /sys/kernel/mm/ksm/*
