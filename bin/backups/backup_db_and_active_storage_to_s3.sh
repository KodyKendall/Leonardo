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

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🚀 Starting full backup: Database + Active Storage"
echo "⏱️  Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════════"
echo ""

OVERALL_START=$(date +%s)

# Run database backup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 1/2: Database Backup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /home/ubuntu/Leonardo
bash bin/db/backup_s3.sh
echo ""

# Run storage backup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Step 2/2: Active Storage Backup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash bin/backups/backup_storage.sh
echo ""

OVERALL_END=$(date +%s)
OVERALL_DURATION=$((OVERALL_END - OVERALL_START))

echo "════════════════════════════════════════════════════════════════"
echo "✅ Full backup complete!"
echo "⏱️  Total duration: ${OVERALL_DURATION} seconds"
echo "⏱️  Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════════"
echo ""
