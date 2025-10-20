#!/bin/bash

set -e

# パラメータ名
PARAM_BACKEND_URL="/pulumi/backend/url"
PARAM_BACKEND_REGION="/pulumi/backend/region"

# デフォルトリージョン（Parameter Store取得用）
DEFAULT_REGION="ap-northeast-1"

# リージョンを取得（失敗した場合はデフォルト値を使用）
REGION=$(aws ssm get-parameter \
    --name "${PARAM_BACKEND_REGION}" \
    --query "Parameter.Value" \
    --output text \
    --region "${DEFAULT_REGION}" 2>/dev/null || echo "${DEFAULT_REGION}")

# バックエンドURLを取得
BACKEND_URL=$(aws ssm get-parameter \
    --name "${PARAM_BACKEND_URL}" \
    --query "Parameter.Value" \
    --output text \
    --region "${REGION}" 2>&1)

if [ $? -ne 0 ]; then
    echo "✗ エラー: Parameter Storeからバックエンド設定を取得できませんでした"
    echo ""
    echo "原因の可能性:"
    echo "  1. Parameter Storeに設定が保存されていない"
    echo "  2. IAMロールにssm:GetParameter権限がない"
    echo ""
    echo "解決方法:"
    echo "  1. 'bash scripts/setup-backend-config.sh' を実行してバックエンド設定を保存"
    echo "  2. IAMロールに必要な権限を追加（詳細はREADME.mdを参照）"
    echo ""
    exit 1
fi

echo "バックエンド設定:"
echo "  URL:      ${BACKEND_URL}"
echo "  リージョン: ${REGION}"
echo ""

# AWSリージョンを環境変数として設定（Pulumiが必要とする）
export AWS_REGION="${REGION}"
export AWS_DEFAULT_REGION="${REGION}"

# 既にログインしているかチェック
CURRENT_BACKEND=$(pulumi whoami -v 2>&1 | grep "URL:" | awk '{print $2}' || echo "")

if [ "$CURRENT_BACKEND" = "$BACKEND_URL" ]; then
    echo "✓ 既に ${BACKEND_URL} にログイン済みです"
    exit 0
fi

# Pulumiにログイン
echo "Pulumiバックエンドにログイン中..."
pulumi login "${BACKEND_URL}"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ ログインに成功しました！"
else
    echo ""
    echo "✗ ログインに失敗しました"
    echo ""
    echo "考えられる原因:"
    echo "  1. S3バケットが存在しない"
    echo "  2. IAMロールにS3アクセス権限がない"
    echo ""
    echo "必要なIAM権限については README.md を参照してください。"
    exit 1
fi
