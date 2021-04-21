# General
variable "aws_region" {
  type        = string
  description = "Used AWS Region."
}

variable "aws_account" {
  type        = string
  description = "Used AWS Account."
}

variable "aws_role" {
  type        = string
  description = "Used AWS Role."
}

# Tagging
variable "namespace" {
  type        = string
  description = "Namespace."
}

variable "bounded_context" {
  type        = string
  description = "Bounded Context."
}

variable "environment" {
  type        = string
  description = "Environment."
}

# VPC
variable "aws_vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "CIDR for VPC."
}

variable "subnet_count" {
  type        = string
  description = "The number of subnets we want to create per type to ensure high availability."
}

# Internet Gateway
variable "aws_internet_gateway_name" {
  type        = string
  description = "Internet Gateway Name"
}

# Route Tables
variable "aws_route_table_gateway_name" {
  type        = string
  description = "Gateway Route Table Name"
}

variable "aws_route_table_application_name" {
  type        = string
  description = "Application Route Table Name"
}

# NAT Gateway
variable "aws_eip_name" {
  type        = string
  description = "NAT Gateway Elastic IP"
}

variable "aws_nat_gateway_name" {
  type        = string
  description = "NAT Gateway Name"
}

# Subnets
variable "aws_subnet_gateway_name" {
  type        = string
  description = "Gateway Subnet Name"
}

variable "aws_subnet_application_name" {
  type        = string
  description = "Applicatioon Subnet Name"
}

# ECR Repository
variable "aws_ecr_repository_name" {
  type        = string
  description = "Required - Name of the repository."
}

variable "aws_ecr_repository_image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "Optional - The tag mutability setting for the repository. Must be one of MUTABLE or IMMUTABLE. Defaults to MUTABLE."
}

variable "aws_ecr_repository_scan_on_push" {
  type        = string
  default     = "false"
  description = "Optional - Configuration block that defines image scanning configuration for the repository. By default, image scanning must be manually triggered."
}

# ECS Cluster
variable "aws_ecs_cluster_name" {
  type        = string
  description = "(Required) The name of the cluster (up to 255 letters, numbers, hyphens, and underscores)"
}

# S3 Bucket for ALB Logs
variable "aws_s3_bucket_name" {
  type        = string
  description = "S3 Bucket for ALB Logs"
}

# ALB Security Group
variable "aws_security_group_name" {
  type        = string
  description = "(Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name."
}

# ALB
variable "aws_lb_name" {
  type        = string
  description = "(Optional) The name of the LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen. If not specified, Terraform will autogenerate a name beginning with tf-lb."
}

# ALB Target Groups Blue & Green
variable "aws_lb_target_group_blue" {
  type        = string
  description = "(Optional, Forces new resource) Name of the target group. If omitted, Terraform will assign a random, unique name."
}

variable "aws_lb_target_group_green" {
  type        = string
  description = "(Optional, Forces new resource) Name of the target group. If omitted, Terraform will assign a random, unique name."
}

# ALB Listeners Blue & Green: No Variables

# ECS Task Execution Role & Policy
variable "ecs_task_role_name" {
  type        = string
  description = "ECS Task Service Role name."
}

# ECS Task Definition
variable "aws_ecs_task_definition_name" {
  type        = string
  description = "aws_ecs_task_definition_name"
}

# ECS Service

# ECS Role for CodeDeploy & Policy
variable "ecs_codedeploy_role_name" {
  type        = string
  description = "CodeDeploy Service Role name."
}

# CodeDeploy App
variable "aws_codedeploy_app_name" {
  type        = string
  description = "(Required) The name of the application."
}

# CodeDeploy Config
variable "aws_codedeploy_deployment_config_name" {
  type        = string
  description = "(Required) The name of the deployment config."
}

# CodeDeploy Group
variable "aws_codedeploy_deployment_group_name" {
  type        = string
  description = "(Required) The name of the deployment group."
}