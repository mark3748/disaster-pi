#!/bin/bash
# scripts/restore-backup.sh
# Restore Disaster PI from a Restic backup
set -e

# --- Configuration (with defaults) ---
USB_MOUNT="${1:-/mnt/usb_backup}"
REPO_PATH="${2:-$USB_MOUNT/disaster-pi-repo}"
PASSWORD_FILE="${3:-/opt/disaster-pi/secrets/restic_pw}"
PROJECT_DIR="${4:-/opt/disaster-pi}"

# --- Display Configuration ---
echo "--- 📋 Restore Configuration ---"
echo "USB Mount:     $USB_MOUNT"
echo "Repo Path:     $REPO_PATH"
echo "Password File: $PASSWORD_FILE"
echo "Project Dir:   $PROJECT_DIR"
echo ""

# --- Validation ---
if [ ! -d "$USB_MOUNT" ]; then
	echo "❌ USB mount point does not exist: $USB_MOUNT"
	exit 1
fi

if ! mountpoint -q "$USB_MOUNT"; then
	echo "❌ USB not mounted at $USB_MOUNT. Aborting."
	exit 1
fi

if [ ! -d "$REPO_PATH" ]; then
	echo "❌ Restic repo not found at $REPO_PATH"
	exit 1
fi

if [ ! -f "$PASSWORD_FILE" ]; then
	echo "❌ Password file not found at $PASSWORD_FILE"
	exit 1
fi

# --- Dependency Check ---
RESTIC_CMD="restic"
if ! command -v restic &>/dev/null; then
	echo "⚠️ System 'restic' not found."
	if [ -f "$USB_MOUNT/restic_binary" ]; then
		echo "✅ Found portable restic on USB. Using that."
		RESTIC_CMD="$USB_MOUNT/restic_binary"
		chmod +x "$RESTIC_CMD"
	else
		echo "❌ No restic binary found on system or USB. Cannot proceed."
		exit 1
	fi
fi

# Confirm restoration
echo "⚠️  WARNING: This will restore files from backup."
echo "This may overwrite existing data in $PROJECT_DIR"
read -r -p "Continue with restore? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
	echo "Restore cancelled."
	exit 0
fi

echo ""
echo "--- 🔄 Starting Disaster Restore ---"

# 1. List available snapshots
echo "[+] Available snapshots:"
"$RESTIC_CMD" -r "$REPO_PATH" --password-file "$PASSWORD_FILE" snapshots

echo ""
read -r -p "Enter snapshot ID to restore (or 'latest' for most recent): " snapshot_id
if [ -z "$snapshot_id" ]; then
	echo "❌ No snapshot specified. Aborting."
	exit 1
fi

# 2. Restore from Restic
echo "[+] Restoring files from snapshot: $snapshot_id"
"$RESTIC_CMD" -r "$REPO_PATH" --password-file "$PASSWORD_FILE" restore "$snapshot_id" --target /

# 3. Restore Database
echo "[+] Checking for database dump..."
DB_DUMP="$PROJECT_DIR/backups/full_db_dump.sql"

if [ ! -f "$DB_DUMP" ]; then
	echo "❌ Database dump not found. Skipping."
else
	echo "[+] Bringing up Postgres (and ONLY Postgres) to avoid lock conflicts..."
	# We target ONLY postgres so Mealie/AI don't start and lock the DB
	docker compose -f "$PROJECT_DIR/compose.yaml" up -d postgres

	echo "[+] Waiting for database to be ready..."
	# Loop until pg_isready returns success
	until docker compose -f "$PROJECT_DIR/compose.yaml" exec -T postgres pg_isready -U admin >/dev/null 2>&1; do
		echo -n "."
		sleep 1
	done
	echo ""

	echo "[+] Restoring database from $DB_DUMP..."
	# No password needed (trust auth). '-c' in dump handles the cleanup.
	docker compose -f "$PROJECT_DIR/compose.yaml" exec -T postgres psql -U admin <"$DB_DUMP"
	echo "✅ Database restored!"
fi

echo ""
echo "--- 🚀 Restarting Full Stack ---"
# Check if AI config exists and include it if present (Matches setup.sh logic)
if [ -f "$PROJECT_DIR/compose.ai.yaml" ]; then
	echo "[+] Detected AI configuration."
	docker compose -f "$PROJECT_DIR/compose.yaml" -f "$PROJECT_DIR/compose.ai.yaml" up -d
else
	docker compose -f "$PROJECT_DIR/compose.yaml" up -d
fi

echo ""
echo "✅ Restore Complete!"
echo ""
echo "Next steps:"
echo "1. Verify restored data integrity"
echo "2. Check database connections and services"
echo "3. Review any logs for errors"
