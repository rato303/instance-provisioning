#!/bin/bash

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 鍵の保存先ディレクトリ
KEY_DIR="${SCRIPT_DIR}/keys"
# 秘密鍵のパス
PRIVATE_KEY="${KEY_DIR}/ansible_id_ed25519"
# 公開鍵のパス
PUBLIC_KEY="${KEY_DIR}/ansible_id_ed25519.pub"

echo "=================================================="
echo "  Ansible SSH鍵生成ツール"
echo "=================================================="
echo ""

# 既存の鍵が存在するかチェック
if [[ -f "${PRIVATE_KEY}" ]] || [[ -f "${PUBLIC_KEY}" ]]; then
    echo "警告: SSH鍵が既に ${KEY_DIR} に存在します"
    echo ""
    read -p "既存の鍵を上書きしますか？ (yes/no): " CONFIRM
    if [[ "${CONFIRM}" != "yes" ]]; then
        echo "操作をキャンセルしました。"
        exit 0
    fi
    echo ""
fi

# 鍵ディレクトリが存在しない場合は作成
mkdir -p "${KEY_DIR}"

# 鍵のコメントを入力
read -p "鍵のコメント用のメールアドレスまたは識別子を入力 (デフォルト: ansible@provisioning): " KEY_COMMENT
KEY_COMMENT=${KEY_COMMENT:-ansible@provisioning}

echo ""
echo "SSH鍵ペアを生成中..."
ssh-keygen -t ed25519 -C "${KEY_COMMENT}" -f "${PRIVATE_KEY}" -N ""

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✓ SSH鍵ペアの生成に成功しました！"
    echo ""
    echo "秘密鍵: ${PRIVATE_KEY}"
    echo "公開鍵: ${PUBLIC_KEY}"
    echo ""
    echo "公開鍵の内容:"
    echo "-------------------"
    cat "${PUBLIC_KEY}"
    echo "-------------------"
    echo ""
    echo "次のステップ:"
    echo "  1. 生成された鍵を確認"
    echo "  2. 'make upload' を実行してAWS Secrets Managerにアップロード"
else
    echo "✗ SSH鍵ペアの生成に失敗しました"
    exit 1
fi
