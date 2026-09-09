# EKS Cluster Module

This Terraform module provisions an Amazon EKS cluster together with the AWS infrastructure and cluster-level integrations required to operate it in this repository. It combines the base EKS control plane, managed node groups, IAM integrations, DNS and load balancer tagging, and shared Kubernetes add-ons through the `k8s_commons` module.

## Features

- **Managed EKS Cluster:** Creates the EKS control plane and managed node groups with configurable labels, taints, storage, and scaling settings.
- **AWS Integrations:** Provisions IAM roles, instance profiles, Route 53 integrations, and load balancer-related AWS resources used by cluster add-ons.
- **Kubernetes Add-ons:** Delegates shared add-ons to `k8s_commons`, including ingress, monitoring, logging, DNS, Vault, and CI/CD components.
- **Networking Tags:** Applies the subnet tags required for Kubernetes load balancer discovery and internal/external traffic separation.
- **Operations Support:** Includes resources for cluster power-save automation and environment-specific operational defaults.

## Architecture

This module is responsible for the AWS and cluster infrastructure layer for EKS environments. Application-specific Kubernetes resources should live in dedicated application modules, while shared add-ons are centralized through `k8s_commons`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.1.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | = 2.2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 3.0.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_aws.solides-infrastructure"></a> [aws.solides-infrastructure](#provider\_aws.solides-infrastructure) | 5.100.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 5.2 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.37 |
| <a name="module_k8s_commons"></a> [k8s\_commons](#module\_k8s\_commons) | ../k8s_commons | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.eks_power_save_scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.eks_power_save_scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.eks_power_save_down_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.eks_power_save_up_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_ec2_tag.private_lb_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.public_lb_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.shared_lb_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_iam_instance_profile.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_eks_power_save](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.thanos_sidecar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.aws_load_balancer_controller_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cluster_autoscaler_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.external_dns_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_eks_power_save_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.thanos_sidecar_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.vault_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_policy_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.gitlab_runner_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_eks_power_save_basic_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_eks_power_save_vpc_access_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_policy_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_policy_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_policy_eks_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_policy_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_function.eks_power_save](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.eks_power_save_allow_cwe_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.eks_power_save_allow_cwe_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_security_group.eks_power_save_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.eks_nodegroup_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [kubernetes_storage_class_v1.gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [kubernetes_storage_class_v1.sc1](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_autoscaler_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_autoscaler_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ebs_csi_driver_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.gitlab_runner_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_group_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.thanos_sidecar_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.thanos_sidecar_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_policy_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.infrastructure_gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_roles.multiaccount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_iam_roles.multiaccount_google](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_secretsmanager_secret.argocd_azure_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.argocd_dex_google_sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.argocd_gitlab_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.blue_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.fluentbit_elastic_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.argocd_azure_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.argocd_dex_google_sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.argocd_gitlab_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.blue_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.fluentbit_elastic_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_enabled"></a> [argocd\_enabled](#input\_argocd\_enabled) | Whether to deploy ArgoCD and its supporting resources in the cluster. | `bool` | `true` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS CLI profile used by Terraform providers and exec-based Kubernetes authentication. | `string` | n/a | yes |
| <a name="input_blue_agent_enabled"></a> [blue\_agent\_enabled](#input\_blue\_agent\_enabled) | Whether to deploy Blue Agent and its supporting resources in the cluster. | `bool` | `true` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name assigned to the EKS cluster and reused by related AWS and Kubernetes resources. | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to run on the EKS control plane, using the `<major>.<minor>` format. | `string` | `"1.33"` | no |
| <a name="input_coredns_replica_count"></a> [coredns\_replica\_count](#input\_coredns\_replica\_count) | Optional override for the number of CoreDNS replicas. When null, the module computes the value from the environment defaults. | `number` | `null` | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | Map of EKS managed node group definitions created for the cluster. | <pre>map(object({<br/>    instance_types           = list(string)<br/>    min_size                 = number<br/>    max_size                 = number<br/>    desired_size             = number<br/>    capacity_type            = string<br/>    spot_allocation_strategy = optional(string)<br/>    ami_type                 = optional(string)<br/>    disk_size                = optional(number)<br/>    block_device_mappings = optional(map(object({<br/>      device_name = string<br/>      ebs = object({<br/>        volume_size           = number<br/>        volume_type           = string<br/>        iops                  = optional(number)<br/>        throughput            = optional(number)<br/>        encrypted             = optional(bool)<br/>        delete_on_termination = optional(bool)<br/>      })<br/>    })))<br/>    labels = optional(map(string))<br/>    taints = optional(map(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    })))<br/>  }))</pre> | n/a | yes |
| <a name="input_eks_node_groups_subnet_id"></a> [eks\_node\_groups\_subnet\_id](#input\_eks\_node\_groups\_subnet\_id) | Subnet ID used by EKS managed node groups for worker node placement. | `string` | n/a | yes |
| <a name="input_eks_subnet_ids"></a> [eks\_subnet\_ids](#input\_eks\_subnet\_ids) | Subnet IDs used by the EKS control plane ENIs and, unless overridden elsewhere, by the cluster control plane itself. | `list(string)` | n/a | yes |
| <a name="input_enable_gitlab_runner_assume_role_policy"></a> [enable\_gitlab\_runner\_assume\_role\_policy](#input\_enable\_gitlab\_runner\_assume\_role\_policy) | Whether to allow the shared infrastructure GitLab Runner role to assume this cluster GitLab Runner IAM role. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for tags, logging context, and environment-specific defaults. | `string` | n/a | yes |
| <a name="input_gitlab_runner_enabled"></a> [gitlab\_runner\_enabled](#input\_gitlab\_runner\_enabled) | Whether to deploy GitLab Runner and its related resources in the cluster. | `bool` | `true` | no |
| <a name="input_lb_private_subnet_ids"></a> [lb\_private\_subnet\_ids](#input\_lb\_private\_subnet\_ids) | Private subnet IDs tagged and used for internal load balancers created in the cluster. | `list(string)` | n/a | yes |
| <a name="input_lb_public_subnet_ids"></a> [lb\_public\_subnet\_ids](#input\_lb\_public\_subnet\_ids) | Public subnet IDs tagged and used for internet-facing load balancers created in the cluster. | `list(string)` | n/a | yes |
| <a name="input_power_save_enabled"></a> [power\_save\_enabled](#input\_power\_save\_enabled) | Whether to tag node groups with the PowerSaveEnabled marker so external automation can power them on and off. | `bool` | `false` | no |
| <a name="input_prometheus_disk_size_gb"></a> [prometheus\_disk\_size\_gb](#input\_prometheus\_disk\_size\_gb) | Persistent volume size requested by Prometheus, for example `100Gi`. | `string` | `"100Gi"` | no |
| <a name="input_prometheus_enabled"></a> [prometheus\_enabled](#input\_prometheus\_enabled) | Whether to deploy the kube-prometheus-stack monitoring addon. | `bool` | `true` | no |
| <a name="input_route53_domain"></a> [route53\_domain](#input\_route53\_domain) | Base Route 53 hosted zone domain used by ingress, DNS, and addon hostnames. | `string` | n/a | yes |
| <a name="input_slogger_context"></a> [slogger\_context](#input\_slogger\_context) | Context suffix used in logging metadata and slogger index prefixes. | `string` | n/a | yes |
| <a name="input_tag_environment"></a> [tag\_environment](#input\_tag\_environment) | Value assigned to the `Environment` tag on AWS resources created by the module. | `string` | n/a | yes |
| <a name="input_tag_product"></a> [tag\_product](#input\_tag\_product) | Value assigned to the `Product` tag on AWS resources created by the module. | `string` | n/a | yes |
| <a name="input_tag_team"></a> [tag\_team](#input\_tag\_team) | Value assigned to the `Team` tag on AWS resources created by the module. | `string` | n/a | yes |
| <a name="input_vault_enabled"></a> [vault\_enabled](#input\_vault\_enabled) | Whether to deploy Vault and its companion resources in the cluster. | `bool` | `true` | no |
| <a name="input_vault_aws_kms_key_arn"></a> [vault\_aws\_kms\_key\_arn](#input\_vault\_aws\_kms\_key\_arn) | Existing AWS KMS key ARN used by Vault auto-unseal. When empty, the module creates a dedicated KMS key. | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the EKS cluster security groups and AWS integrations are created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_eks_outputs"></a> [cluster\_eks\_outputs](#output\_cluster\_eks\_outputs) | All outputs from the EKS cluster module |
<!-- END_TF_DOCS -->
