#!/usr/bin/env bash
# 
# run-updates.sh
#
set -euo pipefail
LOGFILE="/opt/disaster-pi/logs/update.log"
INSTALL_DIR="/opt/disaster-pi"

if [ -f "$INSTALL_DIR/.env" ]; then
    source "$INSTALL_DIR/.env"
fi

echo "Starting updates at $(date)" >> "$LOGFILE"

# --- 1. System Updates ---
{
	export DEBIAN_FRONTEND=noninteractive
	sudo apt-get update -y -q
	sudo apt-get upgrade -y -q
	sudo apt-get autoremove -y -q
} >> "$LOGFILE" 2>&1

# --- 2. Code Updates (Git) ---
if [[ -n "${GITPATH:-}" ]] && [[ -d "$GITPATH" ]]; then
    echo "Checking for updates in $GITPATH..." >> "$LOGFILE"
    
    # Fix "dubious ownership" error since script runs as root but repo is likely user-owned
    git config --global --add safe.directory "$GITPATH"

    if git -C "$GITPATH" pull --ff-only >> "$LOGFILE" 2>&1; then
        echo "Git repo updated. Syncing config to $INSTALL_DIR..." >> "$LOGFILE"
        
        # Sync updated config files to the production directory
        # We use rsync or cp to update the Docker configs and scripts
        cp -r "$GITPATH/docker/"* "$INSTALL_DIR/docker/"
        cp -r "$GITPATH/scripts/"* "$INSTALL_DIR/scripts/"
        cp -r "$GITPATH/homepage/"* "$INSTALL_DIR/homepage/"
        # Note: We do NOT copy .env or data directories to avoid overwriting secrets/data
        
        # Re-apply executable permissions on scripts
        chmod +x "$INSTALL_DIR/scripts/"*.sh
        
        echo "Sync complete." >> "$LOGFILE"
    else
        echo "Git pull failed (or up to date). Skipping sync." >> "$LOGFILE"
    fi
else
    echo "GITPATH not set or invalid. Skipping code update." >> "$LOGFILE"
fi

# --- 3. Container Updates ---
echo "Updating Docker Images" >> "$LOGFILE"

cd "$INSTALL_DIR" || exit 1
sudo docker compose -f compose.yaml pull >> "$LOGFILE" 2>&1

if [[ "$ENABLE_AI" == "true" ]]; then
    sudo docker compose -f compose.ai.yaml pull >> "$LOGFILE" 2>&1
    echo "Updating containers (AI Enabled)..." >> "$LOGFILE"
    # Re-launch stack to apply any changes from the synced compose files
    sudo docker compose -f compose.yaml -f compose.ai.yaml up -d >> "$LOGFILE" 2>&1
else
    echo "Updating containers (Standard)..." >> "$LOGFILE"
    sudo docker compose -f compose.yaml up -d >> "$LOGFILE" 2>&1
fi