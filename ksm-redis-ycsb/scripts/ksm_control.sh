#!bin/bash

if [ $1 -eq 0 ];
then
    echo "turn off ksm"
    sudo service ksm stop
    sudo service ksmtuned stop
    sudo sh -c "echo 0 > /sys/kernel/mm/ksm/run"
    grep . /sys/kernel/mm/ksm/*
fi

if [ $1 -eq 1 ];
then
    echo "turn on ksm"
    sudo service ksm start
    sudo service ksmtuned start
    sudo sh -c "echo 1 > /sys/kernel/mm/ksm/run"
    grep . /sys/kernel/mm/ksm/*
fi

# KSM configuration file is at /etc/ksmtuned.conf

# How long ksmtuned should sleep between tuning adjustments
# KSM_MONITOR_INTERVAL=60

# Millisecond sleep between ksm scans for 16Gb server.
# Smaller servers sleep more, bigger sleep less.
# KSM_SLEEP_MSEC=10

# KSM_NPAGES_BOOST=300
# KSM_NPAGES_DECAY=-50
# KSM_NPAGES_MIN=64
# KSM_NPAGES_MAX=1250

# KSM_THRES_COEF=99
# KSM_THRES_CONST=2048

# uncomment the following if you want ksmtuned debug info

# LOGFILE=/var/log/ksmtuned
# DEBUG=1