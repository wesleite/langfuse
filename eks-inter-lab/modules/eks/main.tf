locals {
  coredns_replica_count = coalesce(
    var.coredns_replica_count,
    var.environment == "prod" ? 5 : 2
  )
}

data "aws_iam_roles" "multiaccount" {
  # name_regex  = "AWSReservedSSO_AWSAdministratorAccess_.*"
  name_regex  = "AWSReservedSSO_(AWSAdministratorAccess|system-administrator)_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "multiaccount_google" {
  name_regex  = "SLD-Administrator"
  path_prefix = "/"
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 20.37"
  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = false
  vpc_id                         = data.aws_vpc.selected.id
  subnet_ids                     = local.eks_subnet_ids
  dataplane_wait_duration        = "900s"
  create_cloudwatch_log_group    = false
  cluster_enabled_log_types      = []

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        computeType  = "EC2"
        replicaCount = local.coredns_replica_count
        topologySpreadConstraints = [
          {
            labelSelector = {
              matchLabels = {
                k8s-app = "kube-dns"
              }
            }
            maxSkew           = 1
            topologyKey       = "kubernetes.io/hostname"
            whenUnsatisfiable = "ScheduleAnyway"
          },
        ]
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_IP_TARGET           = "1"
          MINIMUM_IP_TARGET        = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
  }

  eks_managed_node_groups = {
    for node_group_name, node_group_config in merge(
      var.environment == "prod" && var.vault_enabled ? {
        vault = {
          instance_types = ["t3.medium"]
          min_size       = 1
          max_size       = 3
          desired_size   = 1
          capacity_type  = "ON_DEMAND"
          subnet_ids     = [local.eks_node_groups_subnet_id]
          labels = {
            NodeGroup = "vault"
          }
          taints = {
            vault = {
              key    = "vault"
              value  = "true"
              effect = "NO_EXECUTE"
            }
          }
        }
      } : {},
      var.eks_managed_node_groups
      ) : node_group_name => merge(
      {
        instance_types        = node_group_config.instance_types
        min_size              = node_group_config.min_size
        max_size              = node_group_config.max_size
        desired_size          = node_group_config.desired_size
        capacity_type         = node_group_config.capacity_type
        subnet_ids            = [local.eks_node_groups_subnet_id]
        create_before_destroy = true
      },
      lookup(node_group_config, "ami_type", null) != null ? {
        ami_type = node_group_config.ami_type
      } : {},
      lookup(node_group_config, "block_device_mappings", null) != null ? {
        block_device_mappings = node_group_config.block_device_mappings
      } : {},
      lookup(node_group_config, "labels", null) != null ? {
        labels = node_group_config.labels
      } : {},
      lookup(node_group_config, "taints", null) != null ? {
        taints = node_group_config.taints
      } : {},
      # Proteção para o campo SPOT (evita erro se a chave não existir no objeto)
      lookup(node_group_config, "capacity_type", "") == "SPOT" ? {
        spot_allocation_strategy = lookup(node_group_config, "spot_allocation_strategy", "capacity-optimized")
      } : {},
      lookup(node_group_config, "launch_template_tags", null) != null ? {
        launch_template_tags = node_group_config.launch_template_tags
      } : {},
      var.power_save_enabled ? {
        node_group_tags = {
          PowerSaveEnabled = "true"
        }
      } : {}
    )
  }

  cluster_security_group_additional_rules = {
    vpn_fortigate_https = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.212.134.0/24"]
      description = "Allow HTTPS from VPN Fortigate"
    }
    # all_networks_https = {
    #   type        = "ingress"
    #   from_port   = 443
    #   to_port     = 443
    #   protocol    = "tcp"
    #   cidr_blocks = ["0.0.0.0/0"]
    #   description = "Allow HTTPS from all networks"
    # }
  }

# Transforma a lista de ARNs em entradas individuais de acesso no EKS
  access_entries = {
    for arn in local.all_admin_arns : basename(arn) => {
      kubernetes_groups = []
      principal_arn     = arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # enable_cluster_creator_admin_permissions = false

  # access_entries = {
  #   sso_admin = {
  #     kubernetes_groups = []
  #     principal_arn     = try(tolist(data.aws_iam_roles.multiaccount.arns)[0], try(tolist(data.aws_iam_roles.multiaccount_google.arns)[0], null))
  #     policy_associations = {
  #       cluster_admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #         access_scope = {
  #           type = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }

  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Istio Webhook Sidecar Injector"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_8080 = {
      description                   = "Vault Webhook Sidecar Injector"
      protocol                      = "TCP"
      from_port                     = 8080
      to_port                       = 8080
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_443 = {
      description = "Rancher connection port 443"
      protocol    = "TCP"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      self        = true
    }
  }

  tags = local.tags
}