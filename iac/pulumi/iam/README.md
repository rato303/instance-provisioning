# IAM Roles and Policies

EC2インスタンスに割り当てるIAMロールとポリシーを管理します。

## 概要

Session Manager完全移行に伴い、SSH鍵管理を削除し、IAMロールベースのアクセス制御を導入しました。

### ロールの種類

#### 1. WebBasicDeveloper
通常の開発作業用のロール。

**アタッチされるポリシー:**
- `AmazonSSMManagedInstanceCore` (AWS管理ポリシー)
  - Session Manager経由での接続を受け入れる
- `WebBasicDeveloperPolicy` (カスタムポリシー)
  - ECR/ECS/DynamoDB/S3/Secrets Managerの`dev-*`リソースへのアクセス
  - EC2の読み取り権限のみ（作成・削除権限なし）
  - IAM権限なし

**用途:**
- 通常の開発作業
- `dev-*`プレフィックスのリソースのみを操作
- 他のインスタンスへのSession Manager接続は不可

**含まれない権限**:
- 他インスタンスへのSession Manager接続
- EC2インスタンスの作成・削除
- IAM PassRole

**ファイル構成**:
```
policies/WebBasicDeveloperPolicy.ts    # カスタムポリシー定義
roles/WebBasicDeveloper.ts             # ロールとインスタンスプロファイル定義
```

---

#### 2. WebSuperDeveloper
プロビジョニング作業用のロール（インフラ管理権限付き）。

**アタッチされるポリシー:**
- `AmazonSSMManagedInstanceCore` (AWS管理ポリシー)
  - Session Manager経由での接続を受け入れる
- `WebBasicDeveloperPolicy` (カスタムポリシー)
  - 基本的な開発権限
- `WebSuperDeveloperPolicy` (カスタムポリシー)
  - 全リソースへのフルアクセス（ECR/ECS/DynamoDB/S3/Secrets Manager）
  - EC2インスタンスの作成・削除・起動・停止
  - IAM PassRole権限（WebBasicDeveloper/WebSuperDeveloperロールのみ）
- `WebDeveloperSessionManagerPolicy` (カスタムポリシー)
  - Session Manager経由で他インスタンスに接続
  - `SSMManaged=true`タグ付きインスタンスのみ

**用途:**
- プロビジョニング専用インスタンス
- Pulumiを使ったインフラ管理
- Session Manager経由で他インスタンスに接続してAnsibleでプロビジョニング

**ファイル構成**:
```
policies/WebSuperDeveloperPolicy.ts            # 追加管理権限ポリシー
policies/WebDeveloperSessionManagerPolicy.ts   # Session Manager接続ポリシー
roles/WebSuperDeveloper.ts                     # ロールとインスタンスプロファイル定義
```

## ディレクトリ構造

```
iac/pulumi/iam/
├── README.md                                    # このファイル
├── Pulumi.yaml                                  # Pulumiプロジェクト設定
├── package.json                                 # Node.js依存関係
├── tsconfig.json                                # TypeScript設定
├── index.ts                                     # メインエントリポイント
├── policies/
│   ├── WebBasicDeveloperPolicy.ts               # 基本開発権限ポリシー
│   ├── WebSuperDeveloperPolicy.ts               # 追加管理権限ポリシー
│   └── WebDeveloperSessionManagerPolicy.ts      # Session Manager接続ポリシー
└── roles/
    ├── WebBasicDeveloper.ts                     # 基本開発ロール
    └── WebSuperDeveloper.ts                     # プロビジョニングロール
```

## 使用方法

### ⚠️ 重要: スタック名について

**IAMリソースのスタック名は `main` を使用してください。**

- **IAMスタック**: `main` （環境共通、全EC2インスタンスで共有）
- **EC2スタック**: `dev`, `prod`, `dev6`, `dev7` など（環境やインスタンスごと）

IAMロール（`WebBasicDeveloper`, `WebSuperDeveloper`）は環境に依存しない固定名のため、環境をまたいで共有されます。

### 1. セットアップ

```bash
cd iac/pulumi/iam
npm install
```

または：

```bash
cd iac/pulumi
make install DIR=iam
```

### 2. Pulumiバックエンドにログイン

```bash
cd iac/pulumi
make login DIR=iam
```

### 3. スタックの初期化（初回のみ）

