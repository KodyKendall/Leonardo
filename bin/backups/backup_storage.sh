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

# S3 base path
S3_BASE="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}"

# Local backup filename
BACKUP_FILE="storage_backup.zip"

# Zip storage folder
echo "Zipping storage folder..."
cd "$PROJECT_ROOT/rails"
zip -r "$BACKUP_FILE" storage/

# Always upload to _latest (overwrites previous)
S3_LATEST="${S3_BASE}/storage_latest.zip"
echo "Uploading to $S3_LATEST..."
aws s3 cp "$BACKUP_FILE" "$S3_LATEST"

# On Mondays, also save a weekly versioned backup
DAY_OF_WEEK=$(date +%u)
if [ "$DAY_OF_WEEK" = "1" ]; then
    S3_WEEKLY="${S3_BASE}/storage_weekly_$(date +%Y%m%d).zip"
    echo "Monday - also uploading weekly backup to $S3_WEEKLY..."
    aws s3 cp "$BACKUP_FILE" "$S3_WEEKLY"
fi

# Clean up local zip file
rm "$BACKUP_FILE"

echo "Done! Storage backup complete."
