#!/bin/bash
set -e

echo "========================================="
echo "EC2 User Data Script - Starting initialization"
echo "Started at: $(date)"
echo "========================================="

# ログディレクトリの作成
LOG_DIR="/var/log/user-data"
echo "Creating log directory: $LOG_DIR"
sudo mkdir -p "$LOG_DIR"

# スクリプトの配置ディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ログ出力関数
log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | sudo tee -a "$LOG_DIR/main.log"
}

# スクリプト実行関数
run_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local log_file="$LOG_DIR/${script_name%.sh}.log"

    log_message "========================================="
    log_message "Starting: $script_name"
    log_message "========================================="

    if [ ! -f "$script_path" ]; then
        log_message "ERROR: Script not found: $script_path"
        return 1
    fi

    if [ ! -x "$script_path" ]; then
        log_message "Making script executable: $script_path"
        chmod +x "$script_path"
    fi

    # スクリプト実行（ログをファイルと標準出力の両方に出力）
    if bash "$script_path" 2>&1 | sudo tee "$log_file"; then
        log_message "SUCCESS: $script_name completed successfully"
        return 0
    else
        local exit_code=$?
        log_message "ERROR: $script_name failed with exit code $exit_code"
        return $exit_code
    fi
}

# メイン処理開始
log_message "Starting EC2 instance initialization..."

# インストールスクリプトのリスト
SCRIPTS=(
    "00-install-prerequisites.sh"
    "01-install-nvm.sh"
    "02-install-nodejs.sh"
    "03-install-claude.sh"
    "04-install-awscli.sh"
    "05-install-pulumi.sh"
    "06-install-docker.sh"
)

# エラーカウンター
FAILED_SCRIPTS=()

# 各スクリプトを順次実行
for script in "${SCRIPTS[@]}"; do
    if ! run_script "$script"; then
        FAILED_SCRIPTS+=("$script")
        log_message "WARNING: $script failed, but continuing with remaining scripts..."
    fi
done

# 実行結果のサマリー
log_message "========================================="
log_message "EC2 Initialization Summary"
log_message "========================================="
log_message "Total scripts: ${#SCRIPTS[@]}"
log_message "Failed scripts: ${#FAILED_SCRIPTS[@]}"

if [ ${#FAILED_SCRIPTS[@]} -eq 0 ]; then
    log_message "STATUS: All installation scripts completed successfully!"
    log_message "Completed at: $(date)"
    log_message "========================================="
    exit 0
else
    log_message "STATUS: Some scripts failed:"
    for failed in "${FAILED_SCRIPTS[@]}"; do
        log_message "  - $failed"
    done
    log_message "Completed at: $(date)"
    log_message "========================================="
    log_message "Please check individual log files in $LOG_DIR for details"
    exit 1
fi
