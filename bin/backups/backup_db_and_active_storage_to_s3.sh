#!/bin/bash
# Note: We intentionally do NOT use set -e here to ensure ALL backup steps
# are attempted even if earlier ones fail. This is critical for robustness.

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

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🚀 Starting full backup: Database + Active Storage"
echo "⏱️  Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════════"
echo ""

OVERALL_START=$(date +%s)

# Track which backups succeeded/failed
DB_BACKUP_STATUS="unknown"
STORAGE_BACKUP_STATUS="unknown"

# Run database backup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 1/2: Database Backup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /home/ubuntu/Leonardo
if bash bin/db/backup_s3.sh; then
  DB_BACKUP_STATUS="success"
else
  DB_BACKUP_STATUS="failed"
  echo "⚠️  Database backup encountered errors - continuing with storage backup..."
fi
echo ""

# Run storage backup (always attempt, regardless of DB backup result)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Step 2/2: Active Storage Backup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if bash bin/backups/backup_storage.sh; then
  STORAGE_BACKUP_STATUS="success"
else
  STORAGE_BACKUP_STATUS="failed"
  echo "⚠️  Storage backup encountered errors"
fi
echo ""

OVERALL_END=$(date +%s)
OVERALL_DURATION=$((OVERALL_END - OVERALL_START))

echo "════════════════════════════════════════════════════════════════"
if [ "$DB_BACKUP_STATUS" = "success" ] && [ "$STORAGE_BACKUP_STATUS" = "success" ]; then
  echo "✅ Full backup complete!"
else
  echo "⚠️  Backup completed with errors:"
  echo "   📊 Database backup: $DB_BACKUP_STATUS"
  echo "   📁 Storage backup:  $STORAGE_BACKUP_STATUS"
fi
echo "⏱️  Total duration: ${OVERALL_DURATION} seconds"
echo "⏱️  Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Exit with error if any backup failed (useful for monitoring/alerting)
if [ "$DB_BACKUP_STATUS" = "failed" ] || [ "$STORAGE_BACKUP_STATUS" = "failed" ]; then
  exit 1
fi
