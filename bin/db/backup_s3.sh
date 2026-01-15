#!/bin/bash
set -e

META_FILE=".leonardo/instance.json"

if [ ! -f "$META_FILE" ]; then
  echo "❌ Error: $META_FILE not found. Cannot determine instance identity."
  exit 1
fi

INSTANCE_NAME=$(jq -r '.instance_name' $META_FILE)

if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "null" ]; then
  echo "❌ Error: instance_name missing in $META_FILE"
  exit 1
fi

# Your real S3 root prefix
S3_BUCKET="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}"

BACKUP_NAME="llamapress_manual_latest.sql.gz"

echo "🔵 Starting S3 backup for instance: ${INSTANCE_NAME}"
echo "📦 Upload target: ${S3_BUCKET}/${BACKUP_NAME}"
echo "⏱️  Start: $(date +%H:%M:%S)"

# Get estimated DB size for progress bar
echo "📊 Calculating database size..."
DB_SIZE=$(docker compose exec -T db psql -U postgres -t -c \
  "SELECT pg_database_size('llamapress_production');" | tr -d ' \n\r')

echo "📊 Estimated DB size: $(numfmt --to=iec $DB_SIZE)"
echo ""

START=$(date +%s)

docker compose exec -T db pg_dump -U postgres llamapress_production \
  | pv -s "$DB_SIZE" -N "Dumping " \
  | gzip \
  | pv -N "Uploading" \
  | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
      --storage-class STANDARD_IA

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "✅ Backup complete in ${DURATION} seconds"
echo "📍 S3 Path: ${S3_BUCKET}/${BACKUP_NAME}"
echo "⏱️  End: $(date +%H:%M:%S)"