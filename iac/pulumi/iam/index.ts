import * as pulumi from "@pulumi/pulumi";

// IAMポリシーとロールをインポート
import * as webBasicDeveloperPolicy from "./policies/WebBasicDeveloperPolicy";
import * as webSuperDeveloperPolicy from "./policies/WebSuperDeveloperPolicy";
import * as webDeveloperSessionManagerPolicy from "./policies/WebDeveloperSessionManagerPolicy";
import * as webBasicDeveloperRole from "./roles/WebBasicDeveloper";
import * as webSuperDeveloperRole from "./roles/WebSuperDeveloper";

// ポリシーARNをエクスポート
export const webBasicDeveloperPolicyArn = webBasicDeveloperPolicy.webBasicDeveloperPolicyArn;
export const webSuperDeveloperPolicyArn = webSuperDeveloperPolicy.webSuperDeveloperPolicyArn;
export const webDeveloperSessionManagerPolicyArn = webDeveloperSessionManagerPolicy.webDeveloperSessionManagerPolicyArn;

// ロールARNとインスタンスプロファイル名をエクスポート
export const webBasicDeveloperRoleArn = webBasicDeveloperRole.webBasicDeveloperRoleArn;
export const webBasicDeveloperInstanceProfileName = webBasicDeveloperRole.webBasicDeveloperInstanceProfileName;

export const webSuperDeveloperRoleArn = webSuperDeveloperRole.webSuperDeveloperRoleArn;
export const webSuperDeveloperInstanceProfileName = webSuperDeveloperRole.webSuperDeveloperInstanceProfileName;
