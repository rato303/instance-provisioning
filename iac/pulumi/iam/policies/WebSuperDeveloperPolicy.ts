import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

// WebSuperDeveloper用のIAMポリシー
// プロビジョニング作業に必要な追加権限を付与
// - WebBasicDeveloperPolicyにない権限（全リソースへのフルアクセス）
// - EC2インスタンスの作成・削除・起動・停止
// - IAM PassRole（WebBasicDeveloper/WebSuperDeveloperロールのみ）
// - Session Manager接続権限はWebDeveloperSessionManagerPolicyで提供

const config = new pulumi.Config();
const accountId = aws.getCallerIdentity().then(id => id.accountId);
const region = aws.getRegion().then(r => r.name);

export const webSuperDeveloperPolicy = new aws.iam.Policy("WebSuperDeveloperPolicy", {
    name: "WebSuperDeveloperPolicy",
    description: "Additional policy for provisioning instances and infrastructure management",
    policy: pulumi.all([accountId, region]).apply(([accId, reg]) => JSON.stringify({
        Version: "2012-10-17",
        Statement: [
            // ECR: 全リポジトリへのフルアクセス
            {
                Sid: "ECRFullAccess",
                Effect: "Allow",
                Action: [
                    "ecr:*"
                ],
                Resource: "*"
            },
            // ECS: 全リソースへのフルアクセス
            {
                Sid: "ECSFullAccess",
                Effect: "Allow",
                Action: [
                    "ecs:*"
                ],
                Resource: "*"
            },
            // DynamoDB: 全テーブルへのフルアクセス
            {
                Sid: "DynamoDBFullAccess",
                Effect: "Allow",
                Action: [
                    "dynamodb:*"
                ],
                Resource: "*"
            },
            // S3: 全バケットへのフルアクセス
            {
                Sid: "S3FullAccess",
                Effect: "Allow",
                Action: [
                    "s3:*"
                ],
                Resource: "*"
            },
            // Secrets Manager: 全シークレットへのフルアクセス
            {
                Sid: "SecretsManagerFullAccess",
                Effect: "Allow",
                Action: [
                    "secretsmanager:*"
                ],
                Resource: "*"
            },
            // SSM Parameter Store: 全パラメータへのフルアクセス
            {
                Sid: "SSMParameterStoreFullAccess",
                Effect: "Allow",
                Action: [
                    "ssm:PutParameter",
                    "ssm:DeleteParameter",
                    "ssm:DeleteParameters",
                    "ssm:AddTagsToResource",
                    "ssm:RemoveTagsFromResource"
                ],
                Resource: `arn:aws:ssm:${reg}:${accId}:parameter/*`
            },
            // EC2インスタンス管理
            {
                Sid: "EC2InstanceManagement",
                Effect: "Allow",
                Action: [
                    "ec2:RunInstances",
                    "ec2:TerminateInstances",
                    "ec2:StartInstances",
                    "ec2:StopInstances",
                    "ec2:CreateTags",
                    "ec2:DeleteTags",
                    "ec2:ModifyInstanceAttribute"
                ],
                Resource: "*"
            },
            // IAM PassRole（WebBasicDeveloper/WebSuperDeveloperロールのみ）
            {
                Sid: "IAMPassRoleForEC2",
                Effect: "Allow",
                Action: [
                    "iam:PassRole",
                    "iam:GetRole",
                    "iam:GetInstanceProfile",
                    "iam:ListInstanceProfiles"
                ],
                Resource: [
                    `arn:aws:iam::${accId}:role/WebBasicDeveloper`,
                    `arn:aws:iam::${accId}:role/WebSuperDeveloper`,
                    `arn:aws:iam::${accId}:instance-profile/WebBasicDeveloper`,
                    `arn:aws:iam::${accId}:instance-profile/WebSuperDeveloper`
                ]
            }
        ]
    })),
    tags: {
        Name: "WebSuperDeveloperPolicy",
        Purpose: "Advanced development with full infrastructure management",
        ManagedBy: "Pulumi"
    }
});

export const webSuperDeveloperPolicyArn = webSuperDeveloperPolicy.arn;
