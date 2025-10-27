#!/bin/bash
set -e

# Parse arguments
S3_BUCKET="$1"
BACKUP_NAME="$2"  # Optional: specific backup name

if [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <s3_bucket> [backup_name]"
    echo "Example: $0 s3://my-bucket/postgres-backups"
    echo "Example: $0 s3://my-bucket/postgres-backups postgres-prod-20251020-153022.sql.gz"
    exit 1
fi

echo "🔵 Fast Postgres Restore Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# If no backup specified, try to find the latest
if [ -z "$BACKUP_NAME" ]; then
    echo "📋 No backup specified, finding latest..."
    LATEST_FILE=$(aws s3 ls "${S3_BUCKET}/" | grep "postgres-" | sort | tail -n 1 | awk '{print $4}')
    if [ -z "$LATEST_FILE" ]; then
        echo "❌ No backups found in ${S3_BUCKET}"
        exit 1
    fi
    BACKUP_NAME="$LATEST_FILE"
    echo "📍 Using: ${BACKUP_NAME}"
fi

# Make sure DB is running
echo "🚀 Ensuring database is running..."
docker compose up -d db

# Wait for DB (with timeout)
echo -n "⏳ Waiting for DB"
TIMEOUT=30
ELAPSED=0
until docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo " ❌ Timeout!"
        exit 1
    fi
    echo -n "."
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo " ✓"

# Stream from S3 directly to postgres (no temp file)
echo "📥 Downloading and restoring from S3..."
aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" - \
    | gunzip \
    | docker compose exec -T db psql -U postgres > /dev/null

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Restore complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"