#!/bin/bash
# Restore Docker volumes from S3 with per-volume error handling.
# A failure restoring one volume (e.g. redis_data) should not prevent
# the others (e.g. postgres_data) from being restored.

INSTANCE_NAME="$1"
S3_BUCKET="$2"
TIMESTAMP="$3"  # Optional: specific timestamp

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [timestamp]"
    echo "Example: $0 production-server-1 s3://my-bucket/volume-backups"
    exit 1
fi

echo "🔵 Volume Restore Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# If no timestamp specified, find the latest
if [ -z "$TIMESTAMP" ]; then
    echo "📋 Finding latest backup..."

    TIMESTAMP=$(aws s3 cp "${S3_BUCKET}/latest-backup.txt" - 2>/dev/null | tr -d '[:space:]' || echo "")

    if [ -z "$TIMESTAMP" ]; then
        # Fallback: list timestamp folders, excluding the quick-backup 'latest/' prefix
        TIMESTAMP=$(aws s3 ls "${S3_BUCKET}/" \
            | grep "PRE" \
            | awk '{print $2}' \
            | sed 's|/||g' \
            | grep -v '^latest$' \
            | sort \
            | tail -n 1)
    fi

    if [ -z "$TIMESTAMP" ]; then
        echo "❌ No full backups found in ${S3_BUCKET}"
        exit 1
    fi

    echo "📍 Using timestamp: ${TIMESTAMP}"
fi

# List of volumes to restore
VOLUMES="postgres_data redis_data rails_storage code_config"
FAILED_VOLUMES=""
RESTORED_COUNT=0

for volume in $VOLUMES; do
    echo "📥 Restoring ${volume}..."
    VOL_START=$(date +%s)

    BACKUP_NAME="${volume}-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"

    # Check if backup exists in timestamped folder
    if ! aws s3 ls "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}" > /dev/null 2>&1; then
        echo "   ⚠️  ${BACKUP_NAME} not found in ${TIMESTAMP}/, skipping"
        continue
    fi

    # Remove old volume and create new one
    docker volume rm ${volume} 2>/dev/null || true
    docker volume create ${volume} > /dev/null

    # Stream from S3 directly to volume (no temp file)
    if aws s3 cp "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}" - \
        | docker run --rm -i \
            -v ${volume}:/volume \
            alpine \
            tar xzf - -C /volume; then
        VOL_END=$(date +%s)
        VOL_DURATION=$((VOL_END - VOL_START))
        echo "   ✓ ${volume} restored in ${VOL_DURATION}s"
        RESTORED_COUNT=$((RESTORED_COUNT + 1))
    else
        echo "   ❌ ${volume} restore FAILED"
        FAILED_VOLUMES="${FAILED_VOLUMES} ${volume}"
    fi
done

END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "📊 Volume restore summary: ${RESTORED_COUNT} restored in ${DURATION}s"

if [ -n "$FAILED_VOLUMES" ]; then
    echo "⚠️  Failed volumes:${FAILED_VOLUMES}"
    echo "⏱️  End: $(date +%H:%M:%S)"
    exit 1
else
    echo "✅ All volumes restored in ${DURATION} seconds"
    echo "⏱️  End: $(date +%H:%M:%S)"
    exit 0
fi
