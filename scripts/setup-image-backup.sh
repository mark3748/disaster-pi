#!/bin/bash
# scripts/setup-image-backup.sh
# Installs RonR's image-backup tool and runs the initial backup.

set -e

# --- Configuration ---
USB_MOUNT="${1:-/mnt/usb_backup}"
IMAGE_PATH="$USB_MOUNT/disaster-pi-full.img"
REPO_URL="https://github.com/seamusdemora/RonR-RPi-image-utils.git"
TEMP_DIR="/tmp/ronr-image-utils"

# --- Checks ---
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root (sudo ./scripts/setup-image-backup.sh)"
	exit 1
fi

if ! mountpoint -q "$USB_MOUNT"; then
	echo "❌ USB not mounted at $USB_MOUNT. Please mount your backup drive first."
	exit 1
fi

echo "--- 🛠️ Installing image-backup tool ---"

# 1. Install Dependencies
apt-get update && apt-get install -y git rsync

# 2. Clone & Install
echo "[+] Cloning repository..."
rm -rf "$TEMP_DIR"
git clone "$REPO_URL" "$TEMP_DIR"

echo "[+] Installing binary to /usr/local/sbin..."
install -m 755 "$TEMP_DIR/image-backup" /usr/local/sbin/image-backup

# 3. Cleanup
echo "[+] Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "✅ Installation Complete."
echo ""

# 4. Launch Initial Backup
if [ -f "$IMAGE_PATH" ]; then
	echo "⚠️  An image file already exists at: $IMAGE_PATH"
	echo "Skipping initial creation."
else
	echo "--- 💿 Starting Initial Image Creation ---"
	echo "You will be asked for:"
	echo "  1. Image file path (Default is correct, just hit Enter if prompted)"
	echo "  2. Initial size (Hit Enter for minimum)"
	echo "  3. Added space (Type '2048' for 2GB of room for updates)"
	echo ""
	read -r -p "Press Enter to launch image-backup..."

	# We pass the path to save typing, but it will still ask for size parameters
	/usr/local/sbin/image-backup "$IMAGE_PATH"
fi
