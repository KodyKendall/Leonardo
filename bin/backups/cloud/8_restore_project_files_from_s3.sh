#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
RESTORE_DIR="${3:-$HOME}"  # Default to user's home directory
SOURCE_MODE="${4:-full}"   # full | quick
BACKUP_NAME="$5"  # Optional (full mode only): specific backup file

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [restore_dir] [source_mode] [backup_name]"
    echo "  source_mode: full (default) | quick"
    echo "Example (full):  $0 prod-1 s3://my-bucket/project-backups /home/ubuntu full"
    echo "Example (quick): $0 prod-1 s3://my-bucket/project-backups /home/ubuntu quick"
    echo "Example (specific tarball): $0 prod-1 s3://bucket/backups /tmp/restore full project-prod-1-20251020-153022.tar.gz"
    exit 1
fi

if [ "$SOURCE_MODE" != "full" ] && [ "$SOURCE_MODE" != "quick" ]; then
    echo "❌ Invalid source_mode: ${SOURCE_MODE} (expected 'full' or 'quick')"
    exit 1
fi

echo "🔵 Restoring project files (mode=${SOURCE_MODE})..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

mkdir -p "$RESTORE_DIR"

if [ "$SOURCE_MODE" = "quick" ]; then
    # Quick mode: sync from ${S3_BUCKET}/latest/project-files/ into ${RESTORE_DIR}/Leonardo/
    # No --delete: safe as either initial restore (target was rm-rf'd by caller) or as
    # an overlay on top of a full-restore tarball (preserves .git, node_modules, etc.
    # which quick_backup.sh excludes).
    SOURCE_PREFIX="${S3_BUCKET}/latest/project-files/"
    TARGET_DIR="${RESTORE_DIR}/Leonardo"

    # Verify quick backup payload exists
    if ! aws s3 ls "${SOURCE_PREFIX}" > /dev/null 2>&1; then
        echo "❌ No quick backup found at ${SOURCE_PREFIX}"
        exit 1
    fi

    QUICK_TS=$(aws s3 cp "${S3_BUCKET}/latest/last-quick-backup.txt" - 2>/dev/null | tr -d '[:space:]' || true)
    echo "📍 Quick backup timestamp: ${QUICK_TS:-unknown}"
    echo "📥 Syncing ${SOURCE_PREFIX} → ${TARGET_DIR}"

    mkdir -p "$TARGET_DIR"
    aws s3 sync "${SOURCE_PREFIX}" "${TARGET_DIR}/" --only-show-errors

    sudo chown -R ubuntu:ubuntu "$TARGET_DIR"

    FULL_PATH="$TARGET_DIR"
else
    # Full mode: extract a tarball from a timestamped backup folder.
    # If no backup specified, find the latest via the latest-backup.txt pointer.
    if [ -z "$BACKUP_NAME" ]; then
        echo "📋 Finding latest full backup for ${INSTANCE_NAME}..."

        LATEST_TIMESTAMP=$(aws s3 cp "${S3_BUCKET}/latest-backup.txt" - 2>/dev/null | tr -d '[:space:]' || true)

        if [ -z "$LATEST_TIMESTAMP" ]; then
            # Fallback: list timestamp folders, excluding the quick-backup 'latest/' prefix
            LATEST_TIMESTAMP=$(aws s3 ls "${S3_BUCKET}/" \
                | grep "PRE" \
                | awk '{print $2}' \
                | sed 's|/||g' \
                | grep -v '^latest$' \
                | sort \
                | tail -n 1)
        fi

        if [ -z "$LATEST_TIMESTAMP" ]; then
            echo "❌ No full backup pointer or timestamp folder found in ${S3_BUCKET}"
            exit 1
        fi

        echo "📍 Using timestamp: ${LATEST_TIMESTAMP}"

        LATEST=$(aws s3 ls "${S3_BUCKET}/${LATEST_TIMESTAMP}/" | grep "project-${INSTANCE_NAME}-" | awk '{print $4}' | head -n 1)
        if [ -z "$LATEST" ]; then
            echo "❌ No project backup found for ${INSTANCE_NAME} in ${LATEST_TIMESTAMP}/"
            exit 1
        fi

        BACKUP_NAME="${LATEST_TIMESTAMP}/${LATEST}"
        echo "📍 Using: ${BACKUP_NAME}"
    fi

    echo "📥 Downloading and extracting to ${RESTORE_DIR}..."
    cd "$RESTORE_DIR"

    if [ -d "$RESTORE_DIR/Leonardo" ] || [ -d "$RESTORE_DIR/llamapress" ]; then
        echo "🧹 Cleaning up existing project directory..."
        sudo rm -rf "$RESTORE_DIR/Leonardo" "$RESTORE_DIR/llamapress"
    fi

    aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" - \
        | tar -xozf -

    EXTRACTED_DIR=$(find . -maxdepth 1 -type d \( -name "Leonardo" -o -name "llamapress" \) | head -n 1 | sed 's|^\./||')

    if [ -z "$EXTRACTED_DIR" ]; then
        echo "❌ Could not find extracted Leonardo or llamapress folder"
        exit 1
    fi

    echo "🔧 Setting ownership to ubuntu:ubuntu..."
    sudo chown -R ubuntu:ubuntu "$RESTORE_DIR/$EXTRACTED_DIR"

    FULL_PATH="${RESTORE_DIR}/${EXTRACTED_DIR}"
fi

END=$(date +%s)
DURATION=$((END - START))

echo "✅ Project files restored in ${DURATION} seconds"
echo "📁 Restored to: ${FULL_PATH}"
echo "⏱️  End: $(date +%H:%M:%S)"

echo ""
echo "📋 Contents:"
ls -lah "${FULL_PATH}" | head -n 15