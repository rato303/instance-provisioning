# Pulumi Infrastructure as Code

このディレクトリには、AWSリソースをPulumiでプロビジョニングするためのコードが含まれています。

## 前提条件

- Node.js 18以上
- Pulumi CLI
- AWS CLI
- 適切なIAM権限を持つEC2インスタンスロール

## 必要なIAM権限

EC2インスタンスに割り当てるIAMロール（例: `EC2WebAppDeveloper`）に以下の権限が必要です：

### 1. AWS Systems Manager Parameter Store（設定管理用）

```json
{
    "Effect": "Allow",
    "Action": [
        "ssm:GetParameter",
        "ssm:PutParameter"
    ],
    "Resource": [
        "arn:aws:ssm:*:*:parameter/pulumi/*"
    ]
}
```

### 2. S3（Pulumiステートファイル保存用）

```json
{
    "Effect": "Allow",
    "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
    ],
    "Resource": [
        "arn:aws:s3:::pulumi-development-bucket/*"
    ]
},
{
    "Effect": "Allow",
    "Action": [
        "s3:ListBucket"
    ],
    "Resource": [
        "arn:aws:s3:::pulumi-development-bucket"
    ]
}
```

### 3. EC2（インスタンス管理用）

既存の権限に加えて、以下が必要です：

```json
{
    "Effect": "Allow",
    "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeImages",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeKeyPairs",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateTags",
        "ec2:DeleteTags"
    ],
    "Resource": "*"
}
```

### 4. IAM（インスタンスプロファイル管理用）

インスタンス作成時にIAMロールを割り当てるため、以下の権限が必要です：

```json
{
    "Effect": "Allow",
    "Action": [
        "iam:GetRole",
        "iam:GetInstanceProfile",
        "iam:PassRole"
    ],
    "Resource": [
        "arn:aws:iam::*:role/WebBasicDeveloper",
        "arn:aws:iam::*:role/WebSuperDeveloper",
        "arn:aws:iam::*:instance-profile/*"
    ]
}
```

**注意**: Session Manager経由でのプロビジョニングを行う場合、WebSuperDeveloperロールを持つインスタンスから実行する必要があります。

## 初期セットアップ

### 1. Parameter Storeにバックエンド設定を保存

```bash
cd iac/pulumi/tools/maintenance/pulumi-backend
make setup
```

対話形式でバックエンドURLとリージョンを入力します。

### 2. 依存パッケージのインストール

```bash
npm install
```

### 3. Pulumiスタックの設定

スタック設定ファイルをコピーして編集:

```bash
cp Pulumi.dev.yaml.example Pulumi.dev.yaml
```

`Pulumi.dev.yaml` を編集して、実際のVPC ID、Subnet ID、Security Group IDなどを設定してください。

## 使い方

### EC2インスタンスの管理

```bash
cd ec2

# ヘルプを表示
make help

# Pulumiバックエンドにログイン
make login

# 変更内容をプレビュー
make preview

# EC2インスタンスをデプロイ
make up

# デプロイ済みリソース情報を表示
make output

# EC2インスタンスを削除
make destroy
```

**注意**: `make preview`、`make up` などのコマンドは自動的に `make login` を実行するので、通常は明示的に `make login` を実行する必要はありません。

### スタックの切り替え

```bash
# 本番環境にデプロイ
make up STACK=prod

# ステージング環境を削除
make destroy STACK=staging
```

## ディレクトリ構成

```
iac/pulumi/
├── README.md                    # このファイル
├── Pulumi.yaml                  # Pulumiプロジェクト設定
├── Pulumi.dev.yaml             # dev環境の設定
├── Pulumi.dev.yaml.example     # 設定ファイルのサンプル
├── package.json                # Node.js依存関係
├── tsconfig.json               # TypeScript設定
├── ec2/                        # EC2インスタンス管理
│   ├── Makefile               # EC2管理用Makefile
│   ├── login-to-backend.sh    # Pulumiログイン処理
│   └── index.ts               # EC2リソース定義
└── tools/                      # ツール群
    └── maintenance/
        └── pulumi-backend/    # Pulumiバックエンド設定管理
            ├── Makefile
            ├── README.md
            └── setup-backend-config.sh
```

## トラブルシューティング

### `AccessDenied` エラー

Parameter StoreやS3にアクセスできない場合は、IAMロールに必要な権限が付与されているか確認してください。

### `ExpiredTokenException` エラー

古いAWS認証情報が残っている場合は、以下を実行してください：

```bash
rm -rf ~/.aws/
```

EC2インスタンスでは、IAMロールから自動的に認証情報を取得するので、`aws configure` は不要です。

### Pulumiバックエンドにログインできない

1. Parameter Storeに設定が保存されているか確認:
   ```bash
   aws ssm get-parameter --name /pulumi/backend/url --region ap-northeast-1
   ```

2. S3バケットが存在するか確認:
   ```bash
   aws s3 ls s3://pulumi-development-bucket/
   ```

3. IAMロールに必要な権限があるか確認（上記「必要なIAM権限」セクションを参照）

## 参考資料

- [Pulumi Documentation](https://www.pulumi.com/docs/)
- [Pulumi AWS Provider](https://www.pulumi.com/registry/packages/aws/)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
