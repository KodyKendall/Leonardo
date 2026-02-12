#!/bin/bash
set -e

# Log to file AND terminal for both manual and cron runs (best effort)
LOG_DIR="/home/ubuntu/Leonardo/logs/backups"
LOG_FILE="$LOG_DIR/backup.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Try to enable logging, but don't fail the backup if it doesn't work
if touch "$LOG_FILE" 2>/dev/null && [ -w "$LOG_FILE" ]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
else
  echo "⚠️  Warning: Cannot write to $LOG_FILE - proceeding without file logging"
fi

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

# Database configurations
DATABASES=("llamapress_production" "llamabot_production")

echo "🔵 Starting S3 backup for instance: ${INSTANCE_NAME}"
echo "📦 Upload target: ${S3_BUCKET}/"
echo "⏱️  Start: $(date +%H:%M:%S)"

# Get estimated DB sizes for progress bar
echo "📊 Calculating database sizes..."
declare -A DB_SIZES
for DB_NAME in "${DATABASES[@]}"; do
  SIZE=$(docker compose exec -T db psql -U postgres -t -c \
    "SELECT pg_database_size('${DB_NAME}');" 2>/dev/null | tr -d ' \n\r')
  if [ -n "$SIZE" ] && [ "$SIZE" != "" ]; then
    DB_SIZES[$DB_NAME]=$SIZE
    echo "   📊 ${DB_NAME}: $(numfmt --to=iec $SIZE)"
  else
    echo "   ⚠️  ${DB_NAME}: database not found or empty, skipping"
  fi
done
echo ""

START=$(date +%s)

# Simple spinner function for progress indication
spin() {
  local pid=$1
  local delay=0.5
  local elapsed=0
  local spinchars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

  while kill -0 "$pid" 2>/dev/null; do
    for ((i=0; i<${#spinchars}; i++)); do
      if ! kill -0 "$pid" 2>/dev/null; then
        break 2
      fi
      printf "\r🔄 Backing up... %s  [%ds elapsed]" "${spinchars:$i:1}" "$elapsed"
      sleep "$delay"
      elapsed=$(( $(date +%s) - START ))
    done
  done
  printf "\r✅ Backup stream complete!              \n"
}

# Timestamp for this backup run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup each database
for DB_NAME in "${DATABASES[@]}"; do
  # Skip if database wasn't found
  if [ -z "${DB_SIZES[$DB_NAME]}" ]; then
    continue
  fi

  DB_SIZE=${DB_SIZES[$DB_NAME]}
  BACKUP_NAME="${DB_NAME}_latest.sql.gz"
  TIMESTAMPED_NAME="${DB_NAME}_${TIMESTAMP}.sql.gz"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  Backing up: ${DB_NAME}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  DB_START=$(date +%s)

  # Check if pv is available for progress visualization
  if command -v pv &> /dev/null; then
    docker compose exec -T db pg_dump -U postgres "$DB_NAME" \
      | pv -s "$DB_SIZE" -N "Dumping " \
      | gzip \
      | pv -N "Uploading" \
      | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
          --storage-class STANDARD_IA
  else
    if [ "$DB_NAME" = "${DATABASES[0]}" ]; then
      echo "ℹ️  Note: Install 'pv' for progress bars (apt install pv)"
    fi

    # Run backup in background and show spinner
    docker compose exec -T db pg_dump -U postgres "$DB_NAME" \
      | gzip \
      | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
          --storage-class STANDARD_IA &

    BACKUP_PID=$!
    spin $BACKUP_PID
    wait $BACKUP_PID
  fi

  DB_END=$(date +%s)
  DB_DURATION=$((DB_END - DB_START))

  # Create a timestamped copy for archival
  echo "📋 Creating timestamped copy: ${TIMESTAMPED_NAME}"
  aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" "${S3_BUCKET}/${TIMESTAMPED_NAME}" --quiet

  echo "✅ ${DB_NAME} backed up in ${DB_DURATION}s"
  echo "   📍 Latest:      ${S3_BUCKET}/${BACKUP_NAME}"
  echo "   📍 Timestamped: ${S3_BUCKET}/${TIMESTAMPED_NAME}"
  echo ""
done

END=$(date +%s)
DURATION=$((END - START))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All backups complete in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"