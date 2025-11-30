#!/bin/bash
set -e

# Fresh EC2 Setup Script
# Run this on a brand new Ubuntu EC2 instance to prepare for restore

echo "════════════════════════════════════════════════════════════"
echo "🔧 Setting up fresh EC2 instance for LlamaPress"
echo "════════════════════════════════════════════════════════════"
echo "⏱️  Start: $(date)"
echo ""
SETUP_START=$(date +%s)

# Step 1: Install AWS CLI v2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 [1/5] Installing AWS CLI v2..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get update -qq
sudo apt-get install -y unzip
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version
echo "✅ AWS CLI installed"
echo ""

# Step 2: Create 4GB swap file
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 [2/6] Creating 4GB swap file..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify swap
SWAP_SIZE=$(free -h | grep Swap | awk '{print $2}')
echo "✅ Swap file created: ${SWAP_SIZE}"
echo ""

# Step 3: Install Docker
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 [3/6] Installing Docker..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
rm get-docker.sh
docker --version
echo "✅ Docker installed"
echo ""

# Step 3: Install Caddy
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 [3/5] Installing Caddy..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update -qq
sudo apt-get install -y caddy
caddy version
echo "✅ Caddy installed"
echo ""

# Step 4: Clone Leonardo repo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 [4/5] Cloning Leonardo repository..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ~
git clone https://github.com/kodykendall/Leonardo.git
cd Leonardo
echo "✅ Leonardo cloned"
echo ""

# Step 5: Download restore scripts from S3
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 [5/5] Downloading restore scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p bin/backups/cloud
aws s3 sync s3://llampress-ai-backups/proprietary-scripts/ bin/backups/cloud/ --exclude "*" --include "*.sh"
chmod +x bin/backups/cloud/*.sh

# Count scripts
SCRIPT_COUNT=$(ls -1 bin/backups/cloud/*.sh 2>/dev/null | wc -l)
echo "✅ Downloaded ${SCRIPT_COUNT} scripts"
echo ""

# Setup complete
SETUP_END=$(date +%s)
SETUP_DURATION=$((SETUP_END - SETUP_START))

echo "════════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "════════════════════════════════════════════════════════════"
echo "⏱️  Total time: ${SETUP_DURATION} seconds"
echo ""
echo "🚀 Next steps:"
echo "   1. Log out and log back in (for Docker group to take effect)"
echo "   2. Run: cd ~/Leonardo"
echo "   3. Run: ./bin/backups/cloud/RESTORE_ALL.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5"
echo ""
echo "Or run directly (will need newgrp):"
echo "   newgrp docker"
echo "   cd ~/Leonardo"
echo "   ./bin/backups/cloud/RESTORE_ALL.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5"
echo "════════════════════════════════════════════════════════════"