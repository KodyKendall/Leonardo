#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket>"
    echo "Example: $0 production-server-1 s3://my-bucket/volume-backups"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "🔵 Fast Volume Backup Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# List of volumes to backup
VOLUMES="postgres_data redis_data rails_storage code_config"

for volume in $VOLUMES; do
    echo "📦 Backing up ${volume}..."
    VOL_START=$(date +%s)
    
    BACKUP_NAME="${volume}-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"
    
    # Stream volume directly to S3 (no temp file)
    docker run --rm \
        -v ${volume}:/volume:ro \
        alpine \
        tar czf - -C /volume . \
        | aws s3 cp - "${S3_BUCKET}/${BACKUP_NAME}" \
            --storage-class STANDARD_IA
    
    VOL_END=$(date +%s)
    VOL_DURATION=$((VOL_END - VOL_START))
    echo "   ✓ ${volume} done in ${VOL_DURATION}s"
done

END=$(date +%s)
DURATION=$((END - START))

echo "✅ All volumes backed up in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/"
echo "⏱️  End: $(date +%H:%M:%S)"

# Save manifest of what was backed up
MANIFEST="volumes-${INSTANCE_NAME}-${TIMESTAMP}.txt"
echo "Backup timestamp: ${TIMESTAMP}" > /tmp/${MANIFEST}
echo "Instance: ${INSTANCE_NAME}" >> /tmp/${MANIFEST}
echo "Volumes: ${VOLUMES}" >> /tmp/${MANIFEST}
aws s3 cp /tmp/${MANIFEST} "${S3_BUCKET}/${MANIFEST}"
echo "📋 Manifest: ${MANIFEST}"