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

DB_NAME="llamapress_production"
DB_USER="postgres"

echo ""
echo "🔵 Starting S3 restore for instance: ${INSTANCE_NAME}"
echo "📥 Download source: ${S3_PATH}"
echo "⏱️  Start: $(date +%H:%M:%S)"

START=$(date +%s)

# Stop services to prevent connections
echo "🛑 Stopping llamapress and llamabot services..."
docker compose stop llamapress llamabot

sleep 2

# Terminate existing connections
echo "🔌 Terminating existing database connections..."
docker compose exec -T db psql -U "$DB_USER" -d postgres -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true

# Drop and recreate database
echo "🗑️  Dropping database $DB_NAME..."
docker compose exec -T db dropdb -U "$DB_USER" --if-exists "$DB_NAME"

echo "🆕 Creating fresh database $DB_NAME..."
docker compose exec -T db createdb -U "$DB_USER" "$DB_NAME"

# Restore from S3
echo "📥 Restoring from S3 backup..."
aws s3 cp "$S3_PATH" - \
  | gunzip \
  | docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME"

# Restart services
echo "🚀 Restarting services..."
docker compose up -d llamapress llamabot

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Restore complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"
