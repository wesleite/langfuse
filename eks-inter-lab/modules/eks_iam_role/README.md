# EKS IAM Role Module

This Terraform module creates an AWS IAM role, policy, and attachment intended to be consumed by workloads running on EKS. It is a small reusable building block for cases where a full application integration module is not necessary.

## Features

- **IAM Role Creation:** Creates an IAM role that can be assumed from Kubernetes through cluster identity outputs.
- **Inline Policy Attachment:** Creates and attaches a custom IAM policy defined by the caller.
- **Reusable Building Block:** Supports small or shared integrations that only need an IAM role without extra Vault or application-level resources.

## Usage

Use this module when you need a standalone IAM role for an EKS workload and already have the cluster identity outputs available.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_eks_outputs"></a> [cluster\_eks\_outputs](#input\_cluster\_eks\_outputs) | All outputs from the EKS cluster module | `any` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace | `string` | n/a | yes |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | IAM Role name | `string` | n/a | yes |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Kubernetes Service Account name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
