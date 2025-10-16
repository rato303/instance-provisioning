#!/bin/bash
set -e

echo "========================================="
echo "Starting Pulumi installation..."
echo "========================================="

# 依存関係の確認
echo "Checking dependencies..."
MISSING_DEPS=()

for dep in curl; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "ERROR: Missing required dependencies: ${MISSING_DEPS[*]}" >&2
    echo "Please run 00-install-prerequisites.sh first" >&2
    exit 1
fi

# Pulumiの公式インストールスクリプトを実行
echo "Installing Pulumi..."
curl -fsSL https://get.pulumi.com | sh

# PATHへの追加（.bashrcに追記）
echo "Adding Pulumi to PATH..."
PULUMI_PATH='export PATH=$PATH:$HOME/.pulumi/bin'
if ! grep -q ".pulumi/bin" "$HOME/.bashrc"; then
    echo "$PULUMI_PATH" >> "$HOME/.bashrc"
    echo "Pulumi PATH added to .bashrc"
fi

# 現在のセッションでPATHを設定
export PATH=$PATH:$HOME/.pulumi/bin

# バージョン確認
echo "Verifying installation..."
if command -v pulumi &> /dev/null; then
    echo "Pulumi installed successfully!"
    pulumi version
else
    echo "ERROR: Pulumi installation failed" >&2
    exit 1
fi

echo "========================================="
echo "Pulumi installation completed!"
echo "========================================="
