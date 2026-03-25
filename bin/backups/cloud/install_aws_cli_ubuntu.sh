#!/bin/bash
set -e

echo "🔵 Installing AWS CLI v2..."

# Download AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip (install unzip if needed)
if ! command -v unzip &> /dev/null; then
    echo "📦 Installing unzip..."
    sudo apt-get update -qq
    sudo apt-get install -y unzip
fi

unzip -q awscliv2.zip

# Install
sudo ./aws/install

# Cleanup
rm -rf aws awscliv2.zip

# Verify
echo ""
echo "✅ AWS CLI installed successfully!"
aws --version

echo ""
echo "🔧 Configure AWS credentials with:"
echo "  aws configure"
echo ""
echo "Or for EC2 instances, attach an IAM role with S3 permissions"