#!/bin/bash
set -e

# Bootstrap script to download proprietary backup/restore scripts from S3
# Then execute the master restore script
# This is the ONLY script that needs to be baked into the AMI

SCRIPTS_BUCKET="s3://llampress-ai-backups/proprietary-scripts"
INSTALL_DIR="/home/ubuntu/bin/backups/cloud"

# Arguments passed through to master_restore_all.sh
INSTANCE_NAME="$1"
S3_BACKUP_PATH="$2"

echo "🔵 Bootstrapping LlamaPress backup/restore scripts..."
echo "📁 Installing to: ${INSTALL_DIR}"

# Create directory structure
mkdir -p "$INSTALL_DIR"

# Download all scripts from S3 (including master_restore_all.sh)
echo "📥 Downloading latest scripts from S3..."
aws s3 sync "${SCRIPTS_BUCKET}/" "${INSTALL_DIR}/" --exclude "*" --include "*.sh" --quiet

# Make executable
chmod +x "${INSTALL_DIR}"/*.sh

# Verify
SCRIPT_COUNT=$(ls -1 "${INSTALL_DIR}"/*.sh 2>/dev/null | wc -l)

echo "✅ Bootstrap complete! Downloaded ${SCRIPT_COUNT} scripts"

# Execute the master restore script with all arguments
echo ""
echo "🚀 Executing master restore script..."
exec "${INSTALL_DIR}/master_restore_all.sh" "$INSTANCE_NAME" "$S3_BACKUP_PATH"
