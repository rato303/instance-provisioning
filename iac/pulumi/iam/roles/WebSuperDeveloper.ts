import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import { webBasicDeveloperPolicyArn } from "../policies/WebBasicDeveloperPolicy";
import { webSuperDeveloperPolicyArn } from "../policies/WebSuperDeveloperPolicy";
import { webDeveloperSessionManagerPolicyArn } from "../policies/WebDeveloperSessionManagerPolicy";

// WebSuperDeveloper IAMロール
// プロビジョニング作業用EC2インスタンスに割り当てるロール
// - AmazonSSMManagedInstanceCore（Session Manager経由での接続を受け入れる）
// - WebBasicDeveloperPolicy（dev-*リソースへのアクセス）
// - WebSuperDeveloperPolicy（全リソースへのフルアクセス + EC2インスタンス管理 + IAM PassRole）
// - WebDeveloperSessionManagerPolicy（Session Manager経由で他インスタンスに接続）

// EC2がこのロールを引き受けることを許可する信頼ポリシー
const assumeRolePolicy = JSON.stringify({
    Version: "2012-10-17",
    Statement: [{
        Effect: "Allow",
        Principal: {
            Service: "ec2.amazonaws.com"
        },
        Action: "sts:AssumeRole"
    }]
});

// WebSuperDeveloperロール作成
export const webSuperDeveloperRole = new aws.iam.Role("WebSuperDeveloperRole", {
    name: "WebSuperDeveloper",
    description: "Role for provisioning EC2 instances via Session Manager and full infrastructure management",
    assumeRolePolicy: assumeRolePolicy,
    tags: {
        Name: "WebSuperDeveloper",
        Purpose: "Advanced development with full infrastructure management and Session Manager access",
        ManagedBy: "Pulumi"
    }
});

// AmazonSSMManagedInstanceCoreポリシーをアタッチ（Session Manager経由での接続を受け入れる）
const ssmCoreAttachment = new aws.iam.RolePolicyAttachment("WebSuperDeveloperSSMCoreAttachment", {
    role: webSuperDeveloperRole.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
});

// WebBasicDeveloperPolicyをアタッチ（基本的な開発権限）
const basicPolicyAttachment = new aws.iam.RolePolicyAttachment("WebSuperDeveloperBasicPolicyAttachment", {
    role: webSuperDeveloperRole.name,
    policyArn: webBasicDeveloperPolicyArn
});

// WebSuperDeveloperPolicyをアタッチ（追加の管理権限）
const superPolicyAttachment = new aws.iam.RolePolicyAttachment("WebSuperDeveloperSuperPolicyAttachment", {
    role: webSuperDeveloperRole.name,
    policyArn: webSuperDeveloperPolicyArn
});

// WebDeveloperSessionManagerPolicyをアタッチ（他インスタンスへの接続権限）
const sessionManagerPolicyAttachment = new aws.iam.RolePolicyAttachment("WebSuperDeveloperSessionManagerPolicyAttachment", {
    role: webSuperDeveloperRole.name,
    policyArn: webDeveloperSessionManagerPolicyArn
});

// インスタンスプロファイル作成
export const webSuperDeveloperInstanceProfile = new aws.iam.InstanceProfile("WebSuperDeveloperInstanceProfile", {
    name: "WebSuperDeveloper",
    role: webSuperDeveloperRole.name,
    tags: {
        Name: "WebSuperDeveloper",
        ManagedBy: "Pulumi"
    }
});

export const webSuperDeveloperRoleArn = webSuperDeveloperRole.arn;
export const webSuperDeveloperInstanceProfileName = webSuperDeveloperInstanceProfile.name;
