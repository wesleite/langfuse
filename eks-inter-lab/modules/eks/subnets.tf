data "aws_region" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name_prefix]
  }
}

data "aws_subnets" "eks_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name_prefix}-eks-*-private-us-east-1*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name_prefix}-private-us-east-1*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name_prefix}-public-us-east-1*"]
  }
}

data "aws_subnet" "eks_private" {
  for_each = toset(data.aws_subnets.eks_private.ids)
  id       = each.value
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

locals {
  eks_subnet_ids_by_name = {
    for subnet in data.aws_subnet.eks_private : subnet.tags["Name"] => subnet.id
  }

  private_lb_subnet_ids_by_name = {
    for subnet in data.aws_subnet.private : subnet.tags["Name"] => subnet.id
  }

  public_lb_subnet_ids_by_name = {
    for subnet in data.aws_subnet.public : subnet.tags["Name"] => subnet.id
  }

  eks_subnet_ids = [
    for subnet_name in sort(keys(local.eks_subnet_ids_by_name)) : local.eks_subnet_ids_by_name[subnet_name]
  ]

  lb_private_subnet_ids = [
    for subnet_name in sort(keys(local.private_lb_subnet_ids_by_name)) : local.private_lb_subnet_ids_by_name[subnet_name]
  ]

  lb_public_subnet_ids = [
    for subnet_name in sort(keys(local.public_lb_subnet_ids_by_name)) : local.public_lb_subnet_ids_by_name[subnet_name]
  ]

  eks_node_groups_subnet_id = one([
    for subnet_name, subnet_id in local.eks_subnet_ids_by_name : subnet_id
    if endswith(subnet_name, "us-east-1a")
  ])
}
