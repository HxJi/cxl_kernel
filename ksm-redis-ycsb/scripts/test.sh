#!bin/bash

sudo taskset -c 16 pidstat -p $(pgrep -f "client7") -u 1