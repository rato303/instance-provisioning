# Inventory Directory

このディレクトリには、Ansibleのインベントリファイルを配置します。

## セットアップ

1. `hosts.example` をコピーして `hosts` を作成:
   ```bash
   cp hosts.example hosts
   ```

2. `hosts` ファイルを編集して、PulumiでプロビジョニングしたEC2インスタンスのIPアドレスを設定:
   ```ini
   [ec2]
   54.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem
   ```

3. SSH接続確認:
   ```bash
   ansible -i hosts ec2 -m ping
   ```

4. Playbookを実行:
   ```bash
   ansible-playbook -i hosts ../provision.yml
   ```

## 注意事項

- `hosts` ファイルは `.gitignore` に含まれているため、Gitにコミットされません
- IPアドレスや秘密鍵のパスなどの機密情報を含むため、誤ってコミットしないよう注意してください
- `hosts.example` はテンプレートとして管理されます
