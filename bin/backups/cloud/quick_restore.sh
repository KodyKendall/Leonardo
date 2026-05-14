#!/bin/bash
set -e

# Quick restore script - Postgres + project files from latest quick backup
# Usage: ./quick_restore.sh <instance_name> <s3_bucket_path> [project_dir]

INSTANCE_NAME="$1"
S3_BUCKET="$2"
PROJECT_DIR="${3:-/home/ubuntu/Leonardo}"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket_path> [project_dir]"
    exit 1
fi

echo "Quick restore: ${INSTANCE_NAME}"
echo "Source: ${S3_BUCKET}/latest/"
echo "Project dir: ${PROJECT_DIR}"
START=$(date +%s)

# Show when the backup was taken
LAST_BACKUP=$(aws s3 cp "${S3_BUCKET}/latest/last-quick-backup.txt" - 2>/dev/null || echo "unknown")
echo "Last backup timestamp: ${LAST_BACKUP}"
echo ""

read -p "This will overwrite the database and project files. Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Step 1: Restore Postgres
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Restoring Postgres database..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

aws s3 cp "${S3_BUCKET}/latest/postgres-${INSTANCE_NAME}.sql.gz" - --only-show-errors \
    | gunzip \
    | docker compose exec -T db psql -U postgres --quiet -f -

echo "Database restored."

# Step 2: Restore project files
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Syncing project files to ${PROJECT_DIR}..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

aws s3 sync "${S3_BUCKET}/latest/project-files/" "${PROJECT_DIR}" \
    --only-show-errors \
    --delete

echo "Project files restored."

# Step 3: Restore Caddy config + certs
CADDY_EXISTS=$(aws s3 ls "${S3_BUCKET}/latest/caddy-config/" 2>/dev/null || true)
if [ -n "$CADDY_EXISTS" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Restoring Caddy config..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sudo mkdir -p /etc/caddy
    aws s3 sync "${S3_BUCKET}/latest/caddy-config/" "/etc/caddy/" --only-show-errors
    echo "Caddy config restored."
fi

CADDY_DATA_EXISTS=$(aws s3 ls "${S3_BUCKET}/latest/caddy-data/" 2>/dev/null || true)
if [ -n "$CADDY_DATA_EXISTS" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Restoring Caddy certs/data..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sudo mkdir -p /var/lib/caddy/.local/share/caddy
    aws s3 sync "${S3_BUCKET}/latest/caddy-data/" "/var/lib/caddy/.local/share/caddy/" --only-show-errors
    sudo chown -R caddy:caddy /var/lib/caddy
    echo "Caddy data restored."
fi

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "Quick restore complete in ${DURATION}s"
echo "You may need to restart services: docker compose down && docker compose up -d"
if [ -n "$CADDY_EXISTS" ] || [ -n "$CADDY_DATA_EXISTS" ]; then
    echo "Reload Caddy: sudo systemctl reload caddy"
fi
