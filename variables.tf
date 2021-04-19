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

# Autoscaling Group (Optional)

# ECS Capacity Provider (Optional)

# ECS Cluster
variable "aws_ecs_cluster_name" {
  type        = string
  description = "(Required) The name of the cluster (up to 255 letters, numbers, hyphens, and underscores)"
}

# ALB Security Group TCP 80 and 8080
variable "aws_security_group_name" {
  type        = string
  description = "(Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name."
}

# S3 Bucket for ALB Logs
variable "aws_s3_bucket_name" {
  type        = string
  description = "S3 Bucket for ALB Logs"
}

# ALB
variable "aws_lb_name" {
  type        = string
  description = "(Optional) The name of the LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen. If not specified, Terraform will autogenerate a name beginning with tf-lb."
}

# ALB Target Groups

# ALB Listeners

# ECS Task Execution Role

# ECS Role for CodeDeploy

# ECS Task Definition

# ECS Service

# CodeDeploy Deployment App

# CodeDeploy Deployment Group