#!/bin/bash
# scripts/freeze-images.sh
# Saves all Disaster Pi docker images to a single offline archive.

BACKUP_DIR="/opt/disaster-pi/backups"
PROJECT_DIR="/opt/disaster-pi"
TIMESTAMP=$(date +%Y%m%d)
ARCHIVE_NAME="disaster-pi-airgap-images-$TIMESTAMP.tar"

mkdir -p "$BACKUP_DIR"

echo "--- 🧊 Freezing System State ---"
echo "Identifying active images..."

# Get all images defined in the compose stack
# We use 'docker compose config' to ensure we only get the ones we care about
IMAGES=$(docker compose -f "$PROJECT_DIR/docker/compose.yaml" -f "$PROJECT_DIR/docker/compose.ai.yaml" config --images)

echo "Detected Images:"
echo "$IMAGES"

echo "--------------------------------"
echo "Saving to $BACKUP_DIR/$ARCHIVE_NAME..."
echo "This will take a few minutes. Go check your solar panels."

# Save all images into one tarball
docker save -o "$BACKUP_DIR/$ARCHIVE_NAME" "$IMAGES"

echo "✅ Backup Complete. Size: $(du -h "$BACKUP_DIR/$ARCHIVE_NAME" | cut -f1)"
echo "To restore on a fresh Pi (No Internet needed):"
echo "  docker load -i $ARCHIVE_NAME"
