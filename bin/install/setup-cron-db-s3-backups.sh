#!/bin/bash
set -e

# To run: 
# ./bin/install/setup-cron-db-s3-backups.sh

echo "Installing cron entry safely..."

# === CONFIG ===
BACKUP_SCRIPT="/home/ubuntu/Leonardo/bin/db/backup_s3.sh"
LOG_DIR="/home/ubuntu/Leonardo/logs/backups"

# Create log directory
mkdir -p "$LOG_DIR"

# === CRON SCHEDULE OPTIONS ===
# Uncomment the schedule you want to use:

# Every 2 minutes (for testing) - 720 backups/day
# CRON_ENTRY="*/2 * * * * cd /home/ubuntu/Leonardo && $BACKUP_SCRIPT"

# Every 2 hours (recommended for production) - 12 backups/day
# CRON_ENTRY="0 */2 * * * cd /home/ubuntu/Leonardo && $BACKUP_SCRIPT"

# Every hour - 24 backups/day
# CRON_ENTRY="0 * * * * cd /home/ubuntu/Leonardo && $BACKUP_SCRIPT"

# Every 6 hours - 4 backups/day
# CRON_ENTRY="0 */6 * * * cd /home/ubuntu/Leonardo && $BACKUP_SCRIPT"

# Daily at 2am - 1 backup/day
CRON_ENTRY="0 2 * * * cd /home/ubuntu/Leonardo && $BACKUP_SCRIPT"

# Show what we're installing
echo "Cron entry to install:"
echo "$CRON_ENTRY"
echo ""

TMPFILE=$(mktemp)

# safely dump existing crontab (ignore errors)
sudo crontab -l 2>/dev/null | sed '/backup_s3.sh/d' > $TMPFILE || true

# append new cron entry
echo "$CRON_ENTRY" >> $TMPFILE

# install new crontab
sudo crontab $TMPFILE

# clean up
rm $TMPFILE

echo "Cron entry installed."
