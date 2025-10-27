#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
RESTORE_DIR="${3:-$HOME}"  # Default to user's home directory
BACKUP_NAME="$4"  # Optional: specific backup

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [restore_dir] [backup_name]"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups /home/ubuntu"
    echo "Example: $0 prod-1 s3://bucket/backups /tmp/restore project-prod-1-20251020-153022.tar.gz"
    exit 1
fi

echo "🔵 Restoring project files..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# If no backup specified, find the latest
if [ -z "$BACKUP_NAME" ]; then
    echo "📋 Finding latest backup for ${INSTANCE_NAME}..."
    LATEST=$(aws s3 ls "${S3_BUCKET}/" | grep "project-${INSTANCE_NAME}-" | sort | tail -n 1 | awk '{print $4}')
    if [ -z "$LATEST" ]; then
        echo "❌ No backups found for ${INSTANCE_NAME}"
        exit 1
    fi
    BACKUP_NAME="$LATEST"
    echo "📍 Using: ${BACKUP_NAME}"
fi

# Stream from S3 and extract
echo "📥 Downloading and extracting to ${RESTORE_DIR}..."
mkdir -p "$RESTORE_DIR"
cd "$RESTORE_DIR"

aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" - \
    | tar xzf -

# Find what was extracted (Leonardo or llamapress)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d \( -name "Leonardo" -o -name "llamapress" \) | head -n 1 | sed 's|^\./||')

if [ -z "$EXTRACTED_DIR" ]; then
    echo "❌ Could not find extracted Leonardo or llamapress folder"
    exit 1
fi

END=$(date +%s)
DURATION=$((END - START))

FULL_PATH="${RESTORE_DIR}/${EXTRACTED_DIR}"

echo "✅ Project files restored in ${DURATION} seconds"
echo "📁 Restored to: ${FULL_PATH}"
echo "⏱️  End: $(date +%H:%M:%S)"

# Show what was restored
echo ""
echo "📋 Contents:"
ls -lah "${FULL_PATH}" | head -n 15