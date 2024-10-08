#!bin/bash

# Turn on/off the VMs
# Usage: ./vm_control.sh [0|1]

# Turn on the VMs and Pin them to each core
if [ $1 -eq 1 ];
then
  echo "start VMs"
  for i in {0..15}
  do
    virsh setmaxmem client$i 4G --config
    virsh setmem client$i 4G --config
    virsh start client$i
    virsh vcpupin client$i 0 $((i))
    # virsh numatune client$i --nodeset '0'
  done
  sleep 20
  parallel-ssh -h vm_ip_all -t 0 -l root -i "sudo /usr/bin/redis-cli FLUSHALL"
  parallel-ssh -h vm_ip_all -t 0 -l root -i "sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'"
  # double pin to make sure it is pinned
  for i in {0..15}; do
	  virsh vcpupin client$i 0 $((i))
  done
  sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
else
  echo "shutdown VMs"
  for i in {0..15}
  do
    virsh shutdown client$i
  done
  sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
fi

# for i in (seq 0 16); echo "IP address of client-$i:"; virsh domifaddr client$i | grep -oP '(\d+
#    \.){3}\d+'; end
# get IPs of all virtual machines
# for i in {0..15}; do virsh domifaddr client$i | awk '/ipv4/ {print $4}'; done

# touch VMs before parallel-ssh
# for ip in $(cat root_ip); do ssh root@$ip "command_to_execute"; done
