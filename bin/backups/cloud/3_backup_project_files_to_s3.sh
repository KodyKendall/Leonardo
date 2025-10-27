#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
PROJECT_DIR="${3:-$PWD}"  # Default to current directory

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [project_dir]"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups"
    echo "Example: $0 production-server-1 s3://my-bucket/project-backups /home/ubuntu/Leonardo"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
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
    --exclude="${PROJECT_FOLDER}/.git" \
    --exclude="${PROJECT_FOLDER}/backups" \
    --exclude="${PROJECT_FOLDER}/.claude" \
    --exclude="${PROJECT_FOLDER}/tmp" \
    --exclude="${PROJECT_FOLDER}/log" \
    "${PROJECT_FOLDER}" \
    | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Project files backed up in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/${BACKUP_NAME}"

# Get size from S3 (parse ls output properly)
sleep 1
SIZE_INFO=$(aws s3 ls "${S3_BUCKET}/${BACKUP_NAME}" 2>/dev/null || echo "")
if [ -n "$SIZE_INFO" ]; then
    SIZE_BYTES=$(echo "$SIZE_INFO" | awk '{print $3}')
    SIZE_KB=$((SIZE_BYTES / 1024))
    echo "📊 Size: ${SIZE_KB}KB"
fi

echo "⏱️  End: $(date +%H:%M:%S)"

# Save latest backup name
echo "${BACKUP_NAME}" > /tmp/latest-project-backup.txt
aws s3 cp /tmp/latest-project-backup.txt "${S3_BUCKET}/latest-${INSTANCE_NAME}.txt"