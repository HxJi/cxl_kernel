#!bin/bash

# Run Redis and Memcached with YCSB as the workloads among VMs
# Also Include KSM on/off
# Usage: ./run_ycsb.sh [ksm_opt] [qps] [workload] [database]

KSM_ON=$1
QPS=$2
WORKLOAD=$3
DATABASE=$4

OUTPUT_FOLDER=$PWD/result/$WORKLOAD-$QPS-$KSM_ON-`date +%d-%H-%M`
mkdir -p $OUTPUT_FOLDER

KSM=`pgrep ksmd`
VICTIM_CORE=3

echo "ksmd: ${KSM}, victim core: ${VICTIM_CORE}"

# Pin kernel process to core
# bash ../vm_control.sh 1
# echo "Wait for 30 seconds until VMs are ready"
# sleep 30

# Loginto each VM and run YCSB with Redis or Memcached
awk 'NR % 4 == 0 {print $0}' vm_ip_all > vm_ip_server
awk 'NR % 4 != 0 { print $0 }' vm_ip_all > vm_ip_client

echo "********** Load Phase**********"

# parallel-ssh -h vm_ip_client -t 0 -l root -i 'echo $(sed "${((LINENO-1)%4)+1}q;d" vm_ip_server)"'
declare -a pids
# this vcpupin doesn't really work for some reasons
# for i in {0..15}
# do
#     virsh vcpupin client$i 0 $i
# done
# # use taskset instead
# for i in {0..15}
# do
#     sudo taskset -cp $i $(pgrep -f "client$i")
# done

if [ $DATABASE == "redis" ]; then
    parallel-ssh -h vm_ip_server  -t 0 -l root -i \
    "cd /root/radio_benchmark/ycsb/; \
    bash bin/ycsb.sh load redis -s  -p 'redis.host=127.0.0.1' -P 'workloads/workload${WORKLOAD}'  -P configs/config-load.dat > redis_load.txt;"
elif [ $DATABASE == "memcached" ]; then
    parallel-ssh -h vm_ip_server -t 0 -l root -i \
    "cd /root/radio_benchmark/ycsb/; \
	bash bin/ycsb.sh load memcached -s -p "memcached.hosts=0.0.0.0:11211" -P "workloads/workload${WORKLOAD}"  -P configs/config-load.dat > memcached_load.txt;"
fi

for pid in ${pids[*]}; do
    echo "waiting on ${pid}"
    wait $pid
done

if [ $KSM_ON -eq 0 ]; then
    echo "KSM is off"
    bash ksm_control.sh 0
else
    echo "KSM is on"
    sudo taskset -cp $VICTIM_CORE $(pgrep ksmd)
    for i in {0..15}
    do
	    virsh vcpupin client$i 0 $i
    done

    bash ksm_control.sh 1
    bash ksm_stat.sh "$OUTPUT_FOLDER/ksm_stat.csv"&
    KSM_STAT_PID=$!
fi

# make sure KSMD running
sleep 1

echo "********** Run Phase**********"
declare -a runpids

if [ $DATABASE == "redis" ]; then
    for i in {0..15}
    do
	    virsh vcpupin client$i 0 $((i))
    done
    
    for i in {0..15}
    do
	    sudo taskset -cp $((i)) $(pgrep -f "client$i")
    done

    sudo taskset -c 16 pidstat -p $(pgrep ksmd) -u 1 > $OUTPUT_FOLDER/ksmd_cpu_stat.csv &
    CPU_STAT_PID=$!
    sudo taskset -c 16 pidstat -p $(pgrep -f "client7") -u 1 > $OUTPUT_FOLDER/vicitm_kvm_cpu_stat.csv &
    VICTIM_CPU_STAT_PID=$!
    sudo taskset -c 16 pidstat -p $(pgrep -f "client15") -u 1 > $OUTPUT_FOLDER/normal_kvm_cpu_stat.csv &
    NORMAL_CPU_STAT_PID=$!

    for ((i=1; i<=4; i++)); do
        client_ips=$(sed -n "$((3*(i-1)+1)),$((3*i))p" vm_ip_client)
        server_ip=$(sed -n "${i}p" vm_ip_server)
        echo "client_ips: ${client_ips}"
        echo "server_ip: ${server_ip}"
        parallel-ssh -H "$client_ips" -t 0 -l root -i \
        "cd /root/radio_benchmark/ycsb/; \
        bash bin/ycsb.sh run redis -s  -p 'redis.host=$server_ip' -P 'workloads/workload${WORKLOAD}' -P configs/config-run.dat -target $QPS -threads 1 > redis_run.txt;" &
        runpids[$i-1]=$!
        echo "pids: ${runpids[*]}"
    done
