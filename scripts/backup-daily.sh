#!/bin/bash
# scripts/backup-daily.sh
# Daily backup script for Disaster PI using Restic. See docs/user-guide.md for setup instructions.
# Add to crontab: 0 4 * * * /opt/disaster-pi/scripts/backup-daily.sh (Daily at 4am)
set -e

# --- Configuration ---
USB_MOUNT="/mnt/usb_backup"
REPO_PATH="$USB_MOUNT/disaster-pi-repo"
PASSWORD_FILE="/opt/disaster-pi/secrets/restic_pw"
PROJECT_DIR="/opt/disaster-pi"

# Check if USB is mounted
if ! mountpoint -q "$USB_MOUNT"; then
	echo "❌ USB not mounted at $USB_MOUNT. Aborting."
	exit 1
fi

echo "--- 🛡️ Starting Disaster Backup ---"

# 1. Database Dump (Critical for Consistency)
# We dump the DB to a file, so Restic backs up a clean SQL file instead of raw binary data.
echo "[+] Dumping Databases..."
docker compose -f $PROJECT_DIR/compose.yaml exec -t postgres pg_dumpall -c -U admin >"$PROJECT_DIR/backups/full_db_dump.sql"

# 2. Bootstrap Safety (Save the tool with the data)
# If the 'restic' binary isn't on the USB, copy it there.
# This ensures you can restore even if you can't 'apt install' later.
if [ ! -f "$USB_MOUNT/restic_binary" ]; then
	echo "[+] Copying Restic binary to USB for emergency bootstrap..."
	cp "$(which restic)" "$USB_MOUNT/restic_binary"
fi

# Copy the restore script to USB so we can run it from there in a disaster
echo "[+] Copying restore script to USB..."
cp "$PROJECT_DIR/scripts/restore-backup.sh" "$USB_MOUNT/restore-backup.sh"

# 3. Restic Backup
# Exclude the raw pgdata (since we have the dump)
echo "[+] Running Restic..."
restic -r "$REPO_PATH" --password-file "$PASSWORD_FILE" backup "$PROJECT_DIR" \
	--exclude "$PROJECT_DIR/pgdata" \
	--tag "daily-auto"

# 4. Prune Old Backups (Keep last 7 days, 4 weeks)
echo "[+] Pruning old snapshots..."
restic -r "$REPO_PATH" --password-file "$PASSWORD_FILE" forget --keep-daily 7 --keep-weekly 4 --prune

echo "✅ Backup Complete!"
