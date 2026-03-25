#!/bin/bash
set -e

# Quick install script for Claude Code
# Usage: ./install_claude_code.sh

echo "🤖 Installing Claude Code..."

# Install Claude Code globally via npm
sudo npm install -g @anthropic-ai/claude-code

# Verify installation
if command -v claude-code &> /dev/null; then
    echo "✅ Claude Code installed successfully!"
    echo ""
    echo "To use Claude Code:"
    echo "  1. Run: claude-code"
    echo "  2. Or: cd ~/Leonardo && claude-code"
    echo ""
    echo "⚠️  You'll need to authenticate on first run"
else
    echo "❌ Installation failed"
    exit 1
fi
