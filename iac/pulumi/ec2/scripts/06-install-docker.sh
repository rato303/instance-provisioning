#!/bin/bash
set -e

echo "========================================="
echo "Starting Docker installation..."
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

# 古いバージョンのDockerを削除
echo "Removing old Docker versions if present..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# パッケージリストの更新と必要なパッケージのインストール
echo "Updating package list and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y \
    ca-certificates \
    gnupg \
    lsb-release

# DockerのGPGキーを追加
echo "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Dockerリポジトリの追加
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# パッケージリストの更新
sudo apt-get update -y

# Docker Engineのインストール
echo "Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Dockerサービスの起動と有効化
echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# 現在のユーザーをdockerグループに追加
echo "Adding current user to docker group..."
sudo usermod -aG docker "$USER"

# バージョン確認
echo "Verifying installation..."
if command -v docker &> /dev/null; then
    echo "Docker installed successfully!"
    docker --version
    docker compose version
else
    echo "ERROR: Docker installation failed" >&2
    exit 1
fi

echo "========================================="
echo "Docker installation completed!"
echo "Note: You may need to log out and back in for group changes to take effect."
echo "========================================="
