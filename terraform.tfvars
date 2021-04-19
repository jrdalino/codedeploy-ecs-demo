# General
aws_region  = "ap-southeast-1"
aws_account = "623552185285" # AWS account where resource will be created
aws_role    = "OrganizationAccountAccessRole"

# Tagging
namespace       = "bbbsdm"
bounded_context = "shared"
environment     = "production"

# ECR Repository
aws_ecr_repository_name                 = "ecs-sample-app"
aws_ecr_repository_image_tag_mutability = "MUTABLE"
aws_ecr_repository_scan_on_push         = "false"

# Autoscaling Group (Optional)

# ECS Capacity Provider (Optional)

# ECS Cluster
aws_ecs_cluster_name = "example-ecs-cluster"

# ALB Security Group TCP 80 and 8080
aws_security_group_name = "example-sg"

# S3 Bucket for ALB Logs
aws_s3_bucket_name = "623552185285-alb-logs"

# ALB
aws_lb_name = "example-lb"
aws_subnet_id_1 = "REPLACE_ME"
aws_subnet_id_2 = "REPLACE_ME"

# ALB Target Groups
aws_vpc_id = "REPLACE_ME"

# ALB Listeners

# ECS Task Execution Role

# ECS Role for CodeDeploy

# ECS Task Definition
aws_ecs_task_definition_name = "REPLACE_ME"

# ECS Service

# CodeDeploy Deployment App

# CodeDeploy Deployment Group