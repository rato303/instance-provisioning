# Ansible Playbooks

このディレクトリには、インスタンスをプロビジョニングするためのAnsible playbookとrolesが含まれています。

## 構成

```
ansible/
├── provision.yml         # メインのplaybook
├── inventory/           # インベントリファイル管理
│   ├── hosts.example   # インベントリテンプレート
│   └── README.md       # インベントリ設定ガイド
├── group_vars/
│   └── all.yml          # 共通変数定義
└── roles/               # ロール定義
    ├── awscli/          # AWS CLI インストール
    ├── make/            # make インストール
    ├── docker/          # Docker & Docker Compose インストール
    ├── ansible/         # Ansible インストール
    ├── pulumi/          # Pulumi インストール
    ├── nvm/             # nvm + Node.js + npmパッケージ
    │   ├── defaults/    # デフォルト変数 (Node.jsバージョン、npmパッケージリスト)
    │   └── tasks/       # インストールタスク
    └── sdkman/          # SDKMAN + Java/Kotlin/Gradle等
        ├── defaults/    # デフォルト変数 (インストールするSDKのリスト)
        └── tasks/       # インストールタスク
```

## インストールされるミドルウェア

- **awscli** - AWS Command Line Interface
- **make** - ビルドツール
- **docker** - Docker Engine & Docker Compose
- **ansible** - 構成管理ツール
- **pulumi** - Infrastructure as Codeツール
- **nvm** - Node Version Manager (デフォルトでNode.js LTS、Claude Code CLIをインストール)
- **sdkman** - SDK Manager for JVM ecosystems (デフォルトでJava、Kotlin、Gradleをインストール)

## 使用方法

### 1. インベントリファイルのセットアップ

PulumiでプロビジョニングしたEC2インスタンスに対して実行するため、インベントリファイルを作成します:

```bash
cd iac/ansible
cp inventory/hosts.example inventory/hosts
```

`inventory/hosts` を編集してEC2インスタンスのIPアドレスとSSHキーを設定:

```ini
[ec2]
54.123.45.67

[ec2:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/your-key.pem
ansible_python_interpreter=/usr/bin/python3
```

### 2. SSH接続確認

```bash
ansible -i inventory/hosts ec2 -m ping
```

### 3. プロビジョニング実行

```bash
ansible-playbook -i inventory/hosts provision.yml
```

### 4. 特定のロールのみ実行する場合

```bash
# Dockerのみインストール
ansible-playbook -i inventory/hosts provision.yml --tags docker

# 複数のロールを指定
ansible-playbook -i inventory/hosts provision.yml --tags "awscli,docker,pulumi"
```

### (参考) ローカル環境で実行する場合

ローカルマシンでテストする場合:

```bash
ansible-playbook -i localhost, -c local provision.yml
```

## 前提条件

- Ubuntu 20.04以降
- Python 3.x
- Ansible 2.9以降
- sudo権限

## カスタマイズ

### NVM (Node.js) のカスタマイズ

`group_vars/all.yml` でNode.jsのバージョンとnpmパッケージをカスタマイズできます:

```yaml
# インストールするNode.jsのバージョンリスト
nvm_node_versions:
  - version: "lts"
  - version: "18"    # 複数バージョン指定可能

nvm_default_version: "lts"  # デフォルトバージョン

# グローバルにインストールするnpmパッケージ
nvm_global_packages:
  - "@anthropic-ai/claude-code"
  - "typescript"
  - "yarn"
```

### SDKMAN (JVM系) のカスタマイズ

`group_vars/all.yml` でSDKをカスタマイズできます:

```yaml
sdkman_sdks:
  - name: java       # 必須: KotlinとGradleの実行に必要
  - name: kotlin
  - name: gradle
  # バージョン指定も可能:
  # - name: java
  #   version: "17.0.8-tem"
  - name: maven      # 追加例
  - name: scala      # 追加例
```

**重要**: KotlinとGradleはJVM上で動作するため、Javaが必須です。デフォルトでは最新のJavaがインストールされます。

## 注意事項

- nvm、sdkmanロールは一般ユーザー権限で実行されます
- dockerインストール後、dockerグループへの追加が行われますが、グループ変更を有効にするには再ログインが必要です
- nvm、sdkman経由でインストールされたツールを使用するには、インストール後に新しいシェルセッションを開くか、`.bashrc`を再読み込みする必要があります
- KotlinとGradleを使用する場合は、必ずJavaもインストールしてください(デフォルトで含まれています)
- 各ロールはべき等性を保っており、複数回実行しても安全です
