import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import { execSync } from "child_process";

// Pulumi設定から既存のネットワークリソースIDを取得
const config = new pulumi.Config();
const vpcId = config.require("vpcId");
const subnetId = config.require("subnetId");
const securityGroupId = config.require("securityGroupId");

// AMIとインスタンス設定
const instanceName = config.get("instanceName") || "dev-instance";
const ami = config.get("ami") || "ami-0a71a0b9c988d5e5e";
const instanceType = config.get("instanceType") || "t3.medium";
const sshKeyPairName = config.get("sshKeyPairName") || "pulumi-dev";
const volumeSize = config.getNumber("volumeSize") || 60;

// Ansible用SSH公開鍵の取得
const ansibleSshKey = aws.secretsmanager.getSecretVersionOutput({
    secretId: "ansible/ssh-key",
});

// JSON文字列から公開鍵を抽出
const ansiblePublicKey = ansibleSshKey.secretString.apply((secretString) => {
    const secret = JSON.parse(secretString);
    return secret.public_key;
});

// user-data: Ansible用SSH公開鍵を登録
const userData = pulumi.interpolate`#!/bin/bash
set -e

# Ansible用SSH公開鍵を登録
echo "${ansiblePublicKey}" >> /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
`;

// Gitコミットハッシュの取得
let gitCommitHash = "unknown";
try {
    gitCommitHash = execSync("git rev-parse HEAD", { encoding: "utf8" }).trim();
} catch (error) {
    console.warn("Warning: Failed to get git commit hash. Tag will be set to 'unknown'.");
}

// EC2インスタンスの作成
const instance = new aws.ec2.Instance(instanceName, {
    ami: ami,
    instanceType: instanceType,
    keyName: sshKeyPairName,
    subnetId: subnetId,
    vpcSecurityGroupIds: [securityGroupId],
    userData: userData,
    rootBlockDevice: {
        volumeSize: volumeSize,
        volumeType: "gp3",
        deleteOnTermination: true,
    },
    tags: {
        Name: instanceName,
        ProvisioningRepositoryVersion: gitCommitHash,
        ProvisionedBy: "instance-provisioning",
    },
});

// エクスポート
export const instanceId = instance.id;
export const publicIp = instance.publicIp;
export const publicDns = instance.publicDns;
export const usedVpcId = vpcId;
export const usedSubnetId = subnetId;
export const usedSecurityGroupId = securityGroupId;
export const provisioningRepositoryVersion = gitCommitHash;
