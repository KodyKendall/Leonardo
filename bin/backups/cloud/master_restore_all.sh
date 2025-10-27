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

# Step 2: Restore Docker volumes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 2/6: Restore Docker Volumes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./bin/backups/cloud/9_restore_docker_volumes_from_s3.sh \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}"
echo "✅ Step 2 complete"
echo ""

# Step 3: Start database
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 3/6: Start Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose up -d db redis
sleep 5
echo "✅ Step 3 complete"
echo ""

# Step 4: Restore Postgres data
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 4/6: Restore Postgres Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./bin/backups/cloud/10_restore_postgres_from_s3.sh \
    "${S3_BUCKET}"
echo "✅ Step 4 complete"
echo ""

# Step 5: Restore system configs (SSL certs, Caddyfile, etc.)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 5/6: Restore System Configs & SSL Certificates"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./bin/backups/cloud/7_restore_system_configs_from_s3.sh \
    "${INSTANCE_NAME}" \
    "${S3_BUCKET}"

# Reload Caddy to pick up restored certificates
echo "🔄 Reloading Caddy..."
sudo systemctl reload caddy
echo "✅ Step 5 complete"
echo ""

# Step 6: Update DNS and start all services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 6/6: Update DNS & Start All Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get public IP using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
IPADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)

echo "📍 Public IP: ${IPADDRESS}"

# Update Route 53
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "llamapress.ai." \
  --query 'HostedZones[0].Id' \
  --output text | sed 's|/hostedzone/||')

cat > /tmp/update-dns.json <<EOF
{
  "Comment": "Update A records for ${INSTANCE_NAME} to new EC2 IP",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${INSTANCE_NAME}.llamapress.ai.",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{ "Value": "${IPADDRESS}" }]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "rails-${INSTANCE_NAME}.llamapress.ai.",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{ "Value": "${IPADDRESS}" }]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "vscode-${INSTANCE_NAME}.llamapress.ai.",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{ "Value": "${IPADDRESS}" }]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch file:///tmp/update-dns.json

echo "✅ DNS updated"
echo "   - ${INSTANCE_NAME}.llamapress.ai -> ${IPADDRESS}"
echo "   - rails-${INSTANCE_NAME}.llamapress.ai -> ${IPADDRESS}"
echo "   - vscode-${INSTANCE_NAME}.llamapress.ai -> ${IPADDRESS}"

# Start all services
echo ""
echo "🚀 Starting all services..."
docker compose up -d

echo "✅ Step 6 complete"
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