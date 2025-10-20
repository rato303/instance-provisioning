# EC2 Instance Provisioning with Pulumi

このプロジェクトは、Pulumiを使用してAWS EC2インスタンスを自動的にプロビジョニングし、Ansibleを使用して開発環境を構築するためのツールです。

## 概要

EC2インスタンスを作成し、AWS Systems Manager Session Manager経由でAnsibleを使用して以下のソフトウェアを自動的にインストールします：

- SDKMAN! (Java、Gradle、Mavenなどの管理)
- Docker & Docker Compose
- その他の開発ツール（Ansible playbookで管理）

Session Managerを使用することで、SSH鍵の管理が不要になり、IAMベースの認証とタグベースのアクセス制御により、セキュアな運用が可能です。

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

### Session Manager接続

```bash
# インスタンスIDを取得
INSTANCE_ID=$(pulumi stack output instanceId)

# Session Manager経由で接続
aws ssm start-session --target $INSTANCE_ID
```

### インスタンスの削除

```bash
pulumi destroy
```

## プロジェクト構造

```
instance-provisioning/
├── iac/
│   ├── ansible/               # Ansible playbook とロール
│   │   ├── inventory/        # インベントリファイル
│   │   ├── roles/            # 各種ロール (SDKMAN, Docker等)
│   │   └── site.yml          # メインplaybook
│   └── pulumi/
│       └── ec2/
│           ├── index.ts      # Pulumi メイン設定ファイル
│           ├── Pulumi.yaml   # Pulumiプロジェクト設定
│           ├── Pulumi.dev.yaml.example  # 設定テンプレート
│           └── login-to-backend.sh      # Backend認証スクリプト
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
| `iamInstanceProfile` | IAMインスタンスプロファイル名 | `EC2WebAppDeveloper` | |

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
- `privateIp`: プライベートIPアドレス
- `publicDns`: パブリックDNS名
- `usedVpcId`: 使用されたVPC ID
- `usedSubnetId`: 使用されたサブネット ID
- `usedSecurityGroupId`: 使用されたセキュリティグループ ID
- `provisioningRepositoryVersion`: プロビジョニングに使用されたGitコミットハッシュ

## Ansibleによるプロビジョニング

Session Manager経由でAnsibleを使用してソフトウェアをインストールします：

### プロビジョニング専用インスタンス（WebSuperDeveloper）からの実行

```bash
# 1. プロビジョニング専用インスタンスにSession Manager経由で接続
aws ssm start-session --target $(pulumi stack output instanceId)

# 2. cloneしたリポジトリのansibleディレクトリに移動
cd <cloneしたディレクトリ>/iac/ansible

# 3. インベントリファイルを作成
cp inventory/hosts.example inventory/hosts
# inventory/hostsを編集してターゲットEC2インスタンスのIDを設定

# 4. Session Manager接続確認
ansible -i inventory/hosts targets -m ping

# 5. プロビジョニング実行
ansible-playbook -i inventory/hosts provision.yml
```

詳細は [iac/ansible/README.md](iac/ansible/README.md) を参照してください。

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

### Session Manager接続エラー

**症状**: `aws ssm start-session` が失敗する

**確認事項**:
1. インスタンスにSSM Agentが起動しているか
2. IAMロールに `AmazonSSMManagedInstanceCore` ポリシーがアタッチされているか
3. インスタンスに `SSMManaged: true` タグが付与されているか

```bash
# インスタンスIDの確認
pulumi stack output instanceId

# タグの確認
aws ec2 describe-tags --filters "Name=resource-id,Values=$(pulumi stack output instanceId)"
```

### Ansible接続エラー

**症状**: `ansible -i inventory/hosts targets -m ping` が失敗する

**確認事項**:
1. `amazon.aws` Ansibleコレクションがインストールされているか
   ```bash
   ansible-galaxy collection install amazon.aws
   ```
2. inventory/hostsに正しいインスタンスIDが設定されているか
3. `ansible_connection=aws_ssm` が設定されているか

## 注意事項

- `Pulumi.dev.yaml` にはAWSリソースIDなどの情報が含まれるため、`.gitignore` で除外されています
- このファイルは各環境で個別に作成・管理してください
- Session Manager経由でのプロビジョニングにはIAMベースの認証を使用します（SSH鍵管理は不要）
- Ansibleによるソフトウェアのインストールには10〜15分程度かかります
- インスタンスを削除（`pulumi destroy`）すると、データは完全に失われます（`deleteOnTermination: true`）

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
