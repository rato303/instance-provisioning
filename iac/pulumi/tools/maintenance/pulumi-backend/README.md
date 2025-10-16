# Pulumiバックエンド設定管理ツール

このツールは、PulumiのS3バックエンド設定をAWS Systems Manager Parameter Storeに保存・管理するためのものです。

## 概要

Pulumiのステートファイルを保存するS3バックエンドの情報（バケットURLとリージョン）をParameter Storeで管理します。これにより、複数の環境や開発者間でバックエンド設定を一元管理できます。

## 前提条件

- AWS CLI がインストールされていること
- IAMロールに以下の権限があること：
  - `ssm:GetParameter`
  - `ssm:PutParameter`
  - `ssm:DeleteParameter`（削除時のみ）

## 使い方

### 初回セットアップ

バックエンド設定をParameter Storeに保存します：

```bash
make setup
```

対話形式で以下を入力します：
- **バックエンドURL**: S3バケットのURL（例: `s3://my-pulumi-state-bucket`）
- **リージョン**: AWSリージョン（例: `ap-northeast-1`）

### 現在の設定を表示

```bash
make show
```

Parameter Storeに保存されている現在のバックエンド設定を表示します。

### 設定を削除

```bash
make delete
```

Parameter Storeからバックエンド設定を削除します（確認プロンプトあり）。

## Parameter Store パラメータ

このツールは以下のParameter Storeパラメータを使用します：

- `/pulumi/backend/url`: PulumiバックエンドのS3 URL
- `/pulumi/backend/region`: AWSリージョン

## IAM権限

EC2インスタンスロールに以下の権限を追加してください：

```json
{
    "Effect": "Allow",
    "Action": [
        "ssm:GetParameter",
        "ssm:PutParameter",
        "ssm:DeleteParameter"
    ],
    "Resource": [
        "arn:aws:ssm:*:*:parameter/pulumi/*"
    ]
}
```

## 関連ファイル

- [setup-backend-config.sh](setup-backend-config.sh) - バックエンド設定を保存するスクリプト
- [Makefile](Makefile) - このツールのMakefile

## 使用例

```bash
# 初回セットアップ
$ make setup
==================================================
  Pulumiバックエンド設定をParameter Storeに保存
==================================================

PulumiバックエンドURL（S3バケットのURL）を入力してください
例: s3://my-pulumi-state-bucket

バックエンドURL: s3://pulumi-development-bucket

AWSリージョンを入力してください
例: ap-northeast-1, us-east-1, eu-west-1

リージョン: ap-northeast-1

以下の設定をParameter Storeに保存します:
  バックエンドURL: s3://pulumi-development-bucket
  リージョン:       ap-northeast-1

続行しますか? [y/N]: y

Parameter Storeに保存中...
✓ /pulumi/backend/url を保存しました
✓ /pulumi/backend/region を保存しました

==================================================
  ✓ バックエンド設定の保存が完了しました！
==================================================

次のステップ:
  1. IAMロールに必要な権限を追加してください（詳細はREADME.mdを参照）
  2. 'make login' でPulumiにログインしてください

# 設定確認
$ make show
==================================================
  現在のPulumiバックエンド設定
==================================================

バックエンドURL:
s3://pulumi-development-bucket

リージョン:
ap-northeast-1
```

## トラブルシューティング

### `AccessDenied` エラー

Parameter Storeにアクセスできない場合は、IAMロールに `ssm:GetParameter` および `ssm:PutParameter` 権限があるか確認してください。

### パラメータが見つからない

`make show` で「(未設定)」と表示される場合は、`make setup` を実行してバックエンド設定を保存してください。
