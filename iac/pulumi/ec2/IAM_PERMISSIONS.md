# EC2インスタンスに必要なIAM権限

## 概要

このPulumi設定で作成されるEC2インスタンスは、ローリング置き換え運用において次の母艦として機能するため、AWS Secrets ManagerからAnsible用SSH鍵を取得する権限が必要です。

## 運用フロー

```
dev3 (現母艦)
  ↓ Pulumi実行でdev4作成
  ↓ Ansible実行（Secrets ManagerからSSH鍵を取得・配置）
dev4 (新母艦) ← EC2WebAppDeveloperロールが必要
  ↓ 次回はdev4がdev5を作成・プロビジョニング
dev5 (新規インスタンス)
```

## 必要なIAMインスタンスプロファイル

デフォルト: `EC2WebAppDeveloper`

このインスタンスプロファイルには、以下の権限を持つIAMロールがアタッチされている必要があります。

## 必要な権限ポリシー

### 1. Secrets Manager読み取り権限（必須）

Ansible用SSH鍵を取得するために必要です。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:ap-northeast-1:*:secret:ansible/ssh-key-*"
    }
  ]
}
```

**用途**:
- Ansibleの`ansible-ssh-key` roleがSecrets Managerから鍵を取得
- 取得した秘密鍵を`~/.ssh/ansible_id_ed25519`に配置

### 2. その他の推奨権限（オプション）

母艦として次のインスタンスを作成・管理する場合、以下の権限も必要になる可能性があります:

#### Pulumi実行のためのEC2権限

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeImages",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Pulumi State管理のためのS3権限

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-pulumi-state-bucket",
        "arn:aws:s3:::your-pulumi-state-bucket/*"
      ]
    }
  ]
}
```

## IAMロールの設定方法

### AWS Consoleでの設定

1. **IAMロールの作成/編集**
   - IAMコンソール → ロール → `EC2WebAppDeveloper` を選択

2. **信頼関係の確認**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "ec2.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   ```

3. **ポリシーのアタッチ**
   - 「権限を追加」→「インラインポリシーを作成」
   - 上記のSecrets Manager権限ポリシーを追加

4. **インスタンスプロファイルの確認**
   - ロールに自動的に同名のインスタンスプロファイルが作成されているか確認

### AWS CLIでの設定

```bash
# 1. ポリシードキュメントを作成
cat > secrets-manager-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:ap-northeast-1:*:secret:ansible/ssh-key-*"
    }
  ]
}
EOF

# 2. IAMロールにポリシーを追加
aws iam put-role-policy \
  --role-name EC2WebAppDeveloper \
  --policy-name SecretsManagerReadAnsibleKey \
  --policy-document file://secrets-manager-policy.json
```

### Pulumiでの設定（将来的な改善案）

現在は既存のIAMロール `EC2WebAppDeveloper` を使用していますが、Pulumiで管理する場合:

```typescript
// iac/pulumi/iam/index.ts (新規作成)
import * as aws from "@pulumi/aws";

const role = new aws.iam.Role("ec2-webapp-developer", {
    name: "EC2WebAppDeveloper",
    assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: { Service: "ec2.amazonaws.com" }
        }]
    })
});

const secretsManagerPolicy = new aws.iam.RolePolicy("secrets-manager-policy", {
    role: role.id,
    policy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Effect: "Allow",
            Action: ["secretsmanager:GetSecretValue"],
            Resource: "arn:aws:secretsmanager:ap-northeast-1:*:secret:ansible/ssh-key-*"
        }]
    })
});

const instanceProfile = new aws.iam.InstanceProfile("ec2-profile", {
    name: "EC2WebAppDeveloper",
    role: role.name
});

export const roleName = role.name;
export const instanceProfileName = instanceProfile.name;
```

## カスタマイズ

別のインスタンスプロファイルを使用する場合は、`Pulumi.dev.yaml`で設定:

```yaml
config:
  instance-provisioning:iamInstanceProfile: "YourCustomProfile"
```

## トラブルシューティング

### 権限エラーの確認

EC2インスタンス上で以下のコマンドで権限を確認:

```bash
# 1. インスタンスメタデータから現在のロールを確認
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/

# 2. Secrets Managerへのアクセステスト
aws secretsmanager get-secret-value \
  --secret-id ansible/ssh-key \
  --region ap-northeast-1 \
  --query SecretString \
  --output text
```

### よくあるエラー

#### AccessDeniedException

```
An error occurred (AccessDeniedException) when calling the GetSecretValue operation
```

**原因**: IAMロールに`secretsmanager:GetSecretValue`権限がない

**解決**: 上記のポリシーをIAMロールに追加

#### NoSuchEntity

```
An error occurred (NoSuchEntity) when calling the DescribeInstanceProfile operation
```

**原因**: インスタンスプロファイルが存在しない

**解決**: IAMロールと同名のインスタンスプロファイルを作成

## セキュリティ考慮事項

### 最小権限の原則

- **リソースの限定**: `ansible/ssh-key-*` に限定（ワイルドカードで将来のバージョン対応）
- **アクションの限定**: `GetSecretValue` のみ（`PutSecretValue`, `DeleteSecret`は不要）
- **リージョンの明示**: `ap-northeast-1` に限定

### 監査とログ

- **CloudTrail**: Secrets Managerへのアクセスは自動的に記録される
- **VPC Flow Logs**: ネットワークアクセスの監視
- **AWS Config**: IAMロール設定変更の追跡

### 定期的なレビュー

- 不要になったインスタンスは速やかに削除
- IAMロールの権限は定期的にレビュー
- Secrets Managerのアクセスログを監視

## 関連ドキュメント

- [Ansible SSH Key Role](../../ansible/roles/ansible-ssh-key/README.md)
- [SSH鍵管理ツール](../tools/maintenance/ansible-ssh-key/README.md)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [IAM Roles for Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
