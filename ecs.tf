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
}

# CloudWatch Log for ECS
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

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
  ]
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "this" {
  bucket = var.aws_s3_bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowELBRootAccount",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.aws_account}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.aws_s3_bucket_name}/*"
    },
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.aws_s3_bucket_name}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${var.aws_s3_bucket_name}"
    }
  ]
}
POLICY
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  description = "Access to the public facing load balancer"

  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default"
    protocol    = "-1"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP Port 80"
    protocol    = "tcp"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP Port 8080"
    protocol    = "tcp"
  }

  name                   = var.aws_security_group_name
  revoke_rules_on_delete = false
  vpc_id                 = aws_vpc.this.id
}

# ALB
resource "aws_lb" "this" {
  name                       = var.aws_lb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  drop_invalid_header_fields = false

  access_logs {
    bucket  = aws_s3_bucket.this.bucket
    prefix  = var.aws_lb_name
    enabled = true
  }

  subnets = aws_subnet.gateway.*.id
  # subnet_mapping
  idle_timeout               = 30
  enable_deletion_protection = false
  # enable_cross_zone_load_balancing # This is for NLB's only
  enable_http2 = true
  # customer_owned_ipv4_pool
  # ip_address_typ
}

# ALB Target Group Blue
resource "aws_lb_target_group" "blue" {
  # deregistration_delay = 300

  health_check {
    enabled           = true
    healthy_threshold = 2
    interval          = 6
    # matcher
    path     = "/"
    port     = 80
    protocol = "HTTP"
    # protocol_version
    timeout             = 5
    unhealthy_threshold = 2
  }

  # lambda_multi_value_headers_enabled # For Lambda Target only
  load_balancing_algorithm_type = "round_robin"
  name                          = var.aws_lb_target_group_blue
  port                          = 80
  # preserve_client_ip
  # protocol_version              = "HTTP1"
  protocol = "HTTP"
  # proxy_protocol_v2 # For NLB Only
  # slow_start = 0
  # stickiness {}

  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  depends_on = [
    aws_lb.this,
  ]
}

# ALB Target Group Green
resource "aws_lb_target_group" "green" {
  # deregistration_delay = 300

  health_check {
    enabled           = true
    healthy_threshold = 2
    interval          = 6
    # matcher
    path     = "/"
    port     = 80
    protocol = "HTTP"
    # protocol_version
    timeout             = 5
    unhealthy_threshold = 2
  }

  # lambda_multi_value_headers_enabled # For Lambda Target only
  load_balancing_algorithm_type = "round_robin"
  name                          = var.aws_lb_target_group_green
  port                          = 80
  # preserve_client_ip
  # protocol_version              = "HTTP1"
  protocol = "HTTP"
  # proxy_protocol_v2 # For NLB Only
  # slow_start = 0
  # stickiness {}

  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  depends_on = [
    aws_lb.this,
  ]
}

# ALB Listener Blue
resource "aws_lb_listener" "blue" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  load_balancer_arn = aws_lb.this.arn
  # alpn_policy
  # certificate_arn
  port     = 80
  protocol = "HTTP"
  # ssl_policy

  depends_on = [
    aws_lb.this, aws_lb_target_group.blue
  ]
}

# ALB Listener Green
resource "aws_lb_listener" "green" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  load_balancer_arn = aws_lb.this.arn
  # alpn_policy
  # certificate_arn  
  port     = 8080
  protocol = "HTTP"
  # ssl_policy

  depends_on = [
    aws_lb.this, aws_lb_target_group.green
  ]
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_role" {
  name               = var.ecs_task_role_name
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
resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family = var.aws_ecs_task_definition_name

  container_definitions = jsonencode([
    {
      name      = var.aws_ecs_task_definition_name
      image     = "182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-app:v1"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          hostPort      = 80
          protocol      = "tcp"
          containerPort = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.aws_ecs_task_definition_name
        }
      }
    }
  ])

  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
}

# ECS Service