```bash
cd iac/pulumi
make stack-init DIR=iam STACK=main
```

パスフレーズは `1`（パスフレーズなし）を選択してください。

### 4. IAMリソースのデプロイ

```bash
cd iac/pulumi
make up DIR=iam STACK=main
```

### 5. 出力の確認

```bash
cd iac/pulumi
make output DIR=iam STACK=main
```

出力例:
```
webBasicDeveloperInstanceProfileName: WebBasicDeveloper
webBasicDeveloperPolicyArn: arn:aws:iam::123456789012:policy/WebBasicDeveloperPolicy
webBasicDeveloperRoleArn: arn:aws:iam::123456789012:role/WebBasicDeveloper
webSuperDeveloperInstanceProfileName: WebSuperDeveloper
webSuperDeveloperPolicyArn: arn:aws:iam::123456789012:policy/WebSuperDeveloperPolicy
webSuperDeveloperRoleArn: arn:aws:iam::123456789012:role/WebSuperDeveloper
webDeveloperSessionManagerPolicyArn: arn:aws:iam::123456789012:policy/WebDeveloperSessionManagerPolicy
```

## EC2インスタンスとの連携

EC2インスタンス作成時に、これらのロールを選択できます。

### Pulumi.dev.yaml設定例

```yaml
config:
  instance-provisioning:instanceRoleType: basic  # または super
```

- `basic`: WebBasicDeveloperロールを使用（通常の開発インスタンス）
- `super`: WebSuperDeveloperロールを使用（プロビジョニング専用インスタンス）

詳細は[../ec2/README.md](../ec2/README.md)を参照してください。

## Session Manager接続

### WebBasicDeveloperロールのインスタンス
- Session Managerで接続を**受け入れる**ことができます
- 他のインスタンスへは接続できません

```bash
# このインスタンスに接続
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
```

### WebSuperDeveloperロールのインスタンス
- Session Managerで接続を**受け入れる**ことができます
- `SSMManaged=true`タグ付きの他インスタンスに接続できます

```bash
# このインスタンスに接続
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx

# このインスタンスから他インスタンスに接続
aws ssm start-session --target i-yyyyyyyyyyyyyyyyy
```

## 注意事項

1. **IAMリソースは共有**
   - IAMロールとポリシーは、複数のEC2インスタンスで共有されます
   - 一度デプロイすれば、EC2インスタンス作成時に参照できます

2. **権限の最小化**
   - WebBasicDeveloperは`dev-*`プレフィックスのリソースのみにアクセス可能
   - 本番環境のリソースには影響しません

3. **Session Managerタグ**
   - `SSMManaged=true`タグがないインスタンスには、WebSuperDeveloperでも接続できません
   - セキュリティのため、接続対象を明示的に指定します

4. **削除時の注意**
   - IAMロールを削除する前に、そのロールを使用しているEC2インスタンスをすべて削除してください
   - インスタンスがロールを使用中の場合、削除に失敗します

## トラブルシューティング

### デプロイに失敗する

```bash
# リソース状態を同期
cd iac/pulumi
make refresh DIR=iam STACK=main

# 変更をプレビュー
make preview DIR=iam STACK=main
```

### ロールが見つからない

```bash
# 出力を確認
make output DIR=iam STACK=main

# AWS CLIで確認
aws iam list-roles --query 'Roles[?starts_with(RoleName, `WebBasicDeveloper`) || starts_with(RoleName, `WebSuperDeveloper`)]'
```

### Session Manager接続ができない

1. インスタンスにAmazonSSMManagedInstanceCoreポリシーがアタッチされているか確認
2. インスタンスのセキュリティグループでアウトバウンド443ポートが許可されているか確認
3. SSM Agentが起動しているか確認（デフォルトで有効）

```bash
# SSM Agentの状態確認（インスタンス内）
sudo systemctl status amazon-ssm-agent
```

## 関連ドキュメント

- [ISSUE_03_IAM_ROLES.md](../../../ISSUE_03_IAM_ROLES.md) - 実装仕様
- [ISSUE_02_SESSION_MANAGER_MIGRATION.md](../../../ISSUE_02_SESSION_MANAGER_MIGRATION.md) - Session Manager移行
- [IAM_ROLE_MIGRATION_CHANGES.md](../../../IAM_ROLE_MIGRATION_CHANGES.md) - IAMロール移行の変更内容
