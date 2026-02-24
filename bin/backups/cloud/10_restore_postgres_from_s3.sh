#!/bin/bash
set -e

# Parse arguments
S3_BUCKET="$1"
BACKUP_NAME="$2"  # Optional: specific backup name

if [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <s3_bucket> [backup_name]"
    echo "Example: $0 s3://my-bucket/postgres-backups"
    echo "Example: $0 s3://my-bucket/postgres-backups 20260224-012850/postgres-myapp-20260224-012850.sql.gz"
    exit 1
fi

# Database configurations
DATABASES=("llamapress_production" "llamabot_production")
DB_USER="postgres"

echo ""
echo "⚠️  WARNING: This will DESTROY all existing data in the following databases!"
for DB_NAME in "${DATABASES[@]}"; do
  echo "   - ${DB_NAME}"
done
echo ""
read -p "Are you sure you want to continue? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "❌ Restore cancelled."
  exit 0
fi

echo ""
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

S3_PATH="${S3_BUCKET}/${BACKUP_NAME}"

echo ""
echo "📥 Source: ${S3_PATH}"

# Stop services to prevent connections
echo "🛑 Stopping llamapress and llamabot services..."
docker compose stop llamapress llamabot 2>/dev/null || true

sleep 2

# Make sure DB is running
echo "🚀 Ensuring database is running..."
docker compose up -d db

# Wait for DB (with timeout)
echo -n "⏳ Waiting for DB"
TIMEOUT=30
ELAPSED=0
until docker compose exec -T db pg_isready -U "$DB_USER" > /dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo " ❌ Timeout!"
        exit 1
    fi
    echo -n "."
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo " ✓"

# Drop and recreate each database
for DB_NAME in "${DATABASES[@]}"; do
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  Preparing: ${DB_NAME}"

  # Terminate existing connections
  echo "🔌 Terminating existing connections..."
  docker compose exec -T db psql -U "$DB_USER" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '$DB_NAME'
      AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true

  # Drop and recreate
  echo "🗑️  Dropping ${DB_NAME}..."
  docker compose exec -T db dropdb -U "$DB_USER" --if-exists "$DB_NAME"

  echo "🆕 Creating fresh ${DB_NAME}..."
  docker compose exec -T db createdb -U "$DB_USER" "$DB_NAME"
done

# Restore the full dump (covers all databases)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Restoring from S3 backup..."
aws s3 cp "$S3_PATH" - \
    | gunzip \
    | docker compose exec -T db psql -U "$DB_USER" 2>&1 \
    | grep -Ev "^(CREATE|ALTER|SET|--|INSERT|COPY)|set_config|setval|^You are now connected|already exists|^ERROR:  (role|database)|^[[:space:]]*[0-9]+[[:space:]]*$|^$" || true

# Verify data was restored
echo ""
echo "🔍 Verifying restoration..."
for DB_NAME in "${DATABASES[@]}"; do
  TABLE_COUNT=$(docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -t -c \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" \
    2>/dev/null | tr -d ' \n' || echo "0")
  echo "   ${DB_NAME}: ${TABLE_COUNT} tables"
done

# Restart services
echo ""
echo "🚀 Restarting services..."
docker compose up -d llamapress llamabot

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Restore complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"
