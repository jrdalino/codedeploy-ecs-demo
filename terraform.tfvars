# General
aws_region  = "ap-southeast-1"
aws_account = "182101634518" # AWS account where resource will be created
aws_role    = "OrganizationAccountAccessRole"

# Tagging
namespace       = "foo"
bounded_context = "bar"
environment     = "production"

# VPC
aws_vpc_name = "foo-bar-vpc"
aws_vpc_cidr = "10.0.0.0/16"
subnet_count = "2"

# Internet Gateway
aws_internet_gateway_name = "foo-bar-internet-gateway"

# Route Tables
aws_route_table_gateway_name     = "foo-bar-gateway-route-table"
aws_route_table_application_name = "foo-shared-application-route-table"

# NAT Gateway
aws_eip_name         = "foo-bar-nat-gateway-eip"
aws_nat_gateway_name = "foo-bar-nat-gateway"

# Subnets
aws_subnet_gateway_name     = "foo-bar-gateway-subnet"
aws_subnet_application_name = "foo-bar-application-subnet"

# ECR Repository
aws_ecr_repository_name                 = "foo-bar-ecr"
aws_ecr_repository_image_tag_mutability = "MUTABLE"
aws_ecr_repository_scan_on_push         = "false"

# ECS Cluster
aws_ecs_cluster_name = "foo-bar-ecs"

# ALB Security Group
aws_security_group_name = "foo-bar-alb-security-group"

# ALB
aws_lb_name = "foo-bar-alb"

# ALB Target Groups Blue & Green
aws_lb_target_group_blue  = "foo-bar-alb-target-group-blue"
aws_lb_target_group_green = "foo-bar-alb-target-group-green"

# ALB Listeners Blue & Green: No Variables

# ECS Task Execution Role & Policy
ecs_task_role_name = "foo-bar-ecs-task-definition-service-role"

# ECS Task Definition
aws_ecs_task_definition_name = "foo-bar-ecs"

# ECS Service
aws_ecs_service_name = "foo-bar-ecs"

# ECS Role for CodeDeploy & Policy
ecs_codedeploy_role_name = "foo-bar-codedeploy-service-role"

# CodeDeploy App
aws_codedeploy_app_name = "foo-bar-codedeploy-app"

# CodeDeploy Config
aws_codedeploy_deployment_config_name = "foo-bar-codedeploy-config"

# CodeDeploy Group
aws_codedeploy_deployment_group_name = "foo-bar-codedeploy-group"