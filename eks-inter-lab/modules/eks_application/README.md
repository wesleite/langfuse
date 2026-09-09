# EKS Application Module

This Terraform module provisions the AWS IAM and Vault integration required by a single application running on an EKS cluster. It is intended to be instantiated per application so each workload can receive its own least-privilege AWS and Vault access configuration.

## Features

- **Application IAM Role:** Creates an IAM role and policy that can be assumed by a Kubernetes service account through IRSA.
- **Vault Integration:** Configures the Vault Kubernetes auth role required for the application to authenticate with Vault.
- **Per-Application Scope:** Keeps access boundaries isolated per application instead of sharing a broad cluster-wide identity.

## Usage

Use this module when an application deployed on EKS needs both AWS IAM permissions and Vault access bound to a specific Kubernetes service account.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | 5.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kv_secret_v2.cicd](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) | resource |
| [vault_kv_secret_v2.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) | resource |
| [vault_policy.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_iam_policy_json"></a> [aws\_iam\_policy\_json](#input\_aws\_iam\_policy\_json) | JSON-formatted IAM policy defining AWS permissions | `string` | `""` | no |
| <a name="input_cluster_eks_outputs"></a> [cluster\_eks\_outputs](#input\_cluster\_eks\_outputs) | All outputs from the EKS cluster module | `any` | n/a | yes |
| <a name="input_k8s_application_name"></a> [k8s\_application\_name](#input\_k8s\_application\_name) | Name of the Kubernetes application | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace associated with the application | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
