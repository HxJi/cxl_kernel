#!/bin/bash

# get latency and their average among all VMs
if [ -z "$1" ]; then
    echo "Usage: $0 <path>"
    exit 1
fi



# ksm case calculate the two average and their ratio 
for dir in "$1"/*; do
    if [ -d "$dir" ]; then
        basename=$(basename "$dir")

        # directory starting with d
        if [[ $basename == d* ]]; then
            paste "$dir"/redis_read.txt "$dir"/redis_insert.txt "$dir"/redis_throughput.txt > "$dir"/output.txt
        else
            paste "$dir"/redis_read.txt "$dir"/redis_update.txt "$dir"/redis_throughput.txt > "$dir"/output.txt
        fi

        # Command 1
		awk 'NR >= 4 && NR <= 6 {
			for (i = 1; i <= NF; ++i)
				sum1[i] += $i;
			if (NF > maxNF)
				maxNF = NF;
		}
		END {
			for (i = 1; i <= maxNF; ++i) {
				avg1[i] = sum1[i] / 3;
				printf "%.3f\t", avg1[i];
			}
			printf "\n";
		}' "$dir"/output.txt > avg1.txt

		# Command 2
		awk 'NR < 4 || (NR > 6 && NR <= 12) {
			for (i = 1; i <= NF; ++i)
				sum2[i] += $i;
			if (NF > maxNF)
				maxNF = NF;
		}
		END {
			getline < "avg1.txt";  # Read avg1 from the file
    		split($0, avg1);       # Split the values into avg1 array

			for (i = 1; i <= maxNF; ++i) {
				avg2[i] = sum2[i] / 9;
				printf "%.3f\t", avg2[i];
				printf "\t";
				printf "%.3f\t", avg1[i];
				printf "\t";
				printf "%.3f\t", avg1[i] / avg2[i];
				printf "\t";
			}
		}' "$dir"/output.txt >> "$dir"/output.txt


        cat "$dir"/output.txt | tail -n 1
	echo ""
    fi
done
