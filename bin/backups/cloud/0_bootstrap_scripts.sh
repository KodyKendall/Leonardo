#!/bin/bash
set -e

# Bootstrap script to download proprietary backup/restore scripts from S3
# This is the ONLY script you need to manually put on a fresh EC2

SCRIPTS_BUCKET="s3://llampress-ai-backups/proprietary-scripts"
INSTALL_DIR="${1:-$HOME/Leonardo/bin/backups/cloud}"

echo "🔵 Bootstrapping LlamaPress backup/restore scripts..."
echo "📁 Installing to: ${INSTALL_DIR}"

# Create directory structure
mkdir -p "$INSTALL_DIR"

# Download all scripts from S3
echo "📥 Downloading scripts from S3..."
aws s3 sync "${SCRIPTS_BUCKET}/" "${INSTALL_DIR}/" --exclude "*" --include "*.sh"

# Make executable
chmod +x "${INSTALL_DIR}"/*.sh

# Verify
SCRIPT_COUNT=$(ls -1 "${INSTALL_DIR}"/*.sh 2>/dev/null | wc -l)

echo "✅ Bootstrap complete!"
echo "📊 Installed ${SCRIPT_COUNT} scripts"
echo ""
echo "Available scripts:"
ls -1 "${INSTALL_DIR}"/*.sh

echo ""
echo "🚀 Ready to restore! Example:"
echo "  cd ~/Leonardo"
echo "  ./bin/backups/cloud/30_restore-project-files-from-s3.sh LP-Test5 s3://bucket/path"
