#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1" 
S3_BUCKET="$2" 

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket>"
    echo "Example: $0 production-server-1 s3://my-bucket/postgres-backups"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="postgres-${INSTANCE_NAME}-${TIMESTAMP}.sql.gz"

echo "🔵 Fast Postgres Backup Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# Stream directly to S3 (no temp file)
echo "📦 Dumping and uploading to S3..."
docker compose exec -T db pg_dumpall -U postgres \
    | gzip \
    | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Backup complete in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/${BACKUP_NAME}"

# Write latest backup name to a known location for restore
echo "${BACKUP_NAME}" > /tmp/latest-postgres-backup.txt
aws s3 cp /tmp/latest-postgres-backup.txt "${S3_BUCKET}/latest-${INSTANCE_NAME}.txt"

echo "⏱️  End: $(date +%H:%M:%S)"