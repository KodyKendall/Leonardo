#!/bin/bash
# This script is meant to be run inside the vscode container within a Leonardo deployment.

# Setup script for Leonardo SSH access
# This script generates an SSH key and configures auto-login to Leonardo server

set -e

SSH_DIR="/config/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
SSH_CONFIG="$SSH_DIR/config"
BASHRC="/config/.bashrc"
LEONARDO_IP=$(curl -4 ifconfig.me)
LEONARDO_USER="ubuntu"

echo "🔧 Setting up Leonardo SSH access..."
echo ""

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key only if it doesn't exist (might be mounted from host)
if [ ! -f "$SSH_KEY" ]; then
    echo "📝 Generating new SSH key..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "leonardo-access"
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
    echo "✅ SSH key generated"
elif [ -r "$SSH_KEY" ]; then
    echo "✅ Using pre-mounted SSH key at $SSH_KEY"
else
    echo "❌ SSH key exists but is not readable at $SSH_KEY"
    exit 1
fi

# Create SSH config
echo "📝 Creating SSH config..."
cat > "$SSH_CONFIG" <<EOF
Host leonardo
    HostName $LEONARDO_IP
    User $LEONARDO_USER
    IdentityFile $SSH_KEY
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    RequestTTY yes
    RemoteCommand cd ~/Leonardo && exec \$SHELL -l
EOF
chmod 600 "$SSH_CONFIG"
echo "✅ SSH config created"

# Add auto-connect to .bashrc if not already present
if ! grep -q "LEONARDO_CONNECTED" "$BASHRC" 2>/dev/null; then
    echo "📝 Adding auto-connect option to .bashrc..."
    cat >> "$BASHRC" <<'EOF'

# Leonardo SSH auto-connect
# Set AUTO_SSH_LEONARDO=1 in your environment or uncomment the line below to enable
export AUTO_SSH_LEONARDO=1

# Alias for quick access
alias leo='ssh leonardo'

# Auto-connect to Leonardo server when opening a new terminal (if enabled)
if [[ $- == *i* ]] && [ -z "$SSH_CONNECTION" ] && [ -z "$LEONARDO_CONNECTED" ] && [ "$AUTO_SSH_LEONARDO" = "1" ]; then
    export LEONARDO_CONNECTED=1
    exec ssh leonardo
fi
EOF
    echo "✅ SSH configuration added to .bashrc"
else
    echo "ℹ️  SSH configuration already in .bashrc"
fi

# Display the public key
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 SETUP COMPLETE! Follow these steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Copy the public key below:"
echo ""
cat "$SSH_KEY.pub"
echo ""
echo "2. Connect to Leonardo:"
echo ""
echo "   • Quick alias: leo"
echo "   • Full command: ssh leonardo"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  AUTO-CONNECT OPTIONS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Auto-connect is DISABLED by default. To enable:"
echo ""
echo "Option 1 - Permanent (recommended):"
echo "   Add to your .bashrc: export AUTO_SSH_LEONARDO=1"
echo ""
echo "Option 2 - Per-session:"
echo "   export AUTO_SSH_LEONARDO=1"
echo "   Then open new terminals"
echo ""
echo "Option 3 - Docker environment variable:"
echo "   Add to docker-compose.yml under 'code' service:"
echo "   environment:"
echo "     - AUTO_SSH_LEONARDO=1"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. On the Leonardo server ($LEONARDO_IP), run:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   echo \"$(cat $SSH_KEY.pub)\" >> ~/.ssh/authorized_keys"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""
