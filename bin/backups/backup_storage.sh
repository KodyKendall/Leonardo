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

# Create timestamp and filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="storage_backup_${TIMESTAMP}.zip"
S3_PATH="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}/${BACKUP_FILE}"

# Zip storage folder
echo "Zipping storage folder..."
cd "$PROJECT_ROOT/rails"
zip -r "$BACKUP_FILE" storage/

# Upload to S3
echo "Uploading to $S3_PATH..."
aws s3 cp "$BACKUP_FILE" "$S3_PATH"

# Clean up local zip file
rm "$BACKUP_FILE"

echo "Done! Backup uploaded to $S3_PATH"
