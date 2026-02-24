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

S3_BUCKET="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}"

# Database configurations (same as backup_s3.sh)
DATABASES=("llamapress_production" "llamabot_production")
DB_USER="postgres"

# Check for --pick flag to select a specific backup
PICK_BACKUP=false
if [ "$1" = "--pick" ] || [ "$1" = "-p" ]; then
  PICK_BACKUP=true
fi

SELECTED_SUFFIX="_latest"

if [ "$PICK_BACKUP" = true ]; then
  echo ""
  echo "🔍 Fetching available backups for instance: ${INSTANCE_NAME}"
  echo ""

  # List all backups for the first database to get available timestamps
  SAMPLE_DB="${DATABASES[0]}"
  BACKUPS=$(aws s3 ls "${S3_BUCKET}/${SAMPLE_DB}_" 2>/dev/null | grep -E '\.sql\.gz$' | awk '{print $4}' | sed "s/${SAMPLE_DB}_//" | sed 's/\.sql\.gz$//' | sort -r)

  if [ -z "$BACKUPS" ]; then
    echo "❌ No backups found in S3 for this instance."
    exit 1
  fi

  echo "Available backups:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Create array and display options
  BACKUP_ARRAY=()
  INDEX=1
  while IFS= read -r backup; do
    BACKUP_ARRAY+=("$backup")
    if [ "$backup" = "latest" ]; then
      echo "  $INDEX) latest (most recent backup)"
    else
      # Format timestamp for readability (assumes format like 20240115_143022)
      FORMATTED=$(echo "$backup" | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/' | sed 's/ \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/ \1:\2:\3/')
      echo "  $INDEX) $backup ($FORMATTED)"
    fi
    INDEX=$((INDEX + 1))
  done <<< "$BACKUPS"

  echo ""
  read -p "Select backup number (1-${#BACKUP_ARRAY[@]}): " SELECTION

  if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#BACKUP_ARRAY[@]}" ]; then
    echo "❌ Invalid selection."
    exit 1
  fi

  SELECTED_SUFFIX="_${BACKUP_ARRAY[$((SELECTION - 1))]}"
  echo ""
  echo "📦 Selected backup: ${BACKUP_ARRAY[$((SELECTION - 1))]}"
fi

echo ""
echo "⚠️  WARNING: This will DESTROY all existing data in the following databases!"
echo "   Instance: ${INSTANCE_NAME}"
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
echo "🔵 Starting S3 restore for instance: ${INSTANCE_NAME}"
echo "⏱️  Start: $(date +%H:%M:%S)"

START=$(date +%s)

# Stop services to prevent connections
echo "🛑 Stopping llamapress and llamabot services..."
docker compose stop llamapress llamabot

sleep 2

# Restore each database
for DB_NAME in "${DATABASES[@]}"; do
  S3_PATH="${S3_BUCKET}/${DB_NAME}${SELECTED_SUFFIX}.sql.gz"

  # Check if backup exists in S3
  if ! aws s3 ls "$S3_PATH" > /dev/null 2>&1; then
    echo "⚠️  Skipping ${DB_NAME}: No backup found at ${S3_PATH}"
    continue
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  Restoring: ${DB_NAME}"
  echo "📥 Source: ${S3_PATH}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  DB_START=$(date +%s)

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

  DB_END=$(date +%s)
  DB_DURATION=$((DB_END - DB_START))
  echo "✅ ${DB_NAME} restored in ${DB_DURATION}s"
done

# Restart services
echo ""
echo "🚀 Restarting services..."
docker compose up -d llamapress llamabot

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All restores complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"
