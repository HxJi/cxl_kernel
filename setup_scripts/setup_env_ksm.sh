#!bin/bash
python3 cpu_offline.py -s 17 -e 63
bash lock_cpu_freq.sh
python3 mem_offline.py -n 0 -s 32
python3 mem_offline.py -n 1 -s 32
sudo setpci -s 2a:00.1 COMMAND=0x02

# disable ksm
echo "turn off ksm"
sudo service ksm stop
sudo service ksmtuned stop
sudo sh -c "echo 0 > /sys/kernel/mm/ksm/run"
grep . /sys/kernel/mm/ksm/*

# parallel-ssh -h vm_ip_all -t 0 -l root -i "sed -i 's/recordcount=50000/recordcount=20000/g' /root/radio_benchmark/ycsb/configs/config-load.dat"
# parallel-ssh -h vm_ip_all -t 0 -l root -i "sed -i 's/operationcount=50000/operationcount=20000/g' /root/radio_benchmark/ycsb/configs/config-load.dat"

# parallel-ssh -h vm_ip_all -t 0 -l root -i "sed -i 's/recordcount=50000/recordcount=20000/g' /root/radio_benchmark/ycsb/configs/config-run.dat"
# parallel-ssh -h vm_ip_all -t 0 -l root -i "sed -i 's/operationcount=50000/operationcount=20000/g' /root/radio_benchmark/ycsb/configs/config-run.dat"
