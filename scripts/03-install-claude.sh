#!/bin/bash
set -e

echo "========================================="
echo "Starting ClaudeCode installation..."
echo "========================================="

# nvmとNode.jsを読み込み
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# npmが利用可能か確認
if ! command -v npm &> /dev/null; then
    echo "ERROR: npm is not available" >&2
    exit 1
fi

# ClaudeCodeをグローバルインストール
echo "Installing ClaudeCode globally..."
npm install -g @anthropic-ai/claude-code

# インストール確認
echo "Verifying installation..."
if command -v claude &> /dev/null; then
    echo "ClaudeCode installed successfully!"
    claude --version
else
    echo "ERROR: ClaudeCode installation failed" >&2
    exit 1
fi

echo "========================================="
echo "ClaudeCode installation completed!"
echo "========================================="
