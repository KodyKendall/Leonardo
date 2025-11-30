#!/bin/bash
set -e

# Master restore script - runs all restore steps in correct order
# Usage: ./RESTORE_ALL.sh <instance_name> <s3_bucket_path>
# Example: ./RESTORE_ALL.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5

INSTANCE_NAME="$1"
S3_BUCKET="$2"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket_path>"
    echo "Example: $0 LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5"
    exit 1
fi

# Check if this is a new instance (no backups exist)
echo "🔍 Checking for existing backups..."
BACKUP_CHECK=$(aws s3 ls "${S3_BUCKET}/latest-backup.txt" 2>/dev/null || echo "")
if [ -z "$BACKUP_CHECK" ]; then
    # No latest-backup.txt, check for any timestamp folders
    FOLDER_CHECK=$(aws s3 ls "${S3_BUCKET}/" 2>/dev/null | grep "PRE" || echo "")
    if [ -z "$FOLDER_CHECK" ]; then
        echo "════════════════════════════════════════════════════════════"
        echo "🆕 NEW INSTANCE DETECTED"
        echo "════════════════════════════════════════════════════════════"
        echo "📍 Instance: ${INSTANCE_NAME}"
        echo "📍 S3 Path: ${S3_BUCKET}"
        echo ""
        echo "ℹ️  No backups found - this is a brand new instance"
        echo "✅ Skipping restore - instance will use fresh Leonardo installation"
        echo ""
        echo "🎉 Instance is ready to use!"
        echo "════════════════════════════════════════════════════════════"
        exit 0
    fi
fi

echo "════════════════════════════════════════════════════════════"
echo "🚀 MASTER RESTORE: ${INSTANCE_NAME}"
echo "════════════════════════════════════════════════════════════"
echo "📍 S3 Bucket: ${S3_BUCKET}"
echo "⏱️  Start time: $(date)"
echo ""
MASTER_START=$(date +%s)

# Step 1: Restore project files (gets code, .env, docker-compose.yml)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1/6: Restore Project Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ~
rm -rf Leonardo llamapress 2>/dev/null || true

# Download scripts first
mkdir -p Leonardo/bin/backups/cloud
cd Leonardo
aws s3 sync s3://llampress-ai-backups/proprietary-scripts/ bin/backups/cloud/ --exclude "*" --include "*.sh" --quiet
chmod +x bin/backups/cloud/*.sh

# Now restore project files
./bin/backups/cloud/8_restore_project_files_from_s3.sh \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}" \
    /home/ubuntu

# Rename to Leonardo (regardless of what it was called in backup)
cd ~
if [ -d "llamapress" ]; then
    rm -rf Leonardo
    mv llamapress Leonardo
fi

cd ~/Leonardo
echo "✅ Step 1 complete"
echo ""

# Step 2: Restore Docker Volumes (includes postgres_data)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 2/6: Restore Docker Volumes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Stop all services before restoring volumes
docker compose down

./bin/backups/cloud/9_restore_docker_volumes_from_s3.sh \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}"
echo "✅ Step 2 complete"
echo ""

# Step 3: Fix Postgres Password Mismatch
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 3/6: Fix Postgres Password"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# CRITICAL: The restored postgres_data volume has data with one password,
# but the restored .env file may have a different password.
# We need to change the password in postgres to match .env

echo "🚀 Starting postgres with OLD password (from restored volume)..."
docker compose up -d db

# Wait for postgres to be ready (with timeout)
echo "⏳ Waiting for postgres to start..."
TIMEOUT=30
ELAPSED=0
until docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "   ❌ Postgres failed to start within ${TIMEOUT} seconds!"
        exit 1
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo "   ✓ Postgres is ready"

# Get the password from restored .env
NEW_PASSWORD=$(grep "^POSTGRES_PASSWORD=" .env | cut -d= -f2)
echo "🔐 Updating postgres password to match .env..."

# Change the password (using trust auth since we don't know the old password)
# We'll temporarily use local socket auth which doesn't require password
docker compose exec -T db psql -U postgres -c "ALTER USER postgres PASSWORD '$NEW_PASSWORD';" > /dev/null 2>&1

# Verify the new password works
if docker compose exec -T db env PGPASSWORD="$NEW_PASSWORD" psql -U postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo "   ✓ Password updated successfully"
else
    echo "   ❌ Password update failed!"
    exit 1
fi

# Restart all services with new password
echo "🔄 Restarting all services..."
docker compose down
docker compose up -d db redis

# Wait for postgres again
echo "⏳ Waiting for postgres to restart..."
ELAPSED=0
until docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "   ❌ Postgres failed to restart!"
        exit 1
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo "   ✓ Postgres restarted with new password"

echo "✅ Step 3 complete"
echo ""

# Step 4: Restore system configs (SSL certs, Caddyfile, etc.)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 4/6: Restore System Configs & SSL Certificates"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./bin/backups/cloud/7_restore_system_configs_from_s3.sh \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}"

# Reload Caddy to pick up restored certificates
echo "🔄 Reloading Caddy..."
sudo systemctl reload caddy
echo "✅ Step 4 complete"
echo ""

# Step 5: Start all services
# Note: DNS is managed by the Rails app - we don't update it here
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 5/5: Start All Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get public IP using IMDSv2 (for logging purposes)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
IPADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)

echo "📍 Public IP: ${IPADDRESS}"
echo "🌐 DNS already configured by orchestrator"

# Start all services
echo ""
echo "🚀 Starting all services..."
docker compose up -d

echo "✅ Step 5 complete"
echo ""

# Final summary
MASTER_END=$(date +%s)
MASTER_DURATION=$((MASTER_END - MASTER_START))

echo "════════════════════════════════════════════════════════════"
echo "✅ RESTORE COMPLETE!"
echo "════════════════════════════════════════════════════════════"
echo "⏱️  Total time: ${MASTER_DURATION} seconds"
echo "⏱️  End time: $(date)"
echo ""
echo "🌐 Your instance is available at:"
echo "   - https://${INSTANCE_NAME}.llamapress.ai"
echo "   - https://rails-${INSTANCE_NAME}.llamapress.ai"
echo "   - https://vscode-${INSTANCE_NAME}.llamapress.ai"
echo ""
echo "📊 Check service status:"
echo "   docker compose ps"
echo ""
echo "📋 View logs:"
echo "   docker compose logs -f"
echo "════════════════════════════════════════════════════════════"