#!/bin/bash
set -e

echo "========================================="
echo "Starting Node.js installation..."
echo "========================================="

# nvmを読み込み
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# nvmが利用可能か確認
if ! command -v nvm &> /dev/null; then
    echo "ERROR: nvm is not available" >&2
    exit 1
fi

# LTS版のNode.jsをインストール
echo "Installing Node.js LTS version..."
nvm install --lts

# デフォルトバージョンとして設定
nvm alias default 'lts/*'

# バージョン確認
echo "Verifying installation..."
node --version
npm --version

echo "========================================="
echo "Node.js installation completed!"
echo "========================================="
