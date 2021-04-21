# ECS Role for CodeDeploy
resource "aws_iam_role" "ecs_codedeploy_role" {
  name               = var.ecs_codedeploy_role_name
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
resource "aws_iam_role_policy_attachment" "ecs_codedeploy_role" {
  role       = aws_iam_role.ecs_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Inline policy
resource "aws_iam_role_policy" "passRoleForCodeDeploy" {
  name = "passRoleForCodeDeploy"
  role = aws_iam_role.ecs_codedeploy_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Action": "iam:PassRole",
        "Resource": ${aws_iam_role.ecs_task_role.arn},
        "Effect": "Allow"
    }
}
EOF
}

# CodeDeploy Deployment App
resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = var.aws_codedeploy_app_name
}

# CodeDeploy Config
resource "aws_codedeploy_deployment_config" "this" {
  deployment_config_name = var.aws_codedeploy_deployment_config_name
  compute_platform       = "ECS"
  # minimum_healthy_hosts # required for "Server" Compute Platform

  traffic_routing_config {
    type = "TimeBasedLinear" # TimeBasedCanary, TimeBasedLinear, AllAtOnce

    time_based_linear {
      interval   = 10
      percentage = 10
    }

    # time_based_canary {
    #   interval   = 10
    #   percentage = 10
    # }
  }
}

# CodeDeploy Group
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = var.aws_codedeploy_deployment_group_name
  service_role_arn      = aws_iam_role.ecs_codedeploy_role.arn

  # alarm_configuration

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  # autoscaling_groups

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce" #aws_codedeploy_deployment_config.this.name

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # ec2_tag_filter
  # ec2_tag_set

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.this.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.blue.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  # on_premises_instance_tag_filter
  # trigger_configuration
  # tags
}