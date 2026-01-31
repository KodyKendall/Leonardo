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

# Check if pv is available for progress visualization
if command -v pv &> /dev/null; then
  docker compose exec -T db pg_dump -U postgres llamapress_production \
    | pv -s "$DB_SIZE" -N "Dumping " \
    | gzip \
    | pv -N "Uploading" \
    | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA
else
  echo "ℹ️  Note: Install 'pv' for progress bars (apt install pv)"

  # Run backup in background and show spinner
  docker compose exec -T db pg_dump -U postgres llamapress_production \
    | gzip \
    | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA &

  BACKUP_PID=$!
  spin $BACKUP_PID
  wait $BACKUP_PID
fi

END=$(date +%s)
DURATION=$((END - START))

# Create a timestamped copy for archival
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TIMESTAMPED_NAME="llamapress_${TIMESTAMP}.sql.gz"
echo ""
echo "📋 Creating timestamped copy: ${TIMESTAMPED_NAME}"
aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" "${S3_BUCKET}/${TIMESTAMPED_NAME}" --quiet

echo ""
echo "✅ Backup complete in ${DURATION} seconds"
echo "📍 Latest:      ${S3_BUCKET}/${BACKUP_NAME}"
echo "📍 Timestamped: ${S3_BUCKET}/${TIMESTAMPED_NAME}"
echo "⏱️  End: $(date +%H:%M:%S)"