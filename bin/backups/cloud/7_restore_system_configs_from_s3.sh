#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
BACKUP_NAME="$3"  # Optional: specific backup

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [backup_name]"
    echo "Example: $0 production-server-1 s3://my-bucket/system-configs"
    echo "Example: $0 prod-1 s3://bucket/configs system-prod-1-20251020-153022.tar.gz"
    exit 1
fi

echo "🔵 Restoring system configs..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# If no backup specified, find the latest
if [ -z "$BACKUP_NAME" ]; then
    echo "📋 Finding latest backup for ${INSTANCE_NAME}..."
    LATEST=$(aws s3 ls "${S3_BUCKET}/" | grep "system-${INSTANCE_NAME}-" | sort | tail -n 1 | awk '{print $4}')
    if [ -z "$LATEST" ]; then
        echo "❌ No backups found for ${INSTANCE_NAME}"
        exit 1
    fi
    BACKUP_NAME="$LATEST"
    echo "📍 Using: ${BACKUP_NAME}"
fi

TEMP_DIR="/tmp/system-restore-$$"
mkdir -p "$TEMP_DIR"

# Download and extract
echo "📥 Downloading and extracting..."
aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" - | tar xzf - -C "$TEMP_DIR"

# Restore Caddyfile
if [ -f "$TEMP_DIR/etc/caddy/Caddyfile" ]; then
    echo "📦 Restoring Caddyfile..."
    sudo mkdir -p /etc/caddy
    sudo cp "$TEMP_DIR/etc/caddy/Caddyfile" /etc/caddy/ 2>/dev/null || \
        echo "   ⚠️  Need sudo to restore Caddyfile (skipped)"
fi

# Restore AWS config
if [ -d "$TEMP_DIR/aws/.aws" ]; then
    echo "📦 Restoring AWS config..."
    mkdir -p "$HOME/.aws"
    cp -r "$TEMP_DIR/aws/.aws/"* "$HOME/.aws/" 2>/dev/null || echo "   ⚠️  Could not restore AWS config"
fi

# Restore GitHub CLI config
if [ -d "$TEMP_DIR/gh/gh" ]; then
    echo "📦 Restoring GitHub CLI config..."
    mkdir -p "$HOME/.config/gh"
    cp -r "$TEMP_DIR/gh/gh/"* "$HOME/.config/gh/" 2>/dev/null || echo "   ⚠️  Could not restore GH config"
fi

# Restore SSH authorized_keys
if [ -f "$TEMP_DIR/ssh/authorized_keys" ]; then
    echo "📦 Restoring SSH authorized_keys..."
    mkdir -p "$HOME/.ssh"
    cp "$TEMP_DIR/ssh/authorized_keys" "$HOME/.ssh/"
    chmod 600 "$HOME/.ssh/authorized_keys"
    chmod 700 "$HOME/.ssh"
fi

# Cleanup
rm -rf "$TEMP_DIR"

END=$(date +%s)
DURATION=$((END - START))

echo "✅ System configs restored in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"
echo ""
echo "⚠️  Note: You may need to restart services:"
echo "    sudo systemctl reload caddy"
