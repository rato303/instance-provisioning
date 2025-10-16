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

# Secrets Managerのシークレット名（引数から取得、デフォルト値あり）
SECRET_NAME="${1:-ansible/ssh-key}"
# AWSリージョン（引数から取得、デフォルト値あり）
AWS_REGION="${2:-ap-northeast-1}"

echo "=================================================="
echo "  SSH鍵をAWS Secrets Managerにアップロード"
echo "=================================================="
echo ""

# 鍵ファイルの存在確認
if [[ ! -f "${PRIVATE_KEY}" ]] || [[ ! -f "${PUBLIC_KEY}" ]]; then
    echo "✗ エラー: SSH鍵が ${KEY_DIR} に見つかりません"
    echo ""
    echo "まず 'make generate' を実行してSSH鍵を作成してください。"
    exit 1
fi

echo "シークレット名: ${SECRET_NAME}"
echo "AWSリージョン: ${AWS_REGION}"
echo ""

# 鍵ファイルの内容を読み込み
PRIVATE_KEY_CONTENT=$(cat "${PRIVATE_KEY}")
PUBLIC_KEY_CONTENT=$(cat "${PUBLIC_KEY}")

# JSONペイロードを作成
SECRET_VALUE=$(jq -n \
    --arg private_key "${PRIVATE_KEY_CONTENT}" \
    --arg public_key "${PUBLIC_KEY_CONTENT}" \
    '{
        private_key: $private_key,
        public_key: $public_key
    }')

# シークレットが既に存在するかチェック
echo "シークレットの存在を確認中..."
SECRET_INFO=$(aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${AWS_REGION}" 2>&1)

if [[ $? -eq 0 ]]; then
    # シークレットが削除予定かどうかをチェック
    DELETION_DATE=$(echo "${SECRET_INFO}" | jq -r '.DeletedDate // empty' 2>/dev/null)

    if [[ -n "${DELETION_DATE}" ]]; then
        echo "シークレットは削除予定です。復元してから更新します..."
        aws secretsmanager restore-secret \
            --secret-id "${SECRET_NAME}" \
            --region "${AWS_REGION}" > /dev/null

        if [[ $? -eq 0 ]]; then
            echo "✓ シークレットを復元しました"
        else
            echo "✗ シークレットの復元に失敗しました"
            exit 1
        fi
    else
        echo "シークレットは既に存在します。更新中..."
    fi

    aws secretsmanager update-secret \
        --secret-id "${SECRET_NAME}" \
        --secret-string "${SECRET_VALUE}" \
        --region "${AWS_REGION}" > /dev/null

    if [[ $? -eq 0 ]]; then
        echo ""
        echo "✓ シークレットの更新に成功しました！"
    else
        echo ""
        echo "✗ シークレットの更新に失敗しました"
        exit 1
    fi
else
    echo "シークレットが存在しません。作成中..."
    aws secretsmanager create-secret \
        --name "${SECRET_NAME}" \
        --description "Ansibleプロビジョニング用のSSH鍵ペア" \
        --secret-string "${SECRET_VALUE}" \
        --region "${AWS_REGION}"

    if [[ $? -eq 0 ]]; then
        echo ""
        echo "✓ シークレットの作成に成功しました！"
    else
        echo ""
        echo "✗ シークレットの作成に失敗しました"
        exit 1
    fi
fi

echo ""
echo "シークレットの詳細:"
echo "  名前:     ${SECRET_NAME}"
echo "  リージョン: ${AWS_REGION}"
echo ""
echo "このシークレットはPulumi/Terraform設定で使用できます。"
