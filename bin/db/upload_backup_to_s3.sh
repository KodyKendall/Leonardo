#!/bin/bash
set -e

META_FILE=".leonardo/instance.json"
LOCAL_BACKUP="backups/llamapress_manual_latest.sql.gz"

# Check instance metadata exists
if [ ! -f "$META_FILE" ]; then
  echo "❌ Error: $META_FILE not found."
  exit 1
fi

INSTANCE_NAME=$(jq -r '.instance_name' $META_FILE)

if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "null" ]; then
  echo "❌ Error: instance_name missing in $META_FILE"
  exit 1
fi

# Check local backup exists
if [ ! -f "$LOCAL_BACKUP" ]; then
  echo "❌ Error: $LOCAL_BACKUP not found. Run bin/db/backup.sh first."
  exit 1
fi

S3_PATH="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}/llamapress_manual_latest.sql.gz"

echo "📤 Uploading $LOCAL_BACKUP to S3..."
echo "📍 Target: $S3_PATH"

aws s3 cp "$LOCAL_BACKUP" "$S3_PATH" --storage-class STANDARD_IA

echo "✅ Upload complete!"