elif [ $DATABASE == "memcached" ]; then
    parallel-ssh -h vm_ip_all -t 0 -l root -i \
    "cd /root/radio_benchmark/ycsb/; \
	bash bin/ycsb.sh load memcached -s -p "memcached.hosts=0.0.0.0:11211" -P "workloads/workload${WORKLOAD}" -P configs/config-run.dat -target $QPS > memcached_run.txt; \
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches';"
fi

for pid in ${runpids[*]}; do
    echo "waiting on ${pid}"
    wait $pid
done

if [ $KSM_ON -eq 1 ]; then
    echo "KSM is off"
    bash ksm_control.sh 0
fi

if [ $KSM_ON -eq 2 ]; then
    echo "KSM is off"
    bash ksm_control.sh 0
fi

# sudo kill -9 $PERF_PID
sudo kill -9 $CPU_STAT_PID
sudo kill -9 $VICTIM_CPU_STAT_PID
sudo kill -9 $NORMAL_CPU_STAT_PID

# sudo pkill -f "perf"
sudo pkill -f "pidstat"
if [ $KSM_ON -eq 1 ]; then
    sudo kill -9 $KSM_STAT_PID
fi

if [ $DATABASE == "redis" ]; then
    parallel-ssh -h vm_ip_all -t 0 -l root -i \
    " /usr/bin/redis-cli FLUSHALL; \
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches';"
fi

echo "********** Copy Results **********"
i=0
j=0
if [ $DATABASE == "redis" ]; then
    while read -r host; do 
        scp "root@${host}:/root/radio_benchmark/ycsb/redis_run.txt" "$OUTPUT_FOLDER/redis_run_${j}.txt"
		# find the throughput
		awk -F', ' '/Throughput\(ops\/sec\)/{print $3}' "$OUTPUT_FOLDER/redis_run_${j}.txt" >> "$OUTPUT_FOLDER/redis_throughput.txt"
        awk -F', ' '/\[READ\], 99thPercentileLatency\(us\)/{print $3}'    "$OUTPUT_FOLDER/redis_run_${j}.txt" >> "$OUTPUT_FOLDER/redis_read.txt"
        awk -F', ' '/\[UPDATE\], 99thPercentileLatency\(us\)/{print $3}'  "$OUTPUT_FOLDER/redis_run_${j}.txt" >> "$OUTPUT_FOLDER/redis_update.txt"
        awk -F', ' '/\[INSERT\], 99thPercentileLatency\(us\)/{print $3}'  "$OUTPUT_FOLDER/redis_run_${j}.txt" >> "$OUTPUT_FOLDER/redis_insert.txt"
        j=$((j+1))
    done < vm_ip_client
elif [ $DATABASE == "memcached" ]; then
    while read -r host; do
        scp "root@${host}:/root/radio_benchmark/ycsb/memcached_run.txt" "$OUTPUT_FOLDER/memcached_run_${j}.txt"
        awk -F', ' '/\[READ\], 99thPercentileLatency\(us\)/{print $3}'    "$OUTPUT_FOLDER/memcached_run_${j}.txt" >> "$OUTPUT_FOLDER/memcached_read.txt"
        awk -F', ' '/\[UPDATE\], 99thPercentileLatency\(us\)/{print $3}'  "$OUTPUT_FOLDER/memcached_run_${j}.txt" >> "$OUTPUT_FOLDER/memcached_update.txt"
        awk -F', ' '/\[INSERT\], 99thPercentileLatency\(us\)/{print $3}'  "$OUTPUT_FOLDER/memcached_run_${j}.txt" >> "$OUTPUT_FOLDER/memcached_insert.txt"
        j=$((j+1))
    done < vm_ip_client
fi

# sudo bash ksm_control.sh 0
# bash ../vm_control.sh 0
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
