#!/bin/sh
INTERFACE=$1
ACTION=$2

if [ "$INTERFACE" = "eth0" ] && [ "$ACTION" = "up" ]; then
    echo "Interface eth0 is up via NM! Triggering updates..." >> /opt/disaster-pi/logs/netplan-script.log
    nohup /opt/disaster-pi/scripts/run-updates.sh > /dev/null 2>&1 &
fi