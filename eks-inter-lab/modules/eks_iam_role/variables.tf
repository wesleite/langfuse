variable "cluster_eks_outputs" {
  description = "All outputs from the EKS cluster module"
  type        = any
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes Service Account name"
  type        = string
}

variable "policy_json" {
  description = "IAM Role name"
  type        = string
}
