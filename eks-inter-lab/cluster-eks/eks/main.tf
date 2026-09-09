module "eks_corp_staging" {
  source              = "../../modules/eks"
  aws_profile         = "solides-ti-corp-staging"
  cluster_name        = "eks-corp-staging"
  cluster_version     = "1.36"
  vpc_name_prefix     = "vpc-corp-staging"
  route53_domain      = local.eks_corp_staging_route53_domain
  environment         = "staging"
  slogger_context     = "corp"
  power_save_enabled  = true
  power_save_suspended  = false
  k8s_cleaner_enabled = true

  eks_managed_node_groups = {
    apps_ondemand = {
      instance_types = ["m6a.large"]
      min_size       = 1
      max_size       = 15
      desired_size   = 1
      capacity_type  = "ON_DEMAND"

      labels = {
        NodeGroup = "apps"
      }

      taints = {
        apps = {
          key    = "apps"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      }
    }

    default_ondemand = {
      instance_types = ["m6a.large"]
      min_size       = 1
      max_size       = 10
      desired_size   = 1
      capacity_type  = "ON_DEMAND"

      labels = {
        NodeGroup = "default"
      }
    }

    gitlab_spot = {
      instance_types = [
        # --- Família C (Compute Optimized - Foco em CPU para Builds) ---
        "c6a.large", "c6a.xlarge", # AMD Gen 6
        "c5a.large", "c5a.xlarge", # AMD Gen 5 (Extremamente baratas)
        "c6i.large", "c6i.xlarge", # Intel Gen 6
        "c5.large", "c5.xlarge",   # Intel Gen 5

        # --- Família M (General Purpose - Balanço CPU/RAM) ---
        "m6a.large", "m6a.xlarge", # AMD Gen 6
        "m5a.large", "m5a.xlarge", # AMD Gen 5
        "m6i.large", "m6i.xlarge", # Intel Gen 6

        # --- Família R (Memory Optimized - Evita estouro de memória no build) ---
        "r6a.large", "r6a.xlarge", # AMD Gen 6
        "r5a.large", "r5a.xlarge", # AMD Gen 5
        "r6i.large", "r6i.xlarge"  # Intel Gen 6
      ]
      min_size      = 1
      max_size      = 10
      desired_size  = 1
      capacity_type = "SPOT"

      labels = {
        NodeGroup = "gitlab"
      }

      taints = {
        gitlab = {
          key    = "gitlab"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      }
    }
  }

  tag_environment = "Staging"
  tag_product     = "Eks-Cluster"
  tag_team        = "PlataformaCloud"
}