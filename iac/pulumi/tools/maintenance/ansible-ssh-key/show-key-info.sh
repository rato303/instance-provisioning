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
echo "  SSH鍵情報"
echo "=================================================="
echo ""

# ローカル鍵の確認
echo "ローカルの鍵:"
echo "-----------"
if [[ -f "${PRIVATE_KEY}" ]]; then
    echo "✓ 秘密鍵: ${PRIVATE_KEY}"
    ls -lh "${PRIVATE_KEY}"
else
    echo "✗ 秘密鍵: 見つかりません"
fi

if [[ -f "${PUBLIC_KEY}" ]]; then
    echo "✓ 公開鍵: ${PUBLIC_KEY}"
    ls -lh "${PUBLIC_KEY}"
    echo ""
    echo "公開鍵の内容:"
    cat "${PUBLIC_KEY}"
else
    echo "✗ 公開鍵: 見つかりません"
fi

echo ""
echo ""

# AWS Secrets Managerの確認
echo "AWS Secrets Manager:"
echo "--------------------"
echo "シークレット名: ${SECRET_NAME}"
echo "AWSリージョン: ${AWS_REGION}"
echo ""

if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${AWS_REGION}" &> /dev/null; then
    echo "✓ シークレットはAWS Secrets Managerに存在します"
    echo ""

    # シークレットのメタデータを取得
    aws secretsmanager describe-secret \
        --secret-id "${SECRET_NAME}" \
        --region "${AWS_REGION}" \
        --query '{Name:Name, Description:Description, LastChangedDate:LastChangedDate, CreatedDate:CreatedDate}' \
        --output table

    echo ""
    echo "Secrets Managerから公開鍵を表示するには:"
    echo "  aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ${AWS_REGION} --query SecretString --output text | jq -r '.public_key'"
else
    echo "✗ シークレットはAWS Secrets Managerに存在しません"
fi
