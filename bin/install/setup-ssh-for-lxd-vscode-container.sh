#!/bin/bash
# Setup script for Leonardo SSH access when the target VM is an LXD container.
#
# LXD containers are not directly reachable from the public internet. SSH access
# requires a ProxyJump through the LXD host (parent node). This script configures
# that jump so `ssh leonardo` works transparently.
#
# Architecture:
#   VSCode container --> [ProxyJump] LXD host (public IP) --> LXD child VM (internal IP)
#
# Two separate SSH keys are generated:
#   1. id_ed25519_lxd_jump   — authorized on the LXD host (parent) with
#                              `restrict,port-forwarding` only. No shell access.
#                              All child VMs share this one jump key for the parent.
#   2. id_ed25519_leonardo   — authorized only on THIS specific child VM.
#                              Unique per child, so a leaked child key cannot be
#                              used to access any other child.

set -e

SSH_DIR="/config/.ssh"
JUMP_KEY="$SSH_DIR/id_ed25519_lxd_jump"
SHARED_JUMP_KEY="/config/workspace/.ssh-shared/id_ed25519_lxd_jump"
CHILD_KEY="$SSH_DIR/id_ed25519_leonardo"
SSH_CONFIG="$SSH_DIR/config"
BASHRC="/config/.bashrc"

# ── Required parameters ──────────────────────────────────────────────────────
# Pass as environment variables or edit here directly.

# LXD host (parent node) — public IP and SSH port
LXD_HOST_USER="${LXD_HOST_USER:-kody}"
LXD_HOST_IP="${LXD_HOST_IP:-}"        # e.g. 65.109.108.78
LXD_HOST_PORT="${LXD_HOST_PORT:-22}"  # change if non-standard, e.g. 2222

# LXD child VM — internal IP and user
LEONARDO_IP="${LEONARDO_IP:-}"        # e.g. 10.137.163.201
LEONARDO_USER="${LEONARDO_USER:-ubuntu}"
# ─────────────────────────────────────────────────────────────────────────────

echo "🔧 Setting up Leonardo SSH access (LXD / ProxyJump mode)..."
echo ""

# Validate required vars
if [ -z "$LXD_HOST_IP" ]; then
    echo "❌ LXD_HOST_IP is not set."
    echo "   Export it before running, e.g.:"
    echo "   LXD_HOST_IP=65.109.108.78 LXD_HOST_PORT=2222 LEONARDO_IP=10.137.163.201 bash $0"
    exit 1
fi
if [ -z "$LEONARDO_IP" ]; then
    echo "❌ LEONARDO_IP is not set."
    echo "   Export it before running, e.g.:"
    echo "   LXD_HOST_IP=65.109.108.78 LXD_HOST_PORT=2222 LEONARDO_IP=10.137.163.201 bash $0"
    exit 1
fi

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Use shared jump key from golden image, or generate a new one
if [ ! -f "$JUMP_KEY" ]; then
    if [ -f "$SHARED_JUMP_KEY" ]; then
        echo "📝 Copying shared LXD jump key from golden image..."
        cp "$SHARED_JUMP_KEY" "$JUMP_KEY"
        cp "${SHARED_JUMP_KEY}.pub" "${JUMP_KEY}.pub"
        chmod 600 "$JUMP_KEY"
        chmod 644 "${JUMP_KEY}.pub"
        echo "✅ Shared jump key installed (no need to add to node authorized_keys)"
    else
        echo "📝 Generating new LXD jump key..."
        ssh-keygen -t ed25519 -f "$JUMP_KEY" -N "" -C "lxd-jump"
        chmod 600 "$JUMP_KEY"
        chmod 644 "$JUMP_KEY.pub"
        echo "✅ Jump key generated (must be added to node authorized_keys)"
    fi
elif [ -r "$JUMP_KEY" ]; then
    echo "✅ Using existing jump key at $JUMP_KEY"
else
    echo "❌ Jump key exists but is not readable at $JUMP_KEY"
    exit 1
fi

# Generate child key (unique to this Leonardo VM)
if [ ! -f "$CHILD_KEY" ]; then
    echo "📝 Generating Leonardo child key..."
    ssh-keygen -t ed25519 -f "$CHILD_KEY" -N "" -C "leonardo-$LEONARDO_IP"
    chmod 600 "$CHILD_KEY"
    chmod 644 "$CHILD_KEY.pub"
    echo "✅ Child key generated"
elif [ -r "$CHILD_KEY" ]; then
    echo "✅ Using existing child key at $CHILD_KEY"
else
    echo "❌ Child key exists but is not readable at $CHILD_KEY"
    exit 1
fi

# Create SSH config with ProxyJump and separate keys per host
echo "📝 Creating SSH config..."
cat > "$SSH_CONFIG" <<EOF
# LXD host (jump node) — proxy-only, no shell access needed
# Uses the shared jump key, authorized on the parent with restrict,port-forwarding
Host lxd-host
    HostName $LXD_HOST_IP
    Port $LXD_HOST_PORT
    User $LXD_HOST_USER
    IdentityFile $JUMP_KEY
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Leonardo child VM — reached via jump through lxd-host
# Uses a child-specific key, so this key only works on this one VM
Host leonardo
    HostName $LEONARDO_IP
    User $LEONARDO_USER
    ProxyJump lxd-host
    IdentityFile $CHILD_KEY
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
# AUTO_SSH_LEONARDO is disabled by default. Set to 1 to enable.
export AUTO_SSH_LEONARDO=0

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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 SETUP COMPLETE! Two keys were generated. Follow these steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1 — Authorize the JUMP KEY on the LXD HOST ($LXD_HOST_USER@$LXD_HOST_IP:$LXD_HOST_PORT)"
echo "         (proxy-only — no shell access)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat "$JUMP_KEY.pub"
echo ""
echo "   Run on the LXD host:"
echo "   echo \"restrict,port-forwarding $(cat $JUMP_KEY.pub)\" >> ~/.ssh/authorized_keys"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2 — Authorize the CHILD KEY on this Leonardo VM ($LEONARDO_USER@$LEONARDO_IP)"
echo "         (this key only works on this specific child)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat "$CHILD_KEY.pub"
echo ""
echo "   Run on the Leonardo VM:"
echo "   echo \"$(cat $CHILD_KEY.pub)\" >> ~/.ssh/authorized_keys"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3 — Test the connection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ssh leonardo"
echo "   # or alias: leo"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  AUTO-CONNECT (disabled by default)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   To enable: set AUTO_SSH_LEONARDO=1 in .bashrc or docker-compose.yml"
echo ""
