variable "cluster_eks_outputs" {
  description = "All outputs from the EKS cluster module"
  type        = any
}

variable "k8s_application_name" {
  description = "Name of the Kubernetes application"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace associated with the application"
  type        = string
}

variable "aws_iam_policy_json" {
  description = "JSON-formatted IAM policy defining AWS permissions"
  type        = string
  default     = ""
}
