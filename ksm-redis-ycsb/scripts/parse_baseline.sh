#!/bin/bash

# get latency and their average among all VMs
if [ -z "$1" ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

# baseline data only print out average
for dir in "$1"/*; do
    if [ -d "$dir" ]; then
        basename=$(basename "$dir")
        # directory starting with d
        if [[ $basename == d* ]]; then
            paste "$dir"/redis_read.txt "$dir"/redis_insert.txt "$dir"/redis_throughput.txt > "$dir"/output.txt
        else
            paste "$dir"/redis_read.txt "$dir"/redis_update.txt "$dir"/redis_throughput.txt > "$dir"/output.txt
        fi

        # paste "$dir"/redis_read.txt "$dir"/redis_insert.txt "$dir"/redis_throughput.txt > "$dir"/output.txt
        
        awk '{ for (i=1; i<=NF; ++i) sum[i]+=$i; if (NF>maxNF) maxNF=NF; } END { for (i=1; i<=maxNF; ++i) printf "%.2f\t", sum[i]/NR; }' "$dir"/output.txt >> "$dir"/output.txt
        
        cat "$dir"/output.txt | tail -n 1
	echo ""
    fi
done

