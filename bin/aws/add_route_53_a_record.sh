#!/bin/bash
set -e

echo "=== AWS Route53 DNS Record Configuration ==="
echo "This script will create three A records for your domain"
echo ""

# Prompt for inputs
read -p "Base domain (e.g., llamapress.ai): " BASE_DOMAIN

# Validate base domain is not empty
if [ -z "$BASE_DOMAIN" ]; then
  echo "Error: Base domain cannot be empty"
  exit 1
fi

read -p "Subdomain/Instance name (e.g., HistoryEducation2): " INSTANCE

# Validate instance name is not empty
if [ -z "$INSTANCE" ]; then
  echo "Error: Instance name cannot be empty"
  exit 1
fi

read -p "IP Address: " IPADDRESS

# Validate IP address is not empty
if [ -z "$IPADDRESS" ]; then
  echo "Error: IP Address cannot be empty"
  exit 1
fi

read -p "Route53 Hosted Zone ID (optional, will auto-detect if empty): " ZONE_ID

# Add trailing dot to domain if not present
if [[ ! "$BASE_DOMAIN" =~ \.$ ]]; then
  BASE_DOMAIN="${BASE_DOMAIN}."
fi

# Auto-detect Zone ID if not provided
if [ -z "$ZONE_ID" ]; then
  echo "Auto-detecting Route53 Hosted Zone ID for ${BASE_DOMAIN}..."
  ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "$BASE_DOMAIN" \
    --query 'HostedZones[0].Id' \
    --output text | sed 's|/hostedzone/||')

  if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "None" ]; then
    echo "Error: Could not find hosted zone for ${BASE_DOMAIN}"
    exit 1
  fi
fi

echo "Route53 Hosted Zone ID: $ZONE_ID"

# Convert instance name to lowercase for DNS (AWS requires lowercase)
INSTANCE_LOWER=$(echo "$INSTANCE" | tr '[:upper:]' '[:lower:]')

# Build FQDNs using lowercase instance name
TARGET_FQDN=${INSTANCE_LOWER}.${BASE_DOMAIN}
RAILS_TARGET_FQDN=rails-${INSTANCE_LOWER}.${BASE_DOMAIN}
VSCODE_TARGET_FQDN=vscode-${INSTANCE_LOWER}.${BASE_DOMAIN}

echo ""
echo "Creating the following DNS A records:"
echo "  - ${TARGET_FQDN} -> ${IPADDRESS}"
echo "  - ${RAILS_TARGET_FQDN} -> ${IPADDRESS}"
echo "  - ${VSCODE_TARGET_FQDN} -> ${IPADDRESS}"
echo ""
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Create the Route53 change batch JSON
cat > /tmp/route53-a-records.json <<EOF
{
  "Comment": "Add A records for ${INSTANCE_LOWER} (main, rails, vscode)",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${TARGET_FQDN}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          { "Value": "${IPADDRESS}" }
        ]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RAILS_TARGET_FQDN}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          { "Value": "${IPADDRESS}" }
        ]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${VSCODE_TARGET_FQDN}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          { "Value": "${IPADDRESS}" }
        ]
      }
    }
  ]
}
EOF

# Apply the DNS changes
echo "Applying DNS changes..."
aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch file:///tmp/route53-a-records.json

echo ""
echo " DNS records created successfully!"
echo ""
echo "Your domains are now configured:"
echo "  - https://${TARGET_FQDN%\.}"
echo "  - https://${RAILS_TARGET_FQDN%\.}"
echo "  - https://${VSCODE_TARGET_FQDN%\.}"
echo ""
echo "Note: DNS propagation may take a few minutes."

# Clean up temporary file
rm -f /tmp/route53-a-records.json
