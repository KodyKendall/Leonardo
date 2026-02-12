#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Read instance name from config
INSTANCE_NAME=$(jq -r '.instance_name' "$PROJECT_ROOT/.leonardo/instance.json")

if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "null" ]; then
    echo "Error: Could not read instance_name from .leonardo/instance.json"
    exit 1
fi

S3_BUCKET="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}"

# Find the latest backup (matches storage_latest.zip and storage_weekly_*.zip)
echo "Finding latest backup for ${INSTANCE_NAME}..."
LATEST_BACKUP=$(aws s3 ls "$S3_BUCKET/" | grep storage_ | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "Error: No storage backups found in $S3_BUCKET"
    exit 1
fi

echo "Latest backup: $LATEST_BACKUP"

# Check if container is running
if ! docker compose -f "$PROJECT_ROOT/docker-compose.yml" ps llamapress --status running -q 2>/dev/null | grep -q .; then
    echo "Error: llamapress container is not running. Start it first with docker compose up -d"
    exit 1
fi

# Warn before overwriting
echo ""
echo "WARNING: This will overwrite storage files in the llamapress container's named volume."
read -p "Do you want to continue? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Download the backup
TEMP_DIR=$(mktemp -d)
TEMP_FILE="$TEMP_DIR/storage_backup_restore.zip"
echo "Downloading $LATEST_BACKUP..."
aws s3 cp "$S3_BUCKET/$LATEST_BACKUP" "$TEMP_FILE"

# Unzip to temp directory
echo "Extracting backup..."
unzip -o "$TEMP_FILE" -d "$TEMP_DIR/"

# Copy into the container's named volume
echo "Copying storage into container..."
docker compose -f "$PROJECT_ROOT/docker-compose.yml" cp "$TEMP_DIR/storage/." llamapress:/rails/storage/

# Clean up
rm -rf "$TEMP_DIR"

echo "Done! Storage restored from $LATEST_BACKUP"