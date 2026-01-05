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

S3_PATH="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}/llamapress_manual_latest.sql.gz"

echo ""
echo "⚠️  WARNING: This will DESTROY all existing data in the database!"
echo "   Instance: ${INSTANCE_NAME}"
echo "   Database: llamapress_production"
echo ""
read -p "Are you sure you want to continue? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "❌ Restore cancelled."
  exit 0
fi

echo ""
echo "🔵 Starting S3 restore for instance: ${INSTANCE_NAME}"
echo "📥 Download source: ${S3_PATH}"
echo "⏱️  Start: $(date +%H:%M:%S)"

START=$(date +%s)

aws s3 cp "$S3_PATH" - \
  | gunzip \
  | docker compose exec -T db psql -U postgres llamapress_production

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Restore complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"
