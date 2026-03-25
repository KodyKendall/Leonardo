#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
BACKUP_FOLDER="$3"  # Shared timestamp folder for this backup session

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [backup_folder]"
    echo "Example: $0 production-server-1 s3://my-bucket/postgres-backups"
    echo "Example: $0 production-server-1 s3://my-bucket/postgres-backups 20251020-153022"
    exit 1
fi

# Use provided backup folder or generate new timestamp
if [ -z "$BACKUP_FOLDER" ]; then
    BACKUP_FOLDER=$(date +%Y%m%d-%H%M%S)
    echo "⚠️  No backup folder specified, generating: ${BACKUP_FOLDER}"
fi

TIMESTAMP="$BACKUP_FOLDER"  # Keep TIMESTAMP variable for backward compatibility
BACKUP_NAME="postgres-${INSTANCE_NAME}-${TIMESTAMP}.sql.gz"

echo "🔵 Fast Postgres Backup Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# Stream directly to S3 (no temp file) - save in timestamped folder
echo "📦 Dumping and uploading to S3..."
docker compose exec -T db pg_dumpall -U postgres \
    | gzip \
    | aws s3 cp - "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Backup complete in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}"

# Write latest backup timestamp to index file at root level
TEMP_FILE=$(mktemp)
echo "${TIMESTAMP}" > "$TEMP_FILE"
aws s3 cp "$TEMP_FILE" "${S3_BUCKET}/latest-backup.txt"
rm -f "$TEMP_FILE"

echo "⏱️  End: $(date +%H:%M:%S)"