.PHONY: help setup show delete

# スクリプトディレクトリ
SCRIPT_DIR := $(shell pwd)
# AWSリージョン（Parameter Store取得用）
AWS_REGION ?= ap-northeast-1
# パラメータ名
PARAM_BACKEND_URL := /pulumi/backend/url
PARAM_BACKEND_REGION := /pulumi/backend/region

help:
	@echo "Pulumiバックエンド設定管理ツール"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  make setup   - バックエンド設定をParameter Storeに保存（初回セットアップ）"
	@echo "  make show    - 現在のバックエンド設定を表示"
	@echo "  make delete  - バックエンド設定をParameter Storeから削除"
	@echo ""

setup:
	@bash $(SCRIPT_DIR)/setup-backend-config.sh

show:
	@echo "=================================================="
	@echo "  現在のPulumiバックエンド設定"
	@echo "=================================================="
	@echo ""
	@echo "バックエンドURL:"
	@aws ssm get-parameter \
		--name "$(PARAM_BACKEND_URL)" \
		--query "Parameter.Value" \
		--output text \
		--region "$(AWS_REGION)" 2>/dev/null || echo "  (未設定)"
	@echo ""
	@echo "リージョン:"
	@aws ssm get-parameter \
		--name "$(PARAM_BACKEND_REGION)" \
		--query "Parameter.Value" \
		--output text \
		--region "$(AWS_REGION)" 2>/dev/null || echo "  (未設定)"
	@echo ""

delete:
	@echo "=================================================="
	@echo "  バックエンド設定を削除"
	@echo "=================================================="
	@echo ""
	@echo "警告: この操作はParameter Storeからバックエンド設定を削除します。"
	@read -p "続行しますか? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo ""; \
		echo "削除中..."; \
		aws ssm delete-parameter --name "$(PARAM_BACKEND_URL)" --region "$(AWS_REGION)" 2>/dev/null && echo "✓ $(PARAM_BACKEND_URL) を削除しました" || echo "  $(PARAM_BACKEND_URL) は存在しません"; \
		aws ssm delete-parameter --name "$(PARAM_BACKEND_REGION)" --region "$(AWS_REGION)" 2>/dev/null && echo "✓ $(PARAM_BACKEND_REGION) を削除しました" || echo "  $(PARAM_BACKEND_REGION) は存在しません"; \
		echo ""; \
		echo "✓ 削除完了"; \
	else \
		echo "キャンセルされました。"; \
	fi
