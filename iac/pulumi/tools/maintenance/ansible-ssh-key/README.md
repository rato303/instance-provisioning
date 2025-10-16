# Ansible SSH Key Management Tool

インタラクティブなAnsible用SSH鍵管理ツールです。AWS Secrets Managerと連携して、SSH鍵の生成・アップロード・ダウンロード・削除を簡単に行えます。

## 前提条件

- AWS CLI がインストールされ、適切に設定されていること
- `jq` コマンドがインストールされていること
- SSH鍵を管理するための適切なAWS IAM権限

必要なIAM権限:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:UpdateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:RestoreSecret"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:ansible/ssh-key*"
    }
  ]
}
```

## 使い方

### ヘルプの表示

```bash
make help
```

### 1. SSH鍵ペアの生成

新しいSSH鍵ペア（秘密鍵・公開鍵）を生成します：

```bash
make generate
```

- インタラクティブにコメント（メールアドレスなど）を入力できます
- 既存の鍵がある場合は上書き確認があります
- 生成された鍵は `keys/` ディレクトリに保存されます

### 2. AWS Secrets Managerへのアップロード

生成したSSH鍵をAWS Secrets Managerにアップロードします：

```bash
make upload
```

- シークレット名: `ansible/ssh-key`
- リージョン: `ap-northeast-1`
- 既存のシークレットがある場合は自動的に更新されます

### 3. AWS Secrets Managerからのダウンロード

AWS Secrets Managerに保存されているSSH鍵をダウンロードします：

```bash
make download
```

- ローカルに鍵が既に存在する場合は上書き確認があります
- ダウンロードした鍵には適切なパーミッション（600/644）が設定されます

### 4. 鍵情報の確認

ローカルとAWS Secrets Managerの鍵情報を表示します：

```bash
make info
```

表示される情報:
- ローカル鍵の存在確認とファイル情報
- 公開鍵の内容
- AWS Secrets Managerのシークレット情報（作成日時、更新日時など）

### 5. AWS Secrets Managerからの削除

AWS Secrets Managerからシークレットを削除します：

```bash
make delete
```

- 削除前に確認プロンプトが表示されます
- リカバリーウィンドウ（7-30日）を指定できます
- リカバリーウィンドウ内であれば復元可能です

### 6. ローカル鍵のクリーンアップ

ローカルに保存されているSSH鍵ファイルを削除します：

```bash
make clean
```

- AWS Secrets Managerの鍵には影響しません
- 削除前に確認プロンプトが表示されます

## ディレクトリ構造

```
ansible-ssh-key/
├── Makefile                              # メインのMakeタスク定義
├── README.md                              # このファイル
├── generate-key.sh                        # 鍵生成スクリプト
├── upload-to-secrets-manager.sh           # アップロードスクリプト
├── download-from-secrets-manager.sh       # ダウンロードスクリプト
├── show-key-info.sh                       # 情報表示スクリプト
├── delete-from-secrets-manager.sh         # 削除スクリプト
├── clean-local-keys.sh                    # ローカルクリーンアップスクリプト
└── keys/                                  # 鍵保存ディレクトリ（gitignore対象）
    ├── ansible_id_rsa                     # 秘密鍵
    └── ansible_id_rsa.pub                 # 公開鍵
```

## セキュリティ注意事項

- `keys/` ディレクトリは `.gitignore` に追加してください
- 秘密鍵は絶対にGitリポジトリにコミットしないでください
- 秘密鍵のパーミッションは常に `600` に設定されます
- AWS Secrets Managerは暗号化されて保存されます
- 不要になった鍵は必ず削除してください

## トラブルシューティング

### AWS CLI関連のエラー

```bash
# AWS CLIの設定確認
aws configure list

# 認証情報の確認
aws sts get-caller-identity
```

### jqがインストールされていない

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### パーミッションエラー

スクリプトに実行権限がない場合：

```bash
chmod +x *.sh
```

## ワークフロー例

### 初回セットアップ

```bash
# 1. 鍵を生成
make generate

# 2. AWS Secrets Managerにアップロード
make upload

# 3. 情報確認
make info
```

### 別の環境で鍵を取得

```bash
# 1. AWS Secrets Managerから鍵をダウンロード
make download

# 2. 情報確認
make info
```

### 鍵のローテーション

```bash
# 1. 古い鍵をローカルから削除
make clean

# 2. 新しい鍵を生成
make generate

# 3. AWS Secrets Managerを更新
make upload
```

## Pulumi/Terraformでの使用

生成したSSH公開鍵をEC2インスタンスに設定する例：

```typescript
// Pulumi example
import * as aws from "@pulumi/aws";

// Secrets Managerから鍵を取得
const ansibleSshKey = aws.secretsmanager.getSecretVersionOutput({
    secretId: "ansible/ssh-key",
});

const publicKey = ansibleSshKey.secretString.apply(s => JSON.parse(s).public_key);

// EC2 Key Pairとして登録
const keyPair = new aws.ec2.KeyPair("ansible-key", {
    publicKey: publicKey,
});
```
