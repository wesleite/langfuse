locals {
  tags = {
    Environment   = var.tag_environment
    Team          = var.tag_team
    Product       = var.tag_product
    node-exporter = "false"
  }

  all_admin_arns = distinct(concat(
    try(tolist(data.aws_iam_roles.multiaccount.arns), []),
    try(tolist(data.aws_iam_roles.multiaccount_google.arns), [])
  ))
}

resource "aws_ec2_tag" "private_lb_subnets" {
  for_each    = toset(local.lb_private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_lb_subnets" {
  for_each    = toset(local.lb_public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "shared_lb_subnets" {
  for_each    = toset(concat(local.lb_private_subnet_ids, local.lb_public_subnet_ids))
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}