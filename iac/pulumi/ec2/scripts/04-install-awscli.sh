#!/bin/bash
set -e

echo "========================================="
echo "Starting AWS CLI installation..."
echo "========================================="

# 依存関係の確認
echo "Checking dependencies..."
MISSING_DEPS=()

for dep in curl unzip; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "ERROR: Missing required dependencies: ${MISSING_DEPS[*]}" >&2
    echo "Please run 00-install-prerequisites.sh first" >&2
    exit 1
fi

# 作業ディレクトリの作成
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# AWS CLI v2の最新版をダウンロード
echo "Downloading AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# 解凍
echo "Extracting archive..."
unzip -q awscliv2.zip

# インストール実行
echo "Installing AWS CLI..."
sudo ./aws/install

# クリーンアップ
cd - > /dev/null
rm -rf "$TMP_DIR"

# バージョン確認
echo "Verifying installation..."
if command -v aws &> /dev/null; then
    echo "AWS CLI installed successfully!"
    aws --version
else
    echo "ERROR: AWS CLI installation failed" >&2
    exit 1
fi

echo "========================================="
echo "AWS CLI installation completed!"
echo "========================================="
