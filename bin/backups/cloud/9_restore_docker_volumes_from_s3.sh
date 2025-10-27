#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
TIMESTAMP="$3"  # Optional: specific timestamp

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [timestamp]"
    echo "Example: $0 production-server-1 s3://my-bucket/volume-backups"
    echo "Example: $0 production-server-1 s3://my-bucket/volume-backups 20251020-153022"
    exit 1
fi

echo "🔵 Fast Volume Restore Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# If no timestamp specified, find the latest
if [ -z "$TIMESTAMP" ]; then
    echo "📋 Finding latest backup for ${INSTANCE_NAME}..."
    LATEST=$(aws s3 ls "${S3_BUCKET}/" | grep "volumes-${INSTANCE_NAME}-" | sort | tail -n 1 | awk '{print $4}')
    if [ -z "$LATEST" ]; then
        echo "❌ No backups found for ${INSTANCE_NAME}"
        exit 1
    fi
    # Extract timestamp from manifest filename: volumes-name-20251020-153022.txt
    TIMESTAMP=$(echo "$LATEST" | sed -n "s/volumes-${INSTANCE_NAME}-\(.*\)\.txt/\1/p")
    echo "📍 Using timestamp: ${TIMESTAMP}"
fi

# List of volumes to restore
VOLUMES="postgres_data redis_data rails_storage code_config"

for volume in $VOLUMES; do
    echo "📥 Restoring ${volume}..."
    VOL_START=$(date +%s)
    
    BACKUP_NAME="${volume}-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"
    
    # Check if backup exists
    if ! aws s3 ls "${S3_BUCKET}/${BACKUP_NAME}" > /dev/null 2>&1; then
        echo "   ⚠️  ${BACKUP_NAME} not found, skipping"
        continue
    fi
    
    # Remove old volume and create new one
    docker volume rm ${volume} 2>/dev/null || true
    docker volume create ${volume} > /dev/null
    
    # Stream from S3 directly to volume (no temp file)
    aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" - \
        | docker run --rm -i \
            -v ${volume}:/volume \
            alpine \
            tar xzf - -C /volume
    
    VOL_END=$(date +%s)
    VOL_DURATION=$((VOL_END - VOL_START))
    echo "   ✓ ${volume} restored in ${VOL_DURATION}s"
done

END=$(date +%s)
DURATION=$((END - START))

echo "✅ All volumes restored in ${DURATION} seconds"
echo "⏱️  End: $(date +%H:%M:%S)"