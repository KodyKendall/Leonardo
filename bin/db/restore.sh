#!/bin/bash
# Database restore script for Leonardo/LlamaPress

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root (two levels up from bin/db/)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BACKUP_DIR="$PROJECT_ROOT/backups"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
DB_NAME="llamapress_production"
DB_USER="postgres"
LOG_FILE="$BACKUP_DIR/restore.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

# Check if docker compose is running
if ! docker compose -f "$COMPOSE_FILE" ps db | grep -q "Up"; then
    error "Database container is not running. Start with: docker compose up -d db"
fi

# List available backups
echo "=================================================="
echo "Available backups:"
echo "=================================================="
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.sql.gz 2>/dev/null)" ]; then
    error "No backups found in $BACKUP_DIR"
fi

# List backups with numbers
backups=($(ls -t $BACKUP_DIR/*.sql.gz 2>/dev/null || ls -t $BACKUP_DIR/*.sql 2>/dev/null))
for i in "${!backups[@]}"; do
    backup_file="${backups[$i]}"
    file_size=$(du -h "$backup_file" | cut -f1)
    file_date=$(date -r "$backup_file" '+%Y-%m-%d %H:%M:%S')
    echo "$((i+1)). $(basename "$backup_file") - Size: $file_size - Created: $file_date"
done

echo ""
read -p "Enter backup number to restore (1-${#backups[@]}), or 'q' to quit: " selection

if [ "$selection" = "q" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#backups[@]}" ]; then
    error "Invalid selection"
fi

BACKUP_FILE="${backups[$((selection-1))]}"
log "Selected backup: $BACKUP_FILE"

# Safety confirmation
echo ""
echo "=================================================="
warning "DANGER: This will REPLACE all current data!"
echo "=================================================="
echo "Database: $DB_NAME"
echo "Backup file: $(basename $BACKUP_FILE)"
echo ""
read -p "Type 'YES' (in capitals) to continue: " confirm

if [ "$confirm" != "YES" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Create pre-restore backup
echo ""
log "Creating pre-restore backup of current database..."
PRE_RESTORE_BACKUP="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).sql.gz"
if docker compose -f "$COMPOSE_FILE" exec -T db pg_dump -U "$DB_USER" "$DB_NAME" 2>/dev/null | gzip > "$PRE_RESTORE_BACKUP"; then
    success "Pre-restore backup created: $(basename $PRE_RESTORE_BACKUP)"
else
    warning "Could not create pre-restore backup (database might be empty)"
fi

# Stop the Rails app to prevent connections
log "Stopping llamapress service..."
docker compose -f "$COMPOSE_FILE" stop llamapress llamabot

# Wait a moment for connections to close
sleep 2

# Terminate existing connections
log "Terminating existing database connections..."
docker compose -f "$COMPOSE_FILE" exec -T db psql -U "$DB_USER" -d postgres -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true

# Drop and recreate database
log "Dropping database $DB_NAME..."
docker compose -f "$COMPOSE_FILE" exec -T db dropdb -U "$DB_USER" --if-exists "$DB_NAME"

log "Creating fresh database $DB_NAME..."
docker compose -f "$COMPOSE_FILE" exec -T db createdb -U "$DB_USER" "$DB_NAME"

# Restore from backup
log "Restoring from backup..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    if gunzip < "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T db psql -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
        success "Database restored successfully!"
    else
        error "Restore failed! Pre-restore backup available at: $(basename $PRE_RESTORE_BACKUP)"
    fi
else
    if cat "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T db psql -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
        success "Database restored successfully!"
    else
        error "Restore failed! Pre-restore backup available at: $(basename $PRE_RESTORE_BACKUP)"
    fi
fi

# Restart services
log "Restarting services..."
docker compose -f "$COMPOSE_FILE" up -d llamapress llamabot

# Wait for services to be healthy
log "Waiting for services to start..."
sleep 5

# Verify restoration
log "Verifying database..."
TABLE_COUNT=$(docker compose -f "$COMPOSE_FILE" exec -T db psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')

if [ "$TABLE_COUNT" -gt 0 ]; then
    success "Verification passed! Database has $TABLE_COUNT tables."
else
    error "Verification failed! Database appears to be empty."
fi

echo ""
echo "=================================================="
success "RESTORE COMPLETE!"
echo "=================================================="
echo "Backup restored: $(basename $BACKUP_FILE)"
echo "Tables in database: $TABLE_COUNT"
echo "Pre-restore backup saved: $(basename $PRE_RESTORE_BACKUP)"
echo ""
echo "Log file: $LOG_FILE"
echo ""
echo "Next steps:"
echo "  1. Check your application at http://$(hostname -I | awk '{print $1}'):3000"
echo "  2. Verify your data is correct"
echo "  3. If everything looks good, you can delete: $PRE_RESTORE_BACKUP"
echo "=================================================="