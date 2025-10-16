#!/bin/bash

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 鍵の保存先ディレクトリ
KEY_DIR="${SCRIPT_DIR}/keys"

echo "=================================================="
echo "  ローカルSSH鍵のクリーンアップ"
echo "=================================================="
echo ""

# 鍵ディレクトリが存在するか確認
if [[ ! -d "${KEY_DIR}" ]]; then
    echo "鍵ディレクトリが見つかりません。クリーンアップするものはありません。"
    exit 0
fi

# 鍵ファイルが存在するか確認
if [[ ! -f "${KEY_DIR}/ansible_id_rsa" ]] && [[ ! -f "${KEY_DIR}/ansible_id_rsa.pub" ]]; then
    echo "${KEY_DIR} にSSH鍵が見つかりません"
    exit 0
fi

echo "以下のディレクトリ内の全てのローカルSSH鍵を削除します:"
echo "  ${KEY_DIR}"
echo ""
echo "削除されるファイル:"
ls -lh "${KEY_DIR}"
echo ""

read -p "本当にこれらのファイルを削除しますか？ (yes/no): " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
    echo "操作をキャンセルしました。"
    exit 0
fi

echo ""
echo "ローカルSSH鍵を削除中..."

rm -rf "${KEY_DIR}"

echo "✓ ローカルSSH鍵の削除に成功しました！"
echo ""
echo "注意: これはローカルファイルのみを削除しました。AWS Secrets Managerの鍵は変更されていません。"
echo "AWS Secrets Managerから鍵を削除するには 'make delete' を実行してください"
