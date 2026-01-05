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

# Find the latest backup
echo "Finding latest backup for ${INSTANCE_NAME}..."
LATEST_BACKUP=$(aws s3 ls "$S3_BUCKET/" | grep storage_backup | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "Error: No storage backups found in $S3_BUCKET"
    exit 1
fi

echo "Latest backup: $LATEST_BACKUP"

# Check if storage folder already exists
STORAGE_PATH="$PROJECT_ROOT/rails/storage"
if [ -d "$STORAGE_PATH" ] && [ "$(ls -A "$STORAGE_PATH" 2>/dev/null)" ]; then
    echo ""
    echo "WARNING: $STORAGE_PATH already exists and contains files."
    echo "Restoring will overwrite existing files."
    read -p "Do you want to continue? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Restore cancelled."
        exit 0
    fi
fi

# Download the backup
TEMP_FILE="/tmp/storage_backup_restore.zip"
echo "Downloading $LATEST_BACKUP..."
aws s3 cp "$S3_BUCKET/$LATEST_BACKUP" "$TEMP_FILE"

# Unzip to rails directory
echo "Extracting to $STORAGE_PATH..."
unzip -o "$TEMP_FILE" -d "$PROJECT_ROOT/rails/"

# Clean up
rm "$TEMP_FILE"

echo "Done! Storage restored from $LATEST_BACKUP"