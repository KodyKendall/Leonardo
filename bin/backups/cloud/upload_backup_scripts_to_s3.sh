# Create proprietary scripts bucket/folder
aws s3 mb s3://llampress-ai-backups/proprietary-scripts 2>/dev/null || true

# Upload all your backup scripts
aws s3 sync bin/backups/cloud/ \
    s3://llampress-ai-backups/proprietary-scripts/ \
    --exclude "*" --include "*.sh"