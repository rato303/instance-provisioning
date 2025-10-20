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

### 前提条件: Session Manager接続

このplaybookは、AWS Systems Manager Session Manager経由で実行します。プロビジョニング専用インスタンス（WebSuperDeveloper）から実行することを想定しています。

**必要な準備**:
1. Ansibleコレクション `amazon.aws` がインストールされていること
   ```bash
   ansible-galaxy collection install amazon.aws
   ```
2. プロビジョニング専用インスタンスに適切なIAM権限があること（WebSuperDeveloperロール）

### 1. インベントリファイルのセットアップ

PulumiでプロビジョニングしたEC2インスタンスに対して実行するため、インベントリファイルを作成します:

```bash
cd iac/ansible
cp inventory/hosts.example inventory/hosts
```

`inventory/hosts` を編集してターゲットEC2インスタンスのIDを設定:

```ini
[targets]
i-0123456789abcdef0  # pulumi stack output instanceIdで取得

[targets:vars]
ansible_connection=aws_ssm
ansible_aws_ssm_region=ap-northeast-1
ansible_python_interpreter=/usr/bin/python3
```

### 2. Session Manager接続確認

```bash
ansible -i inventory/hosts targets -m ping
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

### ターゲットインスタンス
- Ubuntu 20.04以降
- Python 3.x
- SSM Agentが起動していること（Amazon Linux/Ubuntu AMIではデフォルトで含まれる）
- IAMロールに `AmazonSSMManagedInstanceCore` ポリシーがアタッチされていること
- sudo権限

### プロビジョニング専用インスタンス（実行元）
- Ansible 2.9以降
- `amazon.aws` Ansibleコレクション
- WebSuperDeveloperロール（Session Manager経由で他インスタンスに接続可能）

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
