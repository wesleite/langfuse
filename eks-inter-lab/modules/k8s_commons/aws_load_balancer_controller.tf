resource "helm_release" "aws_load_balancer_controller" {
  count            = var.cloud_provider == "aws" ? 1 : 0
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = true

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.3"

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.aws_load_balancer_controller_identifier
    },
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "vpcId"
      value = var.aws_vpc_id
    }
  ]

  values = [
    file("${path.module}/values/aws_load_balancer_controller/values.yaml")
  ]

  depends_on = [
    helm_release.keda,
  ]
}
