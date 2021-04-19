# ECR Repository
resource "aws_ecr_repository" "this" {
  name = var.aws_ecr_repository_name
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_tag_mutability = var.aws_ecr_repository_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.aws_ecr_repository_scan_on_push
  }

  tags = {
    name           = var.aws_ecr_repository_name
    namespace      = var.namespace
    boundedContext = var.bounded_context
    environment    = var.environment
  }
}

# Autoscaling Group (Optional)

# ECS Capacity Provider (Optional)

# CloudWatch Log
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.aws_ecs_cluster_name}/cluster"
  retention_in_days = 7
}

# ECS Cluster - Fargate
resource "aws_ecs_cluster" "this" {
  name               = var.aws_ecs_cluster_name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = "100" 
    base              = "1"
  }

  tags = {
    name           = var.aws_ecs_cluster_name
    namespace      = var.namespace
    boundedContext = var.bounded_context
    environment    = var.environment
  }

  setting {
    name = "containerInsight"
    value = "enabled"
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
  ]  
}

# ALB Security Group TCP 80 and 8080
resource "aws_security_group" "alb_sg" {\
  description = "Access to the public facing load balancer"

  egress {
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Default" 
    protocol         = "-1"
  }

  ingress {
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "HTTP Port 80"
    protocol         = "tcp"
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "HTTP Port 8080"    
    protocol         = "tcp"
  }  

  name                   = var.aws_security_group_name
  revoke_rules_on_delete = false

  tags = {
    name            = var.aws_security_group_name
    namespace       = var.namespace
    bounded_context = var.bounded_context
    environment     = var.environment    
  }

  vpc_id = var.aws_vpc_id
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "this" {
  bucket = var.aws_s3_bucket_name
  acl    = "private"

  tags = {
    name            = var.aws_s3_bucket_name
    namespace       = var.namespace
    bounded_context = var.bounded_context
    environment     = var.environment    
  }
}

# ALB
resource "aws_lb" "this" {
  name                       = "aws_lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_sg.id]
  drop_invalid_header_fields = false

  access_logs {
    bucket  = aws_s3_bucket.this.bucket
    prefix  = "aws_lb"
    enabled = true
  }

  subnets = [var.aws_subnet_id_1, var.aws_subnet_id_1]
  # subnet_mapping
  idle_timeout               = 30
  enable_deletion_protection = false
  # enable_cross_zone_load_balancing # This is for NLB's only
  enable_http2 = true
  # customer_owned_ipv4_pool
  # ip_address_typ

  tags = {
    name            = "aws_lb"
    namespace       = var.namespace
    bounded_context = var.bounded_context
    environment     = var.environment    
  }
}

# ALB Target Group 1 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "blue" {
  # deregistration_delay = 300

  health_check {
    enabled           = true
    healthy_threshold = 2
    interval          = 6
    # matcher
    path              =  "/"
    port              = 80
    protocol          = "HTTP"
    # protocol_version
    timeout           = 5
    unhealthy_threshold =  2
  }

  # lambda_multi_value_headers_enabled # For Lambda Target only
  load_balancing_algorithm_type = "round_robin"
  name                          = "alb-tg-blue"
  port                          = 80
  # preserve_client_ip
  # protocol_version              = "HTTP1"
  protocol                      = "HTTP"
  # proxy_protocol_v2 # For NLB Only
  slow_start = 0
  stickiness {

  }

  tags = {
    name            = "alb-tg-blue"
    namespace       = var.namespace
    bounded_context = var.bounded_context
    environment     = var.environment    
  }

  target_type = "ip"
  vpc_id      = var.aws_vpc_id

  depends_on = [
    aws_lb.this,
  ]
}

# ALB Target Group 2 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "green" {
  # deregistration_delay = 300

  health_check {
    enabled           = true
    healthy_threshold = 2
    interval          = 6
    # matcher
    path              =  "/"
    port              = 80
    protocol          = "HTTP"
    # protocol_version
    timeout           = 5
    unhealthy_threshold =  2
  }

  # lambda_multi_value_headers_enabled # For Lambda Target only
  load_balancing_algorithm_type = "round_robin"
  name                          = "alb-tg-green"
  port                          = 80
  # preserve_client_ip
  # protocol_version              = "HTTP1"
  protocol                      = "HTTP"
  # proxy_protocol_v2 # For NLB Only
  slow_start = 0
  stickiness {

  }

  tags = {
    name            = "alb-tg-green"
    namespace       = var.namespace
    bounded_context = var.bounded_context
    environment     = var.environment    
  }

  target_type = "ip"
  vpc_id      = var.aws_vpc_id

  depends_on = [
    aws_lb.this,
  ]
}

# ALB Listener 1 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "blue" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  load_balancer_arn = aws_lb.this.arn
  # alpn_policy
  # certificate_arn
  port     = "80"
  protocol = "HTTP"
  # ssl_policy

  depends_on = [
    aws_lb.this, aws_lb_target_group.blue
  ]
}

# ALB Listener 2 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "green" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  load_balancer_arn = aws_lb.this.arn
  # alpn_policy
  # certificate_arn  
  port     = "80"
  protocol = "HTTP"
  # ssl_policy

  depends_on = [
    aws_lb.this, aws_lb_target_group.green
  ]
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_role" {
  name = var.ecs_task_role_name
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ECS Task Execution Role Policy
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = var.ecs_task_role_policy_name
  role = aws_iam_role.ecs_task_role.name
  policy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Role for CodeDeploy
resource "aws_iam_role" "ecs_codedeploy_role" {
  name = var.ecs_codedeploy_role_name
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ECS Role for CodeDeploy Policy
resource "aws_iam_role_policy" "ecs_codedeploy_role_policy" {
  name = var.ecs_codedeploy_role_policy_name
  role = aws_iam_role.ecs_task_role.name
  policy = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}


# ECS Task Definition https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
resource "aws_ecs_task_definition" "this" {
  family = var.aws_ecs_task_definition_name

  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "service-first"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
    {
      name      = "second"
      image     = "service-second"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]
    }
  ])

  # task_role_arn
  # execution_role_arn
  # network_mode # The valid values are none, bridge, awsvpc, and host
  # ipc_mode # The valid values are host, task, and none
  # pid_mode # The valid values are host and task.

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [ap-southeast-1a, ap-southeast-1b]"
  }

  cpu    = "REPLACE_ME"
  memory = "REPLACE_ME" 
  requires_compatibilities = "FARGATE"
  # proxy_configuration
  # inference_accelerator

  tags = {
    name            = var.aws_ecs_task_definition_name
    namespace       = var.namespace
    bounded_context = var.bounded_context
    environment     = var.environment    
  }
}

# ECS Service

# CodeDeploy Deployment App

# CodeDeploy Deployment Group
