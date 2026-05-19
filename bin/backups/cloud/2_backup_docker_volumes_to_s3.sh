#!/bin/bash
set -e

# Parse arguments
INSTANCE_NAME="$1"
S3_BUCKET="$2"
BACKUP_FOLDER="$3"  # Shared timestamp folder for this backup session

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket> [backup_folder]"
    echo "Example: $0 production-server-1 s3://my-bucket/volume-backups"
    echo "Example: $0 production-server-1 s3://my-bucket/volume-backups 20251020-153022"
    exit 1
fi

# Use provided backup folder or generate new timestamp
if [ -z "$BACKUP_FOLDER" ]; then
    BACKUP_FOLDER=$(date +%Y%m%d-%H%M%S)
    echo "⚠️  No backup folder specified, generating: ${BACKUP_FOLDER}"
fi

TIMESTAMP="$BACKUP_FOLDER"  # Keep TIMESTAMP variable for backward compatibility

echo "🔵 Fast Volume Backup Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# Source AWS credentials from .env if available (needed on LXD/Hetzner hosts without IMDS)
if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -f .env ]; then
    export $(grep -E '^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_DEFAULT_REGION)=' .env | xargs)
fi

# Detect Docker Compose project name for volume prefix.
# Compose prefixes volumes with the project name (e.g. leonardo_postgres_data).
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')}"

# List of volumes to backup (logical names as defined in docker-compose.yml)
VOLUMES="postgres_data redis_data rails_storage code_config"

for volume in $VOLUMES; do
    echo "📦 Backing up ${volume}..."
    VOL_START=$(date +%s)

    # Resolve actual volume name: prefer Compose-prefixed, fall back to bare
    prefixed="${PROJECT_NAME}_${volume}"
    if docker volume inspect "$prefixed" >/dev/null 2>&1; then
        SOURCE_VOLUME="$prefixed"
    elif docker volume inspect "$volume" >/dev/null 2>&1; then
        SOURCE_VOLUME="$volume"
    else
        echo "   ⚠️  Volume ${volume} not found (tried ${prefixed} and ${volume}), skipping"
        continue
    fi
    echo "   Using volume: ${SOURCE_VOLUME}"

    BACKUP_NAME="${volume}-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"

    # Stream volume directly to S3 (no temp file) - save in timestamped folder
    docker run --rm \
        -v ${SOURCE_VOLUME}:/volume:ro \
        alpine \
        tar czf - -C /volume . \
        | aws s3 cp - "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}" \
            --storage-class STANDARD_IA

    VOL_END=$(date +%s)
    VOL_DURATION=$((VOL_END - VOL_START))
    echo "   ✓ ${volume} done in ${VOL_DURATION}s"
done

END=$(date +%s)
DURATION=$((END - START))

echo "✅ All volumes backed up in ${DURATION} seconds"
echo "📍 ${S3_BUCKET}/${TIMESTAMP}/"
echo "⏱️  End: $(date +%H:%M:%S)"

# Save manifest of what was backed up in timestamped folder
MANIFEST="volumes-${INSTANCE_NAME}-${TIMESTAMP}.txt"
TEMP_MANIFEST=$(mktemp)
echo "Backup timestamp: ${TIMESTAMP}" > "$TEMP_MANIFEST"
echo "Instance: ${INSTANCE_NAME}" >> "$TEMP_MANIFEST"
echo "Volumes: ${VOLUMES}" >> "$TEMP_MANIFEST"
aws s3 cp "$TEMP_MANIFEST" "${S3_BUCKET}/${TIMESTAMP}/${MANIFEST}"
rm -f "$TEMP_MANIFEST"
echo "📋 Manifest: ${MANIFEST}"

# Update latest backup timestamp at root level
TEMP_FILE=$(mktemp)
echo "${TIMESTAMP}" > "$TEMP_FILE"
aws s3 cp "$TEMP_FILE" "${S3_BUCKET}/latest-backup.txt"
rm -f "$TEMP_FILE"