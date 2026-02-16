#!/usr/bin/env bash
# 
# run-updates.sh
#
# Description:
#	This script updates the system
#

LOGFILE="/opt/disaster-pi/logs/update.log"
AI=true

echo "Starting updates at $(date)" >> $LOGFILE

{
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt autoremove -y
} >> $LOGFILE 2>&1

echo "Updating Docker Images" >> $LOGFILE

cd /opt/disaster-pi || exit

sudo docker compose -f compose.yaml pull >> $LOGFILE 2>&1

if [[ $AI ]]; then
	sudo docker compose -f compose.ai.yaml pull >> $LOGFILE 2>&1
	echo "Updating containers as needed..." >> $LOGFILE
	sudo docker compose -f compose.yaml -f compose.ai.yaml up -d >> $LOGFILE 2>&1
else
	echo "Updating containers as needed...">> $LOGFILE
	sudo docker compose -f compose.yaml up -d >> $LOGFILE 2>&1
fi
