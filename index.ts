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

// シンプルなuser-data（スクリプトディレクトリの作成のみ）
const userData = `#!/bin/bash
set -e

echo "========================================="
echo "EC2 User Data - Preparing environment"
echo "Started at: $(date)"
echo "========================================="

# スクリプト用ディレクトリの作成
echo "Creating /opt/scripts directory..."
sudo mkdir -p /opt/scripts
sudo chown ubuntu:ubuntu /opt/scripts

# ログディレクトリの作成
echo "Creating /var/log/user-data directory..."
sudo mkdir -p /var/log/user-data
sudo chown ubuntu:ubuntu /var/log/user-data

echo "========================================="
echo "Environment preparation completed!"
echo "Scripts should be transferred to /opt/scripts/"
echo "Run /opt/scripts/user-data.sh to start installation"
echo "========================================="
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
