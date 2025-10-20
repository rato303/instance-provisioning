.DEFAULT_GOAL := help

# Pulumiスタック名（環境変数で上書き可能）
STACK ?= dev

# AWSリージョンをParameter Storeから取得（キャッシュ）
AWS_REGION ?= $(shell aws ssm get-parameter --name /pulumi/backend/region --query "Parameter.Value" --output text --region ap-northeast-1 2>/dev/null || echo "ap-northeast-1")

# 環境変数をエクスポート
export AWS_REGION
export AWS_DEFAULT_REGION := $(AWS_REGION)

help:
	@echo "Pulumiインフラ管理"
	@echo ""
	@echo "使い方: make <ターゲット> DIR=<iam|ec2> [STACK=<スタック名>]"
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
	@echo "  DIR=<iam|ec2>         # 対象ディレクトリ（必須）"
	@echo "  STACK=<スタック名>    # スタック名（デフォルト: dev）"
	@echo ""
	@echo "例:"
	@echo "  make install DIR=iam            # IAMの依存関係をインストール"
	@echo "  make preview DIR=iam            # IAMリソースをプレビュー (devスタック)"
	@echo "  make up DIR=ec2 STACK=prod      # EC2リソースをデプロイ (prodスタック)"
	@echo "  make stack-init DIR=iam         # 新しいIAMスタックを作成"
	@echo "  make stack-rm DIR=ec2 STACK=old # 古いEC2スタックを削除"
	@echo ""

.PHONY: install login stack-list stack-info stack-init stack-rm preview up refresh destroy output config clean

# DIRパラメータの検証
check-dir:
	@if [ -z "$(DIR)" ]; then \
		echo "エラー: DIRパラメータが必要です"; \
		echo ""; \
		echo "使い方: make <ターゲット> DIR=<iam|ec2>"; \
		echo ""; \
		echo "例:"; \
		echo "  make install DIR=iam"; \
		echo "  make preview DIR=ec2"; \
		echo ""; \
		exit 1; \
	fi

install: check-dir
	@echo "=================================================="
	@echo "  依存関係をインストール中 ($(DIR))"
	@echo "=================================================="
	@echo ""
	@cd $(DIR) && npm install
	@echo ""
	@echo "✓ $(DIR) の依存関係をインストールしました"
	@echo ""

login: check-dir
	@cd $(DIR) && bash ../login-to-backend.sh

stack-list: check-dir
	@echo "=================================================="
	@echo "  利用可能なPulumiスタック ($(DIR))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi stack ls

stack-info: check-dir
	@echo "=================================================="
	@echo "  スタック詳細: $(STACK) ($(DIR))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi stack --stack $(STACK) --show-ids --show-urns

stack-init: check-dir
	@echo "=================================================="
	@echo "  新しいスタックを作成: $(STACK) ($(DIR))"
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
		cd $(DIR) && pulumi stack init $(STACK); \
	elif [ "$$choice" = "2" ]; then \
		echo ""; \
		echo "パスフレーズを入力してください（今後の操作に必要になります）:"; \
		cd $(DIR) && pulumi stack init $(STACK); \
	else \
		echo ""; \
		echo "無効な選択です。キャンセルしました。"; \
		exit 1; \
	fi
	@echo ""
	@echo "✓ $(DIR) にスタック '$(STACK)' を作成しました"
	@echo ""
	@echo "次のステップ:"
	@echo "  1. Pulumi.$(STACK).yaml を編集して設定を追加"
	@echo "  2. make preview DIR=$(DIR) STACK=$(STACK)"
	@echo "  3. make up DIR=$(DIR) STACK=$(STACK)"
	@echo ""

stack-rm: check-dir
	@echo "=================================================="
	@echo "  スタックを削除: $(STACK) ($(DIR))"
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
		cd $(DIR) && pulumi destroy --stack $(STACK) --yes || true; \
		echo ""; \
		echo "ステップ2: スタックを削除中..."; \
		cd $(DIR) && pulumi stack rm $(STACK) --yes; \
		echo ""; \
		echo "✓ $(DIR) からスタック '$(STACK)' を削除しました"; \
		echo ""; \
		echo "注意: Pulumi.$(STACK).yaml が残っている場合は手動で削除してください。"; \
	else \
		echo ""; \
		echo "キャンセルしました。"; \
	fi

preview: login check-dir
	@echo "=================================================="
	@echo "  変更をプレビュー ($(DIR)/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi preview --stack $(STACK)

up: login check-dir
	@echo "=================================================="
	@echo "  インフラをデプロイ ($(DIR)/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi up --stack $(STACK) --yes

refresh: login check-dir
	@echo "=================================================="
	@echo "  リソース状態を同期 ($(DIR)/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi refresh --stack $(STACK) --yes

destroy: login check-dir
	@echo "=================================================="
	@echo "  リソースを削除 ($(DIR)/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi destroy --stack $(STACK)

output: login check-dir
	@echo "=================================================="
	@echo "  スタック出力 ($(DIR)/$(STACK))"
	@echo "=================================================="
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && (pulumi stack output --stack $(STACK) --json | jq -r 'to_entries[] | "\(.key): \(.value)"' || pulumi stack output --stack $(STACK))

config: check-dir
	@echo "=================================================="
	@echo "  スタック設定 ($(DIR)/$(STACK))"
	@echo "=================================================="
	@echo ""
	@echo "スタック: $(STACK)"
	@echo "ディレクトリ: $(DIR)"
	@echo ""
	@export PULUMI_CONFIG_PASSPHRASE=""; \
	cd $(DIR) && pulumi config --stack $(STACK)

clean: check-dir
	@echo "=================================================="
	@echo "  ローカルキャッシュをクリーンアップ ($(DIR))"
	@echo "=================================================="
	@echo ""
	@cd $(DIR) && rm -rf node_modules .pulumi
	@echo "✓ $(DIR) のキャッシュをクリーンアップしました"
	@echo ""
	@echo "次回使用前に $(DIR) で 'npm install' を実行してください。"
	@echo ""
