set -e

# Base domain configuration - all instances will be created under llamapress.ai
# If you need to support multiple base domains, update TARGET_FQDN variables below
export DOMAIN=llamapress.ai.

echo "=== AWS Lightsail Instance Deployment ==="
echo "This script will create DNS records under llamapress.ai"
echo ""
read -p "Name of instance (e.g., HistoryEducation2): " INSTANCE
read -p "Path to identity file (defaults to ~/.ssh/LightsailDefaultKey-us-east-2.pem): " IDENTITY_FILE
export INSTANCE
export REGION=us-east-2
export AZ=${REGION}a
export BLUEPRINT=ubuntu_24_04
export BUNDLE=small_2_0
export IDENTITY_FILE=${IDENTITY_FILE:-~/.ssh/LightsailDefaultKey-us-east-2.pem}

# Convert instance name to lowercase for DNS (AWS requires lowercase)
INSTANCE_LOWER=$(echo "$INSTANCE" | tr '[:upper:]' '[:lower:]')

echo ""
echo "Creating instance '$INSTANCE' with the following DNS records:"
echo "  - https://${INSTANCE_LOWER}.llamapress.ai"
echo "  - https://rails-${INSTANCE_LOWER}.llamapress.ai"
echo "  - https://vscode-${INSTANCE_LOWER}.llamapress.ai"
echo ""

aws lightsail create-instances \
  --instance-names "$INSTANCE" \
  --availability-zone "$AZ" \
  --blueprint-id "$BLUEPRINT" \
  --bundle-id "$BUNDLE" \
  --region "$REGION"

IPADDRESS=$(aws lightsail get-instance \
              --instance-name "$INSTANCE" \
              --region "$REGION" \
              --query 'instance.publicIpAddress' \
              --output text)

echo $IPADDRESS

cat >> ~/.ssh/config <<EOF
Host $INSTANCE
        HostName $IPADDRESS
        User ubuntu
        IdentityFile $IDENTITY_FILE
        IdentitiesOnly yes
EOF

export ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN" --query 'HostedZones[0].Id' --output text | sed 's|/hostedzone/||')
echo "Route53 Hosted Zone ID: $ZONE_ID"

# Build FQDNs using lowercase instance name
TARGET_FQDN=${INSTANCE_LOWER}.llamapress.ai.
RAILS_TARGET_FQDN=rails-${INSTANCE_LOWER}.llamapress.ai.
VSCODE_TARGET_FQDN=vscode-${INSTANCE_LOWER}.llamapress.ai.

cat > new-a-record.json <<EOF
{
  "Comment": "Add A records for $TARGET_FQDN for LlamaBot Agent Deploy",
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

aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch file://new-a-record.json

echo "Instance created! Now, waiting to open port 443..."
sleep 20

# Open port 443: 
aws lightsail open-instance-public-ports \
  --instance-name "$INSTANCE" \
  --port-info fromPort=443,toPort=443,protocol=TCP \
  --region "$REGION"

#Check port is open on instance
aws lightsail get-instance-port-states \
  --instance-name "$INSTANCE" \
  --region "$REGION" \
  --query 'portStates[?fromPort==`443`]'

echo "Instance is ready to be used! type command ssh $INSTANCE to connect to it, then paste the following command to install the agent: "
echo "curl -fsSL "https://raw.githubusercontent.com/KodyKendall/LlamaBot/refs/heads/main/bin/install_llamabot_prod.sh" -o install_llamabot_prod.sh && bash install_llamabot_prod.sh"

ssh $INSTANCE

# REGION=us-east-1
# REGION=us-east-2
# INSTANCE=HistoryEducation
# # LIST ALL INSTANCES:

# aws lightsail get-instances \
#   --region $REGION \
#   --query 'instances[*].[name,publicIpAddress]' \
#   --output table

# #DELETE AN INSTANCE:

# aws lightsail delete-instance \
#   --instance-name "$INSTANCE" \
#   --region "$REGION"

# Take a postgres database backup