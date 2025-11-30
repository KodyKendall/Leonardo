#!/bin/bash
# Save as ~/llamapress/backup.sh

set -e 

BACKUP_DIR="$PWD/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Check for --dated flag
if [[ "$1" == "--dated" ]]; then
  BACKUP_FILE="$BACKUP_DIR/llamapress_manual_$DATE.sql.gz"
else
  BACKUP_FILE="$BACKUP_DIR/llamapress_manual_latest.sql.gz"
fi

mkdir -p "$BACKUP_DIR"

docker compose exec -T db pg_dump -U postgres llamapress_production | gzip > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE"

# Keep only last 10 manual backups (only for dated backups)
if [[ "$1" == "--dated" ]]; then
  ls -t $BACKUP_DIR/llamapress_manual_*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm
fi
