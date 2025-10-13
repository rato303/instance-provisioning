# EC2 Instance Provisioning with Pulumi

このプロジェクトは、Pulumiを使用してAWS EC2インスタンスを自動的にプロビジョニングし、開発環境を構築するためのツールです。

## 概要

EC2インスタンス起動時に以下のソフトウェアを自動的にインストールします：

- nvm (Node Version Manager)
- Node.js LTS版
- Claude Code
- AWS CLI v2
- Pulumi
- Docker & Docker Compose

## 前提条件

### 必要なツール

- [Node.js](https://nodejs.org/) (v18以上推奨)
- [Pulumi CLI](https://www.pulumi.com/docs/get-started/install/)
- [AWS CLI](https://aws.amazon.com/cli/)
- AWS認証情報の設定

### AWS認証情報の設定

```bash
# AWS CLIで認証情報を設定
aws configure

# または環境変数で設定
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_REGION=ap-northeast-1
```

## セットアップ

### 1. リポジトリのクローンと依存関係のインストール

```bash
git clone <repository-url>
cd instance-provisioning
npm install
```

### 2. Pulumi設定ファイルの作成

既存のVPC、サブネット、セキュリティグループを使用するため、設定ファイルを作成します。

```bash
# テンプレートをコピー
cp Pulumi.dev.yaml.example Pulumi.dev.yaml
```

### 3. Pulumi.dev.yaml の編集

`Pulumi.dev.yaml` を編集して、実際のAWSリソースIDを設定します：

```yaml
config:
  aws:region: ap-northeast-1
  instance-provisioning:vpcId: vpc-xxxxx           # 既存のVPC ID
  instance-provisioning:subnetId: subnet-xxxxx     # 既存のサブネット ID
  instance-provisioning:securityGroupId: sg-xxxxx  # 既存のセキュリティグループ ID
  instance-provisioning:instanceName: dev-instance      # EC2インスタンス名
  instance-provisioning:ami: ami-xxxxx                  # 使用するAMI ID
  instance-provisioning:instanceType: t3.medium         # インスタンスタイプ
  instance-provisioning:sshKeyPairName: your-key-pair   # SSH鍵ペア名
  instance-provisioning:volumeSize: "60"                # EBSボリュームサイズ (GB)
```

#### 既存リソースIDの確認方法

```bash
# VPC IDの確認
aws ec2 describe-vpcs --query 'Vpcs[*].{ID:VpcId,Name:Tags[?Key==`Name`].Value|[0]}' --output table

# サブネットIDの確認
aws ec2 describe-subnets --query 'Subnets[*].{ID:SubnetId,VPC:VpcId,AZ:AvailabilityZone}' --output table

# セキュリティグループIDの確認
aws ec2 describe-security-groups --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName,VPC:VpcId}' --output table
```

### 4. Pulumiスタックの初期化

```bash
# devスタックを選択（既に存在する場合）
pulumi stack select dev

# または新しいスタックを作成
pulumi stack init dev
```

## 使い方

### EC2インスタンスの作成

#### デフォルト設定で作成

```bash
pulumi up
```

#### インスタンス名を指定して作成

```bash
pulumi up --config instanceName=dev4
```

#### 複数の設定を上書きして作成

```bash
pulumi up \
  --config instanceName=dev5 \
  --config instanceType=t3.small \
  --config volumeSize=100
```

### プレビュー（変更内容の確認）

実際にリソースを作成せず、変更内容を確認：

```bash
pulumi preview
```

### インスタンス情報の確認

作成されたインスタンスの情報を表示：

```bash
# すべての出力を表示
pulumi stack output

# 特定の値を表示
pulumi stack output publicIp
pulumi stack output instanceId
```

### SSH接続

```bash
# Public IPを取得して接続
ssh -i /path/to/your-key.pem ubuntu@$(pulumi stack output publicIp)
```

### インスタンスの削除

```bash
pulumi destroy
```

## プロジェクト構造

```
instance-provisioning/
├── index.ts                    # Pulumi メイン設定ファイル
├── scripts/
│   ├── user-data.sh           # EC2起動時のメインスクリプト
│   ├── 00-install-prerequisites.sh  # 前提条件インストール
│   ├── 01-install-nvm.sh      # nvmインストール
│   ├── 02-install-nodejs.sh   # Node.jsインストール
│   ├── 03-install-claude.sh   # ClaudeCodeインストール
│   ├── 04-install-awscli.sh   # AWS CLIインストール
│   ├── 05-install-pulumi.sh   # Pulumiインストール
│   └── 06-install-docker.sh   # Dockerインストール
├── Pulumi.yaml                # Pulumiプロジェクト設定
├── Pulumi.dev.yaml            # 環境固有設定（gitignore対象）
├── Pulumi.dev.yaml.example    # 設定テンプレート
├── package.json
├── tsconfig.json
└── README.md
```

## 設定可能なパラメータ

| パラメータ | 説明 | デフォルト値 | 必須 |
|-----------|------|------------|------|
| `vpcId` | 既存のVPC ID | - | ✓ |
| `subnetId` | 既存のサブネット ID | - | ✓ |
| `securityGroupId` | 既存のセキュリティグループ ID | - | ✓ |
| `instanceName` | EC2インスタンス名 | `dev-instance` | |
| `ami` | AMI ID | `ami-0a71a0b9c988d5e5e` | |
| `instanceType` | インスタンスタイプ | `t3.medium` | |
| `sshKeyPairName` | SSH鍵ペア名 | `pulumi-dev` | |
| `volumeSize` | EBSボリュームサイズ (GB) | `60` | |

## 自動付与されるEC2タグ

作成されるEC2インスタンスには、以下のタグが自動的に付与されます：

| タグ名 | 説明 | 値の例 |
|--------|------|--------|
| `Name` | インスタンス名 | `dev-instance` |
| `ProvisioningRepositoryVersion` | プロビジョニングに使用されたGitコミットハッシュ | `a1b2c3d4e5f6...` |
| `ProvisionedBy` | プロビジョニングに使用されたリポジトリ名 | `instance-provisioning` |

これらのタグにより、どのバージョンのコードからインスタンスが作成されたかを追跡できます。

### タグの確認方法

```bash
# AWS CLIでタグを確認
aws ec2 describe-tags --filters "Name=resource-id,Values=$(pulumi stack output instanceId)"

# Pulumiの出力からGitコミットハッシュを確認
pulumi stack output provisioningRepositoryVersion
```

## エクスポートされる値

Pulumiスタックからエクスポートされる値：

- `instanceId`: EC2インスタンスID
- `publicIp`: パブリックIPアドレス
- `publicDns`: パブリックDNS名
- `usedVpcId`: 使用されたVPC ID
- `usedSubnetId`: 使用されたサブネット ID
- `usedSecurityGroupId`: 使用されたセキュリティグループ ID
- `provisioningRepositoryVersion`: プロビジョニングに使用されたGitコミットハッシュ

## インストールログの確認

EC2インスタンス内で、各スクリプトの実行ログを確認できます：

```bash
# SSH接続後
sudo cat /var/log/user-data/main.log                    # メインログ
sudo cat /var/log/user-data/00-install-prerequisites.log
sudo cat /var/log/user-data/01-install-nvm.log
sudo cat /var/log/user-data/02-install-nodejs.log
sudo cat /var/log/user-data/03-install-claude.log
sudo cat /var/log/user-data/04-install-awscli.log
sudo cat /var/log/user-data/05-install-pulumi.log
sudo cat /var/log/user-data/06-install-docker.log
```

## トラブルシューティング

### Pulumiスタックが存在しない

```bash
# 利用可能なスタックを確認
pulumi stack ls

# スタックを作成
pulumi stack init dev
```

### AWS認証エラー

```bash
# AWS認証情報を確認
aws sts get-caller-identity

# 認証情報を再設定
aws configure
```

### インスタンスへの接続エラー

- セキュリティグループでSSH（ポート22）が許可されているか確認
- 正しい鍵ペアを使用しているか確認
- Public IPが割り当てられているか確認

```bash
pulumi stack output publicIp
```

### user-dataスクリプトの実行状態確認

```bash
# EC2インスタンスにSSH接続後
sudo tail -f /var/log/cloud-init-output.log
```

## 注意事項

- `Pulumi.dev.yaml` にはAWSリソースIDなどの情報が含まれるため、`.gitignore` で除外されています
- このファイルは各環境で個別に作成・管理してください
- EC2インスタンスの起動後、すべてのソフトウェアのインストールには10〜15分程度かかります
- インスタンスを削除（`pulumi destroy`）すると、データは完全に失われます（`deleteOnTermination: true`）

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
