#!/bin/bash
set -e

# Quick backup script - Postgres + project files only (optimized for speed)
# Runs on every task completion. Uses s3 sync for project files (incremental).
# Usage: ./quick_backup.sh <instance_name> <s3_bucket_path> [project_dir]

INSTANCE_NAME="$1"
S3_BUCKET="$2"
PROJECT_DIR="${3:-/home/ubuntu/Leonardo}"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket_path> [project_dir]"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo "Quick backup: ${INSTANCE_NAME} @ ${TIMESTAMP}"
START=$(date +%s)

# Run Postgres dump and project sync in parallel
POSTGRES_PID=""
POSTGRES_OK=""
SYNC_OK=""

# Step 1: Postgres dump (background)
(
    docker compose exec -T db pg_dumpall -U postgres \
        | gzip \
        | aws s3 cp - "${S3_BUCKET}/latest/postgres-${INSTANCE_NAME}.sql.gz" \
            --storage-class STANDARD_IA --only-show-errors
) &
POSTGRES_PID=$!

# Step 2: Project files sync (foreground - incremental, fast for small changes)
aws s3 sync "${PROJECT_DIR}" "${S3_BUCKET}/latest/project-files/" \
    --exclude "*.pyc" \
    --exclude "__pycache__/*" \
    --exclude ".git/*" \
    --exclude "tmp/*" \
    --exclude "log/*" \
    --exclude "node_modules/*" \
    --exclude ".claude/*" \
    --exclude "backups/*" \
    --storage-class STANDARD_IA \
    --only-show-errors \
    --delete \
    && SYNC_OK="1"

# Step 3: Caddy config + certs (incremental sync, near-instant when unchanged)
CADDY_OK=""
if [ -d "/etc/caddy" ]; then
    aws s3 sync "/etc/caddy" "${S3_BUCKET}/latest/caddy-config/" \
        --storage-class STANDARD_IA --only-show-errors \
        && CADDY_OK="1" || echo "Warning: Caddy config sync failed"
fi
CADDY_CERT_DIR="/var/lib/caddy/.local/share/caddy"
if [ -d "$CADDY_CERT_DIR" ]; then
    aws s3 sync "$CADDY_CERT_DIR" "${S3_BUCKET}/latest/caddy-data/" \
        --storage-class STANDARD_IA --only-show-errors \
        && CADDY_OK="1" || echo "Warning: Caddy data sync failed"
fi

# Wait for Postgres to finish
wait $POSTGRES_PID && POSTGRES_OK="1"

END=$(date +%s)
DURATION=$((END - START))

# Write timestamp marker
echo "${TIMESTAMP}" | aws s3 cp - "${S3_BUCKET}/latest/last-quick-backup.txt" --only-show-errors

if [ "$POSTGRES_OK" = "1" ] && [ "$SYNC_OK" = "1" ]; then
    echo "Quick backup complete in ${DURATION}s"
    exit 0
else
    echo "Quick backup partial failure (pg=${POSTGRES_OK:-fail} sync=${SYNC_OK:-fail}) in ${DURATION}s"
    exit 1
fi
