#!/bin/sh
if [ "$IFACE" = "eth0" ]; then
    echo "Interface eth0 is up! triggering update..." >> /opt/disaster-pi/logs/netplan-script.log
    # Run in background with nohup so we don't block the network stack
    nohup /opt/disaster-pi/scripts/run-updates.sh > /dev/null 2>&1 &
fi