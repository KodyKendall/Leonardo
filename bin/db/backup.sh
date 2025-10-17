#!/bin/bash
# Save as ~/llamapress/backup.sh

set -e 

BACKUP_DIR="/home/ubuntu/llamapress/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/llamapress_manual_$DATE.sql.gz"

mkdir -p "$BACKUP_DIR"

docker compose exec -T db pg_dump -U postgres llamapress_production | gzip > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE"
# Keep only last 10 manual backups
ls -t $BACKUP_DIR/llamapress_manual_*.sql.gz | tail -n +11 | xargs -r rm