#!/usr/bin/env bash
# 
# run-updates.sh
#
# Description:
#	This script updates the system
#

LOGFILE="/opt/disaster-pi/logs/update.log"

if [ -f /opt/disaster-pi/.env ]; then
    source /opt/disaster-pi/.env
fi

echo "Starting updates at $(date)" >> $LOGFILE

{
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt autoremove -y
} >> $LOGFILE 2>&1

echo "Updating Docker Images" >> $LOGFILE

cd /opt/disaster-pi || exit

sudo docker compose -f compose.yaml pull >> $LOGFILE 2>&1

if [[ "$ENABLE_AI" == "true" ]]; then
    sudo docker compose -f compose.ai.yaml pull >> $LOGFILE 2>&1
    echo "Updating containers (AI Enabled)..." >> $LOGFILE
    sudo docker compose -f compose.yaml -f compose.ai.yaml up -d >> $LOGFILE 2>&1
else
    echo "Updating containers (Standard)..." >> $LOGFILE
    sudo docker compose -f compose.yaml up -d >> $LOGFILE 2>&1
fi