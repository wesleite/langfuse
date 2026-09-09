data "aws_availability_zones" "available_zones" {
  state = "available"
}

variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be created"
  default     = "us-west-2"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
  default     = "eks-vpc"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "192.168.0.0/16"
}

variable "eks_cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
  default     = "eks-cluster"
}

variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, staging, prod)"
  default     = "lab"
}