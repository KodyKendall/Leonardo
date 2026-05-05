#!/bin/bash
set -e

PROJECT_DIR="${1:-$PWD}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: '$PROJECT_DIR' is not a directory"
    echo "Usage: $0 [project_dir]"
    echo "Example: $0 /home/ubuntu/Leonardo"
    exit 1
fi

PROJECT_FOLDER=$(basename "$PROJECT_DIR")
PARENT_DIR=$(dirname "$PROJECT_DIR")

echo "📁 Project: ${PROJECT_DIR}"
echo ""

RAW_SIZE=$(du -sh "$PROJECT_DIR" | awk '{print $1}')
echo "📦 Raw folder size: ${RAW_SIZE}"

echo "🗜️  Computing compressed tarball size (this matches what gets uploaded to S3)..."
cd "$PARENT_DIR"
TARBALL_BYTES=$(tar czf - \
    --exclude="${PROJECT_FOLDER}/backups" \
    --exclude="${PROJECT_FOLDER}/.claude" \
    --exclude="${PROJECT_FOLDER}/tmp" \
    --exclude="${PROJECT_FOLDER}/log" \
    "${PROJECT_FOLDER}" 2>/dev/null | wc -c)

TARBALL_MB=$(awk "BEGIN {printf \"%.2f\", ${TARBALL_BYTES}/1024/1024}")
TARBALL_KB=$((TARBALL_BYTES / 1024))

echo "✅ Compressed tarball: ${TARBALL_MB} MB (${TARBALL_KB} KB, ${TARBALL_BYTES} bytes)"
echo ""
echo "Excluded: backups/, .claude/, tmp/, log/"
