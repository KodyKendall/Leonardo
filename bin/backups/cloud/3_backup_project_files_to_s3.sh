#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
PROJECT_DIR="${3:-$PWD}"  # Default to current directory
BACKUP_FOLDER="$4"  # Shared timestamp folder for this backup session

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [project_dir] [backup_folder]"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups /home/ubuntu/Leonardo"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups /home/ubuntu/Leonardo 20251020-153022"
    exit 1
fi

# Use provided backup folder or generate new timestamp
if [ -z "$BACKUP_FOLDER" ]; then
    BACKUP_FOLDER=$(date +%Y%m%d-%H%M%S)
    echo "⚠️  No backup folder specified, generating: ${BACKUP_FOLDER}"
fi

TIMESTAMP="$BACKUP_FOLDER"  # Keep TIMESTAMP variable for backward compatibility
BACKUP_NAME="project-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"

echo "🔵 Backing up project files..."
echo "⏱️  Start: $(date +%H:%M:%S)"
echo "📁 Project dir: ${PROJECT_DIR}"
START=$(date +%s)

# Get project folder name (Leonardo or llamapress)
PROJECT_FOLDER=$(basename "$PROJECT_DIR")

# Create tarball and stream to S3
cd "$(dirname "$PROJECT_DIR")"

tar czf - \
    --exclude="${PROJECT_FOLDER}/backups" \
    --exclude="${PROJECT_FOLDER}/.claude" \
    --exclude="${PROJECT_FOLDER}/tmp" \
    --exclude="${PROJECT_FOLDER}/log" \
    "${PROJECT_FOLDER}" \
    | aws s3 cp - "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Project files backed up in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}"

# Get size from S3 (parse ls output properly)
sleep 1
SIZE_INFO=$(aws s3 ls "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}" 2>/dev/null || echo "")
if [ -n "$SIZE_INFO" ]; then
    SIZE_BYTES=$(echo "$SIZE_INFO" | awk '{print $3}')
    SIZE_KB=$((SIZE_BYTES / 1024))
    echo "📊 Size: ${SIZE_KB}KB"
fi

echo "⏱️  End: $(date +%H:%M:%S)"

# Update latest backup timestamp at root level
TEMP_FILE=$(mktemp)
echo "${TIMESTAMP}" > "$TEMP_FILE"
aws s3 cp "$TEMP_FILE" "${S3_BUCKET}/latest-backup.txt"
rm -f "$TEMP_FILE"