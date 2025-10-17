# Ansible SSH Key Role

このroleは、AWS Secrets Managerに保存されているAnsible用SSH鍵（秘密鍵・公開鍵）を取得し、ターゲットホストの`~/.ssh`ディレクトリに配置します。

## 目的

EC2インスタンスのローリング置き換え運用において、新しいインスタンスが次の母艦として機能するために必要なAnsible実行環境を構築します。

```
dev3 (現母艦)
  ↓ Pulumi実行でdev4作成
  ↓ Ansible実行（このroleを含む）
dev4 (新母艦) ← Ansible秘密鍵が配置される
  ↓ 次回はdev4がdev5を作成・プロビジョニング
dev5 (新規インスタンス)
```

## 前提条件

### 1. AWS Secrets Managerにシークレットが登録済み

[iac/pulumi/tools/maintenance/ansible-ssh-key](../../../pulumi/tools/maintenance/ansible-ssh-key/README.md) のツールを使用して、SSH鍵をSecrets Managerに登録してください。

```bash
cd iac/pulumi/tools/maintenance/ansible-ssh-key
make generate  # 鍵生成
make upload    # Secrets Managerにアップロード
```

シークレットの形式:
```json
{
  "private_key": "-----BEGIN OPENSSH PRIVATE KEY-----\n...",
  "public_key": "ssh-ed25519 AAAA... comment"
}
```

### 2. EC2インスタンスのIAMロールに必要な権限

ターゲットEC2インスタンスにアタッチされたIAMロールに、以下の権限が必要です:

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

### 3. AWS CLIがインストール済み

このroleは `aws` コマンドを使用します。`awscli` roleを先に実行してください。

## 使用方法

### playbook に追加

```yaml
---
- name: Setup development environment
  hosts: all
  become: yes
  roles:
    - awscli              # AWS CLIを先にインストール
    - ansible-ssh-key     # このrole
    - make
    - docker
    # ... その他のroles
```

### 単体実行

```bash
ansible-playbook -i inventory/hosts provision.yml --tags ansible-ssh-key
```

## 設定オプション

`group_vars/all.yml` または `host_vars/` で以下の変数をカスタマイズできます:

```yaml
# Secrets Managerのシークレット名（デフォルト: "ansible/ssh-key"）
ansible_ssh_key_secret_name: "ansible/ssh-key"

# AWSリージョン（デフォルト: "ap-northeast-1"）
ansible_ssh_key_region: "ap-northeast-1"

# 秘密鍵の配置先パス（デフォルト: "~/.ssh/ansible_id_ed25519"）
ansible_ssh_key_private_path: "{{ ansible_env.HOME }}/.ssh/ansible_id_ed25519"

# 公開鍵の配置先パス（デフォルト: "~/.ssh/ansible_id_ed25519.pub"）
ansible_ssh_key_public_path: "{{ ansible_env.HOME }}/.ssh/ansible_id_ed25519.pub"

# パーミッション設定
ansible_ssh_key_private_mode: "0600"  # 秘密鍵
ansible_ssh_key_public_mode: "0644"   # 公開鍵
```

## 動作内容

1. `~/.ssh` ディレクトリの作成（存在しない場合）
2. AWS Secrets Managerから鍵情報を取得
3. 秘密鍵を `~/.ssh/ansible_id_ed25519` に配置（パーミッション: 600）
4. 公開鍵を `~/.ssh/ansible_id_ed25519.pub` に配置（パーミッション: 644）
5. `~/.ssh/config` にIdentityFileを追加（ssh-agent自動追加設定）

## セキュリティ考慮事項

### ✅ 安全な点

- **Secrets Managerで暗号化保存**: 鍵はAWS KMSで暗号化
- **IAMロールベース認証**: EC2のIAMロールで権限制御
- **最小権限の原則**: GetSecretValueのみ許可
- **監査可能**: CloudTrailでSecrets Managerアクセスを記録
- **ログに秘密情報を出力しない**: `no_log: true` 設定
- **適切なファイルパーミッション**: 秘密鍵は600、公開鍵は644

### ⚠️ 注意点

- **秘密鍵がEC2上に存在する**: インスタンス侵害時のリスクを考慮
- **運用終了時の鍵削除**: 不要になった母艦は速やかに削除
- **鍵ローテーション**: 定期的な鍵更新を推奨

### 推奨対策

1. **母艦の寿命を短く保つ**: dev3→dev4→dev5とローリング更新
2. **不要なインスタンスは即削除**: dev3削除後は秘密鍵も消滅
3. **定期的な鍵ローテーション**: 3-6ヶ月ごとに新しい鍵を生成
4. **セキュリティグループの制限**: 必要最小限のSSH接続元のみ許可

## トラブルシューティング

### 権限エラー: "AccessDeniedException"

```
An error occurred (AccessDeniedException) when calling the GetSecretValue operation
```

**原因**: EC2のIAMロールに `secretsmanager:GetSecretValue` 権限がない

**解決**: Pulumiでインスタンスプロファイル/IAMロールに権限を追加:

```typescript
// iac/pulumi/ec2/index.ts
const role = new aws.iam.Role("ec2-role", {
    assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: { Service: "ec2.amazonaws.com" }
        }]
    })
});

const policy = new aws.iam.RolePolicy("secrets-manager-policy", {
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
    role: role.name
});

const instance = new aws.ec2.Instance("instance", {
    // ...
    iamInstanceProfile: instanceProfile.name,
});
```

### シークレットが見つからない: "ResourceNotFoundException"

```
Secrets Manager can't find the specified secret
```

**原因**: Secrets Managerに鍵が登録されていない

**解決**: 鍵生成ツールで登録:

```bash
cd iac/pulumi/tools/maintenance/ansible-ssh-key
make generate && make upload
```

### AWS CLIが見つからない

```
aws: command not found
```

**原因**: AWS CLIがインストールされていない

**解決**: playbookで `awscli` roleを先に実行:

```yaml
roles:
  - awscli              # 先に実行
  - ansible-ssh-key     # 後から実行
```

## 関連ドキュメント

- [鍵管理ツール](../../../pulumi/tools/maintenance/ansible-ssh-key/README.md)
- [Pulumi EC2設定](../../../pulumi/ec2/README.md)
- [Ansibleプロビジョニング](../../README.md)
