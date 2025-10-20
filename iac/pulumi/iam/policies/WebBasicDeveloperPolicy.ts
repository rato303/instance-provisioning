import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

// WebBasicDeveloper用のIAMポリシー
// 通常の開発作業に必要な権限を付与
// - ECR/ECS/DynamoDB/S3/Secrets Managerのdev-*リソースへのアクセス
// - EC2の読み取り権限のみ（作成・削除権限なし）
// - IAM権限なし
// - Session Manager経由での接続を受け入れる権限はAmazonSSMManagedInstanceCoreで提供

const config = new pulumi.Config();
const accountId = aws.getCallerIdentity().then(id => id.accountId);
const region = aws.getRegion().then(r => r.name);

export const webBasicDeveloperPolicy = new aws.iam.Policy("WebBasicDeveloperPolicy", {
    name: "WebBasicDeveloperPolicy",
    description: "Policy for basic web development instances - access to dev-* resources only",
    policy: pulumi.all([accountId, region]).apply(([accId, reg]) => JSON.stringify({
        Version: "2012-10-17",
        Statement: [
            // ECR: Describe全体 + dev-*リポジトリ管理
            {
                Sid: "ECRDescribeAll",
                Effect: "Allow",
                Action: [
                    "ecr:DescribeRepositories",
                    "ecr:DescribeImages",
                    "ecr:ListImages",
                    "ecr:GetAuthorizationToken"
                ],
                Resource: "*"
            },
            {
                Sid: "ECRManageDevelopmentRepositories",
                Effect: "Allow",
                Action: [
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:PutImage",
                    "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CompleteLayerUpload"
                ],
                Resource: `arn:aws:ecr:${reg}:${accId}:repository/dev-*`
            },
            // ECS: List/Describe全体 + dev-*リソース管理
            {
                Sid: "ECSListDescribeAll",
                Effect: "Allow",
                Action: [
                    "ecs:ListClusters",
                    "ecs:ListServices",
                    "ecs:ListTasks",
                    "ecs:DescribeClusters",
                    "ecs:DescribeServices",
                    "ecs:DescribeTasks",
                    "ecs:DescribeTaskDefinition",
                    "ecs:ListTaskDefinitions"
                ],
                Resource: "*"
            },
            {
                Sid: "ECSManageDevelopmentResources",
                Effect: "Allow",
                Action: [
                    "ecs:CreateService",
                    "ecs:UpdateService",
                    "ecs:DeleteService",
                    "ecs:RegisterTaskDefinition",
                    "ecs:DeregisterTaskDefinition",
                    "ecs:RunTask",
                    "ecs:StopTask",
                    "ecs:StartTask"
                ],
                Resource: [
                    `arn:aws:ecs:${reg}:${accId}:cluster/dev-*`,
                    `arn:aws:ecs:${reg}:${accId}:service/dev-*/*`,
                    `arn:aws:ecs:${reg}:${accId}:task/dev-*/*`,
                    `arn:aws:ecs:${reg}:${accId}:task-definition/dev-*:*`
                ]
            },
            // DynamoDB: List/Describe全体 + dev-*テーブル管理
            {
                Sid: "DynamoDBListDescribeAll",
                Effect: "Allow",
                Action: [
                    "dynamodb:ListTables",
                    "dynamodb:DescribeTable",
                    "dynamodb:DescribeTimeToLive"
                ],
                Resource: "*"
            },
            {
                Sid: "DynamoDBManageDevelopmentTables",
                Effect: "Allow",
                Action: [
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:Query",
                    "dynamodb:Scan",
                    "dynamodb:BatchGetItem",
                    "dynamodb:BatchWriteItem"
                ],
                Resource: [
                    `arn:aws:dynamodb:${reg}:${accId}:table/dev-*`
                ]
            },
            // S3: ListBuckets全体 + dev-*バケット管理
            {
                Sid: "S3ListAllBuckets",
                Effect: "Allow",
                Action: [
                    "s3:ListAllMyBuckets",
                    "s3:GetBucketLocation"
                ],
                Resource: "*"
            },
            {
                Sid: "S3ManageDevelopmentBuckets",
                Effect: "Allow",
                Action: [
                    "s3:ListBucket",
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:GetObjectVersion"
                ],
                Resource: [
                    "arn:aws:s3:::dev-*",
                    "arn:aws:s3:::dev-*/*"
                ]
            },
            // EC2: Describe系のみ（作成・削除権限なし）
            {
                Sid: "EC2ReadOnly",
                Effect: "Allow",
                Action: [
                    "ec2:DescribeInstances",
                    "ec2:DescribeInstanceTypes",
                    "ec2:DescribeImages",
                    "ec2:DescribeVpcs",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeKeyPairs",
                    "ec2:DescribeTags"
                ],
                Resource: "*"
            },
            // Secrets Manager: dev/*プレフィックス
            {
                Sid: "SecretsManagerDevelopment",
                Effect: "Allow",
                Action: [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret",
                    "secretsmanager:ListSecrets"
                ],
                Resource: `arn:aws:secretsmanager:${reg}:${accId}:secret:dev/*`
            },
            // SSM Parameter Store: pulumi/*のみ（読み取り専用）
            {
                Sid: "SSMParameterStorePulumiReadOnly",
                Effect: "Allow",
                Action: [
                    "ssm:GetParameter",
                    "ssm:GetParameters",
                    "ssm:GetParametersByPath"
                ],
                Resource: `arn:aws:ssm:${reg}:${accId}:parameter/pulumi/*`
            }
        ]
    })),
    tags: {
        Name: "WebBasicDeveloperPolicy",
        Purpose: "Basic web development with access to dev resources",
        ManagedBy: "Pulumi"
    }
});

export const webBasicDeveloperPolicyArn = webBasicDeveloperPolicy.arn;
