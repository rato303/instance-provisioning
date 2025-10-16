.PHONY: help generate upload download delete info clean

# スクリプトディレクトリ
SCRIPTS_DIR := $(shell pwd)
# Secrets Managerのシークレット名
SECRET_NAME := ansible/ssh-key
# AWSリージョン
AWS_REGION := ap-northeast-1

help:
	@echo "Ansible SSH鍵管理ツール"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  make generate  - Ansible用の新しいSSH鍵ペアを生成"
	@echo "  make upload    - SSH鍵をAWS Secrets Managerにアップロード"
	@echo "  make download  - SSH鍵をAWS Secrets Managerからダウンロード"
	@echo "  make info      - 現在の鍵情報を表示"
	@echo "  make delete    - SSH鍵をAWS Secrets Managerから削除"
	@echo "  make clean     - ローカルの鍵ファイルを削除"
	@echo ""

generate:
	@bash $(SCRIPTS_DIR)/generate-key.sh

upload:
	@bash $(SCRIPTS_DIR)/upload-to-secrets-manager.sh $(SECRET_NAME) $(AWS_REGION)

download:
	@bash $(SCRIPTS_DIR)/download-from-secrets-manager.sh $(SECRET_NAME) $(AWS_REGION)

info:
	@bash $(SCRIPTS_DIR)/show-key-info.sh $(SECRET_NAME) $(AWS_REGION)

delete:
	@bash $(SCRIPTS_DIR)/delete-from-secrets-manager.sh $(SECRET_NAME) $(AWS_REGION)

clean:
	@bash $(SCRIPTS_DIR)/clean-local-keys.sh
