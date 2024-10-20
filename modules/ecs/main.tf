# Create ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# Get existing secret from Secrets Manager
data "aws_secretsmanager_secret" "app_env_secret" {
  name = "${var.project_name}-develop-environment"
}

# Get the secret version
data "aws_secretsmanager_secret_version" "app_env_secret_version" {
  secret_id = data.aws_secretsmanager_secret.app_env_secret.id
}

# Attach the AmazonECSTaskExecutionRolePolicy policy to the ECS execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Policy to allow access to secrets
resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name = "ecs-task-secrets-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secret.app_env_secret.arn
      }
    ]
  })
}

# Policy to allow access to secrets in the execution role
resource "aws_iam_role_policy" "ecs_execution_secrets_policy" {
  name = "ecs-execution-secrets-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secret.app_env_secret.arn
      }
    ]
  })
}

# Create IAM roles for ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# ECSFargateAllowExecuteCommand policy
resource "aws_iam_policy" "ecs_fargate_allow_execute_command_policy" {
  name        = "ECSFargateAllowExecuteCommand"
  description = "Allows ECS tasks to execute commands on the host"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecs:ExecuteCommand",
          "ssm:SendCommand",
          "ssm:ListCommandInvocations",
          "ssm:ListCommands",
          "ssm:GetCommandInvocation",
        ],
        Resource = "*"
      }
    ]
  })
}

# Create ECS task definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-container"
    image = "${var.ecr_repository_url}:latest"
    essential = true
    enableExecuteCommand = true
    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }
    ]
    secrets = [
      {
        name      = "ENV_FILE"
        valueFrom = var.app_env_secret_arn
      }
    ]
    command = ["sh","-c","echo \"$ENV_FILE\" > .env && cat .env && npm run start"]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    version = timestamp()
  }
}

# Create ECS service
resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.project_name}-container"
    container_port   = var.container_port
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}
