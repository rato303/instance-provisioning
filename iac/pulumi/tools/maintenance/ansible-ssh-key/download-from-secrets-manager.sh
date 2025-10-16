#!/bin/bash

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 鍵の保存先ディレクトリ
KEY_DIR="${SCRIPT_DIR}/keys"
# 秘密鍵のパス
PRIVATE_KEY="${KEY_DIR}/ansible_id_rsa"
# 公開鍵のパス
PUBLIC_KEY="${KEY_DIR}/ansible_id_rsa.pub"

# Secrets Managerのシークレット名（引数から取得、デフォルト値あり）
SECRET_NAME="${1:-ansible/ssh-key}"
# AWSリージョン（引数から取得、デフォルト値あり）
AWS_REGION="${2:-ap-northeast-1}"

echo "=================================================="
echo "  SSH鍵をAWS Secrets Managerからダウンロード"
echo "=================================================="
echo ""

# ローカルの鍵が既に存在するかチェック
if [[ -f "${PRIVATE_KEY}" ]] || [[ -f "${PUBLIC_KEY}" ]]; then
    echo "警告: ローカルのSSH鍵が既に ${KEY_DIR} に存在します"
    echo ""
    read -p "既存のローカル鍵を上書きしますか？ (yes/no): " CONFIRM
    if [[ "${CONFIRM}" != "yes" ]]; then
        echo "操作をキャンセルしました。"
        exit 0
    fi
    echo ""
fi

echo "シークレット名: ${SECRET_NAME}"
echo "AWSリージョン: ${AWS_REGION}"
echo ""

# AWS Secrets Managerからシークレットを取得
echo "AWS Secrets Managerからシークレットを取得中..."
SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRET_NAME}" \
    --region "${AWS_REGION}" \
    --query SecretString \
    --output text)

if [[ $? -ne 0 ]]; then
    echo "✗ AWS Secrets Managerからシークレットの取得に失敗しました"
    exit 1
fi

# 鍵ディレクトリが存在しない場合は作成
mkdir -p "${KEY_DIR}"

# JSONから鍵を抽出
echo "${SECRET_VALUE}" | jq -r '.private_key' > "${PRIVATE_KEY}"
echo "${SECRET_VALUE}" | jq -r '.public_key' > "${PUBLIC_KEY}"

# 適切なパーミッションを設定
chmod 600 "${PRIVATE_KEY}"
chmod 644 "${PUBLIC_KEY}"

echo "✓ SSH鍵のダウンロードに成功しました！"
echo ""
echo "秘密鍵: ${PRIVATE_KEY}"
echo "公開鍵: ${PUBLIC_KEY}"
echo ""
echo "公開鍵の内容:"
echo "-------------------"
cat "${PUBLIC_KEY}"
echo "-------------------"
