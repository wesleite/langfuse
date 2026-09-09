####################################################################################
### Karpenter NodeClass & NodePool (Spot + Pod Subnet Selector)
####################################################################################
resource "kubectl_manifest" "node_class" {
  yaml_body = <<-EOT
    apiVersion: eks.amazonaws.com/v1
    kind: NodeClass
    metadata:
      name: spot-nodeclass
    spec:
      role: ${module.eks.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            "kubernetes.io/cluster/${var.eks_cluster_name}": "shared"
      podSubnetSelectorTerms:
        - tags:
            "kubernetes.io/role/cni": "1"
      securityGroupSelectorTerms:
        - id: ${module.eks.cluster_primary_security_group_id}
  EOT

  depends_on = [module.eks]
}

resource "kubectl_manifest" "node_pool_spot" {
  yaml_body = <<-EOT
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: spot-nodepool
    spec:
      template:
        metadata:
          labels:
            lifecycle: spot
        spec:
          nodeClassRef:
            group: eks.amazonaws.com
            kind: NodeClass
            name: spot-nodeclass
          requirements:
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot"]
            - key: "eks.amazonaws.com/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "eks.amazonaws.com/instance-generation"
              operator: Gt
              values: ["4"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64", "arm64"]
      limits:
        cpu: "1000"
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  EOT

  depends_on = [kubectl_manifest.node_class]
}