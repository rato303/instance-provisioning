.PHONY: help login stack-list stack-info stack-init stack-rm preview up refresh output config clean

# Pulumiスタック名（環境変数で上書き可能）
STACK ?= dev
# ログインスクリプトのパス（同じディレクトリ）
LOGIN_SCRIPT := $(shell pwd)/login-to-backend.sh

# AWSリージョンをParameter Storeから取得（キャッシュ）
AWS_REGION ?= $(shell aws ssm get-parameter --name /pulumi/backend/region --query "Parameter.Value" --output text --region ap-northeast-1 2>/dev/null || echo "ap-northeast-1")

# 環境変数をエクスポート
export AWS_REGION
export AWS_DEFAULT_REGION := $(AWS_REGION)

help:
	@echo "EC2インスタンス管理 (Pulumi)"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  make login      - Pulumiバックエンドにログイン"
	@echo "  make stack-list - 利用可能なスタック一覧を表示"
	@echo "  make stack-info - スタックの詳細情報を表示"
	@echo "  make stack-init - 新しいスタックを作成"
	@echo "  make stack-rm   - スタックとリソースを完全に削除"
	@echo "  make preview    - インフラ変更をプレビュー"
	@echo "  make up         - インフラをデプロイ（EC2インスタンスを作成/更新）"
	@echo "  make refresh    - 実際のリソース状態と同期"
	@echo "  make output     - デプロイ済みリソースの出力値を表示"
	@echo "  make config     - Pulumi設定を表示"
	@echo "  make clean      - ローカルキャッシュをクリーンアップ"
	@echo ""
	@echo "スタック指定: STACK=dev (デフォルト)"
	@echo "例: make stack-init STACK=prod"
	@echo ""

login:
	@bash $(LOGIN_SCRIPT)

stack-list:
	@echo "=================================================="
	@echo "  利用可能なPulumiスタック一覧"
	@echo "=================================================="
	@echo ""
	@cd .. && pulumi stack ls --cwd ec2

stack-info:
	@echo "=================================================="
	@echo "  スタック詳細情報: $(STACK)"
	@echo "=================================================="
	@echo ""
	@cd .. && pulumi stack --stack $(STACK) --cwd ec2 --show-ids --show-urns

stack-init:
	@echo "=================================================="
	@echo "  新しいスタックを作成: $(STACK)"
	@echo "=================================================="
	@echo ""
	@echo "パスフレーズ設定:"
	@echo "  1. パスフレーズなし（デフォルト、推奨：開発環境）"
	@echo "  2. パスフレーズあり"
	@echo ""
	@read -p "選択 [1/2] (デフォルト: 1): " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then \
		echo ""; \
		echo "パスフレーズなしでスタックを作成します..."; \
		export PULUMI_CONFIG_PASSPHRASE=""; \
		cd .. && pulumi stack init $(STACK) --cwd ec2; \
	elif [ "$$choice" = "2" ]; then \
		echo ""; \
		echo "パスフレーズを入力してください（次回以降、このパスフレーズが必要になります）"; \
		cd .. && pulumi stack init $(STACK) --cwd ec2; \
	else \
		echo ""; \
		echo "無効な選択です。キャンセルします。"; \
		exit 1; \
	fi
	@echo ""
	@echo "✓ スタック '$(STACK)' が作成されました"
	@echo ""
	@echo "次のステップ:"
	@echo "  1. Pulumi.$(STACK).yaml を編集して設定を追加"
	@echo "  2. make preview STACK=$(STACK) で変更をプレビュー"
	@echo "  3. make up STACK=$(STACK) でデプロイ"
	@echo ""

preview:
	@echo "=================================================="
	@echo "  インフラ変更をプレビュー中..."
	@echo "=================================================="
	@echo ""
	cd .. && pulumi preview --stack $(STACK) --cwd ec2

up:
	@echo "=================================================="
	@echo "  EC2インスタンスをデプロイ中..."
	@echo "=================================================="
	@echo ""
	cd .. && pulumi up --stack $(STACK) --cwd ec2 --yes

refresh:
	@echo "=================================================="
	@echo "  リソース状態を同期中..."
	@echo "=================================================="
	@echo ""
	cd .. && pulumi refresh --stack $(STACK) --cwd ec2 --yes

stack-rm:
	@echo "=================================================="
	@echo "  スタックを完全に削除: $(STACK)"
	@echo "=================================================="
	@echo ""
	@echo "警告: この操作は以下を実行します:"
	@echo "  1. スタック内の全リソース（EC2インスタンス等）を削除"
	@echo "  2. スタック '$(STACK)' 自体とその履歴を削除"
	@echo ""
	@read -p "続行しますか? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo ""; \
		echo "ステップ1: リソースを削除中..."; \
		pulumi destroy --stack $(STACK) --yes || true; \
		echo ""; \
		echo "ステップ2: スタックを削除中..."; \
		pulumi stack rm $(STACK) --yes; \
		echo ""; \
		echo "✓ スタック '$(STACK)' を完全に削除しました"; \
		echo ""; \
		echo "注意: Pulumi.$(STACK).yaml が残っている場合は手動で削除してください"; \
	else \
		echo ""; \
		echo "キャンセルされました。"; \
	fi

output:
	@echo "=================================================="
	@echo "  デプロイ済みリソース情報"
	@echo "=================================================="
	@echo ""
	@cd .. && (pulumi stack output --stack $(STACK) --cwd ec2 --json | jq -r 'to_entries[] | "\(.key): \(.value)"' || pulumi stack output --stack $(STACK) --cwd ec2)

config:
	@echo "=================================================="
	@echo "  Pulumi設定"
	@echo "=================================================="
	@echo ""
	@echo "スタック: $(STACK)"
	@echo ""
	@cd .. && pulumi config --stack $(STACK) --cwd ec2

clean:
	@echo "=================================================="
	@echo "  ローカルキャッシュをクリーンアップ中..."
	@echo "=================================================="
	@echo ""
	rm -rf node_modules
	rm -rf .pulumi
	@echo "✓ クリーンアップ完了"
	@echo ""
	@echo "次回実行前に 'npm install' を実行してください。"
	@echo ""
