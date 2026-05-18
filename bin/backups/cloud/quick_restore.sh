#!/bin/bash

# Quick restore script - project files + per-database postgres restores
# Matches the backup format written by quick_backup.sh:
#   - project-files/                             (s3 sync)
#   - llamapress_production-<instance>.sql.gz    (pg_dump)
#   - llamabot_production-<instance>.sql.gz      (pg_dump, no checkpoint tables)
#
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

LAST_BACKUP=$(aws s3 cp "${S3_BUCKET}/latest/last-quick-backup.txt" - 2>/dev/null || echo "unknown")
echo "Last backup timestamp: ${LAST_BACKUP}"
echo ""

read -p "This will overwrite the database and project files. Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

START=$(date +%s)

STEP1_STATUS="⏭️  skipped"
STEP2_STATUS="⏭️  skipped"
STEP3_STATUS="⏭️  skipped"
OVERALL_OK=true

# ─────────────────────────────────────────────────────────────
# Step 1: Restore project files
# ─────────────────────────────────────────────────────────────
echo ""
echo "Step 1/3: Restoring project files to ${PROJECT_DIR}..."
if aws s3 sync "${S3_BUCKET}/latest/project-files/" "${PROJECT_DIR}" \
    --only-show-errors \
    --delete; then
    STEP1_STATUS="✅ success"
else
    STEP1_STATUS="❌ FAILED"
    OVERALL_OK=false
fi

# ─────────────────────────────────────────────────────────────
# Step 2: Restore llamapress_production (only if step 1 succeeded)
# ─────────────────────────────────────────────────────────────
if [ "$OVERALL_OK" = true ]; then
    echo ""
    echo "Step 2/3: Restoring llamapress_production..."
    if aws s3 cp "${S3_BUCKET}/latest/llamapress_production-${INSTANCE_NAME}.sql.gz" - --only-show-errors \
        | gunzip \
        | docker compose exec -T db psql -U postgres -d llamapress_production --quiet -f -; then
        STEP2_STATUS="✅ success"
    else
        STEP2_STATUS="❌ FAILED"
        OVERALL_OK=false
    fi
else
    STEP2_STATUS="⏭️  skipped (step 1 failed)"
fi

# ─────────────────────────────────────────────────────────────
# Step 3: Restore llamabot_production (only if steps 1+2 succeeded)
# Note: checkpoint tables were excluded from backup — they will be empty after restore.
# ─────────────────────────────────────────────────────────────
if [ "$OVERALL_OK" = true ]; then
    echo ""
    echo "Step 3/3: Restoring llamabot_production..."
    if aws s3 cp "${S3_BUCKET}/latest/llamabot_production-${INSTANCE_NAME}.sql.gz" - --only-show-errors \
        | gunzip \
        | docker compose exec -T db psql -U postgres -d llamabot_production --quiet -f -; then
        STEP3_STATUS="✅ success"
    else
        STEP3_STATUS="❌ FAILED"
        OVERALL_OK=false
    fi
else
    STEP3_STATUS="⏭️  skipped (step 1 or 2 failed)"
fi

# ─────────────────────────────────────────────────────────────
# Caddy config + certs (non-critical, best-effort)
# ─────────────────────────────────────────────────────────────
CADDY_STATUS=""
CADDY_EXISTS=$(aws s3 ls "${S3_BUCKET}/latest/caddy-config/" 2>/dev/null || true)
if [ -n "$CADDY_EXISTS" ]; then
    sudo mkdir -p /etc/caddy
    if aws s3 sync "${S3_BUCKET}/latest/caddy-config/" "/etc/caddy/" --only-show-errors 2>/dev/null; then
        CADDY_STATUS="✅ caddy config"
    else
        CADDY_STATUS="⚠️  caddy config restore failed (non-critical)"
    fi
fi
CADDY_DATA_EXISTS=$(aws s3 ls "${S3_BUCKET}/latest/caddy-data/" 2>/dev/null || true)
if [ -n "$CADDY_DATA_EXISTS" ]; then
    sudo mkdir -p /var/lib/caddy/.local/share/caddy
    if aws s3 sync "${S3_BUCKET}/latest/caddy-data/" "/var/lib/caddy/.local/share/caddy/" --only-show-errors 2>/dev/null; then
        sudo chown -R caddy:caddy /var/lib/caddy
        CADDY_STATUS="${CADDY_STATUS} ✅ caddy certs"
    else
        CADDY_STATUS="${CADDY_STATUS} ⚠️  caddy certs restore failed (non-critical)"
    fi
fi

END=$(date +%s)
DURATION=$((END - START))

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
if [ "$OVERALL_OK" = true ]; then
    echo "✅ Restore complete in ${DURATION}s"
else
    echo "❌ Restore FAILED in ${DURATION}s"
fi
echo "════════════════════════════════════════"
echo "  Step 1 — project files:         ${STEP1_STATUS}"
echo "  Step 2 — llamapress_production: ${STEP2_STATUS}"
echo "  Step 3 — llamabot_production:   ${STEP3_STATUS}"
[ -n "$CADDY_STATUS" ] && echo "  Caddy:                          ${CADDY_STATUS}"
echo "════════════════════════════════════════"

if [ "$OVERALL_OK" = true ]; then
    echo ""
    echo "Next steps:"
    echo "  docker compose down && docker compose up -d"
    [ -n "$CADDY_EXISTS" ] || [ -n "$CADDY_DATA_EXISTS" ] && echo "  sudo systemctl reload caddy"
    echo ""
    echo "Note: llamabot checkpoint tables (checkpoints, checkpoint_writes,"
    echo "  checkpoint_migrations, checkpoint_blobs) were not backed up and will be empty."
fi

if [ "$OVERALL_OK" = true ]; then
    exit 0
else
    exit 1
fi
