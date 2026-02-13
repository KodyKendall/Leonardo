#!/bin/bash
# Note: We intentionally do NOT use set -e here to ensure cleanup always runs
# and errors are reported gracefully.

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Read instance name from config
INSTANCE_NAME=$(jq -r '.instance_name' "$PROJECT_ROOT/.leonardo/instance.json")

if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "null" ]; then
    echo "❌ Error: Could not read instance_name from .leonardo/instance.json"
    exit 1
fi

# S3 base path
S3_BASE="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}"

# Temp directory for staging the backup
TEMP_DIR=$(mktemp -d)
BACKUP_FILE="$TEMP_DIR/storage_backup.zip"

# Ensure cleanup happens even on failure
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

BACKUP_SUCCESS=true

# Copy storage from the Docker named volume to a temp directory on the host
echo "📦 Copying storage from container..."
if ! docker compose -f "$PROJECT_ROOT/docker-compose.yml" cp llamapress:/rails/storage "$TEMP_DIR/storage"; then
    echo "❌ Failed to copy storage from container"
    BACKUP_SUCCESS=false
fi

if [ "$BACKUP_SUCCESS" = true ]; then
    # Zip the copied storage folder
    echo "🗜️  Zipping storage folder..."
    cd "$TEMP_DIR"
    if ! zip -r "$BACKUP_FILE" storage/; then
        echo "❌ Failed to create zip archive"
        BACKUP_SUCCESS=false
    fi
fi

if [ "$BACKUP_SUCCESS" = true ]; then
    # Sanity check: warn if backup is suspiciously small (< 1KB)
    BACKUP_SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE" 2>/dev/null)
    if [ "$BACKUP_SIZE" -lt 1024 ]; then
        echo "⚠️  WARNING: Backup file is only ${BACKUP_SIZE} bytes - this may indicate empty storage!"
    else
        echo "📊 Backup size: $(numfmt --to=iec $BACKUP_SIZE 2>/dev/null || echo "${BACKUP_SIZE} bytes")"
    fi

    # Always upload to _latest (overwrites previous)
    S3_LATEST="${S3_BASE}/storage_latest.zip"
    echo "☁️  Uploading to $S3_LATEST..."
    if ! aws s3 cp "$BACKUP_FILE" "$S3_LATEST"; then
        echo "❌ Failed to upload storage backup to S3"
        BACKUP_SUCCESS=false
    fi
fi

if [ "$BACKUP_SUCCESS" = true ]; then
    # On Mondays, also save a weekly versioned backup
    DAY_OF_WEEK=$(date +%u)
    if [ "$DAY_OF_WEEK" = "1" ]; then
        S3_WEEKLY="${S3_BASE}/storage_weekly_$(date +%Y%m%d).zip"
        echo "📅 Monday - also uploading weekly backup to $S3_WEEKLY..."
        if ! aws s3 cp "$BACKUP_FILE" "$S3_WEEKLY"; then
            echo "⚠️  Weekly backup upload failed (daily backup succeeded)"
        fi
    fi

    echo "✅ Storage backup complete!"
else
    echo "❌ Storage backup FAILED"
    exit 1
fi
