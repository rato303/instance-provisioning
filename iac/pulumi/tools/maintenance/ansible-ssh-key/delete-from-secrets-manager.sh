#!/bin/bash

set -e

# Secrets Managerのシークレット名（引数から取得、デフォルト値あり）
SECRET_NAME="${1:-ansible/ssh-key}"
# AWSリージョン（引数から取得、デフォルト値あり）
AWS_REGION="${2:-ap-northeast-1}"

echo "=================================================="
echo "  SSH鍵をAWS Secrets Managerから削除"
echo "=================================================="
echo ""

echo "シークレット名: ${SECRET_NAME}"
echo "AWSリージョン: ${AWS_REGION}"
echo ""

# シークレットが存在するか確認
if ! aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${AWS_REGION}" &> /dev/null; then
    echo "✗ シークレットはAWS Secrets Managerに存在しません"
    exit 1
fi

echo "警告: これはAWS Secrets Managerからシークレットを完全に削除します。"
echo "ローカルバックアップがない限り、鍵を復元することはできません。"
echo ""
read -p "本当にこのシークレットを削除しますか？ (yes/no): " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
    echo "操作をキャンセルしました。"
    exit 0
fi

echo ""
read -p "リカバリーウィンドウの日数を入力 (7-30、デフォルト: 30): " RECOVERY_DAYS
RECOVERY_DAYS=${RECOVERY_DAYS:-30}

# リカバリー日数の検証
if [[ ${RECOVERY_DAYS} -lt 7 ]] || [[ ${RECOVERY_DAYS} -gt 30 ]]; then
    echo "✗ リカバリー日数は7から30の間である必要があります"
    exit 1
fi

echo ""
echo "${RECOVERY_DAYS}日のリカバリーウィンドウでシークレットを削除中..."

aws secretsmanager delete-secret \
    --secret-id "${SECRET_NAME}" \
    --recovery-window-in-days ${RECOVERY_DAYS} \
    --region "${AWS_REGION}"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✓ シークレットの削除スケジュールが正常に設定されました！"
    echo ""
    echo "シークレットは${RECOVERY_DAYS}日後に完全に削除されます。"
    echo "この期間中は以下のコマンドで復元できます:"
    echo "  aws secretsmanager restore-secret --secret-id ${SECRET_NAME} --region ${AWS_REGION}"
else
    echo ""
    echo "✗ シークレットの削除に失敗しました"
    exit 1
fi
