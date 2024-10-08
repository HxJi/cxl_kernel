#!/bin/bash

# get latency and their average among all VMs
if [ -z "$1" ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

# extract cpu data from pidstat
awk 'NR>2 {print $9}' $1/ksmd_cpu_stat.csv > output1.txt

# skip the first row of output1 and calculate average
# filter out the zero values
awk 'NR > 1 && $1 != 0 { sum += $1; count++ } END { if (count > 0) print "Average:", sum / count; else print "No data to compute" }' output1.txt

# awk 'NR > 1 { sum += $1; count++ } END { if (count > 0) print "Average:", sum / count; else print "No data to compute" }' output1.txt

rm output1.txt


#awk 'NR>2 {print $9}' $1/vicitm_kvm_cpu_stat.csv > output2.txt
#awk 'NR>2 {print $9}' $1/normal_kvm_cpu_stat.csv > output3.txt

# Combine the output files column-wise
#paste output1.txt output2.txt output3.txt > $1/combined_cpu_output.txt

# Cleaning up individual output files (optional)
#rm output1.txt output2.txt output3.txt
