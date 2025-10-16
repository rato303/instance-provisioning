#!/bin/bash

set -e

# パラメータ名
PARAM_BACKEND_URL="/pulumi/backend/url"
PARAM_BACKEND_REGION="/pulumi/backend/region"

echo "=================================================="
echo "  Pulumiバックエンド設定をParameter Storeに保存"
echo "=================================================="
echo ""

# バックエンドURLの入力
echo "PulumiバックエンドURL（S3バケットのURL）を入力してください"
echo "例: s3://my-pulumi-state-bucket"
echo ""
while true; do
    read -p "バックエンドURL: " BACKEND_URL
    if [ -n "$BACKEND_URL" ]; then
        break
    else
        echo "エラー: バックエンドURLは必須です。再度入力してください。"
        echo ""
    fi
done

# リージョンの入力
echo ""
echo "AWSリージョンを入力してください"
echo "例: ap-northeast-1, us-east-1, eu-west-1"
echo ""
while true; do
    read -p "リージョン: " REGION
    if [ -n "$REGION" ]; then
        break
    else
        echo "エラー: リージョンは必須です。再度入力してください。"
        echo ""
    fi
done

echo ""
echo "以下の設定をParameter Storeに保存します:"
echo "  バックエンドURL: ${BACKEND_URL}"
echo "  リージョン:       ${REGION}"
echo ""

read -p "続行しますか? [y/N]: " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "キャンセルされました。"
    exit 0
fi

echo ""
echo "Parameter Storeに保存中..."

# バックエンドURLを保存
aws ssm put-parameter \
    --name "${PARAM_BACKEND_URL}" \
    --value "${BACKEND_URL}" \
    --type "String" \
    --overwrite \
    --region "${REGION}" \
    --description "Pulumi state backend S3 URL" > /dev/null

if [ $? -eq 0 ]; then
    echo "✓ ${PARAM_BACKEND_URL} を保存しました"
else
    echo "✗ ${PARAM_BACKEND_URL} の保存に失敗しました"
    exit 1
fi

# リージョンを保存
aws ssm put-parameter \
    --name "${PARAM_BACKEND_REGION}" \
    --value "${REGION}" \
    --type "String" \
    --overwrite \
    --region "${REGION}" \
    --description "AWS region for Pulumi operations" > /dev/null

if [ $? -eq 0 ]; then
    echo "✓ ${PARAM_BACKEND_REGION} を保存しました"
else
    echo "✗ ${PARAM_BACKEND_REGION} の保存に失敗しました"
    exit 1
fi

echo ""
echo "=================================================="
echo "  ✓ バックエンド設定の保存が完了しました！"
echo "=================================================="
echo ""
echo "次のステップ:"
echo "  1. IAMロールに必要な権限を追加してください（詳細はREADME.mdを参照）"
echo "  2. 'make login' でPulumiにログインしてください"
echo ""
