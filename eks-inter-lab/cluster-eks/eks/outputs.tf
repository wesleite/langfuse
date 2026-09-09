output "cluster_eks_outputs" {
  description = "All outputs from the EKS cluster module"
  value       = module.eks_corp_staging.cluster_eks_outputs
}
