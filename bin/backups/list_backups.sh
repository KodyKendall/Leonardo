#!/bin/bash
# List recent S3 backups with timestamps and sizes
# Usage: bin/backups/list_backups.sh [--all]

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

META_FILE="$PROJECT_ROOT/.leonardo/instance.json"

if [ ! -f "$META_FILE" ]; then
  echo "❌ Error: $META_FILE not found. Cannot determine instance identity."
  exit 1
fi

INSTANCE_NAME=$(jq -r '.instance_name' "$META_FILE")

if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "null" ]; then
  echo "❌ Error: instance_name missing in $META_FILE"
  exit 1
fi

S3_BUCKET="s3://llampress-ai-backups/backups/leonardos/${INSTANCE_NAME}"

# Check if --all flag is passed
SHOW_ALL=false
if [ "$1" = "--all" ]; then
  SHOW_ALL=true
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📦 Backup Status for: ${INSTANCE_NAME}"
echo "📍 S3 Location: ${S3_BUCKET}/"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Function to format bytes to human readable
format_size() {
  local size=$1
  if command -v numfmt &> /dev/null; then
    echo $(numfmt --to=iec $size 2>/dev/null || echo "${size}B")
  else
    echo "${size}B"
  fi
}

# Function to format timestamp to relative time
relative_time() {
  local timestamp="$1"
  local now=$(date +%s)
  local backup_time=$(date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" +%s 2>/dev/null || date -d "$timestamp" +%s 2>/dev/null)

  if [ -z "$backup_time" ]; then
    echo "$timestamp"
    return
  fi

  local diff=$((now - backup_time))

  if [ $diff -lt 60 ]; then
    echo "just now"
  elif [ $diff -lt 3600 ]; then
    echo "$((diff / 60)) minutes ago"
  elif [ $diff -lt 86400 ]; then
    echo "$((diff / 3600)) hours ago"
  elif [ $diff -lt 604800 ]; then
    echo "$((diff / 86400)) days ago"
  else
    echo "$((diff / 604800)) weeks ago"
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  DATABASE BACKUPS (Latest)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get latest database backups
for db in "llamapress_production" "llamabot_production"; do
  LATEST_FILE="${db}_latest.sql.gz"

  # Get file info from S3
  INFO=$(aws s3 ls "${S3_BUCKET}/${LATEST_FILE}" 2>/dev/null || echo "")

  if [ -n "$INFO" ]; then
    # Parse the output: "2024-01-15 10:30:45    12345678 filename"
    TIMESTAMP=$(echo "$INFO" | awk '{print $1 " " $2}')
    SIZE=$(echo "$INFO" | awk '{print $3}')
    SIZE_HUMAN=$(format_size $SIZE)
    REL_TIME=$(relative_time "$TIMESTAMP")

    echo ""
    echo "  📊 ${db}"
    echo "     Last backup: ${TIMESTAMP} (${REL_TIME})"
    echo "     Size: ${SIZE_HUMAN}"
  else
    echo ""
    echo "  ⚠️  ${db}"
    echo "     No backup found"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 STORAGE BACKUPS (Latest)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get latest storage backup
STORAGE_INFO=$(aws s3 ls "${S3_BUCKET}/storage_latest.zip" 2>/dev/null || echo "")

if [ -n "$STORAGE_INFO" ]; then
  TIMESTAMP=$(echo "$STORAGE_INFO" | awk '{print $1 " " $2}')
  SIZE=$(echo "$STORAGE_INFO" | awk '{print $3}')
  SIZE_HUMAN=$(format_size $SIZE)
  REL_TIME=$(relative_time "$TIMESTAMP")

  echo ""
  echo "  📦 Active Storage"
  echo "     Last backup: ${TIMESTAMP} (${REL_TIME})"
  echo "     Size: ${SIZE_HUMAN}"
else
  echo ""
  echo "  ⚠️  Active Storage"
  echo "     No backup found"
fi

# Show weekly storage backups
WEEKLY_BACKUPS=$(aws s3 ls "${S3_BUCKET}/storage_weekly_" 2>/dev/null | tail -3 || echo "")
if [ -n "$WEEKLY_BACKUPS" ]; then
  echo ""
  echo "  📅 Recent Weekly Backups:"
  echo "$WEEKLY_BACKUPS" | while read line; do
    FILE=$(echo "$line" | awk '{print $4}')
    SIZE=$(echo "$line" | awk '{print $3}')
    SIZE_HUMAN=$(format_size $SIZE)
    DATE=$(echo "$FILE" | grep -oE '[0-9]{8}' | head -1)
    if [ -n "$DATE" ]; then
      FORMATTED_DATE="${DATE:0:4}-${DATE:4:2}-${DATE:6:2}"
      echo "     • ${FORMATTED_DATE}: ${SIZE_HUMAN}"
    fi
  done
fi

# If --all flag, show timestamped database backups
if [ "$SHOW_ALL" = true ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📜 ALL TIMESTAMPED BACKUPS (Last 10)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo ""
  echo "  All files in backup directory:"
  aws s3 ls "${S3_BUCKET}/" --human-readable 2>/dev/null | tail -20 | while read line; do
    echo "     $line"
  done
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "💡 Tips:"
echo "   • Run with --all to see all timestamped backups"
echo "   • Database backups run: daily (or as scheduled)"
echo "   • Weekly storage backups: every Monday"
echo "════════════════════════════════════════════════════════════════"
echo ""
