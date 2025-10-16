#!/bin/bash
set -e

echo "========================================="
echo "Starting prerequisites installation..."
echo "========================================="

# パッケージリストの更新
echo "Updating package list..."
sudo apt-get update -y

# 必須ツールのインストール
echo "Installing essential tools (curl, unzip)..."
sudo apt-get install -y curl unzip

# インストール確認
echo "Verifying installations..."
MISSING_TOOLS=()

for tool in curl unzip; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "ERROR: The following tools are not available: ${MISSING_TOOLS[*]}" >&2
    exit 1
fi

echo "All prerequisites installed successfully!"
echo "========================================="
echo "Prerequisites installation completed!"
echo "========================================="
