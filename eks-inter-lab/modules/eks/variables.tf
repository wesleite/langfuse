variable "argocd_enabled" {
  description = "Whether to deploy ArgoCD and its supporting resources in the cluster."
  type        = bool
  default     = true
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform providers and exec-based Kubernetes authentication."
  type        = string
}

variable "blue_agent_enabled" {
  description = "Whether to deploy Blue Agent and its supporting resources in the cluster."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name assigned to the EKS cluster and reused by related AWS and Kubernetes resources."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to run on the EKS control plane, using the `<major>.<minor>` format."
  type        = string
  default     = "1.33"
}

variable "coredns_replica_count" {
  description = "Optional override for the number of CoreDNS replicas. When null, the module computes the value from the environment defaults."
  type        = number
  default     = null
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions created for the cluster."
  type = map(object({
    instance_types           = list(string)
    min_size                 = number
    max_size                 = number
    desired_size             = number
    capacity_type            = string
    spot_allocation_strategy = optional(string)
    ami_type                 = optional(string)
    disk_size                = optional(number)
    block_device_mappings = optional(map(object({
      device_name = string
      ebs = object({
        volume_size           = number
        volume_type           = string
        iops                  = optional(number)
        throughput            = optional(number)
        encrypted             = optional(bool)
        delete_on_termination = optional(bool)
      })
    })))
    labels = optional(map(string))
    taints = optional(map(object({
      key    = string
      value  = string
      effect = string
    })))
  }))
}

variable "environment" {
  description = "Deployment environment (e.g. staging, prod)."
  type        = string
}

variable "gitlab_runner_enabled" {
  description = "Whether to deploy GitLab Runner and its related resources in the cluster."
  type        = bool
  default     = true
}

variable "gitlab_runner_node_isolation_enabled" {
  description = "Whether GitLab Runner pods should use the dedicated node selector and tolerations."
  type        = bool
  default     = true
}

variable "k8s_cleaner_enabled" {
  description = "Whether to deploy the k8s-cleaner addon responsible for removing Evicted pods from the cluster."
  type        = bool
  default     = false
}

variable "power_save_enabled" {
  description = "Whether to tag node groups with the PowerSaveEnabled marker so external automation can power them on and off."
  type        = bool
  default     = false
}

variable "prometheus_disk_size_gb" {
  description = "Persistent volume size requested by Prometheus, for example `100Gi`."
  type        = string
  default     = "100Gi"
}

variable "prometheus_enabled" {
  description = "Whether to deploy the kube-prometheus-stack monitoring addon."
  type        = bool
  default     = true
}

variable "route53_domain" {
  description = "Base Route 53 hosted zone domain used by ingress, DNS, and addon hostnames."
  type        = string
}

variable "slogger_context" {
  description = "Context suffix used in logging metadata and slogger index prefixes."
  type        = string
}

variable "tag_environment" {
  description = "Value assigned to the `Environment` tag on AWS resources created by the module."
  type        = string
}

variable "tag_product" {
  description = "Value assigned to the `Product` tag on AWS resources created by the module."
  type        = string
}

variable "tag_team" {
  description = "Value assigned to the `Team` tag on AWS resources created by the module."
  type        = string
}

variable "vault_enabled" {
  description = "Whether to deploy Vault and its companion resources in the cluster."
  type        = bool
  default     = true
}

variable "vault_aws_kms_key_arn" {
  description = "Existing AWS KMS key ARN used by Vault auto-unseal. When empty, the module creates a dedicated KMS key."
  type        = string
  default     = ""
}

variable "vpc_name_prefix" {
  description = "Base VPC Name tag prefix used to discover the VPC and related EKS/private/public subnets, for example `vpc-rh-prod`."
  type        = string
}

variable "power_save_suspended" {
  type        = bool
  description = "Define se a execução automática do Power Save está suspensa (Pausada)"
  default     = false
}