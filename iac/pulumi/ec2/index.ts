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
const iamInstanceProfile = config.get("iamInstanceProfile") || "EC2WebAppDeveloper";

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
    iamInstanceProfile: iamInstanceProfile,
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
export const privateIp = instance.privateIp;
export const publicDns = instance.publicDns;
export const usedVpcId = vpcId;
export const usedSubnetId = subnetId;
export const usedSecurityGroupId = securityGroupId;
export const provisioningRepositoryVersion = gitCommitHash;
