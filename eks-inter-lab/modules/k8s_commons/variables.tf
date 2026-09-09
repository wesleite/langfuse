variable "argocd_dex_google_sso_client_id" {
  description = "Google OAuth client ID stored in the ArgoCD Dex SSO secret."
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_dex_google_sso_client_secret" {
  description = "Google OAuth client secret stored in the ArgoCD Dex SSO secret."
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_enabled" {
  description = "Whether to deploy ArgoCD. This addon is currently used only for AWS clusters."
  type        = bool
  default     = true
}

variable "argocd_azure_password" {
  description = "Password for the Azure repository credential template configured in ArgoCD."
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_gitlab_password" {
  description = "Password for the GitLab repository credential template configured in ArgoCD."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_acm_certificate_arn" {
  description = "ACM certificate ARN used by AWS-facing ingress and load balancer addons."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || trimspace(var.aws_acm_certificate_arn) != ""
    error_message = "aws_acm_certificate_arn is required when cloud_provider = \"aws\"."
  }
}

variable "aws_load_balancer_controller_identifier" {
  description = "IAM role ARN used by the AWS Load Balancer Controller service account."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || trimspace(var.aws_load_balancer_controller_identifier) != ""
    error_message = "aws_load_balancer_controller_identifier is required when cloud_provider = \"aws\"."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform exec-based Kubernetes authentication."
  type        = string
  default     = null

  validation {
    condition     = var.cloud_provider != "aws" || (var.aws_profile != null && trimspace(var.aws_profile) != "")
    error_message = "aws_profile is required when cloud_provider = \"aws\"."
  }
}

variable "aws_region" {
  description = "AWS region used by AWS-specific addons such as cluster-autoscaler."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || trimspace(var.aws_region) != ""
    error_message = "aws_region is required when cloud_provider = \"aws\"."
  }
}

variable "aws_vpc_id" {
  description = "AWS VPC ID consumed by AWS-specific addons such as the AWS Load Balancer Controller."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || trimspace(var.aws_vpc_id) != ""
    error_message = "aws_vpc_id is required when cloud_provider = \"aws\"."
  }
}

variable "azure_resource_group_name" {
  description = "Azure resource group name used by Azure-specific addons and workload identities."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "azure" || trimspace(var.azure_resource_group_name) != ""
    error_message = "azure_resource_group_name is required when cloud_provider = \"azure\"."
  }
}

variable "azure_subscription_id" {
  description = "Azure subscription ID used by Azure-specific addons."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "azure" || trimspace(var.azure_subscription_id) != ""
    error_message = "azure_subscription_id is required when cloud_provider = \"azure\"."
  }
}

variable "azure_tenant_id" {
  description = "Azure tenant ID used by Azure-specific addons."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "azure" || trimspace(var.azure_tenant_id) != ""
    error_message = "azure_tenant_id is required when cloud_provider = \"azure\"."
  }
}

variable "blue_agent_enabled" {
  description = "Whether to deploy Blue Agent. This addon is currently used only for AWS clusters."
  type        = bool
  default     = true
}

variable "blue_agent_organization_url" {
  description = "Azure DevOps organization URL used by the Blue Agent chart."
  type        = string
  default     = ""
  sensitive   = true
}

variable "blue_agent_personal_access_token" {
  description = "Azure DevOps personal access token used by the Blue Agent chart."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cert_manager_identifier" {
  description = "Cloud identity identifier used by cert-manager. Use an IAM role ARN on AWS or a managed identity client ID on Azure."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "azure" || trimspace(var.cert_manager_identifier) != ""
    error_message = "cert_manager_identifier is required when cloud_provider = \"azure\"."
  }
}

variable "cloud_provider" {
  description = "Target cloud provider for the cluster addons. Supported values are aws, azure, oracle, and huawei."
  type        = string

  validation {
    condition     = contains(["aws", "azure", "oracle", "huawei"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, azure, oracle, huawei."
  }
}

variable "cluster_autoscaler_identifier" {
  description = "IAM role ARN used by the cluster-autoscaler service account."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || trimspace(var.cluster_autoscaler_identifier) != ""
    error_message = "cluster_autoscaler_identifier is required when cloud_provider = \"aws\"."
  }
}

variable "cluster_name" {
  description = "Cluster name used by Helm releases, DNS ownership, and addon-specific identifiers."
  type        = string
}

variable "dns_domain" {
  description = "Base DNS domain used by ingress, ExternalDNS, cert-manager, and addon hostnames."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. staging, prod)."
  type        = string
}

variable "external_dns_identifier" {
  description = "Cloud identity identifier used by ExternalDNS. Use an IAM role ARN on AWS or a managed identity client ID on Azure."
  type        = string
  default     = ""

  validation {
    condition     = !contains(["aws", "azure"], var.cloud_provider) || trimspace(var.external_dns_identifier) != ""
    error_message = "external_dns_identifier is required when cloud_provider = \"aws\" or \"azure\"."
  }
}

