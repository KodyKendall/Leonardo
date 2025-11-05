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

    # Try to read the latest-backup.txt index file
    LATEST_TIMESTAMP=$(aws s3 cp "${S3_BUCKET}/latest-backup.txt" - 2>/dev/null || echo "")

    if [ -z "$LATEST_TIMESTAMP" ]; then
        # Fallback: list all timestamp folders and get the most recent
        LATEST_TIMESTAMP=$(aws s3 ls "${S3_BUCKET}/" | grep "PRE" | awk '{print $2}' | sed 's|/||g' | sort | tail -n 1)
    fi

    if [ -z "$LATEST_TIMESTAMP" ]; then
        echo "❌ No backups found in ${S3_BUCKET}"
        exit 1
    fi

    echo "📍 Using timestamp: ${LATEST_TIMESTAMP}"

    # Find the postgres backup in this timestamp folder
    LATEST_FILE=$(aws s3 ls "${S3_BUCKET}/${LATEST_TIMESTAMP}/" | grep "postgres-" | awk '{print $4}' | head -n 1)
    if [ -z "$LATEST_FILE" ]; then
        echo "❌ No postgres backup found in ${S3_BUCKET}/${LATEST_TIMESTAMP}/"
        exit 1
    fi

    BACKUP_NAME="${LATEST_TIMESTAMP}/${LATEST_FILE}"
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
echo "   Source: ${S3_BUCKET}/${BACKUP_NAME}"

# Restore the SQL dump - show errors but suppress routine output
# Note: We keep stderr visible to catch any errors
aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" - \
    | gunzip \
    | docker compose exec -T db psql -U postgres 2>&1 \
    | grep -v "^CREATE\|^ALTER\|^SET\|^--\|^INSERT\|^COPY\|^$" || true

# Verify data was restored
echo "🔍 Verifying data restoration..."
TABLE_COUNT=$(docker compose exec -T db psql -U postgres -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' \n' || echo "0")
echo "   Found ${TABLE_COUNT} tables in database"

if [ "$TABLE_COUNT" = "0" ]; then
    echo "   ❌ WARNING: No tables found after restore! Data may not have been restored."
    echo "   Check if SQL dump exists at: ${S3_BUCKET}/${BACKUP_NAME}"
fi

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Restore complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"