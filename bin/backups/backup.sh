#!/bin/bash
set -e

# Get the current folder name (Leonardo or llamapress)
PROJECT_DIR=$(basename "$PWD")
BACKUP_NAME="${PROJECT_DIR}-backup-$(date +%Y%m%d-%H%M%S)"
OUTPUT_FILE="${1:-$HOME/${BACKUP_NAME}.tar.gz}"

echo "🔵 Starting backup of: ${PROJECT_DIR}"
echo "⏱️  Start time: $(date)"
START_TIME=$(date +%s)

# 1. Backup Postgres database
echo ""
echo "📦 [1/4] Backing up Postgres database..."
STEP_START=$(date +%s)
mkdir -p /tmp/db-backup
docker compose exec -T db pg_dumpall -U postgres | gzip > /tmp/db-backup/postgres_dump.sql.gz
STEP_END=$(date +%s)
DB_SIZE=$(du -h /tmp/db-backup/postgres_dump.sql.gz | cut -f1)
echo "    ✓ Done in $((STEP_END - STEP_START)) seconds (${DB_SIZE})"

# 2. Backup Docker volumes
echo ""
echo "📦 [2/4] Backing up Docker volumes..."
STEP_START=$(date +%s)
mkdir -p /tmp/volumes-backup

for volume in postgres_data redis_data rails_storage code_config; do
    echo -n "    - ${volume}... "
    VOL_START=$(date +%s)
    docker run --rm \
        -v ${volume}:/volume \
        -v /tmp/volumes-backup:/backup \
        alpine \
        tar czf /backup/${volume}.tar.gz -C /volume . 2>/dev/null || echo "⚠️  Not found, skipping"
    if [ -f "/tmp/volumes-backup/${volume}.tar.gz" ]; then
        VOL_END=$(date +%s)
        VOL_SIZE=$(du -h /tmp/volumes-backup/${volume}.tar.gz | cut -f1)
        echo "✓ $((VOL_END - VOL_START))s (${VOL_SIZE})"
    fi
done
STEP_END=$(date +%s)
echo "    ✓ All volumes done in $((STEP_END - STEP_START)) seconds"

# 3. Create project archive (excluding volumes backup)
echo ""
echo "📦 [3/4] Archiving project folder..."
STEP_START=$(date +%s)
cd ..

# Create tarball of project folder + database + volumes
tar czf "/tmp/${BACKUP_NAME}.tar.gz" \
    --exclude="${PROJECT_DIR}/.git" \
    --exclude="${PROJECT_DIR}/backups" \
    --exclude="${PROJECT_DIR}/.claude" \
    "${PROJECT_DIR}" \
    -C /tmp db-backup \
    -C /tmp volumes-backup

STEP_END=$(date +%s)
echo "    ✓ Done in $((STEP_END - STEP_START)) seconds"

# 4. Move to final location
echo ""
echo "📦 [4/4] Finalizing backup..."
mv "/tmp/${BACKUP_NAME}.tar.gz" "${OUTPUT_FILE}"

# Cleanup
rm -rf /tmp/db-backup /tmp/volumes-backup

# Final stats
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
FINAL_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)

echo ""
echo "✅ Backup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Location: ${OUTPUT_FILE}"
echo "📊 Size: ${FINAL_SIZE}"
echo "⏱️  Total time: ${TOTAL_TIME} seconds"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To restore this backup, run:"
echo "  ./restore-simple.sh ${OUTPUT_FILE}"