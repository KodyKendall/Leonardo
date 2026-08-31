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

# ─── SI#327: verify this list actually covers where the app stores uploads ───
# The constant above used to BE the whole definition of what we protect, and nothing
# checked it against reality. Seven customer boxes wrote uploads to tmp/storage — not
# one of these volumes — and the nightly backup reported success while capturing none
# of it. Ask the application instead of assuming.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/storage_coverage.sh
[ -f "$SCRIPT_DIR/lib/storage_coverage.sh" ] && . "$SCRIPT_DIR/lib/storage_coverage.sh"

EXTRA_STORAGE_ROOT=""
if command -v root_is_covered >/dev/null 2>&1; then
    STORAGE_ROOT="$(resolve_storage_root llamapress)"
    root_is_covered "$STORAGE_ROOT" /rails/storage
    case "$?" in
      0) echo "✅ Storage coverage: app root ${STORAGE_ROOT} is inside a backed-up volume" ;;
      2) echo "ℹ️  Storage coverage: no local storage root (S3-backed service) — nothing to cover" ;;
      1)
        echo "════════════════════════════════════════════════════════════"
        echo "⚠️  STORAGE NOT COVERED BY THE VOLUME BACKUP"
        echo "   App stores uploads at: ${STORAGE_ROOT}"
        echo "   Backed-up volumes:     ${VOLUMES}"
        echo "   Those files are in the container's writable layer and are DESTROYED"
        echo "   on every image bump. See mothership SI#327."
        echo "   Backing the directory up anyway so the box is protected while the"
        echo "   configuration is corrected."
        echo "════════════════════════════════════════════════════════════"
        EXTRA_STORAGE_ROOT="$STORAGE_ROOT"
        BACKUP_WARNINGS="${BACKUP_WARNINGS:-}storage_root_outside_backed_up_volumes(${STORAGE_ROOT});"
        ;;
    esac
fi

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

# Back up a storage root that lives OUTSIDE the volume set (SI#327). A misconfigured box
# stays protected while its configuration is being fixed, rather than silently having no
# file backup at all.
if [ -n "$EXTRA_STORAGE_ROOT" ]; then
    echo "📦 Backing up out-of-volume storage root ${EXTRA_STORAGE_ROOT}..."
    BACKUP_NAME="rails_storage_outofvolume-${INSTANCE_NAME}-${TIMESTAMP}.tar.gz"
    if docker compose exec -T llamapress tar czf - -C "$EXTRA_STORAGE_ROOT" . 2>/dev/null \
        | aws s3 cp - "${S3_BUCKET}/${TIMESTAMP}/${BACKUP_NAME}"; then
        echo "   ✅ Captured ${EXTRA_STORAGE_ROOT} as ${BACKUP_NAME}"
    else
        echo "   ❌ FAILED to capture ${EXTRA_STORAGE_ROOT} — customer uploads are UNPROTECTED"
    fi
fi

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