#!/bin/bash

# Quick backup script - strict ordered pipeline:
#   1) Leonardo source code sync
#   2) llamapress_production postgres dump  (only after 1 succeeds)
#   3) llamabot_production postgres dump    (only after 1+2 succeed)
#      -- excludes heavy LangGraph checkpoint tables
#
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

# ─────────────────────────────────────────────────────────────
# Pre-flight: verify AWS credentials before doing any work
# ─────────────────────────────────────────────────────────────
echo ""
echo "Pre-flight: Checking AWS credentials..."
if ! AWS_IDENTITY=$(aws sts get-caller-identity --output text 2>&1); then
    echo ""
    echo "════════════════════════════════════════"
    echo "❌ AWS CREDENTIALS FAILED — backup aborted"
    echo "════════════════════════════════════════"
    echo ""
    echo "  Error: ${AWS_IDENTITY}"
    echo ""
    echo "  Common causes:"
    echo "    • AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY not set in environment"
    echo "    • IAM role not attached to this EC2 instance"
    echo "    • ~/.aws/credentials missing or expired"
    echo "    • AWS_PROFILE set to a profile that doesn't exist"
    echo ""
    echo "  To debug, run:  aws sts get-caller-identity"
    echo "════════════════════════════════════════"
    exit 1
fi
echo "  ✅ AWS auth OK — $(echo "$AWS_IDENTITY" | awk '{print "Account: "$1, "| User:", $2}')"

STEP1_STATUS="⏭️  skipped"
STEP2_STATUS="⏭️  skipped"
STEP3_STATUS="⏭️  skipped"
OVERALL_OK=true

# ─────────────────────────────────────────────────────────────
# Step 1: Source code sync (incremental, fast for small changes)
# ─────────────────────────────────────────────────────────────
echo ""
echo "Step 1/3: Syncing Leonardo source code..."
STEP1_START=$(date +%s)
if aws s3 sync "${PROJECT_DIR}" "${S3_BUCKET}/latest/project-files/" \
    --exclude "*.pyc" \
    --exclude "__pycache__/*" \
    --exclude "tmp/*" \
    --exclude "log/*" \
    --exclude "node_modules/*" \
    --exclude ".claude/*" \
    --exclude "backups/*" \
    --storage-class STANDARD_IA \
    --only-show-errors \
    --delete; then
    STEP1_STATUS="✅ success ($(( $(date +%s) - STEP1_START ))s)"
else
    STEP1_STATUS="❌ FAILED ($(( $(date +%s) - STEP1_START ))s)"
    OVERALL_OK=false
fi

# ─────────────────────────────────────────────────────────────
# Step 2: LlamaPress database backup (only if step 1 succeeded)
# ─────────────────────────────────────────────────────────────
if [ "$OVERALL_OK" = true ]; then
    echo ""
    echo "Step 2/3: Backing up llamapress_production..."
    STEP2_START=$(date +%s)
    if docker compose exec -T db pg_dump -U postgres llamapress_production \
        | gzip \
        | aws s3 cp - "${S3_BUCKET}/latest/llamapress_production-${INSTANCE_NAME}.sql.gz" \
            --storage-class STANDARD_IA --only-show-errors; then
        STEP2_STATUS="✅ success ($(( $(date +%s) - STEP2_START ))s)"
    else
        STEP2_STATUS="❌ FAILED ($(( $(date +%s) - STEP2_START ))s)"
        OVERALL_OK=false
    fi
else
    STEP2_STATUS="⏭️  skipped (step 1 failed)"
fi

# ─────────────────────────────────────────────────────────────
# Step 3: LlamaBot database backup (only if steps 1+2 succeeded)
#
# Excluded tables (LangGraph checkpoint data — too large):
#   checkpoints, checkpoint_writes, checkpoint_migrations, checkpoint_blobs
# ─────────────────────────────────────────────────────────────
if [ "$OVERALL_OK" = true ]; then
    echo ""
    echo "Step 3/3: Backing up llamabot_production (excluding checkpoint tables)..."
    STEP3_START=$(date +%s)
    if docker compose exec -T db pg_dump -U postgres llamabot_production \
        --exclude-table=checkpoints \
        --exclude-table=checkpoint_writes \
        --exclude-table=checkpoint_migrations \
        --exclude-table=checkpoint_blobs \
        | gzip \
        | aws s3 cp - "${S3_BUCKET}/latest/llamabot_production-${INSTANCE_NAME}.sql.gz" \
            --storage-class STANDARD_IA --only-show-errors; then
        STEP3_STATUS="✅ success ($(( $(date +%s) - STEP3_START ))s)"
    else
        STEP3_STATUS="❌ FAILED ($(( $(date +%s) - STEP3_START ))s)"
        OVERALL_OK=false
    fi
else
    STEP3_STATUS="⏭️  skipped (step 1 or 2 failed)"
fi

# ─────────────────────────────────────────────────────────────
# Caddy config + certs (non-critical, best-effort)
# ─────────────────────────────────────────────────────────────
CADDY_STATUS=""
if [ -d "/etc/caddy" ]; then
    if aws s3 sync "/etc/caddy" "${S3_BUCKET}/latest/caddy-config/" \
        --storage-class STANDARD_IA --only-show-errors 2>/dev/null; then
        CADDY_STATUS="✅ caddy config"
    else
        CADDY_STATUS="⚠️  caddy config sync failed (non-critical)"
    fi
fi
CADDY_CERT_DIR="/var/lib/caddy/.local/share/caddy"
if [ -d "$CADDY_CERT_DIR" ]; then
    if aws s3 sync "$CADDY_CERT_DIR" "${S3_BUCKET}/latest/caddy-data/" \
        --storage-class STANDARD_IA --only-show-errors 2>/dev/null; then
        CADDY_STATUS="${CADDY_STATUS} ✅ caddy certs"
    else
        CADDY_STATUS="${CADDY_STATUS} ⚠️  caddy certs sync failed (non-critical)"
    fi
fi

END=$(date +%s)
DURATION=$((END - START))

echo "${TIMESTAMP}" | aws s3 cp - "${S3_BUCKET}/latest/last-quick-backup.txt" --only-show-errors 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
if [ "$OVERALL_OK" = true ]; then
    echo "✅ Backup complete in ${DURATION}s"
else
    echo "❌ Backup FAILED in ${DURATION}s"
fi
echo "════════════════════════════════════════"
echo "  Step 1 — source code:          ${STEP1_STATUS}"
echo "  Step 2 — llamapress_production: ${STEP2_STATUS}"
echo "  Step 3 — llamabot_production:   ${STEP3_STATUS}"
[ -n "$CADDY_STATUS" ] && echo "  Caddy:                          ${CADDY_STATUS}"
echo "════════════════════════════════════════"

if [ "$OVERALL_OK" = true ]; then
    exit 0
else
    exit 1
fi
