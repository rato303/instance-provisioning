#!/bin/bash
set -e

echo "========================================="
echo "Starting nvm installation..."
echo "========================================="

# nvmの最新版をインストール
NVM_VERSION="v0.40.1"
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# 環境変数の設定
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# インストール確認
if command -v nvm &> /dev/null; then
    echo "nvm installed successfully!"
    nvm --version
else
    echo "ERROR: nvm installation failed" >&2
    exit 1
fi

echo "========================================="
echo "nvm installation completed!"
echo "========================================="
