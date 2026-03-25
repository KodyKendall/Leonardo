#!/bin/bash
set -e

# Helper script to select which backup timestamp to use for restore
# This updates the latest-backup.txt file to point to a specific backup

INSTANCE_NAME="$1"
TIMESTAMP="$2"
S3_BUCKET="${3:-s3://llampress-ai-backups/backups/leonardos}"

if [ -z "$INSTANCE_NAME" ]; then
    echo "Usage: $0 <instance_name> [timestamp] [s3_bucket]"
    echo ""
    echo "Examples:"
    echo "  $0 LP-Test5                           # List available backups"
    echo "  $0 LP-Test5 20251022-011843           # Set to use specific backup"
    echo "  $0 LP-Test5 latest                    # Set to use latest backup"
    echo ""
    exit 1
fi

S3_PATH="${S3_BUCKET}/${INSTANCE_NAME}"

echo "════════════════════════════════════════════════════════════"
echo "📦 Backup Version Selector for ${INSTANCE_NAME}"
echo "════════════════════════════════════════════════════════════"
echo "📍 S3 Path: ${S3_PATH}"
echo ""

# Get current selection
CURRENT=$(aws s3 cp "${S3_PATH}/latest-backup.txt" - 2>/dev/null || echo "none")
echo "Current selection: ${CURRENT}"
echo ""

# List all available backups
echo "Available backups:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
BACKUPS=($(aws s3 ls "${S3_PATH}/" | grep "PRE" | awk '{print $2}' | sed 's|/||g' | sort))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "❌ No backups found in ${S3_PATH}/"
    exit 1
fi

# Display numbered list with details
for i in "${!BACKUPS[@]}"; do
    BACKUP="${BACKUPS[$i]}"
    MARKER=""
    if [ "$BACKUP" = "$CURRENT" ]; then
        MARKER=" ← CURRENT"
    fi

    # Get creation date of first file in backup
    FIRST_FILE=$(aws s3 ls "${S3_PATH}/${BACKUP}/" | head -1)
    DATE=$(echo "$FIRST_FILE" | awk '{print $1" "$2}')

    echo "$((i+1)). ${BACKUP}  (${DATE})${MARKER}"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# If no timestamp provided, just list and exit
if [ -z "$TIMESTAMP" ]; then
    echo "💡 To select a backup, run:"
    echo "   $0 ${INSTANCE_NAME} <timestamp>"
    echo ""
    echo "Examples:"
    echo "   $0 ${INSTANCE_NAME} ${BACKUPS[0]}"
    echo "   $0 ${INSTANCE_NAME} latest"
    exit 0
fi

# Handle "latest" keyword
if [ "$TIMESTAMP" = "latest" ]; then
    TIMESTAMP="${BACKUPS[-1]}"
    echo "📍 'latest' resolved to: ${TIMESTAMP}"
fi

# Verify the selected backup exists
if ! aws s3 ls "${S3_PATH}/${TIMESTAMP}/" > /dev/null 2>&1; then
    echo "❌ Backup ${TIMESTAMP} not found in ${S3_PATH}/"
    echo ""
    echo "Available backups:"
    printf '%s\n' "${BACKUPS[@]}"
    exit 1
fi

# Update latest-backup.txt
echo "🔄 Updating latest-backup.txt to: ${TIMESTAMP}"
TEMP_FILE=$(mktemp)
echo "${TIMESTAMP}" > "$TEMP_FILE"
aws s3 cp "$TEMP_FILE" "${S3_PATH}/latest-backup.txt"
rm -f "$TEMP_FILE"

echo "✅ Done! Next restore will use backup: ${TIMESTAMP}"
echo ""
echo "📋 To verify, check files in this backup:"
echo "   aws s3 ls ${S3_PATH}/${TIMESTAMP}/"
echo ""
echo "🚀 To restore using this backup, run:"
echo "   ./master_restore_all.sh ${INSTANCE_NAME} ${S3_PATH}"
echo "════════════════════════════════════════════════════════════"
