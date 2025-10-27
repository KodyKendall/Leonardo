#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket>"
    echo "Example: $0 production-server-1 s3://my-bucket/system-configs"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="system-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"
TEMP_DIR="/tmp/system-backup-$$"

echo "🔵 Backing up system configs..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

mkdir -p "$TEMP_DIR"

# Backup Caddy SSL certificates
CADDY_CERT_DIR="/var/lib/caddy/.local/share/caddy/certificates"
if [ -d "$CADDY_CERT_DIR" ]; then
    echo "📦 Backing up Caddy SSL certificates..."
    mkdir -p "$TEMP_DIR/caddy-certs"
    sudo cp -r "$CADDY_CERT_DIR" "$TEMP_DIR/caddy-certs/" 2>/dev/null && echo "   ✓ Certificates backed up" || \
        echo "   ⚠️  Caddy certificates not accessible (may need sudo)"
fi

# Backup Caddyfile
if [ -f "/etc/caddy/Caddyfile" ]; then
    echo "📦 Backing up Caddyfile..."
    mkdir -p "$TEMP_DIR/etc/caddy"
    sudo cp /etc/caddy/Caddyfile "$TEMP_DIR/etc/caddy/" 2>/dev/null && echo "   ✓ Caddyfile backed up" || \
        cp /etc/caddy/Caddyfile "$TEMP_DIR/etc/caddy/" 2>/dev/null || \
        echo "   ⚠️  Caddyfile not accessible"
fi

# Backup AWS config
if [ -d "$HOME/.aws" ]; then
    echo "📦 Backing up AWS config..."
    mkdir -p "$TEMP_DIR/aws"
    cp -r "$HOME/.aws" "$TEMP_DIR/aws/" 2>/dev/null || echo "   ⚠️  AWS config not accessible"
fi

# Backup GitHub CLI config
if [ -d "$HOME/.config/gh" ]; then
    echo "📦 Backing up GitHub CLI config..."
    mkdir -p "$TEMP_DIR/gh"
    cp -r "$HOME/.config/gh" "$TEMP_DIR/gh/" 2>/dev/null || echo "   ⚠️  GH config not accessible"
fi

# Backup SSH authorized_keys
if [ -f "$HOME/.ssh/authorized_keys" ]; then
    echo "📦 Backing up SSH authorized_keys..."
    mkdir -p "$TEMP_DIR/ssh"
    cp "$HOME/.ssh/authorized_keys" "$TEMP_DIR/ssh/" 2>/dev/null || echo "   ⚠️  authorized_keys not accessible"
fi

# Check if we have anything to backup
if [ -z "$(ls -A $TEMP_DIR)" ]; then
    echo "❌ No system configs found to backup"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Create tarball and stream to S3
echo "📤 Uploading to S3..."
cd "$TEMP_DIR"
tar czf - . \
    | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
        --storage-class STANDARD_IA

# Cleanup
cd /
rm -rf "$TEMP_DIR"

END=$(date +%s)
DURATION=$((END - START))

echo "✅ System configs backed up in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/${BACKUP_NAME}"

# Get size from S3
sleep 1
SIZE_INFO=$(aws s3 ls "${S3_BUCKET}/${BACKUP_NAME}" 2>/dev/null || echo "")
if [ -n "$SIZE_INFO" ]; then
    SIZE_BYTES=$(echo "$SIZE_INFO" | awk '{print $3}')
    SIZE_KB=$((SIZE_BYTES / 1024))
    echo "📊 Size: ${SIZE_KB}KB"
fi

echo "⏱️  End: $(date +%H:%M:%S)"

# Save latest backup name
echo "${BACKUP_NAME}" > /tmp/latest-system-backup.txt
aws s3 cp /tmp/latest-system-backup.txt "${S3_BUCKET}/latest-${INSTANCE_NAME}.txt"