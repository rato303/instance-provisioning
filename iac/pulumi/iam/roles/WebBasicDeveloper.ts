import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import { webBasicDeveloperPolicyArn } from "../policies/WebBasicDeveloperPolicy";

// WebBasicDeveloper IAMロール
// 通常の開発作業用EC2インスタンスに割り当てるロール
// - AmazonSSMManagedInstanceCore（Session Manager経由での接続を受け入れる）
// - WebBasicDeveloperPolicy（dev-*リソースへのアクセス）

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

// WebBasicDeveloperロール作成
export const webBasicDeveloperRole = new aws.iam.Role("WebBasicDeveloperRole", {
    name: "WebBasicDeveloper",
    description: "Role for basic web development EC2 instances with Session Manager support",
    assumeRolePolicy: assumeRolePolicy,
    tags: {
        Name: "WebBasicDeveloper",
        Purpose: "Basic web development with access to dev resources",
        ManagedBy: "Pulumi"
    }
});

// AmazonSSMManagedInstanceCoreポリシーをアタッチ（Session Manager経由での接続を受け入れる）
const ssmCoreAttachment = new aws.iam.RolePolicyAttachment("WebBasicDeveloperSSMCoreAttachment", {
    role: webBasicDeveloperRole.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
});

// WebBasicDeveloperPolicyをアタッチ
const customPolicyAttachment = new aws.iam.RolePolicyAttachment("WebBasicDeveloperPolicyAttachment", {
    role: webBasicDeveloperRole.name,
    policyArn: webBasicDeveloperPolicyArn
});

// インスタンスプロファイル作成
export const webBasicDeveloperInstanceProfile = new aws.iam.InstanceProfile("WebBasicDeveloperInstanceProfile", {
    name: "WebBasicDeveloper",
    role: webBasicDeveloperRole.name,
    tags: {
        Name: "WebBasicDeveloper",
        ManagedBy: "Pulumi"
    }
});

export const webBasicDeveloperRoleArn = webBasicDeveloperRole.arn;
export const webBasicDeveloperInstanceProfileName = webBasicDeveloperInstanceProfile.name;
