import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

// WebDeveloperSessionManagerPolicy
// Session Manager経由で他インスタンスに接続するための権限
// WebSuperDeveloperロールにのみアタッチされる
// 条件: aws:ResourceTag/SSMManaged = "true"

export const webDeveloperSessionManagerPolicy = new aws.iam.Policy("WebDeveloperSessionManagerPolicy", {
    name: "WebDeveloperSessionManagerPolicy",
    description: "Policy for Session Manager access to other instances with SSMManaged tag",
    policy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [
            // Session Manager経由で他インスタンスに接続
            {
                Sid: "SSMStartSession",
                Effect: "Allow",
                Action: [
                    "ssm:StartSession"
                ],
                Resource: [
                    "arn:aws:ec2:*:*:instance/*"
                ],
                Condition: {
                    StringEquals: {
                        "aws:ResourceTag/SSMManaged": "true"
                    }
                }
            },
            // SSM SendCommand（Ansibleプロビジョニング用）
            {
                Sid: "SSMSendCommand",
                Effect: "Allow",
                Action: [
                    "ssm:SendCommand"
                ],
                Resource: [
                    "arn:aws:ec2:*:*:instance/*"
                ],
                Condition: {
                    StringEquals: {
                        "aws:ResourceTag/SSMManaged": "true"
                    }
                }
            },
            // SSM SendCommandで使用するドキュメント
            {
                Sid: "SSMSendCommandDocuments",
                Effect: "Allow",
                Action: [
                    "ssm:SendCommand"
                ],
                Resource: [
                    "arn:aws:ssm:*:*:document/AWS-RunShellScript",
                    "arn:aws:ssm:*:*:document/AWS-StartSession"
                ]
            },
            // Session Manager セッション管理
            {
                Sid: "SSMSessionManagement",
                Effect: "Allow",
                Action: [
                    "ssm:TerminateSession",
                    "ssm:ResumeSession",
                    "ssm:DescribeSessions",
                    "ssm:GetConnectionStatus"
                ],
                Resource: "*"
            }
        ]
    }),
    tags: {
        Name: "WebDeveloperSessionManagerPolicy",
        Purpose: "Session Manager access to other instances",
        ManagedBy: "Pulumi"
    }
});

export const webDeveloperSessionManagerPolicyArn = webDeveloperSessionManagerPolicy.arn;
