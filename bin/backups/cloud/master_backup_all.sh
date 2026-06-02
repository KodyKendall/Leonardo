#!/bin/bash
set -e

# Master backup script - runs all backup steps with a shared timestamp
# Usage: ./master_backup_all.sh <instance_name> <s3_bucket_path> [project_dir]
# Example: ./master_backup_all.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5
# Example: ./master_backup_all.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5 /home/ubuntu/Leonardo

INSTANCE_NAME="$1"
S3_BUCKET="$2"
PROJECT_DIR="${3:-$PWD}"

# Load S3 backup creds from .env. LXD/Hetzner have no IMDS role, so the aws CLI
# needs these from the env. The `=.+` requires a non-empty value, so on AWS —
# where .env carries no AWS_* keys — this is a no-op and the IMDS role is used.
if [ -f "${PROJECT_DIR}/.env" ]; then
  export $(grep -E '^AWS_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|DEFAULT_REGION)=.+' "${PROJECT_DIR}/.env" | xargs)
fi

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket_path> [project_dir]"
    echo "Example: $0 LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5"
    echo "Example: $0 LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5 /home/ubuntu/Leonardo"
    exit 1
fi

# Generate single timestamp for entire backup session
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "════════════════════════════════════════════════════════════"
echo "🚀 MASTER BACKUP: ${INSTANCE_NAME}"
echo "════════════════════════════════════════════════════════════"
echo "📍 S3 Bucket: ${S3_BUCKET}"
echo "📁 Backup Folder: ${BACKUP_TIMESTAMP}"
echo "📂 Project Dir: ${PROJECT_DIR}"
echo "⏱️  Start time: $(date)"
echo ""
MASTER_START=$(date +%s)

# Get script directory (where this script is located)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Step 1: Backup Postgres
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1/4: Backup Postgres Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/1_backup_postgres_to_s3.sh" \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}" \
    "${BACKUP_TIMESTAMP}"
echo "✅ Step 1 complete"
echo ""

# Step 2: Backup Docker Volumes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 2/4: Backup Docker Volumes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/2_backup_docker_volumes_to_s3.sh" \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}" \
    "${BACKUP_TIMESTAMP}"
echo "✅ Step 2 complete"
echo ""

# Step 3: Backup Project Files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 3/4: Backup Project Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/3_backup_project_files_to_s3.sh" \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}" \
    "${PROJECT_DIR}" \
    "${BACKUP_TIMESTAMP}"
echo "✅ Step 3 complete"
echo ""

# Step 4: Backup System Configs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 4/4: Backup System Configs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Step 4 needs root (Caddy certs/conf, authorized_keys). On LXD/Hetzner, forward
# the S3 creds through sudo via `env` so they survive env_reset. On AWS the vars
# are unset, so we fall through to plain sudo and step 4 uses the IMDS role.
if [ -n "${AWS_ACCESS_KEY_ID:-}" ]; then
    sudo env AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
             AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
             AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}" \
             "${SCRIPT_DIR}/4_backup_system_configs_to_s3.sh" \
             "${INSTANCE_NAME}" \
             "${S3_BUCKET}" \
             "${BACKUP_TIMESTAMP}"
else
    sudo "${SCRIPT_DIR}/4_backup_system_configs_to_s3.sh" \
        "${INSTANCE_NAME}" \
        "${S3_BUCKET}" \
        "${BACKUP_TIMESTAMP}"
fi
echo "✅ Step 4 complete"
echo ""

# Final summary
MASTER_END=$(date +%s)
MASTER_DURATION=$((MASTER_END - MASTER_START))

echo "════════════════════════════════════════════════════════════"
echo "✅ BACKUP COMPLETE!"
echo "════════════════════════════════════════════════════════════"
echo "📁 Backup Folder: ${BACKUP_TIMESTAMP}"
echo "📍 S3 Location: ${S3_BUCKET}/${BACKUP_TIMESTAMP}/"
echo "⏱️  Total time: ${MASTER_DURATION} seconds"
echo "⏱️  End time: $(date)"
echo ""
echo "📋 View backups:"
echo "   aws s3 ls ${S3_BUCKET}/"
echo ""
echo "📦 Restore with:"
echo "   ./master_restore_all.sh ${INSTANCE_NAME} ${S3_BUCKET}"
echo "════════════════════════════════════════════════════════════"