variable "fluentbit_elastic_password" {
  description = "Password used by Fluent Bit when authenticating to Elasticsearch/OpenSearch."
  type        = string
  sensitive   = true
}

variable "fluentbit_elastic_user" {
  description = "Username used by Fluent Bit when authenticating to Elasticsearch/OpenSearch."
  type        = string
}

variable "gitlab_runner_enabled" {
  description = "Whether to deploy GitLab Runner releases and their shared service account."
  type        = bool
  default     = true
}

variable "gitlab_runner_identifier" {
  description = "Cloud identity identifier used by GitLab Runner. Use an IAM role ARN on AWS or a managed identity client ID on Azure."
  type        = string
  default     = ""

  validation {
    condition     = !contains(["aws", "azure"], var.cloud_provider) || !var.gitlab_runner_enabled || trimspace(var.gitlab_runner_identifier) != ""
    error_message = "gitlab_runner_identifier is required when gitlab_runner_enabled is true on AWS or Azure."
  }
}

variable "gitlab_runner_node_isolation_enabled" {
  description = "Whether GitLab Runner pods should use the dedicated node selector and tolerations."
  type        = bool
  default     = true
}

variable "gitlab_runner_tokens" {
  description = "Map of GitLab Runner registration tokens keyed by runner suffix. Each key becomes part of the Helm release name."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "huawei_cluster_id" {
  description = "Huawei CCE cluster ID used by Huawei-specific integrations."
  type        = string
  default     = null

  validation {
    condition     = var.cloud_provider != "huawei" || (var.huawei_cluster_id != null && trimspace(var.huawei_cluster_id) != "")
    error_message = "huawei_cluster_id is required when cloud_provider = \"huawei\"."
  }
}

variable "huawei_region" {
  description = "Huawei region used by Huawei-specific integrations."
  type        = string
  default     = null

  validation {
    condition     = var.cloud_provider != "huawei" || (var.huawei_region != null && trimspace(var.huawei_region) != "")
    error_message = "huawei_region is required when cloud_provider = \"huawei\"."
  }
}

variable "k8s_cleaner_enabled" {
  description = "Whether to deploy the k8s-cleaner addon responsible for removing Evicted pods from the cluster."
  type        = bool
  default     = false
}

variable "oracle_cluster_id" {
  description = "Oracle OKE cluster OCID used by Oracle-specific integrations."
  type        = string
  default     = null

  validation {
    condition     = var.cloud_provider != "oracle" || (var.oracle_cluster_id != null && trimspace(var.oracle_cluster_id) != "")
    error_message = "oracle_cluster_id is required when cloud_provider = \"oracle\"."
  }
}

variable "oracle_region" {
  description = "Oracle region used by Oracle-specific integrations."
  type        = string
  default     = null

  validation {
    condition     = var.cloud_provider != "oracle" || (var.oracle_region != null && trimspace(var.oracle_region) != "")
    error_message = "oracle_region is required when cloud_provider = \"oracle\"."
  }
}

variable "prometheus_aws_iam_role_arn" {
  description = "IAM role ARN used by Prometheus/Thanos when AWS access is required."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || !var.prometheus_enabled || trimspace(var.prometheus_aws_iam_role_arn) != ""
    error_message = "prometheus_aws_iam_role_arn is required when prometheus_enabled is true on AWS."
  }
}

variable "prometheus_disk_size_gb" {
  description = "Persistent volume size requested by Prometheus, for example `100Gi`."
  type        = string
  default     = "100Gi"
}

variable "prometheus_enabled" {
  description = "Whether to deploy the kube-prometheus-stack addon."
  type        = bool
  default     = true
}

variable "slogger_context" {
  description = "Context suffix used in log routing metadata and slogger index prefixes."
  type        = string
}

variable "slogger_environment" {
  description = "Environment label used in log routing metadata and slogger index prefixes."
  type        = string
}

variable "vault_aws_kms_key_arn" {
  description = "AWS KMS key ARN used by Vault auto-unseal on AWS clusters."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || !var.vault_enabled || trimspace(var.vault_aws_kms_key_arn) != ""
    error_message = "vault_aws_kms_key_arn is required when vault_enabled is true on AWS."
  }
}

variable "vault_enabled" {
  description = "Whether to deploy HashiCorp Vault and its companion resources."
  type        = bool
  default     = true
}

variable "vault_identifier" {
  description = "Cloud identity identifier used by Vault. On AWS this should be the IRSA IAM role ARN."
  type        = string
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || !var.vault_enabled || trimspace(var.vault_identifier) != ""
    error_message = "vault_identifier is required when vault_enabled is true on AWS."
  }
}

variable "vault_node_isolation_enabled" {
  description = "Whether Vault pods should use dedicated node selector and toleration settings."
  type        = bool
  default     = true
}
