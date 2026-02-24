#!/bin/bash
# Full SSH setup for VSCode container to access host
# This script combines all steps: key generation, container restart, and SSH config
set -e

cd /home/ubuntu/Leonardo

echo "=== Full SSH Setup for VSCode Container ==="
echo "Started at: $(date)"
echo ""

# Step 1: Generate SSH key on host and add to authorized_keys
echo "Step 1/3: Generating SSH key on host..."
./bin/install/setup-host-ssh-for-vscode.sh
echo ""

# Step 2: Restart VSCode container to pick up mounted keys
echo "Step 2/3: Restarting VSCode container to pick up new keys..."
docker compose restart code
echo ""

# Step 3: Wait for container to start and configure SSH client inside
echo "Step 3/3: Waiting for container and configuring SSH client..."
sleep 5

# Run the container-side SSH config script
# This creates the SSH config file and sets up the 'leonardo' host alias
docker exec code /config/workspace/bin/install/setup-ssh-for-vscode-container.sh || {
    echo ""
    echo "Note: Container SSH config may need manual setup."
    echo "Run this inside the VSCode container:"
    echo "  /config/workspace/bin/install/setup-ssh-for-vscode-container.sh"
}

echo ""
echo "=== SSH Setup Complete ==="
echo ""
echo "Open a new terminal in VSCode - it will auto-connect to the host."
echo "Or manually connect with: ssh leonardo (or alias: leo)"
echo ""
echo "Completed at: $(date)"
