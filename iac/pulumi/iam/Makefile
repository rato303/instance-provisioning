.DEFAULT_GOAL := help

# Pulumiスタック名（環境変数で上書き可能）
STACK ?= main

# AWSリージョンをParameter Storeから取得（キャッシュ）
AWS_REGION ?= $(shell aws ssm get-parameter --name /pulumi/backend/region --query "Parameter.Value" --output text --region ap-northeast-1 2>/dev/null || echo "ap-northeast-1")

# 環境変数をエクスポート
export AWS_REGION
export AWS_DEFAULT_REGION := $(AWS_REGION)

help:
	@echo "Pulumi IAMインフラ管理"
	@echo ""
	@echo "使い方: make <ターゲット> [STACK=<スタック名>]"
	@echo ""
	@echo "ターゲット:"
	@echo "  install     - 依存関係をインストール (npm install)"
	@echo "  login       - Pulumiバックエンドにログイン"
	@echo "  stack-list  - スタック一覧を表示"
	@echo "  stack-info  - スタック詳細を表示"
	@echo "  stack-init  - 新しいスタックを作成"
	@echo "  stack-rm    - スタックとリソースを削除"
	@echo "  preview     - 変更をプレビュー"
	@echo "  up          - リソースをデプロイ"
	@echo "  refresh     - リソース状態を同期"
	@echo "  destroy     - リソースを削除"
	@echo "  output      - スタック出力を表示"
	@echo "  config      - スタック設定を表示"
	@echo "  clean       - ローカルキャッシュをクリーンアップ"
	@echo ""
	@echo "パラメータ:"
	@echo "  STACK=<スタック名>    # スタック名（デフォルト: main）"
	@echo ""
	@echo "例:"
	@echo "  make install              # 依存関係をインストール"
	@echo "  make preview              # リソースをプレビュー (mainスタック)"
	@echo "  make up                   # リソースをデプロイ (mainスタック)"
	@echo "  make stack-init STACK=dev # 新しいスタックを作成"
	@echo ""

.PHONY: install login stack-list stack-info stack-init stack-rm preview up refresh destroy output config clean

install:
	@echo "=================================================="
	@echo "  依存関係をインストール中 (IAM)"
	@echo "=================================================="
	@echo ""
	@npm install
	@echo ""
	@echo "✓ 依存関係をインストールしました"
	@echo ""

login:
	@bash ./login-to-backend.sh

stack-list:
	@echo "=================================================="
	@echo "  利用可能なPulumiスタック (IAM)"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi stack ls

stack-info:
	@echo "=================================================="
	@echo "  スタック詳細: $(STACK) (IAM)"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi stack --stack $(STACK) --show-ids --show-urns

stack-init:
	@echo "=================================================="
	@echo "  新しいスタックを作成: $(STACK) (IAM)"
	@echo "=================================================="
	@echo ""
	@echo "パスフレーズ設定:"
	@echo "  1. パスフレーズなし（デフォルト、開発環境推奨）"
	@echo "  2. パスフレーズあり"
	@echo ""
	@read -p "選択 [1/2] (デフォルト: 1): " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then \
		echo ""; \
		echo "パスフレーズなしでスタックを作成中..."; \
		export PULUMI_CONFIG_PASSPHRASE=""; \
		pulumi stack init $(STACK); \
	elif [ "$$choice" = "2" ]; then \
		echo ""; \
		echo "パスフレーズを入力してください（今後の操作に必要になります）:"; \
		pulumi stack init $(STACK); \
	else \
		echo ""; \
		echo "無効な選択です。キャンセルしました。"; \
		exit 1; \
	fi
	@echo ""
	@echo "✓ スタック '$(STACK)' を作成しました"
	@echo ""
	@echo "次のステップ:"
	@echo "  1. Pulumi.$(STACK).yaml を編集して設定を追加"
	@echo "  2. make preview STACK=$(STACK)"
	@echo "  3. make up STACK=$(STACK)"
	@echo ""

stack-rm:
	@echo "=================================================="
	@echo "  スタックを削除: $(STACK) (IAM)"
	@echo "=================================================="
	@echo ""
	@echo "警告: この操作は以下を実行します:"
	@echo "  1. スタック内の全リソースを削除"
	@echo "  2. スタックとその履歴を削除"
	@echo ""
	@read -p "続行しますか? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo ""; \
		echo "ステップ1: リソースを削除中..."; \
		export PULUMI_CONFIG_PASSPHRASE=""; \
		pulumi destroy --stack $(STACK) --yes || true; \
		echo ""; \
		echo "ステップ2: スタックを削除中..."; \
		pulumi stack rm $(STACK) --yes; \
		echo ""; \
		echo "✓ スタック '$(STACK)' を削除しました"; \
		echo ""; \
		echo "注意: Pulumi.$(STACK).yaml が残っている場合は手動で削除してください。"; \
	else \
		echo ""; \
		echo "キャンセルしました。"; \
	fi

preview: login
	@echo "=================================================="
	@echo "  変更をプレビュー (IAM/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi preview --stack $(STACK)

up: login
	@echo "=================================================="
	@echo "  インフラをデプロイ (IAM/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi up --stack $(STACK) --yes

refresh: login
	@echo "=================================================="
	@echo "  リソース状態を同期 (IAM/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi refresh --stack $(STACK) --yes

destroy: login
	@echo "=================================================="
	@echo "  リソースを削除 (IAM/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi destroy --stack $(STACK)

output: login
	@echo "=================================================="
	@echo "  スタック出力 (IAM/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	(pulumi stack output --stack $(STACK) --json | jq -r 'to_entries[] | "\(.key): \(.value)"' || pulumi stack output --stack $(STACK))

config:
	@echo "=================================================="
	@echo "  スタック設定 (IAM/$(STACK))"
	@echo "=================================================="
	@echo ""
	@echo "スタック: $(STACK)"
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	pulumi config --stack $(STACK)

clean:
	@echo "=================================================="
	@echo "  ローカルキャッシュをクリーンアップ (IAM)"
	@echo "=================================================="
	@echo ""
	@rm -rf node_modules .pulumi
	@echo "✓ キャッシュをクリーンアップしました"
	@echo ""
	@echo "次回使用前に 'make install' を実行してください。"
	@echo ""
