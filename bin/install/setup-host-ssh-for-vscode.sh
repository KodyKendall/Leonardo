#!/bin/bash
# Run on host Ubuntu VM to set up SSH access for VSCode container
set -e

SSH_KEY_DIR="$HOME/.ssh"
SSH_KEY="$SSH_KEY_DIR/vscode_container_key"
AUTHORIZED_KEYS="$SSH_KEY_DIR/authorized_keys"

echo "Setting up SSH key for VSCode container access..."

# Ensure .ssh directory exists
mkdir -p "$SSH_KEY_DIR"
chmod 700 "$SSH_KEY_DIR"

# Generate key if not exists
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating new SSH key..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "vscode-container-access"
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
    echo "SSH key generated at $SSH_KEY"
else
    echo "SSH key already exists at $SSH_KEY"
fi

# Add to authorized_keys if not present
if ! grep -q "vscode-container-access" "$AUTHORIZED_KEYS" 2>/dev/null; then
    echo "Adding public key to authorized_keys..."
    cat "$SSH_KEY.pub" >> "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
    echo "Public key added to authorized_keys"
else
    echo "Public key already in authorized_keys"
fi

echo ""
echo "Setup complete! Restart containers with: docker compose down code && docker compose up -d code"
