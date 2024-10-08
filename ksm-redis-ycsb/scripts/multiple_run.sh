#!bin/bash

for dataset in a b c d; do
    for qps in {1500..2500..500}; do
        bash run_ycsb_pair.sh 1 $qps $dataset redis
    done
    
    #for qps in {1500..2500..500}; do
#	bash run_ycsb_pair.sh 0 $qps $dataset redis
 #   done
  #  for qps in {1500..2500..500}; do
#	bash run_ycsb_pair.sh 1 $qps $dataset redis
 #   done
done
