#!/bin/bash
set -e

echo "Installing cron entry safely..."

# === CONFIG ===
BACKUP_SCRIPT="/home/ubuntu/Leonardo/bin/db/backup_s3.sh"
CRON_LOG="/var/log/leonardo_backup.log"
CRON_ENTRY="0 */2 * * * $BACKUP_SCRIPT >> $CRON_LOG 2>&1"

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
